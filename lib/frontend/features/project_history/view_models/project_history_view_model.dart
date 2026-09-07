import 'package:flutter/foundation.dart';

import '../data/project_history_repository.dart';

class ProjectHistoryViewModel extends ChangeNotifier {
  ProjectHistoryViewModel({this.repository = const ProjectHistoryRepository()});

  final ProjectHistoryRepository repository;
  final records = <Map<String, dynamic>>[];
  var isLoading = false;
  var lastError = '';

  Future<void> load() async {
    isLoading = true;
    lastError = '';
    notifyListeners();

    try {
      records
        ..clear()
        ..addAll(await repository.listInvoices());
    } catch (error) {
      lastError = error.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> save(Map<String, Object> invoice) async {
    records.insert(0, invoice);
    lastError = '';
    notifyListeners();

    try {
      final saved = await repository.saveInvoice(invoice);
      records[0] = saved;
      notifyListeners();
    } catch (error) {
      lastError = error.toString();
    }
  }
}
