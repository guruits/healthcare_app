package com.example.health

import android.Manifest
import android.bluetooth.*
import android.content.BroadcastReceiver
import android.content.Intent
import android.content.IntentFilter
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
import java.nio.ByteOrder
import java.nio.ByteBuffer

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
    private val ACK_TIMEOUT = 5000L
    private var isReceivingMode = false
    private var receiverThread: Thread? = null
    private val FTP_UUID = UUID.fromString("00001106-0000-1000-8000-00805f9b34fb")
    private val ROOT_PATH = "/storage/emulated/0/Android/data/com.example.health/files/"
    private val FTP_ROOT_PATH = "/"
    private val MIME_TYPES = mapOf(
        "jpg" to "image/jpeg",
        "jpeg" to "image/jpeg",
        "png" to "image/png",
        "pdf" to "application/pdf",
        "txt" to "text/plain",
        "doc" to "application/msword",
        "docx" to "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
    )


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

                    "startReceiving" -> {
                        startReceiving(result)
                    }
                    "stopReceiving" -> {
                        stopReceiving()
                        result.success(true)
                    }

                    "browseFiles" -> {
                        val path = call.argument<String>("path") ?: ROOT_PATH
                        browseRemoteFiles(path, result)
                    }
                    "downloadFile" -> {
                        val remotePath = call.argument<String>("remotePath")
                        if (remotePath == null) {
                            result.error("INVALID_ARGUMENT", "Remote file path is required", null)
                            return@setMethodCallHandler
                        }
                        downloadRemoteFile(remotePath, result)
                    }

                    "browseDeviceFiles" -> {
                        val path = call.argument<String>("path") ?: FTP_ROOT_PATH
                        browseDeviceFiles(path, result)
                    }
                    "getFileDetails" -> {
                        val path = call.argument<String>("path")
                        if (path != null) {
                            getFileDetails(path, result)
                        } else {
                            result.error("INVALID_PATH", "File path is required", null)
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

    private fun startReceiving(result: MethodChannel.Result) {
        if (!hasRequiredPermissions()) {
            result.error("PERMISSION_ERROR", "Bluetooth permissions not granted", null)
            return
        }

        isReceivingMode = true

        // Create accepting thread
        receiverThread = Thread {
            try {
                val serverSocket = if (ActivityCompat.checkSelfPermission(
                        this,
                        Manifest.permission.BLUETOOTH_CONNECT
                    ) == PackageManager.PERMISSION_GRANTED
                ) {
                    bluetoothAdapter?.listenUsingRfcommWithServiceRecord(
                        "HealthFileReceiver",
                        OPP_UUID
                    )
                } else {
                    null
                }

                serverSocket?.use { server ->
                    while (isReceivingMode) {
                        try {
                            Log.d(TAG, "Waiting for incoming connection...")
                            val socket = server.accept()

                            Log.d(TAG, "Connection accepted from: ${socket.remoteDevice.address}")

                            handleIncomingFile(socket)
                        } catch (e: IOException) {
                            Log.e(TAG, "Error accepting connection: ${e.message}")
                            if (!isReceivingMode) break
                        }
                    }
                }

                handler.post { result.success(true) }

            } catch (e: IOException) {
                Log.e(TAG, "Error setting up receiver: ${e.message}")
                handler.post {
                    result.error(
                        "RECEIVER_ERROR",
                        "Failed to start receiver: ${e.message}",
                        null
                    )
                }
            }
        }.apply { start() }
    }

        private fun handleIncomingFile(socket: BluetoothSocket) {
            try {
                socket.use { connectedSocket ->
                    // Read file size header (8 bytes)
                    val sizeBuffer = ByteArray(8)
                    connectedSocket.inputStream.read(sizeBuffer)
                    val expectedFileSize = String(sizeBuffer).toLong()

                    Log.d(TAG, "Expected file size: $expectedFileSize bytes")

                    // Create file to save the incoming data
                    val timestamp = System.currentTimeMillis()
                    val receivedFile = File(getExternalFilesDir(null), "received_image_$timestamp.jpg")

                    var totalBytesReceived = 0L
                    val buffer = ByteArray(8192)

                    receivedFile.outputStream().use { fileOutputStream ->
                        while (totalBytesReceived < expectedFileSize) {
                            val bytesRead = connectedSocket.inputStream.read(buffer)
                            if (bytesRead == -1) break

                            fileOutputStream.write(buffer, 0, bytesRead)
                            totalBytesReceived += bytesRead

                            // Log progress
                            val progress = (totalBytesReceived.toFloat() / expectedFileSize * 100).toInt()
                            if (progress % 10 == 0) {
                                Log.d(TAG, "Receiving progress: $progress%")
                            }
                        }
                    }

                    Log.d(TAG, "File received successfully: ${receivedFile.absolutePath}")

                    // Send acknowledgment
                    connectedSocket.outputStream.write(byteArrayOf(1))
                    connectedSocket.outputStream.flush()
                    handler.post {
                        flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
                            MethodChannel(messenger, CHANNEL).invokeMethod("onFileReceived", mapOf(
                                "path" to receivedFile.absolutePath,
                                "size" to totalBytesReceived
                            ))
                        }
                    }
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error handling incoming file: ${e.message}")
            }
        }

        private fun stopReceiving() {
            isReceivingMode = false
            receiverThread?.interrupt()
            receiverThread = null
        }
    private fun sanitizePath(path: String): String {
        return if (!path.startsWith(ROOT_PATH)) {
            ROOT_PATH + path.trimStart('/')
        } else {
            path
        }
    }

    private fun browseRemoteFiles(path: String, result: MethodChannel.Result) {
        if (!isConnected || currentConnectedDevice == null) {
            result.error("CONNECTION_ERROR", "No device connected", null)
            return
        }

        val sanitizedPath = sanitizePath(path)
        Log.d(TAG, "Browsing files at path: $sanitizedPath")

        Thread {
            var retryCount = 0
            val maxRetries = 3
            var hasResponded = false

            while (retryCount < maxRetries && !hasResponded) {
                try {
                    if (!hasRequiredPermissions()) {
                        if (!hasResponded) {
                            handler.post {
                                result.error("PERMISSION_ERROR", "Bluetooth permission not granted", null)
                            }
                            hasResponded = true
                        }
                        return@Thread
                    }

                    // Create FTP connection
                    val ftpSocket = currentConnectedDevice?.createRfcommSocketToServiceRecord(FTP_UUID)
                    ftpSocket?.let { socket ->
                        try {
                            // Set connection timeout
                            socket.connect()

                            val output = socket.outputStream
                            val input = socket.inputStream

                            // Send browse request command
                            val browseCommand = buildBrowseCommand(sanitizedPath)
                            output.write(browseCommand)
                            output.flush()

                            // Check for initial response
                            if (checkForResponse(input)) {
                                // Read response
                                val response = readFileListResponse(input)

                                if (!hasResponded) {
                                    handler.post {
                                        result.success(response)
                                    }
                                    hasResponded = true
                                }
                                return@Thread
                            } else {
                                throw IOException("No response received within timeout")
                            }
                        } finally {
                            try {
                                socket.close()
                            } catch (e: IOException) {
                                Log.e(TAG, "Error closing socket: ${e.message}")
                            }
                        }
                    } ?: throw IOException("Failed to create socket")

                } catch (e: Exception) {
                    Log.e(TAG, "Error browsing files (attempt ${retryCount + 1}): ${e.message}")
                    retryCount++

                    if (retryCount >= maxRetries && !hasResponded) {
                        handler.post {
                            result.error("BROWSE_ERROR",
                                "Failed to browse files after $maxRetries attempts: ${e.message}",
                                null)
                        }
                        hasResponded = true
                    } else if (!hasResponded) {
                        // Wait before retry
                        Thread.sleep(1000)
                        // Attempt to reconnect
                        reconnectIfNeeded()
                    }
                }
            }
        }.start()
    }
    private fun checkForResponse(input: InputStream): Boolean {
        val startTime = System.currentTimeMillis()
        val timeout = 10000L // 10 seconds

        while (System.currentTimeMillis() - startTime < timeout) {
            if (input.available() > 0) {
                return true
            }
            Thread.sleep(100)
        }
        return false
    }


    private fun reconnectIfNeeded() {
        if (!isConnected && currentConnectedDevice != null) {
            try {
                connectToDevice(currentConnectedDevice!!.address) { success ->
                    Log.d(TAG, "Reconnection ${if (success) "successful" else "failed"}")
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error during reconnection: ${e.message}")
            }
        }
    }


    private fun readFully(input: InputStream, buffer: ByteArray, timeout: Int): Boolean {
        var totalRead = 0
        val startTime = System.currentTimeMillis()

        while (totalRead < buffer.size && System.currentTimeMillis() - startTime < timeout) {
            val read = input.read(buffer, totalRead, buffer.size - totalRead)
            if (read > 0) {
                totalRead += read
            } else if (read == -1) {
                return false
            }
        }

        return totalRead == buffer.size
    }

    private fun buildBrowseCommand(path: String): ByteArray {
        val pathBytes = path.toByteArray()
        return byteArrayOf(0x01) + pathBytes.size.toByte() + pathBytes
    }

    private fun downloadRemoteFile(remotePath: String, result: MethodChannel.Result) {
        if (!isConnected || currentConnectedDevice == null) {
            result.error("CONNECTION_ERROR", "No device connected", null)
            return
        }
        val sanitizedPath = sanitizePath(remotePath)
        Log.d(TAG, "Downloading file from path: $sanitizedPath")

        Thread {
            try {
                if (!hasRequiredPermissions()) {
                    handler.post {
                        result.error("PERMISSION_ERROR", "Bluetooth permission not granted", null)
                    }
                    return@Thread
                }

                val ftpSocket = currentConnectedDevice?.createRfcommSocketToServiceRecord(FTP_UUID)
                ftpSocket?.connect()

                ftpSocket?.use { socket ->
                    val output = socket.outputStream
                    val input = socket.inputStream

                    // Send download request command
                    val downloadCommand = buildDownloadCommand(sanitizedPath)
                    output.write(downloadCommand)
                    output.flush()

                    // Read file size with ByteBuffer
                    val sizeBuffer = ByteArray(8)
                    if (input.read(sizeBuffer) != 8) {
                        throw IOException("Failed to read file size")
                    }

                    val sizeByteBuffer = ByteBuffer.wrap(sizeBuffer).order(ByteOrder.BIG_ENDIAN)
                    val fileSize = sizeByteBuffer.getLong()

                    // Create local file
                    val fileName = remotePath.substringAfterLast('/')
                    val localFile = File(getExternalFilesDir(null), fileName)

                    // Download file with progress tracking
                    var totalReceived = 0L
                    val buffer = ByteArray(8192)

                    localFile.outputStream().use { fileOutput ->
                        while (totalReceived < fileSize) {
                            val read = input.read(buffer, 0, minOf(buffer.size, (fileSize - totalReceived).toInt()))
                            if (read == -1) break

                            fileOutput.write(buffer, 0, read)
                            totalReceived += read

                            // Report progress
                            val progress = (totalReceived * 100 / fileSize).toInt()
                            if (progress % 10 == 0) {
                                Log.d(TAG, "Download progress: $progress%")
                                // Notify Flutter of progress
                                handler.post {
                                    flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
                                        MethodChannel(messenger, CHANNEL).invokeMethod(
                                            "onDownloadProgress",
                                            mapOf(
                                                "progress" to progress,
                                                "totalSize" to fileSize,
                                                "received" to totalReceived
                                            )
                                        )
                                    }
                                }
                            }
                        }
                    }

                    handler.post {
                        result.success(mapOf(
                            "path" to localFile.absolutePath,
                            "size" to totalReceived
                        ))
                    }
                }

            } catch (e: Exception) {
                Log.e(TAG, "Error downloading file: ${e.message}")
                handler.post {
                    result.error("DOWNLOAD_ERROR", "Failed to download file: ${e.message}", null)
                }
            }
        }.start()
    }

    private fun buildDownloadCommand(path: String): ByteArray {
        // Format: [0x02][path length][path]
        val pathBytes = path.toByteArray()
        return byteArrayOf(0x02) + pathBytes.size.toByte() + pathBytes
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

    private fun browseDeviceFiles(path: String, result: MethodChannel.Result) {
        if (!isConnected || currentConnectedDevice == null) {
            result.error("CONNECTION_ERROR", "No device connected", null)
            return
        }

        Thread {
            var retryCount = 0
            val maxRetries = 3
            var socket: BluetoothSocket? = null

            while (retryCount < maxRetries) {
                try {
                    // Create new socket connection for file browsing
                    socket = currentConnectedDevice?.createRfcommSocketToServiceRecord(FTP_UUID)

                    // Set connection timeout
                    socket?.connect()

                    socket?.use { connectedSocket ->
                        val output = connectedSocket.outputStream
                        val input = connectedSocket.inputStream

                        // Send browse command with protocol version and path length
                        val command = buildBrowseCommandV2(path)
                        output.write(command)
                        output.flush()

                        // Wait for acknowledgment with timeout
                        if (!waitForAcknowledgment(input)) {
                            throw IOException("No acknowledgment received from device")
                        }

                        // Read response header
                        val headerBuffer = ByteArray(4)
                        val headerRead = input.read(headerBuffer)
                        if (headerRead != 4) {
                            throw IOException("Failed to read response header, got $headerRead bytes")
                        }

                        // Verify response header
                        if (!isValidResponseHeader(headerBuffer)) {
                            throw IOException("Invalid response header received")
                        }

                        // Read file list with timeout
                        val fileList = readFileListResponseWithTimeout(input)

                        handler.post {
                            result.success(fileList)
                        }
                        return@Thread
                    }

                } catch (e: Exception) {
                    Log.e(TAG, "Browse attempt ${retryCount + 1} failed: ${e.message}")
                    socket?.close()

                    if (retryCount == maxRetries - 1) {
                        handler.post {
                            result.error("BROWSE_ERROR",
                                "Failed to browse files after $maxRetries attempts: ${e.message}",
                                null)
                        }
                        return@Thread
                    }

                    retryCount++
                    // Exponential backoff between retries
                    Thread.sleep(1000L * (1 shl retryCount))

                    // Try to re-establish the connection
                    reconnectIfNeeded()
                }
            }
        }.start()
    }
    private fun buildBrowseCommandV2(path: String): ByteArray {
        val pathBytes = path.toByteArray()
        return byteArrayOf(
            0x02, // Protocol version
            0x01, // Command type (BROWSE)
            (pathBytes.size and 0xFF).toByte(), // Path length (1 byte)
            ((pathBytes.size shr 8) and 0xFF).toByte() // Path length (continued)
        ) + pathBytes
    }

    private fun waitForAcknowledgment(input: InputStream): Boolean {
        val startTime = System.currentTimeMillis()
        val timeout = 5000L // 5 second timeout

        while (System.currentTimeMillis() - startTime < timeout) {
            if (input.available() > 0) {
                val ack = input.read()
                return ack == 0x06 // ACK byte
            }
            Thread.sleep(100)
        }
        return false
    }

    private fun isValidResponseHeader(header: ByteArray): Boolean {
        return header[0] == 0x02.toByte() && // Protocol version
                header[1] == 0x01.toByte() && // Response type
                header[2] != 0xFF.toByte() && // Error check
                header[3] != 0xFF.toByte()    // Error check
    }


    private enum class CommandType {
        BROWSE,
        GET_DETAILS,
        DOWNLOAD
    }
    private fun buildCommand(type: CommandType, path: String): ByteArray {
        val pathBytes = path.toByteArray()
        val commandByte = when(type) {
            CommandType.BROWSE -> 0x01.toByte()
            CommandType.GET_DETAILS -> 0x02.toByte()
            CommandType.DOWNLOAD -> 0x03.toByte()
        }

        return byteArrayOf(commandByte) +
                pathBytes.size.toByte() +
                pathBytes
    }

    private fun getFileDetails(path: String, result: MethodChannel.Result) {
        if (!isConnected || currentConnectedDevice == null) {
            result.error("CONNECTION_ERROR", "No device connected", null)
            return
        }

        Thread {
            try {
                val ftpSocket = currentConnectedDevice?.createRfcommSocketToServiceRecord(FTP_UUID)
                ftpSocket?.connect()

                ftpSocket?.use { socket ->
                    val output = socket.outputStream
                    val input = socket.inputStream

                    // Send get details command
                    val command = buildCommand(CommandType.GET_DETAILS, path)
                    output.write(command)
                    output.flush()

                    // Read response
                    val details = readFileDetails(input)

                    handler.post {
                        result.success(details)
                    }
                }
            } catch (e: Exception) {
                handler.post {
                    result.error("DETAILS_ERROR", "Failed to get file details: ${e.message}", null)
                }
            }
        }.start()
    }
    private fun readFileListResponseWithTimeout(input: InputStream): List<Map<String, Any>> {
        val timeout = 10000L // 10 second timeout
        val startTime = System.currentTimeMillis()
        val files = mutableListOf<Map<String, Any>>()

        // Read number of files (4 bytes)
        val countBuffer = ByteArray(4)
        if (!readFullyWithTimeout(input, countBuffer, timeout)) {
            throw IOException("Failed to read file count")
        }

        val count = ByteBuffer.wrap(countBuffer).order(ByteOrder.BIG_ENDIAN).getInt()
        if (count < 0 || count > 1000) { // Sanity check
            throw IOException("Invalid file count: $count")
        }

        val remainingTimeout = timeout - (System.currentTimeMillis() - startTime)
        for (i in 0 until count) {
            if (System.currentTimeMillis() - startTime > timeout) {
                throw IOException("Timeout while reading file list")
            }

            val file = readFileEntry(input, remainingTimeout)
            files.add(file)
        }

        return files
    }

    private fun readFileEntry(input: InputStream, timeout: Long): Map<String, Any> {
        // Read name length (2 bytes)
        val nameLenBuffer = ByteArray(2)
        if (!readFullyWithTimeout(input, nameLenBuffer, timeout)) {
            throw IOException("Failed to read name length")
        }

        val nameLength = ByteBuffer.wrap(nameLenBuffer).order(ByteOrder.BIG_ENDIAN).short.toInt()
        if (nameLength <= 0 || nameLength > 1024) { // Sanity check
            throw IOException("Invalid name length: $nameLength")
        }

        // Read name
        val nameBuffer = ByteArray(nameLength)
        if (!readFullyWithTimeout(input, nameBuffer, timeout)) {
            throw IOException("Failed to read file name")
        }

        val name = String(nameBuffer)

        // Read attributes (2 bytes)
        val attrBuffer = ByteArray(2)
        if (!readFullyWithTimeout(input, attrBuffer, timeout)) {
            throw IOException("Failed to read file attributes")
        }

        val attributes = ByteBuffer.wrap(attrBuffer).order(ByteOrder.BIG_ENDIAN).short

        // Read size (8 bytes)
        val sizeBuffer = ByteArray(8)
        if (!readFullyWithTimeout(input, sizeBuffer, timeout)) {
            throw IOException("Failed to read file size")
        }

        val size = ByteBuffer.wrap(sizeBuffer).order(ByteOrder.BIG_ENDIAN).long

        return mapOf(
            "name" to name,
            "isDirectory" to (attributes.toInt() and 0x01 != 0),
            "isHidden" to (attributes.toInt() and 0x02 != 0),
            "size" to size,
            "mimeType" to getMimeType(name)
        )
    }

    private fun readFullyWithTimeout(input: InputStream, buffer: ByteArray, timeout: Long): Boolean {
        var totalRead = 0
        val startTime = System.currentTimeMillis()

        while (totalRead < buffer.size) {
            if (System.currentTimeMillis() - startTime > timeout) {
                return false
            }

            val read = input.read(buffer, totalRead, buffer.size - totalRead)
            if (read == -1) {
                return false
            }
            totalRead += read
        }

        return true
    }



    private fun readFileDetails(input: InputStream): Map<String, Any> {
        val sizeBuffer = ByteArray(8)
        input.read(sizeBuffer)
        val size = ByteBuffer.wrap(sizeBuffer).order(ByteOrder.BIG_ENDIAN).getLong()

        val modifiedBuffer = ByteArray(8)
        input.read(modifiedBuffer)
        val modified = ByteBuffer.wrap(modifiedBuffer).order(ByteOrder.BIG_ENDIAN).getLong()

        val permissionByte = input.read()
        val isReadable = (permissionByte and 0x04) != 0
        val isWritable = (permissionByte and 0x02) != 0
        val isExecutable = (permissionByte and 0x01) != 0

        return mapOf(
            "size" to size,
            "modified" to modified,
            "permissions" to mapOf(
                "readable" to isReadable,
                "writable" to isWritable,
                "executable" to isExecutable
            )
        )
    }

    private fun readFileListResponse(input: InputStream): List<Map<String, Any>> {
        val countBuffer = ByteArray(4)
        input.read(countBuffer)
        val count = ByteBuffer.wrap(countBuffer).order(ByteOrder.BIG_ENDIAN).getInt()

        val files = mutableListOf<Map<String, Any>>()

        for (i in 0 until count) {
            // Read name length
            val nameLength = input.read()
            val nameBuffer = ByteArray(nameLength)
            input.read(nameBuffer)
            val name = String(nameBuffer)

            // Read file attributes
            val attributeBuffer = ByteArray(2)
            input.read(attributeBuffer)
            val attributes = ByteBuffer.wrap(attributeBuffer).order(ByteOrder.BIG_ENDIAN).short

            val isDirectory = (attributes.toInt() and 0x01) != 0
            val isHidden = (attributes.toInt() and 0x02) != 0


            // Read file size
            val sizeBuffer = ByteArray(8)
            input.read(sizeBuffer)
            val size = ByteBuffer.wrap(sizeBuffer).order(ByteOrder.BIG_ENDIAN).getLong()

            files.add(mapOf(
                "name" to name,
                "isDirectory" to isDirectory,
                "isHidden" to isHidden,
                "size" to size,
                "mimeType" to getMimeType(name)
            ))
        }

        return files
    }

    private fun getMimeType(fileName: String): String {
        val extension = fileName.substringAfterLast('.', "").lowercase()
        return MIME_TYPES[extension] ?: "application/octet-stream"
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