import 'package:drift/drift.dart';

@DataClassName('BillItem')
class BillItems extends Table {
  TextColumn get id => text()();
  TextColumn get billId => text().customConstraint('NOT NULL REFERENCES bills(id) ON DELETE CASCADE')();
  TextColumn get productId => text()();
  TextColumn get productName => text()();
  TextColumn get unitType => text()(); // SINGLE or PACK
  IntColumn get quantity => integer()(); // Quantity of Single or Pack
  RealColumn get unitPrice => real()();
  IntColumn get equivalentPieces => integer()(); // Total pieces deducted for this line item
  RealColumn get totalPrice => real()();

  @override
  Set<Column> get primaryKey => {id};
}
