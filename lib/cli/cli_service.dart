import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// CliService - CLI 명령 실행 로직 (서버 REST 호출)
///
/// [책임]
/// - 사용자 입력 수집
/// - 서버 REST API 호출
/// - 응답 포맷팅 및 출력
///
/// [보안]
/// - CLI는 LLM을 직접 호출하지 않음
/// - 모든 로직은 서버를 통해 처리
class CliService {
  final String baseUrl;
  final http.Client _httpClient;

  CliService({
    required this.baseUrl,
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  /// create: 로드맵 생성
  Future<void> create() async {
    try {
      print('┌─────────────────────────────────────────┐');
      print('│  로드맵 생성                            │');
      print('└─────────────────────────────────────────┘');
      print('');

      // 사용자 입력
      stdout.write('목표를 입력하세요: ');
      final goal = stdin.readLineSync() ?? '';
      if (goal.trim().isEmpty) {
        print('[ERROR] 목표는 필수입니다.');
        return;
      }

      stdout.write('기간을 선택하세요 (2/4/8주): ');
      final durationStr = stdin.readLineSync() ?? '';
      final duration = int.tryParse(durationStr);
      if (duration == null || ![2, 4, 8].contains(duration)) {
        print('[ERROR] 기간은 2, 4, 또는 8이어야 합니다.');
        return;
      }

      stdout.write('난이도를 선택하세요 (easy/medium/hard): ');
      final difficulty = stdin.readLineSync() ?? '';
      if (!['easy', 'medium', 'hard'].contains(difficulty)) {
        print('[ERROR] 난이도는 easy, medium, 또는 hard여야 합니다.');
        return;
      }

      print('');
      print('[INFO] 로드맵 생성 중... (ChatGPT API 호출, 최대 30초 소요)');
      print('');

      // 서버 요청
      final requestBody = {
        'goal': goal,
        'duration': duration,
        'difficulty': difficulty,
      };

      final response = await _httpClient
          .post(
        Uri.parse('$baseUrl/roadmaps'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      )
          .timeout(Duration(seconds: 60));

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && data['ok'] == true) {
        final result = data['data'] as Map<String, dynamic>;
        print('✓ 생성 완료!');
        print('');
        print('ID:    ${result['id']}');
        print('제목:  ${result['title']}');
        print('메시지: ${result['message']}');
      } else {
        final error = data['error'] as Map<String, dynamic>;
        print('[ERROR] ${error['code']}: ${error['message']}');
      }
    } catch (e) {
      print('[ERROR] 로드맵 생성 실패: $e');
    }
  }

  /// list: 내 로드맵 목록
  Future<void> list() async {
    try {
      final response = await _httpClient.get(Uri.parse('$baseUrl/roadmaps'));
      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && data['ok'] == true) {
        final result = data['data'] as Map<String, dynamic>;
        final roadmaps = result['roadmaps'] as List;

        print('┌─────────────────────────────────────────┐');
        print('│  내 로드맵 목록                         │');
        print('└─────────────────────────────────────────┘');
        print('');

        if (roadmaps.isEmpty) {
          print('로드맵이 없습니다.');
          return;
        }

        for (final roadmap in roadmaps) {
          final rm = roadmap as Map<String, dynamic>;
          print('ID:       ${rm['id']}');
          print('제목:     ${rm['title']}');
          print('기간:     ${rm['duration']}주');
          print('난이도:   ${rm['difficulty']}');
          print('진행률:   ${(rm['progress'] * 100).toStringAsFixed(0)}%');
          print('공개:     ${rm['isPublic'] ? 'Yes' : 'No'}');
          print('생성일:   ${rm['createdAt']}');
          print('─────────────────────────────────────────');
        }
      } else {
        final error = data['error'] as Map<String, dynamic>;
        print('[ERROR] ${error['code']}: ${error['message']}');
      }
    } catch (e) {
      print('[ERROR] 목록 조회 실패: $e');
    }
  }

  /// view: 로드맵 상세 조회
  Future<void> view(String id) async {
    try {
      final response = await _httpClient.get(Uri.parse('$baseUrl/roadmaps/$id'));
      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && data['ok'] == true) {
        final roadmap = data['data'] as Map<String, dynamic>;

        print('┌─────────────────────────────────────────┐');
        print('│  로드맵 상세                            │');
        print('└─────────────────────────────────────────┘');
        print('');
        print('ID:           ${roadmap['id']}');
        print('제목:         ${roadmap['title']}');
        print('기간:         ${roadmap['duration']}주');
        print('난이도:       ${roadmap['difficulty']}');
        print('진행률:       ${(roadmap['progress'] * 100).toStringAsFixed(0)}%');
        print('공개:         ${roadmap['isPublic'] ? 'Yes' : 'No'}');
        print('생성일:       ${roadmap['createdAt']}');
        if (roadmap['forkedFrom'] != null) {
          print('포크 원본:    ${roadmap['forkedFrom']}');
        }
        print('');
        print('노드 목록:');
        final nodes = roadmap['nodes'] as List;
        for (int i = 0; i < nodes.length; i++) {
          final node = nodes[i] as Map<String, dynamic>;
          print('  ${i + 1}. [${node['status']}] ${node['title']}');
          print('     ${node['description']}');
        }
      } else {
        final error = data['error'] as Map<String, dynamic>;
        print('[ERROR] ${error['code']}: ${error['message']}');
      }
    } catch (e) {
      print('[ERROR] 조회 실패: $e');
    }
  }

  /// delete: 로드맵 삭제
  Future<void> delete(String id) async {
    try {
      stdout.write('정말로 삭제하시겠습니까? (y/N): ');
      final confirm = stdin.readLineSync() ?? '';
      if (confirm.toLowerCase() != 'y') {
        print('취소되었습니다.');
        return;
      }

      final response = await _httpClient.delete(Uri.parse('$baseUrl/roadmaps/$id'));
      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && data['ok'] == true) {
        final result = data['data'] as Map<String, dynamic>;
        print('✓ ${result['message']}');
      } else {
        final error = data['error'] as Map<String, dynamic>;
        print('[ERROR] ${error['code']}: ${error['message']}');
      }
    } catch (e) {
      print('[ERROR] 삭제 실패: $e');
    }
  }

  /// share: 로드맵 공개 전환
  Future<void> share(String id) async {
    try {
      final response = await _httpClient.post(
        Uri.parse('$baseUrl/roadmaps/$id/share'),
        headers: {'Content-Type': 'application/json'},
      );
      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && data['ok'] == true) {
        final result = data['data'] as Map<String, dynamic>;
        print('✓ ${result['message']}');
        print('');
        print('ID:        ${result['id']}');
        print('공개 상태: ${result['isPublic'] ? 'Public' : 'Private'}');
        print('공개 일시: ${result['sharedAt']}');
      } else {
        final error = data['error'] as Map<String, dynamic>;
        print('[ERROR] ${error['code']}: ${error['message']}');
      }
    } catch (e) {
      print('[ERROR] 공개 전환 실패: $e');
    }
  }

  /// public: 공개 로드맵 목록
  Future<void> publicList() async {
    try {
      final response = await _httpClient.get(Uri.parse('$baseUrl/public'));
      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && data['ok'] == true) {
        final result = data['data'] as Map<String, dynamic>;
        final roadmaps = result['roadmaps'] as List;

        print('┌─────────────────────────────────────────┐');
        print('│  공개 로드맵 목록                       │');
        print('└─────────────────────────────────────────┘');
        print('');

        if (roadmaps.isEmpty) {
          print('공개 로드맵이 없습니다.');
          return;
        }

        for (final roadmap in roadmaps) {
          final rm = roadmap as Map<String, dynamic>;
          print('ID:       ${rm['id']}');
          print('제목:     ${rm['title']}');
          print('기간:     ${rm['duration']}주');
          print('난이도:   ${rm['difficulty']}');
          print('진행률:   ${(rm['progress'] * 100).toStringAsFixed(0)}%');
          print('생성일:   ${rm['createdAt']}');
          print('─────────────────────────────────────────');
        }
      } else {
        final error = data['error'] as Map<String, dynamic>;
        print('[ERROR] ${error['code']}: ${error['message']}');
      }
    } catch (e) {
      print('[ERROR] 공개 목록 조회 실패: $e');
    }
  }

  /// fork: 공개 로드맵 포크
  Future<void> fork(String id) async {
    try {
      print('[INFO] 로드맵 포크 중...');

      final response = await _httpClient.post(
        Uri.parse('$baseUrl/public/$id/fork'),
        headers: {'Content-Type': 'application/json'},
      );
      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && data['ok'] == true) {
        final result = data['data'] as Map<String, dynamic>;
        print('✓ ${result['message']}');
        print('');
        print('새 ID:     ${result['newId']}');
        print('원본 ID:   ${result['originalId']}');
        print('제목:      ${result['title']}');
      } else {
        final error = data['error'] as Map<String, dynamic>;
        print('[ERROR] ${error['code']}: ${error['message']}');
      }
    } catch (e) {
      print('[ERROR] 포크 실패: $e');
    }
  }

  void dispose() {
    _httpClient.close();
  }
}
