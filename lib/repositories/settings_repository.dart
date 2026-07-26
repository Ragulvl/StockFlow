import '../core/database/app_database.dart';
import '../core/logger/app_logger.dart';

class StoreSettingsModel {
  final String storeName;
  final String storeTagline;
  final String storeAddress;
  final String storeState;
  final String storePhone;
  final String storeEmail;
  final String storePan;
  final String fssaiLicense;
  final String gstin;
  final String bankAccountName;
  final String bankName;
  final String bankAccountNo;
  final String bankIfsc;
  final String storeDeclaration;
  final String receiptFooter;
  final bool showBankDetails;
  final bool showPan;

  StoreSettingsModel({
    required this.storeName,
    required this.storeTagline,
    required this.storeAddress,
    required this.storeState,
    required this.storePhone,
    required this.storeEmail,
    required this.storePan,
    required this.fssaiLicense,
    required this.gstin,
    required this.bankAccountName,
    required this.bankName,
    required this.bankAccountNo,
    required this.bankIfsc,
    required this.storeDeclaration,
    required this.receiptFooter,
    this.showBankDetails = false,
    this.showPan = false,
  });

  factory StoreSettingsModel.fromMap(Map<String, String> map) {
    final rawName = map['store_name'];
    final rawAddress = map['store_address'];
    final rawPhone = map['store_phone'];
    final rawTagline = map['store_tagline'];

    final bool isLegacyDefault = rawName == null || rawName == 'ChocoGummy Delights' || rawAddress == '123 Sweet Street, Candy City';

    return StoreSettingsModel(
      storeName: isLegacyDefault ? 'NK CHOCOLATES' : rawName,
      storeTagline: isLegacyDefault ? '' : (rawTagline ?? ''),
      storeAddress: isLegacyDefault ? '165, Abiramy garden, podanur main road, Coimbatore - 641111' : (rawAddress ?? ''),
      storeState: map['store_state'] ?? 'Tamil Nadu, Code : 33',
      storePhone: isLegacyDefault ? '8124722402' : (rawPhone ?? ''),
      storeEmail: map['store_email'] ?? '',
      storePan: map['store_pan'] ?? '',
      fssaiLicense: map['fssai_license'] ?? '',
      gstin: map['gstin'] ?? '',
      bankAccountName: map['bank_account_name'] ?? '',
      bankName: map['bank_name'] ?? '',
      bankAccountNo: map['bank_account_no'] ?? '',
      bankIfsc: map['bank_ifsc'] ?? '',
      storeDeclaration: map['store_declaration'] ??
          '1. Goods once sold will not be taken back.\n2. Subject to coimbatore jurisdiction only.',
      receiptFooter: (map['receipt_footer'] == 'Thank you for your visit! Enjoy your gummies!' || map['receipt_footer'] == null)
          ? 'This is a Computer Generated Invoice'
          : map['receipt_footer']!,
      showBankDetails: map['show_bank_details'] == 'true',
      showPan: map['show_pan'] == 'true',
    );
  }
}

class SettingsRepository {
  final AppDatabase _db;

  SettingsRepository(this._db);

  Future<StoreSettingsModel> getStoreSettings() async {
    final map = await _db.getAllSettings();
    final model = StoreSettingsModel.fromMap(map);

    // Auto-migrate legacy default values on existing device databases
    if (map['store_name'] == 'ChocoGummy Delights' || map['store_name'] == null) {
      await updateStoreSettings(model);
    }

    return model;
  }

  Future<void> updateStoreSettings(StoreSettingsModel settings) async {
    AppLogger.info("Updating store settings in SQLite", "SettingsRepository");
    await _db.updateSetting('store_name', settings.storeName);
    await _db.updateSetting('store_tagline', settings.storeTagline);
    await _db.updateSetting('store_address', settings.storeAddress);
    await _db.updateSetting('store_state', settings.storeState);
    await _db.updateSetting('store_phone', settings.storePhone);
    await _db.updateSetting('store_email', settings.storeEmail);
    await _db.updateSetting('store_pan', settings.storePan);
    await _db.updateSetting('fssai_license', settings.fssaiLicense);
    await _db.updateSetting('gstin', settings.gstin);
    await _db.updateSetting('bank_account_name', settings.bankAccountName);
    await _db.updateSetting('bank_name', settings.bankName);
    await _db.updateSetting('bank_account_no', settings.bankAccountNo);
    await _db.updateSetting('bank_ifsc', settings.bankIfsc);
    await _db.updateSetting('store_declaration', settings.storeDeclaration);
    await _db.updateSetting('receipt_footer', settings.receiptFooter);
    await _db.updateSetting('show_bank_details', settings.showBankDetails.toString());
    await _db.updateSetting('show_pan', settings.showPan.toString());
  }
}
