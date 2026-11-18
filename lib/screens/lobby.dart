import 'dart:convert';
import 'package:crime_endless/screens/play_game.dart';
import 'package:crime_endless/utils/db_helper.dart';
import 'package:crime_endless/utils/strings.dart';
import 'package:http/http.dart' as http;
import 'package:crime_endless/screens/home.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/helpers.dart';

class Lobby extends StatefulWidget {
  const Lobby({super.key});

  @override
  State<Lobby> createState() => _LobbyState();
}

class _LobbyState extends State<Lobby> {
  List<List<int>> levels = [
    [3, 3, 3, -1],
    [4, 5, 5, 5],
    [5, 3, 5, 2]
  ];
  int level = 0;
  int gameLanguage = 0;
  late List<bool> isLoadingList;
  final stories = [
    'assets/images/story1.png',
    'assets/images/story2.png',
  ];
  String gameTitle = "Crime Story";

  String get storyPrompt {
    String languageInstruction = (gameLanguage == 1)
        ? "Respond in Arabic language."
        : "Respond in English language.";
    return """
You are an AI story generator for a murder mystery game.

TASK:
Generate a complete mystery scenario based only on this story title $gameTitle.
$languageInstruction
You must output the result in a **strictly structured JSON format** so it can be parsed programmatically in Flutter.

REQUIREMENTS:
1. Create a murder case with:
   - Victim details (name, age, cause of death, location)
   - ${levels[level][0]} suspects with short background, motive, and alibi
   - A logical connection between suspects and the victim
2. Insert **${levels[level][1]} clues** that appear in different parts of the story.
3. Ensure clues logically support or contradict alibis.
4. Generate **${levels[level][2]} hints** that will be revealed during chat with susbects.
5. Choose of these clues because i have prepared images for them (knife , bloodStain , car , bloodyCloth , bullet , gun , moneyPile)
6. The "id" field of every clue and hint must be exactly one of these values:
   ["knife", "bloodStain", "car", "bloodyCloth", "bullet", "gun", "moneyPile"].
7. write a hint for each clue and specify the clue owner.
8. Do not use the victim name as an owner for any clue or hint.
9. Do **not** reveal the killer directly.
10. Make the game level : ${(level == 0) ? 'Easy' : (level == 1)
        ? 'Medium'
        : 'Hard'}
11. Output in **JSON** only — no extra commentary.

OUTPUT FORMAT:
{
  "title": "<story title>",
  "victim": {
    "name": "",
    "age": "",
    "cause_of_death": "",
    "location": ""
  },
  "suspects": [
    {
      "name": "",
      "relation": "",
      "motive": "",
      "alibi": "",
      "gender" : "",
      "personality": ""
    }
  ],
  "clues": [
    {
      "id": "knife", // one of: knife, bloodStain, car, bloodyCloth, bullet, gun, moneyPile
      "description": "",
      "found_at": "",
      "relevance": "",
      "owner" : ""
    }
  ],
  "hints": [
    {
      "id": "clue1",
      "description": "",
      "owner" : ""
    }
  ],
  "story_summary": "<short 3-5 paragraph story that includes where each clue was found>"
}

RULES:
- Follow the JSON structure exactly.
- Do not add explanations or markdown formatting.
- Make sure each clue links to a place or suspect.
- Keep names realistic and consistent.

EXAMPLE INPUT:
Title: "The Silent Apartment"

EXAMPLE OUTPUT (truncated):
{
  "title": "The Silent Apartment",
  "victim": { "name": "Lina Hariri", "age": 38, "cause_of_death": "stab wound", "location": "her apartment" },
  "suspects": [
    { "name": "Omar Hariri", "relation": "husband", "motive": "jealousy", "alibi": "claims to be on a business trip", "gender" : "male", "personality": "defensive" },
    ...
  ],
  "clues": [
    { "id": "knife", "description": "A bloody kitchen knife", "found_at": "kitchen sink", "relevance": "matches victim’s wound" , "owner" : "Omar Hariri" },
    ...
  ],
  "hints": [
    { "id": "clue1", "description": "he did not agree to give me money", "owner" : "Omar Hariri" },
    ...
  ],
  "story_summary": "Police found Lina dead... (continues)"
}

INSTRUCTION TO MODEL:
Return **only** the JSON response.
""";
  }

  @override
  void initState() {
    super.initState();
    isLoadingList = List.generate(stories.length, (_) => false);
  }

  // call chat gpt and send story prompt and receive story details from it
  // then store the data in database and continue to the second page
  Future<bool> createNewStory(int l) async {
    print("start generating");
    final prefs = await SharedPreferences.getInstance();
    final body = jsonEncode({
      'message': storyPrompt,
    });
    final openAiApiKey = await fetchApiKey();
    final res = await http.post(
      Uri.parse("https://api.openai.com/v1/chat/completions"),
      headers: {
        'Content-Type': 'application/json',
        "Authorization": "Bearer $openAiApiKey",
      },
      body: jsonEncode({
        "model": "gpt-4o-mini",
        "messages": [
          {"role": "user", "content": storyPrompt}
        ],
        "temperature": 0.9
      }),
    );
    print('Status code: ${res.statusCode}');

    if (res.statusCode != 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Server error: ${res.statusCode}')),
      );
      return false;
    }

    dynamic resDecoded;
    try {
      resDecoded = jsonDecode(res.body);
    } catch (e) {
      print('JSON decode error: $e');
      return false;
    }
    if (resDecoded['status'] == 'error') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(resDecoded['error'] ?? 'Something went wrong'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return false;
    }

    final jsonRes = jsonDecode(res.body);
    final content = jsonRes["choices"][0]["message"]["content"];

    final cleaned =
        content.replaceAll('```json', '').replaceAll('```', '').trim();

    final data = jsonDecode(cleaned);

    if (data['title'] == null ||
        data['suspects'] == null ||
        data['clues'] == null) {
      return false;
    }

    final title = data['title'] ?? 'Untitled Story';
    final summary = data['story_summary'] ?? '';
    final suspects = data['suspects'] ?? [];
    final clues = data['clues'] ?? [];
    final textClues = data['hints'] ?? [];
    final victim = data['victim'] ?? [];

    print(title);
    print(summary);
    print(victim);
    print(suspects);
    print(clues);
    print(textClues);

    await prefs.clear();

    await prefs.setString('story_title', title);
    await prefs.setString('story_summary', summary);
    await prefs.setString('victim', jsonEncode(victim));
    await prefs.setString('suspects', jsonEncode(suspects));
    await prefs.setString('clues', jsonEncode(clues));
    await prefs.setString('textClues', jsonEncode(textClues));

    final db = DBHelper();
    final storyId = await db.insertStory(data, l , gameLanguage);
    await prefs.setInt('storyId', storyId);
    await prefs.setInt('gameLanguage' , gameLanguage);
    print("Saved story with ID $storyId");

    return true;
  }


  // this function gets called when start new game button gets clicked
  void startGame(BuildContext context, int l, int index , int lang) async {
    Navigator.pop(context);
    setState(() => isLoadingList[index] = true);
    level = l;
    gameLanguage = lang;
    try {
      bool res = true;
      res = await createNewStory(l);

      if (!mounted) return;
      if (res) {
        final prefs = await SharedPreferences.getInstance();
        prefs.setInt("GameLevel", l);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => PlayGame()),
        );
      }
      else {

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Could not load story, Check your internet connection.',
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );

      }
    } catch (e) {
      print(e);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not load story, Check your internet connection.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => isLoadingList[index] = false);
    }
  }

  // when start button gets clicked it call another function to show the level popup
  Future<void> handlePress(BuildContext context, int index) async {
    showLevelDialog(context, index);
  }

  // show level popup dialog
  void showLevelDialog(BuildContext context, int index) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => Dialog(
        insetPadding: EdgeInsets.zero,
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: Color(0xFF1A1A2E), // dark gaming background
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Select Case Difficulty',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      blurRadius: 4,
                      color: Colors.blueAccent,
                      offset: Offset(0, 0),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Container(
                        // padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.brown.shade200,
                        ),
                        child: Image.asset(
                          'assets/images/easy.png',
                          width: 140,
                          height: 140,
                          fit: BoxFit.cover,
                        )),
                    Expanded(
                      child: Container(
                        // padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.brown.shade100,
                        ),
                        height: 140,
                        child: Column(
                          spacing: 2,
                          children: [
                            Container(
                              alignment: Alignment.topRight,
                              child: Container(
                                  width: 60,
                                  padding: EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade800,
                                    borderRadius: BorderRadius.only(
                                        bottomLeft: Radius.circular(10)),
                                  ),
                                  child: Text(
                                    "Easy",
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                  )),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Row(
                                  children: [
                                    Image.asset(
                                      'assets/images/badge.png',
                                      width: 16,
                                      height: 16,
                                    ),
                                    Text('Susbects :'),
                                    Text(levels[0][0].toString()),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Image.asset(
                                      'assets/images/timer.png',
                                      width: 16,
                                      height: 16,
                                    ),
                                    Text('Time :'),
                                    Text('--'),
                                  ],
                                ),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Row(
                                  children: [
                                    Image.asset(
                                      'assets/images/search.png',
                                      width: 16,
                                      height: 16,
                                    ),
                                    Text('Clues :'),
                                    Text(levels[0][1].toString()),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Image.asset(
                                      'assets/images/hints.png',
                                      width: 16,
                                      height: 16,
                                    ),
                                    Text('Hints :'),
                                    Text(levels[0][2].toString()),
                                  ],
                                ),
                              ],
                            ),
                            Row(

                              children: [
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8),
                                alignment: Alignment.topRight,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blueAccent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: () => startGame(context, 0, index , 0),
                                  child: const Text(
                                    'English',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ),

                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                alignment: Alignment.topRight,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blueAccent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: () => startGame(context, 0, index , 1),
                                  child: const Text(
                                    'Arabic',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ),

                            ],),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Container(
                        child: Image.asset(
                      'assets/images/medium.jpg',
                      width: 140,
                      height: 140,
                      fit: BoxFit.cover,
                    )),
                    Expanded(
                      child: Container(
                        // padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade200,
                        ),
                        height: 140,
                        child: Column(
                          spacing: 2,
                          children: [
                            Container(
                              alignment: Alignment.topRight,
                              child: Container(
                                  width: 80,
                                  padding: EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade800,
                                    borderRadius: BorderRadius.only(
                                        bottomLeft: Radius.circular(10)),
                                  ),
                                  child: Text(
                                    "Medium",
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                  )),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Row(
                                  children: [
                                    Image.asset(
                                      'assets/images/badge.png',
                                      width: 16,
                                      height: 16,
                                    ),
                                    Text('Susbects :'),
                                    Text(levels[1][0].toString()),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Image.asset(
                                      'assets/images/timer.png',
                                      width: 16,
                                      height: 16,
                                    ),
                                    Text('Time :'),
                                    Text(levels[1][3].toString()),
                                  ],
                                ),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Row(
                                  children: [
                                    Image.asset(
                                      'assets/images/search.png',
                                      width: 16,
                                      height: 16,
                                    ),
                                    Text('Clues :'),
                                    Text(levels[1][1].toString()),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Image.asset(
                                      'assets/images/hints.png',
                                      width: 16,
                                      height: 16,
                                    ),
                                    Text('Hints :'),
                                    Text(levels[1][2].toString()),
                                  ],
                                ),
                              ],
                            ),
                            Row(children: [
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8),
                                alignment: Alignment.topRight,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blueAccent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: () => startGame(context, 1, index , 0),
                                  child: const Text(
                                    'English',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ),

                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                alignment: Alignment.topRight,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blueAccent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: () => startGame(context, 1, index , 1),
                                  child: const Text(
                                    'Arabic',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ),

                            ],),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Container(
                        child: Image.asset(
                      'assets/images/hard.jpg',
                      width: 140,
                      height: 140,
                      fit: BoxFit.cover,
                    )),
                    Expanded(
                      child: Container(
                        // padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade500,
                        ),
                        height: 140,
                        child: Column(
                          spacing: 2,
                          children: [
                            Container(
                              alignment: Alignment.topRight,
                              child: Container(
                                  width: 60,
                                  padding: EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade800,
                                    borderRadius: BorderRadius.only(
                                        bottomLeft: Radius.circular(10)),
                                  ),
                                  child: Text(
                                    "Hard",
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                  )),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Row(
                                  children: [
                                    Image.asset(
                                      'assets/images/badge.png',
                                      width: 16,
                                      height: 16,
                                    ),
                                    Text('Susbects :'),
                                    Text(levels[2][0].toString()),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Image.asset(
                                      'assets/images/timer.png',
                                      width: 16,
                                      height: 16,
                                    ),
                                    Text('Time :'),
                                    Text(levels[2][3].toString()),
                                  ],
                                ),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Row(
                                  children: [
                                    Image.asset(
                                      'assets/images/search.png',
                                      width: 16,
                                      height: 16,
                                    ),
                                    Text('Clues :'),
                                    Text(levels[2][1].toString()),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Image.asset(
                                      'assets/images/hints.png',
                                      width: 16,
                                      height: 16,
                                    ),
                                    Text('Hints :'),
                                    Text(levels[2][2].toString()),
                                  ],
                                ),
                              ],
                            ),
                            Row(children: [
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8),
                                alignment: Alignment.topRight,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blueAccent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: () => startGame(context, 2, index , 0),
                                  child: const Text(
                                    'English',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ),

                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                alignment: Alignment.topRight,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blueAccent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: () => startGame(context, 2, index , 1),
                                  child: const Text(
                                    'Arabic',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ),

                            ],),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Close',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text(
                'Choose a story',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: stories.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.asset(
                            stories[index],
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          bottom: 12,
                          right: 12,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            onPressed: isLoadingList[index]
                                ? null
                                : () => handlePress(context, index),
                            child: isLoadingList[index]
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Start',
                                    style: TextStyle(color: Colors.white),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      backgroundColor: const Color.fromARGB(255, 19, 19, 19),
    );
  }
}
