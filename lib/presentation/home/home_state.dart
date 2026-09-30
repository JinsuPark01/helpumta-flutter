import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

import '../../domain/entity/group.dart';

enum HomeStatus { initial, loading, success, failure }

class HomeState extends Equatable {
  const HomeState({
    this.status = HomeStatus.initial,
    this.groups = const [],
    this.errorMessage,
  });

  final HomeStatus status;
  final List<Group> groups;
  final String? errorMessage;

  bool get isLoading => status == HomeStatus.loading;

  HomeState copyWith({
    HomeStatus? status,
    List<Group>? groups,
    ValueGetter<String?>? errorMessage,
  }) {
    return HomeState(
      status: status ?? this.status,
      groups: groups ?? this.groups,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, groups, errorMessage];
}