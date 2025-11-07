import '../models/roadmap.dart';

/// RoadmapRepository - 저장소 Port(인터페이스)
///
/// [포트/어댑터 패턴]
/// - Port: 도메인 계층의 저장소 요구사항 정의(이 파일)
/// - Adapter: 실제 구현체
///   - InMemoryRoadmapRepository (개발/테스트)
///   - FileRoadmapRepository (로컬 영속화)
///   - FirestoreRoadmapRepository (Project #4, 프로덕션)
///
/// [Firebase 전환 준비]
/// - Project #4에서 이 인터페이스 구현만 교체하면 됨
/// - 핸들러/서비스 코드는 변경 불필요
abstract class RoadmapRepository {
  /// 내 로드맵 목록 조회
  /// [ownerId]: 소유자 ID (Project #3: "local")
  Future<List<Roadmap>> findByOwnerId(String ownerId);

  /// 로드맵 단건 조회
  /// [id]: 로드맵 ID
  /// 없으면 null 반환
  Future<Roadmap?> findById(String id);

  /// 로드맵 저장 (생성 또는 업데이트)
  /// [roadmap]: 저장할 로드맵
  Future<void> save(Roadmap roadmap);

  /// 로드맵 삭제
  /// [id]: 삭제할 로드맵 ID
  Future<void> delete(String id);

  /// 공개(isPublic=true) 로드맵 전체 목록
  Future<List<Roadmap>> findAllPublic();

  /// 공개 로드맵 단건 조회
  /// [id]: 로드맵 ID
  /// isPublic=true인 경우만 반환, 아니면 null
  Future<Roadmap?> findPublicById(String id);

  /// ID 존재 여부 확인
  Future<bool> exists(String id);
}
