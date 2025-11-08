import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/node.dart';
import '../models/roadmap.dart';

/// LlmService - OpenAI Chat Completions API 호출 서비스
///
/// [보안]
/// - API 키는 환경변수 OPENAI_API_KEY에서만 읽음
/// - 키/응답 전문은 로그에 출력하지 않음(마스킹)
///
/// [OpenAI API 스펙]
/// - 엔드포인트: POST https://api.openai.com/v1/chat/completions
/// - 헤더:
///   - Authorization: Bearer {API_KEY}
///   - content-type: application/json
/// - 모델: gpt-4 (또는 gpt-3.5-turbo)
class LlmService {
  static const String _apiUrl = 'https://api.openai.com/v1/chat/completions';
  static const String _model = 'gpt-3.5-turbo';
  static const int _maxTokens = 2500;
  static const int _maxRetries = 2;

  final String apiKey;
  final http.Client _httpClient;

  LlmService({required this.apiKey, http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  /// 로드맵 생성 프롬프트 템플릿
  static String _buildPrompt(String goal, int duration, String difficulty) {
    return '''
역할: 당신은 학습 로드맵 설계 전문가입니다.
입력: 사용자 목표(goal), 기간(duration: 2|4|8주), 난이도(difficulty: easy|medium|hard)
출력: 아래 JSON 스키마를 엄격히 준수하여 원형 스킬트리용 로드맵을 만듭니다.
형식: 반드시 JSON만 출력 (설명 텍스트 금지)

JSON 스키마:
{
  "title": "<로드맵 제목>",
  "duration": <2|4|8>,
  "difficulty": "<easy|medium|hard>",
  "progress": 0.0,
  "nodes": [
    {
      "id": "n1",
      "title": "핵심 주제/마일스톤",
      "description": "간단한 실행/학습 지시",
      "status": "locked",
      "ring": "inner|outer",
      "videos": [
        {
          "title": "동영상 제목",
          "url": "https://..."
        }
      ],
      "books": [
        {
          "title": "책/문서 제목",
          "url": "https://..."
        }
      ],
      "todos": [
        "구체적인 학습 과제 1",
        "구체적인 학습 과제 2"
      ]
    }
    // 총 12개 노드 (내부 링 4개, 외부 링 8개 권장)
  ]
}

제약:
- title/description은 사용자 goal 맥락을 반영
- 단계적으로 난이도를 높이고, 실습/평가를 포함
- status는 모두 "locked"으로 설정 (초기화는 서버에서 자동 처리)
- ring: 처음 4개 노드는 "inner" (핵심/기초), 나머지 8개는 "outer" (심화/응용)
- videos: 각 노드당 1-3개의 관련 동영상 링크 (YouTube, Udemy 등)
- books: 각 노드당 1-2개의 책/문서 링크 (공식 문서, 교재 등)
- todos: 각 노드당 2-4개의 구체적이고 실행 가능한 학습 과제
- 모든 URL은 실제 존재하는 유용한 학습 자료여야 함
- JSON 외 텍스트 출력 금지

사용자 입력:
- 목표: $goal
- 기간: $duration주
- 난이도: $difficulty

위 조건에 맞는 JSON 로드맵을 생성하세요.
''';
  }

  /// 로드맵 생성 요청
  ///
  /// [goal]: 사용자 목표
  /// [duration]: 기간 (2|4|8)
  /// [difficulty]: 난이도 (easy|medium|hard)
  /// [ownerId]: 소유자 ID
  ///
  /// 반환: 생성된 Roadmap 객체
  /// 예외: LlmException (API 오류, 파싱 실패 등)
  Future<Roadmap> generateRoadmap({
    required String goal,
    required int duration,
    required String difficulty,
    required String ownerId,
  }) async {
    // 입력 검증
    if (!Roadmap.isValidDuration(duration)) {
      throw LlmException('Invalid duration: $duration');
    }
    if (!Roadmap.isValidDifficulty(difficulty)) {
      throw LlmException('Invalid difficulty: $difficulty');
    }

    final prompt = _buildPrompt(goal, duration, difficulty);

    // 재시도 로직
    for (int attempt = 0; attempt <= _maxRetries; attempt++) {
      try {
        final jsonResponse = await _callOpenAiApi(prompt);
        final roadmap = _parseRoadmapFromJson(
          jsonResponse,
          ownerId: ownerId,
        );
        return roadmap;
      } catch (e) {
        if (attempt == _maxRetries) {
          rethrow;
        }
        print('[LlmService] Attempt ${attempt + 1} failed: $e. Retrying...');
        await Future<void>.delayed(Duration(seconds: attempt + 1));
      }
    }

    throw LlmException('Failed after $_maxRetries retries');
  }

  /// OpenAI Chat Completions API 호출
  Future<Map<String, dynamic>> _callOpenAiApi(String userMessage) async {
    final requestBody = {
      'model': _model,
      'messages': [
        {'role': 'user', 'content': userMessage}
      ],
      'max_tokens': _maxTokens,
      'temperature': 0.7,
    };

    try {
      final response = await _httpClient.post(
        Uri.parse(_apiUrl),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'content-type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        // choices[0].message.content 에서 JSON 추출
        final choices = data['choices'] as List;
        if (choices.isEmpty) {
          throw LlmException('Empty choices in API response');
        }
        final choice = choices[0] as Map<String, dynamic>;
        final message = choice['message'] as Map<String, dynamic>;
        final text = message['content'] as String;

        // JSON 파싱
        return _extractJsonFromText(text);
      } else if (response.statusCode >= 400 && response.statusCode < 500) {
        throw LlmException(
            'Client error ${response.statusCode}: ${response.body}');
      } else if (response.statusCode >= 500) {
        throw LlmException(
            'Server error ${response.statusCode}: ${response.body}');
      } else {
        throw LlmException('Unexpected status ${response.statusCode}');
      }
    } catch (e) {
      if (e is LlmException) rethrow;
      throw LlmException('HTTP request failed: $e');
    }
  }

  /// 텍스트에서 JSON 추출 (```json ... ``` 또는 {...} 형태)
  Map<String, dynamic> _extractJsonFromText(String text) {
    try {
      // 1. 마크다운 코드블럭 제거 시도
      final codeBlockPattern = RegExp(r'```(?:json)?\s*(\{.*?\})\s*```',
          dotAll: true, caseSensitive: false);
      final match = codeBlockPattern.firstMatch(text);
      if (match != null) {
        return jsonDecode(match.group(1)!) as Map<String, dynamic>;
      }

      // 2. 순수 JSON 파싱
      final trimmed = text.trim();
      if (trimmed.startsWith('{')) {
        return jsonDecode(trimmed) as Map<String, dynamic>;
      }

      // 3. {...} 패턴 검색
      final jsonPattern = RegExp(r'\{.*\}', dotAll: true);
      final jsonMatch = jsonPattern.firstMatch(text);
      if (jsonMatch != null) {
        return jsonDecode(jsonMatch.group(0)!) as Map<String, dynamic>;
      }

      throw LlmException('No valid JSON found in response text');
    } catch (e) {
      throw LlmException('JSON parsing failed: $e');
    }
  }

  /// LLM 응답 JSON → Roadmap 객체 변환
  Roadmap _parseRoadmapFromJson(
    Map<String, dynamic> json, {
    required String ownerId,
  }) {
    try {
      final title = json['title'] as String;
      final duration = json['duration'] as int;
      final difficulty = json['difficulty'] as String;
      final progress = (json['progress'] as num).toDouble();
      final nodesJson = json['nodes'] as List;

      // 노드 파싱 및 검증
      final nodes = nodesJson.map((nodeData) {
        final node = Node.fromJson(nodeData as Map<String, dynamic>);
        if (!Node.isValidStatus(node.status)) {
          throw LlmException('Invalid node status: ${node.status}');
        }
        if (!Node.isValidRing(node.ring)) {
          throw LlmException('Invalid node ring: ${node.ring}');
        }
        return node;
      }).toList();

      // 노드 수 권장 (최소 1개)
      if (nodes.isEmpty) {
        throw LlmException('No nodes in roadmap');
      }

      final roadmap = Roadmap(
        id: _generateId(),
        ownerId: ownerId,
        title: title,
        duration: duration,
        difficulty: difficulty,
        progress: progress,
        createdAt: DateTime.now(),
        nodes: nodes,
      );

      return roadmap;
    } catch (e) {
      throw LlmException('Failed to parse roadmap from JSON: $e');
    }
  }

  /// 간단한 ID 생성 (실제로는 uuid 사용 권장)
  String _generateId() {
    return 'r_${DateTime.now().millisecondsSinceEpoch}';
  }

  void dispose() {
    _httpClient.close();
  }
}

/// LLM 서비스 예외
class LlmException implements Exception {
  final String message;
  LlmException(this.message);

  @override
  String toString() => 'LlmException: $message';
}
