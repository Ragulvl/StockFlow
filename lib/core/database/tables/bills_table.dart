import 'package:drift/drift.dart';

@DataClassName('Bill')
class Bills extends Table {
  TextColumn get id => text()();
  TextColumn get billNumber => text().unique()();
  RealColumn get subtotal => real()();
  RealColumn get discount => real().withDefault(const Constant(0.0))();
  RealColumn get tax => real().withDefault(const Constant(0.0))();
  RealColumn get grandTotal => real()();
  TextColumn get paymentMethod => text()(); // CASH, UPI, CARD
  RealColumn get amountTendered => real().withDefault(const Constant(0.0))();
  RealColumn get changeReturned => real().withDefault(const Constant(0.0))();
  TextColumn get customerName => text().nullable()();
  TextColumn get customerPhone => text().nullable()();
  TextColumn get customerAddress => text().nullable()();
  TextColumn get customerState => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
