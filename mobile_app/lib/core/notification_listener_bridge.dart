import 'dart:async';

import 'package:flutter/services.dart';

/// 通知监听桥 — 从 Android Native 接收通知文本
///
/// 使用方式：
/// ```dart
/// final bridge = NotificationListenerBridge.instance;
/// bridge.startListening(onNotification: ...);
/// bridge.stopListening();
/// ```
///
/// 双重保障模式（不依赖前台 Service）：
/// 1. 先订阅 EventChannel（开实时流）
/// 2. 再调用 MethodChannel flushCached 拉取缓存（App 被杀期间错过的通知）
/// 3. 收到通知时用 fingerprint 去重（避免缓存回放和实时推送重复）
///
/// 单例模式，确保退出页面后监听仍然保持。
class NotificationListenerBridge {
  static const _eventChannel = EventChannel('com.financetracker/notifications');
  static const _cacheChannel = MethodChannel('com.financetracker/notification_cache');

  StreamSubscription<dynamic>? _subscription;

  /// 全局单例
  static final NotificationListenerBridge instance = NotificationListenerBridge._();

  NotificationListenerBridge._();

  /// 是否正在监听
  bool get isListening => _subscription != null;

  /// 已处理的指纹集合，用于 Flutter 层去重
  final Set<String> _processedFingerprints = {};

  /// 当前回调引用
  void Function(String source, String rawText)? _onNotification;

  /// 更新回调（不重启监听，仅替换通知处理器）
  /// 用于页面重建后更新回调引用，防止旧页面闭包泄漏。
  void updateCallback({
    required void Function(String source, String rawText) onNotification,
  }) {
    _onNotification = onNotification;
  }

  /// 开始监听通知
  ///
  /// 顺序：
  ///   1. 先订阅 EventChannel（实时流）
  ///   2. 再拉取 Native 缓存（回放被杀期间错过的通知）
  ///   3. 后续实时推送和缓存回放统一经过指纹去重
  ///
  /// 每次调用都会取消旧订阅并重新注册，确保回调引用是最新的。
  ///
  /// [onNotification] 回调参数：
  ///   - source: "alipay" | "wechat" | "bank"
  ///   - rawText: 通知原始文本
  Future<void> startListening({
    required void Function(String source, String rawText) onNotification,
  }) async {
    _onNotification = onNotification;

    // 取消旧订阅，确保 EventChannel 重新绑定到当前 Flutter 引擎
    _subscription?.cancel();

    // ── Step 1: 先开实时流 ──
    _subscription = _eventChannel.receiveBroadcastStream().listen(
      _onRawNotification,
      onError: (_) {},
    );

    // ── Step 2: 再拉取缓存（flushCached = 取出即删） ──
    try {
      final cachedList = await _cacheChannel.invokeMethod<List<dynamic>>('flushCached');
      if (cachedList != null) {
        for (final item in cachedList) {
          if (item is Map) {
            _onRawNotification(Map<String, dynamic>.from(item));
          }
        }
      }
    } catch (_) {
      // 缓存拉取失败不影响实时流
    }
  }

  /// 统一的原始通知处理（去重 + 回调转发）
  void _onRawNotification(dynamic data) {
    if (data is! Map) return;

    final fingerprint = data['fingerprint'] as String? ?? '';
    final source = data['source'] as String? ?? '';
    final rawText = data['rawText'] as String? ?? '';

    if (rawText.isEmpty) return;

    // Flutter 层去重：同一 fingerprint 只处理一次
    if (fingerprint.isNotEmpty) {
      if (_processedFingerprints.contains(fingerprint)) return;
      _processedFingerprints.add(fingerprint);
      // 控制集合大小，防止内存泄漏（最多保留 2000 条指纹）
      if (_processedFingerprints.length > 2000) {
        _processedFingerprints.remove(_processedFingerprints.first);
      }
    }

    _onNotification?.call(source, rawText);
  }

  /// 停止监听
  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
    // 不清除 _processedFingerprints：
    // 如果用户停止后立即重新启动，已处理的通知不会被重复引入
  }

  /// 销毁（全局使用时不调用，仅在测试/重置时使用）
  void dispose() {
    stopListening();
    _processedFingerprints.clear();
  }
}
