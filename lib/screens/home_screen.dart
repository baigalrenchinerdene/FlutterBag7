import 'package:flutter/material.dart';
import '../services/api.dart';
import 'my_appointments_screen.dart';
import 'salon_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_tab == 0 ? 'Find a salon' : 'My appointments'),
        actions: const [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: Auth.signOut,
          ),
        ],
      ),
      // Pages are rebuilt when you switch tabs, so data is always fresh.
      body: _tab == 0 ? const SalonListScreen() : const MyAppointmentsScreen(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.storefront_outlined), label: 'Salons'),
          NavigationDestination(
              icon: Icon(Icons.event_note_outlined), label: 'Appointments'),
        ],
      ),
    );
  }
}
