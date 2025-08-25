import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../services/api_service.dart';
import '../services/voice_service.dart';
import 'diary_loading_screen.dart';

class EmotionRecordScreen extends StatefulWidget {
  final String accessToken;
  const EmotionRecordScreen({Key? key, required this.accessToken}) : super(key: key);

  @override
  State<EmotionRecordScreen> createState() => _EmotionRecordScreenState();
}

class _EmotionRecordScreenState extends State<EmotionRecordScreen> with TickerProviderStateMixin {
  double sleepScore = 5;
  double stressScore = 5;
  final TextEditingController diaryController = TextEditingController();
  final VoiceService _voiceService = VoiceService();
  bool isRecording = false;
  bool isLoading = false;
  
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _voiceService.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

    // 음성 입력 기능 구현
  Future<void> onVoiceInput() async {
    try {
      if (isRecording) {
        // 녹음 중지
        final audioPath = await _voiceService.stopRecording();
        if (audioPath != null) {
          setState(() { isLoading = true; });
          
          // 음성인식 수행
          final result = await _voiceService.speechToText(
            accessToken: widget.accessToken,
            audioFilePath: audioPath,
          );
          
          if (result['success']) {
            final recognizedText = result['text'] as String;
            if (recognizedText.isNotEmpty) {
              diaryController.text += recognizedText;
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(result['error'] ?? '음성인식에 실패했습니다.')),
            );
          }
        }
        setState(() { 
          isRecording = false;
          isLoading = false;
        });
      } else {
        // 녹음 시작
        final success = await _voiceService.startRecording();
        if (success) {
          setState(() { isRecording = true; });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('녹음을 시작했습니다. 다시 탭하면 녹음을 중지합니다.'),
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          // Web에서 음성 녹음이 실패할 경우 안내 메시지
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('음성 녹음이 지원되지 않습니다. 텍스트로 직접 입력해주세요.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      setState(() { 
        isRecording = false;
        isLoading = false;
      });
      
      // 음성인식 오류 처리
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('음성입력 오류: ${e.toString()}')),
      );
    }
  }



  Future<void> onSubmit() async {
    if (diaryController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('일기 내용을 입력해주세요.')),
      );
      return;
    }
    setState(() { isLoading = true; });
    try {
      final record = await ApiService.createRecord(
        accessToken: widget.accessToken,
        content: diaryController.text.trim(),
        sleepScore: sleepScore.round(),
        stressScore: stressScore.round(),
      );
      // 저장 성공 시 로딩 화면 → 결과 화면으로 데이터 전달
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DiaryLoadingScreen(record: record),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    } finally {
      setState(() { isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('감정 기록 입력'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE8F5E8),
              Color(0xFFF0F8FF),
              Colors.white,
            ],
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 32),
                  _buildSleepCard(),
                  const SizedBox(height: 24),
                  _buildStressCard(),
                  const SizedBox(height: 24),
                  _buildDiaryCard(),
                  const SizedBox(height: 32),
                  _buildSubmitButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Card(
      elevation: 6,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF667eea),
              Color(0xFF764ba2),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.2),
                ),
                child: const Icon(
                  Icons.edit_note,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '오늘 하루를 알려주세요!',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '당신의 감정을 기록하고 분석해보세요',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSleepCard() {
    return Card(
      elevation: 4,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.bedtime,
                    color: Colors.blue,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  '수면 품질',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '${sleepScore.round()}/10',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 8),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: Colors.blue,
                inactiveTrackColor: Colors.blue.withOpacity(0.2),
                thumbColor: Colors.blue,
                overlayColor: Colors.blue.withOpacity(0.1),
                valueIndicatorColor: Colors.blue,
                valueIndicatorTextStyle: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              child: Slider(
                value: sleepScore,
                min: 1,
                max: 10,
                divisions: 9,
                label: sleepScore.round().toString(),
                onChanged: (v) => setState(() => sleepScore = v),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStressCard() {
    return Card(
      elevation: 4,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.psychology,
                    color: Colors.orange,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  '스트레스 정도',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '${stressScore.round()}/10',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 8),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: Colors.orange,
                inactiveTrackColor: Colors.orange.withOpacity(0.2),
                thumbColor: Colors.orange,
                overlayColor: Colors.orange.withOpacity(0.1),
                valueIndicatorColor: Colors.orange,
                valueIndicatorTextStyle: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              child: Slider(
                value: stressScore,
                min: 1,
                max: 10,
                divisions: 9,
                label: stressScore.round().toString(),
                onChanged: (v) => setState(() => stressScore = v),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiaryCard() {
    return Card(
      elevation: 4,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.book,
                    color: Colors.green,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  '오늘의 일기',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: diaryController,
              maxLines: 6,
              decoration: InputDecoration(
                hintText: '오늘 하루는 어땠나요? 당신의 생각과 감정을 자유롭게 적어보세요.',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.green, width: 2),
                ),
                filled: true,
                fillColor: Colors.grey.withOpacity(0.05),
                suffixIcon: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isRecording ? Colors.red : Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    icon: Icon(
                      isRecording ? Icons.mic : Icons.mic_none,
                      color: isRecording ? Colors.white : Colors.grey,
                    ),
                    onPressed: isLoading ? null : onVoiceInput,
                    tooltip: isRecording ? '녹음 중지' : '음성 입력',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF4CAF50),
            Color(0xFF45a049),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4CAF50).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onSubmit,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.save,
                    color: Colors.white,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    '일기 저장하기',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
} 