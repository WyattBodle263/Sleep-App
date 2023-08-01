import 'package:flutter/material.dart';
import 'package:theresa_test/globals.dart';

class SuggestionsPage extends StatefulWidget {
  const SuggestionsPage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<SuggestionsPage> createState() => _SuggestionsPageState();
}

class _SuggestionsPageState extends State<SuggestionsPage> {
  List<String> sleepSuggestions = [];

  // Function to check sleep suggestions based on various environmental factors
  void checkSleepSuggestions() {
    // Clear the sleepSuggestions list before adding new suggestions
    sleepSuggestions.clear();

    try {
      // Check humidity levels
      if (humidity < 30.0 || humidity > 60.0) {
        if (humidity < 30.0) {
          // Humidity is too low for ideal sleep, suggest using a humidifier
          sleepSuggestions.add('Humidity levels too low for ideal sleep. Consider using a humidifier.');
        } else {
          // Humidity is too high for ideal sleep, suggest opening a window or using a dehumidifier
          sleepSuggestions.add('Humidity levels too high for ideal sleep. Consider opening a window or using a dehumidifier.');
        }
      }

      // Check light levels
      if (light > 30.0) {
        // Light levels are too high for ideal sleep, suggest removing any light sources
        sleepSuggestions.add('Light levels too high for ideal sleep. Consider removing any light sources.');
      }

      // Check ambient light levels
      if (ambientLight > 200.0) {
        // Ambient light levels are too high for ideal sleep, suggest removing any light sources
        sleepSuggestions.add('Ambient light levels too high for ideal sleep. Consider removing any light sources.');
      }

      // Check temperature levels
      if (temp <= 60.0 || temp >= 75.0) {
        if (temp <= 60.0) {
          // Temperature levels are too low for ideal sleep, suggest raising the temperature
          sleepSuggestions.add('Temperature levels too low for ideal sleep. Consider raising the temperature.');
        } else {
          // Temperature levels are too high for ideal sleep, suggest lowering the temperature
          sleepSuggestions.add('Temperature levels too high for ideal sleep. Consider lowering the temperature.');
        }
      }

      // Check total sleep time
      if (totalTime.isNotEmpty) {
        int sleepTime = int.parse(totalTime.split(' ')[0]);
        if (sleepTime < 7) {
          // Suggest getting more sleep if sleep time is less than 7 hours
          sleepSuggestions.add('You may need more sleep. Aim for at least 7 hours.');
        } else if (sleepTime > 12) {
          // Suggest reducing total sleep time if sleep time is more than 12 hours
          sleepSuggestions.add('You may be oversleeping. Consider reducing your total sleep time.');
        }
      }
    } catch (e) {
      // Handle any errors that occur during parsing
      print('Error parsing total time: $e');
    }

  }


  @override
  void initState() {
    super.initState();
    checkSleepSuggestions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFFCFB1B0),
        automaticallyImplyLeading: false, // Disable the back arrow
        title: const Text(
          'Sleep Suggestions',
          style: TextStyle(
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                '${thisDate}',
                style: TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 10.0),
            if (temp != 0 && sleepSuggestions.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: sleepSuggestions.map((suggestion) => ListTile(
                  leading: Icon(
                    Icons.circle,
                    size: 10.0,
                    color: Theme.of(context).primaryColor,
                  ),
                  title: Text(
                    suggestion,
                    style: const TextStyle(fontSize: 16.0),
                  ),
                )).toList(),
              )
            else
              const Center(
                child: Text(
                  'No sleep suggestions',
                  style: TextStyle(fontSize: 16.0),
                ),
              ),
          ],
        ),
      ),
    );
  }
}