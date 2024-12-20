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

class MainActivity: FlutterActivity() {
    private val TAG = "BluetoothFile"
    private val CHANNEL = "bluetooth_health"

    private val REQUEST_BLUETOOTH_PERMISSIONS = 1
    private var bluetoothAdapter: BluetoothAdapter? = null
    private var bluetoothGatt: BluetoothGatt? = null
    private var classicSocket: BluetoothSocket? = null
    private val handler = Handler(Looper.getMainLooper())

    private val SPP_UUID = UUID.fromString("00001101-0000-1000-8000-00805F9B34FB")
    private val OPP_UUID = UUID.fromString("00001105-0000-1000-8000-00805f9b34fb")

    private val CHUNK_SIZE = 4096

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

                    "sendFile" -> {
                        val deviceAddress = call.argument<String>("deviceAddress")
                        val filePath = call.argument<String>("filePath")

                        if (deviceAddress == null || filePath == null) {
                            result.error(
                                "INVALID_ARGUMENT",
                                "Device address and file path are required",
                                null
                            )
                            return@setMethodCallHandler
                        }

                        sendFile(deviceAddress, filePath) { success ->
                            handler.post {
                                result.success(success)
                            }
                        }
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
                callback(true)
            } catch (e: IOException) {
                Log.e(TAG, "Error connecting to Classic device: ${e.message}")
                callback(false)
            }
        }.start()
    }

    private fun connectLE(device: BluetoothDevice, callback: (Boolean) -> Unit) {
        val gattCallback = object : BluetoothGattCallback() {
            override fun onConnectionStateChange(gatt: BluetoothGatt, status: Int, newState: Int) {
                when (newState) {
                    BluetoothProfile.STATE_CONNECTED -> callback(true)
                    BluetoothProfile.STATE_DISCONNECTED -> callback(false)
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

        device.connectGatt(this, false, gattCallback)
    }

    private fun connectDual(device: BluetoothDevice, callback: (Boolean) -> Unit) {
        connectClassic(device) { classicSuccess ->
            if (classicSuccess) {
                callback(true)
            } else {
                connectLE(device, callback)
            }
        }
    }

    private fun sendFile(deviceAddress: String, filePath: String, callback: (Boolean) -> Unit) {
        Thread {
            var socket: BluetoothSocket? = null
            var inputStream: InputStream? = null

            try {
                // Check for necessary Bluetooth permissions
                if (!hasRequiredPermissions()) {
                    Log.e(TAG, "Missing required permissions")
                    callback(false)
                    return@Thread
                }

                // Check if Bluetooth is enabled
                val bluetoothAdapter = BluetoothAdapter.getDefaultAdapter()
                if (bluetoothAdapter == null || !bluetoothAdapter.isEnabled) {
                    Log.e(TAG, "Bluetooth is not enabled")
                    callback(false)
                    return@Thread
                }

                // Get remote device
                val device = bluetoothAdapter.getRemoteDevice(deviceAddress)
                if (device == null) {
                    Log.e(TAG, "Device not found")
                    callback(false)
                    return@Thread
                }

                // Check if file exists
                val file = File(filePath)
                if (!file.exists()) {
                    Log.e(TAG, "File does not exist: $filePath")
                    callback(false)
                    return@Thread
                }
                Log.d(TAG, "File exists at path: ${file.absolutePath}")

                // Create content URI for the file
                val contentUri = try {
                    FileProvider.getUriForFile(
                        this,
                        "${applicationContext.packageName}.fileprovider",
                        file
                    )
                } catch (e: IllegalArgumentException) {
                    Log.e(TAG, "Error creating content URI: ${e.message}")
                    callback(false)
                    return@Thread
                }

                // Open input stream for the file
                inputStream = try {
                    contentResolver.openInputStream(contentUri)
                } catch (e: Exception) {
                    Log.e(TAG, "Error opening input stream: ${e.message}")
                    callback(false)
                    return@Thread
                }

                if (inputStream == null) {
                    Log.e(TAG, "Could not open input stream")
                    callback(false)
                    return@Thread
                }

                // Create Bluetooth socket for connection
                socket = device.createRfcommSocketToServiceRecord(OPP_UUID)

                // Connect to the device with timeout
                var connectionSuccessful = false
                val connectionThread = Thread {
                    try {
                        socket?.connect()
                        connectionSuccessful = true
                    } catch (e: IOException) {
                        Log.e(TAG, "Connection failed: ${e.message}")
                    }
                }

                connectionThread.start()
                connectionThread.join(60000)

                if (!connectionSuccessful) {
                    Log.e(TAG, "Connection failed after timeout")
                    callback(false)
                    socket?.close()
                    return@Thread
                }

                val outputStream = socket!!.outputStream
                val socketInputStream = socket.inputStream

                // OBEX Connect Packet
                val connectPacket = ByteArray(7)
                connectPacket[0] = 0x80.toByte() // Connect opcode
                connectPacket[1] = 0x00.toByte() // Packet length high byte
                connectPacket[2] = 0x07.toByte() // Packet length low byte
                connectPacket[3] = 0x10.toByte() // OBEX version
                connectPacket[4] = 0x00.toByte() // Flags
                connectPacket[5] = 0x20.toByte() // Max packet length high byte
                connectPacket[6] = 0x00.toByte() // Max packet length low byte

                outputStream.write(connectPacket)
                outputStream.flush()

                // Read connect response
                val connectResponse = ByteArray(7)
                val bytesRead = socketInputStream.read(connectResponse)
                if (bytesRead < 7 || (connectResponse[0].toInt() and 0xFF) != 0xA0) {
                    Log.e(TAG, "OBEX connect failed")
                    callback(false)
                    return@Thread
                }

                // Get file name and prepare packet headers
                val fileName = file.name
                val nameBytes = fileName.toByteArray()

                val fileLength = file.length()
                val headerLength = 3 + 3 + nameBytes.size + 2

                // Send PUT request with headers
                val putPacket = ByteArrayOutputStream()
                putPacket.write(0x82) // PUT with final bit
                putPacket.write(((headerLength + 3) shr 8) and 0xFF) // Length high byte
                putPacket.write((headerLength + 3) and 0xFF) // Length low byte

                // Name header
                putPacket.write(0x01) // Name header ID
                putPacket.write((nameBytes.size + 3) shr 8 and 0xFF)
                putPacket.write((nameBytes.size + 3) and 0xFF)
                putPacket.write(nameBytes)
                putPacket.write(0x00)

                // Length header
                putPacket.write(0xC3) // Length header ID
                putPacket.write(0x00)
                putPacket.write(0x05)
                putPacket.write((fileLength shr 24).toInt() and 0xFF)
                putPacket.write((fileLength shr 16).toInt() and 0xFF)
                putPacket.write((fileLength shr 8).toInt() and 0xFF)
                putPacket.write(fileLength.toInt() and 0xFF)

                outputStream.write(putPacket.toByteArray())
                outputStream.flush()

                // Read PUT response
                val putResponse = ByteArray(3)
                socketInputStream.read(putResponse)

                // Send file data in chunks
                val buffer = ByteArray(CHUNK_SIZE)
                var bytesTransferred: Int
                var totalBytesTransferred: Long = 0

                while (inputStream.read(buffer).also { bytesTransferred = it } != -1) {
                    val bodyHeader = ByteArrayOutputStream()
                    bodyHeader.write(0x48) // Body header
                    bodyHeader.write((bytesTransferred + 3) shr 8 and 0xFF)
                    bodyHeader.write((bytesTransferred + 3) and 0xFF)

                    outputStream.write(bodyHeader.toByteArray())
                    outputStream.write(buffer, 0, bytesTransferred)
                    outputStream.flush()

                    totalBytesTransferred += bytesTransferred
                    Log.d(TAG, "Transferred $totalBytesTransferred bytes")

                    // Read body response
                    val bodyResponse = ByteArray(3)
                    socketInputStream.read(bodyResponse)
                }

                // Send End of Body
                val endOfBody = byteArrayOf(
                    0x49.toByte(),
                    0x00.toByte(),
                    0x03.toByte()
                )
                outputStream.write(endOfBody)
                outputStream.flush()

                // Handle final response
                var transferSuccess = false
                val responseThread = Thread {
                    try {
                        val responseBuffer = ByteArray(3)
                        val response = socketInputStream.read(responseBuffer)

                        if (response > 0) {
                            val hexResponse = responseBuffer.take(response)
                                .joinToString("") { "%02x".format(it) }
                            Log.d(TAG, "Raw response (hex): $hexResponse")

                            if ((responseBuffer[0].toInt() and 0xFF) == 0xA0 ||
                                (responseBuffer[0].toInt() and 0xFF) == 0xD1) {
                                Log.d(TAG, "File transfer completed successfully")
                                transferSuccess = true
                            } else {
                                Log.w(TAG, "Unexpected OBEX response")
                            }
                        }
                    } catch (e: IOException) {
                        Log.e(TAG, "Error reading response: ${e.message}")
                    }
                }

                responseThread.start()
                responseThread.join(5000)

                callback(transferSuccess)

            } catch (e: Exception) {
                Log.e(TAG, "Error during file transfer: ${e.message}")
                callback(false)
            } finally {
                try {
                    inputStream?.close()
                    socket?.close()
                } catch (e: IOException) {
                    Log.e(TAG, "Error closing resources: ${e.message}")
                }
            }
        }.start()
    }



    private fun disconnect() {
        try {
            classicSocket?.close()
            classicSocket = null

            if (ActivityCompat.checkSelfPermission(
                    this,
                    Manifest.permission.BLUETOOTH_CONNECT
                ) == PackageManager.PERMISSION_GRANTED
            ) {
                bluetoothGatt?.disconnect()
                bluetoothGatt?.close()
                bluetoothGatt = null
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error during disconnect: ${e.message}")
        }
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