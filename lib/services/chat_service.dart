import 'dart:convert';
import 'package:crime_endless/Models/susbect_data.dart';
import 'package:crime_endless/Models/text_clue.dart';
import 'package:crime_endless/Models/chat_message.dart';
import 'package:crime_endless/utils/db_helper.dart';
import 'package:crime_endless/utils/helpers.dart';
import 'package:crime_endless/utils/strings.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ChatService {
  static const String _apiKey = 'OPENAI_API_KEY';

  final String caseContext = '''
You are an NPC in a murder mystery game.
You are roleplaying ONLY the suspect below. 
Never speak as another suspect. 
Never reveal knowledge another suspect would not know. 
If the player asks something another suspect knows, reply:
"I cannot speak for others, detective."
Game rules:
- Stay in character for the suspect you are playing.
- Only answer questions relevant to the investigation.
- Answer the player question that is related to the case
- If the player goes off-topic, reply exactly: "Stay focused on the case, detective."
- Never reveal information about the case unless it has been discovered as a clue.
- Hints are only revealed when explicitly given by system with keyword [REVEAL_HINT]. Never reveal hints on your own.
- If the player asks close questions and the system did not send [REVEAL_HINT], respond normally without leaking hint.
- Do not invent evidence, places, or people not provided in clues.
- Collaborate with information based on how many clues found related to the speaker suspect.
- Keep answers short (2-3 sentences max) unless the detective presses for detail.
- Never reveal who the killer is unless explicitly caught with evidence.
- If the player confront the killer and all the clues and hints where found admit that you are the killer any write how you did the crime.
Important:
- Never switch character
- Never mention data about other suspects unless the detective explicitly states their name
- If you ever start speaking as another suspect, stop and correct yourself.
If you recieved EndGame and the player confronts you:
  - If IsKiller is true, write in response exactly [KILLER_FOUND] then admit being the killer and describe how you committed the crime.
  - If IsKiller is false, refuse to admit and stay in character.
''';

  // send last messages from user to chatgpt with suspects profiles and chat history
  // then receive a response form chatgpt and convert it to json format
  Future<ChatMessage> sendMessage(
      String suspectId, String userText, List<ChatMessage> history , int gameLanguage) async {

    final languageInstruction = gameLanguage == 1
?
    '''- You must ALWAYS respond in Arabic, no matter what language the player uses.
    - Important : Do not include English words or sentences in your responses'''
        :
    '''- You must ALWAYS respond in English, no matter what language the player uses.
    - Important : Do not include other languages words or sentences in your responses''';

    final db = DBHelper();
    final prefs = await SharedPreferences.getInstance();
    final stroyId = prefs.getInt("storyId");
    final storyData = await db.getStoryWithDetails(stroyId!);
    final clues = await getDiscoveredClues(true);
    final discoveredTextClues = await getDiscoveredClues(false);
    final suspects = storyData!['suspects'] as List<dynamic>? ?? [];
    final suspectData = suspects.firstWhere(
      (s) => s.name == suspectId,
      orElse: () => SusbectData(
        name: '',
        relation: '',
        alibi: '',
        motive: '',
        gender: '',
        personality: '',
      ),
    );

    if (suspectData.name.isEmpty) {
      return ChatMessage(role: 'ai', text: 'Error: Suspect data not found');
    }

    final recentMessages =
        history.length > 5 ? history.sublist(history.length - 5) : history;

    final buffer = StringBuffer();

    buffer.writeln(caseContext);
    buffer.writeln('Story summary: ${storyData['summary']}');

    buffer.writeln('''

 Suspect Identity:
Name: ${suspectData.name}
Relation: ${suspectData.relation}
Alibi: ${suspectData.alibi}
Personality: ${suspectData.personality}
''');

    final suspectTextClues =
        await getDiscoveredClueModels(false, suspectData.name);

    final suspectClues = await getDiscoveredClueModels(true, suspectData.name);

    final suspectCluesString = suspectClues.isEmpty
        ? "none"
        : suspectClues.map((c) => c.description).join(", ");

    final suspectTextCluesString = suspectTextClues.isEmpty
        ? "none"
        : suspectTextClues.map((c) => c.description).join(", ");

    buffer.writeln("Discovered clues: $suspectCluesString");
    buffer.writeln("Discovered hints: $suspectTextCluesString");

    for (var m in recentMessages) {
      final role = m.role == 'user' ? 'User' : 'AI';
      buffer.writeln('$role: ${m.text}');
    }
  buffer.writeln(languageInstruction);
// Add current user message last
    buffer.writeln('User: $userText');

    final bool endGame = await isEndGame();
    if (endGame) {
      buffer.writeln('EndGame: $endGame');
    }

    final fullMessage = buffer.toString();

    for (final hint in storyData["textClues"]) {
      if (discoveredTextClues.contains(hint.id)) continue;
      if (hint.owner != suspectData.name) continue;
      if (isCloseQuestion(userText, hint)) {
        markClueDiscovered(hint.id, false);
        return ChatMessage(
          role: 'ai',
          text: '[REVEAL_HINT] ${hint.description}',
          isClue: true,
        );
      }
    }
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
          {"role": "user", "content": fullMessage}
        ],
        "temperature": 0.7
      }),
    );

    if (res.statusCode != 200) {
      return ChatMessage(role: 'ai', text: 'Error: No response from server');
    }

    final jsonRes = jsonDecode(res.body);
    final content = jsonRes["choices"][0]["message"]["content"];

    final result = content.trim();
    bool isClue = false;

    return ChatMessage(role: 'ai', text: result, isClue: isClue);
  }
}
