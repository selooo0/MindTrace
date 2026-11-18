import 'package:crime_endless/screens/lobby.dart';
import 'package:crime_endless/screens/login.dart';
import 'package:crime_endless/screens/saved_games.dart';
import 'package:crime_endless/screens/profile.dart';
import 'package:crime_endless/utils/helpers.dart';
import 'package:crime_endless/widgets/custom_app_bar.dart';
import 'package:flutter/material.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  int _selectedIndex = 1;

  // Bottom Bar pages
  final List<Widget> _pages = [
    SavedGames(),
    Lobby(),
    Profile(),
  ];

  // open a page
  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  void initState() {
    super.initState();
    checkUserLoggedIn();

  }

  // check if user not logged in then redirect him to log in page
  void checkUserLoggedIn() async {
    bool check = await isUserLoggedIn();
    if (!check) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => Login(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        appBar: AppBar(),
      ),
      // body: PlayGame(),
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Color.fromARGB(255, 63, 0, 100),
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(
                Icons.save,
              ),
              label: 'Saved'),
          BottomNavigationBarItem(
              icon: Icon(
                Icons.map,
              ),
              label: 'Game'),
          BottomNavigationBarItem(
              icon: Icon(
                Icons.person,
              ),
              label: 'Profile'),
        ],
      ),
    );
  }
}
