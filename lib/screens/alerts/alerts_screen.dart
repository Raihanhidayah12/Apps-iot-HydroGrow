import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../models/sensor_model.dart';
import '../../providers/sensor_provider.dart';
import '../../services/firebase_service.dart';

// ─── Design Tokens (Standardized with AppColors) ────────────────────────────────
class _T {
  static Color getBg(BuildContext context) =>
      Theme.of(context).scaffoldBackgroundColor;
  static Color getCardBg(BuildContext context) =>
      Theme.of(context).colorScheme.surface;
  static Color getInk(BuildContext context) =>
      Theme.of(context).textTheme.bodyLarge?.color ?? AppColors.ink;
  static Color getInkSoft(BuildContext context) =>
      Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7) ??
      AppColors.inkSoft;

  static const emerald = AppColors.primary;
  static const emeraldDark = AppColors.primaryDark;
  static const emeraldLight = AppColors.primaryLight;
  static const stroke = AppColors.stroke;

  static const r24 = BorderRadius.all(Radius.circular(24));
  static const r20 = BorderRadius.all(Radius.circular(20));
  static const r16 = BorderRadius.all(Radius.circular(16));
  static const r12 = BorderRadius.all(Radius.circular(12));

  static List<BoxShadow> cardShadow(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return [
      BoxShadow(
        color: isDark ? Colors.black26 : AppColors.ink.withOpacity(0.04),
        blurRadius: 20,
        offset: const Offset(0, 8),
      ),
    ];
  }

  static TextStyle titleStyle(BuildContext context) => TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.w900,
    color: getInk(context),
    letterSpacing: -1.0,
  );

  static TextStyle sectionTitle(BuildContext context) => TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w800,
    color: getInk(context),
  );

  static const labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w800,
    letterSpacing: 1.5,
    color: emeraldDark,
  );
}

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseService _firebaseService = FirebaseService();
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();
  int _selectedFilterDays = 7;
  int _currentPage = 1;
  final int _itemsPerPage = 10;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));

    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _setFilterDays(int days) {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedFilterDays = days;
      _endDate = DateTime.now();
      _startDate = DateTime.now().subtract(Duration(days: days));
      _currentPage = 1;
    });
  }

  Future<void> _pickDateRange() async {
    HapticFeedback.selectionClick();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      builder: (context, child) => child!,
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
        _selectedFilterDays = 0; // Custom
        _currentPage = 1;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _T.getBg(context),
      body: Consumer<SensorProvider>(
        builder: (context, provider, child) {
          final history = provider.getFilteredData(_startDate, _endDate);

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildModernHeader(),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    FadeTransition(
                      opacity: _fadeAnim,
                      child: SlideTransition(
                        position: _slideAnim,
                        child: _buildActivityHistorySection(history),
                      ),
                    ),
                    const SizedBox(height: 24),
                    FadeTransition(
                      opacity: _fadeAnim,
                      child: SlideTransition(
                        position: _slideAnim,
                        child: _buildConfigurationSection(provider),
                      ),
                    ),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildModernHeader() {
    return SliverToBoxAdapter(
      child: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("SECURITY & ANALYTICS", style: _T.labelSmall),
                const SizedBox(height: 8),
                Text("System Alerts", style: _T.titleStyle(context)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActivityHistorySection(List<SensorData> history) {
    final startStr = DateFormat('dd MMM').format(_startDate).toUpperCase();
    final endStr = DateFormat('dd MMM').format(_endDate).toUpperCase();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Activity History", style: _T.sectionTitle(context)),
            Row(
              children: [
                _buildQuickFilter(3, "3 Days"),
                const SizedBox(width: 8),
                _buildQuickFilter(7, "7 Days"),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: _pickDateRange,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _T.getCardBg(context),
              borderRadius: _T.r16,
              boxShadow: _T.cardShadow(context),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.history_toggle_off_rounded,
                  color: _T.emerald,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  "$startStr  —  $endStr",
                  style: TextStyle(
                    color: _T.getInk(context),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        _buildHistoryDataTable(history),
      ],
    );
  }

  Widget _buildHistoryDataTable(List<SensorData> history) {
    if (history.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: _T.getCardBg(context).withOpacity(0.5),
          borderRadius: _T.r24,
          border: Border.all(
            color: Theme.of(context).dividerColor.withOpacity(0.1),
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Text(
              "No history records found in this range.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _T.getInkSoft(context),
                fontSize: 13,
                fontWeight: FontWeight.w500,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      );
    }

    final totalItems = history.length;
    final totalPages = (totalItems / _itemsPerPage).ceil().clamp(1, 9999);
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage).clamp(0, totalItems);
    final currentData = history.sublist(startIndex, endIndex);

    return Container(
      decoration: BoxDecoration(
        color: _T.getCardBg(context),
        borderRadius: _T.r24,
        boxShadow: _T.cardShadow(context),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: DataTable(
              headingRowHeight: 48,
              dataRowHeight: 56,
              horizontalMargin: 12,
              columnSpacing: 16,
              headingRowColor: MaterialStateProperty.all(
                Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withOpacity(0.05)
                    : AppColors.background,
              ),
              columns: const [
                DataColumn(
                  label: Text(
                    "Time",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
                DataColumn(
                  label: Text(
                    "Plant",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
                DataColumn(
                  label: Text(
                    "Box",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
                DataColumn(
                  label: Text(
                    "Soil",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    "Light",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      color: AppColors.orange,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    "Water",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      color: AppColors.info,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    "Batt",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      color: AppColors.accent,
                    ),
                  ),
                ),
              ],
              rows: currentData.map((data) {
                // Find first available plant and box
                String plant = "-";
                String box = "-";
                double moisture = 0.0;

                if (data.rawData.isNotEmpty) {
                  for (var key in data.rawData.keys) {
                    if (data.rawData[key] is Map &&
                        key != "battery" &&
                        key != "light" &&
                        key != "water" &&
                        key != "timestamp") {
                      plant = key.toString().toUpperCase();
                      final plantMap = data.rawData[key] as Map;
                      if (plantMap.keys.isNotEmpty) {
                        box = plantMap.keys.first
                            .toString()
                            .toUpperCase()
                            .replaceAll('_', ' ');
                        final boxData = plantMap[plantMap.keys.first];
                        if (boxData is Map && boxData.containsKey('moisture')) {
                          moisture = (boxData['moisture'] ?? 0).toDouble();
                        }
                      }
                      break;
                    }
                  }
                }

                return DataRow(
                  cells: [
                    DataCell(
                      _StaggeredWidget(
                        index: currentData.indexOf(data),
                        delay: 50,
                        child: Text(
                          DateFormat('HH:mm').format(data.timestamp),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      _StaggeredWidget(
                        index: currentData.indexOf(data),
                        delay: 100,
                        child: Text(
                          plant,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.inkSoft,
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      _StaggeredWidget(
                        index: currentData.indexOf(data),
                        delay: 150,
                        child: Text(
                          box,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.inkSoft,
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      _StaggeredWidget(
                        index: currentData.indexOf(data),
                        delay: 200,
                        child: Text(
                          "${moisture.toStringAsFixed(0)}%",
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      _StaggeredWidget(
                        index: currentData.indexOf(data),
                        delay: 250,
                        child: Text(
                          "${data.light.toStringAsFixed(0)}%",
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      _StaggeredWidget(
                        index: currentData.indexOf(data),
                        delay: 300,
                        child: Text(
                          "${data.water.toStringAsFixed(0)}%",
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.info,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      _StaggeredWidget(
                        index: currentData.indexOf(data),
                        delay: 350,
                        child: Text(
                          "${data.battery.toStringAsFixed(0)}%",
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.accent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "PAGE $_currentPage OF $totalPages",
                style: TextStyle(
                  color: _T.getInkSoft(context),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded),
                    onPressed: _currentPage > 1
                        ? () => setState(() => _currentPage--)
                        : null,
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded),
                    onPressed: _currentPage < totalPages
                        ? () => setState(() => _currentPage++)
                        : null,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickFilter(int days, String label) {
    final isSelected = _selectedFilterDays == days;
    return GestureDetector(
      onTap: () => _setFilterDays(days),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? _T.getCardBg(context) : Colors.transparent,
          borderRadius: _T.r12,
          boxShadow: isSelected ? _T.cardShadow(context) : null,
          border: Border.all(
            color: isSelected ? Colors.transparent : _T.stroke,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? _T.emerald : _T.getInkSoft(context),
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildConfigurationSection(SensorProvider provider) {
    final config = provider.thresholdConfig;
    if (config == null) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _T.getCardBg(context),
        borderRadius: _T.r24,
        boxShadow: _T.cardShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.primary
                          : AppColors.ink,
                      borderRadius: _T.r12,
                    ),
                    child: const Icon(
                      Icons.tune_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    "Configuration",
                    style: _T.sectionTitle(context).copyWith(fontSize: 18),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          _buildThresholdSlider(
            label: "MIN. WATER STORAGE",
            value: config.waterMin.toDouble(),
            onChanged: (val) {
              provider.updateThresholdConfig(
                config.copyWith(waterMin: val.toInt()),
              );
            },
            color: AppColors.info,
          ),
          const SizedBox(height: 24),
          _buildThresholdSlider(
            label: "MIN. BATTERY HEALTH",
            value: config.batteryMin.toDouble(),
            onChanged: (val) {
              provider.updateThresholdConfig(
                config.copyWith(batteryMin: val.toInt()),
              );
            },
            color: AppColors.primary,
          ),
          const SizedBox(height: 32),
          _buildNotificationToggle(provider),
        ],
      ),
    );
  }

  Widget _buildThresholdSlider({
    required String label,
    required double value,
    required ValueChanged<double> onChanged,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                color: _T.getInkSoft(context),
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
            Text(
              "${value.toInt()}%",
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
            activeTrackColor: color.withOpacity(0.3),
            inactiveTrackColor: Theme.of(context).dividerColor.withOpacity(0.1),
            thumbColor: color,
          ),
          child: Slider(
            value: value,
            min: 0,
            max: 100,
            onChanged: (val) {
              HapticFeedback.selectionClick();
              onChanged(val);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationToggle(SensorProvider provider) {
    final isActive = provider.telegramConfig?.isActive ?? false;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.white.withOpacity(0.05)
            : AppColors.ink,
        borderRadius: _T.r16,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Push Notifications",
                  style: TextStyle(
                    color: _T.emerald,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  "Via Telegram Bot (${isActive ? 'Active' : 'Inactive'})",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: isActive,
            onChanged: (val) {
              HapticFeedback.mediumImpact();
              if (provider.telegramConfig != null) {
                provider.updateTelegramConfig(
                  provider.telegramConfig!.copyWith(isActive: val),
                );
              }
            },
            activeColor: Colors.white,
            activeTrackColor: _T.emerald,
          ),
        ],
      ),
    );
  }
}

class _StaggeredWidget extends StatefulWidget {
  final Widget child;
  final int index;
  final int delay;

  const _StaggeredWidget({
    required this.child,
    required this.index,
    this.delay = 100,
  });

  @override
  State<_StaggeredWidget> createState() => _StaggeredWidgetState();
}

class _StaggeredWidgetState extends State<_StaggeredWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    Future.delayed(Duration(milliseconds: widget.index * widget.delay), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(position: _slideAnimation, child: widget.child),
    );
  }
}
