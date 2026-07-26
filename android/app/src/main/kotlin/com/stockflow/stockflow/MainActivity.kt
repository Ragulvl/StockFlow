package com.stockflow.stockflow

import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.hardware.usb.*
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.stockflow.stockflow/usb_printer"
    private val ACTION_USB_PERMISSION = "com.stockflow.stockflow.USB_PERMISSION"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
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
