import 'package:flutter/material.dart';

// this class shows cloud loading from both sides of screen
// when moving from play game page to the chat screen page

class CloudLoading extends StatefulWidget {
  final Widget toScreen;

  const CloudLoading({
    super.key,
    required this.toScreen,
  });

  @override
  State<CloudLoading> createState() => _CloudLoadingState();
}

class _CloudLoadingState extends State<CloudLoading>
    with TickerProviderStateMixin {
  late final AnimationController cloudController;
  late final Animation<double> leftCloud;
  late final Animation<double> rightCloud;

  bool _showNextScreen = false;

  @override
  void initState() {
    super.initState();

    cloudController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    leftCloud = Tween<double>(begin: -1.5, end: -0.2).animate(
      CurvedAnimation(parent: cloudController, curve: Curves.easeInOut),
    );

    rightCloud = Tween<double>(begin: 1.5, end: 0.2).animate(
      CurvedAnimation(parent: cloudController, curve: Curves.easeInOut),
    );

    cloudController.addStatusListener((status) async {
      if (status == AnimationStatus.completed) {
        setState(() => _showNextScreen = true);

        await Future.delayed(const Duration(milliseconds: 1000));

        cloudController.reverse().then((_) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => widget.toScreen),
          );
        });
      }
    });

    cloudController.forward();
  }

  @override
  void dispose() {
    cloudController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    return Scaffold(
      body: SizedBox.expand(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              color: Colors.black,
            ),
            AnimatedBuilder(
              animation: cloudController,
              builder: (context, child) => FractionalTranslation(
                translation: Offset(leftCloud.value, 0),
                child: child,
              ),
              child: Image.asset(
                'assets/images/wl.png',
                width: w * 0.9,
                height: h,
                fit: BoxFit.cover,
              ),
            ),
            AnimatedBuilder(
              animation: cloudController,
              builder: (context, child) => FractionalTranslation(
                translation: Offset(rightCloud.value, 0),
                child: child,
              ),
              child: Image.asset(
                'assets/images/wr.png',
                width: w * 0.9,
                height: h,
                fit: BoxFit.cover,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
