import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database/firebase_database.dart' show DataSnapshot, DatabaseEvent;
import 'package:profanity_filter/profanity_filter.dart';

class CommunityPage extends StatefulWidget {
  const CommunityPage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  //Create instances of firebase objects
  late FirebaseAuth _auth;
  late DatabaseReference _userRef;
  late DatabaseReference _postsRef;
  late TextEditingController _postController;
  List<Map<String, dynamic>> _posts = [];

  @override
  void initState() {
    super.initState();
    //Initialize all of the variables
    _auth = FirebaseAuth.instance;
    _userRef = FirebaseDatabase.instance.reference().child('users').child(_auth.currentUser!.uid);
    _postsRef = FirebaseDatabase.instance.reference().child('posts');
    _postController = TextEditingController();
    _loadPosts();
  }

  //Function to load the posts to the community page
  Future<void> _loadPosts() async {
    final DatabaseEvent event = await _postsRef.orderByChild('timestamp').once();
    final DataSnapshot snapshot = event.snapshot;
    final dynamic postsData = snapshot.value;

    if (postsData != null) {
      final List<Map<String, dynamic>> postsList = [];
      if (postsData is Map<dynamic, dynamic>) {
        postsData.forEach((key, value) {
          final post = Map<String, dynamic>.from(value as Map).cast<String, dynamic>();
          postsList.add(post);
        });
      }

      postsList.sort((a, b) {
        final int timestampA = int.parse(a['timestamp']);
        final int timestampB = int.parse(b['timestamp']);
        return timestampB.compareTo(timestampA); // Compare timestamps in descending order
      });

      setState(() {
        _posts = postsList;
      });
    }
  }

  //Dispose of post controller
  @override
  void dispose() {
    _postController.dispose();
    super.dispose();
  }

  // Function to submit a post to Firebase
  Future<void> _submitPost() async {
    // Create an instance of the profanity filter
    final profanityFilter = ProfanityFilter();

    // Check if the post text is not empty and does not contain profanity
    if (_postController.text.trim() != "" && !profanityFilter.hasProfanity(_postController.text.trim())) {

      // Get the current user from FirebaseAuth
      final user = FirebaseAuth.instance.currentUser;

      // Proceed if the user is authenticated
      if (user != null) {
        // Get the current date and time as milliseconds since epoch
        final DateTime now = DateTime.now();
        final int timestamp = now.millisecondsSinceEpoch ~/ 1000;

        // Generate a unique post key based on user ID and timestamp
        final String postKey = '${user.uid}-$timestamp';

        // Get the user data from the Firebase Realtime Database
        final DatabaseReference userRef = FirebaseDatabase.instance.reference().child('users').child(user.uid);
        final DataSnapshot userSnapshot = await userRef.get();
        final Map<dynamic, dynamic>? userData = userSnapshot.value as Map<dynamic, dynamic>?;

        // Get the username and avatarURL from the user data, use 'anonymous' if not available
        final username = userData?['username'] as String? ?? 'anonymous';
        final avatarURL = userData?['avatarURL'] as String? ?? 'assets/profile_pictures/avatar1.png';

        // Create a post object with necessary data
        final post = {
          'postKey': postKey,             // Unique key for the post
          'username': username,           // Username of the author
          'avatarURL': avatarURL,         // URL of the author's avatar
          'timestamp': timestamp.toString(), // Timestamp of the post creation
          'text': _postController.text.trim(), // Text content of the post
          'likes': 0,                     // Initial number of likes (set to zero)
          'likedBy': [],                  // Initialize likedBy as an empty list
        };

        // Insert the post at the beginning of the posts list
        setState(() {
          _posts.insert(0, post);
        });

        // Get a reference to the post location in the Firebase Realtime Database
        final DatabaseReference postRef = _postsRef.child(postKey);

        // Save the post data to the Firebase Realtime Database
        await postRef.set(post);

        // Clear the post input field after successful submission
        _postController.clear();
      }
    }
  }
  
  //Function to like a post
  Future<void> _likePost(String postKey) async {
    final DatabaseReference postRef = _postsRef.child(postKey);
    final DataSnapshot postSnapshot = await postRef.get();
    final Map<dynamic, dynamic>? postData = postSnapshot.value as Map<dynamic, dynamic>?;

    if (postData != null) {
      final user = FirebaseAuth.instance.currentUser;
      List<dynamic> likedBy = List.from(postData['likedBy'] ?? []);

      if (user != null) {
        if (likedBy.contains(user.uid)) {
          likedBy.remove(user.uid); // Remove user ID from likedBy if already liked
        } else {
          likedBy.add(user.uid); // Add user ID to likedBy if not already liked
        }
      }

      final int currentLikes = likedBy.length;

      await postRef.update({
        'likes': currentLikes,
        'likedBy': likedBy,
      });

      setState(() {
        // Replace the existing post in _posts with the updated copy
        _posts = _posts.map((post) {
          if (post['postKey'] == postKey) {
            return {
              ...post,
              'likes': currentLikes,
              'likedBy': likedBy,
            };
          }
          return post;
        }).toList();
      });
    }
  }


  Widget _buildPostTile(Map<String, dynamic> post) {
    final username = post['username'] ?? 'anonymous';
    final avatarURL = post['avatarURL'] ?? '//assets/profile_pictures/avatar1.png';
    final timestamp = DateTime.fromMillisecondsSinceEpoch(int.parse(post['timestamp']) * 1000);

    final hour = timestamp.hour > 12 ? timestamp.hour - 12 : timestamp.hour;
    final period = timestamp.hour >= 12 ? 'PM' : 'AM';

    final formattedDate =
        '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')} $hour:${timestamp.minute.toString().padLeft(2, '0')} $period';

    final user = FirebaseAuth.instance.currentUser;
    final List<dynamic> likedBy = post['likedBy'] ?? [];
    final bool isLiked = user != null && likedBy.contains(user.uid);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              backgroundImage: avatarURL.startsWith('http') ? NetworkImage(avatarURL) : AssetImage(avatarURL) as ImageProvider<Object>?,
            ),
            const SizedBox(width: 8.0),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  username,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  formattedDate,
                  style: const TextStyle(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8.0),
        Text(post['text']),
        Row(
          children: [
            IconButton(
              onPressed: () => _likePost(post['postKey'] as String),
              icon: Icon(
                Icons.favorite,
                color: isLiked ? Colors.red : null, // Set color to red if liked
              ),
            ),
            Text('${post['likes'] ?? 0}'),
          ],
        ),
        const Divider(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFFCFB1B0),
        automaticallyImplyLeading: false,
        title: const Text(
          'Community',
          style: TextStyle(
            fontSize:            20.0,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ListView.builder(
                itemCount: _posts.length,
                itemBuilder: (context, index) {
                  final post = _posts[index];
                  return _buildPostTile(post);
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _postController,
                    decoration: const InputDecoration(
                      hintText: 'Write your post...',
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _submitPost,
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}