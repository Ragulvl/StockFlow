import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/providers/core_providers.dart';
import '../repositories/backup_repository.dart';
import '../repositories/bill_repository.dart';
import '../repositories/inventory_repository.dart';
import '../repositories/printer_repository.dart';
import '../repositories/settings_repository.dart';

final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return InventoryRepository(db);
});

final billRepositoryProvider = Provider<BillRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return BillRepository(db);
});

final printerRepositoryProvider = Provider<PrinterRepository>((ref) {
  final queue = ref.watch(printQueueProvider);
  return PrinterRepository(queue);
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return SettingsRepository(db);
});

final backupRepositoryProvider = Provider<BackupRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return BackupRepository(db);
});
