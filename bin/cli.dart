import 'dart:io';
import '../lib/cli/cli_service.dart';

/// SkillOrbit Project #3 - CLI 진입점
///
/// [책임]
/// - 명령어 파싱
/// - CLI 서비스 호출
/// - 서버 REST API를 통해 모든 작업 수행
///
/// [사용법]
/// $ dart run bin/cli.dart create              # 로드맵 생성
/// $ dart run bin/cli.dart list                # 내 로드맵 목록
/// $ dart run bin/cli.dart view <id>           # 로드맵 상세
/// $ dart run bin/cli.dart delete <id>         # 로드맵 삭제
/// $ dart run bin/cli.dart share <id>          # 로드맵 공개
/// $ dart run bin/cli.dart public              # 공개 로드맵 목록
/// $ dart run bin/cli.dart fork <id>           # 공개 로드맵 포크
///
/// [환경변수]
/// - SERVER_URL: 서버 주소 (기본값: http://localhost:8080)
void main(List<String> args) async {
  final serverUrl = Platform.environment['SERVER_URL'] ?? 'http://localhost:8080';
  final cliService = CliService(baseUrl: serverUrl);

  try {
    if (args.isEmpty) {
      _printUsage();
      exit(1);
    }

    final command = args[0];

    switch (command) {
      case 'create':
        await cliService.create();
        break;

      case 'list':
        await cliService.list();
        break;

      case 'view':
        if (args.length < 2) {
          print('[ERROR] Usage: dart run bin/cli.dart view <id>');
          exit(1);
        }
        await cliService.view(args[1]);
        break;

      case 'delete':
        if (args.length < 2) {
          print('[ERROR] Usage: dart run bin/cli.dart delete <id>');
          exit(1);
        }
        await cliService.delete(args[1]);
        break;

      case 'share':
        if (args.length < 2) {
          print('[ERROR] Usage: dart run bin/cli.dart share <id>');
          exit(1);
        }
        await cliService.share(args[1]);
        break;

      case 'public':
        await cliService.publicList();
        break;

      case 'fork':
        if (args.length < 2) {
          print('[ERROR] Usage: dart run bin/cli.dart fork <id>');
          exit(1);
        }
        await cliService.fork(args[1]);
        break;

      case 'help':
      case '--help':
      case '-h':
        _printUsage();
        break;

      default:
        print('[ERROR] Unknown command: $command');
        print('');
        _printUsage();
        exit(1);
    }
  } catch (e) {
    print('[ERROR] CLI error: $e');
    exit(1);
  } finally {
    cliService.dispose();
  }
}

void _printUsage() {
  print('┌─────────────────────────────────────────┐');
  print('│  SkillOrbit Project #3 CLI              │');
  print('│  AI Roadmap Generation                  │');
  print('└─────────────────────────────────────────┘');
  print('');
  print('사용법:');
  print('  dart run bin/cli.dart <command> [args]');
  print('');
  print('명령어:');
  print('  create               로드맵 생성 (LLM 호출)');
  print('  list                 내 로드맵 목록');
  print('  view <id>            로드맵 상세 조회');
  print('  delete <id>          로드맵 삭제');
  print('  share <id>           로드맵 공개 전환');
  print('  public               공개 로드맵 목록');
  print('  fork <id>            공개 로드맵 포크');
  print('  help                 이 메시지 표시');
  print('');
  print('환경변수:');
  print('  SERVER_URL           서버 주소 (기본: http://localhost:8080)');
  print('');
  print('예시:');
  print('  dart run bin/cli.dart create');
  print('  dart run bin/cli.dart list');
  print('  dart run bin/cli.dart view r_1234567890');
  print('  dart run bin/cli.dart share r_1234567890');
  print('  dart run bin/cli.dart public');
  print('  dart run bin/cli.dart fork r_9876543210');
  print('');
}
