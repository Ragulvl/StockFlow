import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';
import 'package:uuid/uuid.dart';

import 'tables/products_table.dart';
import 'tables/bills_table.dart';
import 'tables/bill_items_table.dart';
import 'tables/settings_table.dart';

part 'app_database.g.dart';

class BillWithItems {
  final Bill bill;
  final List<BillItem> items;

  BillWithItems({required this.bill, required this.items});
}

@DriftDatabase(tables: [Products, Bills, BillItems, Settings])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  // Initial Seed Data for Chocolate Gummies Business
  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        await _seedInitialData();
      },
    );
  }

  Future<void> _seedInitialData() async {
    const uuid = Uuid();
    final now = DateTime.now();

    // Default Chocolate Gummies Products
    final defaultProducts = [
      ProductsCompanion.insert(
        id: uuid.v4(),
        name: 'Dark Chocolate Gummies',
        description: const Value('70% Cocoa infused rich chocolate gummies'),
        piecePrice: 15.0,
        packPrice: 135.0, // 10% discount for 10 pieces pack
        packSize: const Value(10),
        stockInPieces: 500,
        minStockAlert: const Value(50),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
      ProductsCompanion.insert(
        id: uuid.v4(),
        name: 'Milk Chocolate Gummies',
        description: const Value('Creamy milk chocolate gummies'),
        piecePrice: 12.0,
        packPrice: 110.0,
        packSize: const Value(10),
        stockInPieces: 350,
        minStockAlert: const Value(40),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
      ProductsCompanion.insert(
        id: uuid.v4(),
        name: 'White Chocolate Gummies',
        description: const Value('Smooth white vanilla chocolate gummies'),
        piecePrice: 14.0,
        packPrice: 125.0,
        packSize: const Value(10),
        stockInPieces: 200,
        minStockAlert: const Value(30),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
      ProductsCompanion.insert(
        id: uuid.v4(),
        name: 'Caramel Fudge Gummies',
        description: const Value('Salted caramel fudge chocolate gummies'),
        piecePrice: 18.0,
        packPrice: 160.0,
        packSize: const Value(10),
        stockInPieces: 150,
        minStockAlert: const Value(25),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
      ProductsCompanion.insert(
        id: uuid.v4(),
        name: 'Hazelnut Crunch Gummies',
        description: const Value('Nutty hazelnut chocolate gummies'),
        piecePrice: 20.0,
        packPrice: 180.0,
        packSize: const Value(10),
        stockInPieces: 80,
        minStockAlert: const Value(20),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
    ];

    for (final p in defaultProducts) {
      await into(products).insert(p);
    }

    // Default Business Settings
    final defaultSettings = [
      const SettingsCompanion(key: Value('store_name'), value: Value('NK CHOCOLATES')),
      const SettingsCompanion(key: Value('store_tagline'), value: Value('Artisanal Chocolates & Gummies')),
      const SettingsCompanion(key: Value('store_address'), value: Value('165, Abiramy garden, podanur main road, Coimbatore - 641111')),
      const SettingsCompanion(key: Value('store_state'), value: Value('Tamil Nadu, Code : 33')),
      const SettingsCompanion(key: Value('store_phone'), value: Value('8124722402')),
      const SettingsCompanion(key: Value('store_email'), value: Value('jnanthakumar087@gmail.com')),
      const SettingsCompanion(key: Value('store_pan'), value: Value('BZSPN0577R')),
      const SettingsCompanion(key: Value('fssai_license'), value: Value('10021043000987')),
      const SettingsCompanion(key: Value('gstin'), value: Value('33AAAAA0000A1Z5')),
      const SettingsCompanion(key: Value('bank_account_name'), value: Value('NK CHOCOLATES')),
      const SettingsCompanion(key: Value('bank_name'), value: Value('SBI')),
      const SettingsCompanion(key: Value('bank_account_no'), value: Value('36817226323')),
      const SettingsCompanion(key: Value('bank_ifsc'), value: Value('MELUR & SBIN0000258')),
      const SettingsCompanion(key: Value('store_declaration'), value: Value('1. Goods once sold will not be taken back.\n2. Subject to coimbatore jurisdiction only.\n3. All claims for pilferage, shortage, damages must be reported immediately.')),
      const SettingsCompanion(key: Value('receipt_footer'), value: Value('This is a Computer Generated Invoice')),
    ];

    for (final s in defaultSettings) {
      await into(settings).insert(s);
    }
  }

  // Reactive DB queries
  Stream<List<Product>> watchAllProducts() {
    return (select(products)..orderBy([(t) => OrderingTerm(expression: t.name)])).watch();
  }

  Future<List<Product>> getAllProducts() {
    return (select(products)..orderBy([(t) => OrderingTerm(expression: t.name)])).get();
  }

  Future<Product?> getProductById(String id) {
    return (select(products)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<int> insertProduct(ProductsCompanion product) {
    return into(products).insert(product);
  }

  Future<bool> updateProduct(ProductsCompanion product) {
    return update(products).replace(product);
  }

  Future<int> deleteProduct(String id) {
    return (delete(products)..where((t) => t.id.equals(id))).go();
  }

  // Stock Management (In Pieces!)
  Future<void> adjustStock(String productId, int deltaPieces) async {
    return transaction(() async {
      final p = await getProductById(productId);
      if (p != null) {
        final newStock = p.stockInPieces + deltaPieces;
        await (update(products)..where((t) => t.id.equals(productId))).write(
          ProductsCompanion(
            stockInPieces: Value(newStock < 0 ? 0 : newStock),
            updatedAt: Value(DateTime.now()),
          ),
        );
      }
    });
  }

  // Atomic Checkout Transaction
  Future<BillWithItems> createBillTransaction({
    required Bill billData,
    required List<BillItem> itemsData,
  }) async {
    return transaction(() async {
      // 1. Insert Bill
      await into(bills).insert(billData);

      // 2. Insert Bill Items & Decrement Stock
      for (final item in itemsData) {
        await into(billItems).insert(item);

        // Deduct equivalent pieces atomically
        final product = await getProductById(item.productId);
        if (product != null) {
          final updatedPieces = product.stockInPieces - item.equivalentPieces;
          await (update(products)..where((t) => t.id.equals(item.productId))).write(
            ProductsCompanion(
              stockInPieces: Value(updatedPieces < 0 ? 0 : updatedPieces),
              updatedAt: Value(DateTime.now()),
            ),
          );
        }
      }

      return BillWithItems(bill: billData, items: itemsData);
    });
  }

  // Bills Queries
  Stream<List<Bill>> watchRecentBills() {
    return (select(bills)..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)])).watch();
  }

  Future<List<BillWithItems>> getAllBillsWithItems() async {
    final allBills = await (select(bills)..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)])).get();
    final result = <BillWithItems>[];
    for (final bill in allBills) {
      final items = await (select(billItems)..where((t) => t.billId.equals(bill.id))).get();
      result.add(BillWithItems(bill: bill, items: items));
    }
    return result;
  }

  Future<BillWithItems?> getBillWithItemsById(String billId) async {
    final bill = await (select(bills)..where((t) => t.id.equals(billId))).getSingleOrNull();
    if (bill == null) return null;
    final items = await (select(billItems)..where((t) => t.billId.equals(bill.id))).get();
    return BillWithItems(bill: bill, items: items);
  }

  Future<void> deleteAllBills() async {
    await delete(billItems).go();
    await delete(bills).go();
  }


  // Settings Queries
  Future<Map<String, String>> getAllSettings() async {
    final list = await select(settings).get();
    return {for (var item in list) item.key: item.value};
  }

  Future<void> updateSetting(String key, String value) async {
    await into(settings).insertOnConflictUpdate(SettingsCompanion(key: Value(key), value: Value(value)));
  }

  // Generate Unique Bill Number
  Future<String> generateNextBillNumber() async {
    final now = DateTime.now();
    final datePrefix = "${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}";
    final countToday = await (select(bills)..where((t) => t.billNumber.like('INV-$datePrefix-%'))).get();
    final nextSeq = (countToday.length + 1).toString().padLeft(4, '0');
    return 'INV-$datePrefix-$nextSeq';
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'stockflow.sqlite'));
    if (Platform.isAndroid) {
      await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
    }
    final cachebase = await getTemporaryDirectory();
    sqlite3.tempDirectory = cachebase.path;
    return NativeDatabase.createInBackground(file);
  });
}
