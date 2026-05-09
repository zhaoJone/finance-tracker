/// 标准化通知解析结果（与后端 ParsedNotification 对齐）
class ParsedNotification {
  final String source; // "alipay" | "wechat" | "bank"
  final String rawText;
  final int amount; // 单位：分（fen）
  final String type; // "income" | "expense"
  final String counterparty;
  final DateTime timestamp;
  final String tradeNo;
  String? categoryId; // 可选的分类 ID

  /// 解析失败标记：告警/微信/招商银行的原始通知无法解析时保留原文
  final bool isUnparsed;

  ParsedNotification({
    required this.source,
    required this.rawText,
    required this.amount,
    required this.type,
    required this.counterparty,
    required this.timestamp,
    required this.tradeNo,
    this.categoryId,
    this.isUnparsed = false,
  });

  Map<String, dynamic> toJson() => {
        'source': source,
        'raw_text': rawText,
        'amount': amount,
        'type': type,
        'counterparty': counterparty,
        'timestamp': timestamp.toIso8601String(),
        'trade_no': tradeNo,
        if (categoryId != null) 'category_id': categoryId,
      };

  factory ParsedNotification.fromJson(Map<String, dynamic> json) {
    return ParsedNotification(
      source: json['source'] as String,
      rawText: json['raw_text'] as String,
      amount: json['amount'] as int,
      type: json['type'] as String,
      counterparty: (json['counterparty'] as String?) ?? '',
      timestamp: DateTime.parse(json['timestamp'] as String),
      tradeNo: (json['trade_no'] as String?) ?? '',
      categoryId: json['category_id'] as String?,
    );
  }
}

/// 导入结果
class ImportResult {
  final int created;
  final int skipped;

  ImportResult({required this.created, required this.skipped});

  factory ImportResult.fromJson(Map<String, dynamic> json) {
    return ImportResult(
      created: json['created'] as int,
      skipped: json['skipped'] as int,
    );
  }
}

/// 云端解析结果（与后端 RawParseResponseData 对齐）
class CloudParseResult {
  final ParsedNotification? parsed;
  final String? sourceHint;

  const CloudParseResult({this.parsed, this.sourceHint});

  factory CloudParseResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>?;
    if (data == null) return const CloudParseResult();
    return CloudParseResult(
      parsed: data['parsed'] != null
          ? ParsedNotification.fromJson(data['parsed'] as Map<String, dynamic>)
          : null,
      sourceHint: data['source_hint'] as String?,
    );
  }

  bool get isParsed => parsed != null;
}
