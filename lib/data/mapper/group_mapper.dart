import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entity/group.dart';

extension GroupMapper on DocumentSnapshot<Map<String, dynamic>> {
  /// name이 없으면 잘못된 문서로 보고 null 반환
  Group? toGroup() {
    final data = this.data();
    if (data == null) return null;

    final name = data['name'];
    if (name is! String) return null;

    final description = data['description'];
    final imageUrl = data['imageUrl'];
    final members = data['members'];

    return Group(
      id: id,
      name: name,
      description: description is String ? description : '',
      imageUrl: imageUrl is String ? imageUrl : '',
      memberCount: members is List ? members.length : 0,
    );
  }
}