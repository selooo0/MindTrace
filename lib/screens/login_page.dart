import 'package:crime_endless/Models/user_model.dart';
import 'package:crime_endless/screens/home.dart';
import 'package:crime_endless/screens/lobby.dart';
import 'package:crime_endless/screens/signup_page.dart';
import 'package:crime_endless/utils/db_helper.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController userNameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String error = '';

  // check user entered info of it is existed in database or not
  // if the user exist move to next page or say Email or Password not correct
  void login(BuildContext context) async {
    final db = DBHelper();
    UserModel? userExit = await db.checkUserExists(
        userNameController.text, passwordController.text);

    if (userExit != null) {
      final prefs = await SharedPreferences.getInstance();
      prefs.setString("userId", userExit.id!);
      Navigator.push(
        context,
        MaterialPageRoute(builder: (BuildContext context) {
          return Home();
        }),
      );
    } else {
      error =
          'Email or Password not correct , if you do not have an account register new account';
    }
    setState(() {});
  }

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
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 32,
                children: [
                  SizedBox(
                    width: 200,
                    child: TextFormField(
                        controller: userNameController,
                        validator: (value) {
                          if (value == "") {
                            return "this field is required";
                          }
                          if (!value!.contains("@") || !value.endsWith(".com")) {
                            return "Email must include @ and .com";
                          }
                          return null;

                        },
                        decoration: InputDecoration(
                            errorMaxLines: 3,
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none),
                            hintText: "Email",
                            filled: true,
                            fillColor: Colors.white)),
                  ),
                  SizedBox(
                    width: 200,
                    child: TextFormField(
                        obscureText: true,
                        controller: passwordController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "This field is required";
                    }
                    final password = value;
                    if (!RegExp(r'[A-Z]').hasMatch(password)) {
                      return "The password must contain uppercase letters, lowercase letters, numbers and symbols.";
                    }
                    if (!RegExp(r'[0-9]').hasMatch(password)) {
                      return "The password must contain uppercase letters, lowercase letters, numbers and symbols.";
                    }
                    if (!RegExp(r'[!@#\$&*~]').hasMatch(password)) {
                      return "The password must contain uppercase letters, lowercase letters, numbers and symbols.";
                    }

                    return null;
                  },
                        decoration: InputDecoration(
                            errorMaxLines: 3,
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none),
                            hintText: "Password",
                            filled: true,
                            fillColor: Colors.white)),
                  ),
                  if (error.isNotEmpty)
                    Center(
                      child: Text(
                        error,
                        style: TextStyle(color: Colors.red.shade600),
                      ),
                    ),
                  SizedBox(
                    width: 200,
                    child: ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            login(context);
                          }
                        },
                        child: Text("Login")),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                    ),
                      onPressed: (){
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (BuildContext context) {
                            return SignupPage();
                          }),
                        );
                      },
                      child: Text("Do not have an account? Sign Up" , style: TextStyle(color:Colors.white),)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
