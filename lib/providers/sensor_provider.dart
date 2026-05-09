import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:excel/excel.dart';
import 'dart:async';
import '../models/sensor_model.dart';
import '../models/telegram_config_model.dart';
import '../models/threshold_config_model.dart';
import '../services/firebase_service.dart';
import '../utils/download_helper.dart';

class SensorProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();

  SensorData? _liveSensor;
  List<SensorData> _history = [];
  bool _isLoading = true;
  List<String> _plantTypes = [];
  StreamSubscription? _plantTypesSub;

  Map<dynamic, dynamic> _unitsData = {};
  Map<dynamic, dynamic> get unitsData => _unitsData;

  List<String> get plantTypes => _plantTypes;

  // Configuration data
  TelegramConfig? _telegramConfig;
  ThresholdConfig? _thresholdConfig;

  SensorData? get liveSensor => _liveSensor;
  List<SensorData> get history => _history;
  bool get isLoading => _isLoading;

  // Configuration getters
  TelegramConfig? get telegramConfig => _telegramConfig;
  ThresholdConfig? get thresholdConfig => _thresholdConfig;

  SensorProvider() {
    _listenToSensorLive();
    _listenToHistory();
    _listenToPlantTypes();
    _listenToUnits();
    _loadConfigurations();
    _listenToThresholdConfigStream(); // NEW: Real-time threshold sync
  }

  void _listenToPlantTypes() {
    print('🌿 Starting plant types listener...');
    _plantTypesSub = _firebaseService.getPlantTypesStream().listen(
      (event) {
        if (event.snapshot.value != null) {
          final data = Map<dynamic, dynamic>.from(event.snapshot.value as Map);
          final types = data.values
              .map<String>(
                (item) =>
                    (item as Map)['label']?.toString().toLowerCase() ??
                    'unknown',
              )
              .where((type) => type != 'unknown')
              .toList();
          _plantTypes = types.cast<String>();
          print('✅ Plant types loaded: $_plantTypes');
          notifyListeners();
        }
      },
      onError: (error) {
        print('❌ Plant types error: $error');
      },
    );
  }

  void _listenToUnits() {
    print('📦 Starting units listener...');
    _firebaseService.getUnitsStream().listen(
      (event) {
        if (event.snapshot.value != null) {
          _unitsData = Map<dynamic, dynamic>.from(event.snapshot.value as Map);
          print('✅ Units data updated');
          notifyListeners();
        }
      },
      onError: (error) {
        print('❌ Units error: $error');
      },
    );
  }

  Future<void> _loadConfigurations() async {
    await _loadTelegramConfig();
    await _loadThresholdConfig();
  }

  Future<void> _loadTelegramConfig() async {
    print('📱 Loading telegram configuration...');
    _telegramConfig = await _firebaseService.getTelegramConfig();
    if (_telegramConfig != null) {
      print('✅ Telegram config loaded: ${_telegramConfig!.isActive}');
    } else {
      print('⚠️ No telegram config found');
    }
    notifyListeners();
  }

  Future<void> _loadThresholdConfig() async {
    print('⚙️ Loading threshold configuration...');
    _thresholdConfig = await _firebaseService.getThresholdConfig();
    if (_thresholdConfig != null) {
      print(
        '✅ Threshold config loaded: moisture_min=${_thresholdConfig!.moistureMin}',
      );
    } else {
      print('⚠️ No threshold config found');
    }
    notifyListeners();
  }

  // NEW: Real-time listener for threshold config
  void _listenToThresholdConfigStream() {
    print('⚙️ Starting threshold config stream listener...');
    _firebaseService.getThresholdConfigStream().listen(
      (event) {
        print('🔄 Threshold stream event: ${event.snapshot.value}');
        if (event.snapshot.value != null) {
          final data = Map<dynamic, dynamic>.from(event.snapshot.value as Map);
          _thresholdConfig = ThresholdConfig.fromMap(data);
          print(
            '✅ Threshold config synced: moisture_min=${_thresholdConfig!.moistureMin}',
          );
          notifyListeners();
        }
      },
      onError: (error) {
        print('❌ Threshold stream error: $error');
      },
    );
  }

  void _listenToSensorLive() {
    print('🎧 Starting sensor live listener...');
    _firebaseService.getSensorLive().listen(
      (event) {
        print('📊 Sensor live event received: ${event.snapshot.value}');
        if (event.snapshot.value != null) {
          final data = Map<dynamic, dynamic>.from(event.snapshot.value as Map);
          print('📈 Parsed sensor data: $data');
          _liveSensor = SensorData.fromMap(data);
          _isLoading = false;
          notifyListeners();
          print('✅ Sensor data updated: $_liveSensor');
        } else {
          print('⚠️ No sensor data received');
        }
      },
      onError: (error) {
        print('❌ Sensor live error: $error');
      },
    );
  }

  void _listenToHistory() {
    print('📚 Starting history listener...');
    _firebaseService.getHistory().listen(
      (event) {
        print(
          '📜 History event received: ${event.snapshot.value != null ? "Has data" : "No data"}',
        );
        if (event.snapshot.value != null) {
          final rawData = Map<dynamic, dynamic>.from(
            event.snapshot.value as Map,
          );
          print('📋 Raw history data keys: ${rawData.keys.length}');
          _history = rawData.entries.map((entry) {
            final item = Map<dynamic, dynamic>.from(entry.value as Map);
            return SensorData.fromMap(item);
          }).toList();

          print('📊 History items parsed: ${_history.length}');

          // Sort terbaru di atas — gunakan getter timestamp yang sudah handle berbagai format
          _history.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          _isLoading = false;
          notifyListeners();
          print('✅ History data updated: ${_history.length} items');
        } else {
          print('⚠️ No history data received');
          _isLoading = false;
          notifyListeners();
        }
      },
      onError: (error) {
        print('❌ History error: $error');
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  // Manual Pump
  Future<void> activatePump(int minutes) async {
    await _firebaseService.activateManualPump(minutes);
    // Optional: bisa tambah toast atau notifikasi
  }

  // Update Threshold (deprecated - use updateThresholdConfig)
  Future<void> updateThreshold(String key, int value) async {
    await _firebaseService.updateThreshold(key, value);
    // Reload threshold config after update
    await _loadThresholdConfig();
  }

  // Update Telegram Config
  Future<void> updateTelegramConfig(TelegramConfig config) async {
    await _firebaseService.updateTelegramConfig(config);
    _telegramConfig = config;
    notifyListeners();
  }

  // Update Threshold Config
  Future<void> updateThresholdConfig(ThresholdConfig config) async {
    await _firebaseService.updateThresholdConfig(config);
    _thresholdConfig = config;
    notifyListeners();
  }

  @override
  void dispose() {
    _plantTypesSub?.cancel();
    super.dispose();
  }

  // Filter by plant type + date (case-insensitive)
  List<SensorData> getFilteredByPlant(
    String? plantType, {
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _history.where((item) {
      // 1. Plant filter
      if (plantType != null) {
        final moisture = item.getMoisture(plantType);
        if (moisture == null) return false;
      }

      // 2. Date filter
      if (startDate != null && endDate != null) {
        try {
          final itemDate = item.timestamp;
          final itemDateOnly = DateTime(
            itemDate.year,
            itemDate.month,
            itemDate.day,
          );
          final startOnly = DateTime(
            startDate.year,
            startDate.month,
            startDate.day,
          );
          final endOnly = DateTime(endDate.year, endDate.month, endDate.day);
          return !itemDateOnly.isBefore(startOnly) &&
              !itemDateOnly.isAfter(endOnly);
        } catch (e) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  // Get moisture from device/units for a specific plant
  double getMoistureForPlant(String plantType) {
    final ptLower = plantType.toLowerCase();
    if (_unitsData.containsKey(ptLower)) {
      final plantData = _unitsData[ptLower];
      if (plantData is Map) {
        for (var boxKey in plantData.keys) {
          final boxData = plantData[boxKey];
          if (boxData is Map && boxData.containsKey('moisture')) {
            return (boxData['moisture'] ?? 0).toDouble();
          }
        }
      }
    }
    return 0.0;
  }

  // Filter data berdasarkan date range (legacy)
  List<SensorData> getFilteredData(DateTime startDate, DateTime endDate) {
    return _history.where((item) {
      try {
        final itemDate = item.timestamp;
        final itemDateOnly = DateTime(
          itemDate.year,
          itemDate.month,
          itemDate.day,
        );
        final startDateOnly = DateTime(
          startDate.year,
          startDate.month,
          startDate.day,
        );
        final endDateOnly = DateTime(endDate.year, endDate.month, endDate.day);
        return !itemDateOnly.isBefore(startDateOnly) &&
            !itemDateOnly.isAfter(endDateOnly);
      } catch (e) {
        return false;
      }
    }).toList();
  }

  // Export data to PDF format
  Future<void> exportToPDF(
    List<SensorData> data, {
    Set<String> selectedSensors = const {
      'moisture',
      'light',
      'water',
      'battery',
    },
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final pdf = pw.Document();

    // Create table headers
    List<String> headers = ['TIMESTAMP'];
    if (selectedSensors.contains('moisture')) headers.add('SOIL (%)');
    if (selectedSensors.contains('light')) headers.add('LIGHT (%)');
    if (selectedSensors.contains('water')) headers.add('WATER (%)');
    if (selectedSensors.contains('battery')) headers.add('BATT (%)');

    // Create table data
    List<List<String>> tableData = [];
    for (var item in data) {
      List<String> row = [item.time];
      if (selectedSensors.contains('moisture')) {
        row.add(item.moisture.toStringAsFixed(1));
      }
      if (selectedSensors.contains('light')) {
        row.add(item.light.toStringAsFixed(1));
      }
      if (selectedSensors.contains('water')) {
        row.add(item.water.toStringAsFixed(1));
      }
      if (selectedSensors.contains('battery')) {
        row.add(item.battery.toStringAsFixed(1));
      }
      tableData.add(row);
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Container(
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(color: PdfColors.teal),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'HydroGrow Monitoring Report',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'Generated on ${DateTime.now().toString()}',
                      style: pw.TextStyle(fontSize: 12, color: PdfColors.white),
                    ),
                    if (startDate != null && endDate != null)
                      pw.Text(
                        'Period: ${startDate.toString().split(' ')[0]} to ${endDate.toString().split(' ')[0]}',
                        style: pw.TextStyle(
                          fontSize: 12,
                          color: PdfColors.white,
                        ),
                      ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              // Table
              pw.TableHelper.fromTextArray(
                headers: headers,
                data: tableData,
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.grey700,
                ),
                cellHeight: 30,
                cellAlignments: {
                  0: pw.Alignment.centerLeft,
                  for (int i = 1; i < headers.length; i++)
                    i: pw.Alignment.center,
                },
                cellStyle: const pw.TextStyle(fontSize: 10),
              ),
              pw.SizedBox(height: 20),
              // Footer
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey),
                ),
                child: pw.Text(
                  'Total Records: ${data.length}',
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey700,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    // Print/Share PDF
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'hydrogrow_monitoring_report.pdf',
    );
  }

  // Export data to CSV format
  Future<void> exportToCSV(
    List<SensorData> data, {
    required String plantType,
    Set<String> selectedSensors = const {
      'moisture',
      'light',
      'water',
      'battery',
    },
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    // Create CSV headers
    List<String> headers = ['TIMESTAMP'];
    if (selectedSensors.contains('moisture')) headers.add('SOIL (%)');
    if (selectedSensors.contains('light')) headers.add('LIGHT (%)');
    if (selectedSensors.contains('water')) headers.add('WATER (%)');
    if (selectedSensors.contains('battery')) headers.add('BATT (%)');

    // Create CSV data
    String csv = '${headers.join(',')}\n';
    for (var item in data) {
      final formattedTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(item.timestamp);
      List<String> row = [formattedTime];
      if (selectedSensors.contains('moisture')) {
        final m = item.getMoisture(plantType) ?? 0.0;
        row.add(m.toStringAsFixed(1));
      }
      if (selectedSensors.contains('light')) {
        row.add(item.light.toStringAsFixed(1));
      }
      if (selectedSensors.contains('water')) {
        row.add(item.water.toStringAsFixed(1));
      }
      if (selectedSensors.contains('battery')) {
        row.add(item.battery.toStringAsFixed(1));
      }
      csv += '${row.join(',')}\n';
    }

    // Trigger download
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    downloadFile('hydrogrow_monitoring_$timestamp.csv', csv);
    debugPrint('CSV Data generated and download triggered');
  }

  // Export data to XLSX format
  Future<void> exportToXLSX(
    List<SensorData> data, {
    required String plantType,
    Set<String> selectedSensors = const {
      'moisture',
      'light',
      'water',
      'battery',
    },
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final excel = Excel.createExcel();
    final sheet = excel['Sheet1'];

    // Create headers
    List<String> headers = ['TIMESTAMP'];
    if (selectedSensors.contains('moisture')) headers.add('SOIL (%)');
    if (selectedSensors.contains('light')) headers.add('LIGHT (%)');
    if (selectedSensors.contains('water')) headers.add('WATER (%)');
    if (selectedSensors.contains('battery')) headers.add('BATT (%)');
    
    // Add headers to sheet
    sheet.appendRow(headers.map((e) => TextCellValue(e)).toList());
    
    // Style headers
    final headerStyle = CellStyle(
      bold: true,
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      backgroundColorHex: ExcelColor.fromHexString('#10B981'),
      horizontalAlign: HorizontalAlign.Center,
    );
    for (int col = 0; col < headers.length; col++) {
      sheet.updateCell(
        CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0),
        TextCellValue(headers[col]),
        cellStyle: headerStyle,
      );
      // set column width
      sheet.setColumnWidth(col, 15.0);
    }
    sheet.setColumnWidth(0, 22.0); // Make timestamp column wider


    // Add data
    for (var item in data) {
      final formattedTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(item.timestamp);
      List<CellValue> row = [TextCellValue(formattedTime)];
      if (selectedSensors.contains('moisture')) {
        final m = item.getMoisture(plantType) ?? 0.0;
        row.add(DoubleCellValue(m));
      }
      if (selectedSensors.contains('light')) {
        row.add(DoubleCellValue(item.light));
      }
      if (selectedSensors.contains('water')) {
        row.add(DoubleCellValue(item.water));
      }
      if (selectedSensors.contains('battery')) {
        row.add(DoubleCellValue(item.battery));
      }
      sheet.appendRow(row);
    }

    final bytes = excel.encode();
    if (bytes != null) {
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      downloadBytes('hydrogrow_monitoring_$timestamp.xlsx', bytes);
      debugPrint('XLSX Data generated and download triggered');
    }
  }
}
