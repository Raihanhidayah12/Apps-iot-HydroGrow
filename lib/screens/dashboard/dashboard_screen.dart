import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../../core/constants.dart';
import '../../providers/sensor_provider.dart';

import '../../models/sensor_model.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  String _currentTime = "";
  String _selectedPlantType = "cabai"; // Default plant type
  late final AnimationController _appearanceController;
  late final AnimationController _chartController;
  Timer? _clockTimer;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 1));
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _updateTime();
    _appearanceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();

    _chartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..forward();
  }

  Future<void> _showDateRangePicker() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      firstDate: DateTime(2023),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      builder: (context, child) {
        return child!;
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      // Optionally trigger data refresh if needed
    }
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _appearanceController.dispose();
    _chartController.dispose();
    super.dispose();
  }

  void _updateTime() {
    _currentTime = DateFormat(
      'HH:mm:ss',
    ).format(DateTime.now().toUtc().add(const Duration(hours: 7)));
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _currentTime = DateFormat(
          'HH:mm:ss',
        ).format(DateTime.now().toUtc().add(const Duration(hours: 7)));
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Consumer<SensorProvider>(
          builder: (context, provider, child) {
            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Custom App Bar
                SliverToBoxAdapter(child: _buildModernHeader()),

                // Plant Type Selector
                SliverToBoxAdapter(child: _buildPlantTypeSelector(provider)),

                // Sensor Cards Grid
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1.4,
                        ),
                    delegate: SliverChildListDelegate([
                      _animatedCard(
                        _buildModernSensorCard(
                          label: 'Soil Moisture',
                          value: provider.getMoistureForPlant(
                            _selectedPlantType,
                          ),
                          unit: '%',
                          icon: Icons.water_drop_rounded,
                          gradientColors: [
                            AppColors.secondary.withOpacity(0.6),
                            AppColors.secondary,
                          ],
                          iconBg: AppColors.secondary.withOpacity(0.1),
                        ),
                        index: 0,
                      ),
                      _animatedCard(
                        _buildModernSensorCard(
                          label: 'Light Intensity',
                          value: provider.liveSensor?.light ?? 0,
                          unit: '%',
                          icon: Icons.wb_sunny_rounded,
                          gradientColors: [
                            AppColors.orange.withOpacity(0.7),
                            AppColors.orange,
                          ],
                          iconBg: AppColors.orange.withOpacity(0.1),
                        ),
                        index: 1,
                      ),
                      _animatedCard(
                        _buildModernSensorCard(
                          label: 'Water Level',
                          value: _getFilteredSensorValue(provider, 'water'),
                          unit: '%',
                          icon: Icons.waves_rounded,
                          gradientColors: [
                            AppColors.info.withOpacity(0.6),
                            AppColors.info,
                          ],
                          iconBg: AppColors.info.withOpacity(0.1),
                        ),
                        index: 2,
                      ),
                      _animatedCard(
                        _buildModernSensorCard(
                          label: 'Battery Health',
                          value: provider.liveSensor?.battery ?? 0,
                          unit: '%',
                          icon: Icons.battery_charging_full_rounded,
                          gradientColors: [
                            AppColors.emerald.withOpacity(0.7),
                            AppColors.emerald,
                          ],
                          iconBg: AppColors.emerald.withOpacity(0.1),
                          subtitle: 'Solar Active',
                        ),
                        index: 3,
                      ),
                    ]),
                  ),
                ),

                // Analytics Chart
                SliverToBoxAdapter(child: _buildAnalyticsChart(provider)),

                // System Status
                SliverToBoxAdapter(child: _buildSystemStatus(provider)),

                // Bottom Spacing
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildModernHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black26
                : AppColors.inkSoft.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
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
                    "HydroGrow",
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      color:
                          Theme.of(context).textTheme.headlineLarge?.color ??
                          AppColors.ink,
                      letterSpacing: -1.0,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.4),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "LIVE MONITORING",
                        style: TextStyle(
                          color: AppColors.inkSoft,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [AppColors.primary, AppColors.primaryDark]
                        : [AppColors.ink, Color(0xFF334155)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.ink.withOpacity(0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  _currentTime,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    fontFamily: 'monospace',
                    color: Colors.white,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlantTypeSelector(SensorProvider provider) {
    final plantTypes = provider.plantTypes;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Select Plant",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color:
                  Theme.of(context).textTheme.titleMedium?.color ??
                  AppColors.ink,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            clipBehavior: Clip.none,
            child: Row(
              children: plantTypes.map((plantType) {
                final isSelected = _selectedPlantType == plantType;
                return GestureDetector(
                  onTap: () {
                    if (_selectedPlantType == plantType) return;
                    setState(() {
                      _selectedPlantType = plantType;
                      _chartController.forward(from: 0.0);
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOutCubic,
                    margin: const EdgeInsets.only(right: 16),
                    padding: EdgeInsets.symmetric(
                      horizontal: isSelected ? 24 : 20,
                      vertical: isSelected ? 16 : 14,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (isDark ? AppColors.primary : AppColors.ink)
                          : Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? Colors.transparent
                            : (isDark
                                  ? AppColors.strokeDark
                                  : AppColors.stroke),
                        width: 1.5,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppColors.ink.withOpacity(0.3),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              ),
                            ]
                          : [
                              BoxShadow(
                                color: AppColors.inkSoft.withOpacity(0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                    ),
                    child: Row(
                      children: [
                        AnimatedScale(
                          scale: isSelected ? 1.2 : 1.0,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutBack,
                          child: Text(
                            _getPlantEmoji(plantType),
                            style: TextStyle(fontSize: 20),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          plantType.toUpperCase(),
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : AppColors.inkSoft,
                            fontWeight: isSelected
                                ? FontWeight.w800
                                : FontWeight.w700,
                            fontSize: 13,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
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

  double _getFilteredSensorValue(SensorProvider provider, String type) {
    // Get latest sensor data for selected plant type (case-insensitive)
    final filteredData = provider.getFilteredByPlant(_selectedPlantType);

    if (filteredData.isNotEmpty) {
      // History sudah diurutkan terbaru di atas, gunakan .first bukan .last
      final latestData = filteredData.first;
      switch (type) {
        case 'moisture':
          return latestData.moisture;
        case 'water':
          return latestData.water;
        default:
          return 0;
      }
    }

    // Fallback: use latest overall history or liveSensor
    if (provider.history.isNotEmpty) {
      final latestOverall = provider.history.first;
      switch (type) {
        case 'moisture':
          return latestOverall.moisture;
        case 'water':
          return latestOverall.water;
        default:
          return 0;
      }
    }

    return 0;
  }

  Widget _buildModernSensorCard({
    required String label,
    required double value,
    required String unit,
    required IconData icon,
    required List<Color> gradientColors,
    required Color iconBg,
    String? subtitle,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white10 : Color(0xFFF1F5F9),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black12
                : AppColors.inkSoft.withOpacity(0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: gradientColors[1], size: 24),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: gradientColors),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: value),
                    duration: const Duration(milliseconds: 1500),
                    curve: Curves.easeOutCubic,
                    builder: (context, animValue, child) {
                      return Text(
                        '${animValue.toInt()}$unit',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF718096),
                    letterSpacing: 0.3,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: Color(0xFF4CAF50),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF4CAF50),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsChart(SensorProvider provider) {
    // Filter using provider (now correctly supports date range)
    final chartData = provider.getFilteredByPlant(
      _selectedPlantType,
      startDate: _startDate,
      endDate: _endDate,
    );

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white10 : Color(0xFFF1F5F9),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black12
                : AppColors.inkSoft.withOpacity(0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
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
                    "System Analytics",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color:
                          Theme.of(context).textTheme.headlineMedium?.color ??
                          Color(0xFF1A202C),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "TIME-BASED TREND",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFA0AEC0),
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              // Functional Date Range Indicator
              GestureDetector(
                onTap: _showDateRangePicker,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? Colors.white10 : Color(0xFFEDF2F7),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        color: AppColors.primary,
                        size: 18,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        DateFormat('dd MMM').format(_startDate).toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? AppColors.inkMidDark
                              : Color(0xFF4A5568),
                          letterSpacing: 0.5,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          "-",
                          style: TextStyle(
                            color: isDark ? Colors.white24 : Color(0xFFCBD5E0),
                          ),
                        ),
                      ),
                      Text(
                        DateFormat('dd MMM').format(_endDate).toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? AppColors.inkMidDark
                              : Color(0xFF4A5568),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 250,
            child: FadeTransition(
              opacity: _chartController,
              child: LineChart(_buildChartData(chartData)),
            ),
          ),
          if (chartData.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Center(
                child: Text(
                  'No records found in this range',
                  style: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 20),
          _buildModernLegend(),
        ],
      ),
    );
  }

  LineChartData _buildChartData(List<SensorData> chartData) {
    // Aggregation: Group data by hour (0-23) to show a single 24-hour trend
    // regardless of how many days are selected. This avoids "double" labels.
    final Map<int, List<SensorData>> hourlyGroups = {};
    for (var data in chartData) {
      final hour = data.timestamp.hour;
      hourlyGroups.putIfAbsent(hour, () => []).add(data);
    }

    // Create averaged data points for each hour
    final List<SensorData> aggregatedData = [];
    for (int i = 0; i < 24; i++) {
      if (hourlyGroups.containsKey(i)) {
        final group = hourlyGroups[i]!;
        final avgMoisture =
            group
                .map((e) => e.getMoisture(_selectedPlantType) ?? 0)
                .reduce((a, b) => a + b) /
            group.length;
        final avgLight =
            group.map((e) => e.light).reduce((a, b) => a + b) / group.length;
        final avgWater =
            group.map((e) => e.water).reduce((a, b) => a + b) / group.length;
        final avgBattery =
            group.map((e) => e.battery).reduce((a, b) => a + b) / group.length;

        aggregatedData.add(
          SensorData(
            moisture: avgMoisture,
            light: avgLight,
            water: avgWater,
            battery: avgBattery,
            time:
                "2026-01-01 ${i.toString().padLeft(2, '0')}:00:00", // Dummy date for the getter
            plantType: _selectedPlantType,
          ),
        );
      }
    }

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        horizontalInterval: 25,
        verticalInterval: 3, // 3 hours
        getDrawingHorizontalLine: (value) =>
            FlLine(color: Color(0xFFE2E8F0).withOpacity(0.4), strokeWidth: 1),
        getDrawingVerticalLine: (value) =>
            FlLine(color: Color(0xFFE2E8F0).withOpacity(0.4), strokeWidth: 1),
      ),
      titlesData: FlTitlesData(
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 42,
            interval: 25,
            getTitlesWidget: (value, meta) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                "${value.toInt()}",
                style: TextStyle(
                  color: AppColors.inkLighter,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 32,
            interval: 3,
            getTitlesWidget: (value, meta) {
              final hour = value.round();
              // Only show hours matching your list: 0, 6, 9, 12, 15, 18, 21
              final allowedHours = [0, 6, 9, 12, 15, 18, 21];
              if (!allowedHours.contains(hour)) return const SizedBox.shrink();

              final timeStr = "${hour.toString().padLeft(2, '0')}.00";

              return Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  timeStr,
                  style: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: Color(0xFFE2E8F0).withOpacity(0.5), width: 1),
      ),
      minX: 0,
      maxX: 23,
      minY: 0,
      maxY: 100,
      lineBarsData: [
        _generateLineData(aggregatedData, (d) => d.moisture, Color(0xFF4FC3F7)),
        _generateLineData(aggregatedData, (d) => d.light, Color(0xFFFFB74D)),
        _generateLineData(aggregatedData, (d) => d.water, Color(0xFF64B5F6)),
        _generateLineData(aggregatedData, (d) => d.battery, Color(0xFF66BB6A)),
      ],
      lineTouchData: LineTouchData(
        enabled: true,
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (touchedSpot) => AppColors.ink.withOpacity(0.9),
          tooltipMargin: 8,
          tooltipRoundedRadius: 12,
          tooltipPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((spot) {
              final hour = spot.x.toInt();
              final timeStr = "${hour.toString().padLeft(2, '0')}:00";

              String label;
              Color color;
              switch (spot.barIndex) {
                case 0:
                  label = 'Moisture';
                  color = Color(0xFF38BDF8);
                  break;
                case 1:
                  label = 'Light';
                  color = Color(0xFFFBBF24);
                  break;
                case 2:
                  label = 'Water';
                  color = Color(0xFF60A5FA);
                  break;
                case 3:
                  label = 'Battery';
                  color = Color(0xFF34D399);
                  break;
                default:
                  label = 'Unknown';
                  color = Colors.white;
              }

              return LineTooltipItem(
                '$label: ${spot.y.toInt()}%\\n$timeStr',
                TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              );
            }).toList();
          },
        ),
      ),
    );
  }

  LineChartBarData _generateLineData(
    List<SensorData> data,
    double? Function(SensorData) getValue,
    Color color,
  ) {
    return LineChartBarData(
      spots: data.map((d) {
        final val = getValue(d);
        final hour = d.timestamp.hour;
        return val != null ? FlSpot(hour.toDouble(), val) : FlSpot.nullSpot;
      }).toList(),
      isCurved: true,
      curveSmoothness: 0.15, // Less aggressive curve for many points
      color: color,
      barWidth: 2.5,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: false), // Hide dots to avoid mess
      belowBarData: BarAreaData(
        show: true,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withOpacity(0.15), color.withOpacity(0.01)],
        ),
      ),
    );
  }

  Widget _buildModernLegend() {
    return Wrap(
      spacing: 16,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: [
        _legendItem("Moisture", Color(0xFF4FC3F7)),
        _legendItem("Light", Color(0xFFFFB74D)),
        _legendItem("Water", Color(0xFF64B5F6)),
        _legendItem("Battery", Color(0xFF66BB6A)),
      ],
    );
  }

  Widget _legendItem(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white12
              : AppColors.stroke,
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF4A5568),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemStatus(SensorProvider provider) {
    final waterLevel = _getFilteredSensorValue(provider, 'water');
    final isWarning = waterLevel < 10;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isWarning
              ? [Color(0xFFFEF2F2), Color(0xFFFEE2E2)]
              : [Color(0xFFF8FAFC), Color(0xFFF1F5F9)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isWarning ? Color(0xFFFECACA) : AppColors.stroke,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (isWarning ? Color(0xFFEF4444) : AppColors.inkSoft)
                .withOpacity(0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(isWarning ? 0.9 : 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isWarning
                  ? Icons.warning_amber_rounded
                  : Icons.check_circle_rounded,
              color: isWarning ? Color(0xFFDC2626) : AppColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isWarning ? "SYSTEM ALERT" : "SYSTEM STATUS",
                  style: TextStyle(
                    color: isWarning ? Color(0xFF991B1B) : AppColors.inkSoft,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isWarning
                      ? "Critical Water Level Detected!"
                      : "All systems operating normally",
                  style: TextStyle(
                    color: isWarning ? Color(0xFF7F1D1D) : AppColors.ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _animatedCard(Widget child, {required int index}) {
    return _StaggeredWidget(index: index, delay: 200, child: child);
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
      Duration(milliseconds: widget.delay + (widget.index * 120)),
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
      child: SlideTransition(
        position: _slide,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.95, end: 1.0).animate(
            CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
