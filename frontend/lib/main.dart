import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/splash_screen.dart';

void main() {
  // Flutter 바인딩 초기화
  WidgetsFlutterBinding.ensureInitialized();
  
  // 시스템 UI 설정
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // 전역 예외 처리 (간단하게)
  FlutterError.onError = (FlutterErrorDetails details) {
    // 오류 로그만 출력하고 앱은 계속 실행
    print('Flutter Error: ${details.exception}');
  };
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SimLog',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        fontFamily: 'Pretendard',
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontFamily: 'Pretendard', fontWeight: FontWeight.w700),
          displayMedium: TextStyle(fontFamily: 'Pretendard', fontWeight: FontWeight.w600),
          displaySmall: TextStyle(fontFamily: 'Pretendard', fontWeight: FontWeight.w600),
          headlineLarge: TextStyle(fontFamily: 'Pretendard', fontWeight: FontWeight.w700),
          headlineMedium: TextStyle(fontFamily: 'Pretendard', fontWeight: FontWeight.w600),
          headlineSmall: TextStyle(fontFamily: 'Pretendard', fontWeight: FontWeight.w600),
          titleLarge: TextStyle(fontFamily: 'Pretendard', fontWeight: FontWeight.w600),
          titleMedium: TextStyle(fontFamily: 'Pretendard', fontWeight: FontWeight.w500),
          titleSmall: TextStyle(fontFamily: 'Pretendard', fontWeight: FontWeight.w500),
          bodyLarge: TextStyle(fontFamily: 'Pretendard', fontWeight: FontWeight.w400),
          bodyMedium: TextStyle(fontFamily: 'Pretendard', fontWeight: FontWeight.w400),
          bodySmall: TextStyle(fontFamily: 'Pretendard', fontWeight: FontWeight.w300),
          labelLarge: TextStyle(fontFamily: 'Pretendard', fontWeight: FontWeight.w600),
          labelMedium: TextStyle(fontFamily: 'Pretendard', fontWeight: FontWeight.w500),
          labelSmall: TextStyle(fontFamily: 'Pretendard', fontWeight: FontWeight.w400),
        ),
      ),
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
