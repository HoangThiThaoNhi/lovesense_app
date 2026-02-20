import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lovesense_app/services/profile_service.dart'; // Added
import 'home/home_tab.dart';
import 'journey/journey_tab.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'profile/profile_tab.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadUnsavedIndex();
  }

  Future<void> _loadUnsavedIndex() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _selectedIndex = prefs.getInt('last_tab_index') ?? 0;
      });
    }
  }

  late final List<Widget> _screens = [
    HomeTab(onNavigateToProfile: () => _onItemTapped(2)),
    const JourneyTab(),
    const ProfileTab(),
  ];

  void _onItemTapped(int index) async {
    setState(() {
      _selectedIndex = index;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('last_tab_index', index);
  }

  @override
  Widget build(BuildContext context) {
    // Removed blocking loading state for faster perceived load
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: _onItemTapped,
          backgroundColor: Colors.white,
          indicatorColor: const Color(0xFFFF4081).withOpacity(0.1),
          destinations: [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home, color: Color(0xFFFF4081)),
              label: 'Trang chủ',
            ),
            NavigationDestination(
              icon: Icon(Icons.map_outlined),
              selectedIcon: Icon(Icons.map, color: Color(0xFFFF4081)),
              label: 'Hành trình',
            ),
            NavigationDestination(
              icon: StreamBuilder<List<dynamic>>(
                // Use generic list to avoid import issues if RequestModel not imported,
                // but ProfileService().getPendingRequests() returns generic stream or list?
                // It returns Stream<List<RequestModel>>. We need to import RequestModel or use 'dynamic'.
                // Let's use dynamic to be safe or just import it. RequestModel is likely needed.
                // Assuming we can't easily add import top of file in this replace, let's try to use valid logic.
                stream: ProfileService().getPendingRequests(),
                builder: (context, snapshot) {
                  final hasRequests =
                      snapshot.hasData && snapshot.data!.isNotEmpty;
                  return Badge(
                    isLabelVisible: hasRequests,
                    label: Text('${snapshot.data?.length ?? 0}'),
                    child: const Icon(Icons.person_outline),
                  );
                },
              ),
              selectedIcon: StreamBuilder<List<dynamic>>(
                stream: ProfileService().getPendingRequests(),
                builder: (context, snapshot) {
                  final hasRequests =
                      snapshot.hasData && snapshot.data!.isNotEmpty;
                  return Badge(
                    isLabelVisible: hasRequests,
                    label: Text('${snapshot.data?.length ?? 0}'),
                    child: const Icon(Icons.person, color: Color(0xFFFF4081)),
                  );
                },
              ),
              label: 'Cá nhân',
            ),
          ],
        ),
      ).animate().slideY(begin: 1, end: 0, duration: 500.ms),
    );
  }
}
