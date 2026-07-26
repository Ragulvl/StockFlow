import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';
import '../printer/print_queue.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

final printQueueProvider = Provider<PrintQueueManager>((ref) {
  return PrintQueueManager();
});
