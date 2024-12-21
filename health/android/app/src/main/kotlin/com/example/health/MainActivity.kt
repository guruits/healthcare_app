package com.example.health

import android.Manifest
import android.bluetooth.*
import android.content.pm.PackageManager
import android.os.Bundle
import android.util.Log
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.IOException
import android.content.Context
import java.util.UUID
import android.os.Handler
import android.os.Looper
import android.os.Build
import java.io.OutputStream
import java.io.ByteArrayOutputStream
import java.io.InputStream
import android.net.Uri
import androidx.core.content.FileProvider
import java.io.File
private val ACK_TIMEOUT = 5000L

class MainActivity: FlutterActivity() {
    private val TAG = "BluetoothFile"
    private val CHANNEL = "bluetooth_health"

    private val REQUEST_BLUETOOTH_PERMISSIONS = 1
    private val REQUEST_STORAGE_PERMISSION = 2
    private var bluetoothAdapter: BluetoothAdapter? = null
    private var bluetoothGatt: BluetoothGatt? = null
    private var classicSocket: BluetoothSocket? = null
    private val handler = Handler(Looper.getMainLooper())

    private val SPP_UUID = UUID.fromString("00001101-0000-1000-8000-00805F9B34FB")
    private val OPP_UUID = UUID.fromString("00001105-0000-1000-8000-00805f9b34fb")
    private var outputStream: OutputStream? = null
    private var inputStream: InputStream? = null
    private var currentConnectedDevice: BluetoothDevice? = null
    private var isConnected = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Log.d("Bluetooth", "MainActivity onCreate")

        val bluetoothManager = getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
        bluetoothAdapter = bluetoothManager.adapter

        if (bluetoothAdapter == null) {
            Log.e("Bluetooth", "Bluetooth not supported on this device.")
            return
        }

        if (!hasBluetoothPermissions()) {
            Log.d("Bluetooth", "Requesting Bluetooth permissions")
            requestBluetoothPermissions()
        }

        setupMethodChannel()
    }

    private fun setupMethodChannel() {
        flutterEngine?.let { engine ->
            Log.d("Bluetooth", "Setting up MethodChannel")
            MethodChannel(
                engine.dartExecutor.binaryMessenger,
                CHANNEL
            ).setMethodCallHandler { call, result ->
                Log.d("Bluetooth", "Method called: ${call.method}")
                when (call.method) {
                    "isBluetoothEnabled" -> {
                        result.success(bluetoothAdapter?.isEnabled ?: false)
                    }

                    "getPairedDevices" -> {
                        if (!hasRequiredPermissions()) {
                            result.error(
                                "PERMISSION_DENIED",
                                "Required Bluetooth permissions not granted", null
                            )
                            return@setMethodCallHandler
                        }
                        val pairedDevices = getPairedDevices()
                        result.success(pairedDevices)
                    }

                    "getDeviceServices" -> {
                        val deviceAddress = call.argument<String>("deviceAddress")
                        if (deviceAddress == null) {
                            result.error(
                                "INVALID_ARGUMENT",
                                "Device address is required", null
                            )
                            return@setMethodCallHandler
                        }
                        getDeviceServices(deviceAddress) { services ->
                            handler.post {
                                result.success(services)
                            }
                        }
                    }

                    "connectToDevice" -> {
                        val deviceAddress = call.argument<String>("deviceAddress")
                        if (deviceAddress == null) {
                            result.error(
                                "INVALID_ARGUMENT",
                                "Device address is required", null
                            )
                            return@setMethodCallHandler
                        }
                        connectToDevice(deviceAddress) { success ->
                            handler.post {
                                result.success(success)
                            }
                        }
                    }
                    "sendImage" -> {
                        val imagePath = call.argument<String>("imagePath")
                        if (imagePath == null) {
                            result.error("INVALID_ARGUMENT", "Image path is required", null)
                            return@setMethodCallHandler
                        }
                        sendImage(imagePath, result)
                    }


                    "disconnect" -> {
                        disconnect()
                        result.success(true)
                    }

                    else -> result.notImplemented()
                }
            }
        }
    }

    private fun hasRequiredPermissions(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            return ActivityCompat.checkSelfPermission(
                this,
                Manifest.permission.BLUETOOTH_CONNECT
            ) == PackageManager.PERMISSION_GRANTED
        }
        return true
    }

    private fun getPairedDevices(): List<Map<String, Any>> {
        val devices = mutableListOf<Map<String, Any>>()

        if (ActivityCompat.checkSelfPermission(
                this,
                Manifest.permission.BLUETOOTH_CONNECT
            ) == PackageManager.PERMISSION_GRANTED
        ) {
            bluetoothAdapter?.bondedDevices?.forEach { device ->
                devices.add(
                    mapOf(
                        "name" to (device.name ?: "Unknown"),
                        "address" to device.address,
                        "type" to when (device.type) {
                            BluetoothDevice.DEVICE_TYPE_CLASSIC -> "CLASSIC"
                            BluetoothDevice.DEVICE_TYPE_LE -> "LE"
                            else -> "UNKNOWN"
                        }
                    )
                )
            }
        }
        return devices
    }

    private fun getDeviceServices(deviceAddress: String, callback: (List<String>) -> Unit) {
        Log.d("Bluetooth", "Getting services for device: $deviceAddress")
        val device = bluetoothAdapter?.getRemoteDevice(deviceAddress)
        val servicesList = mutableListOf<String>()

        device?.let {
            if (ActivityCompat.checkSelfPermission(
                    this,
                    Manifest.permission.BLUETOOTH_CONNECT
                ) != PackageManager.PERMISSION_GRANTED
            ) {
                callback(emptyList())
                return
            }

            Log.d("Bluetooth", "Device Name: ${it.name}")
            Log.d("Bluetooth", "Device Address: ${it.address}")
            Log.d("Bluetooth", "Device Type: ${it.type}")

            servicesList.add("Device Name: ${it.name}")
            servicesList.add("Device Address: ${it.address}")
            servicesList.add("Device Type: ${getDeviceTypeName(it.type)}")

            it.uuids?.let { uuids ->
                servicesList.add("Available Services:")
                uuids.forEach { uuid ->
                    Log.d("Bluetooth", "Found UUID: ${uuid.uuid}")
                    servicesList.add("  Service: ${uuid.uuid}")
                }
            }

            callback(servicesList)
        } ?: callback(emptyList())
    }

    private fun getDeviceTypeName(type: Int): String {
        return when (type) {
            BluetoothDevice.DEVICE_TYPE_CLASSIC -> "Classic"
            BluetoothDevice.DEVICE_TYPE_LE -> "Low Energy"
            BluetoothDevice.DEVICE_TYPE_DUAL -> "Dual-mode"
            else -> "Unknown"
        }
    }

    private fun connectToDevice(deviceAddress: String, callback: (Boolean) -> Unit) {
        val device = bluetoothAdapter?.getRemoteDevice(deviceAddress)
        device?.let {
            currentConnectedDevice = device  // Set the current device
            when (it.type) {
                BluetoothDevice.DEVICE_TYPE_CLASSIC -> connectClassic(it, callback)
                BluetoothDevice.DEVICE_TYPE_LE -> connectLE(it, callback)
                BluetoothDevice.DEVICE_TYPE_DUAL -> connectDual(it, callback)
                else -> connectClassic(it, callback)
            }
        } ?: callback(false)
    }


    private fun connectClassic(device: BluetoothDevice, callback: (Boolean) -> Unit) {
        Thread {
            try {
                if (ActivityCompat.checkSelfPermission(
                        this,
                        Manifest.permission.BLUETOOTH_CONNECT
                    ) != PackageManager.PERMISSION_GRANTED
                ) {
                    callback(false)
                    return@Thread
                }

                val socket = device.createRfcommSocketToServiceRecord(SPP_UUID)
                bluetoothAdapter?.cancelDiscovery()
                socket.connect()
                classicSocket = socket
                outputStream = socket.outputStream
                inputStream = socket.inputStream
                isConnected = true
                callback(true)
            } catch (e: IOException) {
                Log.e(TAG, "Error connecting to Classic device: ${e.message}")
                classicSocket = null
                outputStream = null
                inputStream = null
                isConnected = false
                callback(false)
            }
        }.start()
    }


    private fun connectLE(device: BluetoothDevice, callback: (Boolean) -> Unit) {
        val gattCallback = object : BluetoothGattCallback() {
            override fun onConnectionStateChange(gatt: BluetoothGatt, status: Int, newState: Int) {
                when (newState) {
                    BluetoothProfile.STATE_CONNECTED -> {
                        bluetoothGatt = gatt
                        isConnected = true
                        callback(true)
                    }
                    BluetoothProfile.STATE_DISCONNECTED -> {
                        bluetoothGatt = null
                        isConnected = false
                        callback(false)
                    }
                }
            }
        }

        if (ActivityCompat.checkSelfPermission(
                this,
                Manifest.permission.BLUETOOTH_CONNECT
            ) != PackageManager.PERMISSION_GRANTED
        ) {
            callback(false)
            return
        }

        bluetoothGatt = device.connectGatt(this, false, gattCallback)
    }


    private fun connectDual(device: BluetoothDevice, callback: (Boolean) -> Unit) {
        // Try Classic first, then fall back to LE if Classic fails
        connectClassic(device) { classicSuccess ->
            if (classicSuccess) {
                Log.d(TAG, "Classic connection successful")
                callback(true)
            } else {
                Log.d(TAG, "Classic connection failed, trying LE")
                connectLE(device) { leSuccess ->
                    if (leSuccess) {
                        Log.d(TAG, "LE connection successful")
                    } else {
                        Log.d(TAG, "LE connection failed")
                    }
                    callback(leSuccess)
                }
            }
        }
    }
    private fun sendImage(imagePath: String, result: MethodChannel.Result) {
        Log.d(TAG, "Attempting to send image, connection status: $isConnected")
        if (!isConnected || currentConnectedDevice == null) {
            Log.e(TAG, "No device connected. Current device: ${currentConnectedDevice?.address}, isConnected: $isConnected")
            result.error("CONNECTION_ERROR", "No device connected", null)
            return
        }

        if (!hasStoragePermissions()) {
            result.error("PERMISSION_ERROR", "Storage permission not granted", null)
            requestStoragePermissions()
            return
        }

        Thread {
            try {
                if (!hasRequiredPermissions()) {
                    handler.post {
                        result.error("PERMISSION_ERROR", "Bluetooth permission not granted", null)
                    }
                    return@Thread
                }

                // Validate file exists and size
                val imageFile = File(imagePath)
                if (!imageFile.exists()) {
                    handler.post {
                        result.error("FILE_ERROR", "Image file not found: $imagePath", null)
                    }
                    return@Thread
                }

                Log.d(TAG, "File size: ${imageFile.length()} bytes")

                // Create or reuse socket with timeout
                val socket = if (classicSocket?.isConnected == true) {
                    Log.d(TAG, "Using existing socket connection")
                    classicSocket
                } else {
                    Log.d(TAG, "Creating new socket connection")
                    currentConnectedDevice?.createRfcommSocketToServiceRecord(OPP_UUID)?.also {
                        bluetoothAdapter?.cancelDiscovery()
                        it.connect()
                    }
                }

                socket?.use { connectedSocket ->
                    try {
                        val imageUri = FileProvider.getUriForFile(
                            this,
                            "${applicationContext.packageName}.provider",
                            imageFile
                        )

                        Log.d(TAG, "File URI: $imageUri")

                        contentResolver.openInputStream(imageUri)?.use { imageStream ->
                            val buffer = ByteArray(8192)
                            var totalBytesRead = 0L
                            var bytesRead: Int

                            // First send file size as header (8 bytes)
                            val fileSize = imageFile.length()
                            connectedSocket.outputStream.write(fileSize.toString().padStart(8, '0').toByteArray())
                            connectedSocket.outputStream.flush()

                            // Then send the actual file data with progress tracking
                            while (imageStream.read(buffer).also { bytesRead = it } != -1) {
                                connectedSocket.outputStream.write(buffer, 0, bytesRead)
                                totalBytesRead += bytesRead

                                // Log progress every 10%
                                val progress = (totalBytesRead.toFloat() / fileSize * 100).toInt()
                                if (progress % 10 == 0) {
                                    Log.d(TAG, "Transfer progress: $progress%")
                                }
                            }

                            connectedSocket.outputStream.flush()
                            Log.d(TAG, "File transfer completed. Total bytes sent: $totalBytesRead")

                            // Wait for acknowledgment with timeout
                            val ACK_TIMEOUT = 10000L // 10 seconds timeout
                            val startTime = System.currentTimeMillis()
                            val ackBuffer = ByteArray(1)

                            while (System.currentTimeMillis() - startTime < ACK_TIMEOUT) {
                                if (connectedSocket.inputStream.available() > 0) {
                                    val ackReceived = connectedSocket.inputStream.read(ackBuffer)
                                    if (ackReceived > 0 && ackBuffer[0] == 1.toByte()) {
                                        Log.d(TAG, "Transfer acknowledged by receiver")
                                        handler.post { result.success(true) }
                                        return@Thread
                                    }
                                }
                                // Small delay to prevent busy waiting
                                Thread.sleep(100)
                            }

                            // If we get here, timeout occurred
                            throw IOException("Transfer acknowledgment timeout after ${ACK_TIMEOUT/1000} seconds")

                        } ?: throw IOException("Failed to open input stream for image")

                    } catch (e: Exception) {
                        Log.e(TAG, "Error during file transfer: ${e.message}")
                        handler.post {
                            result.error("SEND_ERROR", "Failed to send image: ${e.message}", null)
                        }
                    } finally {
                        try {
                            // Only close the socket if it's a new connection
                            if (socket != classicSocket) {
                                connectedSocket.close()
                            }
                        } catch (e: IOException) {
                            Log.e(TAG, "Error closing socket: ${e.message}")
                        }
                    }
                } ?: throw IOException("Failed to get valid socket connection")

            } catch (e: Exception) {
                Log.e(TAG, "Error sending image: ${e.message}")
                handler.post {
                    result.error("SEND_ERROR", "Failed to send image: ${e.message}", null)
                }
            }
        }.start()
    }


    private fun hasStoragePermissions(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            true // Android 10 and above handle storage differently
        } else {
            ContextCompat.checkSelfPermission(
                this,
                Manifest.permission.READ_EXTERNAL_STORAGE
            ) == PackageManager.PERMISSION_GRANTED
        }
    }

    private fun requestStoragePermissions() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            ActivityCompat.requestPermissions(
                this,
                arrayOf(Manifest.permission.READ_EXTERNAL_STORAGE),
                REQUEST_STORAGE_PERMISSION
            )
        }
    }



    private fun disconnect() {
        try {
            classicSocket?.close()
            classicSocket = null

            if (hasRequiredPermissions()) {
                bluetoothGatt?.disconnect()
                bluetoothGatt?.close()
                bluetoothGatt = null
            }

            outputStream?.close()
            outputStream = null
            inputStream?.close()
            inputStream = null
            isConnected = false
        } catch (e: Exception) {
            Log.e(TAG, "Error during disconnect: ${e.message}", e)
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        disconnect()
    }



    private fun hasBluetoothPermissions(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            ContextCompat.checkSelfPermission(
                this,
                Manifest.permission.BLUETOOTH_CONNECT
            ) == PackageManager.PERMISSION_GRANTED &&
                    ContextCompat.checkSelfPermission(
                        this,
                        Manifest.permission.BLUETOOTH_SCAN
                    ) == PackageManager.PERMISSION_GRANTED
        } else {
            true
        }
    }

    private fun requestBluetoothPermissions() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            ActivityCompat.requestPermissions(
                this,
                arrayOf(
                    Manifest.permission.BLUETOOTH_CONNECT,
                    Manifest.permission.BLUETOOTH_SCAN
                ),
                REQUEST_BLUETOOTH_PERMISSIONS
            )
        }
    }
}