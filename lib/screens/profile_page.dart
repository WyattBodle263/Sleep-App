import 'package:flutter/material.dart';
import 'package:theresa_test/screens/launch_page.dart';
import 'firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:profanity_filter/profanity_filter.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  AuthService authService = AuthService();
  final databaseReference = FirebaseDatabase.instance.reference();
  late FirebaseAuth _auth;

  String? username;
  String? deviceName;
  String? units;
  int selectedAvatar = 1;
  String avatarURL = 'assets/profile_pictures/avatar1.png';

  TextEditingController _usernameController = TextEditingController();
  TextEditingController _deviceNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  void loadUserData() {
    _auth = FirebaseAuth.instance;
    final user = _auth.currentUser;
    if (user != null) {
      DatabaseReference userReference = databaseReference.child('users').child(user.uid);
      userReference.onValue.listen((event) {
        final dataSnapshot = event.snapshot;
        final userData = dataSnapshot.value as Map<dynamic, dynamic>?;

        if (userData != null) {
          setState(() {
            username = userData['username'] as String?;
            deviceName = userData['deviceName'] as String?;
            units = userData['units'] as String?;
            selectedAvatar = userData['selectedAvatar'] as int? ?? 1;
            avatarURL = userData['avatarURL'] as String? ?? 'assets/profile_pictures/avatar1.png';
            _usernameController.text = username ?? '';
            _deviceNameController.text = deviceName ?? '';
          });
        }
      });
    }
  }

  void saveUserData() async {
    _auth = FirebaseAuth.instance;
    final profanityFilter = ProfanityFilter();
    final user = _auth.currentUser;
    if (user != null && !profanityFilter.hasProfanity(username!)) {
      databaseReference.child('users').child(user.uid).set({
        'username': username,
        'deviceName': deviceName,
        'units': units,
        'selectedAvatar': selectedAvatar,
        'avatarURL': avatarURL,
      });
    }
  }

  void showAvatarSelectionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select Avatar'),
          content: Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            children: List.generate(6, (index) {
              final avatarNumber = index + 1;
              final avatarImagePath = 'assets/profile_pictures/avatar$avatarNumber.png';
              return GestureDetector(
                onTap: () {
                  selectAvatar(avatarNumber);
                  Navigator.pop(context); // Close the dialog
                },
                child: CircleAvatar(
                  backgroundImage: AssetImage(avatarImagePath),
                  radius: 25,
                  backgroundColor: selectedAvatar == avatarNumber ? Colors.blue : Colors.transparent,
                ),
              );
            }),
          ),
        );
      },
    );
  }

  void selectAvatar(int avatarNumber) {
    if (avatarNumber >= 1&& avatarNumber <= 6) {
      setState(() {
        selectedAvatar = avatarNumber;
        avatarURL = 'assets/profile_pictures/avatar$avatarNumber.png';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Profile',
          style: TextStyle(
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: showAvatarSelectionDialog,
              child: Image.asset(avatarURL, width: 120, height: 120),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _usernameController,
              onChanged: (value) {
                setState(() {
                  username = value;
                });
              },
              decoration: InputDecoration(
                labelText: 'Username',
              ),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _deviceNameController,
              onChanged: (value) {
                setState(() {
                  deviceName = value;
                });
              },
              decoration: InputDecoration(
                labelText: 'Device Name',
              ),
            ),
            SizedBox(height: 10),
            ListTile(
              title: Text('Celsius'),
              leading: Radio<String>(
                value: 'Celsius',
                groupValue: units,
                onChanged: (value) {
                  setState(() {
                    units = value;
                  });
                },
              ),
            ),
            ListTile(
              title: Text('Fahrenheit'),
              leading: Radio<String>(
                value: 'Fahrenheit',
                groupValue: units,
                onChanged: (value) {
                  setState(() {
                    units = value;
                  });
                },
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                saveUserData();
              },
              child: Text('Save'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                authService.logout();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => LaunchPage(
                      title: 'Login / Sign Up',
                    ),
                  ),
                );
              },
              child: Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }
}