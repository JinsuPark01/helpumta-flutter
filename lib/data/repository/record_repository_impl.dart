import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../core/result.dart';
import '../../domain/entity/network_exception.dart';
import '../../domain/entity/record_image.dart';
import '../../domain/entity/workout_record.dart';
import '../../domain/repository/record_repository.dart';
import '../mapper/record_mapper.dart';
import '../network/network_checker.dart';
import '../util/image_compressor.dart';

class RecordRepositoryImpl implements RecordRepository {
  RecordRepositoryImpl(
      this._firestore,
      this._storage,
      this._imageCompressor,
      this._networkChecker,
      );

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final ImageCompressor _imageCompressor;
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
  Future<Result<WorkoutRecord>> getRecordById(String recordId) async {
    try {
      final doc = await _records.doc(recordId).get();
      if (!doc.exists) {
        return Result.error(Exception('기록을 찾을 수 없습니다'));
      }

      final record = doc.toWorkoutRecord();
      if (record == null) {
        return Result.error(Exception('기록 정보가 올바르지 않습니다'));
      }
      return Result.ok(record);
    } on Exception catch (e) {
      return Result.error(e);
    }
  }

  @override
  Future<Result<String>> createRecord({
    required String groupId,
    required String userId,
    required String userName,
    required String workoutType,
    required int workoutDuration,
    String? imagePath,
    required String comment,
  }) async {
    if (!await _networkChecker.isOnline()) {
      return const Result.error(NetworkUnavailableException());
    }

    final docRef = _records.doc();
    String? uploadedImageUrl;

    try {
      var imageUrl = '';
      if (imagePath != null) {
        imageUrl = await _uploadImage(
          groupId: groupId,
          recordId: docRef.id,
          imagePath: imagePath,
        );
        uploadedImageUrl = imageUrl;
      }

      await docRef.set({
        'groupId': groupId,
        'userId': userId,
        'userName': userName,
        'workoutType': workoutType,
        'workoutDuration': workoutDuration,
        'imageUrl': imageUrl,
        'comment': comment,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      });

      return Result.ok(docRef.id);
    } on Exception catch (e) {
      // 이미지는 올라갔는데 문서 저장이 실패하면 고아 파일 정리
      final orphan = uploadedImageUrl;
      if (orphan != null) await _deleteImageQuietly(orphan);
      return Result.error(e);
    }
  }

  @override
  Future<Result<void>> updateRecord({
    required String recordId,
    required String currentUserId,
    required String workoutType,
    required int workoutDuration,
    required RecordImage image,
    required String comment,
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
        return Result.error(Exception('본인 기록만 수정할 수 있습니다'));
      }

      final oldImageUrl =
      data['imageUrl'] is String ? data['imageUrl'] as String : '';
      final groupId = data['groupId'] is String ? data['groupId'] as String : '';

      // 1. 새 이미지가 있으면 먼저 업로드
      String? uploadedImageUrl;
      final String newImageUrl;
      switch (image) {
        case NoRecordImage():
          newImageUrl = '';
        case ExistingRecordImage(:final url):
          newImageUrl = url;
        case NewRecordImage(:final path):
          uploadedImageUrl = await _uploadImage(
            groupId: groupId,
            recordId: recordId,
            imagePath: path,
          );
          newImageUrl = uploadedImageUrl;
      }

      // 2. 문서 업데이트 (createdAt, userId, userName, groupId는 유지)
      try {
        await docRef.update({
          'workoutType': workoutType,
          'workoutDuration': workoutDuration,
          'imageUrl': newImageUrl,
          'comment': comment,
        });
      } on Exception {
        // 문서가 새 이미지를 가리키지 못했으므로 방금 올린 이미지 정리
        final orphan = uploadedImageUrl;
        if (orphan != null) await _deleteImageQuietly(orphan);
        rethrow;
      }

      // 3. 문서가 새 이미지를 가리키게 된 뒤에 기존 이미지 정리
      if (oldImageUrl.isNotEmpty && oldImageUrl != newImageUrl) {
        await _deleteImageQuietly(oldImageUrl);
      }

      return const Result.ok(null);
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

  /// 같은 경로에 덮어쓰면 다운로드 URL이 그대로라 이미지 캐시가 갱신되지 않으므로
  /// 기록 ID + 업로드 시각으로 매번 새 파일명을 만든다
  Future<String> _uploadImage({
    required String groupId,
    required String recordId,
    required String imagePath,
  }) async {
    final bytes = await _imageCompressor.compress(imagePath);
    final fileName = '${recordId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = _storage.ref('records/$groupId/$fileName');
    await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
    return ref.getDownloadURL();
  }

  Future<void> _deleteImageQuietly(String imageUrl) async {
    try {
      await _storage.refFromURL(imageUrl).delete();
    } on Exception {
      // 이미지 정리 실패는 결과에 영향 주지 않음
    }
  }
}