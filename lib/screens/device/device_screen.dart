import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import '../../core/constants.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ANIMATED FADE-SLIDE WRAPPER
// ─────────────────────────────────────────────────────────────────────────────
class _FadeSlide extends StatefulWidget {
  final Widget child;
  final int delay;
  final Offset begin;
  const _FadeSlide({
    required this.child,
    this.delay = 0,
    this.begin = const Offset(0, 0.08),
  });

  @override
  State<_FadeSlide> createState() => _FadeSlideState();
}

class _FadeSlideState extends State<_FadeSlide>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _fade = CurvedAnimation(parent: _c, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: widget.begin,
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _fade,
    child: SlideTransition(
      position: _slide,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.98, end: 1.0).animate(
          CurvedAnimation(parent: _c, curve: Curves.easeOutBack),
        ),
        child: widget.child,
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// PULSING DOT
// ─────────────────────────────────────────────────────────────────────────────
class _PulsingDot extends StatefulWidget {
  final Color color;
  const _PulsingDot({required this.color});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (_, __) => Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: widget.color.withOpacity(0.6 + 0.4 * _c.value),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: widget.color.withOpacity(0.5 * _c.value),
            blurRadius: 6,
            spreadRadius: 2 * _c.value,
          ),
        ],
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// MOISTURE ARC PAINTER
// ─────────────────────────────────────────────────────────────────────────────
class _MoistureArc extends StatelessWidget {
  final double value; // 0–100
  final double min;
  final double max;
  final double size;

  const _MoistureArc({
    required this.value,
    required this.min,
    required this.max,
    this.size = 80,
  });

  Color get _color {
    if (value >= max) return AppColors.orange;
    if (value < min) return AppColors.info;
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _ArcPainter(
              value: value / 100,
              color: _color,
              bgColor: _color.withOpacity(0.12),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "${value.toInt()}%",
                style: TextStyle(
                  fontSize: size * 0.22,
                  fontWeight: FontWeight.w900,
                  color: _color,
                  height: 1,
                ),
              ),
              Text(
                "MOISTURE",
                style: TextStyle(
                  fontSize: size * 0.1,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[400],
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  final double value;
  final Color color;
  final Color bgColor;
  _ArcPainter({
    required this.value,
    required this.color,
    required this.bgColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final bgPaint = Paint()
      ..color = bgColor
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fgPaint = Paint()
      ..color = color
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, 2.35, 4.71, false, bgPaint);
    canvas.drawArc(rect, 2.35, 4.71 * value.clamp(0, 1), false, fgPaint);
  }

  @override
  bool shouldRepaint(_ArcPainter old) =>
      old.value != value || old.color != color;
}

// ─────────────────────────────────────────────────────────────────────────────
// MAIN PAGE
// ─────────────────────────────────────────────────────────────────────────────
class DevicePage extends StatefulWidget {
  const DevicePage({super.key});

  @override
  State<DevicePage> createState() => _DevicePageState();
}

class _DevicePageState extends State<DevicePage> with TickerProviderStateMixin {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  Map<dynamic, dynamic>? _plantTypes;
  Map<String, dynamic> _units = {};
  String? _selectedCategoryId;
  bool _isLoading = true;
  bool _isEditingThreshold = false;

  double _tempMin = 40;
  double _tempMax = 80;
  double _waterLevel = 100.0;

  StreamSubscription? _typesSub;
  StreamSubscription? _unitsSub;
  StreamSubscription? _waterSub;

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _initDataListeners();
  }

  @override
  void dispose() {
    _typesSub?.cancel();
    _unitsSub?.cancel();
    _waterSub?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _initDataListeners() {
    _typesSub = _dbRef.child("config/plant_types").onValue.listen((event) {
      final data = event.snapshot.value as Map? ?? {};
      if (mounted) {
        setState(() {
          _plantTypes = data;
          _isLoading = false;
          if (data.isNotEmpty && _selectedCategoryId == null) {
            _selectedCategoryId = data.keys.first.toString();
            _syncTempThresholds();
          }
        });
      }
    });

    _unitsSub = _dbRef.child("device/units").onValue.listen((event) {
      final data = event.snapshot.value as Map? ?? {};
      Map<String, dynamic> flattened = {};
      data.forEach((cat, boxes) {
        if (boxes is Map) {
          boxes.forEach((boxId, boxData) {
            flattened["$cat/$boxId"] = Map<String, dynamic>.from(boxData);
          });
        }
      });
      if (mounted) setState(() => _units = flattened);
    });

    _waterSub = _dbRef.child("device/sensor_live/water").onValue.listen((
      event,
    ) {
      final val = event.snapshot.value;
      if (mounted && val != null) {
        setState(() => _waterLevel = double.tryParse(val.toString()) ?? 100.0);
      }
    });
  }

  void _syncTempThresholds() {
    if (_selectedCategoryId != null && _plantTypes != null) {
      final cat = _plantTypes![_selectedCategoryId];
      setState(() {
        _tempMin = (cat['moisture_min'] ?? 40).toDouble();
        _tempMax = (cat['moisture_max'] ?? 80).toDouble();
      });
    }
  }

  // ── LOGIC ────────────────────────────────────────────────────────────────

  Future<void> _startTimer(String boxPath, int minutes) async {
    if (_waterLevel < 5) {
      _toast(
        "GAGAL: Air tersisa ${_waterLevel.toInt()}%. Isi dulu!",
        Colors.red,
      );
      return;
    }
    final currentMoisture = (_units[boxPath]?['moisture'] ?? 0).toDouble();
    if (currentMoisture >= _tempMax) {
      _toast(
        "Kelembapan sudah max (${currentMoisture.toInt()}%).",
        Colors.orange,
      );
      return;
    }
    final now = DateTime.now();
    final fmt = DateFormat('HH:mm:ss');
    await _dbRef.child("device/control/manualTimer/$boxPath").set({
      "startTime": fmt.format(now),
      "endTime": fmt.format(now.add(Duration(minutes: minutes))),
      "duration": minutes,
      "isactive": true,
    });
    await _dbRef.child("device/units/$boxPath").update({"pump_status": true});
    _toast("Pompa berjalan $minutes menit", AppColors.info);
  }

  Future<void> _stopTimer(String boxPath) async {
    await _dbRef.child("device/control/manualTimer/$boxPath").update({
      "isactive": false,
      "endTime": DateFormat('HH:mm:ss').format(DateTime.now()),
      "duration": 0,
    });
    await _dbRef.child("device/units/$boxPath").update({"pump_status": false});
    _toast("Pompa dihentikan", Colors.redAccent);
  }

  Future<void> _addNewUnit() async {
    if (_selectedCategoryId == null) return;
    final catData = _plantTypes![_selectedCategoryId];
    final String catPath = (catData['label'] ?? 'unknown')
        .toString()
        .toLowerCase()
        .replaceAll(' ', '_');
    int maxNum = 0;
    _units.keys.where((k) => k.startsWith("$catPath/")).forEach((k) {
      final num = int.tryParse(k.split("/")[1].replaceAll("box_", "")) ?? 0;
      if (num > maxNum) maxNum = num;
    });
    final newBoxNumber = (maxNum + 1).toString().padLeft(2, '0');
    await _dbRef.child("device/units/$catPath/box_$newBoxNumber").set({
      "auth_uid": "UID_BOX_${newBoxNumber}_XYZ",
      "control": {},
      "plant_type_id": _selectedCategoryId,
      "moisture": 0,
      "pump_status": false,
      "last_sync": DateTime.now().toIso8601String(),
    });
    _toast("Unit baru ditambahkan", AppColors.primary);
  }

  Future<void> _saveThreshold() async {
    await _dbRef.child("config/plant_types/$_selectedCategoryId").update({
      "moisture_min": _tempMin.toInt(),
      "moisture_max": _tempMax.toInt(),
    });
    setState(() => _isEditingThreshold = false);
    _toast("Konfigurasi diperbarui", AppColors.primary);
  }

  void _toast(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  // ── SELECTED CATEGORY DATA ────────────────────────────────────────────────

  String get _catLabel {
    if (_selectedCategoryId == null || _plantTypes == null) return '';
    return _plantTypes![_selectedCategoryId]?['label']?.toString() ?? '';
  }

  String get _catPath =>
      _catLabel.toLowerCase().replaceAll(RegExp(r'\s+'), '_');

  List<MapEntry<String, dynamic>> get _currentBoxes =>
      _units.entries.where((e) => e.key.startsWith("$_catPath/")).toList();

  // ── BUILD ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 2,
              ),
            )
          : CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildAppBar(),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildConfigCard(),
                        const SizedBox(height: 20),
                        _buildPlanterBoxesSection(),
                        const SizedBox(height: 28),
                        _buildGlobalConnectivity(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  // ── APP BAR ───────────────────────────────────────────────────────────────

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 130,
      pinned: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      elevation: 0,
      scrolledUnderElevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 24, bottom: 16),
        title: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "INDUSTRIAL ARCHITECTURE",
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.6,
                color: AppColors.primary,
              ),
            ),
            Text(
              "Multi-Planter Box",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Theme.of(context).textTheme.bodyLarge?.color ?? AppColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── CONFIG CARD ───────────────────────────────────────────────────────────

  Widget _buildConfigCard() {
    return _FadeSlide(
      delay: 0,
      child: _card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "$_catLabel Configuration",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Theme.of(context).textTheme.bodyLarge?.color ?? AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Atur parameter dan kelola unit planter box untuk kategori ini.",
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6) ?? Colors.grey[500],
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Category dropdown
            _categoryDropdown(),

            const SizedBox(height: 24),
            Divider(height: 1, color: Theme.of(context).dividerColor.withOpacity(0.15)),
            const SizedBox(height: 20),

            // MOISTURE THRESHOLDS
            Row(
              children: [
                Text(
                  "MOISTURE THRESHOLDS",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: Colors.grey[500],
                  ),
                ),
                const Spacer(),
                _editThresholdButton(),
              ],
            ),
            const SizedBox(height: 16),

            // Threshold display / edit
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 350),
              crossFadeState: _isEditingThreshold
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: _thresholdDisplay(),
              secondChild: _thresholdSliders(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _categoryDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.05) : AppColors.ink,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
      ),
      child: DropdownButton<String>(
        value: _selectedCategoryId,
        underline: const SizedBox(),
        isExpanded: false,
        dropdownColor: Theme.of(context).colorScheme.surface,
        icon: Icon(
          Icons.keyboard_arrow_down_rounded,
          color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.white70,
          size: 20,
        ),
        selectedItemBuilder: (context) {
          return _plantTypes?.keys.map((k) {
            return Row(
              children: [
                const Text("🪴", style: TextStyle(fontSize: 14)),
                const SizedBox(width: 8),
                Text(
                  (_plantTypes![k]['label'] ?? '').toString(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.white,
                  ),
                ),
              ],
            );
          }).toList() ?? [];
        },
        items: _plantTypes?.keys
            .map(
              (k) => DropdownMenuItem(
                value: k.toString(),
                child: Row(
                  children: [
                    const Text("🪴", style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 8),
                    Text(
                      (_plantTypes![k]['label'] ?? '').toString(),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).textTheme.bodyLarge?.color ?? AppColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
        onChanged: (v) => setState(() {
          _selectedCategoryId = v;
          _syncTempThresholds();
        }),
      ),
    );
  }

  Widget _editThresholdButton() {
    return GestureDetector(
      onTap: () => setState(() => _isEditingThreshold = !_isEditingThreshold),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: _isEditingThreshold
              ? AppColors.red.withOpacity(0.1)
              : AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _isEditingThreshold
                ? Colors.redAccent.withOpacity(0.3)
                : AppColors.primaryLight,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _isEditingThreshold ? Icons.close_rounded : Icons.tune_rounded,
              size: 14,
              color: _isEditingThreshold
                  ? Colors.redAccent
                  : AppColors.primaryDark,
            ),
            const SizedBox(width: 6),
            Text(
              _isEditingThreshold ? "Batal" : "Edit Threshold",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _isEditingThreshold
                    ? Colors.redAccent
                    : AppColors.primaryDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _thresholdDisplay() {
    return Column(
      children: [
        _thresholdRow(
          label: "LOWER LIMIT (MIN)",
          value: _tempMin,
          color: AppColors.orange,
          icon: Icons.water_drop_outlined,
        ),
        const SizedBox(height: 16),
        _thresholdRow(
          label: "UPPER LIMIT (MAX)",
          value: _tempMax,
          color: AppColors.info,
          icon: Icons.waves_rounded,
        ),
      ],
    );
  }

  Widget _thresholdRow({
    required String label,
    required double value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "${value.toInt()}%",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: color,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
          Icon(icon, color: color.withOpacity(0.5), size: 28),
        ],
      ),
    );
  }

  Widget _thresholdSliders() {
    return StatefulBuilder(
      builder: (ctx, setLocal) => Column(
        children: [
          _sliderRow("MIN", _tempMin, AppColors.orange, (v) {
            setLocal(() => _tempMin = v);
            setState(() => _tempMin = v);
          }),
          const SizedBox(height: 12),
          _sliderRow("MAX", _tempMax, AppColors.info, (v) {
            setLocal(() => _tempMax = v);
            setState(() => _tempMax = v);
          }),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              onPressed: _saveThreshold,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryDark,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "Simpan Perubahan",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sliderRow(
    String label,
    double val,
    Color color,
    ValueChanged<double> onChanged,
  ) {
    return Row(
      children: [
        SizedBox(
          width: 34,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: Colors.grey[600],
            ),
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderThemeData(
              activeTrackColor: color,
              thumbColor: color,
              inactiveTrackColor: color.withOpacity(0.15),
              overlayColor: color.withOpacity(0.1),
              trackHeight: 4,
            ),
            child: Slider(value: val, min: 0, max: 100, onChanged: onChanged),
          ),
        ),
        SizedBox(
          width: 40,
          child: Text(
            "${val.toInt()}%",
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: color,
              fontSize: 13,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  // ── PLANTER BOXES SECTION ─────────────────────────────────────────────────

  Widget _buildPlanterBoxesSection() {
    final boxes = _currentBoxes;
    return _FadeSlide(
      delay: 150,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Text(
              "PLANTER BOXES",
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.4,
                color: Colors.grey[500],
              ),
            ),
          ),
          _card(
            padding: const EdgeInsets.all(0),
            child: Column(
              children: [
                // Boxes list
                if (boxes.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(
                          Icons.inbox_rounded,
                          size: 40,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Belum ada box",
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                      ],
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: boxes.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      indent: 20,
                      endIndent: 20,
                      color: Theme.of(context).dividerColor.withOpacity(0.15),
                    ),
                    itemBuilder: (context, i) {
                      final box = boxes[i];
                      return _FadeSlide(
                        delay: 200 + i * 80,
                        begin: const Offset(0.03, 0),
                        child: _boxCard(box.key, box.value),
                      );
                    },
                  ),

                // Tambah Box button
                Divider(height: 1, color: Theme.of(context).dividerColor.withOpacity(0.15)),
                GestureDetector(
                  onTap: _addNewUnit,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primary,
                              width: 1.5,
                            ),
                          ),
                          child: const Icon(
                            Icons.add_rounded,
                            size: 14,
                            color: Color(0xFF4CAF50),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          "Tambah Planter Box Baru",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF4CAF50),
                          ),
                        ),
                      ],
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

  Widget _boxCard(String path, Map data) {
    final bool isOn = data['pump_status'] ?? false;
    final double moisture = (data['moisture'] ?? 0).toDouble();
    final bool isOffline = _isBoxOffline(data);
    final String boxId = path
        .split("/")
        .last
        .toUpperCase()
        .replaceAll('_', '_');
    final String lastSync = _formatLastSync(data['last_sync']);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      color: isOn
          ? AppColors.info.withOpacity(0.08)
          : (isOffline ? AppColors.red.withOpacity(0.05) : Colors.transparent),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Box header
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        boxId,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Theme.of(context).textTheme.bodyLarge?.color ?? AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _PulsingDot(
                            color: isOffline
                                ? Colors.orange
                                : (isOn
                                      ? AppColors.info
                                      : AppColors.primary),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isOffline
                                ? "OFFLINE"
                                : (isOn ? "ACTIVE" : "STANDBY"),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: isOffline
                                  ? Colors.orange
                                  : (isOn
                                        ? AppColors.info
                                        : AppColors.primary),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Delete
                GestureDetector(
                  onTap: () => _confirmDeleteBox(path),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      size: 16,
                      color: Colors.redAccent,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Moisture + Pump info
            Row(
              children: [
                // Arc moisture gauge
                _MoistureArc(
                  value: moisture,
                  min: _tempMin,
                  max: _tempMax,
                  size: 90,
                ),
                const SizedBox(width: 20),
                // Pump status + timer
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Pump status badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isOn
                              ? AppColors.info.withOpacity(0.1)
                              : AppColors.stroke,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isOn
                                  ? Icons.water_drop_rounded
                                  : Icons.water_drop_outlined,
                              size: 14,
                              color: isOn
                                  ? AppColors.secondary
                                  : Colors.grey[500],
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isOn ? "PUMP ON" : "PUMP OFF",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: isOn
                                    ? AppColors.secondary
                                    : Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Timer chips / stop
                      if (!isOn)
                        Wrap(
                          spacing: 6,
                          children: [5, 10, 15].map((m) {
                            final bool disabled =
                                moisture >= _tempMax || _waterLevel < 5;
                            return GestureDetector(
                              onTap: disabled
                                  ? null
                                  : () => _startTimer(path, m),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: disabled
                                      ? Theme.of(context).dividerColor.withOpacity(0.15)
                                      : AppColors.info.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  "${m}m",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: disabled
                                        ? Colors.grey[400]
                                        : AppColors.secondary,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        )
                      else
                        ElevatedButton.icon(
                          onPressed: () => _stopTimer(path),
                          icon: const Icon(Icons.stop_rounded, size: 14),
                          label: const Text(
                            "STOP",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Last updated
            Row(
              children: [
                Text(
                  "LAST UPDATED",
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                    color: Colors.grey[400],
                  ),
                ),
                const Spacer(),
                Text(
                  lastSync,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  bool _isBoxOffline(Map data) {
    final ls = data['last_sync'];
    if (ls == null) return true;
    try {
      final dt = DateTime.parse(ls.toString());
      return DateTime.now().difference(dt).inHours > 1;
    } catch (_) {
      return true;
    }
  }

  String _formatLastSync(dynamic ls) {
    if (ls == null) return "Unknown";
    try {
      final dt = DateTime.parse(ls.toString());
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return "Just now";
      if (diff.inMinutes < 60) return "${diff.inMinutes} mins ago";
      if (diff.inHours < 24) return "${diff.inHours} hrs ago";
      return "${diff.inDays}d ago";
    } catch (_) {
      return "Unknown";
    }
  }

  void _confirmDeleteBox(String path) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Hapus Box?",
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: Text(
          "Yakin ingin menghapus ${path.split('/').last.toUpperCase()}?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Batal", style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              _dbRef.child("device/units/$path").remove();
            },
            child: const Text("Hapus", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── GLOBAL CONNECTIVITY ───────────────────────────────────────────────────

  Widget _buildGlobalConnectivity() {
    final sensors = [
      {
        'title': 'Global Light',
        'subtitle': 'LDR PHOTORESISTOR',
        'icon': Icons.wb_sunny_rounded,
        'color': AppColors.orange,
        'status': 'ACTIVE',
        'connectivity': 'STABLE',
      },
      {
        'title': 'Global Water',
        'subtitle': 'LOAD CELL 10KG',
        'icon': Icons.storage_rounded,
        'color': AppColors.info,
        'status': 'ACTIVE',
        'connectivity': _waterLevel < 5 ? 'WARNING' : 'STABLE',
      },
      {
        'title': 'Global Power',
        'subtitle': 'INTERNAL BATTERY',
        'icon': Icons.battery_charging_full_rounded,
        'color': AppColors.primary,
        'status': 'ACTIVE',
        'connectivity': 'STABLE',
      },
    ];

    return _FadeSlide(
      delay: 300,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Global Connectivity Status",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Theme.of(context).textTheme.bodyLarge?.color ?? AppColors.ink,
            ),
          ),
          const SizedBox(height: 14),
          ...sensors.asMap().entries.map((e) {
            final s = e.value;
            final isWarning = s['connectivity'] == 'WARNING';
            final color = s['color'] as Color;
            return _FadeSlide(
              delay: 350 + e.key * 80,
              child: _connectivityCard(
                title: s['title'] as String,
                subtitle: s['subtitle'] as String,
                icon: s['icon'] as IconData,
                color: color,
                status: s['status'] as String,
                connectivity: s['connectivity'] as String,
                isWarning: isWarning,
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _connectivityCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required String status,
    required String connectivity,
    required bool isWarning,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top accent bar
          Container(
            height: 3,
            decoration: BoxDecoration(
              color: isWarning ? Colors.orange : AppColors.primary,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: color, size: 22),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isWarning
                            ? AppColors.orange.withOpacity(0.1)
                            : AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: isWarning
                              ? Colors.orange[700]
                              : AppColors.primaryDark,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Theme.of(context).textTheme.bodyLarge?.color ?? AppColors.ink,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Divider(height: 1, color: Theme.of(context).dividerColor.withOpacity(0.15)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text(
                      "CONNECTIVITY",
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                        color: Colors.grey[400],
                      ),
                    ),
                    const Spacer(),
                    _PulsingDot(
                      color: isWarning
                          ? Colors.orange
                          : AppColors.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      connectivity,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: isWarning
                            ? Colors.orange
                            : AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── HELPERS ───────────────────────────────────────────────────────────────

  Widget _card({required Widget child, EdgeInsetsGeometry? padding}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
