import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../domain/ports/roadmap_repository.dart';
import '../domain/services/llm_service.dart';
import '../domain/services/node_progress_service.dart';
import 'dto.dart';

/// [기능 명확성 - C 등급 반영]
/// REST API 라우팅 및 핸들러
///
/// [엔드포인트]
/// - GET    /roadmaps                  내 로드맵 목록
/// - GET    /roadmaps/:id              로드맵 단건 조회
/// - POST   /roadmaps                  로드맵 생성 (LLM 호출)
/// - DELETE /roadmaps/:id              로드맵 삭제
/// - POST   /roadmaps/:id/share        공개 전환
/// - GET    /public                    공개 로드맵 목록
/// - GET    /public/:id                공개 로드맵 단건 조회
/// - POST   /public/:id/fork           공개 로드맵 포크
/// - POST   /roadmaps/:id/nodes/:nodeId/start    노드 시작
/// - POST   /roadmaps/:id/nodes/:nodeId/complete 노드 완료
/// - GET    /roadmaps/:id/progress     진행 상태 조회
class RoadmapHandlers {
  final RoadmapRepository _repository;
  final LlmService _llmService;

  static const String _defaultOwnerId = 'local'; // Project #3 임시 소유자

  RoadmapHandlers({
    required RoadmapRepository repository,
    required LlmService llmService,
  })  : _repository = repository,
        _llmService = llmService;

  Router get router {
    final router = Router();

    // 내 로드맵 관련
    router.get('/roadmaps', _listRoadmaps);
    router.get('/roadmaps/<id>', _getRoadmap);
    router.post('/roadmaps', _createRoadmap);
    router.delete('/roadmaps/<id>', _deleteRoadmap);
    router.post('/roadmaps/<id>/share', _shareRoadmap);

    // 노드 진행 관련
    router.post('/roadmaps/<id>/nodes/<nodeId>/start', _startNode);
    router.post('/roadmaps/<id>/nodes/<nodeId>/complete', _completeNode);
    router.get('/roadmaps/<id>/progress', _getProgress);

    // 공개 로드맵 관련
    router.get('/public', _listPublicRoadmaps);
    router.get('/public/<id>', _getPublicRoadmap);
    router.post('/public/<id>/fork', _forkRoadmap);

    return router;
  }

  /// GET /roadmaps - 내 로드맵 목록
  Future<Response> _listRoadmaps(Request request) async {
    try {
      final roadmaps = await _repository.findByOwnerId(_defaultOwnerId);
      final summaries =
          roadmaps.map((r) => RoadmapSummary.fromRoadmap(r)).toList();
      final response = ApiResponse.success(RoadmapListResponse(summaries).toJson());

      return Response.ok(
        response.toJsonString(),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('[Handler] Error listing roadmaps: $e');
      final response = ApiResponse.failure(
        ApiError.internalError('Failed to list roadmaps: $e'),
      );
      return Response.internalServerError(
        body: response.toJsonString(),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  /// GET /roadmaps/:id - 로드맵 단건 조회
  Future<Response> _getRoadmap(Request request, String id) async {
    try {
      final roadmap = await _repository.findById(id);
      if (roadmap == null) {
        final response = ApiResponse.failure(
          ApiError.notFound('Roadmap not found: $id'),
        );
        return Response.notFound(
          response.toJsonString(),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // 소유자 확인 (현재는 모두 local이므로 체크 생략)
      final response = ApiResponse.success(RoadmapDetailResponse(roadmap).toJson());
      return Response.ok(
        response.toJsonString(),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('[Handler] Error getting roadmap: $e');
      final response = ApiResponse.failure(
        ApiError.internalError('Failed to get roadmap: $e'),
      );
      return Response.internalServerError(
        body: response.toJsonString(),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  /// POST /roadmaps - 로드맵 생성 (LLM 호출)
  Future<Response> _createRoadmap(Request request) async {
    try {
      // 요청 바디 파싱
      final body = await request.readAsString();
      final json = jsonDecode(body) as Map<String, dynamic>;
      final req = CreateRoadmapRequest.fromJson(json);

      // 유효성 검증
      final validationError = req.validate();
      if (validationError != null) {
        final response = ApiResponse.failure(
          ApiError.badRequest(validationError),
        );
        return Response.badRequest(
          body: response.toJsonString(),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final ownerId = req.ownerId ?? _defaultOwnerId;

      print('[Handler] Generating roadmap via LLM...');
      print('  Goal: ${req.goal}');
      print('  Duration: ${req.duration} weeks');
      print('  Difficulty: ${req.difficulty}');

      // LLM 호출
      final llmRoadmap = await _llmService.generateRoadmap(
        goal: req.goal,
        duration: req.duration,
        difficulty: req.difficulty,
        ownerId: ownerId,
      );

      // 노드 상태 초기화 (첫 번째 inner 노드만 active, 나머지는 locked)
      final roadmap = NodeProgressService.initializeNodeStatuses(llmRoadmap);

      // 저장
      await _repository.save(roadmap);

      print('[Handler] Roadmap created: ${roadmap.id}');

      final response = ApiResponse.success(
        CreateRoadmapResponse(
          id: roadmap.id,
          title: roadmap.title,
          message: 'Roadmap created successfully',
        ).toJson(),
      );

      return Response.ok(
        response.toJsonString(),
        headers: {'Content-Type': 'application/json'},
      );
    } on LlmException catch (e) {
      print('[Handler] LLM error: $e');
      final response = ApiResponse.failure(
        ApiError.internalError('LLM generation failed: ${e.message}'),
      );
      return Response.internalServerError(
        body: response.toJsonString(),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('[Handler] Error creating roadmap: $e');
      final response = ApiResponse.failure(
        ApiError.internalError('Failed to create roadmap: $e'),
      );
      return Response.internalServerError(
        body: response.toJsonString(),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  /// DELETE /roadmaps/:id - 로드맵 삭제
  Future<Response> _deleteRoadmap(Request request, String id) async {
    try {
      final roadmap = await _repository.findById(id);
      if (roadmap == null) {
        final response = ApiResponse.failure(
          ApiError.notFound('Roadmap not found: $id'),
        );
        return Response.notFound(
          response.toJsonString(),
          headers: {'Content-Type': 'application/json'},
        );
      }

      await _repository.delete(id);

      final response = ApiResponse.success(
        DeleteRoadmapResponse(
          id: id,
          message: 'Roadmap deleted successfully',
        ).toJson(),
      );

      return Response.ok(
        response.toJsonString(),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('[Handler] Error deleting roadmap: $e');
      final response = ApiResponse.failure(
        ApiError.internalError('Failed to delete roadmap: $e'),
      );
      return Response.internalServerError(
        body: response.toJsonString(),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  /// POST /roadmaps/:id/share - 공개 전환
  Future<Response> _shareRoadmap(Request request, String id) async {
    try {
      final roadmap = await _repository.findById(id);
      if (roadmap == null) {
        final response = ApiResponse.failure(
          ApiError.notFound('Roadmap not found: $id'),
        );
        return Response.notFound(
          response.toJsonString(),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // 이미 공개된 경우
      if (roadmap.isPublic) {
        final response = ApiResponse.success(
          ShareRoadmapResponse(
            id: id,
            isPublic: true,
            sharedAt: roadmap.sharedAt!,
            message: 'Roadmap is already public',
          ).toJson(),
        );
        return Response.ok(
          response.toJsonString(),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // 공개 전환
      final now = DateTime.now();
      final updatedRoadmap = roadmap.copyWith(
        isPublic: true,
        sharedAt: now,
      );
      await _repository.save(updatedRoadmap);

      print('[Handler] Roadmap shared: $id');

      final response = ApiResponse.success(
        ShareRoadmapResponse(
          id: id,
          isPublic: true,
          sharedAt: now,
          message: 'Roadmap is now public',
        ).toJson(),
      );

      return Response.ok(
        response.toJsonString(),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('[Handler] Error sharing roadmap: $e');
      final response = ApiResponse.failure(
        ApiError.internalError('Failed to share roadmap: $e'),
      );
      return Response.internalServerError(
        body: response.toJsonString(),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  /// GET /public - 공개 로드맵 목록
  Future<Response> _listPublicRoadmaps(Request request) async {
    try {
      final roadmaps = await _repository.findAllPublic();
      final summaries =
          roadmaps.map((r) => RoadmapSummary.fromRoadmap(r)).toList();
      final response = ApiResponse.success(RoadmapListResponse(summaries).toJson());

      return Response.ok(
        response.toJsonString(),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('[Handler] Error listing public roadmaps: $e');
      final response = ApiResponse.failure(
        ApiError.internalError('Failed to list public roadmaps: $e'),
      );
      return Response.internalServerError(
        body: response.toJsonString(),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  /// GET /public/:id - 공개 로드맵 단건 조회
  Future<Response> _getPublicRoadmap(Request request, String id) async {
    try {
      final roadmap = await _repository.findPublicById(id);
      if (roadmap == null) {
        final response = ApiResponse.failure(
          ApiError.notFound('Public roadmap not found: $id'),
        );
        return Response.notFound(
          response.toJsonString(),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final response = ApiResponse.success(RoadmapDetailResponse(roadmap).toJson());
      return Response.ok(
        response.toJsonString(),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('[Handler] Error getting public roadmap: $e');
      final response = ApiResponse.failure(
        ApiError.internalError('Failed to get public roadmap: $e'),
      );
      return Response.internalServerError(
        body: response.toJsonString(),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  /// POST /public/:id/fork - 공개 로드맵 포크
  Future<Response> _forkRoadmap(Request request, String id) async {
    try {
      final originalRoadmap = await _repository.findPublicById(id);
      if (originalRoadmap == null) {
        final response = ApiResponse.failure(
          ApiError.notFound('Public roadmap not found: $id'),
        );
        return Response.notFound(
          response.toJsonString(),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // 새 로드맵 생성 (forkedFrom 설정)
      final newId = 'r_${DateTime.now().millisecondsSinceEpoch}';
      final forkedRoadmap = originalRoadmap.copyWith(
        id: newId,
        ownerId: _defaultOwnerId,
        isPublic: false,
        sharedAt: null,
        forkedFrom: id,
        createdAt: DateTime.now(),
      );

      await _repository.save(forkedRoadmap);

      print('[Handler] Roadmap forked: $id -> $newId');

      final response = ApiResponse.success(
        ForkRoadmapResponse(
          newId: newId,
          originalId: id,
          title: forkedRoadmap.title,
          message: 'Roadmap forked successfully',
        ).toJson(),
      );

      return Response.ok(
        response.toJsonString(),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('[Handler] Error forking roadmap: $e');
      final response = ApiResponse.failure(
        ApiError.internalError('Failed to fork roadmap: $e'),
      );
      return Response.internalServerError(
        body: response.toJsonString(),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  /// POST /roadmaps/:id/nodes/:nodeId/start - 노드 시작
  Future<Response> _startNode(Request request, String id, String nodeId) async {
    try {
      final roadmap = await _repository.findById(id);
      if (roadmap == null) {
        final response = ApiResponse.failure(
          ApiError.notFound('Roadmap not found: $id'),
        );
        return Response.notFound(
          response.toJsonString(),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // 노드 시작 시도
      final updatedRoadmap = NodeProgressService.startNode(roadmap, nodeId);
      await _repository.save(updatedRoadmap);

      print('[Handler] Node started: $id -> $nodeId');

      final response = ApiResponse.success(
        NodeProgressResponse(
          roadmapId: id,
          nodeId: nodeId,
          status: 'active',
          progress: updatedRoadmap.progress,
          message: 'Node started successfully',
        ).toJson(),
      );

      return Response.ok(
        response.toJsonString(),
        headers: {'Content-Type': 'application/json'},
      );
    } on NodeProgressException catch (e) {
      print('[Handler] Node progress error: $e');
      final response = ApiResponse.failure(
        ApiError.badRequest(e.message),
      );
      return Response.badRequest(
        body: response.toJsonString(),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('[Handler] Error starting node: $e');
      final response = ApiResponse.failure(
        ApiError.internalError('Failed to start node: $e'),
      );
      return Response.internalServerError(
        body: response.toJsonString(),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  /// POST /roadmaps/:id/nodes/:nodeId/complete - 노드 완료
  Future<Response> _completeNode(
      Request request, String id, String nodeId) async {
    try {
      final roadmap = await _repository.findById(id);
      if (roadmap == null) {
        final response = ApiResponse.failure(
          ApiError.notFound('Roadmap not found: $id'),
        );
        return Response.notFound(
          response.toJsonString(),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // 노드 완료 시도
      final updatedRoadmap = NodeProgressService.completeNode(roadmap, nodeId);
      await _repository.save(updatedRoadmap);

      print('[Handler] Node completed: $id -> $nodeId');

      // 다음 시작 가능한 노드 조회
      final availableNodes = NodeProgressService.getAvailableNodes(updatedRoadmap);

      final responseData = NodeProgressResponse(
        roadmapId: id,
        nodeId: nodeId,
        status: 'completed',
        progress: updatedRoadmap.progress,
        message: 'Node completed successfully',
        availableNodes: availableNodes.isNotEmpty ? availableNodes : null,
      ).toJson();

      final response = ApiResponse.success(responseData);

      return Response.ok(
        response.toJsonString(),
        headers: {'Content-Type': 'application/json'},
      );
    } on NodeProgressException catch (e) {
      print('[Handler] Node progress error: $e');
      final response = ApiResponse.failure(
        ApiError.badRequest(e.message),
      );
      return Response.badRequest(
        body: response.toJsonString(),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('[Handler] Error completing node: $e');
      final response = ApiResponse.failure(
        ApiError.internalError('Failed to complete node: $e'),
      );
      return Response.internalServerError(
        body: response.toJsonString(),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  /// GET /roadmaps/:id/progress - 진행 상태 조회
  Future<Response> _getProgress(Request request, String id) async {
    try {
      final roadmap = await _repository.findById(id);
      if (roadmap == null) {
        final response = ApiResponse.failure(
          ApiError.notFound('Roadmap not found: $id'),
        );
        return Response.notFound(
          response.toJsonString(),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // 진행 상태 요약 조회
      final summary = NodeProgressService.getProgressSummary(roadmap);
      final availableNodes = NodeProgressService.getAvailableNodes(roadmap);

      final responseData = ProgressSummaryResponse(
        roadmapId: id,
        title: roadmap.title,
        totalNodes: summary.totalNodes,
        completedNodes: summary.completedNodes,
        activeNodes: summary.activeNodes,
        lockedNodes: summary.lockedNodes,
        innerRingProgress: summary.innerRingProgress,
        outerRingProgress: summary.outerRingProgress,
        overallProgress: summary.overallProgress,
        canStartOuterRing: summary.canStartOuterRing,
        activeNodeIds: summary.activeNodeIds,
        availableNodes: availableNodes,
      ).toJson();

      final response = ApiResponse.success(responseData);

      return Response.ok(
        response.toJsonString(),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('[Handler] Error getting progress: $e');
      final response = ApiResponse.failure(
        ApiError.internalError('Failed to get progress: $e'),
      );
      return Response.internalServerError(
        body: response.toJsonString(),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }
}
