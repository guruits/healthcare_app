package com.example.health

import android.Manifest
import android.bluetooth.*
import android.content.pm.PackageManager
import android.media.*
import android.os.Bundle
import java.io.File
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
import android.media.MediaCodec
import android.media.MediaExtractor
import android.media.MediaFormat
import android.media.AudioTrack
import android.media.AudioAttributes
import android.media.AudioFormat
import java.nio.ByteBuffer

class MainActivity: FlutterActivity() {
    private val TAG = "BluetoothAudio"
    private val CHANNEL = "bluetooth_health"
    private var bluetoothAdapter: BluetoothAdapter? = null
    private var gatt: BluetoothGatt? = null
    private var classicSocket: BluetoothSocket? = null
    private val handler = Handler(Looper.getMainLooper())
    private val REQUEST_BLUETOOTH_PERMISSIONS = 1
    private var bluetoothA2dp: BluetoothA2dp? = null
    private var audioTrack: AudioTrack? = null

    private val SPP_UUID = UUID.fromString("00001101-0000-1000-8000-00805F9B34FB")
    private val A2DP_UUID = UUID.fromString("0000110b-0000-1000-8000-00805f9b34fb")

    // Battery Service and Characteristic UUIDs
    private val BATTERY_SERVICE_UUID = UUID.fromString("0000180F-0000-1000-8000-00805f9b34fb")
    private val BATTERY_LEVEL_CHARACTERISTIC_UUID = UUID.fromString("00002A19-0000-1000-8000-00805f9b34fb")

    private val bluetoothProfile = object : BluetoothProfile.ServiceListener {
        override fun onServiceConnected(profile: Int, proxy: BluetoothProfile) {
            if (profile == BluetoothProfile.A2DP) {
                bluetoothA2dp = proxy as BluetoothA2dp
                Log.d("Bluetooth", "A2DP Profile connected")
            }
        }

        override fun onServiceDisconnected(profile: Int) {
            if (profile == BluetoothProfile.A2DP) {
                bluetoothA2dp = null
                Log.d("Bluetooth", "A2DP Profile disconnected")
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Log.d("Bluetooth", "MainActivity onCreate")

        val bluetoothManager = getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
        bluetoothAdapter = bluetoothManager.adapter

        if (bluetoothAdapter == null) {
            Log.e("Bluetooth", "Bluetooth not supported on this device.")
            return
        }

        // Initialize A2DP profile
        bluetoothAdapter?.getProfileProxy(this, bluetoothProfile, BluetoothProfile.A2DP)

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
                        Log.d("Bluetooth", "Checking if Bluetooth is enabled")
                        result.success(bluetoothAdapter?.isEnabled ?: false)
                    }

                    "getPairedDevices" -> {
                        if (!hasRequiredPermissions()) {
                            Log.e("Bluetooth", "Bluetooth permissions denied")
                            result.error(
                                "PERMISSION_DENIED",
                                "Required Bluetooth permissions not granted", null
                            )
                            return@setMethodCallHandler
                        }
                        Log.d("Bluetooth", "Getting paired devices")
                        val pairedDevices = getPairedDevices()
                        result.success(pairedDevices)
                    }

                    "getDeviceServices" -> {
                        val deviceAddress = call.argument<String>("deviceAddress")
                        if (deviceAddress == null) {
                            Log.e("Bluetooth", "Device address is missing")
                            result.error(
                                "INVALID_ARGUMENT",
                                "Device address is required", null
                            )
                            return@setMethodCallHandler
                        }
                        Log.d("Bluetooth", "Getting services for device: $deviceAddress")
                        getDeviceServices(deviceAddress) { services ->
                            handler.post {
                                Log.d("Bluetooth", "Services fetched: $services")
                                result.success(services)
                            }
                        }
                    }

                    "connectToDevice" -> {
                        val deviceAddress = call.argument<String>("deviceAddress")
                        if (deviceAddress == null) {
                            Log.e("Bluetooth", "Device address is missing")
                            result.error(
                                "INVALID_ARGUMENT",
                                "Device address is required", null
                            )
                            return@setMethodCallHandler
                        }
                        Log.d("Bluetooth", "Connecting to device: $deviceAddress")
                        connectToDevice(deviceAddress) { success ->
                            handler.post {
                                Log.d("Bluetooth", "Connection status: $success")
                                result.success(success)
                            }
                        }
                    }

                    "getBatteryLevel" -> {
                        val deviceAddress = call.argument<String>("deviceAddress")
                        if (deviceAddress == null) {
                            result.error(
                                "INVALID_ARGUMENT",
                                "Device address is required", null
                            )
                            return@setMethodCallHandler
                        }

                        getBatteryLevel(deviceAddress) { batteryLevel ->
                            handler.post {
                                if (batteryLevel != null) {
                                    result.success(batteryLevel)
                                } else {
                                    result.error(
                                        "BATTERY_LEVEL_ERROR",
                                        "Could not retrieve battery level",
                                        null
                                    )
                                }
                            }
                        }
                    }

                    "startAudioStreaming" -> {
                        val deviceAddress = call.argument<String>("deviceAddress")
                        val audioData = call.argument<ByteArray>("audioData")
                        if (deviceAddress == null || audioData == null) {
                            Log.e("Bluetooth", "Device address or audio data is missing")
                            result.error(
                                "INVALID_ARGUMENT",
                                "Device address and audio data are required", null
                            )
                            return@setMethodCallHandler
                        }
                        Log.d("Bluetooth", "Starting audio streaming for device: $deviceAddress")
                        handleAudioStreaming(deviceAddress, audioData) { success ->
                            handler.post {
                                Log.d("Bluetooth", "Audio streaming status: $success")
                                result.success(success)
                            }
                        }
                    }

                    "stopAudioStreaming" -> {
                        Log.d("Bluetooth", "Stopping audio streaming")
                        stopAudioStreaming()
                        result.success(true)
                    }

                    "disconnect" -> {
                        Log.d("Bluetooth", "Disconnecting from all devices")
                        disconnectAll()
                        result.success(true)
                    }

                    else -> result.notImplemented()
                }
            }
        }
    }

    private fun hasRequiredPermissions(): Boolean {
        Log.d("Bluetooth", "Checking Bluetooth permissions")
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            return ActivityCompat.checkSelfPermission(
                this,
                Manifest.permission.BLUETOOTH_CONNECT
            ) == PackageManager.PERMISSION_GRANTED
        }
        return true
    }

    private fun getPairedDevices(): List<Map<String, Any>> {
        Log.d("Bluetooth", "Fetching paired devices")
        val devices = mutableListOf<Map<String, Any>>()

        if (ActivityCompat.checkSelfPermission(
                this,
                Manifest.permission.BLUETOOTH_CONNECT
            ) == PackageManager.PERMISSION_GRANTED
        ) {
            bluetoothAdapter?.bondedDevices?.forEach { device ->
                Log.d("Bluetooth", "Paired device found: ${device.name} (${device.address})")
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
    private fun connectLE(device: BluetoothDevice, callback: (Boolean) -> Unit) {
        Log.d("Bluetooth", "Attempting LE connection")
        val gattCallback = object : BluetoothGattCallback() {
            override fun onConnectionStateChange(gatt: BluetoothGatt, status: Int, newState: Int) {
                when (newState) {
                    BluetoothProfile.STATE_CONNECTED -> {
                        Log.d("Bluetooth", "Connected to LE device")
                        callback(true)
                    }
                    BluetoothProfile.STATE_DISCONNECTED -> {
                        Log.d("Bluetooth", "Disconnected from LE device")
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

        device.connectGatt(this, false, gattCallback)
    }

    private fun connectDual(device: BluetoothDevice, callback: (Boolean) -> Unit) {
        // Try Classic connection first, then fall back to LE if needed
        connectClassic(device) { classicSuccess ->
            if (classicSuccess) {
                callback(true)
            } else {
                connectLE(device, callback)
            }
        }
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

            // Log device details
            Log.d("Bluetooth", "Device Name: ${it.name}")
            Log.d("Bluetooth", "Device Address: ${it.address}")
            Log.d("Bluetooth", "Device Type: ${it.type}")

            // Add more detailed service discovery
            servicesList.add("Device Name: ${it.name}")
            servicesList.add("Device Address: ${it.address}")
            servicesList.add("Device Type: ${getDeviceTypeName(it.type)}")

            // Check available UUIDs
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
        Log.d("Bluetooth", "Connecting to device: $deviceAddress")
        val device = bluetoothAdapter?.getRemoteDevice(deviceAddress)

        device?.let {
            Log.d("Bluetooth", "Device type: ${it.type}")
            when (it.type) {
                BluetoothDevice.DEVICE_TYPE_CLASSIC -> {
                    Log.d("Bluetooth", "Connecting to Classic device")
                    connectClassic(it, callback)
                }
                BluetoothDevice.DEVICE_TYPE_LE -> {
                    Log.d("Bluetooth", "Connecting to LE device")
                    connectLE(it, callback)
                }
                BluetoothDevice.DEVICE_TYPE_DUAL -> {
                    Log.d("Bluetooth", "Connecting to Dual-mode device")
                    connectDual(it, callback)
                }
                else -> {
                    Log.e("Bluetooth", "Unsupported or unknown device type: ${it.type}")
                    // Attempt fallback to Classic connection
                    connectClassic(it, callback)
                }
            }
        } ?: callback(false)
    }

    private fun connectClassic(device: BluetoothDevice, callback: (Boolean) -> Unit) {
        Thread {
            var socket: BluetoothSocket? = null
            try {
                if (ActivityCompat.checkSelfPermission(
                        this,
                        Manifest.permission.BLUETOOTH_CONNECT
                    ) != PackageManager.PERMISSION_GRANTED
                ) {
                    callback(false)
                    return@Thread
                }

                // Create multiple fallback methods for connection
                socket = device.createRfcommSocketToServiceRecord(SPP_UUID)

                // Attempt to cancel any ongoing discovery to improve connection
                bluetoothAdapter?.cancelDiscovery()

                socket.connect()
                classicSocket = socket
                Log.d(TAG, "Successfully connected to Classic device")
                callback(true)
            } catch (e: IOException) {
                Log.e(TAG, "Error connecting to Classic device: ${e.message}")

                // Additional fallback connection method
                try {
                    socket = fallbackConnect(device)
                    if (socket != null && socket.isConnected) {
                        classicSocket = socket
                        callback(true)
                        return@Thread
                    }
                } catch (fallbackEx: Exception) {
                    Log.e(TAG, "Fallback connection failed: ${fallbackEx.message}")
                }

                // Ensure socket is closed properly
                safeCloseSocket(socket)
                callback(false)
            }
        }.start()
    }
    private fun fallbackConnect(device: BluetoothDevice): BluetoothSocket? {
        return try {
            val method = device.javaClass.getMethod("createRfcommSocket", Int::class.javaPrimitiveType)
            method.invoke(device, 1) as BluetoothSocket?
        } catch (e: Exception) {
            Log.e(TAG, "Fallback connection method failed: ${e.message}")
            null
        }
    }


    private fun getBatteryLevel(deviceAddress: String, callback: (Int?) -> Unit) {
        // Validate device address
        val device = bluetoothAdapter?.getRemoteDevice(deviceAddress) ?: run {
            Log.e(TAG, "Invalid device address: $deviceAddress")
            callback(null)
            return
        }

        // Check Bluetooth permissions
        if (ActivityCompat.checkSelfPermission(
                this,
                Manifest.permission.BLUETOOTH_CONNECT
            ) != PackageManager.PERMISSION_GRANTED
        ) {
            Log.e(TAG, "Bluetooth connect permission not granted")
            callback(null)
            return
        }

        val bluetoothGattCallback = object : BluetoothGattCallback() {
            override fun onConnectionStateChange(gatt: BluetoothGatt, status: Int, newState: Int) {
                when (newState) {
                    BluetoothProfile.STATE_CONNECTED -> {
                        Log.d(TAG, "Connected to GATT server")
                        gatt.discoverServices()
                    }
                    BluetoothProfile.STATE_DISCONNECTED -> {
                        Log.d(TAG, "Disconnected from GATT server")
                        callback(null)
                        gatt.close()
                    }
                }
            }

            override fun onServicesDiscovered(gatt: BluetoothGatt, status: Int) {
                if (status == BluetoothGatt.GATT_SUCCESS) {
                    val batteryService = gatt.getService(BATTERY_SERVICE_UUID)
                    batteryService?.let { service ->
                        val batteryCharacteristic = service.getCharacteristic(BATTERY_LEVEL_CHARACTERISTIC_UUID)
                        batteryCharacteristic?.let { characteristic ->
                        gatt.setCharacteristicNotification(characteristic, true)

                            // Read battery level
                            if (gatt.readCharacteristic(characteristic)) {
                                Log.d(TAG, "Reading battery characteristic")
                            } else {
                                Log.e(TAG, "Failed to read battery characteristic")
                                callback(null)
                                gatt.disconnect()
                            }


                        } ?: run {
                            Log.e(TAG, "Battery level characteristic not found")
                            callback(null)
                            gatt.disconnect()
                        }
                    } ?: run {
                        Log.e(TAG, "Battery service not found")
                        callback(null)
                        gatt.disconnect()
                    }
                } else {
                    Log.e(TAG, "Service discovery failed")
                    callback(null)
                    gatt.disconnect()
                }
            }

            override fun onCharacteristicRead(
                gatt: BluetoothGatt,
                characteristic: BluetoothGattCharacteristic,
                value: ByteArray,
                status: Int
            ) {
                if (status == BluetoothGatt.GATT_SUCCESS &&
                    characteristic.uuid == BATTERY_LEVEL_CHARACTERISTIC_UUID
                ) {
                    val batteryLevel = value[0].toInt().coerceIn(0, 100)
                    Log.d(TAG, "Battery Level: $batteryLevel%")
                    callback(batteryLevel)
                    gatt.disconnect()
                } else {
                    Log.e(TAG, "Battery level read failed")
                    callback(null)
                    gatt.disconnect()
                }
            }
        }

        // Connect to GATT server
        val bluetoothGatt = device.connectGatt(
            this,
            false,  // autoConnect
            bluetoothGattCallback
        )
        this.gatt = bluetoothGatt
    }

    private fun handleAudioStreaming(deviceAddress: String, audioData: ByteArray, callback: (Boolean) -> Unit) {
        Log.d(TAG, "Starting audio streaming process for device: $deviceAddress")
        Log.d(TAG, "Audio data size: ${audioData.size} bytes")

        Thread {
            android.os.Process.setThreadPriority(android.os.Process.THREAD_PRIORITY_AUDIO)
            Log.d(TAG, "Audio thread priority set")

            val device = bluetoothAdapter?.getRemoteDevice(deviceAddress)
            if (device == null) {
                Log.e(TAG, "Failed to get remote device for address: $deviceAddress")
                handler.post { callback(false) }
                return@Thread
            }
            Log.d(TAG, "Retrieved remote device: ${device.name}")

            if (!checkPermissionsAndA2DPSupport(device)) {
                Log.e(TAG, "Permission check or A2DP support check failed")
                handler.post { callback(false) }
                return@Thread
            }
            Log.d(TAG, "Permissions and A2DP support verified")

            try {
                // Create temporary file
                val tempFile = File.createTempFile("audio", ".mp3", cacheDir)
                tempFile.writeBytes(audioData)
                Log.d(TAG, "Temporary audio file created: ${tempFile.path}")

                // Set up MediaExtractor
                val extractor = MediaExtractor()
                extractor.setDataSource(tempFile.path)
                Log.d(TAG, "MediaExtractor initialized with audio file")

                // Select audio track
                val audioTrackIndex = selectAudioTrack(extractor)
                if (audioTrackIndex < 0) {
                    Log.e(TAG, "No audio track found in the file")
                    handler.post { callback(false) }
                    return@Thread
                }
                Log.d(TAG, "Audio track selected, index: $audioTrackIndex")

                // Get format details
                val format = extractor.getTrackFormat(audioTrackIndex)
                val mime = format.getString(MediaFormat.KEY_MIME)
                Log.d(TAG, "Audio format retrieved - MIME: $mime")

                // Initialize decoder
                val decoder = MediaCodec.createDecoderByType(mime!!)
                decoder.configure(format, null, null, 0)
                decoder.start()
                Log.d(TAG, "Media decoder configured and started")

                // Set up AudioTrack
                val sampleRate = format.getInteger(MediaFormat.KEY_SAMPLE_RATE)
                val channelCount = format.getInteger(MediaFormat.KEY_CHANNEL_COUNT)
                val channelConfig = if (channelCount == 1) AudioFormat.CHANNEL_OUT_MONO else AudioFormat.CHANNEL_OUT_STEREO
                Log.d(TAG, "Audio properties - Sample Rate: $sampleRate, Channels: $channelCount")

                val minBufferSize = AudioTrack.getMinBufferSize(
                    sampleRate,
                    channelConfig,
                    AudioFormat.ENCODING_PCM_16BIT
                )
                Log.d(TAG, "Calculated minimum buffer size: $minBufferSize bytes")

                audioTrack = AudioTrack.Builder()
                    .setAudioAttributes(AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_MEDIA)
                        .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                        .build())
                    .setAudioFormat(AudioFormat.Builder()
                        .setEncoding(AudioFormat.ENCODING_PCM_16BIT)
                        .setSampleRate(sampleRate)
                        .setChannelMask(channelConfig)
                        .build())
                    .setBufferSizeInBytes(minBufferSize * 4)
                    .setTransferMode(AudioTrack.MODE_STREAM)
                    .setPerformanceMode(AudioTrack.PERFORMANCE_MODE_LOW_LATENCY)
                    .build()

                Log.d(TAG, "AudioTrack initialized with buffer size: ${minBufferSize * 4} bytes")

                audioTrack?.play()
                Log.d(TAG, "AudioTrack playback started")

                // Begin decoding and playing
                decodeAndPlay(extractor, decoder, audioTrackIndex)
                Log.d(TAG, "Audio decoding and playback completed successfully")

                handler.post {
                    callback(true)
                }

            } catch (e: Exception) {
                Log.e(TAG, "Error during audio streaming: ${e.message}", e)
                e.printStackTrace()
                stopAudioStreaming()
                handler.post { callback(false) }
            }
        }.start()
        Log.d(TAG, "Audio streaming thread started")
    }


    private fun selectAudioTrack(extractor: MediaExtractor): Int {
        for (i in 0 until extractor.trackCount) {
            val format = extractor.getTrackFormat(i)
            val mime = format.getString(MediaFormat.KEY_MIME)
            if (mime?.startsWith("audio/") == true) {
                extractor.selectTrack(i)
                return i
            }
        }
        return -1
    }

    private fun decodeAndPlay(extractor: MediaExtractor, decoder: MediaCodec, trackIndex: Int) {
        Log.d(TAG, "Starting decode and play process")
        val bufferInfo = MediaCodec.BufferInfo()
        val TIMEOUT_US = 10000L
        var isEOS = false
        var totalBytesProcessed = 0

        while (!isEOS) {
            // Handle input buffer
            val inputBufferId = decoder.dequeueInputBuffer(TIMEOUT_US)
            if (inputBufferId >= 0) {
                val inputBuffer = decoder.getInputBuffer(inputBufferId)
                val sampleSize = extractor.readSampleData(inputBuffer!!, 0)

                if (sampleSize < 0) {
                    Log.d(TAG, "Reached end of stream")
                    decoder.queueInputBuffer(inputBufferId, 0, 0, 0, MediaCodec.BUFFER_FLAG_END_OF_STREAM)
                    isEOS = true
                } else {
                    decoder.queueInputBuffer(inputBufferId, 0, sampleSize, extractor.sampleTime, 0)
                    extractor.advance()
                    totalBytesProcessed += sampleSize
                    Log.v(TAG, "Processed $totalBytesProcessed bytes so far")
                }
            }

            // Handle output buffer
            var outputBufferId = decoder.dequeueOutputBuffer(bufferInfo, TIMEOUT_US)
            while (outputBufferId >= 0) {
                val outputBuffer = decoder.getOutputBuffer(outputBufferId)
                val pcmData = ByteArray(bufferInfo.size)
                outputBuffer?.get(pcmData)

                val writtenBytes = audioTrack?.write(pcmData, 0, pcmData.size) ?: 0
                Log.v(TAG, "Written $writtenBytes bytes to AudioTrack")

                decoder.releaseOutputBuffer(outputBufferId, false)
                outputBufferId = decoder.dequeueOutputBuffer(bufferInfo, TIMEOUT_US)
            }
        }

        Log.d(TAG, "Cleaning up decoder and extractor")
        decoder.stop()
        decoder.release()
        extractor.release()
        Log.d(TAG, "Decode and play process completed")
    }

    private fun checkPermissionsAndA2DPSupport(device: BluetoothDevice): Boolean {
        if (ActivityCompat.checkSelfPermission(this, Manifest.permission.BLUETOOTH_CONNECT)
            != PackageManager.PERMISSION_GRANTED) {
            Log.e("Bluetooth", "Missing BLUETOOTH_CONNECT permission")
            return false
        }

        if (!isA2DPSupported(device) || bluetoothA2dp?.getConnectionState(device) != BluetoothProfile.STATE_CONNECTED) {
            Log.e("Bluetooth", "A2DP not supported or not connected")
            return false
        }

        return true
    }




    private fun isA2DPSupported(device: BluetoothDevice): Boolean {
        if (ActivityCompat.checkSelfPermission(this, Manifest.permission.BLUETOOTH_CONNECT)
            != PackageManager.PERMISSION_GRANTED) {
            return false
        }

        return device.uuids?.any { uuid ->
            uuid.uuid == A2DP_UUID
        } ?: false
    }

    private fun stopAudioStreaming() {
        Log.d("Bluetooth", "Stopping audio streaming")
        audioTrack?.apply {
            stop()
            flush()
            release()
        }
        audioTrack = null
    }

    private fun disconnectAll() {
        Log.d(TAG, "Disconnecting from all devices")

        // Safely close Classic Socket
        classicSocket?.let { socket ->
            try {
                if (socket.isConnected) {
                    socket.close()
                }
            } catch (e: IOException) {
                Log.e(TAG, "Error closing Classic socket: ${e.message}")
            }
            classicSocket = null
        }

        // Close GATT connection
        gatt?.let {
            it.disconnect()
            it.close()
            gatt = null
        }

        // Stop audio streaming
        stopAudioStreaming()
    }

    private fun requestBluetoothPermissions() {
        Log.d("Bluetooth", "Requesting Bluetooth permissions")
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

    private fun hasBluetoothPermissions(): Boolean {
        Log.d("Bluetooth", "Checking for required Bluetooth permissions")
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            ContextCompat.checkSelfPermission(
                this,
                Manifest.permission.BLUETOOTH_CONNECT
            ) == PackageManager.PERMISSION_GRANTED && ContextCompat.checkSelfPermission(
                this,
                Manifest.permission.BLUETOOTH_SCAN
            ) == PackageManager.PERMISSION_GRANTED
        } else {
            true
        }
    }
    private fun safeCloseSocket(socket: BluetoothSocket?) {
        socket?.let {
            try {
                if (it.isConnected) {
                    it.close()
                } else {
                    Log.d(TAG, "Socket is not connected, no need to close")
                }
            } catch (e: IOException) {
                Log.e(TAG, "Error closing Bluetooth socket: ${e.message}")
            }
        }
    }
}
