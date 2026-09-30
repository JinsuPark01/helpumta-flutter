import 'package:equatable/equatable.dart';

class Group extends Equatable {
  const Group({
    required this.id,
    required this.name,
    this.description = '',
    this.imageUrl = '',
    required this.memberCount,
  });

  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final int memberCount;

  @override
  List<Object?> get props => [id, name, description, imageUrl, memberCount];
}