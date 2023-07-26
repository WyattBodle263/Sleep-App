import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class LogPage extends StatefulWidget {
  const LogPage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<LogPage> createState() => _LogPageState();
}

class _LogPageState extends State<LogPage> {
  late DatabaseReference _logsReference;
  late List<Log> _logs;

  late FirebaseAuth _auth;

  DateTime selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    Firebase.initializeApp();
    _auth = FirebaseAuth.instance;
    final user = _auth.currentUser;
    if (user != null) {
      _logsReference =
          FirebaseDatabase.instance.ref().child('logs').child(user.uid);
      _logs = [];
      _fetchLogs();
    }
  }
  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _fetchLogs() async {
    DataSnapshot snapshot = (await _logsReference.once()).snapshot;
    Map<dynamic, dynamic>? logsMap = snapshot.value as Map<dynamic, dynamic>?;

    if (logsMap != null) {
      List<Log> logs = [];
      logsMap.forEach((key, value) {
        Log log = Log.fromMap(key, value);
        logs.add(log);
      });
      setState(() {
        _logs = logs;
      });
    }
  }

  Future<void> _addLog() async {
    final user = _auth.currentUser;
    if (user != null) {
      final TextEditingController logController = TextEditingController();
      SleepQuality selectedSleepQuality = SleepQuality.good;
      DateTime selectedDate = DateTime.now();

      await showDialog(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return AlertDialog(
                title: const Text('New Log'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: logController,
                      decoration: const InputDecoration(
                        labelText: 'Log',
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Sleep Quality'),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              selectedSleepQuality = SleepQuality.good;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: selectedSleepQuality == SleepQuality.good
                                ? Colors.green
                                : null,
                          ),
                          child: const Text('Good'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              selectedSleepQuality = SleepQuality.average;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: selectedSleepQuality == SleepQuality.average
                                ? Colors.yellow
                                : null,
                          ),
                          child: const Text('Average'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              selectedSleepQuality = SleepQuality.poor;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: selectedSleepQuality == SleepQuality.poor
                                ? Colors.red
                                : null,
                          ),
                          child: const Text('Poor'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                        'Selected Date: ${DateFormat('yyyy-MM-dd').format(selectedDate)}'),
                    ElevatedButton(
                      onPressed: () {
                        showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        ).then((DateTime? pickedDate) {
                          if (pickedDate != null) {
                            setState(() {
                              selectedDate = pickedDate;
                            });
                          }
                        });
                      },
                      child: const Text('Select Date'),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      final newLog = Log(
                        logController.text,
                        selectedSleepQuality,
                        selectedDate,
                      );

                      //Add log to database
                      final logPath = '${user.uid}/${DateFormat('yyyy-MM-dd').format(selectedDate)}';
                      final logReference = FirebaseDatabase.instance
                          .ref()
                          .child('logs')
                          .child(logPath);

                      await logReference.set(newLog.toMap());
                      //Change color in day
                      final colorPath = 'devices/Wyatt\'s Pi/${DateFormat('yyyy-MM-dd').format(selectedDate)}';
                      final colorReference = FirebaseDatabase.instance.ref().child(colorPath);
                      String color = "grey";
                      //Set the color for the database ref
                      if(selectedSleepQuality == SleepQuality.good){
                        color = "green";
                      }else if(selectedSleepQuality == SleepQuality.average){
                        color = "yellow";
                      }else if(selectedSleepQuality == SleepQuality.poor){
                        color = "red";
                      }else{
                        color = "grey";
                      }
                      Map<String, dynamic> updateData = {
                        'color': color,
                      };

                      await colorReference.update(updateData);

                      _fetchLogs();
                      Navigator.of(context).pop();
                    },
                    child: const Text('Save'),
                  ),
                ],
              );
            },
          );
        },
      );
    } else {
      print('User not authenticated or does not have admin privilege.');
    }
  }

  Color _getSleepQualityColor(SleepQuality sleepQuality) {
    switch (sleepQuality) {
      case SleepQuality.good:
        return Colors.green;
      case SleepQuality.average:
        return Colors.yellow;
      case SleepQuality.poor:
        return Colors.red;
      default:
        return Colors.transparent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // Disable the back arrow
        title: const Text(
          'Log',
          style: TextStyle(
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Center(
        child: ListView.builder(
          itemCount: _logs.length,
          itemBuilder: (context, index) {
            final log = _logs[index];
            return Column(
              children: [
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getSleepQualityColor(log.sleepQuality),
                    radius: 10,
                  ),
                  title: Text(log.text),
                  subtitle: Text(DateFormat('yyyy-MM-dd').format(log.date)),
                ),
                if (index < _logs.length - 1)
                  const Divider(
                    color: Colors.grey,
                    height: 1,
                    thickness: 1,
                  ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addLog,
        child: const Icon(Icons.add),
      ),
    );
  }
}

enum SleepQuality {
  good,
  average,
  poor,
}

class Log {
  final String text;
  final SleepQuality sleepQuality;
  final DateTime date;

  Log(this.text, this.sleepQuality, this.date);

  Log.fromMap(String key, Map<dynamic, dynamic> map)
      : text = map['text'] ?? '',
        sleepQuality = _mapToSleepQuality(map['quality']),
        date =
        map['date'] != null ? DateTime.parse(map['date']) : DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'quality': _sleepQualityToMap(sleepQuality),
      'date': date.toString(),
    };
  }

  static SleepQuality _mapToSleepQuality(String quality) {
    switch (quality) {
      case 'good':
        return SleepQuality.good;
      case 'average':
        return SleepQuality.average;
      case 'poor':
        return SleepQuality.poor;
      default:
        return SleepQuality.good;
    }
  }

  static String _sleepQualityToMap(SleepQuality sleepQuality) {
    switch (sleepQuality) {
      case SleepQuality.good:
        return 'good';
      case SleepQuality.average:
        return 'average';
      case SleepQuality.poor:
        return 'poor';
      default:
        return 'good';
    }
  }
}