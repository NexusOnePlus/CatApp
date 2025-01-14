import 'package:cat_app/pages/favorites.dart';
import 'package:cat_app/pages/home.dart';
import 'package:cat_app/pages/settings.dart';
import 'package:flutter/material.dart';

class NavigationBarPages extends StatefulWidget {
  const NavigationBarPages({super.key});

  @override
  State<NavigationBarPages> createState() => _NavigationBarPagesState();
}

class _NavigationBarPagesState extends State<NavigationBarPages> {
  int thecurrentIndex = 0;
  List pages = [
    HomePage(),
    Favorites(),
    Settings()
  ];



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: Container(
        margin: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 30,
              offset: const Offset(0, 20)
            )
          ]
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),

          child: BottomNavigationBar(
            currentIndex: thecurrentIndex,
            backgroundColor: Colors.white,
            selectedItemColor: Colors.orange,
            unselectedItemColor: Colors.black,
            selectedFontSize: 12,
            showSelectedLabels: true,
            showUnselectedLabels: false,
            onTap: (index)  {
              setState(() {
                thecurrentIndex = index;
              });
            },
            items: [
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.favorite_border_outlined), label: 'Favorites'),
            BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: 'Settings')
          ]),
        ),
      ),
      body: pages[thecurrentIndex],
    );
  }
}