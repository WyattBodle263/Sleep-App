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
  late FirebaseAuth _auth;
  late DatabaseReference _userRef;
  late DatabaseReference _postsRef;
  late TextEditingController _postController;
  List<Map<String, dynamic>> _posts = [];

  @override
  void initState() {
    super.initState();
    _auth = FirebaseAuth.instance;
    _userRef = FirebaseDatabase.instance.reference().child('users').child(_auth.currentUser!.uid);
    _postsRef = FirebaseDatabase.instance.reference().child('posts');
    _postController = TextEditingController();
    _loadPosts();
  }

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

  @override
  void dispose() {
    _postController.dispose();
    super.dispose();
  }

  Future<void> _submitPost() async {
    final profanityFilter = ProfanityFilter(); // Create an instance of the profanity filter

    if (_postController.text.trim() != "" && !profanityFilter.hasProfanity(_postController.text.trim())) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final DateTime now = DateTime.now();
        final int timestamp = now.millisecondsSinceEpoch ~/ 1000;
        final String postKey = '${user.uid}-$timestamp';

        final DatabaseReference userRef = FirebaseDatabase.instance.reference().child('users').child(user.uid);
        final DataSnapshot userSnapshot = await userRef.get();
        final Map<dynamic, dynamic>? userData = userSnapshot.value as Map<dynamic, dynamic>?;

        final username = userData?['username'] as String? ?? 'anonymous';
        final avatarURL = userData?['avatarURL'] as String? ?? 'assets/profile_pictures/avatar1.png';

        final post = {
          'postKey': postKey,
          'username': username,
          'avatarURL': avatarURL,
          'timestamp': timestamp.toString(),
          'text': _postController.text.trim(),
          'likes': 0,
          'likedBy': [], // Initialize likedBy as an empty list
        };

        setState(() {
          _posts.insert(0, post);
        });

        final DatabaseReference postRef = _postsRef.child(postKey);
        await postRef.set(post);

        _postController.clear();
      }
    }
  }

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