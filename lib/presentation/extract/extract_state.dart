import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

import '../../domain/entity/extract_slot.dart';

enum ExtractStatus { loading, success, failure }

enum ExtractSaveStatus { idle, inProgress, success, failure }

class ExtractState extends Equatable {
  const ExtractState({
    required this.groupId,
    required this.date,
    this.status = ExtractStatus.loading,
    this.slots = const [],
    this.saveStatus = ExtractSaveStatus.idle,
    this.saveErrorMessage,
  });

  final String groupId;
  final DateTime date;
  final ExtractStatus status;
  final List<ExtractSlot> slots;
  final ExtractSaveStatus saveStatus;
  final String? saveErrorMessage;

  bool get isSaving => saveStatus == ExtractSaveStatus.inProgress;

  ExtractState copyWith({
    ExtractStatus? status,
    List<ExtractSlot>? slots,
    ExtractSaveStatus? saveStatus,
    ValueGetter<String?>? saveErrorMessage,
  }) {
    return ExtractState(
      groupId: groupId,
      date: date,
      status: status ?? this.status,
      slots: slots ?? this.slots,
      saveStatus: saveStatus ?? this.saveStatus,
      saveErrorMessage:
      saveErrorMessage != null ? saveErrorMessage() : this.saveErrorMessage,
    );
  }

  @override
  List<Object?> get props =>
      [groupId, date, status, slots, saveStatus, saveErrorMessage];
}