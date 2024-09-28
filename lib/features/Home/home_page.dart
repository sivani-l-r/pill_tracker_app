import 'package:flutter/material.dart';
import 'package:pill_tracker/features/AddPill/add_pill.dart';
import 'package:pill_tracker/features/Home/home_screen.dart';
import 'package:pill_tracker/features/Profile/profile_page.dart';
import 'package:pill_tracker/features/Settings/settings_page.dart';
import 'package:pill_tracker/features/Stats/stats_page.dart';
import '../Login/login_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    HomeScreen(),
    Container(),
    StatsScreen(),
  ];

  void _onItemTapped(int index) {
    if (index == 1) {
      _showAddPillModal(context);
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        centerTitle: true,
        leading: PopupMenuButton<int>(
          onSelected: (item) => _onSelectedMenuItem(context, item),
          itemBuilder: (context) => [
            const PopupMenuItem<int>(value: 0, child: Text('Settings')),
            const PopupMenuItem<int>(value: 1, child: Text('Profile')),
          ],
          icon: const Icon(Icons.settings),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        elevation: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            label: 'Add Pill',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Stats',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blueAccent,
        onTap: _onItemTapped,
      ),
    );
  }

  void _showAddPillModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: AddPillForm(),
      ),
    );
  }

  void _onSelectedMenuItem(BuildContext context, int item) {
    switch (item) {
      case 0:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SettingsPage()),
        );
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ProfilePage()),
        );
        break;
    }
  }

  void _logout() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }
}
