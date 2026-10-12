import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../core/result.dart';
import '../../domain/entity/group.dart';
import '../../domain/entity/network_exception.dart';
import '../../domain/repository/group_repository.dart';
import '../mapper/group_mapper.dart';
import '../network/network_checker.dart';
import '../util/image_compressor.dart';

class GroupRepositoryImpl implements GroupRepository {
  GroupRepositoryImpl(
      this._firestore,
      this._storage,
      this._imageCompressor,
      this._networkChecker,
      );

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final ImageCompressor _imageCompressor;
  final NetworkChecker _networkChecker;

  static const _groupImageMaxSize = 1080;

  CollectionReference<Map<String, dynamic>> get _groups =>
      _firestore.collection('groups');

  @override
  Future<Result<List<Group>>> getGroups(String userId) async {
    try {
      final snapshot =
      await _groups.where('members', arrayContains: userId).get();

      final groups =
      snapshot.docs.map((doc) => doc.toGroup()).nonNulls.toList();
      return Result.ok(groups);
    } on Exception catch (e) {
      return Result.error(e);
    }
  }

  @override
  Future<Result<Group>> getGroupById(String groupId) async {
    try {
      final doc = await _groups.doc(groupId).get();
      if (!doc.exists) {
        return Result.error(Exception('그룹을 찾을 수 없습니다'));
      }

      final group = doc.toGroup();
      if (group == null) {
        return Result.error(Exception('그룹 정보가 올바르지 않습니다'));
      }
      return Result.ok(group);
    } on Exception catch (e) {
      return Result.error(e);
    }
  }

  @override
  Future<Result<String>> createGroup({
    required String userId,
    required String name,
    required String description,
    String? imagePath,
  }) async {
    // Firestore는 오프라인 쓰기를 임시 저장하고 서버 응답까지 대기하므로,
    // 명백한 오프라인은 요청 전에 걸러서 무한 대기를 막는다
    if (!await _networkChecker.isOnline()) {
      return const Result.error(NetworkUnavailableException());
    }

    // 문서 ID를 먼저 만들어 이미지 파일명으로 사용 (그룹 ↔ 이미지 1:1)
    final docRef = _groups.doc();
    Reference? uploadedImageRef;

    try {
      var imageUrl = '';
      if (imagePath != null) {
        final bytes = await _imageCompressor.compress(
          imagePath,
          maxSize: _groupImageMaxSize,
        );
        final ref = _storage.ref('groups/${docRef.id}.jpg');
        await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
        uploadedImageRef = ref;
        imageUrl = await ref.getDownloadURL();
      }

      await docRef.set({
        'name': name,
        'description': description,
        'imageUrl': imageUrl,
        'members': [userId],
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      });

      return Result.ok(docRef.id);
    } on Exception catch (e) {
      // 이미지는 올라갔는데 문서 저장이 실패하면 Storage에 고아 파일이 남으므로 정리
      final orphan = uploadedImageRef;
      if (orphan != null) {
        try {
          await orphan.delete();
        } on Exception {
          // 정리 실패는 무시 (원래 에러를 반환하는 게 우선)
        }
      }
      return Result.error(e);
    }
  }

  @override
  Future<Result<void>> leaveGroup({
    required String groupId,
    required String userId,
  }) async {
    if (!await _networkChecker.isOnline()) {
      return const Result.error(NetworkUnavailableException());
    }

    try {
      final docRef = _groups.doc(groupId);
      final doc = await docRef.get();
      final data = doc.data();

      // 이미 없는 그룹이면 성공 처리 (멱등성)
      if (!doc.exists || data == null) return const Result.ok(null);

      final members = data['members'];
      final memberIds =
      members is List ? members.whereType<String>().toList() : <String>[];
      final remaining = memberIds.where((id) => id != userId);

      if (remaining.isEmpty) {
        // 마지막 멤버 → 그룹 문서 먼저 삭제, 이미지는 그다음 정리
        await docRef.delete();

        final imageUrl = data['imageUrl'];
        if (imageUrl is String && imageUrl.isNotEmpty) {
          try {
            await _storage.refFromURL(imageUrl).delete();
          } on Exception {
            // 이미지 정리 실패는 결과에 영향 주지 않음
          }
        }
      } else {
        // 멤버 남아있음 → 배열에서 본인만 제거
        await docRef.update({
          'members': FieldValue.arrayRemove([userId]),
        });
      }

      return const Result.ok(null);
    } on Exception catch (e) {
      return Result.error(e);
    }
  }
}