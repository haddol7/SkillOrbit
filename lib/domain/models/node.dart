/// VideoReference - 동영상 학습 자료 참조
class VideoReference {
  final String title;
  final String url;

  const VideoReference({
    required this.title,
    required this.url,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'url': url,
      };

  factory VideoReference.fromJson(Map<String, dynamic> json) {
    return VideoReference(
      title: json['title'] as String,
      url: json['url'] as String,
    );
  }
}

/// BookReference - 책/문서 학습 자료 참조
class BookReference {
  final String title;
  final String url;

  const BookReference({
    required this.title,
    required this.url,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'url': url,
      };

  factory BookReference.fromJson(Map<String, dynamic> json) {
    return BookReference(
      title: json['title'] as String,
      url: json['url'] as String,
    );
  }
}

/// Node - 개별 학습 단계/마일스톤을 나타냄
///
/// status:
///   - locked: 아직 시작 불가
///   - active: 현재 진행 가능
///   - completed: 완료됨
///
/// ring:
///   - inner: 내부 링 (핵심/기초)
///   - outer: 외부 링 (심화/응용)
class Node {
  final String id;
  final String title;
  final String description;
  final String status; // locked | active | completed
  final String ring; // inner | outer
  final List<VideoReference> videos;
  final List<BookReference> books;
  final List<String> todos;

  const Node({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    this.ring = 'outer',
    this.videos = const [],
    this.books = const [],
    this.todos = const [],
  });

  /// JSON 직렬화
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'status': status,
        'ring': ring,
        'videos': videos.map((v) => v.toJson()).toList(),
        'books': books.map((b) => b.toJson()).toList(),
        'todos': todos,
      };

  /// JSON 역직렬화
  factory Node.fromJson(Map<String, dynamic> json) {
    return Node(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      status: json['status'] as String,
      ring: json['ring'] as String? ?? 'outer',
      videos: (json['videos'] as List<dynamic>?)
              ?.map((v) => VideoReference.fromJson(v as Map<String, dynamic>))
              .toList() ??
          [],
      books: (json['books'] as List<dynamic>?)
              ?.map((b) => BookReference.fromJson(b as Map<String, dynamic>))
              .toList() ??
          [],
      todos: (json['todos'] as List<dynamic>?)
              ?.map((t) => t as String)
              .toList() ??
          [],
    );
  }

  /// 상태값 검증
  static bool isValidStatus(String status) {
    return ['locked', 'active', 'completed'].contains(status);
  }

  /// 링 위치 검증
  static bool isValidRing(String ring) {
    return ['inner', 'outer'].contains(ring);
  }

  /// 복사 생성자
  Node copyWith({
    String? id,
    String? title,
    String? description,
    String? status,
    String? ring,
    List<VideoReference>? videos,
    List<BookReference>? books,
    List<String>? todos,
  }) {
    return Node(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      ring: ring ?? this.ring,
      videos: videos ?? this.videos,
      books: books ?? this.books,
      todos: todos ?? this.todos,
    );
  }

  @override
  String toString() => 'Node(id: $id, title: $title, status: $status)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Node &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          description == other.description &&
          status == other.status &&
          ring == other.ring;

  @override
  int get hashCode =>
      id.hashCode ^
      title.hashCode ^
      description.hashCode ^
      status.hashCode ^
      ring.hashCode;
}
