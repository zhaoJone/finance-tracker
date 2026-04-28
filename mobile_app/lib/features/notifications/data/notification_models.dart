/// 标准化通知解析结果（与后端 ParsedNotification 对齐）
class ParsedNotification {
  final String source; // "alipay" | "wechat" | "bank"
  final String rawText;
  final int amount; // 单位：分（fen）
  final String type; // "income" | "expense"
  final String counterparty;
  final DateTime timestamp;
  final String tradeNo;

  const ParsedNotification({
    required this.source,
    required this.rawText,
    required this.amount,
    required this.type,
    required this.counterparty,
    required this.timestamp,
    required this.tradeNo,
  });

  Map<String, dynamic> toJson() => {
        'source': source,
        'raw_text': rawText,
        'amount': amount,
        'type': type,
        'counterparty': counterparty,
        'timestamp': timestamp.toIso8601String(),
        'trade_no': tradeNo,
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
