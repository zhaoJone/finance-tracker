import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../categories/data/categories_models.dart';
import '../../categories/data/categories_repository.dart';
import '../data/notification_models.dart';
import '../data/notification_import_repository.dart';
import 'notification_import_event.dart';
import 'notification_import_state.dart';

class NotificationImportBloc
    extends Bloc<NotificationImportEvent, NotificationImportState> {
  final NotificationImportRepository _repository;
  final CategoriesRepository _categoriesRepo;
  final CategoryMatchRuleRepository _ruleRepo;
  final List<ParsedNotification> _notifications = [];
  List<Category> _categories = [];
  final String _defaultCategoryId = '';

  NotificationImportBloc(
    this._repository,
    this._categoriesRepo,
    this._ruleRepo,
  ) : super(NotificationImportInitial()) {
    on<NotificationInit>(_onInit);
    on<NotificationIncoming>(_onIncoming);
    on<NotificationRemove>(_onRemove);
    on<NotificationSetCategory>(_onSetCategory);
    on<NotificationSetGroupCategory>(_onSetGroupCategory);
    on<NotificationSaveRule>(_onSaveRule);
    on<NotificationImportConfirmed>(_onImportConfirmed);
    on<NotificationReset>(_onReset);
  }

  Future<void> _onInit(
    NotificationInit event,
    Emitter<NotificationImportState> emit,
  ) async {
    // Load categories
    try {
      _categories = await _categoriesRepo.listCategories();
    } catch (_) {
      _categories = [];
    }

    emit(NotificationImportLoaded(
      notifications: List.from(_notifications),
      categories: _categories,
      defaultCategoryId: _defaultCategoryId,
    ));
  }

  /// 尝试用匹配规则自动分配分类
  Future<void> _applyMatchRules() async {
    try {
      final rules = await _ruleRepo.list();
      if (rules.isEmpty) return;
      for (final n in _notifications) {
        if (n.categoryId != null) continue;
        final matchedRules = rules.where(
          (r) => n.counterparty.contains(r.keyword) || r.keyword.contains(n.counterparty),
        );
        if (matchedRules.isNotEmpty) {
          n.categoryId = matchedRules.first.categoryId;
        }
      }
    } catch (_) {
      // 规则加载失败不影响核心功能
    }
  }

  Future<void> _onIncoming(
    NotificationIncoming event,
    Emitter<NotificationImportState> emit,
  ) async {
    // 唯一路径：云端解析（无本地降级）
    final cloudResult = await _repository.parseViaCloud(
      rawText: event.rawText,
      sourceHint: event.source,
    );

    if (cloudResult.isParsed) {
      _notifications.add(cloudResult.parsed!);
      _applyMatchRules();
    } else {
      // 解析失败或网络错误 → 标记为未解析，显示在列表中
      _notifications.add(ParsedNotification(
        source: event.source,
        rawText: event.rawText,
        amount: 0,
        type: 'expense',
        counterparty: '',
        timestamp: DateTime.now(),
        tradeNo: '',
        isUnparsed: true,
      ));
    }

    emit(NotificationImportLoaded(
      notifications: List.from(_notifications),
      categories: _categories,
      defaultCategoryId: _defaultCategoryId,
    ));
  }

  void _onRemove(
    NotificationRemove event,
    Emitter<NotificationImportState> emit,
  ) {
    if (event.index >= 0 && event.index < _notifications.length) {
      _notifications.removeAt(event.index);
    }
    emit(NotificationImportLoaded(
      notifications: List.from(_notifications),
      categories: _categories,
      defaultCategoryId: _defaultCategoryId,
    ));
  }

  void _onSetCategory(
    NotificationSetCategory event,
    Emitter<NotificationImportState> emit,
  ) {
    if (event.index >= 0 && event.index < _notifications.length) {
      _notifications[event.index].categoryId = event.categoryId;
    }
    emit(NotificationImportLoaded(
      notifications: List.from(_notifications),
      categories: _categories,
      defaultCategoryId: _defaultCategoryId,
    ));
  }

  void _onSetGroupCategory(
    NotificationSetGroupCategory event,
    Emitter<NotificationImportState> emit,
  ) {
    for (final n in _notifications) {
      if (n.counterparty == event.counterparty) {
        n.categoryId = event.categoryId;
      }
    }
    emit(NotificationImportLoaded(
      notifications: List.from(_notifications),
      categories: _categories,
      defaultCategoryId: _defaultCategoryId,
    ));
  }

  Future<void> _onSaveRule(
    NotificationSaveRule event,
    Emitter<NotificationImportState> emit,
  ) async {
    try {
      await _ruleRepo.create(
        keyword: event.keyword,
        categoryId: event.categoryId,
      );
    } catch (_) {
      // 静默失败，不影响导入
    }
  }

  Future<void> _onImportConfirmed(
    NotificationImportConfirmed event,
    Emitter<NotificationImportState> emit,
  ) async {
    if (_notifications.isEmpty) return;
    emit(NotificationImportLoading());
    try {
      // 过滤掉未解析的通知，只导入成功解析的
      final parsedNotifications =
          _notifications.where((n) => !n.isUnparsed).toList();
      if (parsedNotifications.isEmpty) {
        emit(const NotificationImportError('没有可导入的通知（所有通知均未能解析）'));
        return;
      }
      final result = await _repository.importNotifications(
        notifications: parsedNotifications,
        defaultCategoryId: event.defaultCategoryId,
      );
      _notifications.clear();
      emit(NotificationImportSuccess(result));
    } catch (e) {
      emit(NotificationImportError(_extractError(e)));
    }
  }

  void _onReset(
    NotificationReset event,
    Emitter<NotificationImportState> emit,
  ) {
    _notifications.clear();
    _categories = [];
    emit(NotificationImportInitial());
  }

  String _extractError(dynamic e) {
    if (e.toString().contains('401')) {
      return '未登录或登录已过期';
    }
    if (e.toString().contains('404') || e.toString().contains('CATEGORY_NOT_FOUND')) {
      return '分类不存在，请先创建分类';
    }
    if (e.toString().contains('connection')) {
      return '无法连接服务器';
    }
    return '导入失败: ${e.toString()}';
  }
}
