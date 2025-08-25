// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:async';

class WebRecorder {
  html.MediaRecorder? _rec;
  html.MediaStream? _stream;
  final List<html.Blob> _chunks = [];

  Future<bool> start() async {
    _stream = await html.window.navigator.mediaDevices!.getUserMedia({'audio': true});
    _rec = html.MediaRecorder(_stream!, {'mimeType': 'audio/webm;codecs=opus'});
    _chunks.clear();
    _rec!.addEventListener('dataavailable', (e) {
      final evt = e as html.BlobEvent;
      if (evt.data != null && evt.data!.size > 0) {
        _chunks.add(evt.data!);
      }
    });
    _rec!.start();
    return true;
  }

  Future<List<int>> stop() async {
    if (_rec == null) return [];
    final completer = Completer<List<int>>();
    _rec!.addEventListener('stop', (_) async {
      final blob = html.Blob(_chunks, 'audio/webm');
      final reader = html.FileReader();
      reader.readAsArrayBuffer(blob);
      reader.onLoadEnd.listen((_) {
        final bytes = (reader.result as List<int>);
        completer.complete(bytes);
      });
      _stream?.getTracks().forEach((t) => t.stop());
    });
    _rec!.stop();
    return completer.future;
  }
}