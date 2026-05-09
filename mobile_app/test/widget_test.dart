import 'package:flutter_test/flutter_test.dart';

import 'package:finance_tracker_app/features/notifications/data/notification_models.dart';

void main() {
  group('CloudParseResult', () {
    test('fromJson — 解析成功时返回 parsed 数据', () {
      final json = {
        'data': {
          'parsed': {
            'source': 'bank',
            'raw_text': '【招商银行】消费人民币128.00元',
            'amount': 12800,
            'type': 'expense',
            'counterparty': '',
            'timestamp': '2026-05-09T12:30:00',
            'trade_no': '',
          },
          'source_hint': 'bank',
        },
      };

      final result = CloudParseResult.fromJson(json);
      expect(result.isParsed, isTrue);
      expect(result.parsed, isNotNull);
      expect(result.parsed!.amount, equals(12800));
      expect(result.parsed!.source, equals('bank'));
      expect(result.parsed!.type, equals('expense'));
      expect(result.sourceHint, equals('bank'));
    });

    test('fromJson — 解析失败时 parsed 为 null', () {
      final json = {
        'data': {
          'parsed': null,
          'source_hint': 'alipay',
        },
      };

      final result = CloudParseResult.fromJson(json);
      expect(result.isParsed, isFalse);
      expect(result.parsed, isNull);
    });

    test('fromJson — 无 data 字段时返回空结果', () {
      final json = <String, dynamic>{};
      final result = CloudParseResult.fromJson(json);
      expect(result.isParsed, isFalse);
      expect(result.parsed, isNull);
    });
  });

  group('ImportResult', () {
    test('fromJson 正确解析', () {
      final json = {
        'created': 3,
        'skipped': 1,
      };
      final result = ImportResult.fromJson(json);
      expect(result.created, equals(3));
      expect(result.skipped, equals(1));
    });
  });
}
