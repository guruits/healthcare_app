package com.example.health

import android.annotation.SuppressLint
import android.app.Activity
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant

class MainActivity : FlutterActivity() {
    private val CHANNEL = "bluetooth.channel"
    private var deviceList: MutableList<BluetoothDevice> = mutableListOf()
    private var bluetoothAdapter: BluetoothAdapter? = BluetoothAdapter.getDefaultAdapter()

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getBlue" -> bluetoothWrapper(result)
                "discoverBlue" -> discoverDevices(result)
                "allPaired" -> getConnectedDevices(result)
                "connectDevice" -> connectDevice(call.argument<String>("deviceName"), result)
                "disconnectDevice" -> disconnectDevice(call.argument<String>("deviceName"), result)
                else -> result.notImplemented()
            }
        }
    }

    private fun discoverDevices(result: MethodChannel.Result) {
        deviceList.clear()
        val myAdapter = bluetoothAdapter ?: run {
            result.error("Bluetooth Adapter", "Bluetooth not supported", null)
            return
        }

        myAdapter.startDiscovery()
        val filter = IntentFilter(BluetoothDevice.ACTION_FOUND)

        val receiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context, intent: Intent) {
                when (intent.action) {
                    BluetoothDevice.ACTION_FOUND -> {
                        val device: BluetoothDevice? = intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE)
                        if (device != null && !deviceList.contains(device)) {
                            deviceList.add(device)
                        }
                    }
                    BluetoothAdapter.ACTION_DISCOVERY_FINISHED -> {
                        myAdapter.cancelDiscovery()
                        val deviceNames = deviceList.map { it.name }
                        result.success(deviceNames)
                        unregisterReceiver(this) // Unregister after discovery is complete
                    }
                }
            }
        }

        registerReceiver(receiver, filter)
        myAdapter.startDiscovery()
    }

    private fun connectDevice(deviceName: String?, result: MethodChannel.Result) {
        deviceList.forEach { device ->
            if (device.name == deviceName) {
                // Implement the logic to connect to the device
                // In Android, you would typically use BluetoothSocket for connecting
                // This is a simplified example
                result.success("Connected to $deviceName")
                return
            }
        }
        result.error("Device not found", "No device found with name $deviceName", null)
    }

    private fun disconnectDevice(deviceName: String?, result: MethodChannel.Result) {
        // Implement logic to disconnect from a device
        result.success("Disconnected from $deviceName") // Simplified example
    }

    private fun getConnectedDevices(result: MethodChannel.Result) {
        val pairedDevices = bluetoothAdapter?.bondedDevices?.map { it.name } ?: emptyList()
        result.success(pairedDevices)
    }

    private fun bluetoothWrapper(result: MethodChannel.Result) {
        checkAdapter(result)
        enableAdapter()
    }

    private fun checkAdapter(result: MethodChannel.Result) {
        if (bluetoothAdapter == null) {
            result.error("Bluetooth adapter doesn't exist on this device", null, null)
        } else {
            result.success("Bluetooth adapter exists on device")
        }
    }

    @SuppressLint("MissingPermission")
    private fun enableAdapter() {
        if (!bluetoothAdapter!!.isEnabled) {
            val enableIntent = Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE)
            startActivityForResult(enableIntent, 1)
        }
    }
}