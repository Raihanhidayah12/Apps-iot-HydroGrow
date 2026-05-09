import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../providers/sensor_provider.dart';

class MonitoringScreen extends StatefulWidget {
  const MonitoringScreen({super.key});

  @override
  State<MonitoringScreen> createState() => _MonitoringScreenState();
}

class _MonitoringScreenState extends State<MonitoringScreen>
    with SingleTickerProviderStateMixin {
  late DateTime _startDate;
  late DateTime _endDate;

  String _selectedPlant = 'Cabai';
  String _selectedGlobalData = 'Global Data';

  final Set<String> _selectedSensors = {
    'moisture',
    'light',
    'water',
    'battery',
  };
  String _outputFormat = 'CSV';

  // Palette is now handled by AppColors in constants.dart

  int _currentPage = 1;
  final int _itemsPerPage = 10;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _endDate = DateTime.now();
    _startDate = _endDate.subtract(const Duration(days: 1));

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _selectDateRange() async {
    final pickedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      builder: (context, child) => child!,
    );
    if (pickedRange != null) {
      setState(() {
        _startDate = pickedRange.start;
        _endDate = pickedRange.end;
        _currentPage = 1;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SensorProvider>(context);
    final plantTypes = provider.plantTypes;
    if (plantTypes.isNotEmpty && !plantTypes.contains(_selectedPlant)) {
      // Gunakan addPostFrameCallback agar tidak memanggil setState saat build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && plantTypes.isNotEmpty && !plantTypes.contains(_selectedPlant)) {
          setState(() {
            _selectedPlant = plantTypes.first;
          });
        }
      });
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Modern Header
            SliverToBoxAdapter(child: _buildModernHeader()),

            // Plant & Data Selectors
            SliverToBoxAdapter(child: _buildSelectors(plantTypes, provider)),

            // Summary Cards
            SliverToBoxAdapter(child: _buildAnimatedSummaryCards(provider)),

            // Data Table
            SliverToBoxAdapter(child: _buildDataTableCard(provider)),

            // Export Section
            SliverToBoxAdapter(child: _buildExportSection(provider)),

            // Bottom Spacing
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }

  Widget _buildModernHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.accent.withOpacity(0.1),
                  AppColors.secondary.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.accent.withOpacity(0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.analytics_outlined,
                  size: 14,
                  color: AppColors.accent,
                ),
                const SizedBox(width: 6),
                Text(
                  "DATA INVENTORY",
                  style: TextStyle(
                    color: AppColors.accent,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "Monitoring Logs",
            style: TextStyle(
              color:
                  Theme.of(context).textTheme.headlineLarge?.color ??
                  AppColors.ink,
              fontSize: 32,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Track and export your sensor data",
            style: TextStyle(
              color: AppColors.inkSoft,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectors(List<String> plantTypes, SensorProvider provider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        children: [
          _buildModernDropdown(
            icon: Icons.spa_outlined,
            label: "Plant Type",
            value: toBeginningOfSentenceCase(_selectedPlant) ?? _selectedPlant,
            onTap: () => _showPlantSelector(plantTypes),
            gradient: [AppColors.primary, AppColors.primaryDark],
          ),
          const SizedBox(height: 12),
          _buildModernDropdown(
            icon: Icons.dashboard_outlined,
            label: "Data Source",
            value: _selectedGlobalData,
            onTap: () => _showBoxSelector(provider),
            gradient: [AppColors.secondary, AppColors.info],
          ),
        ],
      ),
    );
  }

  Widget _buildModernDropdown({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
    required List<Color> gradient,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.black26
                  : Colors.black.withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradient),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: AppColors.inkSoft,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      color:
                          Theme.of(context).textTheme.titleMedium?.color ??
                          AppColors.ink,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.inkSoft,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedSummaryCards(SensorProvider provider) {
    final ptKey = _selectedPlant.toLowerCase().replaceAll(' ', '_');
    int totalBoxes = 0;
    if (provider.unitsData.containsKey(ptKey)) {
      final plantData = provider.unitsData[ptKey];
      if (plantData is Map) {
        totalBoxes = plantData.length;
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: _StaggeredWidget(
              index: 0,
              child: _buildStatCard(
                icon: Icons.category_outlined,
                label: "CATEGORIES",
                value: provider.plantTypes.length.toString(),
                gradient: [AppColors.accent, AppColors.secondary],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _StaggeredWidget(
              index: 1,
              child: _buildStatCard(
                icon: Icons.inventory_2_outlined,
                label: "TOTAL BOXES",
                value: totalBoxes.toString(),
                gradient: [AppColors.secondary, AppColors.info],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required List<Color> gradient,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: gradient[0].withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 16),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataTableCard(SensorProvider provider) {
    final rawData = provider.getFilteredData(_startDate, _endDate);
    final plantKey = _selectedPlant.toLowerCase().replaceAll(' ', '_');

    List<Map<String, dynamic>> processedData = [];

    if (_selectedGlobalData == 'All Box Moisture') {
      // Tampilkan SEMUA box (hanya moisture)
      for (var data in rawData) {
        if (!data.rawData.containsKey(plantKey)) continue;
        final plantData = data.rawData[plantKey];
        if (plantData is Map) {
          plantData.forEach((boxId, boxValues) {
            if (boxValues is Map) {
              processedData.add({
                'timestamp': data.timestamp,
                'boxId': boxId.toString().toUpperCase(),
                'moisture': (boxValues['moisture'] ?? 0.0).toDouble(),
                // Field lain tidak diperlukan untuk mode ini
              });
            }
          });
        }
      }
    } else if (_selectedGlobalData == 'Global Data') {
      // Tampilkan data global (semua sensor)
      for (var data in rawData) {
        if (!data.rawData.containsKey(plantKey)) continue;
        processedData.add({
          'timestamp': data.timestamp,
          'moisture': data.getMoisture(_selectedPlant) ?? 0.0,
          'light': data.light,
          'water': data.water,
          'battery': data.battery,
        });
      }
    } else {
      // Box spesifik
      final boxKey = _selectedGlobalData.toLowerCase();
      for (var data in rawData) {
        if (!data.rawData.containsKey(plantKey)) continue;
        final plantData = data.rawData[plantKey];
        if (plantData is Map && plantData.containsKey(boxKey)) {
          final boxValues = plantData[boxKey];
          if (boxValues is Map) {
            processedData.add({
              'timestamp': data.timestamp,
              'boxId': boxKey.toUpperCase(),
              'moisture': (boxValues['moisture'] ?? 0.0).toDouble(),
              'light': (boxValues['light'] ?? data.light).toDouble(),
              'water': (boxValues['water'] ?? data.water).toDouble(),
              'battery': (boxValues['battery'] ?? data.battery).toDouble(),
            });
          }
        }
      }
    }

    final totalItems = processedData.length;
    final totalPages = (totalItems / _itemsPerPage).ceil().clamp(1, 9999);
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage).clamp(0, totalItems);
    final currentData = processedData.isNotEmpty
        ? processedData.sublist(startIndex, endIndex)
        : [];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Database Records",
                    style: TextStyle(
                      color:
                          Theme.of(context).textTheme.headlineSmall?.color ??
                          AppColors.ink,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Total: ${provider.history.where((d) => d.rawData.containsKey(_selectedPlant.toLowerCase())).length} records",
                    style: TextStyle(
                      color: AppColors.inkSoft,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.accent.withOpacity(0.1),
                      AppColors.secondary.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.table_chart_outlined,
                  color: AppColors.accent,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Date Range Selector
          GestureDetector(
            onTap: _selectDateRange,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.accent, AppColors.secondary],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accent.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.date_range_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${DateFormat('dd MMM').format(_startDate)} — ${DateFormat('dd MMM').format(_endDate)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Table
          if (currentData.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: 64,
                    color: AppColors.inkSoft.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "No records found in this date range",
                    style: TextStyle(
                      color: AppColors.inkSoft,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: DataTable(
                headingRowHeight: 48,
                dataRowHeight: 56,
                headingRowColor: MaterialStateProperty.all(
                  Theme.of(context).brightness == Brightness.dark
                      ? Colors.white.withOpacity(0.05)
                      : Color(0xFFF7FAFC),
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                ),
                columns: [
                  _buildDataColumn('Time', AppColors.inkSoft),
                  if (_selectedGlobalData != 'Global Data')
                    _buildDataColumn('Box', AppColors.secondary),
                  _buildDataColumn('Moisture', const Color(0xFF48BB78)),
                  if (_selectedGlobalData != 'All Box Moisture') ...[
                    _buildDataColumn('Light', const Color(0xFFED8936)),
                    _buildDataColumn('Water', const Color(0xFF4299E1)),
                    _buildDataColumn('Battery', const Color(0xFF667EEA)),
                  ],
                ],
                rows: currentData.asMap().entries.map((entry) {
                  final index = entry.key;
                  final data = entry.value;
                  return DataRow(
                    cells: [
                      DataCell(
                        _StaggeredWidget(
                          index: index,
                          delay: 100,
                          child: Text(
                            DateFormat(
                              'dd MMM\nHH:mm',
                            ).format(data['timestamp']),
                            style: const TextStyle(
                              color: AppColors.inkSoft,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ),
                      if (_selectedGlobalData != 'Global Data')
                        _buildDataCell(
                          data['boxId'] ?? '-',
                          AppColors.secondary,
                          index,
                        ),
                      _buildDataCell(
                        '${data['moisture'].toStringAsFixed(1)}%',
                        const Color(0xFF48BB78),
                        index,
                      ),
                      if (_selectedGlobalData != 'All Box Moisture') ...[
                        _buildDataCell(
                          '${(data['light'] ?? 0).toStringAsFixed(1)}%',
                          const Color(0xFFED8936),
                          index,
                        ),
                        _buildDataCell(
                          '${(data['water'] ?? 0).toStringAsFixed(1)}%',
                          const Color(0xFF4299E1),
                          index,
                        ),
                        _buildDataCell(
                          '${(data['battery'] ?? 0).toStringAsFixed(1)}%',
                          const Color(0xFF667EEA),
                          index,
                        ),
                      ],
                    ],
                  );
                }).toList(),
              ),
            ),

          const SizedBox(height: 24),
          Divider(color: Color(0xFFE2E8F0), height: 1),
          const SizedBox(height: 16),

          // Pagination
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "PAGE $_currentPage OF $totalPages",
                style: TextStyle(
                  color: AppColors.inkSoft,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              Row(
                children: [
                  _buildPaginationButton(
                    icon: Icons.chevron_left_rounded,
                    onTap: () {
                      if (_currentPage > 1) setState(() => _currentPage--);
                    },
                    enabled: _currentPage > 1,
                  ),
                  const SizedBox(width: 12),
                  _buildPaginationButton(
                    icon: Icons.chevron_right_rounded,
                    onTap: () {
                      if (_currentPage < totalPages)
                        setState(() => _currentPage++);
                    },
                    enabled: _currentPage < totalPages,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  DataColumn _buildDataColumn(String label, Color color) {
    return DataColumn(
      label: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  DataCell _buildDataCell(String value, Color color, int index) {
    return DataCell(
      _StaggeredWidget(
        index: index,
        delay: 100,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaginationButton({
    required IconData icon,
    required VoidCallback onTap,
    required bool enabled,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: enabled
              ? AppColors.accent.withOpacity(0.1)
              : Color(0xFFF7FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: enabled
                ? AppColors.accent.withOpacity(0.2)
                : Color(0xFFE2E8F0),
          ),
        ),
        child: Icon(
          icon,
          color: enabled
              ? AppColors.accent
              : AppColors.inkSoft.withOpacity(0.3),
          size: 20,
        ),
      ),
    );
  }

  Widget _buildExportSection(SensorProvider provider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: Theme.of(context).brightness == Brightness.dark
              ? [Color(0xFF1E293B), Color(0xFF0F172A)]
              : [Color(0xFFF7FAFC), Color(0xFFFFFFFF)],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white10
              : Color(0xFFE2E8F0),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, Color(0xFF38A169)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.cloud_download_outlined,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Export Archive",
                    style: TextStyle(
                      color:
                          Theme.of(context).textTheme.titleLarge?.color ??
                          AppColors.ink,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    "Download your sensor data",
                    style: TextStyle(
                      color: AppColors.inkSoft,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),

          // STEP 1: Date Range
          _buildStepLabel("1", "SELECT DATE RANGE", AppColors.accent),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _selectDateRange,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.accent.withOpacity(0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accent.withOpacity(0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    color: AppColors.accent,
                    size: 18,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${DateFormat('dd MMM').format(_startDate)} — ${DateFormat('dd MMM').format(_endDate)}',
                    style: TextStyle(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),

          // STEP 2: Select Sensors
          _buildStepLabel("2", "SELECT SENSORS TO EXPORT", AppColors.secondary),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildModernSensorCheckbox(
                "Moisture",
                "moisture",
                Icons.water_drop_outlined,
                Color(0xFF48BB78),
              ),
              _buildModernSensorCheckbox(
                "Light",
                "light",
                Icons.wb_sunny_outlined,
                Color(0xFFED8936),
              ),
              _buildModernSensorCheckbox(
                "Water",
                "water",
                Icons.waves_rounded,
                Color(0xFF4299E1),
              ),
              _buildModernSensorCheckbox(
                "Battery",
                "battery",
                Icons.battery_charging_full_rounded,
                Color(0xFF667EEA),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // STEP 3: Output Format
          _buildStepLabel("3", "CHOOSE OUTPUT FORMAT", AppColors.orange),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildFormatButton('CSV', Icons.table_rows_outlined),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFormatButton('XLSX', Icons.grid_on_outlined),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Download Button
          GestureDetector(
            onTap: () => _handleExport(provider),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, Color(0xFF38A169)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.download_rounded, color: Colors.white, size: 22),
                  SizedBox(width: 10),
                  Text(
                    "Download Archive",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepLabel(String number, String label, Color color) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [color, color.withOpacity(0.8)]),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }

  Widget _buildModernSensorCheckbox(
    String label,
    String key,
    IconData icon,
    Color color,
  ) {
    final isSelected = _selectedSensors.contains(key);
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedSensors.remove(key);
          } else {
            _selectedSensors.add(key);
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(colors: [color, color.withOpacity(0.8)])
              : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? Colors.transparent : Color(0xFFE2E8F0),
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isSelected ? Colors.white : color, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.ink,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              color: isSelected ? Colors.white : AppColors.inkSoft,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormatButton(String format, IconData icon) {
    final isSelected = _outputFormat == format;
    return GestureDetector(
      onTap: () => setState(() => _outputFormat = format),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(colors: [AppColors.orange, Color(0xFFDD6B20)])
              : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? Colors.transparent : Color(0xFFE2E8F0),
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.orange.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : AppColors.inkSoft,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              format,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.ink,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleExport(SensorProvider provider) {
    final filteredData = provider.getFilteredData(_startDate, _endDate);

    if (filteredData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No data available to export'),
          backgroundColor: AppColors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    try {
      if (_outputFormat == 'CSV') {
        provider.exportToCSV(
          filteredData,
          plantType: _selectedPlant,
          selectedSensors: _selectedSensors,
          startDate: _startDate,
          endDate: _endDate,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Successfully exported as CSV'),
              ],
            ),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      } else {
        provider.exportToXLSX(
          filteredData,
          plantType: _selectedPlant,
          selectedSensors: _selectedSensors,
          startDate: _startDate,
          endDate: _endDate,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Successfully exported as XLSX'),
              ],
            ),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export failed: $e'),
          backgroundColor: Colors.red[400],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  void _showPlantSelector(List<String> plantTypes) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.primary, Color(0xFF38A169)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.spa_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      "Select Plant Type",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (plantTypes.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
                  child: Text(
                    "No plant data available.",
                    style: TextStyle(color: AppColors.inkSoft),
                  ),
                )
              else
                ...plantTypes.map((plant) {
                  final isSelected = _selectedPlant == plant;
                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedPlant = plant;
                        _currentPage = 1;
                      });
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withOpacity(0.1)
                            : Colors.transparent,
                        border: Border(
                          left: BorderSide(
                            color: isSelected
                                ? AppColors.primary
                                : Colors.transparent,
                            width: 4,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            _getPlantEmoji(plant),
                            style: const TextStyle(fontSize: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              toBeginningOfSentenceCase(plant) ?? plant,
                              style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.ink,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              Icons.check_circle,
                              color: AppColors.primary,
                              size: 24,
                            ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
            ],
          ),
        );
      },
    );
  }

  void _showBoxSelector(SensorProvider provider) {
    final plantKey = _selectedPlant.toLowerCase().replaceAll(' ', '_');
    List<String> options = ["Global Data", "All Box Moisture"];

    if (provider.unitsData.containsKey(plantKey)) {
      final plantData = provider.unitsData[plantKey];
      if (plantData is Map) {
        options.addAll(plantData.keys.map((k) => k.toString().toUpperCase()));
      }
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.secondary, AppColors.info],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.inventory_2_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      "Select Data Source",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ...options.map((option) {
                final isSelected = _selectedGlobalData == option;
                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedGlobalData = option;
                      _currentPage = 1;
                    });
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.info.withOpacity(0.1)
                          : Colors.transparent,
                      border: Border(
                        left: BorderSide(
                          color: isSelected
                              ? AppColors.info
                              : Colors.transparent,
                          width: 4,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          option == "All Boxes"
                              ? Icons.dashboard_rounded
                              : Icons.inventory_2_rounded,
                          size: 18,
                          color: isSelected
                              ? AppColors.info
                              : AppColors.inkSoft,
                        ),
                        const SizedBox(width: 16),
                        Text(
                          option,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: isSelected
                                ? FontWeight.w800
                                : FontWeight.w600,
                            color: isSelected ? AppColors.info : AppColors.ink,
                          ),
                        ),
                        if (isSelected) ...[
                          const Spacer(),
                          const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.info,
                            size: 20,
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  String _getPlantEmoji(String plantType) {
    switch (plantType.toLowerCase()) {
      case 'cabai':
        return '🌶️';
      case 'tomat':
        return '🍅';
      case 'selada':
        return '🥬';
      default:
        return '🌱';
    }
  }
}

class _StaggeredWidget extends StatefulWidget {
  final Widget child;
  final int index;
  final int delay;

  const _StaggeredWidget({
    required this.child,
    required this.index,
    this.delay = 0,
  });

  @override
  State<_StaggeredWidget> createState() => _StaggeredWidgetState();
}

class _StaggeredWidgetState extends State<_StaggeredWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    Future.delayed(
      Duration(milliseconds: widget.delay + (widget.index * 100)),
      () {
        if (mounted) _controller.forward();
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}
