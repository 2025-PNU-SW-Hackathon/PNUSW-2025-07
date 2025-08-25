import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:async';
import 'web_recorder.dart';

class VoiceService {
  static const String baseUrl = 'https://simlog-production.up.railway.app';
  final AudioRecorder _audioRecorder = AudioRecorder();
  final WebRecorder _webRecorder = WebRecorder();
  bool _isRecording = false;
  
  /// 마이크 권한 요청
  Future<bool> requestMicrophonePermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  /// 음성 녹음 시작
  Future<bool> startRecording() async {
    if (_isRecording) return false;

    try {
      if (kIsWeb) {
        // 웹에서는 MediaRecorder 래퍼 사용
        final ok = await _webRecorder.start();
        _isRecording = ok;
        return ok;
      } else {
        // 모바일/데스크탑에서는 record 패키지 사용
        final hasPermission = await requestMicrophonePermission();
        if (!hasPermission) {
          throw Exception('마이크 권한이 필요합니다.');
        }

        final tempDir = Directory.systemTemp;
        final tempFile = File('${tempDir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.wav');
        
        await _audioRecorder.start(
          const RecordConfig(
            encoder: AudioEncoder.wav,
            bitRate: 128000,
            sampleRate: 16000,
          ),
          path: tempFile.path,
        );
        _isRecording = true;
        return true;
      }
    } catch (e) {
      throw Exception('녹음을 시작할 수 없습니다: $e');
    }
  }

  /// 음성 녹음 중지
  Future<String?> stopRecording() async {
    if (!_isRecording) return null;

    try {
      if (kIsWeb) {
        final bytes = await _webRecorder.stop();
        // 메모리 바이트를 Blob URL처럼 취급하기 위해 data URL 생성 대신 바로 서버로 보낼 것이므로
        // 임시로 로컬 파일 경로 대신 식별용 가짜 경로를 반환하고, 상위에서 kIsWeb이면 바이트 경로를 따로 처리할 수도 있으나
        // 기존 인터페이스를 유지하기 위해 bytes를 data URL 형태로 encoding 하여 전달
        final dataUrl = 'data:audio/webm;base64,${base64Encode(bytes)}';
        _isRecording = false;
        return dataUrl;
      } else {
        final path = await _audioRecorder.stop();
        _isRecording = false;
        return path;
      }
    } catch (e) {
      _isRecording = false;
      throw Exception('녹음을 중지할 수 없습니다: $e');
    }
  }

  /// 녹음 중인지 확인
  bool get isRecording => _isRecording;

  /// 음성 파일을 텍스트로 변환
  Future<Map<String, dynamic>> speechToText({
    required String accessToken,
    required String audioFilePath,
  }) async {
    try {
      if (kIsWeb && audioFilePath.startsWith('data:audio/webm;base64,')) {
        // data URL에서 바이트 추출하여 업로드
        final base64Part = audioFilePath.split(',').last;
        final bytes = base64Decode(base64Part);
        return await _uploadBytes(accessToken: accessToken, bytes: bytes, filename: 'audio.webm', contentType: MediaType('audio', 'webm'));
      } else {
        final file = File(audioFilePath);
        if (!await file.exists()) {
          throw Exception('오디오 파일을 찾을 수 없습니다.');
        }
        final bytes = await file.readAsBytes();
        return await _uploadBytes(accessToken: accessToken, bytes: bytes, filename: 'audio.wav', contentType: MediaType('audio', 'wav'));
      }
    } catch (e) {
      return {
        'success': false,
        'error': '음성인식 처리 중 오류가 발생했습니다: $e',
      };
    }
  }

  Future<Map<String, dynamic>> _uploadBytes({
    required String accessToken,
    required List<int> bytes,
    required String filename,
    required MediaType contentType,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/voice/stt'),
    );

    request.headers['Authorization'] = 'Bearer $accessToken';
    request.files.add(
      http.MultipartFile.fromBytes(
        'audio_file',
        bytes,
        filename: filename,
        contentType: contentType,
      ),
    );

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();
    final result = json.decode(responseBody);

    if (response.statusCode == 200) {
      return {
        'success': true,
        'text': result['text'] ?? '',
        'confidence': result['confidence'] ?? 0.0,
      };
    } else {
      return {
        'success': false,
        'error': result['detail'] ?? '음성인식에 실패했습니다.',
      };
    }
  }

  /// 리소스 해제
  void dispose() {
    _audioRecorder.dispose();
  }
} 