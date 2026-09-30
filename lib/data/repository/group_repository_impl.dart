import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/result.dart';
import '../../domain/entity/group.dart';
import '../../domain/repository/group_repository.dart';
import '../mapper/group_mapper.dart';

class GroupRepositoryImpl implements GroupRepository {
  GroupRepositoryImpl(this._firestore);

  final FirebaseFirestore _firestore;

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
}