import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../core/database/app_database.dart';
import '../core/logger/app_logger.dart';
import '../core/notifications/notification_service.dart';
import '../models/product_model.dart';

class InventoryRepository {
  final AppDatabase _db;

  InventoryRepository(this._db);

  ProductModel _mapToDomain(Product p) {
    return ProductModel(
      id: p.id,
      name: p.name,
      description: p.description,
      piecePrice: p.piecePrice,
      packPrice: p.packPrice,
      packSize: p.packSize,
      stockInPieces: p.stockInPieces,
      minStockAlert: p.minStockAlert,
      createdAt: p.createdAt,
      updatedAt: p.updatedAt,
    );
  }

  Stream<List<ProductModel>> watchProducts() {
    return _db.watchAllProducts().map((list) => list.map(_mapToDomain).toList());
  }

  Future<List<ProductModel>> getAllProducts() async {
    final list = await _db.getAllProducts();
    return list.map(_mapToDomain).toList();
  }

  Future<ProductModel?> getProductById(String id) async {
    final p = await _db.getProductById(id);
    return p != null ? _mapToDomain(p) : null;
  }

  Future<void> addProduct({
    required String name,
    String? description,
    required double piecePrice,
    required double packPrice,
    int packSize = 10,
    required int initialStockInPieces,
    int minStockAlert = 50,
  }) async {
    const uuid = Uuid();
    final now = DateTime.now();
    AppLogger.info("Adding new product: $name with packSize: $packSize", "InventoryRepository");

    await _db.insertProduct(
      ProductsCompanion.insert(
        id: uuid.v4(),
        name: name,
        description: Value(description),
        piecePrice: piecePrice,
        packPrice: packPrice,
        packSize: Value(packSize),
        stockInPieces: initialStockInPieces,
        minStockAlert: Value(minStockAlert),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
    );

    if (initialStockInPieces <= minStockAlert) {
      await NotificationService.instance.showLowStockNotification(
        productName: name,
        currentStock: initialStockInPieces,
      );
    }
  }

  Future<void> updateProduct(ProductModel product) async {
    AppLogger.info("Updating product: ${product.name} (id: ${product.id})", "InventoryRepository");
    await _db.updateProduct(
      ProductsCompanion(
        id: Value(product.id),
        name: Value(product.name),
        description: Value(product.description),
        piecePrice: Value(product.piecePrice),
        packPrice: Value(product.packPrice),
        packSize: Value(product.packSize),
        stockInPieces: Value(product.stockInPieces),
        minStockAlert: Value(product.minStockAlert),
        updatedAt: Value(DateTime.now()),
      ),
    );

    if (product.isLowStock) {
      await NotificationService.instance.showLowStockNotification(
        productName: product.name,
        currentStock: product.stockInPieces,
      );
    }
  }

  Future<void> deleteProduct(String id) async {
    AppLogger.info("Deleting product id: $id", "InventoryRepository");
    await _db.deleteProduct(id);
  }

  /// Adjust stock in total pieces. [deltaPieces] can be positive (add) or negative (deduct).
  Future<void> adjustStock(String productId, int deltaPieces) async {
    AppLogger.info("Adjusting stock for product $productId by $deltaPieces pieces", "InventoryRepository");
    await _db.adjustStock(productId, deltaPieces);

    final updated = await getProductById(productId);
    if (updated != null && updated.isLowStock) {
      await NotificationService.instance.showLowStockNotification(
        productName: updated.name,
        currentStock: updated.stockInPieces,
      );
    }
  }
}

