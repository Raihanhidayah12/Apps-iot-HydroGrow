import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'login_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../../core/constants.dart';
import '../../widgets/custom_drawer.dart';
import '../monitoring/monitoring_screen.dart';
import '../device/device_screen.dart';
import '../schedule/schedule_screen.dart';
import '../alerts/alerts_screen.dart';
import '../support/support_screen.dart' as support_module;
import '../categories/categories_screen.dart';
import '../../providers/theme_provider.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Jika user sudah login
        if (snapshot.hasData && snapshot.data != null) {
          return const MainScreen();
        }

        // Jika user belum login
        return const LoginScreen();
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const MonitoringScreen(),
    const CategoriesPage(),
    const DevicePage(),
    const ScheduleScreen(),
    const AlertsScreen(),
    const support_module.SupportPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;
        final themeProvider = context.watch<ThemeProvider>();
        final isDark = themeProvider.isDarkMode;

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(80),
            child: Container(
              margin: EdgeInsets.only(
                left: isWide ? 20 : 20,
                right: isWide ? 20 : 20,
                top: 16,
                bottom: 8,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface.withOpacity(0.7),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark ? Colors.white10 : Colors.white,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark ? Colors.black26 : AppColors.ink.withOpacity(0.06),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: isDark ? Colors.white10 : Colors.white, width: 1.5),
                ),
                child: AppBar(
                    title: Text(
                      _getTitle(_selectedIndex),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: isDark ? AppColors.inkDark : AppColors.ink,
                        letterSpacing: -0.5,
                      ),
                    ),
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    iconTheme: IconThemeData(
                      color: isDark ? AppColors.inkDark : AppColors.ink,
                      size: 24,
                    ),
                    centerTitle: false,
                    titleSpacing: 8,
                    actions: [
                      // Theme Toggle
                      IconButton(
                        onPressed: () => themeProvider.toggleTheme(),
                        icon: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          transitionBuilder: (child, anim) => RotationTransition(
                            turns: anim,
                            child: FadeTransition(opacity: anim, child: child),
                          ),
                          child: Icon(
                            isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                            key: ValueKey(isDark),
                            color: isDark ? Colors.amber : AppColors.inkMid,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: InkWell(
                          onTap: () => _showProfileEditSheet(context),
                          borderRadius: BorderRadius.circular(30),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                      Text(
                                        FirebaseAuth.instance.currentUser?.displayName ?? "Admin",
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w900,
                                          color: isDark ? AppColors.inkDark : AppColors.ink,
                                        ),
                                      ),
                                    const Text(
                                      "OPERATOR",
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.primary,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 10),
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryLight,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary.withOpacity(0.15),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.person_rounded,
                                    color: AppColors.primaryDark,
                                    size: 20,
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
            ),
          drawer: isWide
              ? null
              : CustomDrawer(
                  currentIndex: _selectedIndex,
                  onItemTapped: _onItemTapped,
                ),
          body: isWide
              ? Row(
                  children: [
                    Container(
                      margin: const EdgeInsets.fromLTRB(20, 0, 0, 20),
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: isDark ? Colors.black12 : AppColors.ink.withOpacity(0.04),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                      child: NavigationRail(
                        backgroundColor: Colors.transparent,
                        selectedIndex: _selectedIndex,
                        onDestinationSelected: _onItemTapped,
                        labelType: NavigationRailLabelType.all,
                        useIndicator: true,
                        indicatorColor: AppColors.primaryLight,
                        selectedIconTheme: const IconThemeData(
                          color: AppColors.primaryDark,
                          size: 28,
                        ),
                        unselectedIconTheme: IconThemeData(
                          color: isDark ? AppColors.inkSoftDark : AppColors.inkLighter,
                          size: 24,
                        ),
                        selectedLabelTextStyle: const TextStyle(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                        ),
                        unselectedLabelTextStyle: TextStyle(
                          color: isDark ? AppColors.inkSoftDark : AppColors.inkLighter,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                        ),
                        destinations: [
                          _railDest(Icons.grid_view_rounded, 'Home'),
                          _railDest(Icons.analytics_rounded, 'Data'),
                          _railDest(Icons.eco_rounded, 'Crops'),
                          _railDest(Icons.settings_input_component_rounded, 'Device'),
                          _railDest(Icons.calendar_today_rounded, 'Plan'),
                          _railDest(Icons.notifications_active_rounded, 'Alerts'),
                          _railDest(Icons.forum_rounded, 'AI Help'),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 10),
                        child: _screens[_selectedIndex],
                      ),
                    ),
                  ],
                )
              : _screens[_selectedIndex],
        );
      },
    );
  }

  NavigationRailDestination _railDest(IconData icon, String label) {
    return NavigationRailDestination(
      icon: Icon(icon),
      label: Text(label),
    );
  }

  String _getTitle(int index) {
    switch (index) {
      case 0:
        return 'Dashboard';
      case 1:
        return 'Monitoring';
      case 2:
        return 'Categories';
      case 3:
        return 'Device';
      case 4:
        return 'Schedule';
      case 5:
        return 'Alerts';
      case 6:
        return 'Support';
      default:
        return 'HydroGrow';
    }
  }

  void _showProfileEditSheet(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final nameController =
        TextEditingController(text: user?.displayName ?? "Admin");
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.stroke,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  "Edit Profil",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 32),
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.15),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.person_rounded,
                        color: AppColors.primaryDark,
                        size: 50,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: nameController,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                  decoration: InputDecoration(
                    labelText: "Nama Lengkap",
                    hintText: "Masukkan nama kamu",
                    labelStyle: const TextStyle(color: AppColors.inkSoft),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(
                      Icons.badge_outlined,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: isSaving
                        ? null
                        : () async {
                            setSheetState(() => isSaving = true);
                            try {
                              await user?.updateDisplayName(nameController.text);
                              if (context.mounted) {
                                Navigator.pop(context);
                                setState(() {}); // Refresh navbar
                              }
                            } catch (e) {
                              print("Error updating profile: $e");
                            } finally {
                              setSheetState(() => isSaving = false);
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: isSaving
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            "Simpan Perubahan",
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
