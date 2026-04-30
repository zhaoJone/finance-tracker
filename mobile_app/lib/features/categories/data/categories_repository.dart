import '../../../core/api_client.dart';
import '../../../core/api_config.dart';
import 'categories_models.dart';

class CategoriesRepository {
  final ApiClient _client;

  CategoriesRepository(this._client);

  Future<List<Category>> listCategories({String? type}) async {
    final queryParams = <String, dynamic>{};
    if (type != null) queryParams['type'] = type;

    final response = await _client.dio.get(
      ApiConfig.categoriesEndpoint,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );
    final data = response.data as Map<String, dynamic>;
    final categoriesData = data['data'] as Map<String, dynamic>;
    final incomeList = (categoriesData['income'] as List?) ?? [];
    final expenseList = (categoriesData['expense'] as List?) ?? [];
    final all = [...incomeList, ...expenseList];
    return all.map((e) => Category.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Category> createCategory(Category category) async {
    final response = await _client.dio.post(
      ApiConfig.categoriesEndpoint,
      data: category.toJson(),
    );
    final data = response.data as Map<String, dynamic>;
    return Category.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<Category> updateCategory(String id, Category category) async {
    final response = await _client.dio.patch(
      '${ApiConfig.categoriesEndpoint}/$id',
      data: category.toJson(),
    );
    final data = response.data as Map<String, dynamic>;
    return Category.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<void> deleteCategory(String id) async {
    await _client.dio.delete('${ApiConfig.categoriesEndpoint}/$id');
  }
}
