package com.example.nfc_reading_writing_improvement

import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

class MainActivity : FlutterActivity() {
    private val CHANNEL_LAB1 = "nfc_lab1"
    private val CHANNEL_LAB2 = "nfc_lab2"
    private val EVENT_CHANNEL_LAB2 = "nfc_lab2_progress"

    private val scope = CoroutineScope(Dispatchers.IO + SupervisorJob())

    private var progressEventSink: EventChannel.EventSink? = null

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL_LAB2)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    progressEventSink = events
                }
                override fun onCancel(arguments: Any?) {
                    progressEventSink = null
                }
            })

        // LAB 1: Granular MethodChannel Calls (unchanged — the point is to show the bad way)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_LAB1).setMethodCallHandler { call, result ->
            scope.launch {
                when (call.method) {
                    "detect" -> {
                        delay(40)
                        withContext(Dispatchers.Main) { result.success(123456789) }
                    }
                    "login" -> {
                        val sector = call.argument<Int>("sector") ?: 0

                        var amountdetect = 0
                        var amount = 0
                        var success = false

                        do {
                            delay(80)
                            success = if (sector >= 16) {
                                false
                            } else {
                                amount > 0
                            }
                            amount++
                            if (!success) {
                                do {
                                    delay(40)
                                    amountdetect++
                                } while (amountdetect <= 1) // Fix: removed redundant `true &&`
                            }
                        } while (!success && amount <= 1)

                        withContext(Dispatchers.Main) { result.success(success) }
                    }
                    "read" -> {
                        delay(40)
                        val data = List(16) { it }
                        withContext(Dispatchers.Main) { result.success(data) }
                    }
                    "writeBlock" -> {
                        delay(40)
                        withContext(Dispatchers.Main) { result.success(true) }
                    }
                    else -> withContext(Dispatchers.Main) { result.notImplemented() }
                }
            }
        }

        // LAB 2: Single Batch MethodChannel Call
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_LAB2).setMethodCallHandler { call, result ->
            scope.launch {
                when (call.method) {
                    "readAll" -> {
                        val sectorKeys = call.argument<List<Map<String, Any>>>("sectorKeys") ?: emptyList()
                        // Fix #3: cardType replaces the magic number heuristic
                        val cardType = call.argument<String>("cardType") ?: "1K"
                        val isAllKeys = call.argument<Boolean>("isAllKeys") ?: false
                        val maxFormattedSector = if (cardType == "4K") 16 else 0

                        delay(20)

                        val resList = mutableListOf<Map<String, Any>>()
                        var lastSectorLogged = -1
                        var logged = false

                        for ((index, keyMap) in sectorKeys.withIndex()) {
                            val sector = keyMap["sector"] as Int
                            val key = keyMap["key"] as List<Int>
                            val sectorBlock = sector * 4

                            withContext(Dispatchers.Main) {
                                progressEventSink?.success(
                                    mapOf(
                                        "type" to "read",
                                        "sector" to sector,
                                        "total" to sectorKeys.size,
                                        "index" to index
                                    )
                                )
                            }

                            if (lastSectorLogged != sector) {
                                if (sector >= maxFormattedSector) {
                                    delay(20)
                                    logged = false
                                } else {
                                    logged = tryLogin(sector)
                                }
                            }

                            if (logged) {
                                lastSectorLogged = sector
                                val sectorData = mutableListOf<Int>()
                                for (i in sectorBlock until (sectorBlock + 3)) {
                                    delay(20)
                                    sectorData.addAll(List(16) { it })
                                }
                                resList.add(mapOf("sector" to sector, "data" to sectorData, "success" to true))
                            } else if (isAllKeys && sector >= maxFormattedSector) {
                                break
                            }
                        }

                        withContext(Dispatchers.Main) { result.success(resList) }
                    }

                    "writeAll" -> {
                        try {
                            delay(20)

                            val blocks = call.argument<List<Map<String, Any>>>("blocks") ?: emptyList()
                            val keys = call.argument<List<Map<String, Any>>>("keys") ?: emptyList()
                            val isInit = call.argument<Boolean>("isInit") ?: false

                            var lastSector = -1
                            var logged = false
                            val writtenBlocks = mutableListOf<Map<String, Any>>()

                            for ((index, item) in blocks.withIndex()) {
                                val itemSector = item["sector"] as Int
                                val itemBlock = item["block"] as Int
                                val itemType = item["type"] as String? ?: "BLOCK"
                                val block = itemBlock + (itemSector * 4)

                                withContext(Dispatchers.Main) {
                                    progressEventSink?.success(
                                        mapOf(
                                            "type" to "write",
                                            "sector" to itemSector,
                                            "block" to itemBlock,
                                            "total" to blocks.size,
                                            "index" to index
                                        )
                                    )
                                }

                                if (lastSector != itemSector) {
                                    val sectorKeyMap = keys.firstOrNull { it["sector"] as Int == itemSector }
                                    val sectorKey = sectorKeyMap?.get("key") as? List<Int>

                                    if (sectorKey != null) {
                                        logged = tryLogin(itemSector)
                                    }
                                }

                                if (logged) {
                                    lastSector = itemSector
                                    val writeSuccess = when (itemType) {
                                        "BLOCK", "DECREMENT" -> {
                                            delay(20)
                                            true
                                        }
                                        else -> {
                                            withContext(Dispatchers.Main) {
                                                result.error("Error", "Tipo de comando de gravação não implementado: $itemType", null)
                                            }
                                            return@launch
                                        }
                                    }
                                    writtenBlocks.add(
                                        mapOf("sector" to itemSector, "block" to itemBlock, "success" to writeSuccess)
                                    )
                                } else {
                                    writtenBlocks.add(
                                        mapOf("sector" to itemSector, "block" to itemBlock, "success" to false)
                                    )
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

    private suspend fun tryLogin(sector: Int): Boolean {
        delay(40)
        val firstTry = sector < 16
        if (firstTry) return true

        delay(20) 
        delay(40)
        return sector < 16
    }

    override fun onDestroy() {
        super.onDestroy()
        scope.cancel()
    }
}
