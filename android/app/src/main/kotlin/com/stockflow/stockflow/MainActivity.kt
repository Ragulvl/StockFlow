package com.stockflow.stockflow

import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.hardware.usb.*
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val PRINTER_CHANNEL = "com.stockflow.stockflow/usb_printer"
    private val UPDATE_CHANNEL = "com.stockflow.stockflow/app_update"
    private val ACTION_USB_PERMISSION = "com.stockflow.stockflow.USB_PERMISSION"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // 1. Production App Update MethodChannel Handler with Edge-case Controls
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, UPDATE_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getSelfApkPath" -> {
                    try {
                        val apkPath = context.applicationInfo.sourceDir
                        result.success(apkPath)
                    } catch (e: Exception) {
                        result.error("PATH_ERROR", e.message, null)
                    }
                }

                "getAppVersion" -> {
                    try {
                        val pInfo = packageManager.getPackageInfo(packageName, 0)
                        val version = pInfo.versionName ?: "1.0.0"
                        val versionCode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) pInfo.longVersionCode else pInfo.versionCode.toLong()
                        result.success(mapOf("versionName" to version, "versionCode" to versionCode))
                    } catch (e: Exception) {
                        result.error("VERSION_ERROR", e.message, null)
                    }
                }

                "checkInstallPermission" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        result.success(packageManager.canRequestPackageInstalls())
                    } else {
                        result.success(true)
                    }
                }

                "openInstallPermissionSettings" -> {
                    try {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            val intent = Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES).apply {
                                data = Uri.parse("package:$packageName")
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            }
                            startActivity(intent)
                            result.success(true)
                        } else {
                            result.success(true)
                        }
                    } catch (e: Exception) {
                        result.error("PERMISSION_INTENT_FAILED", e.message, null)
                    }
                }

                "installApkFile" -> {
                    val filePath = call.argument<String>("path")
                    if (filePath == null) {
                        result.error("INVALID_PATH", "APK file path is null", null)
                        return@setMethodCallHandler
                    }

                    try {
                        val file = File(filePath)
                        if (!file.exists()) {
                            result.error("FILE_NOT_FOUND", "APK file does not exist at $filePath", null)
                            return@setMethodCallHandler
                        }

                        // Check unknown sources installation permission on Android 8.0+
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && !packageManager.canRequestPackageInstalls()) {
                            val permIntent = Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES).apply {
                                data = Uri.parse("package:$packageName")
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            }
                            startActivity(permIntent)
                            result.error("PERMISSION_REQUIRED", "Please allow 'Install Unknown Apps' permission in Settings screen.", null)
                            return@setMethodCallHandler
                        }

                        val intent = Intent(Intent.ACTION_VIEW).apply {
                            val apkUri = FileProvider.getUriForFile(
                                context,
                                "${context.packageName}.fileprovider",
                                file
                            )
                            setDataAndType(apkUri, "application/vnd.android.package-archive")
                            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
                            putExtra(Intent.EXTRA_NOT_UNKNOWN_SOURCE, true)
                        }

                        context.startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("INSTALL_ERROR", e.message, null)
                    }
                }

                else -> result.notImplemented()
            }
        }

        // 2. USB Thermal Printer MethodChannel Handler
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PRINTER_CHANNEL).setMethodCallHandler { call, result ->
            val usbManager = getSystemService(Context.USB_SERVICE) as UsbManager

            when (call.method) {
                "getConnectedUsbDevices" -> {
                    val deviceList = mutableListOf<Map<String, Any?>>()
                    for ((_, device) in usbManager.deviceList) {
                        val map = mapOf(
                            "deviceName" to device.deviceName,
                            "vendorId" to device.vendorId,
                            "productId" to device.productId,
                            "productName" to if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) device.productName else "USB Device",
                            "manufacturerName" to if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) device.manufacturerName else "Unknown"
                        )
                        deviceList.add(map)
                    }
                    result.success(deviceList)
                }

                "printRawBytes" -> {
                    val bytes = call.argument<ByteArray>("bytes")
                    val vendorId = call.argument<Int>("vendorId")
                    val productId = call.argument<Int>("productId")
                    val targetName = call.argument<String>("deviceName")

                    if (bytes == null) {
                        result.error("INVALID_ARGS", "Bytes array is null", null)
                        return@setMethodCallHandler
                    }

                    var targetDevice: UsbDevice? = null
                    for ((_, device) in usbManager.deviceList) {
                        if (targetName != null && device.deviceName == targetName) {
                            targetDevice = device
                            break
                        }
                        if (vendorId != null && productId != null && device.vendorId == vendorId && device.productId == productId) {
                            targetDevice = device
                            break
                        }
                    }

                    if (targetDevice == null) {
                        for ((_, device) in usbManager.deviceList) {
                            if (device.vendorId == 0x0456 || device.vendorId == 0x0416 || device.vendorId == 0x0483 || device.vendorId == 0x1a86) {
                                targetDevice = device
                                break
                            }
                        }
                    }

                    if (targetDevice == null) {
                        for ((_, device) in usbManager.deviceList) {
                            if (device.vendorId != 0x05e3 && device.vendorId != 0x0bda && device.vendorId != 0x343c) {
                                targetDevice = device
                                break
                            }
                        }
                    }

                    if (targetDevice == null && usbManager.deviceList.isNotEmpty()) {
                        targetDevice = usbManager.deviceList.values.first()
                    }

                    if (targetDevice == null) {
                        result.error("NO_DEVICE", "No USB printer device found", null)
                        return@setMethodCallHandler
                    }

                    if (!usbManager.hasPermission(targetDevice)) {
                        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0
                        val permissionIntent = PendingIntent.getBroadcast(this, 0, Intent(ACTION_USB_PERMISSION), flags)
                        usbManager.requestPermission(targetDevice, permissionIntent)
                        result.error("PERMISSION_DENIED", "USB Permission required for ${targetDevice.deviceName}. Please tap ALLOW on phone screen.", null)
                        return@setMethodCallHandler
                    }

                    val success = sendBulkTransfer(usbManager, targetDevice, bytes)
                    if (success) {
                        result.success(true)
                    } else {
                        result.error("PRINT_FAILED", "Bulk transfer failed on ${targetDevice.deviceName}", null)
                    }
                }

                else -> result.notImplemented()
            }
        }
    }

    private fun sendBulkTransfer(usbManager: UsbManager, device: UsbDevice, bytes: ByteArray): Boolean {
        val connection: UsbDeviceConnection = usbManager.openDevice(device) ?: return false

        try {
            for (i in 0 until device.interfaceCount) {
                val usbInterface: UsbInterface = device.getInterface(i)
                val claimed = connection.claimInterface(usbInterface, true)
                if (!claimed) continue

                for (j in 0 until usbInterface.endpointCount) {
                    val endpoint: UsbEndpoint = usbInterface.getEndpoint(j)
                    if (endpoint.direction == UsbConstants.USB_DIR_OUT) {
                        val chunkSize = 4096
                        var offset = 0
                        var overallSuccess = true

                        while (offset < bytes.size) {
                            val length = Math.min(chunkSize, bytes.size - offset)
                            val chunk = ByteArray(length)
                            System.arraycopy(bytes, offset, chunk, 0, length)
                            val transferResult = connection.bulkTransfer(endpoint, chunk, length, 2000)
                            if (transferResult < 0) {
                                overallSuccess = false
                                break
                            }
                            offset += length
                        }

                        connection.releaseInterface(usbInterface)
                        connection.close()
                        if (overallSuccess) return true
                    }
                }
                connection.releaseInterface(usbInterface)
            }
        } catch (e: Exception) {
            e.printStackTrace()
        } finally {
            try {
                connection.close()
            } catch (_: Exception) {}
        }
        return false
    }
}
