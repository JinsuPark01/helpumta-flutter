import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../core/result.dart';
import '../../domain/entity/network_exception.dart';
import '../../domain/entity/workout_record.dart';
import '../../domain/repository/record_repository.dart';
import '../mapper/record_mapper.dart';
import '../network/network_checker.dart';

class RecordRepositoryImpl implements RecordRepository {
  RecordRepositoryImpl(this._firestore, this._storage, this._networkChecker);

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final NetworkChecker _networkChecker;

  CollectionReference<Map<String, dynamic>> get _records =>
      _firestore.collection('records');

  @override
  Future<Result<List<WorkoutRecord>>> getRecordsByGroup({
    required String groupId,
    required DateTime start,
    required DateTime end,
  }) async {
    try {
      final snapshot = await _records
          .where('groupId', isEqualTo: groupId)
          .where('createdAt', isGreaterThanOrEqualTo: start.millisecondsSinceEpoch)
          .where('createdAt', isLessThan: end.millisecondsSinceEpoch)
          .orderBy('createdAt', descending: true)
          .get();

      final records =
      snapshot.docs.map((doc) => doc.toWorkoutRecord()).nonNulls.toList();
      return Result.ok(records);
    } on Exception catch (e) {
      return Result.error(e);
    }
  }

  @override
  Future<Result<bool>> hasRecordSince({
    required String groupId,
    required String userId,
    required DateTime since,
  }) async {
    try {
      final snapshot = await _records
          .where('groupId', isEqualTo: groupId)
          .where('userId', isEqualTo: userId)
          .where('createdAt', isGreaterThanOrEqualTo: since.millisecondsSinceEpoch)
          .limit(1)
          .get();

      return Result.ok(snapshot.docs.isNotEmpty);
    } on Exception catch (e) {
      return Result.error(e);
    }
  }

  @override
  Future<Result<void>> deleteRecord({
    required String recordId,
    required String currentUserId,
  }) async {
    if (!await _networkChecker.isOnline()) {
      return const Result.error(NetworkUnavailableException());
    }

    try {
      final docRef = _records.doc(recordId);
      final snapshot = await docRef.get();
      final data = snapshot.data();

      if (!snapshot.exists || data == null) {
        return Result.error(Exception('기록을 찾을 수 없습니다'));
      }
      // 권한 체크: 본인 기록만
      if (data['userId'] != currentUserId) {
        return Result.error(Exception('본인 기록만 삭제할 수 있습니다'));
      }

      // 문서 먼저 삭제 → 이미지 삭제가 실패해도 깨진 기록은 남지 않고
      // 사용자에게 보이지 않는 고아 파일만 남음
      await docRef.delete();

      final imageUrl = data['imageUrl'];
      if (imageUrl is String && imageUrl.isNotEmpty) {
        await _deleteImageQuietly(imageUrl);
      }

      return const Result.ok(null);
    } on Exception catch (e) {
      return Result.error(e);
    }
  }

  @override
  Future<Result<void>> deleteRecordsByUserInGroup({
    required String groupId,
    required String userId,
  }) async {
    if (!await _networkChecker.isOnline()) {
      return const Result.error(NetworkUnavailableException());
    }

    try {
      final snapshot = await _records
          .where('groupId', isEqualTo: groupId)
          .where('userId', isEqualTo: userId)
          .get();

      if (snapshot.docs.isEmpty) return const Result.ok(null);

      // 문서는 Batch로 한 번에 삭제 → 전부 지워지거나 하나도 안 지워짐
      final batch = _firestore.batch();
      final imageUrls = <String>[];
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
        final imageUrl = doc.data()['imageUrl'];
        if (imageUrl is String && imageUrl.isNotEmpty) {
          imageUrls.add(imageUrl);
        }
      }
      await batch.commit();

      // 이미지는 문서 삭제 후 병렬로 정리 (실패해도 무시)
      await Future.wait(imageUrls.map(_deleteImageQuietly));

      return const Result.ok(null);
    } on Exception catch (e) {
      return Result.error(e);
    }
  }

  Future<void> _deleteImageQuietly(String imageUrl) async {
    try {
      await _storage.refFromURL(imageUrl).delete();
    } on Exception {
      // 이미지 정리 실패는 결과에 영향 주지 않음
    }
  }
}