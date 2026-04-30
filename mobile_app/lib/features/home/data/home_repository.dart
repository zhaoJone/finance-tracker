import '../../../core/api_client.dart';
import '../../../core/api_config.dart';
import 'home_models.dart';

class HomeRepository {
  final ApiClient _client;

  HomeRepository(this._client);

  Future<MonthlySummary> getMonthlySummary({required int year, required int month}) async {
    final response = await _client.dio.get(
      '${ApiConfig.statsEndpoint}/monthly',
      queryParameters: {'year': year, 'month': month},
    );
    final body = response.data as Map<String, dynamic>;
    return MonthlySummary.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<CategoryBreakdownResponse> getCategoryBreakdown({required int year, required int month}) async {
    final startDate = '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-01';
    final nextMonth = month == 12 ? 1 : month + 1;
    final nextYear = month == 12 ? year + 1 : year;
    final endDate = '${nextYear.toString().padLeft(4, '0')}-${nextMonth.toString().padLeft(2, '0')}-01';

    final response = await _client.dio.get(
      '${ApiConfig.statsEndpoint}/by-category',
      queryParameters: {
        'start_date': startDate,
        'end_date': endDate,
      },
    );
    final body = response.data as Map<String, dynamic>;
    return CategoryBreakdownResponse.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<List<Transaction>> getRecentTransactions({required int year, required int month, int limit = 10}) async {
    final startDate = '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-01';
    final nextMonth = month == 12 ? 1 : month + 1;
    final nextYear = month == 12 ? year + 1 : year;
    final endDate = '${nextYear.toString().padLeft(4, '0')}-${nextMonth.toString().padLeft(2, '0')}-01';

    final response = await _client.dio.get(
      ApiConfig.transactionsEndpoint,
      queryParameters: {
        'start_date': startDate,
        'end_date': endDate,
        'limit': limit,
        'sort': '-created_at',
      },
    );
    final body = response.data as Map<String, dynamic>;
    final items = body['data'] as List;
    return items.map((e) => Transaction.fromJson(e as Map<String, dynamic>)).toList();
  }
}
