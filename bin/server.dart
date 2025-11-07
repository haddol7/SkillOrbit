import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_cors_headers/shelf_cors_headers.dart';
import '../lib/domain/services/llm_service.dart';
import '../lib/infra/repo_memory.dart';
import '../lib/server/handlers.dart';

/// SkillOrbit Project #3 - 서버 진입점
///
/// [책임]
/// - 환경변수에서 OPENAI_API_KEY 읽기
/// - 저장소/서비스 주입
/// - REST 라우트 바인딩
/// - HTTP 서버 기동
///
/// [실행]
/// $ export OPENAI_API_KEY=sk-xxxx  # Windows: set OPENAI_API_KEY=sk-xxxx
/// $ dart run bin/server.dart
///
/// [환경변수]
/// - OPENAI_API_KEY: 필수
/// - PORT: 선택 (기본값 8080)
/// - ROADMAPS_FILE: 선택 (파일 영속화 경로, 기본값 roadmaps.json)
void main() async {
  // 환경변수 읽기
  final apiKey = Platform.environment['OPENAI_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    print('[ERROR] OPENAI_API_KEY environment variable is required');
    print('');
    print('Usage:');
    print('  # Linux/Mac');
    print('  export OPENAI_API_KEY=sk-...');
    print('  dart run bin/server.dart');
    print('');
    print('  # Windows');
    print('  set OPENAI_API_KEY=sk-...');
    print('  dart run bin/server.dart');
    exit(1);
  }

  final portStr = Platform.environment['PORT'] ?? '8080';
  final port = int.tryParse(portStr) ?? 8080;

  final roadmapsFile = Platform.environment['ROADMAPS_FILE'] ?? 'roadmaps.json';

  print('┌─────────────────────────────────────────┐');
  print('│  SkillOrbit Project #3 Server           │');
  print('│  AI Roadmap Generation MVP              │');
  print('└─────────────────────────────────────────┘');
  print('');
  print('[INFO] Initializing server...');
  print('[INFO] API Key: ${_maskApiKey(apiKey)}');
  print('[INFO] Storage: InMemory + File ($roadmapsFile)');
  print('');

  // 의존성 주입
  final repository = InMemoryRoadmapRepository(
    filePath: roadmapsFile,
    persistToFile: true,
  );

  final llmService = LlmService(apiKey: apiKey);

  final handlers = RoadmapHandlers(
    repository: repository,
    llmService: llmService,
  );

  // 미들웨어 설정
  final handler = Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(corsHeaders())
      .addMiddleware(_errorHandler)
      .addHandler(handlers.router.call);

  // 서버 기동
  final server = await shelf_io.serve(handler, '0.0.0.0', port);

  print('┌─────────────────────────────────────────┐');
  print('│  Server listening on:                   │');
  print('│  http://localhost:$port                    │');
  print('└─────────────────────────────────────────┘');
  print('');
  print('[INFO] Press Ctrl+C to stop');
  print('');

  // Graceful shutdown
  ProcessSignal.sigint.watch().listen((signal) async {
    print('');
    print('[INFO] Shutting down...');
    await server.close(force: true);
    llmService.dispose();
    print('[INFO] Server stopped');
    exit(0);
  });
}

/// API 키 마스킹 (보안)
String _maskApiKey(String key) {
  if (key.length <= 10) return '***';
  return '${key.substring(0, 7)}...${key.substring(key.length - 4)}';
}

/// 전역 에러 핸들러 미들웨어
Middleware _errorHandler = (Handler innerHandler) {
  return (Request request) async {
    try {
      return await innerHandler(request);
    } catch (error, stackTrace) {
      print('[ERROR] Unhandled exception: $error');
      print(stackTrace);
      return Response.internalServerError(
        body: '{"ok": false, "error": {"code": "INTERNAL_ERROR", "message": "Internal server error"}}',
        headers: {'Content-Type': 'application/json'},
      );
    }
  };
};
