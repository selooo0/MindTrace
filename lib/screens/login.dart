import 'package:crime_endless/screens/login_page.dart';
import 'package:crime_endless/screens/signup_page.dart';

import 'package:flutter/material.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
              child: Image.asset(
            'assets/images/back.png',
            fit: BoxFit.cover,
            alignment: Alignment.center,
          )),
          Padding(
            padding: const EdgeInsets.only(bottom: 64.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              spacing: 16,
              children: [
                SizedBox(
                  child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (BuildContext context) {
                            return LoginPage();
                          }),
                        );
                      },
                      child: Text("Login")),
                  width: 200,
                ),
                SizedBox(
                    width: 200,
                    child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (BuildContext context) {
                              return SignupPage();
                            }),
                          );
                        },
                        child: Text("Sign up"))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
