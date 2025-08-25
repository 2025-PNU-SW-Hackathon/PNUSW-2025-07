import 'package:flutter/material.dart';

class DiaryResultScreen extends StatelessWidget {
  final Map<String, dynamic> record;
  const DiaryResultScreen({Key? key, required this.record}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final aiKeywords = (record['ai_keywords'] as List<dynamic>?)?.cast<String>() ?? [];
    final aiSummary = record['ai_summary'] ?? '';
    final emotion = record['emotion_analysis'] ?? {};
    final colorInfo = emotion['color'] ?? {};
    final colorName = colorInfo['name'] ?? '알 수 없음';
    final colorHex = colorInfo['hex'] ?? '#CCCCCC';
    final primaryEmotion = emotion['primary_emotion'] ?? '';
    
    // AI 실패 여부 확인
    final aiFailed = emotion['ai_failed'] ?? false;
    final errorMessage = emotion['error_message'] ?? '';
    final aiUsed = emotion['ai_used'] ?? false;

    Color parseColor(String hex) {
      hex = hex.replaceAll('#', '');
      if (hex.length == 6) hex = 'FF$hex';
      return Color(int.parse(hex, radix: 16));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('일기 분석 결과')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // AI 실패 경고 메시지
            if (aiFailed) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  border: Border.all(color: Colors.orange, width: 1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'AI 분석에 실패하여 키워드 기반 분석을 사용했습니다.',
                        style: TextStyle(color: Colors.orange[800], fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // 분석 방법 표시
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: aiUsed ? Colors.green.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                aiUsed ? '🤖 AI 분석' : '🔍 키워드 분석',
                style: TextStyle(
                  color: aiUsed ? Colors.green[700] : Colors.blue[700],
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // 오늘의 감정색 문구
            Text(
              '오늘의 감정색은 $colorName 입니다',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            // 색상 강조 (더 큰 원)
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: parseColor(colorHex),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black12, width: 2),
              ),
              alignment: Alignment.center,
              child: Text(
                colorName,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
              ),
            ),
            const SizedBox(height: 32),
            // AI 한줄요약
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'AI 한줄요약:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.deepPurple),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                aiSummary,
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 24),
            // 감정 키워드
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '감정 키워드:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.deepPurple),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                aiKeywords.isNotEmpty ? aiKeywords.join(", ") : '-',
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 32),
            const Text('일기가 저장되었습니다!', style: TextStyle(fontSize: 18, color: Colors.green)),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                // 홈으로 돌아가기 (네비게이션 바에서 분석 탭으로 이동 가능)
                Navigator.popUntil(context, (route) => route.isFirst);
              },
              child: const Text('홈으로 돌아가기'),
            ),
          ],
        ),
      ),
    );
  }
} 