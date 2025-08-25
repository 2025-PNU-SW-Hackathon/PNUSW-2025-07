import 'package:flutter/material.dart';

class RecordDetailScreen extends StatelessWidget {
  final Map<String, dynamic> record;
  
  const RecordDetailScreen({
    Key? key,
    required this.record,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final emotion = record['emotion_analysis'] ?? {};
    final colorInfo = emotion['color'] ?? {};
    final colorName = colorInfo['name'] ?? '알 수 없음';
    final colorHex = colorInfo['hex'] ?? '#CCCCCC';
    final primaryEmotion = emotion['primary_emotion'] ?? '';
    final intensity = emotion['intensity'] ?? 5;
    final confidence = emotion['confidence'] ?? 0.0;
    final aiSummary = record['ai_summary'] ?? '';
    final aiKeywords = (record['ai_keywords'] as List<dynamic>?)?.cast<String>() ?? [];
    final content = record['content'] ?? '';
    final sleepScore = record['sleep_score'] ?? 0;
    final stressScore = record['stress_score'] ?? 0;
    final createdAt = DateTime.parse(record['created_at']);

    Color parseColor(String hex) {
      hex = hex.replaceAll('#', '');
      if (hex.length == 6) hex = 'FF$hex';
      return Color(int.parse(hex, radix: 16));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${createdAt.month}월 ${createdAt.day}일의 일기'),
        centerTitle: true,
        automaticallyImplyLeading: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 감정색 카드
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                                          Text(
                      '오늘의 감정색은 $colorName 입니다',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                      const SizedBox(height: 20),
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: parseColor(colorHex),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black12, width: 3),
                        ),
                        child: Center(
                                                  child: Text(
                          colorName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildInfoItem('감정 강도', '$intensity/10', Icons.speed),
                          _buildInfoItem('분석 신뢰도', '${(confidence * 100).toInt()}%', Icons.psychology),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // 수면/스트레스 점수
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildScoreItem(
                          '수면 점수',
                          sleepScore,
                          Icons.bedtime,
                          Colors.indigo,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildScoreItem(
                          '스트레스 점수',
                          stressScore,
                          Icons.psychology,
                          Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // AI 한줄 요약
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.auto_awesome, color: Colors.amber),
                          const SizedBox(width: 8),
                          const Text(
                            'AI 한줄 요약',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        aiSummary.isNotEmpty ? aiSummary : 'AI 요약이 없습니다.',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // 감정 키워드
              if (aiKeywords.isNotEmpty) ...[
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.tag, color: Colors.green),
                            const SizedBox(width: 8),
                            const Text(
                              '감정 키워드',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: aiKeywords.map((keyword) => Chip(
                            label: Text(keyword),
                            backgroundColor: Colors.green.withOpacity(0.1),
                            labelStyle: TextStyle(
                              color: Colors.green[700],
                              fontWeight: FontWeight.bold,
                            ),
                          )).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
              
              // 일기 내용
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.edit_note, color: Colors.blue),
                          const SizedBox(width: 8),
                          const Text(
                            '일기 내용',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        content,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // 작성 시간
              Card(
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Icon(Icons.access_time, color: Colors.grey, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        '작성 시간: ${createdAt.year}년 ${createdAt.month}월 ${createdAt.day}일 ${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.deepPurple, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildScoreItem(String label, int score, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          '$score/10',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
} 