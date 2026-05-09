import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:http/http.dart' as http;
import '../core/constants.dart';
import '../screens/auth/login_screen.dart';

// =============================================================================
// CUSTOM DRAWER - HYDROGROW V2 ANIMATED
// Added: Breathing Glow, Staggered Entrance, Elastic Logo, Tap Feedback
// =============================================================================

class CustomDrawer extends StatefulWidget {
  final int currentIndex;
  final Function(int) onItemTapped;

  const CustomDrawer({
    super.key,
    required this.currentIndex,
    required this.onItemTapped,
  });

  @override
  State<CustomDrawer> createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer>
    with TickerProviderStateMixin {
  // 1. Tambahkan 2 Controller untuk animasi masuk dan efek denyut (pulse)
  late AnimationController _entranceController;
  late AnimationController _pulseController;

  // Modern Color Palette
  static const Color _deepDark = Color(0xFF050A08);
  static const Color _cardDark = Color(0xFF0D1410);
  static const Color _surfaceDark = Color(0xFF131A15);
  static const Color _green = Color(0xFF10B981);
  static const Color _greenBright = Color(0xFF34D399);
  static const Color _greenDim = Color(0xFF059669);
  static const Color _textWhite = Color(0xFFF0FDF4);
  static const Color _textGray = Color(0xFF6B7280);
  static const Color _textMuted = Color(0xFF374151);
  static const Color _borderColor = Color(0xFF1F2937);

  // Live Data
  String _temperature = "--°C";
  bool _isLoadingWeather = true;
  int _lightValue = 0;
  int _waterLevel = 0;

  final DatabaseReference _sensorRef = FirebaseDatabase.instance.ref(
    'device/sensor_live',
  );

  @override
  void initState() {
    super.initState();

    // Animasi saat drawer dibuka (berjalan 1x)
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    // Animasi denyut (breathing) untuk indikator sensor aktif (berulang)
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _fetchWeather();
    _listenToFirebaseSensors();
  }

  void _listenToFirebaseSensors() {
    _sensorRef.onValue.listen((DatabaseEvent event) {
      if (event.snapshot.value != null) {
        final data = Map<dynamic, dynamic>.from(event.snapshot.value as Map);
        if (mounted) {
          setState(() {
            _lightValue = data['light'] ?? 0;
            _waterLevel = data['water'] ?? 0;
          });
        }
      }
    });
  }

  Future<void> _fetchWeather() async {
    const url =
        "https://api.open-meteo.com/v1/forecast?latitude=-7.9525&longitude=112.6144&current_weather=true";
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _temperature = "${data['current_weather']['temperature']}°C";
            _isLoadingWeather = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _temperature = "Err";
          _isLoadingWeather = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: _deepDark,
      elevation: 0,
      width: MediaQuery.of(context).size.width * 0.85,
      child: Container(
        decoration: const BoxDecoration(color: _deepDark),
        child: SafeArea(
          child: Column(
            children: [
              _buildModernHeader(),
              const SizedBox(height: 4),
              _buildSectionDivider(),
              const SizedBox(height: 16),
              Expanded(child: _buildNavigationList()),
              _buildBottomSection(context),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // MODERN HEADER WITH ANIMATION
  // ===========================================================================
  Widget _buildModernHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Elastic Logo Animation
              ScaleTransition(
                scale: CurvedAnimation(
                  parent: _entranceController,
                  curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
                ),
                child: AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: _green,
                        boxShadow: [
                          BoxShadow(
                            // Logo memancarkan cahaya hijau pelan-pelan
                            color: _green.withOpacity(
                              0.2 + (_pulseController.value * 0.3),
                            ),
                            blurRadius: 15 + (_pulseController.value * 10),
                            spreadRadius: 1 + (_pulseController.value * 2),
                          ),
                        ],
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(13),
                          color: _cardDark,
                        ),
                        child: Image.asset(
                          'assets/images/icon.png',
                          width: 24,
                          height: 24,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 14),
              // Fade In Text
              Expanded(
                child: FadeTransition(
                  opacity: CurvedAnimation(
                    parent: _entranceController,
                    curve: const Interval(0.2, 0.7, curve: Curves.easeIn),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "HydroGrow",
                        style: TextStyle(
                          fontFamily: AppFonts.spaceGrotesk,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: _textWhite,
                          letterSpacing: -1.0,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              color: _green,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: _green.withOpacity(0.8),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 7),
                          const Text(
                            "PRECISION IOT",
                            style: TextStyle(
                              fontFamily: AppFonts.manrope,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: _green,
                              letterSpacing: 2.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Stats card with Drop Down Animation
          SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(0, -0.2),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: _entranceController,
                    curve: const Interval(0.3, 0.8, curve: Curves.easeOutBack),
                  ),
                ),
            child: FadeTransition(
              opacity: CurvedAnimation(
                parent: _entranceController,
                curve: const Interval(0.3, 0.8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _surfaceDark.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _borderColor.withOpacity(0.3),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildFloatingStat(
                          "Light",
                          "$_lightValue",
                          Icons.wb_sunny_outlined,
                          isActive: _lightValue >= 50,
                          activeColor: const Color(0xFFFBBF24),
                        ),
                        _buildStatDivider(),
                        _buildFloatingStat(
                          "Water",
                          "$_waterLevel%",
                          Icons.water_drop_outlined,
                          isActive:
                              _waterLevel >
                              0, // <-- Diubah agar nyala biru selama ada air
                          activeColor: const Color(0xFF3B82F6),
                        ),
                        _buildStatDivider(),
                        _buildFloatingStat(
                          "Temp",
                          _isLoadingWeather ? "..." : _temperature,
                          Icons.thermostat_outlined,
                          isActive: !_isLoadingWeather,
                          activeColor: const Color(0xFFEF4444),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingStat(
    String label,
    String value,
    IconData icon, {
    bool isActive = false,
    Color activeColor = _green,
  }) {
    // Breathing Animation menggunakan AnimatedBuilder
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final glowIntensity = isActive ? _pulseController.value : 0.0;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isActive ? activeColor.withOpacity(0.15) : _cardDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isActive
                        ? activeColor.withOpacity(0.3 + (glowIntensity * 0.2))
                        : _borderColor,
                    width: 1.5,
                  ),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: activeColor.withOpacity(
                              0.1 + (glowIntensity * 0.25),
                            ), // Efek nafas menyala
                            blurRadius: 10 + (glowIntensity * 10),
                            spreadRadius: glowIntensity * 2,
                          ),
                        ]
                      : [],
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: isActive ? activeColor : _textMuted,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontFamily: AppFonts.spaceGrotesk,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: _textWhite,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontFamily: AppFonts.manrope,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: isActive ? activeColor.withOpacity(0.8) : _textMuted,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatDivider() {
    return Container(
      width: 1,
      height: 40,
      color: _borderColor.withOpacity(0.5),
    );
  }

  Widget _buildSectionDivider() {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.4, 0.9),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            Expanded(
              child: Container(height: 1, color: _borderColor.withOpacity(0.3)),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                "MENU",
                style: TextStyle(
                  fontFamily: AppFonts.manrope,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: _textMuted,
                  letterSpacing: 3.0,
                ),
              ),
            ),
            Expanded(
              child: Container(height: 1, color: _borderColor.withOpacity(0.3)),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // STAGGERED NAVIGATION LIST
  // ===========================================================================
  Widget _buildNavigationList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildModernNavItem(
            0,
            Icons.dashboard_outlined,
            Icons.dashboard_rounded,
            "Dashboard",
            0.4,
          ),
          _buildModernNavItem(
            1,
            Icons.sensors_outlined,
            Icons.sensors,
            "Monitoring",
            0.5,
          ),
          _buildModernNavItem(
            2,
            Icons.category_outlined,
            Icons.category_rounded,
            "Categories",
            0.6,
          ),
          _buildModernNavItem(
            3,
            Icons.developer_board_outlined,
            Icons.developer_board,
            "Device",
            0.7,
          ),
          _buildModernNavItem(
            4,
            Icons.event_note_outlined,
            Icons.event_note_rounded,
            "Schedule",
            0.8,
          ),
          _buildModernNavItem(
            5,
            Icons.notifications_outlined,
            Icons.notifications_rounded,
            "Alerts",
            0.9,
          ),
        ],
      ),
    );
  }

  Widget _buildModernNavItem(
    int index,
    IconData icon,
    IconData activeIcon,
    String label,
    double startInterval,
  ) {
    final isSelected = widget.currentIndex == index;
    // Hitung waktu selesai animasi
    final endInterval = (startInterval + 0.3).clamp(0.0, 1.0);

    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(-0.2, 0), end: Offset.zero)
          .animate(
            CurvedAnimation(
              parent: _entranceController,
              curve: Interval(
                startInterval,
                endInterval,
                curve: Curves.easeOutCubic,
              ),
            ),
          ),
      child: FadeTransition(
        opacity: CurvedAnimation(
          parent: _entranceController,
          curve: Interval(startInterval, endInterval, curve: Curves.easeOut),
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                widget.onItemTapped(index);
                Navigator.pop(context);
              },
              borderRadius: BorderRadius.circular(16),
              splashColor: _green.withOpacity(0.1),
              highlightColor: _green.withOpacity(0.05),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutBack,
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? _green.withOpacity(0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? _green.withOpacity(0.3)
                        : Colors.transparent,
                    width: 1,
                  ),
                  // Efek glow untuk menu terpilih
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: _green.withOpacity(0.15),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [],
                ),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves
                          .easeOutBack, // Icon agak membal ketika disorot/dipilih
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: isSelected ? _green : _cardDark,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? _green.withOpacity(0.5)
                              : _borderColor,
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        isSelected ? activeIcon : icon,
                        size: 20,
                        color: isSelected ? Colors.white : _textMuted,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: TextStyle(
                          fontFamily: AppFonts.manrope,
                          fontSize: isSelected
                              ? 16
                              : 15, // Teks membesar sedikit jika dipilih
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w600,
                          color: isSelected ? _textWhite : _textGray,
                          letterSpacing: -0.3,
                        ),
                        child: Text(label),
                      ),
                    ),
                    if (isSelected)
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          return Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: _greenBright,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: _green.withOpacity(
                                    0.5 + (_pulseController.value * 0.5),
                                  ),
                                  blurRadius: 5 + (_pulseController.value * 5),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // BOTTOM SECTION WITH SLIDE UP ANIMATION
  // ===========================================================================
  Widget _buildBottomSection(BuildContext context) {
    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero)
          .animate(
            CurvedAnimation(
              parent: _entranceController,
              curve: const Interval(0.6, 1.0, curve: Curves.easeOutCubic),
            ),
          ),
      child: FadeTransition(
        opacity: CurvedAnimation(
          parent: _entranceController,
          curve: const Interval(0.6, 1.0),
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: _borderColor.withOpacity(0.3), width: 1),
            ),
            color: Colors.black.withOpacity(0.1),
          ),
          child: Column(
            children: [
              _buildBottomItem(
                context,
                index: 6,
                icon: Icons.headset_mic_outlined,
                activeIcon: Icons.headset_mic_rounded,
                label: "Support",
                color: const Color(0xFF3B82F6),
              ),
              const SizedBox(height: 10),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _showModernLogoutDialog(context),
                  borderRadius: BorderRadius.circular(16),
                  splashColor: Colors.red.withOpacity(0.1),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFEF4444).withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFEF4444).withOpacity(0.3),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.logout_rounded,
                            size: 20,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Text(
                          "Log Out",
                          style: TextStyle(
                            fontFamily: AppFonts.manrope,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFEF4444),
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
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

  Widget _buildBottomItem(
    BuildContext context, {
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required Color color,
  }) {
    final isSelected = widget.currentIndex == index;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          widget.onItemTapped(index);
          Navigator.pop(context);
        },
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutBack,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? color.withOpacity(0.3) : Colors.transparent,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isSelected ? color : _cardDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _borderColor, width: 1),
                ),
                child: Icon(
                  isSelected ? activeIcon : icon,
                  size: 20,
                  color: isSelected ? Colors.white : _textMuted,
                ),
              ),
              const SizedBox(width: 14),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontFamily: AppFonts.manrope,
                  fontSize: isSelected ? 16 : 15,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isSelected ? _textWhite : _textGray,
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // MODERN LOGOUT DIALOG
  // ===========================================================================
  void _showModernLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: _surfaceDark.withOpacity(0.95),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: _borderColor.withOpacity(0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 40,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFEF4444).withOpacity(0.4),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.logout_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Keluar dari sesi?",
                  style: TextStyle(
                    fontFamily: AppFonts.spaceGrotesk,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: _textWhite,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Kamu akan diarahkan kembali ke halaman login dan perlu masuk lagi.",
                  style: TextStyle(
                    fontFamily: AppFonts.manrope,
                    fontSize: 14,
                    color: _textGray,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: _borderColor.withOpacity(0.5),
                          ),
                          foregroundColor: _textGray,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          "Batal",
                          style: TextStyle(
                            fontFamily: AppFonts.manrope,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEF4444),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () async {
                          Navigator.pop(context);
                          await FirebaseAuth.instance.signOut();
                          if (context.mounted) {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const LoginScreen(),
                              ),
                              (route) => false,
                            );
                          }
                        },
                        child: const Text(
                          "Log Out",
                          style: TextStyle(
                            fontFamily: AppFonts.manrope,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
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
    );
  }
}
