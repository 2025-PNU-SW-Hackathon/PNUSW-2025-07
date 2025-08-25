import 'package:flutter/material.dart';

class AppSettingsScreen extends StatelessWidget {
  const AppSettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('앱 설정'), centerTitle: true),
      body: const Center(
        child: Text('앱 설정 기능은 준비 중입니다.', style: TextStyle(fontSize: 16)),
      ),
    );
  }
} 