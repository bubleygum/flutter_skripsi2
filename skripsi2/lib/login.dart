import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:skripsi2/home.dart';
import 'auth_bloc.dart';

class login extends StatelessWidget {
  const login({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: BlocProvider(
            create: (context) => AuthBloc(),
            child: const loginForm(),
          ),
        ),
      ),
    );
  }
}

class loginForm extends StatefulWidget {
  const loginForm({super.key});

  @override
  loginFormState createState() => loginFormState();
}

class loginFormState extends State<loginForm> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  TextEditingController emailCont = TextEditingController();
  TextEditingController passCont = TextEditingController();
  String? email;
  String? password;
  Map<String, dynamic> userData = {};
  DateTime currentTime = DateTime.now();
  bool passVisibility = false;

  void loginUser() async {
    if (formKey.currentState!.validate()) {
      try {
        var url = Uri.parse('http://172.22.74.201/login.php');
        var response = await http.post(url, body: {
          'email': emailCont.text,
          'password': passCont.text,
        });
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          bool success = data['success'];
          if (success) {
            final SharedPreferences prefs =
                await SharedPreferences.getInstance();
            await prefs.setBool('isLoggedIn', true);
            await prefs.setString('idAnggota', data["idAnggota"].toString());
            final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
            String idAnggota = data['data'][0]['idAnggota'].toString();
            await prefs.setString('idAnggota', idAnggota);
            if (prefs.getBool('isLoggedIn') ?? false) {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => homeScreen(id: idAnggota)));
            }
            BlocProvider.of<AuthBloc>(context).add(AuthEvent.login);
          } else {
            String message = data['message'];
            if (message ==
                "Your account is not active. Please contact the administrator.") {
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text('Login Failed'),
                    content: Text(message),
                    actions: [
                      TextButton(
                        child: const Text('OK'),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  );
                },
              );
            } else {
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text('Login Failed'),
                    content: Text(message),
                    actions: [
                      TextButton(
                        child: const Text('OK'),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  );
                },
              );
            }
          }
        }
      } catch (error) {
        print('Error: $error');
      }
    }
  }

  String? validateField(String? value) {
    if (value == null || value.isEmpty) {
      return 'This field is required';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        children: <Widget>[
          const SizedBox(height: 24.0),
          const Align(
            alignment: Alignment.center,
            child: Text(
              "Aplikasi Koperasi PT.Rutan",
              style: TextStyle(
                  fontSize: 20, color: Colors.black),
              textAlign: TextAlign.left,
            ),
          ),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Welcome, Please login to start using app",
              style: TextStyle(
                  fontSize: 16, color: Color.fromRGBO(130, 143, 161, 1)),
              textAlign: TextAlign.left,
            ),
          ),
          const SizedBox(height: 24.0),
          Column(
            children: <Widget>[
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Email",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.left,
                ),
              ),
              const SizedBox(height: 8.0),
              TextFormField(
                controller: emailCont,
                decoration: InputDecoration(
                  hintText: 'Enter your email',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25.0),
                    borderSide: const BorderSide(
                      color: Color.fromRGBO(240, 240, 240, 1),
                    ),
                  ),
                  filled: true,
                  fillColor: const Color.fromRGBO(240, 240, 240, 1),
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                ),
                validator: validateField,
                onSaved: (value) {
                  email = value;
                },
                enableInteractiveSelection: false,
              ),
              const SizedBox(height: 16.0),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Password",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.left,
                ),
              ),
              const SizedBox(height: 8.0),
              TextFormField(
                controller: passCont,
                decoration: InputDecoration(
                  hintText: 'Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25.0),
                    borderSide: const BorderSide(
                        color: Color.fromRGBO(240, 240, 240, 1)),
                  ),
                  filled: true,
                  fillColor: const Color.fromRGBO(240, 240, 240, 1),
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  suffixIcon: IconButton(
                    icon: Icon(
                      Icons.remove_red_eye,
                      color: passVisibility ? Colors.blue : Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        passVisibility = !passVisibility;
                      });
                    },
                  ),
                ),
                validator: validateField,
                onSaved: (value) {
                  password = value;
                },
                obscureText: !passVisibility,
              ),
            ],
          ),
          const SizedBox(height: 24.0),
          SizedBox(
            height: 48.0,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                loginUser();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromRGBO(0, 166, 82, 1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25.0),
                ),
              ),
              child: const Text(
                'Sign In',
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
