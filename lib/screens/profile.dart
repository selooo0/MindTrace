import 'package:crime_endless/screens/login.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Models/user_model.dart';
import '../utils/db_helper.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {

  int currentXp = 120;
  int maxXp = 200;
  int gamesPlayed = 50;
  int wins = 22;
  int totalProgress = 14;
  UserModel? user;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  // load user information from database such as user name and winned games
  Future<void> loadData() async {
    final sharedPrefrences = await SharedPreferences.getInstance();
    final db = DBHelper();
    final userId = sharedPrefrences.getString("userId");
    final u = await db.getUser(userId!);
    final pg = await db.getPlayedGamesCount();
    final winnedGames = await db.getWinnedGamesCount();

    setState(() {
      user = u;
      gamesPlayed = pg;
      wins = winnedGames;

      maxXp = pg * 100;
      currentXp = winnedGames * 100 + (pg - winnedGames) * 40;

      totalProgress = (maxXp == 0)
          ? 0
          : ((currentXp / maxXp) * 100).floor();
    });
  }



  @override
  Widget build(BuildContext context) {
    double xpPercent = currentXp / maxXp;
    int level = (currentXp / 100).floor() + 1;

    return Scaffold(

      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Profile Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF0F3460),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: AssetImage('assets/images/person.png'),
                  ),
                  const SizedBox(height: 15),

                  Text(
                    user?.name ?? "Unknown",
                    style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    user?.email ?? "Unknown",
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 14),
                  ),

                  Text(
                    "Age: ${user!.age}" ?? '0',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Level Label
                  Text(
                    "Level $level",
                    style: const TextStyle(
                        fontSize: 18,
                        color: Colors.amber,
                        fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 8),

                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: LinearProgressIndicator(
                      value: xpPercent,
                      backgroundColor: Colors.white24,
                      color: Colors.amber,
                      minHeight: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "$currentXp / $maxXp XP",
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Stats
            const Text(
              "Player Stats",
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF0F3460),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _statItem(Icons.videogame_asset, "Games", gamesPlayed),
                  _statItem(Icons.military_tech, "Wins", wins),
                  _statItem(Icons.trending_up, "Progress", totalProgress),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Badges
            const Text(
              "Badges",
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF0F3460),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 12,

                children: [
                  const _Badge(icon: Icons.star, label: "Rookie"),
                  if(gamesPlayed > 1)
                  const _Badge(icon: Icons.flash_on, label: "Master"),
                  if(gamesPlayed > 2 && wins > 1)
                  const _Badge(icon: Icons.shield, label: "Expert"),
                  if(gamesPlayed > 3 && wins > 2)
                  const _Badge(icon: Icons.security, label: "Legend"),
                  if(gamesPlayed > 5 && wins > 3)
                  const _Badge(icon: Icons.flight_takeoff, label: "Grand Master"),

                ],
              ),
            ),
        Padding(
          padding: const EdgeInsets.only(top: 16.0),
          child: ElevatedButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();

              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => Login()),
                    (route) => false,
              );
            },
            child: Text("Logout"),
          ),
        ),

          ],
        ),
      ),
    );
  }

  Widget _statItem(IconData icon, String title, int value) {
    return Column(
      children: [
        Icon(icon, size: 34, color: Colors.amber),
        const SizedBox(height: 5),
        Text(
          "$value${(title == "Progress") ? ' %' : ''}",
          style: const TextStyle(
              fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
        ),
        Text(
          title,
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        )
      ],
    );
  }
}

// badge component
class _Badge extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Badge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: Colors.white24,
          child: Icon(icon, color: Colors.amber, size: 30),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        )
      ],
    );
  }
}
