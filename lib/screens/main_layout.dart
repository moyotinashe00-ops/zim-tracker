import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:zim_tracker/theme/volt_theme.dart';
import 'package:zim_tracker/screens/home_screen.dart';
import 'package:zim_tracker/screens/schedule_screen.dart';
import 'package:zim_tracker/screens/alerts_screen.dart';
import 'package:zim_tracker/screens/atlas_screen.dart';
import 'package:zim_tracker/screens/tools_screen.dart';
import 'package:zim_tracker/screens/auth_screen.dart';
import 'package:zim_tracker/services/auth_service.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  static MainLayoutState? of(BuildContext context) =>
      context.findAncestorStateOfType<MainLayoutState>();

  @override
  State<MainLayout> createState() => MainLayoutState();
}

class MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;
  final AuthService _authService = AuthService();

  void setTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  final List<Widget> _screens = [
    const HomeScreen(),
    const ScheduleScreen(),
    const ToolsScreen(),
    const AlertsScreen(),
    const AtlasScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authService.user,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: VoltTheme.obsidian,
            body: Center(child: CircularProgressIndicator(color: VoltTheme.cyberBlue)),
          );
        }

        if (!snapshot.hasData) {
          return const AuthScreen();
        }

        return Scaffold(
          body: _screens[_currentIndex],
          bottomNavigationBar: Container(
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.white10, width: 1),
              ),
            ),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              backgroundColor: VoltTheme.obsidian,
              selectedItemColor: VoltTheme.cyberBlue,
              unselectedItemColor: VoltTheme.textDim,
              type: BottomNavigationBarType.fixed,
              selectedLabelStyle: VoltTheme.dataStyle.copyWith(fontSize: 8),
              unselectedLabelStyle: VoltTheme.dataStyle.copyWith(fontSize: 8),
              onTap: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              items: const [
                BottomNavigationBarItem(icon: Icon(LucideIcons.home, size: 20), label: 'DASHBOARD'),
                BottomNavigationBarItem(icon: Icon(LucideIcons.calendar, size: 20), label: 'CHRONOS'),
                BottomNavigationBarItem(icon: Icon(LucideIcons.calculator, size: 20), label: 'TOOLS'),
                BottomNavigationBarItem(icon: Icon(LucideIcons.bell, size: 20), label: 'PULSE'),
                BottomNavigationBarItem(icon: Icon(LucideIcons.map, size: 20), label: 'ATLAS'),
              ],
            ),
          ),
        );
      },
    );
  }
}
