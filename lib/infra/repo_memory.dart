import 'dart:convert';
import 'dart:io';
import '../domain/models/roadmap.dart';
import '../domain/ports/roadmap_repository.dart';

/// InMemoryRoadmapRepository - 메모리/파일 기반 저장소 어댑터
///
/// [저장 방식]
/// - 메모리: Map<String, Roadmap> _store
/// - 파일(선택): roadmaps.json 파일에 {id: {...}} 형태로 저장
///
/// [Project #4 전환 준비]
/// - RoadmapRepository 인터페이스 구현
/// - Firestore 어댑터로 교체 시 핸들러 코드 변경 불필요
class InMemoryRoadmapRepository implements RoadmapRepository {
  final Map<String, Roadmap> _store = {};
  final String? _filePath;
  final bool _persistToFile;

  InMemoryRoadmapRepository({
    String? filePath,
    bool persistToFile = false,
  })  : _filePath = filePath,
        _persistToFile = persistToFile {
    if (_persistToFile && _filePath != null) {
      _loadFromFile();
    }
  }

  @override
  Future<List<Roadmap>> findByOwnerId(String ownerId) async {
    return _store.values.where((r) => r.ownerId == ownerId).toList();
  }

  @override
  Future<Roadmap?> findById(String id) async {
    return _store[id];
  }

  @override
  Future<void> save(Roadmap roadmap) async {
    _store[roadmap.id] = roadmap;
    if (_persistToFile) {
      await _saveToFile();
    }
  }

  @override
  Future<void> delete(String id) async {
    _store.remove(id);
    if (_persistToFile) {
      await _saveToFile();
    }
  }

  @override
  Future<List<Roadmap>> findAllPublic() async {
    return _store.values.where((r) => r.isPublic).toList();
  }

  @override
  Future<Roadmap?> findPublicById(String id) async {
    final roadmap = _store[id];
    if (roadmap != null && roadmap.isPublic) {
      return roadmap;
    }
    return null;
  }

  @override
  Future<bool> exists(String id) async {
    return _store.containsKey(id);
  }

  /// 파일에서 로드
  void _loadFromFile() {
    if (_filePath == null) return;

    try {
      final file = File(_filePath!);
      if (!file.existsSync()) {
        print('[Repo] File not found, starting with empty store: $_filePath');
        return;
      }

      final content = file.readAsStringSync();
      if (content.trim().isEmpty) {
        print('[Repo] File is empty: $_filePath');
        return;
      }

      final data = jsonDecode(content) as Map<String, dynamic>;
      for (final entry in data.entries) {
        final roadmap = Roadmap.fromJson(entry.value as Map<String, dynamic>);
        _store[entry.key] = roadmap;
      }

      print('[Repo] Loaded ${_store.length} roadmaps from file');
    } catch (e) {
      print('[Repo] Failed to load from file: $e');
    }
  }

  /// 파일에 저장
  Future<void> _saveToFile() async {
    if (_filePath == null) return;

    try {
      final file = File(_filePath!);
      final data = <String, dynamic>{};
      for (final entry in _store.entries) {
        data[entry.key] = entry.value.toJson();
      }

      final jsonStr = JsonEncoder.withIndent('  ').convert(data);
      await file.writeAsString(jsonStr);
    } catch (e) {
      print('[Repo] Failed to save to file: $e');
    }
  }

  /// 테스트/개발용: 전체 데이터 클리어
  Future<void> clear() async {
    _store.clear();
    if (_persistToFile) {
      await _saveToFile();
    }
  }

  /// 디버깅용: 전체 데이터 출력
  void printAll() {
    print('[Repo] Total roadmaps: ${_store.length}');
    for (final roadmap in _store.values) {
      print('  - ${roadmap.id}: ${roadmap.title} (public: ${roadmap.isPublic})');
    }
  }
}
