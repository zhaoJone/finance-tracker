import '../../../core/api_client.dart';
import '../../../core/api_config.dart';
import 'bills_models.dart';

class BillsRepository {
  final ApiClient _client;

  BillsRepository(this._client);

  Future<List<Transaction>> listTransactions({
    String? type,
    int? year,
    int? month,
    int page = 1,
    int limit = 50,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
      'sort': '-created_at',
    };
    if (type != null) queryParams['type'] = type;
    if (year != null && month != null) {
      final startDate = '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-01';
      final nextMonth = month == 12 ? 1 : month + 1;
      final nextYear = month == 12 ? year + 1 : year;
      final endDate = '${nextYear.toString().padLeft(4, '0')}-${nextMonth.toString().padLeft(2, '0')}-01';
      queryParams['start_date'] = startDate;
      queryParams['end_date'] = endDate;
    }

    final response = await _client.dio.get(
      ApiConfig.transactionsEndpoint,
      queryParameters: queryParams,
    );
    final data = response.data as Map<String, dynamic>;
    final items = data['data'] as List;
    return items.map((e) => Transaction.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Transaction> createTransaction(TransactionCreate create) async {
    final response = await _client.dio.post(
      ApiConfig.transactionsEndpoint,
      data: create.toJson(),
    );
    final data = response.data as Map<String, dynamic>;
    return Transaction.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<Transaction> updateTransaction(String id, TransactionUpdate update) async {
    final response = await _client.dio.put(
      '${ApiConfig.transactionsEndpoint}/$id',
      data: update.toJson(),
    );
    final data = response.data as Map<String, dynamic>;
    return Transaction.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<void> deleteTransaction(String id) async {
    await _client.dio.delete('${ApiConfig.transactionsEndpoint}/$id');
  }
}
