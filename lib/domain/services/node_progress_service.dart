import '../models/node.dart';
import '../models/roadmap.dart';

/// NodeProgressService - 노드 진행 상태 관리 서비스
///
/// 비즈니스 규칙:
/// 1. 모든 inner 링 노드를 완료해야 outer 링 노드를 시작할 수 있음
/// 2. 노드는 locked → active → completed 순서로만 변경 가능
/// 3. 진행률은 completed 노드 수 / 전체 노드 수로 계산
class NodeProgressService {
  /// 노드를 활성화(시작) 가능한지 검증
  ///
  /// 규칙:
  /// - inner 링 노드: 항상 시작 가능 (locked 상태인 경우)
  /// - outer 링 노드: 모든 inner 링 노드가 completed여야 시작 가능
  static bool canStartNode(Roadmap roadmap, String nodeId) {
    final node = roadmap.nodes.firstWhere(
      (n) => n.id == nodeId,
      orElse: () => throw NodeProgressException('Node not found: $nodeId'),
    );

    // 이미 active이거나 completed인 경우
    if (node.status != 'locked') {
      return false;
    }

    // inner 링 노드는 항상 시작 가능
    if (node.ring == 'inner') {
      return true;
    }

    // outer 링 노드는 모든 inner 노드가 완료되어야 함
    final allInnerCompleted = roadmap.nodes
        .where((n) => n.ring == 'inner')
        .every((n) => n.status == 'completed');

    return allInnerCompleted;
  }

  /// 노드를 완료 가능한지 검증
  ///
  /// 규칙:
  /// - 노드가 active 상태여야 완료 가능
  static bool canCompleteNode(Roadmap roadmap, String nodeId) {
    final node = roadmap.nodes.firstWhere(
      (n) => n.id == nodeId,
      orElse: () => throw NodeProgressException('Node not found: $nodeId'),
    );

    return node.status == 'active';
  }

  /// 노드를 active 상태로 변경
  ///
  /// [roadmap]: 대상 로드맵
  /// [nodeId]: 시작할 노드 ID
  ///
  /// 반환: 업데이트된 Roadmap
  /// 예외: NodeProgressException (규칙 위반 시)
  static Roadmap startNode(Roadmap roadmap, String nodeId) {
    if (!canStartNode(roadmap, nodeId)) {
      final node = roadmap.nodes.firstWhere((n) => n.id == nodeId);
      if (node.ring == 'outer') {
        throw NodeProgressException(
          'Cannot start outer ring node. Complete all inner ring nodes first.',
        );
      }
      throw NodeProgressException(
        'Cannot start node $nodeId. Node must be in locked status.',
      );
    }

    final updatedNodes = roadmap.nodes.map((node) {
      if (node.id == nodeId) {
        return node.copyWith(status: 'active');
      }
      return node;
    }).toList();

    return roadmap.copyWith(
      nodes: updatedNodes,
      progress: _calculateProgress(updatedNodes),
    );
  }

  /// 노드를 completed 상태로 변경
  ///
  /// [roadmap]: 대상 로드맵
  /// [nodeId]: 완료할 노드 ID
  ///
  /// 반환: 업데이트된 Roadmap
  /// 예외: NodeProgressException (규칙 위반 시)
  static Roadmap completeNode(Roadmap roadmap, String nodeId) {
    if (!canCompleteNode(roadmap, nodeId)) {
      throw NodeProgressException(
        'Cannot complete node $nodeId. Node must be in active status.',
      );
    }

    final updatedNodes = roadmap.nodes.map((node) {
      if (node.id == nodeId) {
        return node.copyWith(status: 'completed');
      }
      return node;
    }).toList();

    return roadmap.copyWith(
      nodes: updatedNodes,
      progress: _calculateProgress(updatedNodes),
    );
  }

  /// 노드 상태를 초기화 (새 로드맵 생성 시 사용)
  ///
  /// 규칙:
  /// - 첫 번째 inner 링 노드만 active
  /// - 나머지는 모두 locked
  ///
  /// [roadmap]: 대상 로드맵
  /// 반환: 상태가 초기화된 Roadmap
  static Roadmap initializeNodeStatuses(Roadmap roadmap) {
    // inner 링 노드 찾기
    final innerNodes = roadmap.nodes.where((n) => n.ring == 'inner').toList();

    if (innerNodes.isEmpty) {
      throw NodeProgressException('No inner ring nodes found');
    }

    // 첫 번째 inner 노드의 ID
    final firstInnerNodeId = innerNodes.first.id;

    final updatedNodes = roadmap.nodes.map((node) {
      if (node.id == firstInnerNodeId) {
        return node.copyWith(status: 'active');
      } else {
        return node.copyWith(status: 'locked');
      }
    }).toList();

    return roadmap.copyWith(
      nodes: updatedNodes,
      progress: _calculateProgress(updatedNodes),
    );
  }

  /// 진행률 계산
  ///
  /// 공식: (completed 노드 수) / (전체 노드 수)
  static double _calculateProgress(List<Node> nodes) {
    if (nodes.isEmpty) return 0.0;

    final completedCount = nodes.where((n) => n.status == 'completed').length;
    return completedCount / nodes.length;
  }

  /// 로드맵의 현재 상태 요약 조회
  ///
  /// [roadmap]: 대상 로드맵
  /// 반환: 상태 요약 정보
  static ProgressSummary getProgressSummary(Roadmap roadmap) {
    final innerNodes = roadmap.nodes.where((n) => n.ring == 'inner').toList();
    final outerNodes = roadmap.nodes.where((n) => n.ring == 'outer').toList();

    final innerCompleted =
        innerNodes.where((n) => n.status == 'completed').length;
    final outerCompleted =
        outerNodes.where((n) => n.status == 'completed').length;

    final activeNodes = roadmap.nodes.where((n) => n.status == 'active').toList();
    final lockedNodes = roadmap.nodes.where((n) => n.status == 'locked').toList();

    return ProgressSummary(
      totalNodes: roadmap.nodes.length,
      completedNodes: innerCompleted + outerCompleted,
      activeNodes: activeNodes.length,
      lockedNodes: lockedNodes.length,
      innerRingProgress: innerNodes.isEmpty
          ? 0.0
          : innerCompleted / innerNodes.length,
      outerRingProgress: outerNodes.isEmpty
          ? 0.0
          : outerCompleted / outerNodes.length,
      overallProgress: roadmap.progress,
      canStartOuterRing: innerNodes.every((n) => n.status == 'completed'),
      activeNodeIds: activeNodes.map((n) => n.id).toList(),
    );
  }

  /// 다음에 시작 가능한 노드 목록 조회
  ///
  /// [roadmap]: 대상 로드맵
  /// 반환: 시작 가능한 노드 ID 목록
  static List<String> getAvailableNodes(Roadmap roadmap) {
    return roadmap.nodes
        .where((node) => canStartNode(roadmap, node.id))
        .map((node) => node.id)
        .toList();
  }
}

/// 진행 상태 요약 정보
class ProgressSummary {
  final int totalNodes;
  final int completedNodes;
  final int activeNodes;
  final int lockedNodes;
  final double innerRingProgress;
  final double outerRingProgress;
  final double overallProgress;
  final bool canStartOuterRing;
  final List<String> activeNodeIds;

  ProgressSummary({
    required this.totalNodes,
    required this.completedNodes,
    required this.activeNodes,
    required this.lockedNodes,
    required this.innerRingProgress,
    required this.outerRingProgress,
    required this.overallProgress,
    required this.canStartOuterRing,
    required this.activeNodeIds,
  });

  @override
  String toString() {
    return '''
Progress Summary:
  Total Nodes: $totalNodes
  Completed: $completedNodes
  Active: $activeNodes
  Locked: $lockedNodes

  Inner Ring Progress: ${(innerRingProgress * 100).toStringAsFixed(1)}%
  Outer Ring Progress: ${(outerRingProgress * 100).toStringAsFixed(1)}%
  Overall Progress: ${(overallProgress * 100).toStringAsFixed(1)}%

  Can Start Outer Ring: ${canStartOuterRing ? 'Yes' : 'No'}
  Active Node IDs: ${activeNodeIds.join(', ')}
''';
  }
}

/// 노드 진행 관련 예외
class NodeProgressException implements Exception {
  final String message;
  NodeProgressException(this.message);

  @override
  String toString() => 'NodeProgressException: $message';
}
