import 'package:equatable/equatable.dart';

abstract class NotificationImportEvent extends Equatable {
  const NotificationImportEvent();

  @override
  List<Object?> get props => [];
}

/// 加载（解析演示用）通知
class NotificationLoadDemo extends NotificationImportEvent {}

/// 添加一条手动输入的通知
class NotificationAdd extends NotificationImportEvent {
  final String rawText;
  final String source; // "alipay" | "wechat"

  const NotificationAdd({required this.rawText, required this.source});

  @override
  List<Object?> get props => [rawText, source];
}

/// 移除一条待导入通知
class NotificationRemove extends NotificationImportEvent {
  final int index;

  const NotificationRemove(this.index);

  @override
  List<Object?> get props => [index];
}

/// 确认导入
class NotificationImportConfirmed extends NotificationImportEvent {
  final String defaultCategoryId;

  const NotificationImportConfirmed({required this.defaultCategoryId});

  @override
  List<Object?> get props => [defaultCategoryId];
}

/// 重置状态
class NotificationReset extends NotificationImportEvent {}
