import 'dart:math';

import 'package:crime_endless/Models/clue_model.dart';
import 'package:crime_endless/Models/susbect_data.dart';
import 'package:crime_endless/screens/chat_screen.dart';
import 'package:crime_endless/cloud_loading.dart';
import 'package:crime_endless/utils/helpers.dart';
import 'package:crime_endless/widgets/flashing_light.dart';
import 'package:crime_endless/widgets/map_cropped_fill.dart';
import 'package:crime_endless/widgets/moving_car_with_suspect.dart';
import 'package:crime_endless/widgets/progress_path.dart';
import 'package:flutter/material.dart';

import 'night_overlay_painter.dart';

// this widget show the map part
// it display background image also the suspects as static images or moving cars based on the game level
// also the clues and the police car


class MapScene extends StatelessWidget {
  final storyData;
  dynamic roadZones;
  final double carX;
  final double carY;
  final double rotation;
  final int level;
  final Function(String, int) onClueFound;
  final overlayOpacity;

  MapScene({
    super.key,
    required this.storyData,
    this.roadZones,
    required this.carX,
    required this.carY,
    required this.rotation,
    required this.level,
    required this.onClueFound,
    required this.overlayOpacity
  });

  List<double> victimePosition = [210, 350];

  List<List<double>> suspectsPostions = [
    [30, 230],
    [40, 650],
    [60, 360],
    [310, 330],
    [160, 650],
  ];

  List<List<double>> cluesPostions = [
    [200, 250],
    [190, 380],
    [50, 550],
    [190, 500],
    [160, 730],
  ];

  final Random _rand = Random();

  final int distance = 100;

  final List<String> roomsSuspects = [
    'boyroom.jpg',
    'boy2room.jpg',
    'manroom.jpg',
    'room1.jpg',
    'grandfatherroom.jpg',
    'room3.jpg',
    'girlroom.jpg',
    'grandmotherroom.jpg',
    'room2.jpg',
    'room2.jpg',
  ];

  final List<String> iconSuspects = [
    'assets/images/person2.png',
    'assets/images/pb1.png',
    'assets/images/pb2.png',
    'assets/images/pb3.png',
    'assets/images/pb4.png',
    'assets/images/person1.png',
    'assets/images/pg1.png',
    'assets/images/pg2.png',
    'assets/images/pg3.png',
    'assets/images/pg3.png',
  ];

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
    'assets/images/g2.png',
  ];

  // specify clue image size based on its type
  double getClueWidth(String id) {
    double result = 60;
    if (id == 'car') {
      result = 40;
    } else if (id == 'knife') {
      result = 20;
    } else if (id == 'bloodStain') {
      result = 40;
    } else if (id == 'bullet') {
      result = 20;
    } else if (id == 'bloodyCloth') {
      result = 20;
    } else if (id == 'gun') {
      result = 20;
    } else if (id == 'moneyPile') {
      result = 20;
    }

    return result;
  }

  double baseMapWidth = 931;
  double baseMapHeight = 849;
  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Center(
      child: Container(
        width: screenWidth,
        height: screenHeight,
        color: Colors.black,
        child: ClipRect(
          child: Stack(
            children: [
              croppedMapFill(
                context: context,
                assetPath: 'assets/images/map1.jpg',
                imageWidth: baseMapWidth,
                imageHeight: baseMapHeight,
                cropLeft: 300,
                cropTop: 0,
                cropWidth: 600,
                cropHeight: 800,
              ),

              // TODO roads area on the map we can delete it
              // TODO it is just for developers
              ...roadZones.asMap().entries.map((entry) {
                final index = entry.key;
                dynamic rect = entry.value;
                return Positioned(
                  left: rect.left,
                  top: rect.top,
                  child: Container(
                    width: rect.width,
                    height: rect.height,
                    decoration: BoxDecoration(
                      color: Colors.grey[300]!.withOpacity(0.3),
                      border: Border.all(
                        color: Colors.blue,
                        width: 2.0,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '',
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
              // clues positions
              if (storyData != null)
                for (int i = 0; i < storyData?['clues'].length; i++)
                  if (storyData?['clues'][i].id == "car")
                    if(level == 2 && overlayOpacity >= 1.0 || level != 2)
                    Positioned(
                      left: cluesPostions[i][0],
                      top: cluesPostions[i][1],
                      child: GestureDetector(
                        onTap: () {
                          showClueDialog(context, storyData?['clues'][i]);
                          if (level == 2)
                            onClueFound(storyData?['clues'][i].id, 1800);
                        },
                        child: Image.asset(
                            getClueImage(storyData?['clues'][i].id),
                            width: getClueWidth(storyData?['clues'][i].id),
                            height: getClueWidth(storyData?['clues'][i].id)),
                      ),
                    ),

              // People
              if (storyData != null)
                for (int i = 0; i < storyData?['suspects'].length; i++)
                  if (level == 0)
                    if (sqrt(pow(suspectsPostions[i][0] - carX, 2) +
                            pow(suspectsPostions[i][1] - carY, 2)) <
                        distance)
                      Positioned(
                        left: suspectsPostions[i][0],
                        top: suspectsPostions[i][1],
                        child: GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              PageRouteBuilder(
                                opaque: false,
                                pageBuilder: (_, __, ___) => CloudLoading(
                                  toScreen: ChatScreen(
                                    suspectId: storyData?['suspects'][i].name,
                                    suspectData: storyData?['suspects'][i],
                                    suspectImage:
                                        (storyData?['suspects'][i].gender ==
                                                "male" || storyData?['suspects'][i].gender ==
                                            "ذكر")
                                            ? profileSuspects[i]
                                            : profileSuspects[i + 5],
                                    imageAsset:
                                        (storyData?['suspects'][i].gender ==
                                                "male"|| storyData?['suspects'][i].gender ==
                                            "ذكر")
                                            ? roomsSuspects[i]
                                            : roomsSuspects[i + 5],
                                    onClueFound : onClueFound,
                                    level : level,
                                  ),
                                ),
                              ),
                            );
                          },
                          child: Image.asset(
                            (storyData?['suspects'][i].gender == "male"|| storyData?['suspects'][i].gender ==
                                "ذكر")
                                ? iconSuspects[i]
                                : iconSuspects[i + 5],
                            width: 60,
                            height: 60,
                            fit: BoxFit.contain,
                          ),
                        ),
                      )
                    else
                      SizedBox.shrink()
                  else
                    MovingCarWithSuspect(
                      suspect: storyData?['suspects'][i],
                      suspectIndex: i,
                      roadZones: roadZones,
                      icon: (storyData?['suspects'][i].gender == "male"|| storyData?['suspects'][i].gender ==
                          "ذكر")
                          ? iconSuspects[i]
                          : iconSuspects[i + 5],
                      carX: carX,
                      carY: carY,
                      distanceFromCar: distance,
                      suspectImage: (storyData?['suspects'][i].gender == "male"|| storyData?['suspects'][i].gender ==
                          "ذكر")
                          ? profileSuspects[i]
                          : profileSuspects[i + 5],
                      imageAsset: (storyData?['suspects'][i].gender == "male"|| storyData?['suspects'][i].gender ==
                          "ذكر")
                          ? roomsSuspects[i]
                          : roomsSuspects[i + 5],
                      level: level,
                      onClueFound: onClueFound,
                    ),

              Positioned(
                left: victimePosition[0],
                top: victimePosition[1],
                child: GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      PageRouteBuilder(
                        opaque: false,
                        pageBuilder: (_, __, ___) => CloudLoading(
                          toScreen: ChatScreen(
                            suspectId: storyData?['victim']["name"],
                            suspectData: SusbectData(
                                name: "",
                                alibi: "",
                                motive: "",
                                gender: "",
                                personality: "",
                                relation: ""),
                            victimData: storyData?['victim'],
                            suspectImage: "",
                            imageAsset: "roomv.jpg",
                            onClueFound: onClueFound,
                            level:level
                          ),
                        ),
                      ),
                    );
                  },
                  child: Image.asset(
                    'assets/images/victime_marker.png',
                    width: 60,
                    height: 60,
                    fit: BoxFit.contain,
                  ),
                ),
              ),



              if (level == 2)
              CustomPaint(
                size: Size(screenWidth, screenHeight),
                painter: NightOverlayPainter(
                  carPosition: Offset(carX + 20, carY + 20),
                  radius: 100,
                  opacity: overlayOpacity,
                ),
              ),

              Positioned(
                left: carX,
                top: carY,
                child: Transform.rotate(
                  angle: rotation * pi / 180,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [

                      Image.asset(
                        'assets/images/pcar.png',
                        width: 40,
                        height: 40,
                      ),
                      Positioned(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            FlashingLight(color: Colors.blue),
                            SizedBox(width: 4),
                            FlashingLight(color: Colors.red),
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
      ),
    );
  }
}
