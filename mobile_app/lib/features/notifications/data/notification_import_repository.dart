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

  /// 删除匹配规则
  Future<void> delete(String id) async {
    await _client.dio.delete('${ApiConfig.matchRulesEndpoint}/$id');
  }
}

/// Notification Import 数据仓库 — 所有解析由后端完成
class NotificationImportRepository {
  final ApiClient _client;

  NotificationImportRepository(this._client);

  /// 发送原始通知到后端解析（纯云端，无本地降级）
  Future<CloudParseResult> parseViaCloud({
    required String rawText,
    String? sourceHint,
  }) async {
    try {
      final response = await _client.dio.post(
        ApiConfig.rawParseEndpoint,
        data: {
          'raw_text': rawText,
          if (sourceHint != null) 'source_hint': sourceHint,
        },
      );
      return CloudParseResult.fromJson(response.data as Map<String, dynamic>);
    } catch (_) {
      // 网络错误 → 返回空结果，前端标记为未解析
      return const CloudParseResult();
    }
  }

  /// 批量导入通知 → 创建交易
  Future<ImportResult> importNotifications({
    required List<ParsedNotification> notifications,
    String? defaultCategoryId,
  }) async {
    final queryParams = <String, dynamic>{};
    if (defaultCategoryId != null && defaultCategoryId.isNotEmpty) {
      queryParams['default_category_id'] = defaultCategoryId;
    }
    final response = await _client.dio.post(
      ApiConfig.importEndpoint,
      data: notifications.map((n) => n.toJson()).toList(),
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    final data = response.data as Map<String, dynamic>;
    return ImportResult.fromJson(data['data'] as Map<String, dynamic>);
  }
}
