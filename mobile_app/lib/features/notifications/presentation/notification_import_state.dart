import '../../categories/data/categories_models.dart';
import '../data/notification_models.dart';
import 'package:equatable/equatable.dart';

abstract class NotificationImportState extends Equatable {
  const NotificationImportState();

  @override
  List<Object?> get props => [];
}

class NotificationImportInitial extends NotificationImportState {}

class NotificationImportLoaded extends NotificationImportState {
  final List<ParsedNotification> notifications;
  final List<Category> categories;
  final String defaultCategoryId;

  const NotificationImportLoaded({
    required this.notifications,
    required this.categories,
    this.defaultCategoryId = '',
  });

  @override
  List<Object?> get props => [notifications, categories, defaultCategoryId];
}

class NotificationImportLoading extends NotificationImportState {}

class NotificationImportSuccess extends NotificationImportState {
  final ImportResult result;

  const NotificationImportSuccess(this.result);

  @override
  List<Object?> get props => [result];
}

class NotificationImportError extends NotificationImportState {
  final String message;

  const NotificationImportError(this.message);

  @override
  List<Object?> get props => [message];
}
