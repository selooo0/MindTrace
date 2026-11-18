import 'package:crime_endless/screens/play_game.dart';
import 'package:crime_endless/utils/db_helper.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SavedGames extends StatefulWidget {
  const SavedGames({super.key});

  @override
  State<SavedGames> createState() => _SavedGamesState();
}

class _SavedGamesState extends State<SavedGames> {
  final DBHelper _dbHelper = DBHelper();
  List<Map<String, dynamic>> _stories = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStories();
  }

  // load all saved games
  Future<void> _loadStories() async {
    final stories = await _dbHelper.getAllStories();
    setState(() {
      _stories = stories;
      _loading = false;

    });
  }

  // this function opens the play game screen when the resume button gets clicked
  void _openStory(BuildContext context, Map<String, dynamic> story) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('storyId', story['id']);
    await prefs.setInt("GameLevel", story['level']);
    await prefs.setInt("gameLanguage", story['language']);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PlayGame()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: _stories.isEmpty
          ? const Center(
              child: Text(
                'No saved stories found.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(12.0),
              child: ListView.builder(
                itemCount: _stories.length,
                itemBuilder: (context, index) {
                  final story = _stories[index];
                  final title = story['title'] ?? 'Untitled Story';
                  final summary = story['summary'] ?? 'No summary available.';
                  final level = story['level'];
                  final language = story['language'] ?? 0;
                  final timeEnd = story['remaining_seconds'] ?? 0;
                  final isSolved = story['is_solved'] ?? false;

                  return GestureDetector(
                    // onTap: () => _openStory(context, story),
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          )
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 90,
                            height: 90,
                            margin: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              image: const DecorationImage(
                                image: AssetImage('assets/images/story1.png'),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12, horizontal: 4),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    summary,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,

                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(

                                            children: [
                                              const Icon(Icons.folder_open,
                                                  color: Colors.blueAccent,
                                                  size: 18),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Level: ${(level == 0) ? 'Easy' : (level == 1) ? 'Medium' : 'Hard'}',
                                            style: const TextStyle(
                                                color: Colors.white54,
                                                fontSize: 12),
                                          ),
                                            ],
                                          ),
                                          Row(

                                            children: [
                                              const Icon(Icons.language,
                                                  color: Colors.blueAccent,
                                                  size: 18),
                                          const SizedBox(width: 4),

                                          Text(
                                        'Language: ${language == 0 ? 'English' : 'Arabic'}',
                                        style: const TextStyle(
                                          color: Colors.white54,
                                          fontSize: 12,
                                        ),
                                      ),
                                            ],
                                          ),
                                                                              ],
                                                                            ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(

                                          backgroundColor: (isSolved ) ?
                                          Colors.green
                                              :
                                          (timeEnd <= 5) ?
                                          Colors.red :
                                          Colors.blueAccent
                                          ,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                        ),
                                        onPressed:  (timeEnd <= 5) ? null : () =>
                                        _openStory(context, story),
                                        child: Text(
                                          (isSolved ) ?
                                              'Game Solved'
                                              :
                                          (timeEnd > 5) ?
                                          'Resume'
                                              :
                                            'Time Ended',
                                          style: TextStyle(
                                              color: Colors.white,

                                              fontSize: 12),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
      backgroundColor: const Color(0xFF0F0F1B),
    );
  }
}
