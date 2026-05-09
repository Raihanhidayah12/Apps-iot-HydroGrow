// lib/screens/schedule/schedule_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:convert';

import '../../core/constants.dart';
import '../../models/schedule_model.dart';
import '../../services/firebase_service.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';

// =============================================================================
// DATA MODEL UNTUK KATEGORI (TIDAK DIUBAH)
// =============================================================================
class PlantCategory {
  final String id;
  final String label;

  PlantCategory({required this.id, required this.label});

  factory PlantCategory.fromMap(String id, Map<dynamic, dynamic> data) {
    return PlantCategory(id: id, label: data['label'] as String? ?? 'Unknown');
  }
}

// =============================================================================
// DESIGN TOKENS — BOTANICAL PRECISION THEME
// Cream base · Emerald accents · Layered shadows · Organic warmth
// =============================================================================
class _T {
  static Color getEmerald(BuildContext context) => AppColors.primary;
  static Color getBg(BuildContext context) =>
      Theme.of(context).scaffoldBackgroundColor;
  static Color getCard(BuildContext context) =>
      Theme.of(context).colorScheme.surface;
  static Color getInk(BuildContext context) =>
      Theme.of(context).textTheme.bodyLarge?.color ?? AppColors.ink;
  static Color getInkMid(BuildContext context) =>
      Theme.of(context).textTheme.bodyMedium?.color ?? AppColors.inkMid;
  static Color getInkSoft(BuildContext context) =>
      Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7) ??
      AppColors.inkSoft;
  static Color getStroke(BuildContext context) =>
      Theme.of(context).dividerColor.withOpacity(0.1);
  static Color getCardTinted(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? Colors.white.withOpacity(0.02)
      : const Color(0xFFFBFDFA);
  static const Color amber = Color(0xFFD97706);
  static const Color amberDim = Color(0x1AD97706);

  static List<BoxShadow> cardShadow(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return [
      BoxShadow(
        color: isDark ? Colors.black26 : AppColors.ink.withOpacity(0.04),
        blurRadius: 20,
        offset: const Offset(0, 4),
      ),
    ];
  }

  static List<BoxShadow> elevatedShadow(BuildContext context) {
    return [
      BoxShadow(
        color: AppColors.primary.withOpacity(0.18),
        blurRadius: 24,
        offset: const Offset(0, 8),
      ),
    ];
  }
}

// =============================================================================
// SCHEDULE SCREEN
// =============================================================================
class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen>
    with TickerProviderStateMixin {
  // ── All original state (UNCHANGED) ────────────────────────────────────────
  final FirebaseService _firebaseService = FirebaseService();
  late StreamSubscription<DatabaseEvent> _pumpSub;
  late StreamSubscription<DatabaseEvent> _plantTypesSub;
  StreamSubscription<DatabaseEvent>? _scheduleSub;
  Timer? _scheduleCheckTimer;
  String _timerSource = 'none';
  Timer? _countdownTimer;
  Timer? _clockTimer;
  String _currentTime = "";
  List<ScheduleModel> _schedules = [];
  int _activeTimer = 0;
  bool _pumpIsActive = false;
  int _selectedDay = DateTime.now().weekday % 7;
  Map<String, dynamic>? _weatherData;

  List<PlantCategory> _categories = [];
  int _selectedCategoryIndex = 0;

  // ── Animation controllers ──────────────────────────────────────────────────
  late AnimationController _pulseCtrl;
  late AnimationController _fadeCtrl;
  late Animation<double> _pulseAnim;
  late Animation<double> _fadeAnim;

  // ── Original getters (UNCHANGED) ──────────────────────────────────────────
  bool get isScheduleActive => isAnyScheduleRunning;

  bool get isAnyScheduleRunning {
    final now = DateTime.now().toUtc().add(const Duration(hours: 7));
    final weekday = now.weekday % 7;
    if (_categories.isEmpty) return false;
    final selectedCategoryId = _categories[_selectedCategoryIndex].id;
    final todaySchedules = _getSchedulesForDay(weekday, selectedCategoryId);
    for (final schedule in todaySchedules) {
      if (!schedule.active) continue;
      final startParts = schedule.startTime.split(':');
      final endParts = schedule.endTime.split(':');
      final startDt = DateTime(
        now.year,
        now.month,
        now.day,
        int.parse(startParts[0]),
        int.parse(startParts[1]),
      );
      DateTime endDt = DateTime(
        now.year,
        now.month,
        now.day,
        int.parse(endParts[0]),
        int.parse(endParts[1]),
      );
      if (endDt.isBefore(startDt)) endDt = endDt.add(const Duration(days: 1));
      if (!now.isBefore(startDt) && now.isBefore(endDt)) return true;
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _pulseAnim = Tween<double>(begin: 0.5, end: 1.0).animate(_pulseCtrl);
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);

    _updateTime();
    _fetchWeather();
    _listenPumpStatus();
    _listenPlantTypes();
    _startCountdownTimer();
    _startScheduleCheckTimer();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _fadeCtrl.dispose();
    _clockTimer?.cancel();
    _countdownTimer?.cancel();
    _scheduleCheckTimer?.cancel();
    _scheduleSub?.cancel();
    _pumpSub.cancel();
    _plantTypesSub.cancel();
    super.dispose();
  }

  // ── All original logic (UNCHANGED) ────────────────────────────────────────
  void _startScheduleCheckTimer() {
    _scheduleCheckTimer?.cancel();
    _scheduleCheckTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _checkAndActivateSchedule(),
    );
  }

  Future<void> _checkAndActivateSchedule() async {
    if (!mounted || _categories.isEmpty) return;
    final now = DateTime.now().toUtc().add(const Duration(hours: 7));
    final today = DateTime(now.year, now.month, now.day);
    final weekday = now.weekday % 7;
    final selectedCategoryId = _categories[_selectedCategoryIndex].id;
    final todaySchedules = _getSchedulesForDay(weekday, selectedCategoryId);
    ScheduleModel? runningSchedule;
    int expectedDurationMinutes = 0;
    for (final schedule in todaySchedules) {
      if (!schedule.active) continue;
      final startParts = schedule.startTime.split(':');
      final endParts = schedule.endTime.split(':');
      final startDt = DateTime(
        today.year,
        today.month,
        today.day,
        int.parse(startParts[0]),
        int.parse(startParts[1]),
      );
      DateTime endDt = DateTime(
        today.year,
        today.month,
        today.day,
        int.parse(endParts[0]),
        int.parse(endParts[1]),
      );
      if (endDt.isBefore(startDt)) endDt = endDt.add(const Duration(days: 1));
      if (!now.isBefore(startDt) && now.isBefore(endDt)) {
        final remainingSeconds = endDt.difference(now).inSeconds;
        expectedDurationMinutes = (remainingSeconds / 60).ceil().clamp(1, 999);
        runningSchedule = schedule;
        break;
      }
    }
    if (runningSchedule != null) {
      if (_timerSource != 'schedule' ||
          _activeTimer != expectedDurationMinutes ||
          !_pumpIsActive) {
        setState(() {
          _timerSource = 'schedule';
          _activeTimer = expectedDurationMinutes;
        });
        await _firebaseService.activateManualPump(
          expectedDurationMinutes,
          source: 'schedule',
          isActive: true,
        );
        _startCountdownTimer();
      }
    } else if (_timerSource == 'schedule') {
      setState(() {
        _timerSource = 'none';
        _activeTimer = 0;
        _pumpIsActive = false;
      });
      _countdownTimer?.cancel();
      await _firebaseService.activateManualPump(
        0,
        source: 'none',
        isActive: false,
      );
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Jangan panggil _listenPumpStatus() di sini — sudah dipanggil di initState
    // dan akan menyebabkan subscription leak setiap kali InheritedWidget berubah
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

  Future<void> _fetchWeather() async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://api.open-meteo.com/v1/forecast?latitude=-7.9525&longitude=112.6144&current_weather=true',
        ),
      );
      if (response.statusCode == 200 && mounted) {
        setState(() {
          _weatherData = json.decode(response.body)['current_weather'];
        });
      }
    } catch (e) {
      print("Error fetching weather: $e");
    }
  }

  void _listenPlantTypes() {
    _plantTypesSub = _firebaseService.getPlantTypesStream().listen((event) {
      if (event.snapshot.value != null && mounted) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        final newCategories = data.entries
            .map(
              (e) => PlantCategory.fromMap(
                e.key,
                Map<String, dynamic>.from(e.value as Map),
              ),
            )
            .toList();
        setState(() {
          _categories = newCategories;
          if (_selectedCategoryIndex >= _categories.length) {
            _selectedCategoryIndex = 0;
          }
          if (_categories.isNotEmpty) {
            _listenSchedulesForCategory(_categories[_selectedCategoryIndex].id);
          } else {
            _schedules = [];
          }
        });
      } else if (mounted) {
        setState(() {
          _categories = [];
          _schedules = [];
        });
      }
    });
  }

  void _listenSchedulesForCategory(String plantTypeId) {
    _scheduleSub?.cancel();
    _scheduleSub = _firebaseService
        .getSchedulesStream(plantTypeId)
        .listen(
          (event) {
            if (event.snapshot.value != null && mounted) {
              final data = Map<dynamic, dynamic>.from(
                event.snapshot.value as Map,
              );
              setState(() {
                _schedules = data.entries
                    .map(
                      (e) => ScheduleModel.fromMap(
                        e.key,
                        Map<dynamic, dynamic>.from(e.value as Map),
                        plantTypeId,
                      ),
                    )
                    .toList();
              });
              _checkAndActivateSchedule();
            } else if (mounted) {
              setState(() => _schedules = []);
            }
          },
          onError: (error) {
            if (mounted) setState(() => _schedules = []);
          },
        );
  }

  void _listenPumpStatus() {
    _pumpSub = _firebaseService.getPumpStatusStream().listen((event) {
      if (event.snapshot.value != null) {
        final data = Map<dynamic, dynamic>.from(event.snapshot.value as Map);
        final duration = data['duration'] as int? ?? 0;
        final isActive = data['isActive'] as bool? ?? false;
        final source = data['source'] as String? ?? 'unknown';
        if (source != _timerSource ||
            (source != 'schedule' && duration != _activeTimer) ||
            (source == 'schedule' && !isActive)) {
          setState(() {
            _pumpIsActive = isActive;
            if (source != 'schedule') _activeTimer = duration;
            _timerSource = source;
          });
          if (_activeTimer > 0 && source != 'schedule') {
            _startCountdownTimer();
          } else if (source != 'schedule') {
            _countdownTimer?.cancel();
          }
        }
      }
    });
  }

  void _startCountdownTimer() {
    _countdownTimer?.cancel();
    if (_activeTimer > 0) {
      _countdownTimer = Timer.periodic(
        const Duration(minutes: 1),
        _updateCountdown,
      );
    }
  }

  void _updateCountdown(Timer timer) {
    if (!mounted) return;
    if (_activeTimer <= 0) {
      _stopTimer();
      timer.cancel();
      return;
    }
    setState(() => _activeTimer--);
    if (_activeTimer > 0 && _timerSource != 'schedule') {
      _firebaseService.activateManualPump(_activeTimer);
    }
  }

  Future<void> _quickAction(int minutes) async {
    if (isAnyScheduleRunning) {
      if (mounted) {
        _showSnackbar(
          'Schedule aktif — hentikan schedule dulu atau gunakan STOP',
          isError: true,
        );
      }
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() {
      _timerSource = 'quick';
      _activeTimer = minutes;
    });
    await _firebaseService.activateManualPump(minutes, source: 'quick');
    _startCountdownTimer();
    if (mounted) _showSnackbar('Pompa aktif selama $minutes menit');
  }

  Future<void> _stopTimer() async {
    HapticFeedback.lightImpact();
    setState(() {
      _activeTimer = 0;
      _timerSource = 'none';
    });
    _countdownTimer?.cancel();
    await _firebaseService.activateManualPump(0, source: 'none');
    if (mounted) _showSnackbar('Timer dihentikan');
  }

  List<ScheduleModel> _getSchedulesForDay(int day, String plantTypeId) {
    const dayMapping = {
      'Sun': 0,
      'Mon': 1,
      'Tue': 2,
      'Wed': 3,
      'Thu': 4,
      'Fri': 5,
      'Sat': 6,
      'Min': 0,
      'Sen': 1,
      'Sel': 2,
      'Rab': 3,
      'Kam': 4,
      'Jum': 5,
      'Sab': 6,
    };
    return _schedules.where((schedule) {
      if (schedule.plantTypeId != plantTypeId) return false;
      final repeatDays = schedule.repeat;
      final lower = repeatDays.toLowerCase().trim();
      if (lower == 'daily') return true;
      if (lower == 'weekend') return day == 0 || day == 6;
      if (repeatDays.contains('-')) {
        final parts = repeatDays.split('-');
        if (parts.length == 2) {
          final s = dayMapping[parts[0].trim()];
          final e = dayMapping[parts[1].trim()];
          if (s != null && e != null) {
            if (s <= e) return day >= s && day <= e;
            return day >= s || day <= e;
          }
        }
      }
      return repeatDays
          .split(',')
          .map((e) => e.trim())
          .any((dayName) => dayMapping[dayName] == day);
    }).toList();
  }

  void _showSnackbar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isError
                    ? Icons.warning_amber_rounded
                    : Icons.check_circle_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? AppColors.orange : AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _deleteSchedule(ScheduleModel schedule) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _T.getCard(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Hapus Jadwal?',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: _T.getInk(context),
          ),
        ),
        content: Text(
          'Anda yakin ingin menghapus jadwal "${schedule.name}"?',
          style: TextStyle(color: _T.getInkMid(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Batal',
              style: TextStyle(color: _T.getInkMid(context)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Hapus', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed ?? false) {
      try {
        await _firebaseService.deleteSchedule(
          schedule.plantTypeId,
          schedule.id,
        );
        _showSnackbar('Jadwal "${schedule.name}" berhasil dihapus.');
      } catch (e) {
        _showSnackbar('Gagal menghapus jadwal: $e', isError: true);
      }
    }
  }

  Future<void> _showAddEditScheduleDialog({ScheduleModel? schedule}) async {
    if (_categories.isEmpty) {
      _showSnackbar(
        'Tidak ada kategori tanaman. Buat satu terlebih dahulu.',
        isError: true,
      );
      return;
    }
    final String plantTypeId =
        schedule?.plantTypeId ?? _categories[_selectedCategoryIndex].id;
    showDialog(
      context: context,
      builder: (context) => _AddEditScheduleForm(
        firebaseService: _firebaseService,
        plantTypeId: plantTypeId,
        schedule: schedule,
        onSave: (newSchedule) async {
          if (schedule != null && schedule.id != newSchedule.id) {
            await _firebaseService.deleteSchedule(schedule.plantTypeId, schedule.id);
          }
          try {
            if (schedule == null) {
              await _firebaseService.addSchedule(newSchedule);
            } else {
              await _firebaseService.updateSchedule(newSchedule);
            }
            _showSnackbar(
              schedule == null
                  ? 'Jadwal berhasil ditambahkan.'
                  : 'Jadwal berhasil diperbarui.',
            );
            if (context.mounted) Navigator.of(context).pop();
          } catch (e) {
            _showSnackbar('Gagal menyimpan jadwal: $e', isError: true);
            if (context.mounted) Navigator.of(context).pop();
          }
        },
      ),
    );
  }

  // ===========================================================================
  // BUILD UTAMA
  // ===========================================================================
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: _T.getBg(context),
        body: FadeTransition(
          opacity: _fadeAnim,
          child: SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: _buildPageHeader(),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Weather + Map side-by-side
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildLiveWeather()),
                            const SizedBox(width: 12),
                            Expanded(flex: 2, child: _buildLocationMap()),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _buildCategoryTabs(),
                        const SizedBox(height: 20),
                        _buildTimelineOverview(),
                        const SizedBox(height: 16),
                        _buildQuickActionPanel(),
                        const SizedBox(height: 24),
                        _buildAnimatedActiveSchedulesList(),
                        const SizedBox(height: 16),
                        _buildAddButton(),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // PAGE HEADER
  // ===========================================================================
  Widget _buildPageHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Brand mark
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF059669), Color(0xFF10B981)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.water_drop_rounded,
            color: Colors.white,
            size: 20,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'HYDROGROW',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  letterSpacing: 2.5,
                ),
              ),
              Text(
                'Irrigation Planner',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: _T.getInk(context),
                  letterSpacing: -0.5,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
        // Clock
        AnimatedBuilder(
          animation: _pulseAnim,
          builder: (_, __) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _T.getCard(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _T.getStroke(context)),
              boxShadow: _T.cardShadow(context),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Opacity(
                  opacity: _pulseAnim.value,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.7),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _currentTime,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: _T.getInk(context),
                        letterSpacing: -0.3,
                        fontFamily: 'monospace',
                      ),
                    ),
                    Text(
                      'WIB',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        color: _T.getInkSoft(context),
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // WEATHER CARD
  // ===========================================================================
  Widget _buildLiveWeather() {
    String getStatus(int code) {
      if (code == 0) return 'Cerah';
      if (code <= 3) return 'Berawan';
      if (code <= 48) return 'Berkabut';
      if (code <= 67) return 'Hujan';
      return 'Badai';
    }

    IconData getIcon(int code) {
      if (code == 0) return Icons.wb_sunny_rounded;
      if (code <= 3) return Icons.cloud_rounded;
      if (code <= 48) return Icons.foggy;
      if (code <= 67) return Icons.grain_rounded;
      return Icons.thunderstorm_rounded;
    }

    Color getIconColor(int code) {
      if (code == 0) return AppColors.orange;
      if (code <= 3) return AppColors.inkLighter;
      return AppColors.info;
    }

    if (_weatherData == null) {
      return Container(
        height: 118,
        decoration: BoxDecoration(
          color: _T.getCard(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _T.getStroke(context)),
          boxShadow: _T.cardShadow(context),
        ),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          ),
        ),
      );
    }

    final code = (_weatherData!['weathercode'] as num).toInt();

    return Container(
      height: 118,
      decoration: BoxDecoration(
        color: _T.getCard(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: _T.cardShadow(context),
      ),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(getIcon(code), color: getIconColor(code), size: 22),
              const Spacer(),
              Text(
                'Live',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_weatherData!['temperature']}°C',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: _T.getInk(context),
                  height: 1,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                getStatus(code),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: _T.getInkMid(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // MAP CARD
  // ===========================================================================
  Widget _buildLocationMap() {
    return Container(
      height: 118,
      decoration: BoxDecoration(
        color: _T.getCard(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _T.getStroke(context)),
        boxShadow: _T.cardShadow(context),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            FlutterMap(
              options: const MapOptions(
                initialCenter: LatLng(-7.9525, 112.6144),
                initialZoom: 14.0,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                  subdomains: const ['a', 'b', 'c'],
                  userAgentPackageName: 'com.example.iot_hydrogrow',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      width: 44,
                      height: 44,
                      point: const LatLng(-7.9525, 112.6144),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2.5),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.5),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.water_drop_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface.withOpacity(0.92),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.location_on_rounded,
                      size: 10,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      'Field Location',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: _T.getInk(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // CATEGORY TABS
  // ===========================================================================
  Widget _buildCategoryTabs() {
    if (_categories.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategoryIndex == index;
          return GestureDetector(
            onTap: () {
              if (_selectedCategoryIndex != index) {
                HapticFeedback.selectionClick();
                setState(() {
                  _selectedCategoryIndex = index;
                  _schedules = [];
                });
                _listenSchedulesForCategory(category.id);
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : _T.getCard(context),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppColors.primary : _T.getStroke(context),
                  width: 1.5,
                ),
                boxShadow: isSelected ? _T.elevatedShadow(context) : [],
              ),
              child: Text(
                category.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : _T.getInkMid(context),
                  letterSpacing: 0.2,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ===========================================================================
  // TIMELINE OVERVIEW
  // ===========================================================================
  Widget _buildTimelineOverview() {
    final days = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];
    final catLabel = _categories.isNotEmpty
        ? _categories[_selectedCategoryIndex].label
        : '';

    return Container(
      decoration: BoxDecoration(
        color: _T.getCard(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _T.getStroke(context)),
        boxShadow: _T.cardShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
            decoration: BoxDecoration(
              color: _T.getCardTinted(context),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              border: Border(bottom: BorderSide(color: _T.getStroke(context))),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(
                    Icons.calendar_month_rounded,
                    size: 17,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Timeline',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: _T.getInk(context),
                          letterSpacing: -0.3,
                        ),
                      ),
                      if (catLabel.isNotEmpty)
                        Text(
                          catLabel,
                          style: TextStyle(
                            fontSize: 11,
                            color: _T.getInkSoft(context),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),
                if (isScheduleActive)
                  AnimatedBuilder(
                    animation: _pulseAnim,
                    builder: (_, __) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGlow,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Opacity(
                            opacity: _pulseAnim.value,
                            child: Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: AppColors.primaryLight,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Aktif',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Day pills
                SizedBox(
                  height: 52,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: days.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 6),
                    itemBuilder: (context, index) {
                      final isSelected = _selectedDay == index;
                      final isToday = DateTime.now().weekday % 7 == index;
                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _selectedDay = index);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutCubic,
                          width: 44,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : _T.getBg(context),
                            borderRadius: BorderRadius.circular(13),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : isToday
                                  ? AppColors.primary
                                  : _T.getStroke(context),
                              width: isToday && !isSelected ? 2 : 1,
                            ),
                            boxShadow: isSelected
                                ? _T.elevatedShadow(context)
                                : [],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                days[index],
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected
                                      ? Colors.white
                                      : isToday
                                      ? AppColors.primary
                                      : _T.getInkMid(context),
                                ),
                              ),
                              if (isToday)
                                Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  width: 4,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Colors.white.withOpacity(0.8)
                                        : AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 16),

                // Timeline bar
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _T.getBg(context),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _T.getStroke(context)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${days[_selectedDay]}  ·  ${_getSchedulesForDay(_selectedDay, _categories.isNotEmpty ? _categories[_selectedCategoryIndex].id : '').length} jadwal',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _T.getInkSoft(context),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final double totalWidth = constraints.maxWidth;
                          final schedulesForBar = _getSchedulesForDay(
                            _selectedDay,
                            _categories.isNotEmpty
                                ? _categories[_selectedCategoryIndex].id
                                : '',
                          );
                          return Column(
                            children: [
                              SizedBox(
                                height: 28,
                                child: Stack(
                                  children: [
                                    // Track
                                    Positioned(
                                      top: 9,
                                      left: 0,
                                      right: 0,
                                      child: Container(
                                        height: 10,
                                        decoration: BoxDecoration(
                                          color: _T.getStroke(context),
                                          borderRadius: BorderRadius.circular(
                                            5,
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Hour tick marks
                                    ...[6, 12, 18].map((h) {
                                      final x = (h / 24) * totalWidth;
                                      return Positioned(
                                        left: x - 0.5,
                                        top: 7,
                                        child: Container(
                                          width: 1,
                                          height: 14,
                                          color: _T.getStroke(context),
                                        ),
                                      );
                                    }),
                                    // Schedule bars
                                    ...schedulesForBar.map((sch) {
                                      final sp = sch.startTime.split(':');
                                      final ep = sch.endTime.split(':');
                                      final startFrac =
                                          (int.parse(sp[0]) +
                                              int.parse(sp[1]) / 60) /
                                          24.0;
                                      final endFrac =
                                          (int.parse(ep[0]) +
                                              int.parse(ep[1]) / 60) /
                                          24.0;
                                      final barW =
                                          ((endFrac - startFrac) * totalWidth)
                                              .clamp(34.0, totalWidth)
                                              .toDouble();
                                      final barL = (startFrac * totalWidth)
                                          .clamp(0.0, totalWidth - 34)
                                          .toDouble();
                                      return Positioned(
                                        left: barL,
                                        top: 7,
                                        child: GestureDetector(
                                          onTap: () =>
                                              _showScheduleModal(schedule: sch),
                                          child: Container(
                                            width: barW,
                                            height: 14,
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: sch.active
                                                    ? const [
                                                        Color(0xFF059669),
                                                        Color(0xFF10B981),
                                                      ]
                                                    : [
                                                        _T.getInkSoft(context),
                                                        _T.getStroke(context),
                                                      ],
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(7),
                                              boxShadow: sch.active
                                                  ? [
                                                      BoxShadow(
                                                        color: AppColors.primary
                                                            .withOpacity(0.3),
                                                        blurRadius: 6,
                                                        offset: const Offset(
                                                          0,
                                                          2,
                                                        ),
                                                      ),
                                                    ]
                                                  : [],
                                            ),
                                            alignment: Alignment.center,
                                            child: Text(
                                              sch.startTime,
                                              style: TextStyle(
                                                fontSize: 7,
                                                color: Colors.white.withOpacity(
                                                  0.95,
                                                ),
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: ['00', '06', '12', '18', '24']
                                    .map(
                                      (t) => Text(
                                        t,
                                        style: TextStyle(
                                          fontSize: 9,
                                          color: _T.getInkSoft(context),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                              if (schedulesForBar.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 10),
                                  child: Text(
                                    'Belum ada jadwal untuk hari ini',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: _T.getInkSoft(context),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // QUICK ACTION PANEL
  // ===========================================================================
  Widget _buildQuickActionPanel() {
    final isActive = _activeTimer > 0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: _T.getCard(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isActive ? AppColors.primaryDim : _T.getStroke(context),
          width: 1.5,
        ),
        boxShadow: isActive
            ? _T.elevatedShadow(context)
            : _T.cardShadow(context),
      ),
      child: Column(
        children: [
          // Header strip
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.primaryGlow
                  : _T.getCardTinted(context),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              border: Border(bottom: BorderSide(color: _T.getStroke(context))),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.primary : _T.getBg(context),
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(
                      color: isActive
                          ? AppColors.primary
                          : _T.getStroke(context),
                    ),
                  ),
                  child: Icon(
                    Icons.bolt_rounded,
                    size: 18,
                    color: isActive ? Colors.white : _T.getInkSoft(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quick Action',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: _T.getInk(context),
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        isActive
                            ? 'Pompa sedang aktif'
                            : 'Siap mengaktifkan pompa',
                        style: TextStyle(
                          fontSize: 11,
                          color: isActive
                              ? AppColors.primary
                              : _T.getInkSoft(context),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.primary
                        : _T.getStroke(context).withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isActive ? 'AKTIF' : 'IDLE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: isActive ? Colors.white : _T.getInkSoft(context),
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Active timer display
                if (isActive) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 24,
                      horizontal: 20,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFECFDF5), Color(0xFFD1FAE5)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: AppColors.primaryDim,
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '$_activeTimer',
                              style: TextStyle(
                                fontSize: 64,
                                fontWeight: FontWeight.w900,
                                color: AppColors.primary,
                                height: 1,
                                letterSpacing: -2,
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.only(bottom: 8),
                              child: Text(
                                ' mnt',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.water_drop_rounded,
                                size: 13,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _timerSource == 'schedule'
                                    ? 'Dari Jadwal'
                                    : 'Manual',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Schedule running warning
                if (isScheduleActive) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: _T.amberDim,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _T.amber.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.schedule_rounded, size: 14, color: _T.amber),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Jadwal sedang berjalan',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFFD97706),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                Text(
                  isActive ? 'Ubah durasi' : 'Pilih durasi',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _T.getInkSoft(context),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 10),

                // Duration buttons
                Row(
                  children: [5, 10, 15].map((min) {
                    final isSelectedMin = _activeTimer == min;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: min != 15 ? 8 : 0),
                        child: GestureDetector(
                          onTap: () => _quickAction(min),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOutCubic,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              gradient: isSelectedMin
                                  ? const LinearGradient(
                                      colors: [
                                        Color(0xFF059669),
                                        Color(0xFF10B981),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                  : null,
                              color: isSelectedMin ? null : _T.getBg(context),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelectedMin
                                    ? AppColors.primary
                                    : _T.getStroke(context),
                              ),
                              boxShadow: isSelectedMin
                                  ? _T.elevatedShadow(context)
                                  : [],
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.water_drop_rounded,
                                  size: 17,
                                  color: isSelectedMin
                                      ? Colors.white
                                      : _T.getInkSoft(context),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '$min',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    color: isSelectedMin
                                        ? Colors.white
                                        : _T.getInk(context),
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                Text(
                                  'menit',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    color: isSelectedMin
                                        ? Colors.white.withOpacity(0.8)
                                        : _T.getInkSoft(context),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 12),

                // Stop button
                SizedBox(
                  width: double.infinity,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isActive
                            ? Colors.red.shade200
                            : _T.getStroke(context),
                      ),
                    ),
                    child: TextButton.icon(
                      onPressed: isActive ? _stopTimer : null,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        foregroundColor: isActive
                            ? Colors.red.shade400
                            : _T.getInkSoft(context),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      icon: const Icon(Icons.stop_circle_outlined, size: 16),
                      label: Text(
                        isActive ? 'Hentikan Timer' : 'Tidak Ada Timer',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // ACTIVE SCHEDULES LIST
  // ===========================================================================
  Widget _buildAnimatedActiveSchedulesList() {
    if (_categories.isEmpty) {
      return _buildEmptyCard(
        icon: Icons.eco_rounded,
        title: 'Buat Kategori Tanaman',
        subtitle: 'Tambahkan kategori terlebih dahulu untuk membuat jadwal.',
      );
    }

    final selectedCategoryId = _categories[_selectedCategoryIndex].id;
    final todaySchedules = _getSchedulesForDay(
      _selectedDay,
      selectedCategoryId,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 18,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Jadwal Aktif',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: _T.getInk(context),
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primaryDim,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${todaySchedules.length}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (todaySchedules.isEmpty)
          _buildEmptyCard(
            icon: Icons.calendar_today_outlined,
            title: 'Belum ada jadwal',
            subtitle:
                'Ketuk "Tambah Jadwal" untuk membuat jadwal irigasi pertamamu.',
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: todaySchedules.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (ctx, i) => _StaggeredWidget(
              index: i,
              delay: 0,
              child: _ScheduleCard(
                schedule: todaySchedules[i],
                onEdit: () =>
                    _showAddEditScheduleDialog(schedule: todaySchedules[i]),
                onDelete: () => _deleteSchedule(todaySchedules[i]),
                firebaseService: _firebaseService,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
      decoration: BoxDecoration(
        color: _T.getCard(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _T.getStroke(context)),
      ),
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: AppColors.primaryDim,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, size: 24, color: AppColors.primary),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _T.getInk(context),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _T.getInkSoft(context),
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // ADD BUTTON
  // ===========================================================================
  Widget _buildAddButton() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        _showAddEditScheduleDialog();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF059669), Color(0xFF10B981)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: _T.elevatedShadow(context),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.add_circle_rounded, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Text(
              'Tambah Jadwal',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 15,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // SCHEDULE MODAL (UNCHANGED logic)
  // ===========================================================================
  void _showScheduleModal({ScheduleModel? schedule}) {
    final isEditing = schedule != null;
    final nameCtrl = TextEditingController(text: schedule?.name ?? "New Cycle");
    final startCtrl = TextEditingController(
      text: schedule?.startTime ?? "07:00",
    );
    final endCtrl = TextEditingController(text: schedule?.endTime ?? "07:10");
    String repeat = schedule?.repeat ?? "Daily";
    bool active = schedule?.active ?? true;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: _T.getStroke(context),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppColors.primaryDim,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isEditing ? Icons.edit_rounded : Icons.add_rounded,
                          color: AppColors.primary,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        isEditing ? 'Edit Jadwal' : 'Jadwal Baru',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: _T.getInk(context),
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  _modalLabel('Nama Jadwal'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: nameCtrl,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: _T.getInk(context),
                      fontSize: 14,
                    ),
                    decoration: _inputDeco('Contoh: Pagi Hari'),
                  ),
                  const SizedBox(height: 16),
                  _modalLabel('Waktu'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTimeField(
                          context,
                          startCtrl,
                          'Mulai',
                          setModalState,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          '–',
                          style: TextStyle(
                            color: _T.getInkSoft(context),
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      Expanded(
                        child: _buildTimeField(
                          context,
                          endCtrl,
                          'Selesai',
                          setModalState,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _modalLabel('Pengulangan'),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: _T.getBg(context),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _T.getStroke(context)),
                    ),
                    child: DropdownButtonFormField<String>(
                      value: repeat,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                      ),
                      items: ['Daily', 'Mon-Fri', 'Weekend']
                          .map(
                            (e) => DropdownMenuItem(value: e, child: Text(e)),
                          )
                          .toList(),
                      onChanged: (val) => setModalState(() => repeat = val!),
                      style: TextStyle(
                        color: _T.getInk(context),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _T.getBg(context),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _T.getStroke(context)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.power_settings_new_rounded,
                          size: 16,
                          color: active
                              ? AppColors.primary
                              : _T.getInkSoft(context),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Jadwal Aktif',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: active
                                  ? _T.getInk(context)
                                  : _T.getInkSoft(context),
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Switch.adaptive(
                          value: active,
                          activeColor: AppColors.primary,
                          onChanged: (val) => setModalState(() => active = val),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(color: _T.getStroke(context)),
                            foregroundColor: _T.getInkMid(context),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            'Batal',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            if (_categories.isEmpty) {
                              _showSnackbar(
                                'Tidak ada kategori tanaman.',
                                isError: true,
                              );
                              return;
                            }
                            if (isEditing) {
                              final updated = ScheduleModel(
                                id: schedule.id,
                                name: nameCtrl.text,
                                startTime: startCtrl.text,
                                endTime: endCtrl.text,
                                repeat: repeat,
                                active: active,
                                plantTypeId: schedule.plantTypeId,
                              );
                              await _firebaseService.updateSchedule(updated);
                            } else {
                              final newSch = ScheduleModel(
                                id: '',
                                name: nameCtrl.text,
                                startTime: startCtrl.text,
                                endTime: endCtrl.text,
                                repeat: repeat,
                                active: active,
                                plantTypeId:
                                    _categories[_selectedCategoryIndex].id,
                              );
                              await _firebaseService.addSchedule(newSch);
                            }
                            if (!mounted) return;
                            Navigator.pop(context);
                            _showSnackbar(
                              isEditing
                                  ? 'Jadwal berhasil diperbarui'
                                  : 'Jadwal berhasil ditambahkan',
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: Icon(
                            isEditing ? Icons.check_rounded : Icons.add_rounded,
                            size: 17,
                          ),
                          label: Text(
                            isEditing ? 'Simpan' : 'Buat Jadwal',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _modalLabel(String text) => Text(
    text,
    style: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      color: _T.getInkSoft(context),
      letterSpacing: 0.8,
    ),
  );

  InputDecoration _inputDeco(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: _T.getInkSoft(context), fontSize: 14),
    filled: true,
    fillColor: _T.getBg(context),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: _T.getStroke(context)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: _T.getStroke(context)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
  );

  Widget _buildTimeField(
    BuildContext context,
    TextEditingController ctrl,
    String label,
    StateSetter setModalState,
  ) {
    return GestureDetector(
      onTap: () async {
        final parts = ctrl.text.split(':');
        final initial = TimeOfDay(
          hour: int.tryParse(parts[0]) ?? 7,
          minute: int.tryParse(parts[1]) ?? 0,
        );
        final time = await showTimePicker(
          context: context,
          initialTime: initial,
          builder: (context, child) => Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: AppColors.primary,
                onPrimary: Colors.white,
              ),
            ),
            child: child!,
          ),
        );
        if (time != null) {
          setModalState(() {
            ctrl.text =
                '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: _T.getBg(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _T.getStroke(context)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.access_time_rounded,
              size: 14,
              color: AppColors.primary,
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 9,
                    color: _T.getInkSoft(context),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  ctrl.text,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: _T.getInk(context),
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// _AddEditScheduleForm (UNCHANGED logic)
// =============================================================================
class _AddEditScheduleForm extends StatefulWidget {
  final FirebaseService firebaseService;
  final String plantTypeId;
  final ScheduleModel? schedule;
  final Function(ScheduleModel) onSave;

  const _AddEditScheduleForm({
    required this.firebaseService,
    required this.plantTypeId,
    this.schedule,
    required this.onSave,
  });

  @override
  __AddEditScheduleFormState createState() => __AddEditScheduleFormState();
}

class __AddEditScheduleFormState extends State<_AddEditScheduleForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late String _repeat;
  late bool _isActive;

  final List<String> _repeatOptions = ['Daily', 'Weekend', 'Mon-Fri'];

  @override
  void initState() {
    super.initState();
    String initialRepeat = widget.schedule?.repeat ?? 'Daily';
    if (!_repeatOptions.contains(initialRepeat)) {
      initialRepeat = 'Daily';
    }
    _nameController = TextEditingController(
      text: widget.schedule?.name ?? 'New Cycle',
    );
    _startTime = _timeOfDayFromString(widget.schedule?.startTime ?? '07:00');
    _endTime = _timeOfDayFromString(widget.schedule?.endTime ?? '07:10');
    _repeat = initialRepeat;
    _isActive = widget.schedule?.active ?? true;
  }

  TimeOfDay _timeOfDayFromString(String time) {
    try {
      final parts = time.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    } catch (_) {
      return const TimeOfDay(hour: 0, minute: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      title: Text(
        widget.schedule == null ? 'Tambah Jadwal' : 'Edit Jadwal',
        style: TextStyle(
          fontWeight: FontWeight.w800,
          color: _T.getInk(context),
        ),
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                style: TextStyle(
                  color: _T.getInk(context),
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  labelText: 'Nama Jadwal',
                  labelStyle: TextStyle(color: _T.getInkSoft(context)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: _T.getStroke(context)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                  ),
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Nama tidak boleh kosong' : null,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final t = await showTimePicker(
                          context: context,
                          initialTime: _startTime,
                        );
                        if (t != null) setState(() => _startTime = t);
                      },
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Mulai',
                          labelStyle: TextStyle(color: _T.getInkSoft(context)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          _startTime.format(context),
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final t = await showTimePicker(
                          context: context,
                          initialTime: _endTime,
                        );
                        if (t != null) setState(() => _endTime = t);
                      },
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Selesai',
                          labelStyle: TextStyle(color: _T.getInkSoft(context)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          _endTime.format(context),
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: _repeat,
                decoration: InputDecoration(
                  labelText: 'Ulangi',
                  labelStyle: TextStyle(color: _T.getInkSoft(context)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: _repeatOptions
                    .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _repeat = v);
                },
              ),
              SwitchListTile(
                title: Text(
                  'Aktif',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                value: _isActive,
                activeColor: AppColors.primary,
                onChanged: (v) => setState(() => _isActive = v),
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Batal', style: TextStyle(color: _T.getInkMid(context))),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final scheduleId = _nameController.text.toLowerCase().replaceAll(
                RegExp(r'[^a-z0-9]+'),
                '_',
              );
              final newSchedule = ScheduleModel(
                id: scheduleId,
                plantTypeId: widget.plantTypeId,
                name: _nameController.text,
                startTime:
                    '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}',
                endTime:
                    '${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}',
                repeat: _repeat,
                active: _isActive,
              );
              widget.onSave(newSchedule);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text('Simpan', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}

// =============================================================================
// _ScheduleCard — redesigned
// =============================================================================
class _ScheduleCard extends StatelessWidget {
  final ScheduleModel schedule;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final FirebaseService firebaseService;

  const _ScheduleCard({
    required this.schedule,
    required this.onEdit,
    required this.onDelete,
    required this.firebaseService,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = schedule.active;

    return Container(
      decoration: BoxDecoration(
        color: _T.getCard(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isActive ? AppColors.primaryDim : _T.getStroke(context),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isActive
                ? AppColors.primary.withOpacity(0.07)
                : Colors.black.withOpacity(0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Left icon block
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: isActive
                    ? const LinearGradient(
                        colors: [Color(0xFF059669), Color(0xFF10B981)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isActive ? null : _T.getBg(context),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isActive ? AppColors.primary : _T.getStroke(context),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.water_drop_rounded,
                    size: 15,
                    color: isActive ? Colors.white : _T.getInkSoft(context),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    schedule.startTime,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: isActive ? Colors.white : _T.getInkSoft(context),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    schedule.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: _T.getInk(context),
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        size: 10,
                        color: _T.getInkSoft(context),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${schedule.startTime} – ${schedule.endTime}',
                        style: TextStyle(
                          fontSize: 11,
                          color: _T.getInkMid(context),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _T.getBg(context),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: _T.getStroke(context)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.repeat_rounded,
                          size: 10,
                          color: _T.getInkSoft(context),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          schedule.repeat,
                          style: TextStyle(
                            fontSize: 10,
                            color: _T.getInkMid(context),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Controls
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Transform.scale(
                  scale: 0.82,
                  child: Switch.adaptive(
                    value: schedule.active,
                    activeColor: AppColors.primary,
                    onChanged: (value) {
                      final updated = schedule.copyWith(active: value);
                      firebaseService.updateSchedule(updated);
                    },
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_horiz_rounded,
                    size: 17,
                    color: _T.getInkSoft(context),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 4,
                  onSelected: (value) {
                    if (value == 'edit') onEdit();
                    if (value == 'delete') onDelete();
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(
                            Icons.edit_rounded,
                            size: 15,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Edit',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline_rounded,
                            size: 15,
                            color: Colors.red.shade400,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Hapus',
                            style: TextStyle(
                              color: Colors.red.shade400,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StaggeredWidget extends StatefulWidget {
  final Widget child;
  final int index;
  final int delay;

  const _StaggeredWidget({required this.child, required this.index, required this.delay});

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
