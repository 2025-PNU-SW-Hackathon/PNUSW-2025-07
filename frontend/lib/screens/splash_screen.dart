import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _isNavigating = false;
  String _statusMessage = '앱을 시작하는 중...';

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // 서버 연결 상태 확인
      setState(() {
        _statusMessage = '서버에 연결하는 중...';
      });
      
      final serverStatus = await ApiService.getServerStatus();
      print('서버 상태: $serverStatus');
      
      if (mounted && !_isNavigating) {
        setState(() {
          _isNavigating = true;
          _statusMessage = '로그인 화면으로 이동 중...';
        });
        
        // 로그인 화면으로 이동
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    } catch (e) {
      print('앱 초기화 오류: $e');
      
      // 오류가 발생해도 로그인 화면으로 이동
      if (mounted && !_isNavigating) {
        setState(() {
          _isNavigating = true;
          _statusMessage = '오프라인 모드로 시작...';
        });
        
        await Future.delayed(const Duration(seconds: 1));
        
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 앱 아이콘
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.spa, 
                  size: 80, 
                  color: Colors.deepPurple,
                ),
              ),
              const SizedBox(height: 32),
              
              // 앱 이름
              const Text(
                'SimLog',
                style: TextStyle(
                  fontSize: 36, 
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
              const SizedBox(height: 12),
              
              // 앱 설명
              const Text(
                '하루 기록으로 마음 심기',
                style: TextStyle(
                  fontSize: 18, 
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 40),
              
              // 상태 메시지
              Text(
                _statusMessage,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              
              // 로딩 인디케이터
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 