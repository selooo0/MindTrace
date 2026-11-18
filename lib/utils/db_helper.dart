import 'package:crime_endless/Models/chat_message.dart';
import 'package:crime_endless/Models/clue_model.dart';
import 'package:crime_endless/Models/susbect_data.dart';
import 'package:crime_endless/Models/text_clue.dart';
import 'package:crime_endless/Models/user_model.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DBHelper {
  static Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await initDB();
    return _db!;
  }




  // create database tables

  Future<Database> initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'mindtrace.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            email TEXT,
            password TEXT,
            age TEXT
          )
        ''');

        await db.execute('''
CREATE TABLE stories (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT,
  summary TEXT,
  level INTEGER,
  language INTEGER
);
''');

        await db.execute('''
CREATE TABLE victims (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  story_id INTEGER,
  name TEXT,
  age TEXT,
  cause_of_death TEXT,
  location TEXT,
  FOREIGN KEY(story_id) REFERENCES stories(id)
);
''');

        await db.execute('''
CREATE TABLE suspects (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  story_id INTEGER,
  name TEXT,
  relation TEXT,
  motive TEXT,
  alibi TEXT,
  gender TEXT,
  personality TEXT,
  FOREIGN KEY(story_id) REFERENCES stories(id)
);
''');

        await db.execute('''
CREATE TABLE clues (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  story_id INTEGER,
  clue_id TEXT,
  description TEXT,
  found_at TEXT,
  relevance TEXT,
  owner TEXT,
  FOREIGN KEY(story_id) REFERENCES stories(id)
);
''');

        await db.execute('''
CREATE TABLE hints (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  story_id INTEGER,
  clue_id TEXT,
  description TEXT,
  owner TEXT,
  FOREIGN KEY(story_id) REFERENCES stories(id)
);
''');

        await db.execute('''
  CREATE TABLE chats (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    story_id INTEGER,
    suspect_name TEXT,
    role TEXT,
    text TEXT,
    is_clue INTEGER DEFAULT 0,
    timestamp INTEGER
  )
''');

        await db.execute('''
  CREATE TABLE game_timers (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    story_id INTEGER,
    end_time INTEGER,   -- timestamp in milliseconds
    remaining_seconds INTEGER,
    FOREIGN KEY(story_id) REFERENCES stories(id)
  )
''');

        await db.execute('''
  CREATE TABLE game_result (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    story_id INTEGER,
    killer_name TEXT,
    killer_relation TEXT,
    killer_motive TEXT,
    killer_alibi TEXT,
    killer_image TEXT,
    solved_at INTEGER,
    FOREIGN KEY(story_id) REFERENCES stories(id)
);
''');

      },
    );
  }


  // add new user when signup
  Future<int> insertUser(UserModel user) async {
    final db = await database;
    return await db.insert('users', user.toMap());
  }


  // load user information based on his id used in profile
  Future<UserModel?> getUser(String userId) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
      orderBy: 'id DESC',
      limit: 1,
    );

    if (result.isNotEmpty) {
      return UserModel.fromMap(result.first);
    } else {
      return null;
    }
  }

  // get last created user so we can store user id in shared preferences
  Future<UserModel?> getLastUser() async {
    final db = await database;
    final result = await db.query(
      'users',
      orderBy: 'id DESC',
      limit: 1,
    );

    if (result.isNotEmpty) {
      return UserModel.fromMap(result.first);
    } else {
      return null;
    }
  }

  // check if a user exist in database used in login
  Future<UserModel?> checkUserExists(String email, String password) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );
    return result.isNotEmpty ? UserModel.fromMap(result.first) : null;
  }

  Future<UserModel?> checkEmailExists(String email) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );
    return result.isNotEmpty ? UserModel.fromMap(result.first) : null;
  }

  // store story information in database
  Future<int> insertStory(Map<String, dynamic> storyData, int level, int language) async {
    final db = await database;

    // Insert story
    final storyId = await db.insert('stories', {
      'title': storyData['title'],
      'summary': storyData['story_summary'],
      'level': level,
      'language': language,
    });

    // Insert victim
    final victim = storyData['victim'];
    await db.insert('victims', {
      'story_id': storyId,
      'name': victim['name'],
      'age': victim['age'],
      'cause_of_death': victim['cause_of_death'],
      'location': victim['location'],
    });

    // Insert suspects
    for (final s in storyData['suspects']) {
      await db.insert('suspects', {
        'story_id': storyId,
        'name': s['name'],
        'relation': s['relation'],
        'motive': s['motive'],
        'alibi': s['alibi'],
        'gender': s['gender'],
        'personality': s['personality'],
      });
    }

    // Insert clues
    for (final c in storyData['clues']) {
      await db.insert('clues', {
        'story_id': storyId,
        'clue_id': c['id'],
        'description': c['description'],
        'found_at': c['found_at'],
        'relevance': c['relevance'],
        'owner': c['owner'],
      });
    }

    // Insert hints
    for (final h in storyData['hints']) {
      await db.insert('hints', {
        'story_id': storyId,
        'clue_id': h['id'],
        'description': h['description'],
        'owner': h['owner'],
      });
    }

    return storyId;
  }

  // load story information form database
  Future<Map<String, dynamic>?> getStoryWithDetails(int storyId) async {
    final db = _db;

    final storyResult =
        await db?.query('stories', where: 'id = ?', whereArgs: [storyId]);
    if (storyResult == null || storyResult.isEmpty) return null;

    final story = storyResult.first;

    final victimResult =
        await db?.query('victims', where: 'story_id = ?', whereArgs: [storyId]);
    final suspectsResult = await db
        ?.query('suspects', where: 'story_id = ?', whereArgs: [storyId]);
    final cluesResult =
        await db?.query('clues', where: 'story_id = ?', whereArgs: [storyId]);
    final textCluesResult =
        await db?.query('hints', where: 'story_id = ?', whereArgs: [storyId]);

    // Convert to model objects
    final suspects = suspectsResult != null
        ? suspectsResult.map((e) => SusbectData.fromMap(e)).toList()
        : [];
    final clues = cluesResult != null
        ? cluesResult.map((e) => ClueModel.fromMap(e)).toList()
        : [];
    final textClues = textCluesResult != null
        ? textCluesResult.map((e) => TextClueModel.fromMap(e)).toList()
        : [];
    print("title : " + story['title'].toString());
    print("summary : " + story['summary'].toString());
    print("level : " + story['level'].toString());
    print("victim : " + victimResult!.first.toString());
    print("suspects: ${suspects.map((c) => c.toMap()).toList()}");
    print("clues: ${clues.map((c) => c.toMap()).toList()}");
    print("textClues: ${textClues.map((c) => c.toMap()).toList()}");

    return {
      'title': story['title'],
      'summary': story['summary'],
      'level': story['level'],
      'victim': victimResult!.isNotEmpty ? victimResult.first : {},
      'suspects': suspects,
      'clues': clues,
      'textClues': textClues,
    };
  }

  // save chat with chatgpt in database
  Future<void> saveChats(
      int storyId, String suspectName, List<ChatMessage> messages) async {
    final db = await database;

    await db.delete(
      'chats',
      where: 'story_id = ? AND suspect_name = ?',
      whereArgs: [storyId, suspectName],
    );


    for (final msg in messages) {
      await db.insert('chats', {
        'story_id': storyId,
        'suspect_name': suspectName,
        'role': msg.role,
        'text': msg.text,
        'is_clue': (msg.isClue ?? false) ? 1 : 0,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    }
  }

  // load chats from database
  Future<List<ChatMessage>> loadChats(int storyId, String suspectName) async {
    final db = await database;
    final result = await db.query(
      'chats',
      where: 'story_id = ? AND suspect_name = ?',
      whereArgs: [storyId, suspectName],
      orderBy: 'timestamp ASC',
    );

    return result
        .map((e) => ChatMessage(
              role: e['role'] as String,
              text: e['text'] as String,
              isClue: (e['is_clue'] as int) == 1,
            ))
        .toList();
  }

  // get all stored stories in database used in saved games page
  Future<List<Map<String, dynamic>>> getAllStories() async {
    final db = await database;

    final result = await db.rawQuery('''
    SELECT 
      s.id,
      s.title,
      s.summary,
      s.level,
      s.language,
      t.remaining_seconds,
      CASE WHEN r.id IS NOT NULL THEN 1 ELSE 0 END AS is_solved
    FROM stories s
    LEFT JOIN game_timers t ON s.id = t.story_id
    LEFT JOIN game_result r ON s.id = r.story_id
    ORDER BY s.id DESC
  ''');

    return result.map((row) {
      return {
        ...row,
        'is_solved': (row['is_solved'] as int) == 1,
      };
    }).toList();
  }


  // save game timer progress in database called in playGame page
  Future<void> saveGameTimer(int storyId, int endTime, int remaining) async {
    final db = await database;


    final updated = await db.update(
      'game_timers',
      {
        'end_time': endTime,
        'remaining_seconds': remaining,
      },
      where: 'story_id = ?',
      whereArgs: [storyId],
    );


    if (updated == 0) {
      await db.insert('game_timers', {
        'story_id': storyId,
        'end_time': endTime,
        'remaining_seconds': remaining,
      });
    }
  }



  // load game timer used in PlayGame page when the game first loaded
  Future<Map<String, dynamic>?> loadGameTimer(int storyId) async {
    final db = await database;

    final result = await db.query(
      'game_timers',
      where: 'story_id = ?',
      whereArgs: [storyId],
      limit: 1,
    );

    if (result.isEmpty) return null;

    return result.first;
  }


  // Save game if the player win it
  Future<void> saveGameResult(int storyId, SusbectData killer , String image) async {
    final db = await database;

    await db.insert(
      'game_result',
      {
        'story_id': storyId,
        'killer_name': killer.name,
        'killer_relation': killer.relation,
        'killer_motive': killer.motive,
        'killer_alibi': killer.alibi,
        'killer_image' : image,
        'solved_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }


  // check if the player already win this game or not
  Future<Map<String, dynamic>?> loadGameResult(int storyId) async {
    final db = await database;

    final result = await db.query(
      'game_result',
      where: 'story_id = ?',
      whereArgs: [storyId],
      limit: 1,
    );

    return result.isNotEmpty ? result.first : null;
  }

  // count all played games used in profile page
  Future<int> getPlayedGamesCount() async {
    final db = await database;
    final result = await db.rawQuery("SELECT COUNT(*) as total FROM stories");
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // count all winned games used in profile page
  Future<int> getWinnedGamesCount() async {
    final db = await database;
    final result = await db.rawQuery("SELECT COUNT(*) as total FROM game_result");
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
