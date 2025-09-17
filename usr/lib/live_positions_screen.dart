import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// Data model for a position
class Position {
  final String index;
  final String size;
  final String profit;
  final dynamic entry;
  final String stoploss;
  final String open;
  final String? close;

  Position({
    required this.index,
    required this.size,
    required this.profit,
    required this.entry,
    required this.stoploss,
    required this.open,
    this.close,
  });

  factory Position.fromJson(Map<String, dynamic> json) {
    return Position(
      index: json['index'] ?? '',
      size: json['size'] ?? '0',
      profit: json['profit'] ?? '0E',
      entry: json['entry'] ?? 0,
      stoploss: json['stoploss'] ?? 'N/A',
      open: json['open'] ?? '',
      close: json['close'],
    );
  }
}

class LivePositionsScreen extends StatefulWidget {
  const LivePositionsScreen({super.key});

  @override
  State<LivePositionsScreen> createState() => _LivePositionsScreenState();
}

class _LivePositionsScreenState extends State<LivePositionsScreen> {
  late Future<List<Position>> _positionsFuture;
  Timer? _timer;

  final Map<String, Map<String, String>> _algoMap = {
    "Germany 40 Cash (E1)": {
      "1.2": "PA-DAX 5M V1.0",
      "0.8": "PA-DAX 15M V0.10",
      "0.5": "PA-DAX 1H V0.01",
      "0.6": "PA-DAX 30M V0.20",
      "1.1": "PA-DAX 10M V1.25"
    },
    "Spot Gold (£1 contract)": {
      "8.0": "PA-GOLD 1D V0.10",
      "4.0": "PA-GOLD 1H V0.10"
    },
    "US Tech 100 Cash (£1)": {
      "0.7": "PA-NAS 1H V0.90",
      "0.8": "PA-NAS 3M V0.2",
      "0.5": "PA-NAS 30M V0.250"
    },
    "Wall Street Cash (£1)": {
      "0.3": "PA-WS 3M V1.6"
    },
    "GBP/USD Mini": {
      "2.5": "PA-GBP/USD 4H V0.10"
    }
  };

  @override
  void initState() {
    super.initState();
    _positionsFuture = _fetchPositions();
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      setState(() {
        _positionsFuture = _fetchPositions();
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<List<Position>> _fetchPositions() async {
    final response = await http.get(Uri.parse("https://profitalgos.com/api/get_live_positions.php"));

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      List<Position> positions = body.map((dynamic item) => Position.fromJson(item)).toList();
      
      // Filter out positions that are closed
      positions.removeWhere((p) => p.close != null);

      return positions;
    } else {
      throw Exception('Failed to load positions');
    }
  }

  String _normalizeIndexName(String index) {
    String clean = index.trim();
    if (clean.contains("Spot Gold")) return "Spot Gold (£1 contract)";
    if (clean.contains("Germany 40")) return "Germany 40 Cash (E1)";
    if (clean.contains("US Tech 100")) return "US Tech 100 Cash (£1)";
    if (clean.contains("Wall Street")) return "Wall Street Cash (£1)";
    if (clean.contains("GBP/USD")) return "GBP/USD Mini";
    return index;
  }

  String _getAlgoName(String index, String size) {
    String cleanIndex = _normalizeIndexName(index);
    double sizeValue = double.tryParse(size) ?? 0.0;
    String absSize = sizeValue.abs().toStringAsFixed(1);
    return _algoMap[cleanIndex]?[absSize] ?? "Okänd Algo";
  }

  Widget _buildIcon(String index) {
    String name = _normalizeIndexName(index).toLowerCase();
    if (name.contains("germany") || name.contains("dax")) {
      return Image.network("https://flagcdn.com/16x12/de.png", width: 24);
    } else if (name.contains("wall street") || name.contains("us tech")) {
      return Image.network("https://flagcdn.com/16x12/us.png", width: 24);
    } else if (name.contains("spot gold")) {
      return const Text("🟡", style: TextStyle(fontSize: 20));
    } else if (name.contains("gbp/usd")) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.network("https://flagcdn.com/16x12/gb.png", width: 24),
          const SizedBox(width: 2),
          Image.network("https://flagcdn.com/16x12/us.png", width: 24),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Positioner'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: FutureBuilder<List<Position>>(
        future: _positionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Inga öppna positioner att visa.'));
          } else {
            List<Position> positions = snapshot.data!;
            return ListView.builder(
              itemCount: positions.length,
              itemBuilder: (context, index) {
                final position = positions[index];
                final profitValue = double.tryParse(position.profit.replaceAll('E', '').replaceAll(',', '.')) ?? 0.0;
                final profitColor = profitValue < 0 ? Colors.red : Colors.green;
                final direction = (double.tryParse(position.size) ?? 0.0) > 0 ? "Long" : "Short";
                final algoName = _getAlgoName(position.index, position.size);
                
                String openDateStr = 'N/A';
                if(position.open.isNotEmpty) {
                  try {
                    final dateObj = DateTime.parse(position.open + 'Z').toLocal();
                    openDateStr = "${dateObj.year}-${dateObj.month.toString().padLeft(2, '0')}-${dateObj.day.toString().padLeft(2, '0')} ${dateObj.hour.toString().padLeft(2, '0')}:${dateObj.minute.toString().padLeft(2, '0')}";
                  } catch(e) {
                    // ignore
                  }
                }

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _buildIcon(position.index),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                algoName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ),
                            Text(direction, style: TextStyle(color: direction == "Long" ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildInfoColumn('Profit', position.profit.replaceFirst('E', '€'), color: profitColor),
                            _buildInfoColumn('Entry', position.entry.toString()),
                            _buildInfoColumn('Stop Loss', position.stoploss),
                          ],
                        ),
                        const SizedBox(height: 8),
                         Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                             _buildInfoColumn('Size', position.size),
                             _buildInfoColumn('Open', openDateStr),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }

  Widget _buildInfoColumn(String title, String value, {Color color = Colors.black}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color)),
      ],
    );
  }
}
