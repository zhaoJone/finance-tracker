import 'dart:async';

import 'package:flutter/services.dart';

/// 通知监听桥 — 从 Android Native EventChannel 接收通知文本
///
/// 使用方式：
/// ```dart
/// final bridge = NotificationListenerBridge.instance;
/// bridge.startListening(...);
/// bridge.stopListening();
/// ```
///
/// 单例模式，确保退出页面后监听仍然保持。
class NotificationListenerBridge {
  static const _channel = EventChannel('com.financetracker/notifications');

  StreamSubscription<dynamic>? _subscription;

  /// 全局单例
  static final NotificationListenerBridge instance = NotificationListenerBridge._();

  NotificationListenerBridge._();

  /// 是否正在监听
  bool get isListening => _subscription != null;

  /// 开始监听通知
  ///
  /// [onNotification] 回调参数：
  ///   - source: "alipay" | "wechat" | "bank"
  ///   - rawText: 通知原始文本
  void startListening({
    required void Function(String source, String rawText) onNotification,
  }) {
    // 如果已经在监听，先取消旧的订阅，避免重复
    _subscription?.cancel();
    _subscription = _channel.receiveBroadcastStream().listen(
      (data) {
        if (data is Map) {
          final source = data['source'] as String? ?? 'alipay';
          final rawText = data['rawText'] as String? ?? '';
          if (rawText.isNotEmpty) {
            onNotification(source, rawText);
          }
        }
      },
      onError: (error) {
        // 静默处理错误，不影响应用运行
      },
    );
  }

  /// 停止监听
  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
  }

  /// 销毁（全局使用时不调用，仅在测试/重置时使用）
  void dispose() {
    stopListening();
  }
}
