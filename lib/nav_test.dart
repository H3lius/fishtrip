import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Test Nav',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const NavTestScreen(),
    );
  }
}

class NavTestScreen extends StatefulWidget {
  const NavTestScreen({super.key});

  @override
  State<NavTestScreen> createState() => _NavTestScreenState();
}

class _NavTestScreenState extends State<NavTestScreen> {
  int _index = 0;

  final List<Widget> _screens = [
    Container(color: Colors.white, child: const Center(child: Text('Feed'))),
    Container(color: Colors.green, child: const Center(child: Text('Map'))),
    Container(color: Colors.blue, child: const Center(child: Text('Rules'))),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Feed'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map'),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Rules'),
        ],
      ),
    );
  }
}