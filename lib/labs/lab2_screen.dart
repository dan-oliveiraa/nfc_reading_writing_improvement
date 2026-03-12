import 'dart:async';
import 'package:flutter/material.dart';
import '../domain/entities/nfc_entities.dart';
import '../nfc/nfc_service_lab2.dart';

class Lab2Screen extends StatefulWidget {
  const Lab2Screen({super.key});

  @override
  State<Lab2Screen> createState() => _Lab2ScreenState();
}

class _Lab2ScreenState extends State<Lab2Screen> {
  final NfcServiceLab2 _nfcService = NfcServiceLab2();

  bool _isRunning = false;
  String _result = '';
  Duration _elapsedTime = Duration.zero;

  StreamSubscription<NfcProgressEvent>? _progressSub;
  String _progressLabel = '';
  double _progressValue = 0.0;

  @override
  void dispose() {
    _progressSub?.cancel();
    super.dispose();
  }

  void _runLab2() async {
    setState(() {
      _isRunning = true;
      _result = '';
      _progressLabel = '';
      _progressValue = 0.0;
    });

    _progressSub?.cancel();
    _progressSub = _nfcService.progressStream.listen((event) {
      setState(() {
        _progressValue = event.percentage;
        if (event.type == 'read') {
          _progressLabel =
              'Reading sector ${event.sector + 1} / ${event.total}';
        } else {
          _progressLabel =
              'Writing block ${event.block} (sector ${event.sector + 1}) — ${event.index + 1}/${event.total}';
        }
      });
    });

    final stopwatch = Stopwatch()..start();

    try {
      const cardType = '4K';

      final keys = List.generate(
        40,
        (index) => SectorKeyEntity(
          sector: index,
          key: [0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF],
        ),
      );

      final readData = await _nfcService.read(keys, cardType: cardType);

      final writeBlocks = <Map<String, dynamic>>[];
      for (int sector = 0; sector < 16; sector++) {
        writeBlocks.add({
          'sector': sector,
          'block': 0,
          'type': 'BLOCK',
          'data': List.generate(16, (i) => i),
        });
        writeBlocks.add({
          'sector': sector,
          'block': 1,
          'type': 'BLOCK',
          'data': List.generate(16, (i) => i),
        });
        writeBlocks.add({
          'sector': sector,
          'block': 2,
          'type': 'BLOCK',
          'data': List.generate(16, (i) => i),
        });
      }

      final writeData = CardInitDataEntity(
        initialize: CardUpdateDataEntity(keys: keys, blocks: writeBlocks),
      );

      final writtenData = await _nfcService.writeCard(writeData, 123456789);
      final failedBlocks = writtenData.where((b) => !b.success).toList();

      stopwatch.stop();

      setState(() {
        _elapsedTime = stopwatch.elapsed;
        _progressLabel = '';
        _progressValue = 1.0;
        _result = failedBlocks.isEmpty
            ? '✅ Success\nRead ${readData.length} sectors.\nWritten ${writtenData.length} blocks.\n\nElapsed Time: ${_elapsedTime.inMilliseconds} ms'
            : '⚠️ Partial Success\nRead ${readData.length} sectors.\n${failedBlocks.length} block(s) failed to write.\n\nElapsed Time: ${_elapsedTime.inMilliseconds} ms';
      });
    } catch (e) {
      stopwatch.stop();
      setState(() {
        _elapsedTime = stopwatch.elapsed;
        _progressLabel = '';
        _result =
            '❌ Error: $e\nElapsed Time: ${_elapsedTime.inMilliseconds} ms';
      });
    } finally {
      _progressSub?.cancel();
      setState(() => _isRunning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lab 2 - The Good Way'),
        backgroundColor: Colors.green,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'This lab delegates the entire NFC loop to the Native Android layer using a single batch MethodChannel call, avoiding the async overhead between Flutter and Native.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isRunning ? null : _runLab2,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
                child: _isRunning
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Start Lab 2', style: TextStyle(fontSize: 18)),
              ),
              const SizedBox(height: 32),

              // Fix #1: Progress bar + label
              if (_isRunning || _progressValue > 0) ...[
                LinearProgressIndicator(
                  value: _progressValue,
                  backgroundColor: Colors.grey[300],
                  color: Colors.green,
                  minHeight: 8,
                ),
                const SizedBox(height: 8),
                Text(
                  _progressLabel,
                  style: const TextStyle(fontSize: 13, color: Colors.black54),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
              ],

              if (_result.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  width: double.infinity,
                  child: Text(
                    _result,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
