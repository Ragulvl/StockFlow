import 'package:drift/drift.dart';

@DataClassName('Product')
class Products extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get description => text().nullable()();
  RealColumn get piecePrice => real()();
  RealColumn get packPrice => real()();
  IntColumn get packSize => integer().withDefault(const Constant(10))();
  IntColumn get stockInPieces => integer()(); // Primary stock tracked exclusively in pieces
  IntColumn get minStockAlert => integer().withDefault(const Constant(50))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
