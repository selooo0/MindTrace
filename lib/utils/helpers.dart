import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:crime_endless/Models/chat_message.dart';
import 'package:crime_endless/Models/clue_model.dart';
import 'package:crime_endless/Models/susbect_data.dart';
import 'package:crime_endless/Models/text_clue.dart';
import 'package:crime_endless/utils/db_helper.dart';
import 'package:crime_endless/utils/strings.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:string_similarity/string_similarity.dart';

// show a popup when a clue gets discovered
void showClueDialog(BuildContext context, ClueModel clue) {
  markClueDiscovered(clue.id, true);
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (_) => Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.blueAccent,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.blueAccent.withOpacity(0.6),
              blurRadius: 12,
              spreadRadius: 1,
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              clue.description ?? '',
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
            Divider(color: Colors.blueAccent),
            const SizedBox(height: 10),
            Text(
              'Found at: ${clue.found_at}\nRelevance: ${clue.relevance}',
              style: TextStyle(color: Colors.white70, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
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

// show a popup when a text clue gets opened used in susbect profile
void showTextClueDialog(BuildContext context, TextClueModel clue) {
  markClueDiscovered(clue.id, false);
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (_) => Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.blueAccent,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.blueAccent.withOpacity(0.6),
              blurRadius: 12,
              spreadRadius: 1,
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              clue.description ?? '',
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
            Divider(color: Colors.blueAccent),
            const SizedBox(height: 10),
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

// mark new clue discovered
Future<void> markClueDiscovered(String clueId, bool type) async {
  final prefs = await SharedPreferences.getInstance();
  String clueKey = prefsKey;
  dynamic list = prefs.getStringList(clueKey) ?? [];

  if (!type) {
    clueKey = textCluesKey;
    list = prefs.getStringList(clueKey) ?? [];
  }

  if (!list.contains(clueId)) {
    list.add(clueId);
    await prefs.setStringList(clueKey, list);
  }
}

// load all discovered clues from shared preferences
Future<List<String>> getDiscoveredClues(bool type) async {
  final prefs = await SharedPreferences.getInstance();
  String key = prefsKey;
  if (!type) key = textCluesKey;
  return prefs.getStringList(key) ?? [];
}

// load text clues
Future<List<TextClueModel>> getTextClues() async {
  final prefs = await SharedPreferences.getInstance();
  final textCluesJson = prefs.getString('textClues');
  final rawClues = textCluesJson != null
      ? List<Map<String, dynamic>>.from(jsonDecode(textCluesJson))
      : [];

  final textClues = rawClues.map((e) => TextClueModel.fromMap(e)).toList();
  return textClues;
}

// load clue image based on its name
getClueImage(String id) {
  String result = 'assets/images/car.png';
  if (id == 'car') {
    result = 'assets/images/car.png';
  } else if (id == 'knife') {
    result = 'assets/images/knife.png';
  } else if (id == 'bloodStain') {
    result = 'assets/images/bloodStain.png';
  } else if (id == 'bullet') {
    result = 'assets/images/bullet.png';
  } else if (id == 'bloodyCloth') {
    result = 'assets/images/bloodyCloth.png';
  } else if (id == 'gun') {
    result = 'assets/images/gun.png';
  } else if (id == 'moneyPile') {
    result = 'assets/images/moneyPile.png';
  }

  return result;
}

// load discovered clues from database
Future<List<dynamic>> getDiscoveredClueModels(
    bool type, String ownerName) async {
  final discoveredIds = await getDiscoveredClues(type);
  final db = DBHelper();
  final prefs = await SharedPreferences.getInstance();
  final stroyId = prefs.getInt("storyId");
  final story = await db.getStoryWithDetails(stroyId!);

  dynamic allClues;
  if (type)
    allClues = story!['clues'];
  else {
    allClues = story!['textClues'];
  }
  final filtered = allClues
      .where((c) => discoveredIds.contains(c.id) && c.owner == ownerName)
      .toList();

  return filtered;
}

// handle arabic and english special characters in chatgpt response
String normalizeText(String text) {
  text = text.toLowerCase();
  text = text.replaceAll(RegExp(r'[ًٌٍَُِْـ]'), '');
  text = text.replaceAll(RegExp(r'\bال'), '');
  text = text.trim();
  return text;
}

// check similarity between each hints and user question
bool isCloseQuestion(String question, TextClueModel hint) {
  question = normalizeText(question);
  final hintText = normalizeText(hint.description);


  final questionWords = question.split(RegExp(r'\s+'));
  final hintWords = hintText.split(RegExp(r'\s+'));

  int matches = 0;

  for (var hw in hintWords) {
    for (var qw in questionWords) {
      final similarity = hw.similarityTo(qw);
      if (similarity >= 0.7) matches++;
    }
  }

  print("matches: $matches");


  return matches >= 2;
}

// check if the game already solved or not
Future<bool> isEndGame() async {
  final db = DBHelper();
  final prefs = await SharedPreferences.getInstance();
  final stroyId = prefs.getInt("storyId");
  final allClues =
      (await db.getStoryWithDetails(stroyId!))!['clues'] as List<ClueModel>;
  final allTextClues = (await db.getStoryWithDetails(stroyId))!['textClues']
      as List<TextClueModel>;

  final discoveredClues = await getDiscoveredClues(true);
  final discoveredTextClues = await getDiscoveredClues(false);

  return discoveredClues.length >= allClues.length &&
      discoveredTextClues.length >= allTextClues.length;
}
// check if a user logged in or not
Future<bool> isUserLoggedIn() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.containsKey('userId');
}

// The OpenAI key is passed at run time and is never stored in the code:
// flutter run --dart-define=OPENAI_API_KEY=your_key_here
Future<String> fetchApiKey() async {
  const key = String.fromEnvironment('OPENAI_API_KEY');
  if (key.isEmpty) {
    throw Exception(
        "Missing OpenAI key. Run with --dart-define=OPENAI_API_KEY=your_key");
  }
  return key;
}
