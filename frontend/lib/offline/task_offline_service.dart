import 'task_offline_dao.dart';
import 'task_offline_entity.dart';
import 'sync_status_offline.dart';

class TaskOfflineService {
  final TaskOfflineDao _dao = TaskOfflineDao();

  Future<void> saveOffline({
    required String title,
    String? description,
    required String status,
    required String createdDate,
  }) async {
    final task = TaskOfflineEntity(
      title: title,
      description: description,
      status: status,
      createdDate: createdDate,
      syncStatus: SyncStatusOffline.pending,
    );

    await _dao.insert(task);
  }
}
