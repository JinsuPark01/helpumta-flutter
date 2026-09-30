import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

enum GroupCreateStatus { initial, loading, success, failure }

class GroupCreateState extends Equatable {
  const GroupCreateState({
    this.name = '',
    this.description = '',
    this.imagePath,
    this.status = GroupCreateStatus.initial,
    this.createdGroupId,
    this.errorMessage,
  });

  final String name;
  final String description;
  final String? imagePath;
  final GroupCreateStatus status;

  /// 성공 시 홈에 돌려줄 그룹 ID
  final String? createdGroupId;

  /// 실패 시 스낵바 문구
  final String? errorMessage;

  bool get isLoading => status == GroupCreateStatus.loading;

  bool get isCreateEnabled => name.trim().isNotEmpty;

  GroupCreateState copyWith({
    String? name,
    String? description,
    ValueGetter<String?>? imagePath,
    GroupCreateStatus? status,
    ValueGetter<String?>? createdGroupId,
    ValueGetter<String?>? errorMessage,
  }) {
    return GroupCreateState(
      name: name ?? this.name,
      description: description ?? this.description,
      imagePath: imagePath != null ? imagePath() : this.imagePath,
      status: status ?? this.status,
      createdGroupId:
      createdGroupId != null ? createdGroupId() : this.createdGroupId,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
    );
  }

  @override
  List<Object?> get props =>
      [name, description, imagePath, status, createdGroupId, errorMessage];
}