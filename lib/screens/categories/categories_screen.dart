import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';
import '../../core/constants.dart';

// --- 1. MODEL DATA ---
class PlantCategory {
  final String key;
  final String label;
  final int id;
  final int moistureMin;
  final int moistureMax;
  final int createdAt;

  PlantCategory({
    required this.key,
    required this.label,
    required this.id,
    required this.moistureMin,
    required this.moistureMax,
    required this.createdAt,
  });

  factory PlantCategory.fromMap(String key, Map data) {
    return PlantCategory(
      key: key,
      label: data['label'] ?? '',
      id: data['id'] ?? 0,
      moistureMin: data['moisture_min'] ?? 40,
      moistureMax: data['moisture_max'] ?? 80,
      createdAt: data['createdAt'] ?? 0,
    );
  }
}

// --- 2. STAT CARD WIDGET ---
class _StatCard extends StatefulWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String label;
  final int value;
  final int delay;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    required this.value,
    required this.delay,
  });

  @override
  State<_StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<_StatCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.9, end: 1.0).animate(
            CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.3 : 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: widget.iconBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(widget.icon, color: widget.iconColor, size: 22),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6) ?? Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 4),
                _AnimatedCounter(value: widget.value),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- 3. ANIMATED COUNTER ---
class _AnimatedCounter extends StatefulWidget {
  final int value;
  const _AnimatedCounter({required this.value});

  @override
  State<_AnimatedCounter> createState() => _AnimatedCounterState();
}

class _AnimatedCounterState extends State<_AnimatedCounter>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _anim = Tween<double>(
      begin: 0,
      end: widget.value.toDouble(),
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Text(
        _anim.value.toInt().toString(),
        style: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: Theme.of(context).textTheme.bodyLarge?.color ?? AppColors.ink,
          height: 1.1,
        ),
      ),
    );
  }
}

// --- 4. ROW ANIMASI UNTUK LIST ---
class _AnimatedRow extends StatefulWidget {
  final Widget child;
  final int index;
  const _AnimatedRow({required this.child, required this.index});

  @override
  State<_AnimatedRow> createState() => _AnimatedRowState();
}

class _AnimatedRowState extends State<_AnimatedRow>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0.05, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    Future.delayed(Duration(milliseconds: 100 + widget.index * 80), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _fade,
    child: SlideTransition(
      position: _slide,
      child: Transform.scale(
        scale: 0.95 + (0.05 * _ctrl.value),
        child: widget.child,
      ),
    ),
  );
}

// --- 5. MAIN PAGE ---
class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  List<PlantCategory> _categories = [];
  Map<String, dynamic> _flatUnits = {};
  bool _isLoading = true;
  String _searchTerm = "";

  // Dummy schedule data (replace with real Firebase if needed)
  int _activeSchedules = 0;
  int _inactiveSchedules = 0;

  late StreamSubscription _typesSub;
  late StreamSubscription _unitsSub;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() {
    _typesSub = _dbRef.child("config/plant_types").onValue.listen((event) {
      final data = event.snapshot.value as Map? ?? {};
      List<PlantCategory> temp = [];
      data.forEach((key, value) {
        temp.add(PlantCategory.fromMap(key, Map<String, dynamic>.from(value)));
      });
      temp.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      if (mounted)
        setState(() {
          _categories = temp;
          _isLoading = false;
        });
    });

    _unitsSub = _dbRef.child("device/units").onValue.listen((event) {
      final data = event.snapshot.value as Map? ?? {};
      Map<String, dynamic> flattened = {};
      data.forEach((catKey, boxes) {
        if (boxes is Map) {
          boxes.forEach((boxId, boxData) {
            flattened["$catKey/$boxId"] = boxData;
          });
        }
      });
      if (mounted) setState(() => _flatUnits = flattened);
    });
  }

  @override
  void dispose() {
    _typesSub.cancel();
    _unitsSub.cancel();
    super.dispose();
  }

  // --- LOGIC ---
  Future<void> _saveCategory(
    String? existingKey,
    String label, {
    int moistureMin = 40,
    int moistureMax = 80,
  }) async {
    if (label.trim().isEmpty) return;
    String newIdPath = label
        .trim()
        .replaceAll(RegExp(r'\s+'), '_')
        .toLowerCase();
    int maxId = 0;
    for (var cat in _categories) {
      if (cat.id > maxId) maxId = cat.id;
    }
    final data = {
      "label": label,
      "moisture_min": moistureMin,
      "moisture_max": moistureMax,
    };
    if (existingKey == null) {
      data["id"] = maxId + 1;
      data["createdAt"] = DateTime.now().millisecondsSinceEpoch;
      await _dbRef.child("config/plant_types/$newIdPath").set(data);
    } else {
      await _dbRef.child("config/plant_types/$existingKey").update(data);
    }
  }

  Future<void> _deleteCategory(PlantCategory cat) async {
    String catPath = cat.label.replaceAll(RegExp(r'\s+'), '_').toLowerCase();
    int relatedBoxes = _flatUnits.keys
        .where((k) => k.startsWith("$catPath/"))
        .length;
    if (relatedBoxes > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Gagal: Kategori masih digunakan oleh $relatedBoxes box.",
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }
    await _dbRef.child("config/plant_types/${cat.key}").remove();
  }

  // --- BOTTOM SHEET FORM ---
  void _showForm(PlantCategory? cat) {
    final labelCtrl = TextEditingController(text: cat?.label ?? "");
    int minVal = cat?.moistureMin ?? 40;
    int maxVal = cat?.moistureMax ?? 80;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            left: 24,
            right: 24,
            top: 8,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20, top: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.eco_rounded,
                      color: AppColors.primaryDark,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    cat == null ? "Kategori Baru" : "Edit Kategori",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Label field
              TextField(
                controller: labelCtrl,
                autofocus: true,
                style: const TextStyle(fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  labelText: "Nama Tanaman",
                  labelStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
                  prefixIcon: const Icon(
                    Icons.local_florist_rounded,
                    color: AppColors.primary,
                  ),
                  filled: true,
                  fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.05) : AppColors.background,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey[200]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Moisture Min Slider
              _buildSliderField(
                label: "Moisture Min",
                value: minVal.toDouble(),
                color: AppColors.orange,
                onChanged: (v) => setModal(() => minVal = v.round()),
              ),
              const SizedBox(height: 12),
              // Moisture Max Slider
              _buildSliderField(
                label: "Moisture Max",
                value: maxVal.toDouble(),
                color: AppColors.info,
                onChanged: (v) => setModal(() => maxVal = v.round()),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryDark,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    _saveCategory(
                      cat?.key,
                      labelCtrl.text,
                      moistureMin: minVal,
                      moistureMax: maxVal,
                    );
                    Navigator.pop(ctx);
                  },
                  child: const Text(
                    "Simpan Data",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSliderField({
    required String label,
    required double value,
    required Color color,
    required ValueChanged<double> onChanged,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
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
            child: Slider(
              value: value,
              min: 0,
              max: 100,
              divisions: 20,
              onChanged: onChanged,
            ),
          ),
        ),
        SizedBox(
          width: 44,
          child: Text(
            "${value.round()}%",
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: color,
              fontSize: 13,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  // --- DELETE CONFIRM DIALOG ---
  void _confirmDelete(PlantCategory cat) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Hapus Kategori?",
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: Text("Yakin ingin menghapus \"${cat.label}\"?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Batal", style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            onPressed: () {
              Navigator.pop(context);
              _deleteCategory(cat);
            },
            child: const Text("Hapus", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- BUILD ---
  @override
  Widget build(BuildContext context) {
    final filtered = _categories
        .where((c) => c.label.toLowerCase().contains(_searchTerm.toLowerCase()))
        .toList();

    int totalBoxes = _flatUnits.length;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 2.5,
              ),
            )
          : CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // --- APP BAR ---
                SliverAppBar(
                  expandedHeight: 130,
                  pinned: true,
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  elevation: 0,
                  scrolledUnderElevation: 0,
                  flexibleSpace: FlexibleSpaceBar(
                    titlePadding: const EdgeInsets.only(left: 24, bottom: 15),
                    title: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "MASTER DATA",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                            color: AppColors.primary,
                          ),
                        ),
                        Text(
                          "Plant Categories",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Theme.of(context).textTheme.bodyLarge?.color ?? AppColors.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- STATS GRID ---
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 14,
                          crossAxisSpacing: 14,
                          childAspectRatio: 1.35,
                          children: [
                            _StatCard(
                              icon: Icons.category_rounded,
                              iconColor: AppColors.primary,
                              iconBg: AppColors.primary.withOpacity(0.1),
                              label: "TOTAL CATEGORIES",
                              value: _categories.length,
                              delay: 0,
                            ),
                            _StatCard(
                              icon: Icons.inventory_2_rounded,
                              iconColor: AppColors.secondary,
                              iconBg: AppColors.secondary.withOpacity(0.1),
                              label: "TOTAL BOXES",
                              value: totalBoxes,
                              delay: 100,
                            ),
                            _StatCard(
                              icon: Icons.schedule_rounded,
                              iconColor: AppColors.accent,
                              iconBg: AppColors.accent.withOpacity(0.1),
                              label: "ACTIVE SCHEDULES",
                              value: _activeSchedules,
                              delay: 200,
                            ),
                            _StatCard(
                              icon: Icons.event_busy_rounded,
                              iconColor: AppColors.inkLighter,
                              iconBg: AppColors.stroke,
                              label: "INACTIVE SCHEDULES",
                              value: _inactiveSchedules,
                              delay: 300,
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // --- REGISTERED CATEGORIES CARD ---
                        Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.3 : 0.04),
                                blurRadius: 20,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Section Header
                                Text(
                                  "REGISTERED CATEGORIES",
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.2,
                                    color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6) ?? AppColors.inkSoft,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "Total: ${_categories.length} categories",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[500],
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Search + Add Button Row
                                Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.05) : AppColors.background,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: Theme.of(context).dividerColor.withOpacity(0.1),
                                          ),
                                        ),
                                        child: TextField(
                                          onChanged: (v) =>
                                              setState(() => _searchTerm = v),
                                          style: const TextStyle(fontSize: 14),
                                          decoration: InputDecoration(
                                            hintText: "Search categories...",
                                            hintStyle: TextStyle(
                                              color: Colors.grey[400],
                                              fontSize: 13,
                                            ),
                                            prefixIcon: Icon(
                                              Icons.search_rounded,
                                              color: Colors.grey[400],
                                              size: 20,
                                            ),
                                            border: InputBorder.none,
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  vertical: 12,
                                                ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    GestureDetector(
                                      onTap: () => _showForm(null),
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 200,
                                        ),
                                        height: 44,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryDark,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppColors.primaryDark.withOpacity(0.3),
                                              blurRadius: 12,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: const Row(
                                          children: [
                                            Icon(
                                              Icons.add_rounded,
                                              color: Colors.white,
                                              size: 18,
                                            ),
                                            SizedBox(width: 4),
                                            Text(
                                              "Add Category",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 16),

                                // Table Header
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).brightness == Brightness.dark
                                        ? Colors.white.withOpacity(0.05)
                                        : AppColors.background,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      _tableHeader("ID", flex: 1),
                                      _tableHeader("KATEGORI", flex: 3),
                                      _tableHeader("TOTAL BOX", flex: 2),
                                      _tableHeader(
                                        "MIN",
                                        flex: 2,
                                        color: AppColors.orange,
                                      ),
                                      _tableHeader(
                                        "MAX",
                                        flex: 2,
                                        color: AppColors.info,
                                      ),
                                      const SizedBox(width: 36),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 8),

                                // Table Rows
                                if (filtered.isEmpty)
                                  Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(32),
                                      child: Column(
                                        children: [
                                          Icon(
                                            Icons.search_off_rounded,
                                            size: 40,
                                            color: Colors.grey[300],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            "Tidak ada data",
                                            style: TextStyle(
                                              color: Colors.grey[400],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                else
                                  ListView.separated(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: filtered.length,
                                    separatorBuilder: (_, __) => Divider(
                                      height: 1,
                                      color: Theme.of(context).dividerColor.withOpacity(0.15),
                                    ),
                                    itemBuilder: (context, index) {
                                      final cat = filtered[index];
                                      String catPath = cat.label
                                          .replaceAll(RegExp(r'\s+'), '_')
                                          .toLowerCase();
                                      int boxCount = _flatUnits.keys
                                          .where(
                                            (k) => k.startsWith("$catPath/"),
                                          )
                                          .length;

                                      return _AnimatedRow(
                                        index: index,
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          onTap: () => _showForm(cat),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 14,
                                            ),
                                            child: Row(
                                              children: [
                                                // ID
                                                Expanded(
                                                  flex: 1,
                                                  child: Text(
                                                    cat.id.toString().padLeft(
                                                      2,
                                                      '0',
                                                    ),
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      color: Colors.grey[400],
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                                // Label
                                                Expanded(
                                                  flex: 3,
                                                  child: Text(
                                                    cat.label,
                                                    style: TextStyle(
                                                      fontSize: 15,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: Theme.of(context).textTheme.bodyLarge?.color ?? AppColors.ink,
                                                    ),
                                                  ),
                                                ),
                                                // Box count
                                                Expanded(
                                                  flex: 2,
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                          vertical: 3,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: AppColors.info.withOpacity(0.1),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            20,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      "$boxCount Box",
                                                      style: const TextStyle(
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        color: Color(
                                                          0xFF1565C0,
                                                        ),
                                                      ),
                                                      textAlign:
                                                          TextAlign.center,
                                                    ),
                                                  ),
                                                ),
                                                // Moisture Min
                                                Expanded(
                                                  flex: 2,
                                                  child: Text(
                                                    "${cat.moistureMin}%",
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: Color(0xFFFF7043),
                                                    ),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ),
                                                // Moisture Max
                                                Expanded(
                                                  flex: 2,
                                                  child: Text(
                                                    "${cat.moistureMax}%",
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: Color(0xFF42A5F5),
                                                    ),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ),
                                                // Delete
                                                GestureDetector(
                                                  onTap: () =>
                                                      _confirmDelete(cat),
                                                  child: Container(
                                                    width: 32,
                                                    height: 32,
                                                    decoration: BoxDecoration(
                                                      color: boxCount > 0
                                                          ? Theme.of(context).dividerColor.withOpacity(0.15)
                                                          : AppColors.red.withOpacity(0.1),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                    ),
                                                    child: Icon(
                                                      Icons
                                                          .delete_outline_rounded,
                                                      size: 16,
                                                      color: boxCount > 0
                                                          ? Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.3)
                                                          : Colors.redAccent,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _tableHeader(
    String text, {
    int flex = 1,
    Color color = AppColors.inkLighter,
  }) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          color: color,
        ),
      ),
    );
  }
}
