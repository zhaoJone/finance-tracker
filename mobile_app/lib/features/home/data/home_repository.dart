import '../../../core/api_client.dart';
import '../../../core/api_config.dart';
import 'home_models.dart';

class HomeRepository {
  final ApiClient _client;

  HomeRepository(this._client);

  Future<MonthlySummary> getMonthlySummary({required int year, required int month}) async {
    final response = await _client.dio.get(
      ApiConfig.transactionsEndpoint,
      queryParameters: {
        'year': year,
        'month': month,
        'summary': true,
      },
    );
    final data = response.data as Map<String, dynamic>;
    return MonthlySummary.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<CategoryBreakdown> getCategoryBreakdown({required int year, required int month}) async {
    final response = await _client.dio.get(
      ApiConfig.transactionsEndpoint,
      queryParameters: {
        'year': year,
        'month': month,
        'breakdown': true,
      },
    );
    final data = response.data as Map<String, dynamic>;
    return CategoryBreakdown.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<List<Transaction>> getRecentTransactions({required int year, required int month, int limit = 10}) async {
    final response = await _client.dio.get(
      ApiConfig.transactionsEndpoint,
      queryParameters: {
        'year': year,
        'month': month,
        'limit': limit,
        'sort': '-created_at',
      },
    );
    final data = response.data as Map<String, dynamic>;
    final items = data['data'] as List;
    return items.map((e) => Transaction.fromJson(e as Map<String, dynamic>)).toList();
  }
}
