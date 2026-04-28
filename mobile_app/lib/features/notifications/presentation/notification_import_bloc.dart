import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/notification_models.dart';
import '../data/notification_import_repository.dart';
import 'notification_import_event.dart';
import 'notification_import_state.dart';

class NotificationImportBloc
    extends Bloc<NotificationImportEvent, NotificationImportState> {
  final NotificationImportRepository _repository;

  NotificationImportBloc(this._repository)
      : super(NotificationImportInitial()) {
    on<NotificationLoadDemo>(_onLoadDemo);
    on<NotificationAdd>(_onAdd);
    on<NotificationRemove>(_onRemove);
    on<NotificationImportConfirmed>(_onImportConfirmed);
    on<NotificationReset>(_onReset);
  }

  List<ParsedNotification> _notifications = [];

  void _onLoadDemo(NotificationLoadDemo event, Emitter<NotificationImportState> emit) {
    _notifications = [
      // 支付宝演示
      ParsedNotification(
        source: 'alipay',
        rawText: '【支付宝】您有一笔支出，金额¥128.50，收款商家：麦当劳，已完成。28/04 14:32',
        amount: 12850,
        type: 'expense',
        counterparty: '麦当劳',
        timestamp: DateTime(2025, 4, 28, 14, 32),
        tradeNo: 'demo_alipay_001',
      ),
      // 微信演示
      ParsedNotification(
        source: 'wechat',
        rawText: '微信支付，¥58.00，哆来茶，28/04/26 14:32:24支付完成',
        amount: 5800,
        type: 'expense',
        counterparty: '哆来茶',
        timestamp: DateTime(2025, 4, 26, 14, 32, 24),
        tradeNo: 'demo_wechat_001',
      ),
    ];
    emit(NotificationImportLoaded(List.from(_notifications)));
  }

  void _onAdd(NotificationAdd event, Emitter<NotificationImportState> emit) {
    final parsed = _repository.parseNotification(
      rawText: event.rawText,
      source: event.source,
    );
    if (parsed == null) return;
    _notifications.add(parsed);
    emit(NotificationImportLoaded(List.from(_notifications)));
  }

  void _onRemove(NotificationRemove event, Emitter<NotificationImportState> emit) {
    if (event.index >= 0 && event.index < _notifications.length) {
      _notifications.removeAt(event.index);
    }
    emit(NotificationImportLoaded(List.from(_notifications)));
  }

  Future<void> _onImportConfirmed(
    NotificationImportConfirmed event,
    Emitter<NotificationImportState> emit,
  ) async {
    if (_notifications.isEmpty) return;
    emit(NotificationImportLoading());
    try {
      final result = await _repository.importNotifications(
        notifications: _notifications,
        defaultCategoryId: event.defaultCategoryId,
      );
      _notifications.clear();
      emit(NotificationImportSuccess(result));
    } catch (e) {
      emit(NotificationImportError(_extractError(e)));
    }
  }

  void _onReset(NotificationReset event, Emitter<NotificationImportState> emit) {
    _notifications.clear();
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
