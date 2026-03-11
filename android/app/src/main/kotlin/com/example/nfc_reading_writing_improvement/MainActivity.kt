package com.example.nfc_reading_writing_improvement

import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

class MainActivity : FlutterActivity() {
    private val CHANNEL_LAB1 = "nfc_lab1"
    private val CHANNEL_LAB2 = "nfc_lab2"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // LAB 1: Granular MethodChannel Calls
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_LAB1).setMethodCallHandler { call, result ->
            CoroutineScope(Dispatchers.IO).launch {
                when (call.method) {
                    "detect" -> {
                        delay(40) // Mock hardware delay + RF spin up
                        withContext(Dispatchers.Main) { result.success(123456789) }
                    }
                    "login" -> {
                        val sector = call.argument<Int>("sector") ?: 0
                        
                        // Mimics PaxCardReader "amountdetect" loop
                        var amountdetect = 0
                        var amount = 0
                        var success = false

                        do {
                            delay(80) // Mock mPicc!!.m1Auth base delay
                            
                            // Mock failure for sector >= 16 (unformatted or different key for 4k tail)
                            if (sector >= 16) {
                                success = false
                            } else {
                                success = amount > 0 // In real world it drops connection often due to async gaps
                            }
                            
                            amount++
                            if (!success) {
                                do {
                                    delay(40) // Mock detect() delay retry
                                    amountdetect++
                                } while (true /* mocked card serial */ && amountdetect <= 1)
                            }
                        } while (!success && amount <= 1)

                        withContext(Dispatchers.Main) { result.success(success) }
                    }
                    "read" -> {
                        delay(40) // Mock hardware delay
                        val block = call.argument<Int>("block") ?: 0
                        val data = List(16) { it }
                        withContext(Dispatchers.Main) { result.success(data) }
                    }
                    "writeBlock" -> {
                        delay(40) // Mock hardware delay
                        val block = call.argument<Int>("block") ?: 0
                        withContext(Dispatchers.Main) { result.success(true) }
                    }
                    else -> withContext(Dispatchers.Main) { result.notImplemented() }
                }
            }
        }

        // LAB 2: Single Batch MethodChannel Call
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_LAB2).setMethodCallHandler { call, result ->
            CoroutineScope(Dispatchers.IO).launch {
                when (call.method) {
                    "readAll" -> {
                        val sectorKeys = call.argument<List<Map<String, Any>>>("sectorKeys") ?: emptyList()
                        val isAllKeys = call.argument<Boolean>("isAllKeys") ?: false
                        
                        // Hardware detect
                        delay(20) 
                        val serialNumber = listOf(1, 2, 3, 4) // Mock serial List<Int>

                        val resList = mutableListOf<Map<String, Any>>()
                        var lastSectorLogged = -1
                        var logged = false

                        for (keyMap in sectorKeys) {
                            val sector = keyMap["sector"] as Int
                            val key = keyMap["key"] as List<Int>
                            
                            val sectorBlock = sector * 4
                            if (lastSectorLogged != sector) {
                                if (sector >= 16) {
                                    delay(20) // Mock Native Hardware login fail for 4K tails
                                    logged = false
                                } else {
                                    delay(40) // Mock Native Hardware login (faster, no dropped connection)
                                    logged = true
                                }
                            }
                            
                            if (logged) {
                                lastSectorLogged = sector
                                val sectorData = mutableListOf<Int>()
                                // Hardware read 3 blocks per sector
                                for (i in sectorBlock until (sectorBlock + 3)) {
                                    delay(20) // Mock native hardware read
                                    sectorData.addAll(List(16) { it })
                                }
                                resList.add(mapOf("sector" to sector, "data" to sectorData))
                            } else if (isAllKeys && sector >= 16) {
                                break // The improvement!
                            }
                        }
                        
                        withContext(Dispatchers.Main) { result.success(resList) }
                    }
                    "writeAll" -> {
                        try {
                            // Hardware detect (simulated)
                            delay(20)
                            
                            val blocks = call.argument<List<Map<String, Any>>>("blocks") ?: emptyList() // From CardUpdateDataEntity
                            val keys = call.argument<List<Map<String, Any>>>("keys") ?: emptyList()
                            val serialNumber = listOf(1, 2, 3, 4)
                            val isInit = call.argument<Boolean>("isInit") ?: false
                            
                            var lastSector = -1
                            var logged = false
                            val writtenBlocks = mutableListOf<Map<String, Any>>()

                            for (item in blocks) {
                                val itemSector = item["sector"] as Int
                                val itemBlock = item["block"] as Int
                                val itemType = item["type"] as String? ?: "BLOCK"

                                val block = itemBlock + (itemSector * 4)
                                
                                if (lastSector != itemSector) {
                                    val sectorKeyMap = keys.firstOrNull { it["sector"] as Int == itemSector }
                                    val sectorKey = sectorKeyMap?.get("key") as? List<Int>
                                    
                                    if (sectorKey != null) {
                                        // Mimics the Lab 2 'try/catch' -> detect -> auth flow
                                        try {
                                            delay(40) // Mock Native m1Auth delay
                                            logged = true
                                        } catch (e: Exception) {
                                            delay(20) // Mock fast detect
                                            delay(40) // Retry auth
                                            logged = true
                                        }
                                    }
                                }

                                if (logged) {
                                    if (itemType == "BLOCK") {
                                        delay(20) // Mock write native
                                        writtenBlocks.add(mapOf("sector" to itemSector, "block" to itemBlock))
                                    } else if (itemType == "DECREMENT") {
                                        delay(20) // Mock decrement native
                                        writtenBlocks.add(mapOf("sector" to itemSector, "block" to itemBlock))
                                    } else {
                                        withContext(Dispatchers.Main) {
                                            result.error("Error", "Tipo de comando de gravação não implementado", null)
                                        }
                                        return@launch
                                    }
                                } else {
                                    break
                                }
                            }
                            
                            withContext(Dispatchers.Main) { result.success(writtenBlocks) }
                        } catch (e: Exception) {
                            withContext(Dispatchers.Main) {
                                result.error("EXCEPTION", e.message, null)
                            }
                        }
                    }
                    else -> withContext(Dispatchers.Main) { result.notImplemented() }
                }
            }
        }
    }
}
