import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'record_detail_screen.dart';

class AnalysisScreen extends StatefulWidget {
  final String accessToken;
  const AnalysisScreen({Key? key, required this.accessToken}) : super(key: key);

  @override
  AnalysisScreenState createState() => AnalysisScreenState();
}

class AnalysisScreenState extends State<AnalysisScreen> with TickerProviderStateMixin {
  bool isLoading = true;
  Map<String, dynamic>? statistics;
  List<Map<String, dynamic>> records = [];
  String selectedPeriod = '7';
  bool _disposed = false;
  
  // 캐시를 위한 변수들
  final Map<String, Map<String, dynamic>> _statisticsCache = {};
  final Map<String, List<Map<String, dynamic>>> _recordsCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheValidDuration = Duration(minutes: 5); // 5분간 캐시 유효
  
  // 애니메이션 컨트롤러
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
    _loadData();
  }

  @override
  void dispose() {
    _disposed = true;
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (_disposed) return;
    
    // 캐시된 데이터가 있고 유효한지 확인
    if (_isCacheValid(selectedPeriod)) {
      setState(() {
        statistics = _statisticsCache[selectedPeriod];
        records = _recordsCache[selectedPeriod] ?? [];
        isLoading = false;
      });
      return;
    }
    
    setState(() {
      isLoading = true;
    });

    try {
      // 백엔드 API에 맞게 수정: /statistics/{days} 엔드포인트 사용
      final stats = await ApiService.getEmotionStatistics(
        accessToken: widget.accessToken,
        days: int.parse(selectedPeriod),
      );
      final recordsData = await ApiService.getRecordsByPeriod(
        accessToken: widget.accessToken,
        days: int.parse(selectedPeriod),
      );
      // average_color.name이 이미 있으면 캐시에 저장하고 AI 호출하지 않음
      if (stats['average_color'] != null && stats['average_color']['name'] != null) {
        _statisticsCache[selectedPeriod] = stats;
        _recordsCache[selectedPeriod] = recordsData;
        _cacheTimestamps[selectedPeriod] = DateTime.now();
        setState(() {
          statistics = stats;
          records = recordsData;
          isLoading = false;
        });
        return;
      }
      
      if (_disposed) return;
      
      // 캐시에 저장
      _statisticsCache[selectedPeriod] = stats;
      _recordsCache[selectedPeriod] = recordsData;
      _cacheTimestamps[selectedPeriod] = DateTime.now();
      
      setState(() {
        statistics = stats;
        records = recordsData;
        isLoading = false;
      });
    } catch (e) {
      if (_disposed) return;
      
      setState(() {
        isLoading = false;
      });
      
      if (mounted && !_disposed) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('데이터 로드 실패: ${e.toString()}')),
        );
      }
    }
  }

  bool _isCacheValid(String period) {
    final timestamp = _cacheTimestamps[period];
    if (timestamp == null) return false;
    
    final now = DateTime.now();
    return now.difference(timestamp) < _cacheValidDuration;
  }

  void _clearCache() {
    _statisticsCache.clear();
    _recordsCache.clear();
    _cacheTimestamps.clear();
  }

  // 외부에서 호출할 수 있는 캐시 갱신 메서드
  void refreshCache() {
    _clearCache();
    if (mounted && !_disposed) {
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('감정 분석'),
        centerTitle: true,
        actions: [
                           PopupMenuButton<String>(
                   onSelected: (value) {
                     if (mounted && !_disposed) {
                       WidgetsBinding.instance.addPostFrameCallback((_) {
                         if (!_disposed) {
                           setState(() {
                             selectedPeriod = value;
                           });
                           _loadData(); // 캐시된 데이터가 있으면 API 호출하지 않음
                         }
                       });
                     }
                   },
            itemBuilder: (context) => [
              const PopupMenuItem(value: '7', child: Text('최근 7일')),
              const PopupMenuItem(value: '14', child: Text('최근 14일')),
              const PopupMenuItem(value: '30', child: Text('최근 30일')),
            ],
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${selectedPeriod}일'),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE3F2FD),
              Color(0xFFF3E5F5),
              Colors.white,
            ],
          ),
        ),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: RefreshIndicator(
                    onRefresh: _loadData,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildStatisticsCard(),
                          const SizedBox(height: 24),
                          _buildRecordsList(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildStatisticsCard() {
    if (statistics == null) return const SizedBox.shrink();

    return Card(
      elevation: 8,
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.2),
                    ),
                    child: const Icon(
                      Icons.analytics,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    '감정 통계',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      '총 기록',
                      '${statistics!['record_count'] ?? 0}개',
                      Icons.article,
                      Colors.white,
                    ),
                  ),
                  Expanded(
                    child: _buildAverageColorItem(
                      statistics!['average_color'],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // 감정 분포 표시
              if (statistics!['emotion_distribution'] != null && 
                  (statistics!['emotion_distribution'] as Map).isNotEmpty) ...[
                const Text(
                  '감정 분포',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: (statistics!['emotion_distribution'] as Map<String, dynamic>)
                      .entries
                      .map((entry) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${entry.key} ${entry.value}개',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ],
              const SizedBox(height: 16),
              Text(
                statistics!['message'] ?? '',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.2),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 12),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildAverageColorItem(Map<String, dynamic>? averageColor) {
    if (averageColor == null) {
      return Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.2),
            ),
            child: const Icon(Icons.palette, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 12),
          const Text(
            '없음',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            '평균 감정색',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      );
    }

    final colorName = averageColor['name'] ?? '알 수 없음';
    final colorHex = averageColor['hex'] ?? '#CCCCCC';
    final intensity = averageColor['average_intensity'] ?? 5;

    Color parseColor(String hex) {
      hex = hex.replaceAll('#', '');
      if (hex.length == 6) hex = 'FF$hex';
      return Color(int.parse(hex, radix: 16));
    }

    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: parseColor(colorHex),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: parseColor(colorHex).withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.palette, color: Colors.white, size: 24),
        ),
        const SizedBox(height: 12),
        Text(
          colorName,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          '평균 감정색',
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
        Text(
          '강도: ${intensity}',
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildRecordsList() {
    if (records.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.article_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  '기록이 없습니다',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '최근 기록',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: records.length,
          itemBuilder: (context, index) {
            final record = records[index];
            final emotion = record['emotion_analysis'] ?? {};
            final colorInfo = emotion['color'] ?? {};
            final colorName = colorInfo['name'] ?? '알 수 없음';
            final colorHex = colorInfo['hex'] ?? '#CCCCCC';
            final primaryEmotion = emotion['primary_emotion'] ?? '';
            final createdAt = DateTime.parse(record['created_at']);

            Color parseColor(String hex) {
              hex = hex.replaceAll('#', '');
              if (hex.length == 6) hex = 'FF$hex';
              return Color(int.parse(hex, radix: 16));
            }

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                onTap: () {
                  Future.delayed(Duration.zero, () {
                    if (mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RecordDetailScreen(record: record),
                        ),
                      );
                    }
                  });
                },
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: parseColor(colorHex),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.favorite, color: Colors.white, size: 20),
                ),
                title: Text(
                  colorName,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${createdAt.year}년 ${createdAt.month}월 ${createdAt.day}일',
                      style: const TextStyle(fontSize: 12),
                    ),
                    if (record['ai_summary'] != null)
                      Text(
                        record['ai_summary'],
                        style: const TextStyle(fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '수면: ${record['sleep_score'] ?? 0}',
                      style: const TextStyle(fontSize: 10),
                    ),
                    Text(
                      '스트레스: ${record['stress_score'] ?? 0}',
                      style: const TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Color _getEmotionColor(String emotion) {
    switch (emotion) {
      case '기쁨':
        return Colors.yellow;
      case '신뢰':
        return Colors.green;
      case '두려움':
        return Colors.cyan;
      case '놀람':
        return Colors.blue;
      case '슬픔':
        return Colors.indigo;
      case '혐오':
        return Colors.purple;
      case '분노':
        return Colors.red;
      case '기대':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
} 