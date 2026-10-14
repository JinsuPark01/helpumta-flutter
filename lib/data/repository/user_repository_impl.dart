import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/result.dart';
import '../../domain/repository/user_repository.dart';

class UserRepositoryImpl implements UserRepository {
  UserRepositoryImpl(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  @override
  Future<Result<void>> saveUser({
    required String uid,
    required String nickname,
    required String email,
  }) async {
    try {
      final docRef = _users.doc(uid);
      final snapshot = await docRef.get();

      if (snapshot.exists) {
        // 이미 있으면 nickname/email만 갱신 (createdAt 보존)
        await docRef.set(
          {'nickname': nickname, 'email': email},
          SetOptions(merge: true),
        );
      } else {
        // 신규 생성
        await docRef.set({
          'nickname': nickname,
          'email': email,
          'createdAt': DateTime.now().millisecondsSinceEpoch,
        });
      }
      return const Result.ok(null);
    } on Exception catch (e) {
      return Result.error(e);
    }
  }

  @override
  Future<Result<Map<String, String>>> getNicknames(List<String> uids) async {
    if (uids.isEmpty) return const Result.ok({});

    try {
      // 그룹 정원이 작아서(최대 4명) 문서별 조회를 병렬로 실행
      final docs = await Future.wait(uids.map((uid) => _users.doc(uid).get()));

      final nicknames = <String, String>{};
      for (final doc in docs) {
        final nickname = doc.data()?['nickname'];
        if (nickname is String) nicknames[doc.id] = nickname;
      }
      return Result.ok(nicknames);
    } on Exception catch (e) {
      return Result.error(e);
    }
  }
}