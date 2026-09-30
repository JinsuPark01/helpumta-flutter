sealed class GroupCreateEvent {
  const GroupCreateEvent();
}

final class GroupCreateNameChanged extends GroupCreateEvent {
  const GroupCreateNameChanged(this.name);

  final String name;
}

final class GroupCreateDescriptionChanged extends GroupCreateEvent {
  const GroupCreateDescriptionChanged(this.description);

  final String description;
}

final class GroupCreateImagePicked extends GroupCreateEvent {
  const GroupCreateImagePicked(this.imagePath);

  final String imagePath;
}

final class GroupCreateSubmitted extends GroupCreateEvent {
  const GroupCreateSubmitted();
}