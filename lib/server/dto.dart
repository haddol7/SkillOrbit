import 'dart:convert';
import '../domain/models/roadmap.dart';

/// [정보 교환 명확성 - B 등급 반영]
/// REST API 요청/응답 DTO 및 에러 포맷 정의
///
/// [표준 응답 포맷]
/// {
///   "ok": true/false,
///   "data": {...},       // 성공 시
///   "error": {           // 실패 시
///     "code": "NOT_FOUND",
///     "message": "Roadmap not found"
///   }
/// }

/// 표준 API 응답
class ApiResponse {
  final bool ok;
  final dynamic data;
  final ApiError? error;

  ApiResponse.success(this.data)
      : ok = true,
        error = null;

  ApiResponse.failure(this.error)
      : ok = false,
        data = null;

  Map<String, dynamic> toJson() {
    if (ok) {
      return {
        'ok': true,
        'data': data,
      };
    } else {
      return {
        'ok': false,
        'error': error?.toJson(),
      };
    }
  }

  String toJsonString() => jsonEncode(toJson());
}

/// API 에러
class ApiError {
  final String code;
  final String message;

  const ApiError({
    required this.code,
    required this.message,
  });

  Map<String, dynamic> toJson() => {
        'code': code,
        'message': message,
      };

  @override
  String toString() => 'ApiError($code: $message)';

  // 미리 정의된 에러들
  static ApiError notFound(String message) =>
      ApiError(code: 'NOT_FOUND', message: message);

  static ApiError badRequest(String message) =>
      ApiError(code: 'BAD_REQUEST', message: message);

  static ApiError internalError(String message) =>
      ApiError(code: 'INTERNAL_ERROR', message: message);

  static ApiError unauthorized(String message) =>
      ApiError(code: 'UNAUTHORIZED', message: message);

  static ApiError forbidden(String message) =>
      ApiError(code: 'FORBIDDEN', message: message);
}

/// POST /roadmaps 요청 DTO
class CreateRoadmapRequest {
  final String goal;
  final int duration; // 2 | 4 | 8
  final String difficulty; // easy | medium | hard
  final String? ownerId; // 선택적, 없으면 "local" 사용

  const CreateRoadmapRequest({
    required this.goal,
    required this.duration,
    required this.difficulty,
    this.ownerId,
  });

  factory CreateRoadmapRequest.fromJson(Map<String, dynamic> json) {
    return CreateRoadmapRequest(
      goal: json['goal'] as String,
      duration: json['duration'] as int,
      difficulty: json['difficulty'] as String,
      ownerId: json['ownerId'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'goal': goal,
        'duration': duration,
        'difficulty': difficulty,
        if (ownerId != null) 'ownerId': ownerId,
      };

  /// 유효성 검증
  String? validate() {
    if (goal.trim().isEmpty) {
      return 'goal is required';
    }
    if (![2, 4, 8].contains(duration)) {
      return 'duration must be 2, 4, or 8';
    }
    if (!['easy', 'medium', 'hard'].contains(difficulty)) {
      return 'difficulty must be easy, medium, or hard';
    }
    return null;
  }
}

/// POST /roadmaps 응답 DTO
class CreateRoadmapResponse {
  final String id;
  final String title;
  final String message;

  const CreateRoadmapResponse({
    required this.id,
    required this.title,
    required this.message,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'message': message,
      };
}

/// GET /roadmaps 응답 DTO (목록)
class RoadmapListResponse {
  final List<RoadmapSummary> roadmaps;

  const RoadmapListResponse(this.roadmaps);

  Map<String, dynamic> toJson() => {
        'roadmaps': roadmaps.map((r) => r.toJson()).toList(),
      };
}

/// 로드맵 요약 정보 (목록용)
class RoadmapSummary {
  final String id;
  final String title;
  final int duration;
  final String difficulty;
  final double progress;
  final bool isPublic;
  final DateTime createdAt;

  const RoadmapSummary({
    required this.id,
    required this.title,
    required this.duration,
    required this.difficulty,
    required this.progress,
    required this.isPublic,
    required this.createdAt,
  });

  factory RoadmapSummary.fromRoadmap(Roadmap roadmap) {
    return RoadmapSummary(
      id: roadmap.id,
      title: roadmap.title,
      duration: roadmap.duration,
      difficulty: roadmap.difficulty,
      progress: roadmap.progress,
      isPublic: roadmap.isPublic,
      createdAt: roadmap.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'duration': duration,
        'difficulty': difficulty,
        'progress': progress,
        'isPublic': isPublic,
        'createdAt': createdAt.toIso8601String(),
      };
}

/// GET /roadmaps/{id} 응답 DTO (상세)
class RoadmapDetailResponse {
  final Roadmap roadmap;

  const RoadmapDetailResponse(this.roadmap);

  Map<String, dynamic> toJson() => roadmap.toJson();
}

/// POST /roadmaps/{id}/share 응답 DTO
class ShareRoadmapResponse {
  final String id;
  final bool isPublic;
  final DateTime sharedAt;
  final String message;

  const ShareRoadmapResponse({
    required this.id,
    required this.isPublic,
    required this.sharedAt,
    required this.message,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'isPublic': isPublic,
        'sharedAt': sharedAt.toIso8601String(),
        'message': message,
      };
}

/// POST /public/{id}/fork 응답 DTO
class ForkRoadmapResponse {
  final String newId;
  final String originalId;
  final String title;
  final String message;

  const ForkRoadmapResponse({
    required this.newId,
    required this.originalId,
    required this.title,
    required this.message,
  });

  Map<String, dynamic> toJson() => {
        'newId': newId,
        'originalId': originalId,
        'title': title,
        'message': message,
      };
}

/// DELETE /roadmaps/{id} 응답 DTO
class DeleteRoadmapResponse {
  final String id;
  final String message;

  const DeleteRoadmapResponse({
    required this.id,
    required this.message,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'message': message,
      };
}
