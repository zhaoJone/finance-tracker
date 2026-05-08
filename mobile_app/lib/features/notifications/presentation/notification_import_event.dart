import 'package:equatable/equatable.dart';

abstract class NotificationImportEvent extends Equatable {
  const NotificationImportEvent();

  @override
  List<Object?> get props => [];
}

/// 初始化页面数据（加载分类列表）
class NotificationInit extends NotificationImportEvent {
  const NotificationInit();
}

/// 接收来自 Android 原生通知监听的新通知
class NotificationIncoming extends NotificationImportEvent {
  final String source; // "alipay" | "wechat" | "bank"
  final String rawText;

  const NotificationIncoming({required this.source, required this.rawText});

  @override
  List<Object?> get props => [source, rawText];
}

/// 移除一条待导入通知
class NotificationRemove extends NotificationImportEvent {
  final int index;

  const NotificationRemove(this.index);

  @override
  List<Object?> get props => [index];
}

/// 设置某条通知的分类
class NotificationSetCategory extends NotificationImportEvent {
  final int index;
  final String categoryId;

  const NotificationSetCategory({required this.index, required this.categoryId});

  @override
  List<Object?> get props => [index, categoryId];
}

/// 设置某个商户组下所有通知的分类（对应商户聚合归类方案④）
class NotificationSetGroupCategory extends NotificationImportEvent {
  final String counterparty;
  final String categoryId;

  const NotificationSetGroupCategory({required this.counterparty, required this.categoryId});

  @override
  List<Object?> get props => [counterparty, categoryId];
}

/// 保存一条匹配规则（记住分类）
class NotificationSaveRule extends NotificationImportEvent {
  final String keyword;
  final String categoryId;

  const NotificationSaveRule({required this.keyword, required this.categoryId});

  @override
  List<Object?> get props => [keyword, categoryId];
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
