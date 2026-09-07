import '../../../core/api/api_client.dart';

class ProjectHistoryRepository {
  const ProjectHistoryRepository({this.apiClient = const ApiClient()});

  final ApiClient apiClient;

  Future<List<Map<String, dynamic>>> listInvoices() async {
    final body = await apiClient.getJson('/api/projectHistory');
    final data = body['data'] as List<dynamic>? ?? const [];
    return data.whereType<Map<String, dynamic>>().toList();
  }

  Future<Map<String, dynamic>> saveInvoice(Map<String, Object> invoice) async {
    final body = await apiClient.postJson('/api/projectHistory', invoice);
    return body['data'] as Map<String, dynamic>;
  }
}
