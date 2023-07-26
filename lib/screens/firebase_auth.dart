import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'bottomNav.dart';

class FirebaseAuthState extends StatefulWidget {
  const FirebaseAuthState({Key? key, required this.title}) : super(key: key);

  final String title;
  @override
  FirebaseAuthStateState createState() => FirebaseAuthStateState();
}

class FirebaseAuthStateState extends State<FirebaseAuthState> {
  //Text controllers for user and pass
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  //Sets an empty message to print to the user if there is an error
  String errorMessage = '';
  @override
  void initState() {
    super.initState();
  }
  //Create a instance of services
  AuthService authService = AuthService();

  // Method to login
  void _login() {
    setState(() {
      errorMessage = '';
    });

    String username = _usernameController.text;
    String password = _passwordController.text;

    FirebaseAuth.instance
        .signInWithEmailAndPassword(email: username, password: password)
        .then((userCredential) {
      authService.storeTokenAndData(userCredential, true);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const BottomNavPage(
            title: 'Home',
          ),
        ),
      );
    })
        .catchError((error) {
      setState(() {
        errorMessage = 'Failed to sign in/up: ${error.toString()}';
      });
    });
  }
  // Method to handle back navigation
  void _goBack() {
    Navigator.pop(context);
  }

// Sign up method instead of login
  void _signup() {
    setState(() {
      errorMessage = '';
    });

    String username = _usernameController.text;
    String password = _passwordController.text;

    FirebaseAuth.instance
        .createUserWithEmailAndPassword(
      email: username,
      password: password,
    )
        .then((userCredential) {
      authService.storeTokenAndData(userCredential, true);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const BottomNavPage(
            title: 'Home',
          ),
        ),
      );
    })
        .catchError((error) {
      setState(() {
        errorMessage = 'Failed to sign in/up: ${error.toString()}';
      });
    });
  }

  // Google sign-in method
  Future<void> _googleSignIn() async {
    try {
      final GoogleSignInAccount? googleUser = await authService.googleSignIn.signIn();
      final GoogleSignInAuthentication googleAuth = await googleUser!.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await authService.auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        authService.storeTokenAndData(userCredential, false);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const BottomNavPage(
              title: 'Home',
            ),
          ),
        );
      }
    } catch (error) {
      print('Failed to sign in with Google: $error');
      setState(() {
        errorMessage = 'Failed to sign in with Google: $error';
      });
    }

  }



  //Disposes of the controllers when done
  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: Text(widget.title),
        leading: widget.title == 'Login'
            ? null
            : IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: _goBack,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    errorMessage,
                    style: const TextStyle(
                      color: Colors.red,
                    ),
                  ),
                  TextField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          if (widget.title == 'Login') {
                            _login();
                          } else {
                            _signup();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(250, 50),
                        ),
                        child: Text(widget.title),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(width: 8.0), // Add some spacing
                  GestureDetector(
                    onTap: _googleSignIn,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage('assets/Google_criculo_logo.jpeg'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AuthService {
  // Init of services
  final GoogleSignIn googleSignIn = GoogleSignIn();
  final FirebaseAuth auth = FirebaseAuth.instance;
  final storage = const FlutterSecureStorage();

  // Method to store token
  Future<void> storeTokenAndData(UserCredential userCredential, bool isEmailSignIn) async {
    String? token;
    print(userCredential.credential != null);
    if (userCredential.additionalUserInfo?.isNewUser == true && isEmailSignIn == false) {
      // For Google sign-in
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      final GoogleSignInAuthentication googleAuth = await googleUser!.authentication;
      token = googleAuth.idToken;
    }else{
      // For email sign-in methods
      IdTokenResult? tokenResult = await userCredential.user!.getIdTokenResult();
      token = tokenResult?.token;
    }

    if (token != null) {
      await storage.write(key: "token", value: token);
      await storage.write(
        key: "userCredential",
        value: userCredential.toString(),
      );
      print("Token saved");
    }
  }

  Future<String?> getToken() async {
    return await storage.read(key: "token");
  }

  Future<void> logout() async {
    print("User is logging out");
    try {
      await googleSignIn.signOut();
      await auth.signOut();
      await storage.delete(key: "token");
    } catch (e) {}
  }

  Future<String?> getUserUID() async {
    final User? user = auth.currentUser;
    return user?.uid;
  }
}