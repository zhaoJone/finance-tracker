import 'package:flutter_test/flutter_test.dart';

import 'package:finance_tracker_app/features/notifications/data/notification_import_repository.dart';

void main() {
  group('parseAlipayNotification', () {
    test('解析正常消费通知', () {
      final result = parseAlipayNotification(
          '【支付宝】您有一笔支出，金额¥128.50，收款商家：麦当劳，已完成。28/04 14:32');
      expect(result, isNotNull);
      expect(result!.amount, equals(12850));
      expect(result.source, equals('alipay'));
      expect(result.type, equals('expense'));
      expect(result.counterparty, equals('麦当劳'));
      expect(result.tradeNo, isNotEmpty);
    });

    test('无金额格式返回 null', () {
      final result =
          parseAlipayNotification('【支付宝】这是一条无效通知');
      expect(result, isNull);
    });
  });

  group('parseWechatNotification', () {
    test('解析正常支付通知', () {
      final result = parseWechatNotification(
          '微信支付，¥58.00，哆来茶，28/04/26 14:32:24支付完成');
      expect(result, isNotNull);
      expect(result!.amount, equals(5800));
      expect(result.source, equals('wechat'));
      expect(result.counterparty, equals('哆来茶'));
    });

    test('无金额格式返回 null', () {
      final result = parseWechatNotification('微信支付，一条无效通知');
      expect(result, isNull);
    });
  });

  group('parseBankNotification', () {
    test('解析正常消费通知', () {
      final result = parseBankNotification(
          '您尾号1234的银行卡片于2024-01-01 12:00:00消费RMB 56.78元');
      expect(result, isNotNull);
      expect(result!.amount, equals(5678));
      expect(result.source, equals('bank'));
      expect(result.type, equals('expense'));
    });

    test('解析 ATM 支取', () {
      final result = parseBankNotification(
          '您尾号1234的银行卡片ATM支取 RMB 200.00元');
      expect(result, isNotNull);
      expect(result!.amount, equals(20000));
      expect(result.source, equals('bank'));
    });

    test('未知格式返回 null', () {
      final result = parseBankNotification('这是一条无关短信');
      expect(result, isNull);
    });
  });

  group('trade_no 去重', () {
    test('相同文本产生相同 hash', () {
      const text =
          '【支付宝】您有一笔支出，金额¥12.50，收款商家：麦当劳，已完成。28/04 14:32';
      final r1 = parseAlipayNotification(text);
      final r2 = parseAlipayNotification(text);
      expect(r1!.tradeNo, equals(r2!.tradeNo));
    });

    test('不同文本产生不同 hash', () {
      const text1 =
          '【支付宝】您有一笔支出，金额¥12.50，收款商家：麦当劳，已完成。28/04 14:32';
      const text2 =
          '【支付宝】您有一笔支出，金额¥12.51，收款商家：麦当劳，已完成。28/04 14:32';
      final r1 = parseAlipayNotification(text1);
      final r2 = parseAlipayNotification(text2);
      expect(r1!.tradeNo, isNot(equals(r2!.tradeNo)));
    });
  });
}
