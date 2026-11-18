import 'package:crime_endless/screens/home.dart';
import 'package:crime_endless/cloud_loading.dart';
import 'package:crime_endless/screens/play_game.dart';
import 'package:flutter/material.dart';
// We created one app bar and it is shared across multiple screens
// the appbar handles back to home page and cloud loading when moving from play game and to it

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  final AppBar appBar;
  final bool? canBack;
  final String? title;
  const CustomAppBar(
      {super.key, required this.appBar, this.canBack, this.title});

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();

  @override
  Size get preferredSize => Size.fromHeight(appBar.preferredSize.height);
}

class _CustomAppBarState extends State<CustomAppBar> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      shadowColor: Colors.transparent,
      leading: (widget.canBack != null)
          ? BackButton(
              color: Colors.white,
              onPressed: () {
                (widget.canBack == true)
                    ? Navigator.of(context).push(
                        PageRouteBuilder(
                          opaque: false,
                          pageBuilder: (_, __, ___) => CloudLoading(
                            toScreen: PlayGame(),
                          ),
                        ),
                      )
                    : Navigator.pop(context);
              },
            )
          : SizedBox(),
      title: Text(
        (widget.title == null) ? "MINDTRACE" : widget.title!,
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      centerTitle: true,
      flexibleSpace: Container(
        alignment: Alignment.bottomCenter,
        height: 100,
        color: Color.fromARGB(255, 63, 0, 100),
      ),
    );
  }
}
