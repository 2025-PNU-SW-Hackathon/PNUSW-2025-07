class WebRecorder {
  Future<bool> start() async => throw UnsupportedError('WebRecorder is only available on web');
  Future<List<int>> stop() async => throw UnsupportedError('WebRecorder is only available on web');
}