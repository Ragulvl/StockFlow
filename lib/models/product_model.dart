class ProductModel {
  final String id;
  final String name;
  final String? description;
  final double piecePrice;
  final double packPrice;
  final int packSize; // Dynamic pieces per pack (e.g., 6, 10, 12, 24)
  final int stockInPieces; // Primary inventory stock maintained exclusively in pieces
  final int minStockAlert;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProductModel({
    required this.id,
    required this.name,
    this.description,
    required this.piecePrice,
    required this.packPrice,
    this.packSize = 10,
    required this.stockInPieces,
    this.minStockAlert = 50,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Dynamic helper: Full packs available
  int get availablePacks => stockInPieces ~/ packSize;

  /// Dynamic helper: Remaining single pieces
  int get availableRemainderPieces => stockInPieces % packSize;

  /// Stock status text e.g. "49 Packs + 9 Pcs"
  String get stockFormatted => '$availablePacks Pk + $availableRemainderPieces Pc ($stockInPieces Pcs Total)';

  bool get isLowStock => stockInPieces <= minStockAlert;

  ProductModel copyWith({
    String? id,
    String? name,
    String? description,
    double? piecePrice,
    double? packPrice,
    int? packSize,
    int? stockInPieces,
    int? minStockAlert,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      piecePrice: piecePrice ?? this.piecePrice,
      packPrice: packPrice ?? this.packPrice,
      packSize: packSize ?? this.packSize,
      stockInPieces: stockInPieces ?? this.stockInPieces,
      minStockAlert: minStockAlert ?? this.minStockAlert,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
