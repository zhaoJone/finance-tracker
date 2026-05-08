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

    test('解析交易提醒支出', () {
      final result = parseAlipayNotification(
          '交易提醒 你有一笔1.00元的支出，点此查看详情。');
      expect(result, isNotNull);
      expect(result!.amount, equals(100));
      expect(result.source, equals('alipay'));
      expect(result.type, equals('expense'));
      expect(result.counterparty, isEmpty);
    });

    test('解析交易提醒收入', () {
      final result = parseAlipayNotification(
          '交易提醒 你有一笔0.88元的收入，点此查看详情。');
      expect(result, isNotNull);
      expect(result!.amount, equals(88));
      expect(result.source, equals('alipay'));
      expect(result.type, equals('income'));
      expect(result.counterparty, isEmpty);
    });

    test('交易提醒无金额格式返回 null', () {
      final result =
          parseAlipayNotification('交易提醒 点此查看详情。');
      expect(result, isNull);
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
    test('解析正常消费通知（通用格式）', () {
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

    test('招行信用卡消费', () {
      final result = parseBankNotification(
          '【招商银行】您尾号8888的信用卡于05月01日12:30消费人民币128.00元');
      expect(result, isNotNull);
      expect(result!.amount, equals(12800));
      expect(result.source, equals('bank'));
      expect(result.type, equals('expense'));
      expect(result.counterparty, isEmpty);
    });

    test('招行一卡通支出', () {
      final result = parseBankNotification(
          '【招商银行】您尾号6666的一卡通于05月01日12:30支出人民币500.00元');
      expect(result, isNotNull);
      expect(result!.amount, equals(50000));
      expect(result.source, equals('bank'));
      expect(result.type, equals('expense'));
    });

    test('招行收款（收入）', () {
      final result = parseBankNotification(
          '【招商银行】您尾号6666的一卡通于05月01日12:30收到转账人民币1000.00元');
      expect(result, isNotNull);
      expect(result!.amount, equals(100000));
      expect(result.source, equals('bank'));
      expect(result.type, equals('income'));
    });

    test('招行信用卡还款', () {
      final result = parseBankNotification(
          '【招商银行】您尾号8888的信用卡于05月01日12:30还款人民币2000.00元');
      expect(result, isNotNull);
      expect(result!.amount, equals(200000));
      expect(result.source, equals('bank'));
      expect(result.type, equals('expense'));
    });

    test('招行带商户名消费', () {
      final result = parseBankNotification(
          '【招商银行】您尾号8888的信用卡于05月01日14:20消费人民币36.50元-瑞幸咖啡');
      expect(result, isNotNull);
      expect(result!.amount, equals(3650));
      expect(result.counterparty, equals('瑞幸咖啡'));
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

    test('相同招行通知文本产生相同 hash', () {
      const text =
          '【招商银行】您尾号8888的信用卡于05月01日12:30消费人民币128.00元';
      final r1 = parseBankNotification(text);
      final r2 = parseBankNotification(text);
      expect(r1!.tradeNo, equals(r2!.tradeNo));
    });
  });
}
