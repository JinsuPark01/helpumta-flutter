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

  @override
  Future<Result<List<Group>>> getGroups(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('groups')
          .where('members', arrayContains: userId)
          .get();

      final groups =
      snapshot.docs.map((doc) => doc.toGroup()).nonNulls.toList();
      return Result.ok(groups);
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
    final docRef = _firestore.collection('groups').doc();
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
}