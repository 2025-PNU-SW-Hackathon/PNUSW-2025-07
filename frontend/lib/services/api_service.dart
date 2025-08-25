import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Railway 배포된 백엔드 서버
  static const String baseUrl = 'https://simlog-production.up.railway.app';
  
  // 개발용 로컬 URL (필요시 주석 해제)
  // static const String baseUrl = 'http://localhost:8000';
  
  // 서버 연결 테스트
  static Future<bool> testConnection() async {
    try {
      final url = Uri.parse('$baseUrl/health');
      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('연결 시간 초과');
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      print('서버 연결 테스트 실패: $e');
      return false;
    }
  }
  
  // 서버 상태 확인 (health check)
  static Future<Map<String, dynamic>> getServerStatus() async {
    try {
      final url = Uri.parse('$baseUrl/health');
      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('연결 시간 초과');
        },
      );
      
      if (response.statusCode == 200) {
        return {'status': 'connected', 'message': '서버 연결됨'};
      } else {
        return {'status': 'error', 'message': '서버 응답 오류: ${response.statusCode}'};
      }
    } catch (e) {
      return {'status': 'error', 'message': '연결 실패: $e'};
    }
  }
  // ===== Reports & Alerts =====
  static Future<Map<String, dynamic>> getConsent({required String accessToken}) async {
    final url = Uri.parse('$baseUrl/reports/consent');
    final response = await http.get(url, headers: {'Authorization': 'Bearer $accessToken'});
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('동의 상태 조회 실패');
    }
  }

  static Future<Map<String, dynamic>> setConsent({required String accessToken, required bool consented}) async {
    final url = Uri.parse('$baseUrl/reports/consent');
    final response = await http.post(
      url,
      headers: {'Authorization': 'Bearer $accessToken', 'Content-Type': 'application/json'},
      body: jsonEncode({'consented': consented}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('동의 설정 실패');
    }
  }

  static Future<Map<String, dynamic>> createWeeklyShare({required String accessToken}) async {
    final url = Uri.parse('$baseUrl/reports/weekly/share');
    final response = await http.post(url, headers: {'Authorization': 'Bearer $accessToken'});
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final body = jsonDecode(response.body);
      throw Exception(body['detail'] ?? '공유 링크 생성 실패');
    }
  }

  static Future<Map<String, dynamic>> getWeeklySummary({required String accessToken, int period = 7}) async {
    final url = Uri.parse('$baseUrl/records/weekly/summary?period=$period');
    final response = await http.get(url, headers: {'Authorization': 'Bearer $accessToken'});
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('주간 요약 조회 실패');
    }
  }

  static Future<Map<String, dynamic>> checkAlert({required String accessToken}) async {
    final url = Uri.parse('$baseUrl/alerts/check');
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $accessToken'},
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('알림 확인 실패');
    }
  }

  static Future<Map<String, dynamic>> forceShowAlertForTesting({required String accessToken}) async {
    final url = Uri.parse('$baseUrl/alerts/test/force-show');
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $accessToken'},
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final body = jsonDecode(response.body);
      throw Exception(body['detail'] ?? '테스트 알림 표시 실패');
    }
  }

  static Future<void> ackAlert({required String accessToken}) async {
    final url = Uri.parse('$baseUrl/alerts/ack');
    final response = await http.post(url, headers: {'Authorization': 'Bearer $accessToken'});
    if (response.statusCode != 200) {
      throw Exception('알림 확인 처리 실패');
    }
  }

  static Future<Map<String, dynamic>> signup({
    required String email,
    required String password,
    required String nickname,
    String? socialType,
    String? socialId,
  }) async {
    final url = Uri.parse('$baseUrl/auth/signup');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'nickname': nickname,
        'social_type': socialType,
        'social_id': socialId,
      }),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(jsonDecode(response.body)['detail'] ?? '회원가입 실패');
    }
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('$baseUrl/auth/login');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(jsonDecode(response.body)['detail'] ?? '로그인 실패');
    }
  }

  static Future<Map<String, dynamic>> getMyInfo(String accessToken) async {
    final url = Uri.parse('$baseUrl/users/me');
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('사용자 정보 조회 실패');
    }
  }

  static Future<Map<String, dynamic>> createRecord({
    required String accessToken,
    required String content,
    required int sleepScore,
    required int stressScore,
    bool shareWithCounselor = false,
  }) async {
    final url = Uri.parse('$baseUrl/records/');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode({
        'content': content,
        'sleep_score': sleepScore,
        'stress_score': stressScore,
        'share_with_counselor': shareWithCounselor,
      }),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(jsonDecode(response.body)['detail'] ?? '감정 기록 저장 실패');
    }
  }

  // 정원 관련 API 메서드들
  static Future<Map<String, dynamic>> checkAttendance(String accessToken) async {
    final url = Uri.parse('$baseUrl/garden/attendance');
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(jsonDecode(response.body)['detail'] ?? '출석 체크 실패');
    }
  }

  static Future<Map<String, dynamic>> getGardenInfo(String accessToken) async {
    final url = Uri.parse('$baseUrl/garden/info');
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('정원 정보 조회 실패');
    }
  }

  static Future<Map<String, dynamic>> getShopItems() async {
    final url = Uri.parse('$baseUrl/garden/shop');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('상점 아이템 조회 실패');
    }
  }

  static Future<Map<String, dynamic>> purchaseItem({
    required String accessToken,
    required int templateId,
    int quantity = 1,
  }) async {
    final url = Uri.parse('$baseUrl/garden/purchase/$templateId?quantity=$quantity');
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(jsonDecode(response.body)['detail'] ?? '아이템 구매 실패');
    }
  }

  static Future<Map<String, dynamic>> equipItem({
    required String accessToken,
    required int itemId,
    required int positionX,
    required int positionY,
    String? variant,
  }) async {
    String url = '$baseUrl/garden/equip/$itemId?position_x=$positionX&position_y=$positionY';
    if (variant != null) {
      url += '&variant=$variant';
    }
    
    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(jsonDecode(response.body)['detail'] ?? '아이템 배치 실패');
    }
  }

  static Future<Map<String, dynamic>> unequipItem({
    required String accessToken,
    required int itemId,
  }) async {
    final url = Uri.parse('$baseUrl/garden/unequip/$itemId');
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(jsonDecode(response.body)['detail'] ?? '아이템 제거 실패');
    }
  }

  static Future<Map<String, dynamic>> getInventory(String accessToken) async {
    final url = Uri.parse('$baseUrl/garden/inventory');
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('인벤토리 조회 실패');
    }
  }

  static Future<Map<String, dynamic>> sellItem({
    required String accessToken,
    required int itemId,
    int quantity = 1,
  }) async {
    final url = Uri.parse('$baseUrl/garden/sell/$itemId');
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'quantity': quantity,
      }),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final errorBody = jsonDecode(response.body);
      throw Exception(errorBody['detail'] ?? '아이템 판매 실패');
    }
  }

  static Future<List<Map<String, dynamic>>> getRecords({
    required String accessToken,
    int skip = 0,
    int limit = 100,
  }) async {
    final url = Uri.parse('$baseUrl/records/?skip=$skip&limit=$limit');
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('감정 기록 조회 실패');
    }
  }

  static Future<List<Map<String, dynamic>>> getRecordsByPeriod({
    required String accessToken,
    required int days,
  }) async {
    final url = Uri.parse('$baseUrl/records/period/$days');
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      final errorBody = jsonDecode(response.body);
      throw Exception(errorBody['detail'] ?? '기간별 감정 기록 조회 실패');
    }
  }

  static Future<Map<String, dynamic>> getEmotionStatistics({
    required String accessToken,
    required int days,
  }) async {
    final url = Uri.parse('$baseUrl/records/statistics/$days');
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final errorBody = jsonDecode(response.body);
      throw Exception(errorBody['detail'] ?? '감정 통계 조회 실패');
    }
  }

  static Future<Map<String, dynamic>> getTodayRecord({
    required String accessToken,
  }) async {
    final url = Uri.parse('$baseUrl/records/today/record');
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('오늘 기록 조회 실패');
    }
  }

  static Future<Map<String, dynamic>> getTodayStatus({
    required String accessToken,
  }) async {
    final url = Uri.parse('$baseUrl/records/today/status');
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('오늘 상태 조회 실패');
    }
  }

  static Future<Map<String, dynamic>> updateProfile({
    required String accessToken,
    String? nickname,
    String? password,
  }) async {
    final url = Uri.parse('$baseUrl/users/me');
    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode({
        if (nickname != null) 'nickname': nickname,
        if (password != null) 'password': password,
      }),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final errorBody = jsonDecode(response.body);
      throw Exception(errorBody['detail'] ?? '프로필 수정 실패');
    }
  }
} 