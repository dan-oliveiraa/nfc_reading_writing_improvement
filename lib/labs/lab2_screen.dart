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

  void _runLab2() async {
    setState(() {
      _isRunning = true;
      _result = 'Running...';
    });

    final stopwatch = Stopwatch()..start();

    try {
      // Mock 40 sectors to read (Full Mifare Classic 4K)
      final keys = List.generate(
        40,
        (index) => SectorKeyEntity(
          sector: index,
          key: [0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF],
        ),
      );

      final readData = await _nfcService.read(keys);

      // Mock data to write
      final writeBlocks = <Map<String, dynamic>>[];
      for (int sector = 0; sector < 16; sector++) {
        writeBlocks.add({'sector': sector, 'block': 0, 'type': 'BLOCK', 'data': List.generate(16, (i) => i)});
        writeBlocks.add({'sector': sector, 'block': 1, 'type': 'BLOCK', 'data': List.generate(16, (i) => i)});
        writeBlocks.add({'sector': sector, 'block': 2, 'type': 'BLOCK', 'data': List.generate(16, (i) => i)});
      }

      final writeData = CardInitDataEntity(
        initialize: CardUpdateDataEntity(
          keys: keys,
          blocks: writeBlocks,
        ),
      );

      final writtenData = await _nfcService.writeCard(writeData, 123456789);

      stopwatch.stop();

      setState(() {
        _elapsedTime = stopwatch.elapsed;
        _result =
            '✅ Success\nRead ${readData.length} sectors.\nWritten ${writtenData.length} blocks.\n\nElapsed Time: ${_elapsedTime.inMilliseconds} ms';
      });
    } catch (e) {
      stopwatch.stop();
      setState(() {
        _elapsedTime = stopwatch.elapsed;
        _result = '❌ Error: $e\nElapsed Time: ${_elapsedTime.inMilliseconds} ms';
      });
    } finally {
      setState(() {
        _isRunning = false;
      });
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
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                child: _isRunning
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Start Lab 2', style: TextStyle(fontSize: 18)),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                width: double.infinity,
                child: Text(
                  _result,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
