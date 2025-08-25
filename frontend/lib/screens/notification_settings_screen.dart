import 'package:flutter/material.dart';

class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('알림 설정'), centerTitle: true),
      body: const Center(
        child: Text('알림 설정 기능은 준비 중입니다.', style: TextStyle(fontSize: 16)),
      ),
    );
  }
} 