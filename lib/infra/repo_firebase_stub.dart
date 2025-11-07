import '../domain/models/roadmap.dart';
import '../domain/ports/roadmap_repository.dart';

/// FirestoreRoadmapRepository - Firestore 저장소 어댑터 (Stub)
///
/// [Project #4에서 구현 예정]
/// - Firebase Admin SDK 또는 cloud_firestore 패키지 사용
/// - Flutter 앱과 통합 시 Firebase Auth로 ownerId 매핑
///
/// [Firestore 컬렉션 구조 (제안)]
/// 1. 개인 로드맵:
///    - users/{uid}/roadmaps/{roadmapId}
///    - 보안 규칙: allow read, write: if request.auth.uid == uid;
///
/// 2. 공개 로드맵:
///    - public_roadmaps/{roadmapId}
///    - 보안 규칙:
///      - allow read: if resource.data.isPublic == true;
///      - allow write: if request.auth.uid == resource.data.ownerId;
///
/// [구현 TODO]
/// - [ ] Firebase Admin SDK 또는 cloud_firestore 패키지 추가
/// - [ ] Firebase 프로젝트 설정 (프로젝트 ID, 서비스 계정 등)
/// - [ ] Firestore 초기화 (initializeApp, Firestore.instance 등)
/// - [ ] findByOwnerId: users/{uid}/roadmaps 쿼리
/// - [ ] findById: users/{uid}/roadmaps/{id} 문서 조회
/// - [ ] save: Firestore set/update, isPublic=true면 public_roadmaps에도 복사
/// - [ ] delete: 문서 삭제, public_roadmaps에도 있다면 삭제
/// - [ ] findAllPublic: public_roadmaps 컬렉션 전체 조회
/// - [ ] findPublicById: public_roadmaps/{id} 문서 조회
/// - [ ] exists: 문서 존재 확인
///
/// [보안 규칙 예시 (firestore.rules)]
/// ```
/// rules_version = '2';
/// service cloud.firestore {
///   match /databases/{database}/documents {
///     // 개인 로드맵
///     match /users/{userId}/roadmaps/{roadmapId} {
///       allow read, write: if request.auth != null && request.auth.uid == userId;
///     }
///
///     // 공개 로드맵
///     match /public_roadmaps/{roadmapId} {
///       allow read: if resource.data.isPublic == true;
///       allow create, update: if request.auth != null && request.auth.uid == resource.data.ownerId;
///       allow delete: if request.auth != null && request.auth.uid == resource.data.ownerId;
///     }
///   }
/// }
/// ```
class FirestoreRoadmapRepository implements RoadmapRepository {
  // TODO: Firestore 인스턴스 추가
  // final FirebaseFirestore _firestore;

  FirestoreRoadmapRepository() {
    throw UnimplementedError(
      'FirestoreRoadmapRepository는 Project #4에서 구현 예정입니다.\n'
      '현재는 InMemoryRoadmapRepository를 사용하세요.',
    );
  }

  @override
  Future<List<Roadmap>> findByOwnerId(String ownerId) async {
    // TODO: users/{ownerId}/roadmaps 쿼리
    throw UnimplementedError();
  }

  @override
  Future<Roadmap?> findById(String id) async {
    // TODO: users/{ownerId}/roadmaps/{id} 문서 조회
    throw UnimplementedError();
  }

  @override
  Future<void> save(Roadmap roadmap) async {
    // TODO: users/{ownerId}/roadmaps/{id} set/update
    // TODO: isPublic=true면 public_roadmaps/{id}에도 복사
    throw UnimplementedError();
  }

  @override
  Future<void> delete(String id) async {
    // TODO: users/{ownerId}/roadmaps/{id} 삭제
    // TODO: public_roadmaps/{id} 삭제 (있다면)
    throw UnimplementedError();
  }

  @override
  Future<List<Roadmap>> findAllPublic() async {
    // TODO: public_roadmaps 컬렉션 전체 조회
    throw UnimplementedError();
  }

  @override
  Future<Roadmap?> findPublicById(String id) async {
    // TODO: public_roadmaps/{id} 문서 조회
    throw UnimplementedError();
  }

  @override
  Future<bool> exists(String id) async {
    // TODO: 문서 존재 확인
    throw UnimplementedError();
  }
}
