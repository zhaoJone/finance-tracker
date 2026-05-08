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

/// 解析银行通知文本（支持招商银行等主流银行格式）
///
/// 通用格式：
///   「您尾号1234的银行卡片于2024-01-01 12:00:00消费RMB 56.78元」
///   「您尾号1234的银行卡片ATM支取 RMB 200.00元」
///
/// 招商银行信用卡消费：
///   「【招商银行】您尾号8888的信用卡于05月01日12:30消费人民币128.00元」
/// 招商银行一卡通支出：
///   「【招商银行】您尾号6666的一卡通于05月01日12:30支出人民币500.00元」
/// 招商银行收款（入账）：
///   「【招商银行】您尾号6666的一卡通于05月01日12:30收到转账人民币1000.00元」
/// 招商银行还款：
///   「【招商银行】您尾号8888的信用卡于05月01日12:30还款人民币2000.00元」
ParsedNotification? parseBankNotification(String text) {
  // ---------- 金额提取 ----------
  // 招行格式：消费/支出/收到转账/还款 人民币X.XX元
  final cmbAmountMatch =
      RegExp(r'(?:消费|支出|收到转账|还款)人民币([\d.]+)元').firstMatch(text);
  // 通用格式：消费/支取 RMB X.XX元
  final genericAmountMatch = RegExp(
          r'(?:消费|支取)\s*(?:RMB\s*)?([\d.]+)')
      .firstMatch(text);

  String? amountStr;
  bool isIncome = false;
  if (cmbAmountMatch != null) {
    amountStr = cmbAmountMatch.group(1);
    // 如果是"收到转账"，是收入
    isIncome = text.contains('收到转账');
  } else if (genericAmountMatch != null) {
    amountStr = genericAmountMatch.group(1);
  }

  if (amountStr == null) return null;
  final amountFen = (double.parse(amountStr) * 100).round();

  // ---------- 时间提取 ----------
  DateTime timestamp = DateTime.now();
  // 招行格式：于05月01日12:30
  final cmbTimeMatch =
      RegExp(r'于(\d{1,2})月(\d{1,2})日(\d{1,2}):(\d{2})').firstMatch(text);
  if (cmbTimeMatch != null) {
    final month = int.parse(cmbTimeMatch.group(1)!);
    final day = int.parse(cmbTimeMatch.group(2)!);
    final hour = int.parse(cmbTimeMatch.group(3)!);
    final minute = int.parse(cmbTimeMatch.group(4)!);
    // 跨年处理：如果解析出的月份 > 当前月份，说明是去年
    int year = DateTime.now().year;
    if (month > DateTime.now().month) {
      year -= 1;
    }
    timestamp = DateTime(year, month, day, hour, minute);
  } else {
    // 通用格式：于2024-01-01 12:00:00
    final genericTimeMatch =
        RegExp(r'于(\d{4})-(\d{1,2})-(\d{1,2})\s+(\d{1,2}):(\d{2}):(\d{2})')
            .firstMatch(text);
    if (genericTimeMatch != null) {
      timestamp = DateTime(
        int.parse(genericTimeMatch.group(1)!),
        int.parse(genericTimeMatch.group(2)!),
        int.parse(genericTimeMatch.group(3)!),
        int.parse(genericTimeMatch.group(4)!),
        int.parse(genericTimeMatch.group(5)!),
        int.parse(genericTimeMatch.group(6)!),
      );
    }
  }

  // ---------- 商户/交易对方提取 ----------
  // 部分银行通知含商户名，如 "-XX超市"
  final merchantMatch = RegExp(r'[-—]([^-—\s]{2,10})$').firstMatch(text);
  final counterparty = merchantMatch?.group(1) ?? '';

  return ParsedNotification(
    source: 'bank',
    rawText: text,
    amount: amountFen,
    type: isIncome ? 'income' : 'expense',
    counterparty: counterparty,
    timestamp: timestamp,
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
    String? defaultCategoryId,
  }) async {
    final body = <String, dynamic>{
      'notifications': notifications.map((n) => n.toJson()).toList(),
    };
    if (defaultCategoryId != null && defaultCategoryId.isNotEmpty) {
      body['default_category_id'] = defaultCategoryId;
    }
    final response = await _client.dio.post(
      ApiConfig.importEndpoint,
      data: body,
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
