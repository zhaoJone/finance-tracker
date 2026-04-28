import 'package:equatable/equatable.dart';
import '../data/notification_models.dart';

abstract class NotificationImportState extends Equatable {
  const NotificationImportState();

  @override
  List<Object?> get props => [];
}

class NotificationImportInitial extends NotificationImportState {}

class NotificationImportLoaded extends NotificationImportState {
  final List<ParsedNotification> notifications;

  const NotificationImportLoaded(this.notifications);

  @override
  List<Object?> get props => [notifications];
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
