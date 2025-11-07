/// Node - 개별 학습 단계/마일스톤을 나타냄
///
/// status:
///   - locked: 아직 시작 불가
///   - active: 현재 진행 가능
///   - completed: 완료됨
class Node {
  final String id;
  final String title;
  final String description;
  final String status; // locked | active | completed

  const Node({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
  });

  /// JSON 직렬화
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'status': status,
      };

  /// JSON 역직렬화
  factory Node.fromJson(Map<String, dynamic> json) {
    return Node(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      status: json['status'] as String,
    );
  }

  /// 상태값 검증
  static bool isValidStatus(String status) {
    return ['locked', 'active', 'completed'].contains(status);
  }

  /// 복사 생성자
  Node copyWith({
    String? id,
    String? title,
    String? description,
    String? status,
  }) {
    return Node(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
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
          status == other.status;

  @override
  int get hashCode =>
      id.hashCode ^ title.hashCode ^ description.hashCode ^ status.hashCode;
}
