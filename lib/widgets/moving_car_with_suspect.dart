import 'dart:math';
import 'package:crime_endless/cloud_loading.dart';
import 'package:crime_endless/screens/chat_screen.dart';
import 'package:flutter/material.dart';

// suspects car
// thi code handles suspect car position and movement with the suspect image

class MovingCarWithSuspect extends StatefulWidget {
  final dynamic suspect;
  final int suspectIndex;
  final List<Rect> roadZones;
  final String icon;
  final double carX;
  final double carY;
  final int distanceFromCar;
  final suspectImage;
  final imageAsset;
  final int level;
  final Function(String, int) onClueFound;

  const MovingCarWithSuspect(
      {super.key,
      required this.suspect,
      required this.suspectIndex,
      required this.roadZones,
      required this.icon,
      required this.carX,
      required this.carY,
      required this.distanceFromCar,
      required this.suspectImage,
      required this.imageAsset,
      required this.level, required this.onClueFound
      });

  @override
  State<MovingCarWithSuspect> createState() => _MovingCarWithSuspectState();
}

class _MovingCarWithSuspectState extends State<MovingCarWithSuspect>
    with SingleTickerProviderStateMixin {
  late double x, y;
  late Offset target;
  late Rect currentZone;
  late AnimationController controller;
  final Random _rand = Random();

  String direction = "right";

  @override
  void initState() {
    super.initState();

    currentZone = widget.roadZones[_rand.nextInt(widget.roadZones.length)];
    final start = Offset(
      currentZone.left + currentZone.width / 2,
      currentZone.top + currentZone.height / 2,
    );
    x = start.dx;
    y = start.dy;

    _pickInitialDirection();
    _setTargetInCurrentDirection();

    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    )..addListener(_moveSmoothly);

    controller.repeat();
  }

  void _pickInitialDirection() {
    const dirs = ["up", "down", "left", "right"];
    direction = dirs[_rand.nextInt(4)];
  }

  void _setTargetInCurrentDirection() {

    const step = 20.0;
    double nx = x, ny = y;

    switch (direction) {
      case "up":
        ny -= step;
        break;
      case "down":
        ny += step;
        break;
      case "left":
        nx -= step;
        break;
      case "right":
        nx += step;
        break;
    }

    target = Offset(nx, ny);
  }

  void _moveSmoothly() {
    if (!mounted) return;

    final dx = target.dx - x;
    final dy = target.dy - y;
    final distance = sqrt(dx * dx + dy * dy);
    const double speed = 1.5;

    if (distance < 1.5) {
      final matching = widget.roadZones.firstWhere(
        (r) => r.contains(Offset(x, y)),
        orElse: () => currentZone,
      );
      currentZone = matching;

      if (_isAtIntersection()) {
        direction = _chooseNextDirection();
      } else if (!_canMoveForward()) {
        direction = _reverseDirection();
      }
      _setTargetInCurrentDirection();
    } else {
      final nx = x + speed * dx / distance;
      final ny = y + speed * dy / distance;
      if (_isInsideRoad(nx, ny)) {
        setState(() {
          x = nx;
          y = ny;
        });
      } else {
        direction = _reverseDirection();
        _setTargetInCurrentDirection();
      }
    }
  }
  // check if suspect inside a road or not
  bool _isInsideRoad(double nx, double ny) {
    return widget.roadZones.any((r) => r.contains(Offset(nx, ny)));
  }
  // check if suspect can still move forward
  bool _canMoveForward() {
    final next = target;
    return _isInsideRoad(next.dx, next.dy);
  }
  // check if the suspects reach an intersection
  bool _isAtIntersection() {

    const checkDistance = 25.0;
    int possible = 0;

    if (_roadExistsInDirection("up", checkDistance)) possible++;
    if (_roadExistsInDirection("down", checkDistance)) possible++;
    if (_roadExistsInDirection("left", checkDistance)) possible++;
    if (_roadExistsInDirection("right", checkDistance)) possible++;

   return possible >= 3 ||
        (possible >= 2 &&
            !_roadExistsInDirection(_reverseDirection(), checkDistance));
  }
  // check if there is another road in this direction
  bool _roadExistsInDirection(String dir, double dist) {
    double nx = x, ny = y;
    switch (dir) {
      case "up":
        ny -= dist;
        break;
      case "down":
        ny += dist;
        break;
      case "left":
        nx -= dist;
        break;
      case "right":
        nx += dist;
        break;
    }
    return _isInsideRoad(nx, ny);
  }

  // if the road was closed drive in the other direction
  String _reverseDirection() {
    switch (direction) {
      case "up":
        return "down";
      case "down":
        return "up";
      case "left":
        return "right";
      case "right":
        return "left";
      default:
        return direction;
    }
  }

  String _getRoadOrientation(Rect zone) {
    return zone.width > zone.height ? "horizontal" : "vertical";
  }
  // choose next direction when the suspect finish his current path
  String _chooseNextDirection() {
    const checkDistance = 25.0;
    final orientation = _getRoadOrientation(currentZone);
    final validDirs = <String>[];

    if (orientation == "horizontal") {
      if (_roadExistsInDirection("left", checkDistance)) validDirs.add("left");
      if (_roadExistsInDirection("right", checkDistance))
        validDirs.add("right");
    } else {
      if (_roadExistsInDirection("up", checkDistance)) validDirs.add("up");
      if (_roadExistsInDirection("down", checkDistance)) validDirs.add("down");
    }


    if (validDirs.isEmpty) {
      if (orientation == "horizontal") {
        if (_roadExistsInDirection("up", checkDistance)) validDirs.add("up");
        if (_roadExistsInDirection("down", checkDistance))
          validDirs.add("down");
      } else {
        if (_roadExistsInDirection("left", checkDistance))
          validDirs.add("left");
        if (_roadExistsInDirection("right", checkDistance))
          validDirs.add("right");
      }
    }

    if (validDirs.isEmpty) return _reverseDirection();
    return validDirs[_rand.nextInt(validDirs.length)];
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final angle = atan2(target.dy - y, target.dx - x);
    return Positioned(
      left: x,
      top: y,
      child: Transform.rotate(
        angle: angle,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (sqrt(pow(x - widget.carX, 2) + pow(y - widget.carY, 2)) <
                widget.distanceFromCar)
              GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      PageRouteBuilder(
                        opaque: false,
                        pageBuilder: (_, __, ___) => CloudLoading(
                          toScreen: ChatScreen(
                            suspectId: widget.suspect.name,
                            suspectData: widget.suspect,
                            suspectImage: widget.suspectImage,
                            imageAsset: widget.imageAsset,
                            level: widget.level,
                            onClueFound: widget.onClueFound,
                          ),
                        ),
                      ),
                    );
                  },
                  child: Image.asset(widget.icon, width: 36, height: 36)),
            const SizedBox(height: 2),
            Image.asset('assets/images/car.png', width: 40, height: 40),
          ],
        ),
      ),
    );
  }
}
