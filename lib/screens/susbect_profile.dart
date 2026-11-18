import 'package:crime_endless/Models/clue_model.dart';
import 'package:crime_endless/Models/susbect_data.dart';
import 'package:crime_endless/Models/text_clue.dart';
import 'package:crime_endless/utils/db_helper.dart';
import 'package:crime_endless/widgets/custom_app_bar.dart';
import 'package:crime_endless/utils/helpers.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SusbectProfile extends StatefulWidget {
  final SusbectData susbect;
  final image;
  const SusbectProfile({super.key, required this.susbect, required this.image});

  @override
  State<SusbectProfile> createState() => _SusbectProfileState();
}

class _SusbectProfileState extends State<SusbectProfile> {
  List<ClueModel> foundClues = [];
  List<ClueModel> filteredClues = [];
  List<TextClueModel> foundTextClues = [];
  List<TextClueModel> filteredTextClues = [];

  @override
  void initState() {
    super.initState();
    loadDiscoveredClues();
  }

  // load all discovered clues from database and filter them based on the susbect id
  // this allow us to show the discovered clues as an image and the undiscovered as a question mark (?)
  void loadDiscoveredClues() async {
    List<String> cluesId = await getDiscoveredClues(true);
    List<String> textCluesId = await getDiscoveredClues(false);

    final db = DBHelper();
    final prefs = await SharedPreferences.getInstance();
    final stroyId = prefs.getInt("storyId");
    final data = await db.getStoryWithDetails(stroyId!);
    List<ClueModel> clues = data!['clues'];
    List<TextClueModel> textClues = data!['textClues'];

    final fClues = clues
        .where((clue) =>
            cluesId.contains(clue.id) && clue.owner == widget.susbect.name)
        .toList();

    final allForOwner =
        clues.where((clue) => clue.owner == widget.susbect.name).toList();

    final remaining = allForOwner
        .where((clue) => !fClues.any((c) => c.id == clue.id))
        .toList();

    final fTextClues = textClues
        .where((clue) =>
            textCluesId.contains(clue.id) && clue.owner == widget.susbect.name)
        .toList();

    final allTextForOwner =
        textClues.where((clue) => clue.owner == widget.susbect.name).toList();

    final remainingText = allTextForOwner
        .where((clue) => !fTextClues.any((c) => c.id == clue.id))
        .toList();

    setState(() {
      foundClues = fClues;
      filteredClues = remaining;

      foundTextClues = fTextClues;
      filteredTextClues = remainingText;
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
        padding: EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Image.asset(
                widget.image,
                height: 300,
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 32.0, vertical: 8),
              child: Center(
                child: Text(
                  widget.susbect.name,
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Text(
                widget.susbect.relation,
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Text(
                widget.susbect.personality,
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Text(
                widget.susbect.alibi,
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Text(
                widget.susbect.motive,
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  // Found clues (real images)
                  ...foundClues.map((clue) => CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white,
                        child: InkWell(
                          onTap: () {
                            showClueDialog(context, clue);
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(3.0),
                            child: ClipOval(
                              child: Image.asset(
                                getClueImage(clue
                                    .id), // adjust if your clue images use id names
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      )),

                  ...foundTextClues.map((clue) => CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white,
                        child: InkWell(
                          onTap: () {
                            showTextClueDialog(context, clue);
                          },
                          child: Center(
                            child: Text(
                              clue.description.length > 2
                                  ? clue.description.substring(0, 2)
                                  : clue.description,
                              style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      )),

                  // Hidden clues (question marks)
                  ...filteredClues.map((_) => CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(3.0),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/qm.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      )),

                  ...filteredTextClues.map((_) => CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(3.0),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/qm.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
