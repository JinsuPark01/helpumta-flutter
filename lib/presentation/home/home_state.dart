import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

import '../../domain/entity/group.dart';
import '../../domain/entity/home_layout.dart';

enum HomeStatus { initial, loading, success, failure }

class HomeState extends Equatable {
  const HomeState({
    this.status = HomeStatus.initial,
    this.groups = const [],
    this.homeLayout = HomeLayout.grid,
    this.errorMessage,
  });

  final HomeStatus status;
  final List<Group> groups;
  final HomeLayout homeLayout;
  final String? errorMessage;

  bool get isLoading => status == HomeStatus.loading;

  HomeState copyWith({
    HomeStatus? status,
    List<Group>? groups,
    HomeLayout? homeLayout,
    ValueGetter<String?>? errorMessage,
  }) {
    return HomeState(
      status: status ?? this.status,
      groups: groups ?? this.groups,
      homeLayout: homeLayout ?? this.homeLayout,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, groups, homeLayout, errorMessage];
}