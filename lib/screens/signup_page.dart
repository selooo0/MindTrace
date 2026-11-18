import 'package:crime_endless/Models/user_model.dart';
import 'package:crime_endless/screens/home.dart';
import 'package:crime_endless/screens/lobby.dart';
import 'package:crime_endless/screens/login_page.dart';
import 'package:crime_endless/utils/db_helper.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String error = '';

  void signup(BuildContext context) async {
    final db = DBHelper();
    UserModel? userExit =
        await db.checkEmailExists(emailController.text);

    if (userExit == null) {
      int result = await db.insertUser(UserModel(
          name: nameController.text,
          email: emailController.text,
          password: passwordController.text,
          age: ageController.text));

      if (result > 0) {
        UserModel? user = await db.getLastUser();
        if (user != null) {
          final prefs = await SharedPreferences.getInstance();
          prefs.setString("userId", user.id!);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (BuildContext context) {
              return Home();
            }),
          );
        } else {
          error = "User not found";
        }
      } else {
        error = "Failed to insert user";
      }
    } else {
      error = 'Email Already exist , choose another email';
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
                        controller: nameController,
                        validator: (value) {
                          if (value == "") {
                            return "this field is required";
                          } else {
                            return null;
                          }
                        },
                        decoration: InputDecoration(
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none),
                            hintText: "User Name",
                            filled: true,
                            fillColor: Colors.white)),
                  ),
                  SizedBox(
                    width: 200,
                    child: TextFormField(
                        controller: ageController,
                        validator: (value) {
                          if (value == "") {
                            return "this field is required";
                          } else {
                            return null;
                          }
                        },
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(

                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none),
                            hintText: "Age",
                            filled: true,
                            fillColor: Colors.white)),
                  ),
                  SizedBox(
                    width: 200,
                    child: TextFormField(
                        controller: emailController,
                        validator: (value) {
                          if (value == "") {
                            return "this field is required";
                          }
                          if (!value!.contains("@") || !value.endsWith(".com")) {
                            return "Email must include @ and .com";
                          }
                            return null;

                        },
                        keyboardType: TextInputType.emailAddress,
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
                        controller: passwordController,
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
                            signup(context);
                          }
                        },
                        child: Text("Sign Up")),
                  ),

                  ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                      ),
                      onPressed: (){
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (BuildContext context) {
                            return LoginPage();
                          }),
                        );
                      },
                      child: Text("Already have an account? Login Up" , style: TextStyle(color:Colors.white),)),

                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
