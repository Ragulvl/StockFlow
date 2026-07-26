import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/notifications/notification_service.dart';
import '../../../../core/printer/esc_pos_builder.dart';
import '../../../../core/printer/receipt_data.dart';
import '../../../../core/printer/usb_printer_adapter.dart';
import '../../../../core/services/app_update_service.dart';
import '../../../../core/theme/app_colors.dart';

import '../../../../core/theme/app_typography.dart';
import '../../../../repositories/settings_repository.dart';
import '../../../../providers/repository_providers.dart';


class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _taglineController;
  late TextEditingController _addressController;
  late TextEditingController _stateController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _panController;
  late TextEditingController _fssaiController;
  late TextEditingController _gstinController;
  late TextEditingController _bankHolderController;
  late TextEditingController _bankNameController;
  late TextEditingController _bankAccountController;
  late TextEditingController _bankIfscController;
  late TextEditingController _declarationController;
  late TextEditingController _footerController;

  bool _showBankDetails = false;
  bool _showPan = false;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isTestingPrinter = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _taglineController = TextEditingController();
    _addressController = TextEditingController();
    _stateController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
    _panController = TextEditingController();
    _fssaiController = TextEditingController();
    _gstinController = TextEditingController();
    _bankHolderController = TextEditingController();
    _bankNameController = TextEditingController();
    _bankAccountController = TextEditingController();
    _bankIfscController = TextEditingController();
    _declarationController = TextEditingController();
    _footerController = TextEditingController();

    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settingsRepo = ref.read(settingsRepositoryProvider);
    final settings = await settingsRepo.getStoreSettings();

    if (mounted) {
      setState(() {
        _nameController.text = settings.storeName;
        _taglineController.text = settings.storeTagline;
        _addressController.text = settings.storeAddress;
        _stateController.text = settings.storeState;
        _phoneController.text = settings.storePhone;
        _emailController.text = settings.storeEmail;
        _panController.text = settings.storePan;
        _fssaiController.text = settings.fssaiLicense;
        _gstinController.text = settings.gstin;
        _bankHolderController.text = settings.bankAccountName;
        _bankNameController.text = settings.bankName;
        _bankAccountController.text = settings.bankAccountNo;
        _bankIfscController.text = settings.bankIfsc;
        _declarationController.text = settings.storeDeclaration;
        _footerController.text = settings.receiptFooter;
        _showBankDetails = settings.showBankDetails;
        _showPan = settings.showPan;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _taglineController.dispose();
    _addressController.dispose();
    _stateController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _panController.dispose();
    _fssaiController.dispose();
    _gstinController.dispose();
    _bankHolderController.dispose();
    _bankNameController.dispose();
    _bankAccountController.dispose();
    _bankIfscController.dispose();
    _declarationController.dispose();
    _footerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.accentLime))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('App Settings & Hardware', style: AppTypography.headingMedium),
                            Text('Configure business details & USB ESC/POS thermal printer', style: AppTypography.bodySmall),
                          ],
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.surfaceCard,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: IconButton(
                            tooltip: 'System Diagnostics & Info',
                            icon: const Icon(Icons.settings_rounded, color: AppColors.accentLime),
                            onPressed: () => _showDiagnosticsModal(context),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),


                    // 1. USB Thermal Printer Discovery & Status Card
                    _buildPrinterStatusCard(),
                    const SizedBox(height: 24),

                    // 2. Offline Database Backup Card
                    _buildBackupCard(),
                    const SizedBox(height: 24),

                    // 3. Mobile System Notification Test Card
                    _buildNotificationCard(),
                    const SizedBox(height: 24),

                    // 4. Offline App Version & Auto-Update Card
                    _buildAppUpdateCard(),
                    const SizedBox(height: 24),



                    // 3. Store Profile Form
                    Text('Business & Receipt Header Settings', style: AppTypography.headingSmall),
                    const SizedBox(height: 12),

                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _nameController,
                            validator: (val) => val == null || val.trim().isEmpty ? 'Enter store name' : null,
                            decoration: const InputDecoration(
                              labelText: 'Store Name',
                              hintText: 'e.g. NK CHOCOLATES',
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _taglineController,
                            decoration: const InputDecoration(
                              labelText: 'Tagline',
                              hintText: 'e.g. Artisanal Chocolates & Gummies',
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _addressController,
                            decoration: const InputDecoration(
                              labelText: 'Store Address',
                              hintText: 'e.g. 165, Abiramy garden, podanur main road, Coimbatore - 641111',
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _stateController,
                            decoration: const InputDecoration(
                              labelText: 'State Name & Code',
                              hintText: 'e.g. Tamil Nadu, Code : 33',
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _phoneController,
                                  decoration: const InputDecoration(
                                    labelText: 'Store Phone',
                                    hintText: '8124722402',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextFormField(
                                  controller: _emailController,
                                  decoration: const InputDecoration(
                                    labelText: 'Store Email',
                                    hintText: 'jnanthakumar087@gmail.com',
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _panController,
                                  decoration: const InputDecoration(
                                    labelText: "Company's PAN",
                                    hintText: 'BZSPN0577R',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextFormField(
                                  controller: _gstinController,
                                  decoration: const InputDecoration(
                                    labelText: 'GSTIN',
                                    hintText: '33AAAAA0000A1Z5',
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _fssaiController,
                            decoration: const InputDecoration(
                              labelText: 'FSSAI License No.',
                              hintText: '10021043000987',
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Bank Details Section
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text("Company's Bank Details", style: AppTypography.headingSmall),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _bankHolderController,
                            decoration: const InputDecoration(
                              labelText: "A/c Holder's Name",
                              hintText: 'NK CHOCOLATES',
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _bankNameController,
                                  decoration: const InputDecoration(
                                    labelText: 'Bank Name',
                                    hintText: 'SBI',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextFormField(
                                  controller: _bankAccountController,
                                  decoration: const InputDecoration(
                                    labelText: 'A/c No.',
                                    hintText: '36817226323',
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _bankIfscController,
                            decoration: const InputDecoration(
                              labelText: 'Branch & IFS Code',
                              hintText: 'MELUR & SBIN0000258',
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Declaration & Footer
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text("Bill Terms & Declaration", style: AppTypography.headingSmall),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _declarationController,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              labelText: 'Declaration Text',
                              hintText: '1. Goods once sold will not be taken back...',
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _footerController,
                            decoration: const InputDecoration(
                              labelText: 'Receipt Footer Message',
                              hintText: 'This is a Computer Generated Invoice',
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Privacy & Bill Details Controls Section
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text("Bill Privacy & Show/Hide Controls", style: AppTypography.headingSmall),
                          ),
                          const SizedBox(height: 12),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Show Bank Details on Receipts', style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
                            subtitle: const Text('Keep OFF to hide Bank A/c & IFSC from customer bills', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                            value: _showBankDetails,
                            activeColor: AppColors.accentLime,
                            onChanged: (val) => setState(() => _showBankDetails = val),
                          ),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Show Company PAN on Receipts', style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
                            subtitle: const Text('Keep OFF to hide PAN number from customer bills', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                            value: _showPan,
                            activeColor: AppColors.accentLime,
                            onChanged: (val) => setState(() => _showPan = val),
                          ),
                          const SizedBox(height: 20),

                          ElevatedButton(
                            onPressed: _isSaving
                                ? null
                                : () async {
                                    if (!_formKey.currentState!.validate()) return;
                                    setState(() => _isSaving = true);
                                    try {
                                      final repo = ref.read(settingsRepositoryProvider);
                                      await repo.updateStoreSettings(
                                        StoreSettingsModel(
                                          storeName: _nameController.text.trim(),
                                          storeTagline: _taglineController.text.trim(),
                                          storeAddress: _addressController.text.trim(),
                                          storeState: _stateController.text.trim(),
                                          storePhone: _phoneController.text.trim(),
                                          storeEmail: _emailController.text.trim(),
                                          storePan: _panController.text.trim(),
                                          fssaiLicense: _fssaiController.text.trim(),
                                          gstin: _gstinController.text.trim(),
                                          bankAccountName: _bankHolderController.text.trim(),
                                          bankName: _bankNameController.text.trim(),
                                          bankAccountNo: _bankAccountController.text.trim(),
                                          bankIfsc: _bankIfscController.text.trim(),
                                          storeDeclaration: _declarationController.text.trim(),
                                          receiptFooter: _footerController.text.trim(),
                                          showBankDetails: _showBankDetails,
                                          showPan: _showPan,
                                        ),
                                      );

                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            backgroundColor: AppColors.accentLime,
                                            content: Text(
                                              'Settings updated successfully',
                                              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            backgroundColor: AppColors.danger,
                                            content: Text('Failed to save settings: $e'),
                                          ),
                                        );
                                      }
                                    } finally {
                                      if (mounted) setState(() => _isSaving = false);
                                    }
                                  },
                            child: _isSaving
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5),
                                  )
                                : const Text('Save Business Settings'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildPrinterStatusCard() {
    final printerRepo = ref.watch(printerRepositoryProvider);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.print_rounded, color: AppColors.accentLime, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('USB ESC/POS Thermal Printer', style: AppTypography.headingSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                          Text('Target: ${printerRepo.activeAdapter.name}', style: AppTypography.bodySmall.copyWith(color: AppColors.accentLime), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              FutureBuilder<bool>(
                future: printerRepo.checkPrinterAvailable(),
                builder: (context, snapshot) {
                  final bool isConnected = snapshot.data ?? false;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isConnected ? AppColors.accentLime.withValues(alpha: 0.2) : AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isConnected ? AppColors.accentLime : AppColors.border),
                    ),
                    child: Text(
                      isConnected ? 'USB Connected' : 'No Printer',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isConnected ? AppColors.accentLime : AppColors.textMuted,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Scan Connected Devices Button
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              minimumSize: Size.zero,
            ),
            onPressed: () async {
              final devices = await printerRepo.getConnectedUsbDevices();
              if (!mounted) return;

              showDialog(
                context: context,
                builder: (dialogContext) => StatefulBuilder(
                  builder: (context, setModalState) {
                    final currentAdapterName = printerRepo.activeAdapter.name;

                    return AlertDialog(
                      backgroundColor: AppColors.surfaceCard,
                      title: Text('Connected USB Devices', style: AppTypography.headingSmall),
                      content: devices.isEmpty
                          ? Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('No USB devices detected by Android OS.', style: TextStyle(color: AppColors.textSecondary)),
                                const SizedBox(height: 14),
                                Text('Troubleshooting Setup:', style: AppTypography.labelLarge),
                                const SizedBox(height: 6),
                                Text('1. Use a USB Type-C OTG Cable/Adapter to plug your printer into your phone.', style: AppTypography.bodySmall),
                                const SizedBox(height: 4),
                                Text('2. Ensure the thermal printer is powered ON (green light).', style: AppTypography.bodySmall),
                                const SizedBox(height: 4),
                                Text('3. Check if your phone requires turning ON "OTG Connection" in Android Settings.', style: AppTypography.bodySmall),
                              ],
                            )
                          : SizedBox(
                              width: double.maxFinite,
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: devices.length,
                                itemBuilder: (context, index) {
                                  final dev = devices[index];
                                  final bool isSelected = (dev.deviceName == currentAdapterName) ||
                                      (currentAdapterName == 'USB ESC/POS Printer' && dev.vid == 0x0456 && dev.pid == 0x0808);

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 6),
                                    decoration: BoxDecoration(
                                      color: isSelected ? AppColors.accentLime.withValues(alpha: 0.12) : AppColors.surface,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: isSelected ? AppColors.accentLime : AppColors.border),
                                    ),
                                    child: ListTile(
                                      leading: Icon(
                                        isSelected ? Icons.print_rounded : Icons.usb_rounded,
                                        color: isSelected ? AppColors.accentLime : AppColors.textMuted,
                                      ),
                                      title: Text(dev.deviceName, style: AppTypography.labelMedium.copyWith(color: isSelected ? AppColors.accentLime : AppColors.textPrimary)),
                                      subtitle: Text('VID: 0x${dev.vid?.toRadixString(16) ?? '0'} | PID: 0x${dev.pid?.toRadixString(16) ?? '0'}', style: AppTypography.bodySmall),
                                      trailing: isSelected
                                          ? Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                              decoration: BoxDecoration(
                                                color: AppColors.accentLime,
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: const Text('Active Printer ✓', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black)),
                                            )
                                          : ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                minimumSize: Size.zero,
                                              ),
                                              onPressed: () {
                                                printerRepo.setActiveAdapter(UsbPrinterAdapter(dev));
                                                setModalState(() {});
                                                setState(() {});
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    backgroundColor: AppColors.accentLime,
                                                    content: Text(
                                                      'Active printer updated: ${dev.deviceName}',
                                                      style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                                                    ),
                                                  ),
                                                );
                                              },
                                              child: const Text('Select Printer', style: TextStyle(fontSize: 10)),
                                            ),
                                    ),
                                  );
                                },
                              ),
                            ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          child: const Text('Close', style: TextStyle(color: AppColors.accentLime)),
                        ),
                      ],
                    );
                  },
                ),
              );
            },
            icon: const Icon(Icons.search_rounded, size: 16),
            label: const Text('Scan Connected USB Devices', style: TextStyle(fontSize: 12)),
          ),
          const SizedBox(height: 12),

          // Execute Test Print Button
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.surface,
              foregroundColor: AppColors.textPrimary,
              side: const BorderSide(color: AppColors.border),
            ),
            onPressed: _isTestingPrinter
                ? null
                : () async {
                    setState(() => _isTestingPrinter = true);
                    try {
                      final testData = ReceiptData(
                        storeName: _nameController.text.trim().isEmpty ? 'ChocoGummy Delights' : _nameController.text.trim(),
                        storeTagline: 'Hardware Test Print',
                        storeAddress: '123 Sweet Street, Candy City',
                        billNumber: 'TEST-0001',
                        dateTime: DateTime.now(),
                        paymentMethod: 'CASH',
                        items: [
                          ReceiptItemData(
                            name: 'Test Dark Gummy',
                            unitType: 'PACK',
                            quantity: 1,
                            unitPrice: 135.0,
                            totalPrice: 135.0,
                          ),
                        ],
                        subtotal: 135.0,
                        grandTotal: 135.0,
                        receiptFooter: 'Printer Test Successful!',
                      );

                      final testBytes = EscPosBuilder.buildReceiptBytes(testData);
                      final success = await printerRepo.printReceiptBytes(testBytes);

                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: success ? AppColors.accentLime : AppColors.danger,
                          content: Text(
                            success ? 'Test print dispatched successfully!' : 'Printer error: Connect printer via USB OTG adapter & allow permission',
                            style: TextStyle(color: success ? Colors.black : Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      );
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: AppColors.danger,
                          content: Text('Test print error: $e'),
                        ),
                      );
                    } finally {
                      if (mounted) setState(() => _isTestingPrinter = false);
                    }
                  },
            icon: const Icon(Icons.print_rounded, size: 18),
            label: _isTestingPrinter
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Execute ESC/POS Test Print'),
          ),
        ],
      ),
    );
  }

  Widget _buildBackupCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.cloud_upload_outlined, color: AppColors.accentYellow, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Database Backup', style: AppTypography.headingSmall),
                      Text(
                        'Export offline data for phone migration',
                        style: AppTypography.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              minimumSize: Size.zero,
            ),
            onPressed: () async {
              final backupRepo = ref.read(backupRepositoryProvider);
              final jsonBackup = await backupRepo.exportBackupJson();
              await Clipboard.setData(ClipboardData(text: jsonBackup));

              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: AppColors.accentLime,
                  content: Text(
                    'Database backup JSON copied to Clipboard!',
                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                ),
              );
            },
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: const Text('Export JSON', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  void _showDiagnosticsModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        bool isChecking = false;
        bool isDownloading = false;
        double downloadProgress = 0.0;
        AppUpdateInfo? updateInfo;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Dialog(
              backgroundColor: AppColors.surfaceCard,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: AppColors.border),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.accentLime.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.wifi_protected_setup_rounded, color: AppColors.accentLime, size: 24),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Wireless OTA Update Center', style: AppTypography.headingSmall),
                                    const Text('Remote Over-The-Air app update system', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: AppColors.textSecondary),
                          onPressed: () => Navigator.pop(dialogContext),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 1, color: AppColors.border),
                    const SizedBox(height: 16),

                    // Version Status Card
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.accentLime.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.verified_rounded, color: AppColors.accentLime, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Current Installed Build: v1.0.0+1', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
                                Text(
                                  updateInfo?.isUpdateAvailable == true
                                      ? 'New Version Available: v${updateInfo!.latestVersion}'
                                      : 'Status: App is up to date & verified',
                                  style: TextStyle(
                                    color: updateInfo?.isUpdateAvailable == true ? AppColors.accentYellow : AppColors.textSecondary,
                                    fontSize: 11,
                                    fontWeight: updateInfo?.isUpdateAvailable == true ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.accentLime.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              updateInfo?.isUpdateAvailable == true ? 'Update Ready' : 'Latest',
                              style: TextStyle(
                                color: updateInfo?.isUpdateAvailable == true ? AppColors.accentYellow : AppColors.accentLime,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Remote OTA Update Instructions Card
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.cloud_sync_rounded, color: AppColors.accentLime, size: 16),
                              SizedBox(width: 6),
                              Text('How Wireless OTA Updates Work:', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 12)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          const Text('• Developers in Coimbatore release a new update.', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                          const Text('• Customers in Bangalore tap "Check Wireless Update".', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                          const Text('• The app downloads the new APK over Wi-Fi/4G/5G and installs automatically on their phone.', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                          if (isDownloading) ...[
                            const SizedBox(height: 10),
                            LinearProgressIndicator(value: downloadProgress, backgroundColor: AppColors.border, color: AppColors.accentLime),
                            const SizedBox(height: 4),
                            Text('Downloading Update... ${(downloadProgress * 100).toStringAsFixed(0)}%', style: const TextStyle(color: AppColors.accentLime, fontSize: 11, fontWeight: FontWeight.bold)),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.border),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            onPressed: isChecking || isDownloading
                                ? null
                                : () async {
                                    setModalState(() => isChecking = true);
                                    final res = await AppUpdateService.instance.checkForUpdates();
                                    setModalState(() {
                                      updateInfo = res;
                                      isChecking = false;
                                    });
                                    if (dialogContext.mounted) {
                                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                                        SnackBar(
                                          backgroundColor: res.isUpdateAvailable ? AppColors.accentYellow : AppColors.accentLime,
                                          content: Text(
                                            res.isUpdateAvailable
                                                ? '🚀 Wireless Update Found! Version ${res.latestVersion} is ready to download.'
                                                : 'Checked! Version ${res.currentVersion} is active and up to date.',
                                            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      );
                                    }
                                  },
                            icon: isChecking
                                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textPrimary))
                                : const Icon(Icons.wifi_rounded, size: 16),
                            label: Text(isChecking ? 'Checking...' : 'Check Wireless Update', style: const TextStyle(fontSize: 11)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accentLime,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            onPressed: isDownloading
                                ? null
                                : () async {
                                    if (updateInfo?.isUpdateAvailable == true && updateInfo!.downloadUrl.isNotEmpty) {
                                      setModalState(() {
                                        isDownloading = true;
                                        downloadProgress = 0.0;
                                      });
                                      final file = await AppUpdateService.instance.downloadApk(
                                        updateInfo!.downloadUrl,
                                        (prog) => setModalState(() => downloadProgress = prog),
                                      );
                                      setModalState(() => isDownloading = false);

                                      if (file != null) {
                                        await AppUpdateService.instance.installDownloadedApk(file);
                                      }
                                    } else {
                                      Navigator.pop(dialogContext);
                                    }
                                  },
                            icon: Icon(updateInfo?.isUpdateAvailable == true ? Icons.cloud_download_rounded : Icons.check_circle_rounded, size: 16),
                            label: Text(
                              updateInfo?.isUpdateAvailable == true ? 'Download & Install' : 'Done',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }


  Widget _buildNotificationCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.notifications_active_rounded, color: AppColors.accentLime, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Mobile Notifications', style: AppTypography.headingSmall),
                      Text(
                        'Android status bar alerts for low stock',
                        style: AppTypography.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: Size.zero,
            ),
            onPressed: () async {
              await NotificationService.instance.showLowStockNotification(
                productName: 'Dark Chocolate Gummies',
                currentStock: 15,
              );
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: AppColors.accentLime,
                  content: Text(
                    'Mobile status bar notification sent! Check phone top bar.',
                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                ),
              );
            },
            icon: const Icon(Icons.send_rounded, size: 16),
            label: const Text('Send Test Alert', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildAppUpdateCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.system_update_rounded, color: AppColors.accentLime, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('App Version & Updates', style: AppTypography.headingSmall),
                      Text(
                        'v1.0.0+1 (Offline Version Control)',
                        style: AppTypography.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentLime,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: Size.zero,
            ),
            onPressed: () => _showDiagnosticsModal(context),
            icon: const Icon(Icons.download_rounded, size: 16),
            label: const Text('Update Center', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}



