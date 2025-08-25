import 'package:flutter/material.dart';
import 'diary_result_screen.dart';

class DiaryLoadingScreen extends StatefulWidget {
  final Map<String, dynamic> record;
  const DiaryLoadingScreen({Key? key, required this.record}) : super(key: key);

  @override
  State<DiaryLoadingScreen> createState() => _DiaryLoadingScreenState();
}

class _DiaryLoadingScreenState extends State<DiaryLoadingScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => DiaryResultScreen(record: widget.record),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            CircularProgressIndicator(),
            SizedBox(height: 24),
            Text('일기를 정리 중입니다...', style: TextStyle(fontSize: 20)),
          ],
        ),
      ),
    );
  }
} 