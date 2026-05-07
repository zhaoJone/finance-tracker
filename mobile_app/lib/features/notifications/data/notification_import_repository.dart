import 'package:crypto/crypto.dart';
import '../../../core/api_client.dart';
import '../../../core/api_config.dart';
import 'notification_models.dart';

/// 匹配规则：关键词 → 分类
class CategoryMatchRule {
  final String id;
  final String keyword;
  final String categoryId;
  final DateTime createdAt;

  const CategoryMatchRule({
    required this.id,
    required this.keyword,
    required this.categoryId,
    required this.createdAt,
  });

  factory CategoryMatchRule.fromJson(Map<String, dynamic> json) {
    return CategoryMatchRule(
      id: json['id'] as String,
      keyword: json['keyword'] as String,
      categoryId: json['category_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

/// CategoryMatchRule 数据仓库
class CategoryMatchRuleRepository {
  final ApiClient _client;

  CategoryMatchRuleRepository(this._client);

  /// 获取当前用户的所有匹配规则
  Future<List<CategoryMatchRule>> list() async {
    final response = await _client.dio.get(ApiConfig.matchRulesEndpoint);
    final body = response.data as Map<String, dynamic>;
    final items = body['data'] as List;
    return items
        .map((e) => CategoryMatchRule.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 创建匹配规则
  Future<CategoryMatchRule> create({
    required String keyword,
    required String categoryId,
  }) async {
    final response = await _client.dio.post(
      ApiConfig.matchRulesEndpoint,
      data: {'keyword': keyword, 'category_id': categoryId},
    );
    final body = response.data as Map<String, dynamic>;
    return CategoryMatchRule.fromJson(body['data'] as Map<String, dynamic>);
  }

  /// 删除匹配规则（目前移动端暂不实现，可后续添加）
  Future<void> delete(String id) async {
    await _client.dio.delete('${ApiConfig.matchRulesEndpoint}/$id');
  }
}

/// 解析支付宝通知文本
/// 「【支付宝】您有一笔支出，金额¥128.50，收款商家：麦当劳，已完成。28/04 14:32」
ParsedNotification? parseAlipayNotification(String text) {
  final amountMatch = RegExp(r'¥(\d+(?:\.\d{1,2})?)').firstMatch(text);
  if (amountMatch == null) return null;
  final amountFen = (double.parse(amountMatch.group(1)!) * 100).round();

  final merchantMatch = RegExp(r'收款商家[：:]([^\s，,]+)').firstMatch(text);
  final counterparty = merchantMatch?.group(1) ?? '';

  final timeMatch = RegExp(r'(\d{1,2})/(\d{1,2})\s+(\d{1,2}):(\d{1,2})').firstMatch(text);
  final timestamp = timeMatch != null
      ? DateTime(DateTime.now().year, int.parse(timeMatch.group(2)!),
          int.parse(timeMatch.group(1)!), int.parse(timeMatch.group(3)!),
          int.parse(timeMatch.group(4)!))
      : DateTime.now();

  return ParsedNotification(
    source: 'alipay',
    rawText: text,
    amount: amountFen,
    type: 'expense',
    counterparty: counterparty,
    timestamp: timestamp,
    tradeNo: _sha256(text),
  );
}

/// 解析微信通知文本
/// 「微信支付，¥58.00，哆来茶，28/04/26 14:32:24支付完成」
ParsedNotification? parseWechatNotification(String text) {
  final amountMatch = RegExp(r'¥(\d+(?:\.\d{1,2})?)').firstMatch(text);
  if (amountMatch == null) return null;
  final amountFen = (double.parse(amountMatch.group(1)!) * 100).round();

  final parts = text.split('，');
  final counterparty = parts.length >= 2 ? parts[parts.length - 2].trim() : '';

  final timeMatch =
      RegExp(r'(\d{2})/(\d{2})/(\d{2})\s+(\d{2}):(\d{2}):(\d{2})').firstMatch(text);
  final timestamp = timeMatch != null
      ? DateTime(2000 + int.parse(timeMatch.group(3)!),
          int.parse(timeMatch.group(2)!), int.parse(timeMatch.group(1)!),
          int.parse(timeMatch.group(4)!), int.parse(timeMatch.group(5)!))
      : DateTime.now();

  return ParsedNotification(
    source: 'wechat',
    rawText: text,
    amount: amountFen,
    type: 'expense',
    counterparty: counterparty,
    timestamp: timestamp,
    tradeNo: _sha256(text),
  );
}

/// 解析银行通知文本
/// 「您尾号1234的银行卡片于2024-01-01 12:00:00消费RMB 56.78元」
ParsedNotification? parseBankNotification(String text) {
  final consumptionMatch = RegExp(r'行卡.*?消费(?:RMB)?\s*([\d.]+)').firstMatch(text);
  final withdrawalMatch = RegExp(r'行卡.*?支取\s*(?:RMB\s*)?([\d.]+)').firstMatch(text);

  String? amountStr;
  if (consumptionMatch != null) {
    amountStr = consumptionMatch.group(1);
  } else if (withdrawalMatch != null) {
    amountStr = withdrawalMatch.group(1);
  }

  if (amountStr == null) return null;
  final amountFen = (double.parse(amountStr) * 100).round();

  return ParsedNotification(
    source: 'bank',
    rawText: text,
    amount: amountFen,
    type: 'expense',
    counterparty: '',
    timestamp: DateTime.now(),
    tradeNo: _sha256(text),
  );
}

String _sha256(String input) => sha256.convert(input.codeUnits).toString();

/// Notification Import 数据仓库
class NotificationImportRepository {
  final ApiClient _client;

  NotificationImportRepository(this._client);

  /// 批量导入通知 → 创建交易
  Future<ImportResult> importNotifications({
    required List<ParsedNotification> notifications,
    required String defaultCategoryId,
  }) async {
    final response = await _client.dio.post(
      ApiConfig.importEndpoint,
      queryParameters: {'default_category_id': defaultCategoryId},
      data: notifications.map((n) => n.toJson()).toList(),
    );

    final data = response.data as Map<String, dynamic>;
    return ImportResult.fromJson(data['data'] as Map<String, dynamic>);
  }

  /// 解析通知文本，返回 ParsedNotification
  /// source: 'alipay' | 'wechat' | 'bank'
  ParsedNotification? parseNotification({
    required String rawText,
    required String source,
  }) {
    switch (source) {
      case 'alipay':
        return parseAlipayNotification(rawText);
      case 'wechat':
        return parseWechatNotification(rawText);
      case 'bank':
        return parseBankNotification(rawText);
      default:
        return null;
    }
  }
}
