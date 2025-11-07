import 'node.dart';

/// Roadmap - 학습 로드맵 전체를 나타냄
///
/// [데이터 저장 구조]
/// - InMemory: Map<String, Roadmap> 메모리 보관
/// - File: JSON 파일 {id: {...}} 형태
/// - Firestore(미래): users/{uid}/roadmaps/{id} + public_roadmaps/{id}
///
/// [책임 경계]
/// - 서버: LLM 호출, CRUD, 공유 로직
/// - CLI: 사용자 입력 → 서버 REST API 호출만
class Roadmap {
  final String id;
  final String ownerId; // Project #3에서는 "local" 등 고정값 사용
  final String title;
  final int duration; // 2 | 4 | 8 (주)
  final String difficulty; // easy | medium | hard
  final double progress; // 0.0 ~ 1.0
  final DateTime createdAt;
  final bool isPublic;
  final DateTime? sharedAt; // 공개 전환 시각
  final String? forkedFrom; // 포크한 원본 로드맵 ID
  final List<Node> nodes; // 내부 4 + 외부 8 (총 12개 권장)

  const Roadmap({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.duration,
    required this.difficulty,
    required this.progress,
    required this.createdAt,
    this.isPublic = false,
    this.sharedAt,
    this.forkedFrom,
    required this.nodes,
  });

  /// JSON 직렬화
  Map<String, dynamic> toJson() => {
        'id': id,
        'ownerId': ownerId,
        'title': title,
        'duration': duration,
        'difficulty': difficulty,
        'progress': progress,
        'createdAt': createdAt.toIso8601String(),
        'isPublic': isPublic,
        'sharedAt': sharedAt?.toIso8601String(),
        'forkedFrom': forkedFrom,
        'nodes': nodes.map((n) => n.toJson()).toList(),
      };

  /// JSON 역직렬화
  factory Roadmap.fromJson(Map<String, dynamic> json) {
    return Roadmap(
      id: json['id'] as String,
      ownerId: json['ownerId'] as String,
      title: json['title'] as String,
      duration: json['duration'] as int,
      difficulty: json['difficulty'] as String,
      progress: (json['progress'] as num).toDouble(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      isPublic: json['isPublic'] as bool? ?? false,
      sharedAt: json['sharedAt'] != null
          ? DateTime.parse(json['sharedAt'] as String)
          : null,
      forkedFrom: json['forkedFrom'] as String?,
      nodes: (json['nodes'] as List)
          .map((nodeJson) => Node.fromJson(nodeJson as Map<String, dynamic>))
          .toList(),
    );
  }

  /// 유효성 검증
  static bool isValidDuration(int duration) {
    return [2, 4, 8].contains(duration);
  }

  static bool isValidDifficulty(String difficulty) {
    return ['easy', 'medium', 'hard'].contains(difficulty);
  }

  /// 복사 생성자
  Roadmap copyWith({
    String? id,
    String? ownerId,
    String? title,
    int? duration,
    String? difficulty,
    double? progress,
    DateTime? createdAt,
    bool? isPublic,
    DateTime? sharedAt,
    String? forkedFrom,
    List<Node>? nodes,
  }) {
    return Roadmap(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      title: title ?? this.title,
      duration: duration ?? this.duration,
      difficulty: difficulty ?? this.difficulty,
      progress: progress ?? this.progress,
      createdAt: createdAt ?? this.createdAt,
      isPublic: isPublic ?? this.isPublic,
      sharedAt: sharedAt ?? this.sharedAt,
      forkedFrom: forkedFrom ?? this.forkedFrom,
      nodes: nodes ?? this.nodes,
    );
  }

  @override
  String toString() =>
      'Roadmap(id: $id, title: $title, duration: ${duration}w, difficulty: $difficulty, public: $isPublic)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Roadmap && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
