import 'dart:async';

import 'package:flutter/services.dart';

/// 通知监听桥 — 从 Android Native EventChannel 接收通知文本
///
/// 使用方式：
/// ```dart
/// final bridge = NotificationListenerBridge();
/// bridge.startListening((source, rawText) {
///   // 处理捕获的通知
/// });
/// bridge.dispose();
/// ```
class NotificationListenerBridge {
  static const _channel = EventChannel('com.financetracker/notifications');

  StreamSubscription<dynamic>? _subscription;

  /// 开始监听通知
  ///
  /// [onNotification] 回调参数：
  ///   - source: "alipay" | "wechat" | "bank"
  ///   - rawText: 通知原始文本
  void startListening({
    required void Function(String source, String rawText) onNotification,
  }) {
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
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }
}
