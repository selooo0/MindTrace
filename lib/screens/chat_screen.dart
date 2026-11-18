import 'package:crime_endless/Models/clue_model.dart';
import 'package:crime_endless/Models/susbect_data.dart';
import 'package:crime_endless/utils/db_helper.dart';
import 'package:crime_endless/widgets/custom_app_bar.dart';
import 'package:crime_endless/utils/helpers.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../Models/chat_message.dart';
import '../../services/chat_service.dart';
import 'package:animated_text_kit/animated_text_kit.dart';

import 'home.dart';

class ChatScreen extends StatefulWidget {
  final String suspectId;
  final SusbectData suspectData;
  final Map<String, dynamic>? victimData;
  final String imageAsset;
  final String suspectImage;
  final Function(String, int) onClueFound;
  final int level;

  const ChatScreen({
    Key? key,
    required this.suspectId,
    required this.suspectData,
    this.victimData,
    required this.imageAsset,
    required this.suspectImage,
    required this.onClueFound,
    required this.level,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List<ChatMessage> messages = [];
  final TextEditingController controller = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final ChatService chatService = ChatService();
  bool isLoading = false;
  bool gameEnd = false;
  int gameLanguage = 0;
  final db = DBHelper();
  int storyId = 0;
  List<ClueModel> clues = [];
  bool clueFound = false;
  bool showClue = true;
  bool enlargedClue = false;
  String enlargedClueId = '';
  String story_summary = '';
  dynamic foundIds;
  dynamic foundTextIds;
  final AudioPlayer typingPlayer = AudioPlayer();
  List<List<double>> cluesPositions = [
    [60, 180],
    [220, 180],
    [280, 220],
    [30, 220],
  ];

  @override
  void initState() {
    super.initState();

    _prepareTypingPlayer();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    await initStoryId();
    await initData();
    await initChat();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bottomInset = MediaQuery.of(context).viewInsets.bottom;
      if (bottomInset > 0) {
        _scrollToBottom();
      }
    });
  }
  Future<void> initStoryId() async {
    final prefs = await SharedPreferences.getInstance();
    storyId = prefs.getInt('storyId') ?? 0;
  }
  // load typing sound
  Future<void> _prepareTypingPlayer() async {
    try {
      await typingPlayer.setAsset('assets/sounds/message.wav');
    } catch (e) {
      print('Audio load error: $e');
    }
  }

  // load story details and discovered clues
  Future<void> initData() async {
    final db = DBHelper();
    final prefs = await SharedPreferences.getInstance();

    gameLanguage = ( prefs.getInt("gameLanguage"))!;
    final result = await db.loadGameResult(storyId);

    if (result != null) {
      print("Real killer: ${result['killer_name']}");

      setState(() {
        gameEnd = true;
      });
    }
    dynamic data = await db.getStoryWithDetails(storyId);
     foundIds = await getDiscoveredClues(true);
     foundTextIds = await getDiscoveredClues(false);
    clues = data?['clues'];
    story_summary = data?['summary'];
  }

  // load chat history and display the messages
  Future<void> initChat() async {
    final db = DBHelper();
    final prefs = await SharedPreferences.getInstance();
    storyId = prefs.getInt('storyId') ?? 0;
    messages = await db.loadChats(storyId, widget.suspectData.name);
    String res = '';
    if (widget.victimData != null) {
      res =
          'Age: ${widget.victimData!["age"]}\nCause Of Death: ${widget.victimData!["vause_of_death"]}\nLocation: ${widget.victimData!["location"]}';
    } else {
      res =
          'Relation: ${widget.suspectData.relation}\nAlibi: ${widget.suspectData.alibi}\nMotive: ${widget.suspectData.motive}\nPersonality: ${widget.suspectData.personality}';
    }
    setState(() {
      messages = messages.isEmpty
          ? [
              ChatMessage(role: 'system', text: res),
              if (widget.victimData != null)
                ChatMessage(role: 'system', text: story_summary)
            ]
          : messages;
    });
    _scrollToBottom();
  }

  // scroll the chat list to the bottom of the page
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // prepare user message and send messages to the chat service file
  Future<void> _sendMessage(String text) async {
    if (text.isEmpty) return;

    setState(() {
      messages.add(ChatMessage(role: "user", text: text));

      controller.clear();
      isLoading = true;
    });

    try {
      final reply = await chatService.sendMessage(
          widget.suspectId, text, List.from(messages) , gameLanguage);

      gameEnd = reply.text.contains('KILLER_FOUND');
      if (gameEnd) {
        print("Game Ended");
        final prefs = await SharedPreferences.getInstance();
        prefs.setBool("gameEnd", true);

        final sid = prefs.getInt("storyId") ?? 0;

        await db.saveGameResult(sid, widget.suspectData , widget.suspectImage);
      }

      setState(() {
        messages.add(reply);
      });
      _scrollToBottom();

    } catch (e) {
      setState(() {
        messages.add(ChatMessage(role: "ai", text: "Error: $e"));
      });
    } finally {
      setState(() => isLoading = false);
    }

    await db.saveChats(storyId, widget.suspectData.name, messages);
  }

  // cancel voice and input field container when leaving the game
  @override
  void dispose() {
    typingPlayer.dispose();
    controller.dispose();
    scrollController.dispose();
    super.dispose();
  }

  // build messages widget
  Widget buildMessage(ChatMessage msg) {
    final isUser = msg.role == "user";
    final isSystem = msg.role == "system";
    return Align(
      alignment: isUser
          ? Alignment.centerRight
          : isSystem
              ? Alignment.center
              : Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser && !isSystem)
            CircleAvatar(
              backgroundImage: AssetImage(widget.suspectImage),
              radius: 16,
            ),
          if (!isUser && !isSystem) const SizedBox(width: 6),
          Flexible(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isUser
                    ? Colors.blue
                    : isSystem
                        ? Colors.grey[600]
                        : Colors.grey[800],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                msg.text,
                style: TextStyle(
                    color: (msg.isClue != null && msg.isClue == true)
                        ? Colors.orange
                        : Colors.white),
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 6),
          if (isUser)
            CircleAvatar(
              backgroundImage: AssetImage("assets/images/person.png"),
              radius: 16,
            ),
        ],
      ),
    );
  }

  // display a winning popup dialog
  void showWinDialog(BuildContext context) async {
    final result = await db.loadGameResult(storyId);

    final killerName = result?['killer_name'] ?? widget.suspectData.name;
    final relation = result?['killer_relation'] ?? widget.suspectData.relation;
    final motive = result?['killer_motive'] ?? widget.suspectData.motive;
    final alibi = result?['killer_alibi'] ?? widget.suspectData.alibi;
    final image = result?['killer_image'] ?? widget.suspectImage;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                (gameLanguage == 1)?
                    "تم اكتشاف المجرم"
                    :
                "Case Solved",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,

                ),
              ),
              const SizedBox(height: 10),
              Text(
                (gameLanguage == 1)?
                "يستطيع الان سكان المدينة النوم بهدوء .. مؤقتا"
                    :
                'The City of Whisers can rest easy .. for now',
                style: TextStyle(color: Colors.white70, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 20,
                children: [
                Image.asset(image , width: 100, height: 100,),
                  Column(children: [
                    Text((gameLanguage == 1)?
                    " المجرم : $killerName"
                        :"Killer : $killerName" , style: TextStyle(color: Colors.white),),
                    Text((gameLanguage == 1)?
                    " الدلائل المكتشفة : ${foundIds.length}"
                        :"Clues Discovered : ${foundIds.length}" , style: TextStyle(color: Colors.white),),
                    Text((gameLanguage == 1)?
                    " أدلة الحوار : ${foundTextIds.length}"
                        :"Hint Discovered : ${foundTextIds.length}" , style: TextStyle(color: Colors.white),),

                  ],),
              ],),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 10,
                children: [

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

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => Home(
                        ),
                      ),
                    );
                  },
                  child: const Text(
                    'Main Menu',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],),

            ],
          ),
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: true,
      appBar: CustomAppBar(
        appBar: AppBar(),
        canBack: true,
        title: widget.suspectId,
      ),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: screenHeight * 0.4,
              width: double.infinity,
              child: Stack(
                children: [
                  IgnorePointer(
                    child: Image.asset('assets/images/${widget.imageAsset}',
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover),
                  ),
                  for (int i = 0, j = 0; i < clues.length; i++)
                    if (clues[i].owner == widget.suspectData.name)
                      if (clues[i].id != "car")
                        Positioned(
                          left: cluesPositions[j][0],
                          top: cluesPositions[j++][1],
                          child: GestureDetector(
                            onTap: () {
                              if (!mounted) return;
                              showClueDialog(
                                  context, clues[i]); // context from the state
                              if (widget.level == 2)
                                widget.onClueFound(clues[i].id, 1800);
                            },
                            child: Image.asset(
                              "assets/images/${clues[i].id}.png",
                              width: 30,
                              height: 30,
                            ),
                          ),
                        ),
                  IgnorePointer(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        height: 100,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                color: Colors.black,
                child: Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        shrinkWrap: true,
                        padding: const EdgeInsets.all(10),
                        itemCount: messages.length,
                        itemBuilder: (context, index) =>
                            buildMessage(messages[index]),
                      ),
                    ),
                    if (isLoading)
                      DefaultTextStyle(
                        style: const TextStyle(
                          fontSize: 24.0,
                          color: Colors.white,
                        ),
                        child: AnimatedTextKit(
                          repeatForever: true,
                          animatedTexts: [
                            TyperAnimatedText('...',
                                speed: Duration(milliseconds: 500)),
                          ],
                        ),
                      ),
                    if (gameEnd)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color.fromARGB(255, 63, 0, 100),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            onPressed: () {
                              showWinDialog(context);
                            },
                            child: Text(
                              "Congrats!",
                              style: TextStyle(
                                  color: Colors.yellowAccent.shade700),
                            )),
                      ),
                    if (widget.victimData == null && !gameEnd)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 0),
                        color: Colors.grey[900],
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: controller,
                                style: const TextStyle(color: Colors.white),
                                decoration: const InputDecoration(
                                  hintText: "Type a message...",
                                  hintStyle: TextStyle(color: Colors.grey),
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.send, color: Colors.white),
                              onPressed: () async {
                                await _sendMessage(controller.text);
                                await typingPlayer.seek(Duration.zero);
                                typingPlayer.play();
                              },
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
