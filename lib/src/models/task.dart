import 'package:flutter/foundation.dart';

/// A single line item on the receipt.
@immutable
class Task {
  const Task({
    required this.id,
    required this.title,
    required this.createdAt,
    this.isCompleted = false,
  });

  final String id;
  final String title;
  final DateTime createdAt;
  final bool isCompleted;

  Task copyWith({String? title, bool? isCompleted}) => Task(
    id: id,
    title: title ?? this.title,
    createdAt: createdAt,
    isCompleted: isCompleted ?? this.isCompleted,
  );

  /// The same task with its completion flipped.
  Task toggled() => copyWith(isCompleted: !isCompleted);

  @override
  bool operator ==(Object other) =>
      other is Task &&
      other.id == id &&
      other.title == title &&
      other.createdAt == createdAt &&
      other.isCompleted == isCompleted;

  @override
  int get hashCode => Object.hash(id, title, createdAt, isCompleted);

  @override
  String toString() =>
      'Task($id, "$title", ${isCompleted ? 'done' : 'open'}, $createdAt)';
}
