import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/result.dart';
import '../../domain/repository/user_repository.dart';

class UserRepositoryImpl implements UserRepository {
  UserRepositoryImpl(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Future<Result<void>> saveUser({
    required String uid,
    required String nickname,
    required String email,
  }) async {
    try {
      final docRef = _firestore.collection('users').doc(uid);
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
}