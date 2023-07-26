import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'firebase_auth.dart';

class LaunchPage extends StatefulWidget {
//Constructor will get the required date and set it correctly.
  const LaunchPage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<LaunchPage> createState() => _LaunchPageState();
}

class _LaunchPageState extends State<LaunchPage> {
  //Override the initial state
  @override
  void initState(){
    //Remove splash screen
    Future.delayed(const Duration(milliseconds: 3000), () {
      FlutterNativeSplash.remove();
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Launch Page'),
      ),
      body: Center(
        child: Container(
          //Change this value to edit the padding for image and buttons
          padding: const EdgeInsets.all(16.0),
          child:Column(
            mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
             'assets/icon.png',
              //Change size of icon on launch
              width: 150,
              height: 150,
            ),
            //A sized box adds space between items
            const SizedBox(height: 170),
            ElevatedButton(
                onPressed: (){
                  Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (context) => const FirebaseAuthState(
                            title: 'Login')
                  )
                  );
                },
                //Change style of button here
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(250, 50),
                ),
                //Change title on top button here
                child: const Text('Login'),
            ),
            const SizedBox(height: 40),
          ElevatedButton(
            onPressed: (){
              Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (context) => const FirebaseAuthState(
                          title: 'Sign Up')
                  )
              );
            },
            //Change style of button here
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(250, 50),
            ),
            //Change title on top button here
            child: const Text('Sign Up'),
          ),
          ],
          ),
        ),
      ),
    );
  }
}

