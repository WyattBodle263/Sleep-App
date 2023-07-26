import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'screens/bottomNav.dart';
//Firebase imports
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/launch_page.dart';
import 'screens/firebase_auth.dart';

void main() async {
  //Splash screen widget init
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  //Firebase init
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    //Name and options of firebase app
    name: 'Sleep-tracker',
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  //Create a widget to hold the current page
  Widget currentPage = LaunchPage(title: 'Login / Sign Up');


AuthService authService = AuthService();


  //Override the initial state
void initState(){
  super.initState();
  checkLogin();
}

//This is method checks for a token if user has logged in
  void checkLogin() async{
  print("Checking for login");
    //Get the token
    String? token = await authService.getToken();
    //If the token exist, the user is logged in, otherwise go to login page
    if(token != null){
      setState(() {
        print("Token found");
        //Set the current page to the nav page
        currentPage = const BottomNavPage(title: 'Nav');
      });
    }else{
  print("User is not logged in");
    }
  }

  @override
  Widget build(BuildContext context){
    return MaterialApp(
      title: '',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.pink),
        useMaterial3: true,
      ),
      //Home is the page that will be called first
      home: currentPage,
      debugShowCheckedModeBanner: false,
    );
  }
}