import 'package:crime_endless/Models/susbect_data.dart';
import 'package:crime_endless/utils/db_helper.dart';
import 'package:crime_endless/widgets/custom_app_bar.dart';
import 'package:crime_endless/screens/susbect_profile.dart';
import 'package:crime_endless/utils/helpers.dart';
import 'package:crime_endless/widgets/wave_prgress_painter.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Inventory extends StatefulWidget {
  const Inventory({super.key});

  @override
  State<Inventory> createState() => _InventoryState();
}

class _InventoryState extends State<Inventory> {
  List<SusbectData> susbects = [];
  Map<String, double> progressMap = {};

  final List<String> profileSuspects = [
    'assets/images/boy.png',
    'assets/images/p1.png',
    'assets/images/p2.png',
    'assets/images/p4.png',
    'assets/images/p3.png',
    'assets/images/girl.png',
    'assets/images/g3.png',
    'assets/images/g1.png',
    'assets/images/g2.png',
  ];

  @override
  void initState() {
    super.initState();
    loadData();
  }

  // load story information
  void loadData() async {
    final db = await DBHelper();
    final prefs = await SharedPreferences.getInstance();
    final stroyId = prefs.getInt("storyId");
    final data = await db.getStoryWithDetails(stroyId!);

    final clues = data!['clues'];
    final textClues = data!['textClues'];
    final foundIds = await getDiscoveredClues(true);
    final foundTextIds = await getDiscoveredClues(false);

    final suspects = data['suspects'] as List<SusbectData>;

    // Calculate progress percentage per suspect
    Map<String, double> tempMap = {};
    for (var s in suspects) {
      final total = clues.where((c) => c.owner == s.name).length +
          textClues.where((c) => c.owner == s.name).length;
      final found = clues
              .where((c) => foundIds.contains(c.id) && c.owner == s.name)
              .length +
          textClues
              .where((c) => foundTextIds.contains(c.id) && c.owner == s.name)
              .length;
      final percent = total == 0 ? 0.0 : found / total;
      tempMap[s.name] = percent;
    }

    setState(() {
      susbects = suspects;
      progressMap = tempMap;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: CustomAppBar(
          appBar: AppBar(),
          canBack: false,
        ),
        body: Container(
          color: Colors.black87,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 3 / 4,
              children: susbects.map((s) {
                final index = susbects.indexOf(s);
                final image = profileSuspects[(s.gender == 'male' || s.gender == 'ذكر'
                    ? index
                    : index + 5 < profileSuspects.length
                        ? index + 5
                        : profileSuspects.length - 1)];
                final progress = progressMap[s.name] ?? 0.0;
                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SusbectProfile(
                          susbect: s,
                          image: image,
                        ),
                      ),
                    );
                  },
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CustomPaint(
                          painter: WaveProgressPainter(progress),
                          child: Container(
                            color: Colors.transparent,
                            height: double.infinity,
                            width: double.infinity,
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white24),
                          color:
                              Colors.transparent,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: ClipRRect(
                                  borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(12)),
                                  child: Image.asset(image, fit: BoxFit.cover)),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                s.name,
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16),
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Text(
                                s.relation,
                                style: TextStyle(
                                    color: Colors.white, fontSize: 16),
                              ),
                            ),
                            SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ));
  }
}
