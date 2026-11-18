  import 'dart:async';
  import 'dart:math';

  import 'package:crime_endless/Models/susbect_data.dart';
  import 'package:crime_endless/screens/home.dart';
  import 'package:crime_endless/utils/db_helper.dart';
  import 'package:crime_endless/widgets/custom_app_bar.dart';
  import 'package:crime_endless/screens/inventory.dart';
  import 'package:crime_endless/utils/helpers.dart';
  import 'package:crime_endless/widgets/map_scene.dart';
  import 'package:flutter/material.dart';
  import 'package:flutter_joystick/flutter_joystick.dart';
  import 'package:just_audio/just_audio.dart';
  import 'package:shared_preferences/shared_preferences.dart';

  import 'lobby.dart';

  class PlayGame extends StatefulWidget {
    const PlayGame({super.key});

    @override
    State<PlayGame> createState() => _PlayGameState();
  }

  class _PlayGameState extends State<PlayGame> with WidgetsBindingObserver {
    var storyData;
    dynamic stroyId;
    late List<SusbectData> susbects;
    double baseMapWidth = 931;
    double baseMapHeight = 849;

    int playerXP = 120;

    double carX = 110;
    double carY = 70;
    double rotation = 0;
    final double speed = 3.0;

    late double offsetX;
    late double offsetY;

    bool isNight = false;
    double overlayOpacity = 0.0;
    Timer? dayNightTimer;


    final _player = AudioPlayer();
    List<Rect> roadZones1 = [

      Rect.fromLTWH(0, 70, 400, 20),// x, y, width, height
      Rect.fromLTWH(0, 210, 400, 20),
      Rect.fromLTWH(0, 335, 400, 20),
      Rect.fromLTWH(0, 470, 330, 20),
      Rect.fromLTWH(0, 650, 400, 20),
      Rect.fromLTWH(0, 770, 400, 20),
      Rect.fromLTWH(0, 870, 400, 20),
      Rect.fromLTWH(135, 0, 20, 860),
      Rect.fromLTWH(320, 0, 20, 860),
    ];

    int level = 0;


    int totalSeconds = 10;
    String timeDisplay = "00:10";
    Timer? countdownTimer;
    bool _audioReady = false;

    Set<String> collectedClues = {};

    @override
    void initState() {
      super.initState();
      initAudio();
      _initializeGameData();
     startDayNightCycle();
      WidgetsBinding.instance.addObserver(this);
    }

    // load car moving sound
    void initAudio() {
      _player.setLoopMode(LoopMode.one);
      _player.setAsset('assets/sounds/car.mp3');
    }

    // load game information from database
    // we load game timer , check if the game already finished or not
    void _initializeGameData() async {
      await loadData();

      final db = DBHelper();
      final timerData = await db.loadGameTimer(stroyId);
      final gameResult = await db.loadGameResult(stroyId);
      if(gameResult != null) return;


      if (timerData != null) {
        int endTime = timerData['end_time'];
        int remTime = timerData['remaining_seconds'];


        totalSeconds = remTime;
        if (totalSeconds < 0) totalSeconds = 0;
      } else {
        _startCountdown();
        return;
      }

      _startTicker();
    }

    // start timer count down
    void _startCountdown() async {
      final db = DBHelper();
      // Set time based on level
      if (level == 1) {
        totalSeconds = 18000;
      } else if (level == 2) {
        totalSeconds = 7200;
      } else {
        totalSeconds = 365400;
      }
      int endTime = DateTime.now()
          .add(Duration(seconds: totalSeconds))
          .millisecondsSinceEpoch;

      await db.saveGameTimer(stroyId, endTime, totalSeconds);

      _startTicker();

    }

    // save the timer progress in database
    void _startTicker() {
      countdownTimer?.cancel();
      _updateTimeDisplay();
      final db = DBHelper();

      countdownTimer = Timer.periodic(Duration(seconds: 1), (timer) async {
        if (!mounted) {
          timer.cancel();
          return;
        }
        totalSeconds--;
        if (totalSeconds <= 0) {
          timer.cancel();
          _onTimeUp();
          return;
        }
        int endTime = DateTime.now()
            .add(Duration(seconds: totalSeconds))
            .millisecondsSinceEpoch;

        await db.saveGameTimer( stroyId, endTime, totalSeconds);
        if (!mounted) {
          timer.cancel();
          return;
        }
          setState(() {
            _updateTimeDisplay();
          });

      });
    }

    // start day and night timer
    void startDayNightCycle() {
      bool fadingToNight = true;
      bool paused = false;

      dayNightTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
        if (!mounted) {

          timer.cancel();
          return;
        }
        if (paused) return;
        setState(() {
          if (fadingToNight) {
            overlayOpacity += 0.01;
            if (overlayOpacity >= 1.0) {
              overlayOpacity = 1.0;
              paused = true;
              Timer(const Duration(seconds: 5), () {
                if (!mounted) return;
                  paused = false;
                  fadingToNight = false;
              });
            }
          } else {
            overlayOpacity -= 0.01;
            if (overlayOpacity <= 0.0) {
              overlayOpacity = 0.0;
              paused = true;
              Timer(const Duration(seconds: 5), () {
                if (!mounted) return;
                  paused = false;
                  fadingToNight = true;

              });
            }
          }
        });
      });
    }

    // show the time in the formal hours:miutes:seconds like this 05:20:10
    void _updateTimeDisplay() {
      int hours = totalSeconds ~/ 3600;
      int rem = totalSeconds % 3600;
      int minutes = rem ~/ 60;
      int seconds = rem % 60;
      timeDisplay =
          '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }

    // when the time finish this show the popup time ended then it force user to go back to home page
    void _onTimeUp() {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('Time Up!'),
          content: const Text('The investigation time has ended.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => Home(
                    ),
                  ),
                );
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }

    @override
    void dispose() {

      WidgetsBinding.instance.removeObserver(this);

      countdownTimer?.cancel();
      dayNightTimer?.cancel();
      _player.dispose();
      super.dispose();
    }

    // stop timer when the app is closed
    @override
    void didChangeAppLifecycleState(AppLifecycleState state) {
      if (state == AppLifecycleState.paused ||
          state == AppLifecycleState.detached ||
          state == AppLifecycleState.inactive) {
        dayNightTimer?.cancel();

        countdownTimer?.cancel();
      }
    }

    // add time bonus when the a clue is found (this only available in level hard)
    void addTimeBonus(String clueId, int seconds) {
      if (collectedClues.contains(clueId)) return;

      setState(() {
        collectedClues.add(clueId);
        totalSeconds += seconds;
        _updateTimeDisplay();
      });
    }

    // play the car sound only when the car moves
    void updateSound(double speed) {
      if (speed > 0) {
        _player.play();
      } else {
        _player.pause();
      }
    }

    // load story details from database
    Future<void> loadData() async {
      final db = DBHelper();
      final prefs = await SharedPreferences.getInstance();
      stroyId = prefs.getInt("storyId");
      level = prefs.getInt("GameLevel") ?? 0;
      final data = await db.getStoryWithDetails(stroyId!);

      if (mounted) {
        setState(() {
          storyData = data;
        });
      }
    }

    // handle joystick movement and then apply these movement on the car
    void onJoystickChanged(StickDragDetails details, Size screenSize) {
      if (!mounted) return;

      double intensity = sqrt(details.x * details.x + details.y * details.y);
      double deltaX = details.x * speed;
      double deltaY = details.y * speed;

      double nextX = carX + deltaX;
      double nextY = carY + deltaY;

      double allowedX = carX;
      double allowedY = carY;

      Offset nextCenterX = Offset(nextX + 40 / 2, carY + 40 / 2);
      if (roadZones1.any((r) => r.contains(nextCenterX)) &&
          nextX >= 0 &&
          nextX <= screenSize.width - 40) {
        allowedX = nextX;
      }
      Offset nextCenterY = Offset(carX + 40 / 2, nextY + 40 / 2);
      if (roadZones1.any((r) => r.contains(nextCenterY)) &&
          nextY >= 0 &&
          nextY <= screenSize.height - 40) {
        allowedY = nextY;
      }

      setState(() {
        carX = allowedX;
        carY = allowedY;
        updateSound(intensity);
        if (details.x != 0 || details.y != 0) {
          rotation = atan2(details.y, details.x) * 180 / pi;
        }
      });
    }

    @override
    Widget build(BuildContext context) {
      if (storyData == null) {
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      }
      double screenWidth = MediaQuery.of(context).size.width;
      double screenHeight = MediaQuery.of(context).size.height;

      final Size imageSize = Size(931, 849);
      final Size screenSize = MediaQuery.of(context).size;
      final double imageRatio = imageSize.width / imageSize.height;
      final double screenRatio = screenSize.width / screenSize.height;

      double renderWidth, renderHeight;
      if (screenRatio > imageRatio) {
        renderWidth = screenSize.width;
        renderHeight = screenSize.width / imageRatio;
      } else {
        renderHeight = screenSize.height;
        renderWidth = screenSize.height * imageRatio;
      }

      offsetX = (renderWidth - screenSize.width) / 2;
      offsetY = (renderHeight - screenSize.height) / 2;
      //scaleRoadZonesToScreen(context);
      return Container(
        width: screenWidth,
        height: screenHeight,
        child: Stack(
          children: [
            MapScene(
              storyData: storyData,
              roadZones: roadZones1,
              carX: carX,
              carY: carY,
              rotation: rotation,
              level: level,
              onClueFound: addTimeBonus,
                overlayOpacity: overlayOpacity
              //scaleRect: scaledRect,
            ),

              Positioned(
                top: 20,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.redAccent, width: 2),
                    ),
                    child: Text(
                      timeDisplay,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
            Positioned(
              left: screenWidth / 2 - 60,
              bottom: 20,
              child: Joystick(
                mode: JoystickMode.all,
                listener: (StickDragDetails details) {
                  onJoystickChanged(details, screenSize);
                },
                period: const Duration(milliseconds: 16),
                stick: JoystickStick(
                  size: 60,
                  decoration: JoystickStickDecoration(
                      color: Colors.white, shadowColor: Colors.transparent),
                ),
                base: JoystickBase(
                  size: 120,
                  decoration: JoystickBaseDecoration(
                      drawOuterCircle: false,
                      drawInnerCircle: false,
                      drawArrows: false,
                      color: Color(0x70FFFFFF),
                      outerCircleColor: Colors.transparent),
                ),
              ),
            ),
            Positioned(
              top: 20,
              left: 20,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: IconButton(
                    color: Colors.black,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => Inventory()),
                      );
                    },
                    icon: Icon(Icons.people)),
              ),
            ),
            Positioned(
              top: 20,
              right: 20,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: IconButton(
                    color: Colors.black,
                    onPressed: () {


                      countdownTimer?.cancel();
                      dayNightTimer?.cancel();


                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => Home()),(route) {

                        return false;
                      },
                      );
                    },
                    icon: Icon(Icons.exit_to_app_rounded , color: Colors.white,)),
              ),
            ),
          ],
        ),
      );
    }
  }
