import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:theresa_test/globals.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_auth.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  //Variables
  String temperatureSymbol = '°C'; // Default to Celsius
  String? units;
  String piRefName = "Wyatt's Pi";
  //List of nights to hold the selected data
  List<Night> nightList = [];
  //Calendar Instance
  //Format for calendar
  CalendarFormat _calendarFormat = CalendarFormat.month;
  //Date and time right now at time of program run
  DateTime _focusedDay = DateTime.now();
  //Date and time that is selected
  DateTime? _selectedDay = DateTime.now();
  //String to store the formatted date
  String? formattedDate;
  //Setting the Auth Service
  AuthService authService = AuthService();
  //Setting last date
  final DateTime lastDayOfYear =
  DateTime(DateTime.now().year, DateTime.now().month, 31);
  //Getting firebase database refernece
  final databaseReference = FirebaseDatabase.instance.ref();
  late FirebaseAuth _auth;
  //Init State
  @override
  void initState() {
    super.initState();
    resetValues();
    listenToDataFromFirebase();
  }

  //Reset values
  void resetValues() {
    // Reset the time values
    activeTime = "";
    totalTime = "";
    sleepTime = "";
    humidity = 0;
    temp = 0;
    sound = 0;
    light = 0;
    ambientLight = 0;
    listTimes.clear();
  }

  //Function to change format of calendar
  void _onFormatChanged(CalendarFormat format) {
    setState(() {
      _calendarFormat = format;
    });
  }

  //Firebase and data display setup
  //Convert Celsius to Fahrenheit
  double convertToF(temp) {
    return (temp * 9 / 5) + 32;
  }

  //Converts an int of seconds into hours
  double convertSecondsToHours(int seconds) {
    return seconds / 60 / 60;
  }

  //Converts and int to seconds into minutes
  double convertSecondsToMinutes(int seconds) {
    return seconds / 60;
  }

  //Converts seconds from epoch to 12 hour time
  String convertEpochTo12HourTime(int epochTime) {
    // Create a DateTime object from the epoch timestamp
    DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(epochTime * 1000);

    // Create a DateFormat object to format the time
    DateFormat format = DateFormat('h:mm a');

    // Format the DateTime object to 12-hour time
    String formattedTime = format.format(dateTime);

    return formattedTime;
  }

  //Function gets the data from firebase and populates lists and classes for later usage
  //Sets an instance ref so we can use that as a shortcut when using firebase methods
  final DatabaseReference database = FirebaseDatabase.instance.ref();

  void listenToDataFromFirebase() {
    print("Retrieving Data");
    _auth = FirebaseAuth.instance;
    final user = _auth.currentUser;

    if (user != null) {
      DatabaseReference userReference =
      databaseReference.child('users').child(user.uid);
      userReference.onValue.listen((event) {
        final dataSnapshot = event.snapshot;
        final userData = dataSnapshot.value as Map<dynamic, dynamic>?;

        if (userData != null) {
          setState(() {
            // Retrieve deviceName and replace special character
            if (userData['deviceName'] != null) {
              piRefName = userData['deviceName'] as String;
              piRefName = piRefName.replaceAll("’", "'");
            }
            units = userData['units'] as String?;
          });

          DatabaseReference dateRef =
          database.child("devices").child(piRefName);
          dateRef.onValue.listen((event) {
            final snapshot = event.snapshot;
            final data = snapshot.value as Map<dynamic, dynamic>?;

            if (data != null) {
              final List<Night> updatedNightList = [];
              data.forEach((date, captures) {
                List<Motion> motionList = [];
                List<int> motionTimes = [];
                String color = "none";

                captures.forEach((capture, value) {
                  if (capture != "color") {
                    int ambientLight = value['AmbientLight'];
                    double humidity = value['Humidity'];
                    double lux = value['Lux'];
                    double tempC = value['Temperature'];
                    double temp = 0;

                    // Convert temperature based on units
                    if (units == "Fahrenheit") {
                      temp = convertToF(tempC);
                      temperatureSymbol = '°F';
                    } else {
                      temp = tempC;
                      temperatureSymbol = '°C';
                    }

                    int timeTaken = (value['Time']).toInt();
                    double soundLevel = value['Sound'];
                    double motionLevel = value['MotionLevel'];

                    Motion thisMotion = Motion(
                      ambientLight: ambientLight,
                      humidity: humidity,
                      lux: lux,
                      temp: temp,
                      timeTaken: timeTaken,
                      soundLevel: soundLevel,
                      motionLevel: motionLevel,
                    );

                    motionList.add(thisMotion);
                    motionTimes.add(timeTaken);
                  } else {
                    color = value;
                  }
                });

                Night newNight = Night(
                  sleepTimeSeconds: 0,
                  totalTimeSeconds: 0,
                  activeTimeSeconds: 0,
                  date: date,
                  motion: motionList,
                  color: color,
                );

                updatedNightList.add(newNight);
              });

              setState(() {
                nightList = updatedNightList;

                // Update selected day if it exists
                if (_selectedDay != null) {
                  selectDate(_selectedDay!);
                }
              });
            }
          }, onError: (error) {
            print('Failed to retrieve data: $error');
          });
        }
      });
    }
  }

  void selectDate(DateTime selectedDay) {
    setState(() {
      _selectedDay = selectedDay;
      formattedDate = DateFormat('yyyy-MM-dd').format(selectedDay);
      print(formattedDate);
      thisDate = formattedDate!;

      Night? selectedNight = nightList.firstWhere(
            (night) => night.date == formattedDate,
        orElse: () => Night(
          sleepTimeSeconds: 0,
          totalTimeSeconds: 0,
          activeTimeSeconds: 0,
          date: "",
          motion: [],
          color: "none",
        ),
      );

      resetValues();

      if (selectedNight != null) {
        for (var motion in selectedNight.motion) {
          List<Motion> motionList = selectedNight.motion;
          int count = 0;
          listTimes.clear();
          for (var data in motionList) {
            count++;
            humidity += data.humidity;
            temp += data.temp;
            sound += data.soundLevel;
            light += data.lux;
            ambientLight += data.ambientLight;
            listTimes.add(data.timeTaken);
          }
          humidity /= count;
          temp /= count;
          sound /= count;
          light /= count;
          ambientLight /= count;

          humidity = double.parse(humidity.toStringAsFixed(1));
          temp = double.parse(temp.toStringAsFixed(1));
          sound = double.parse(sound.toStringAsFixed(1));
          light = double.parse(light.toStringAsFixed(1));
          ambientLight = double.parse(ambientLight.toStringAsFixed(1));
        }
      } else {
        totalTime = "0 minutes 0 Seconds";
        activeTime = "0 minutes 0 Seconds";
        sleepTime = "0 minutes 0 Seconds";
      }
    });
  }

//User Interface
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // Disable the back arrow
        title: const Text(
          'Home',
          style: TextStyle(
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            //Creating our calendar
            TableCalendar(
              //Focused day is the day and time right now
              focusedDay: _focusedDay,
              //First day of calendar
              firstDay: DateTime.utc(2021, 1, 1),
              //Last day accessible
              lastDay: lastDayOfYear,
              //Calendar format, set to month with option for 2 weeks or wee
              calendarFormat: _calendarFormat,
              //Returns the function is the selected day the same day as a different test
              selectedDayPredicate: (day) {
                return isSameDay(_selectedDay, day);
              },
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, date, events) {
                  // Find the corresponding night in the nightList
                  Night? selectedNight = nightList.firstWhere(
                        (night) =>
                    night.date == DateFormat('yyyy-MM-dd').format(date),
                    orElse: () => Night(
                        sleepTimeSeconds: 0,
                        totalTimeSeconds: 0,
                        activeTimeSeconds: 0,
                        date: "",
                        motion: [],
                        color: "none"),
                  );
                  // Check if a night is found and the temp field is not equal to 0
                  if (selectedNight != null &&
                      selectedNight.motion.any((motion) => motion.temp != 0)) {
                    // Return a colored dot for the marker
                    Color markerColor = Colors.grey;
                    if (selectedNight.color == "green") {
                      markerColor = Colors.green;
                    } else if (selectedNight.color == "yellow") {
                      markerColor = Colors.yellow;
                    } else if (selectedNight.color == "red") {
                      markerColor = Colors.red;
                    } else {
                      markerColor = Colors.grey;
                    }
                    return Container(
                      margin: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: markerColor,
                      ),
                      height: 5,
                      width: 5,
                    );
                  }

                  // Return an empty container if no marker should be shown
                  return Container();
                },
              ),
              //When a day is selected run this code
              onDaySelected: (selectedDay, focusedDay) {
                //Changes the UI or screen, it will run code inside and set the screen to show the changes
                setState(() {
                  // Change selected day to selected day
                  _selectedDay = selectedDay;
                  // Format the selected date as "yyyy-mm-dd"
                  formattedDate = DateFormat('yyyy-MM-dd').format(selectedDay);
                  print(formattedDate);
                  thisDate = formattedDate!;
                  // Change focused day to focused day
                  _focusedDay = focusedDay;

                  // Find the corresponding night in the nightList
                  Night? selectedNight = nightList.firstWhere(
                        (night) => night.date == formattedDate,
                    orElse: () => Night(
                      sleepTimeSeconds: 0,
                      totalTimeSeconds: 0,
                      activeTimeSeconds: 0,
                      date: "",
                      motion: [],
                      color: "none",
                    ),
                  );

                  // Reset the time values
                  resetValues();

                  // If a night is found, calculate the time values
                  if (selectedNight != null) {
                    for (var motion in selectedNight.motion) {
                      List<Motion> motionList = selectedNight.motion;
                      int count = 0;
                      listTimes.clear();
                      for (var data in motionList) {
                        count++;
                        humidity += data.humidity;
                        temp += data.temp;
                        sound += data.soundLevel;
                        light += data.lux;
                        ambientLight += data.ambientLight;
                        listTimes.add(data.timeTaken);
                      }
                      //Get the averages
                      humidity /= count;
                      temp /= count;
                      sound /= count;
                      light /= count;
                      ambientLight /= count;

                      //Round averages off
                      humidity = double.parse(humidity.toStringAsFixed(1));
                      temp = double.parse(temp.toStringAsFixed(1));
                      sound = double.parse(sound.toStringAsFixed(1));
                      light = double.parse(light.toStringAsFixed(1));
                      ambientLight =
                          double.parse(ambientLight.toStringAsFixed(1));
                    }
                  } else {
                    totalTime = "0 minutes 0 Seconds";
                    activeTime = "0 minutes 0 Seconds";
                    sleepTime = "0 minutes 0 Seconds";
                  }

                  //Calculate the total time by subtracting the first and last times
                  int calculateTotalTime() {
                    //Sort data from least to greatest
                    listTimes.sort();
                    int firstTime = listTimes.first;
                    int lastTime = listTimes.last;
                    if (firstTime == lastTime) {
                      //If there is only one time return 0
                      return 0;
                    } else {
                      return lastTime - firstTime;
                    }
                  }

                  //Calculate active time
                  int calculateActiveTime() {
                    if(calculateTotalTime() < 700){
                      return listTimes.length * 30;
                    }else{
                      return listTimes.length * 30 + 700;
                    }
                  }

                  //Calculates the sleep time by subtracting the total time by the active time
                  int calculateSleepTime() {
                    return calculateTotalTime() - calculateActiveTime();
                  }

                  //Converts int seconds to a string in minutes and hours
                  String convertSecondsToString(int seconds) {
                    double totalMinutes = seconds / 60;
                    int hours = (totalMinutes / 60).toInt();
                    int minutes = (totalMinutes.toInt() - (hours * 60));
                    return "$hours hours $minutes minutes";
                  }

                  //Get the time data if there is some, if not set the no sleep data
                  if (listTimes.isNotEmpty) {
                    //Calculate the total times
                    totalTime = convertSecondsToString(calculateTotalTime());
                    //Store the active time
                    activeTime = convertSecondsToString(calculateActiveTime());
                    //Store the sleep time
                    sleepTime = convertSecondsToString(calculateSleepTime());
                  }
                });
              },
              // Display the calendar style
              calendarStyle: const CalendarStyle(
                // Today's style
                todayDecoration: BoxDecoration(
                  color: Colors.pink,
                  shape: BoxShape.circle,
                ),
                // Selected day style
                selectedDecoration: BoxDecoration(
                  color: Colors.pinkAccent,
                  shape: BoxShape.circle,
                ),

                // Format of the selected day text
                selectedTextStyle: TextStyle(color: Colors.white),
                // Format of the day text
                // Format of the weekend day text
                weekendTextStyle: TextStyle(color: Colors.black),
              ),
              // Display the header style
              headerStyle: const HeaderStyle(
                titleTextStyle: TextStyle(fontSize: 20),
                formatButtonVisible: true,
              ),
              // Available calendar formats
              availableCalendarFormats: const {
                CalendarFormat.month: 'Month',
                CalendarFormat.twoWeeks: '2 weeks',
                CalendarFormat.week: 'Week',
              },
              // Change the format of the calendar
              onFormatChanged: _onFormatChanged,
            ),
            // Display the selected date and time values
            const SizedBox(height: 40),
            //If there is a temperature reading on this day show data otherwise show no data found
            // If there is a temperature reading on this day show data otherwise show no data found
            if (temp != 0)
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Total Time text
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Total Time:',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '$totalTime',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Sleep Time text
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Sleep Time:',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '$sleepTime',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Active Time text
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Active Time:',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                activeTime,
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Humidity Text
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Humidity:',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '$humidity %',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Temperature
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Temperature:',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '$temp $temperatureSymbol',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Light
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Light:',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '$light lx',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Ambient Light
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Ambient Light:',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '$ambientLight lx',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Sound Level
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Sound Level:',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '$sound dB',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              const Text(
                'No sleep data available.',
                style: TextStyle(fontSize: 16),
              ),
            //clear the sleep suggestions
          ],
        ),
      ),
    );
  }
}

class Night {
  final int sleepTimeSeconds;
  final int totalTimeSeconds;
  final int activeTimeSeconds;
  final String date;
  final List<Motion> motion;
  final String color;

  Night({
    required this.sleepTimeSeconds,
    required this.totalTimeSeconds,
    required this.activeTimeSeconds,
    required this.date,
    required this.motion,
    required this.color,
  });
}

class Motion {
  final int ambientLight;
  final double humidity;
  final double lux;
  final double temp;
  final int timeTaken;
  final double soundLevel;
  final double motionLevel;

  Motion({
    required this.ambientLight,
    required this.humidity,
    required this.lux,
    required this.temp,
    required this.timeTaken,
    required this.soundLevel,
    required this.motionLevel,
  });
}