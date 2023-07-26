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

  void checkSleepSuggestions() {
    sleepSuggestions.clear(); // Clear the sleepSuggestions list

    print(temp);
    try {
      if (humidity < 30.0 || humidity > 60.0) {
        if (humidity < 30.0) {
          sleepSuggestions.add('Humidity levels too low for ideal sleep. Consider using a humidifier.');
        } else {
          sleepSuggestions.add('Humidity levels too high for ideal sleep. Consider opening a window or using a dehumidifier.');
        }
      }

      if (light > 30.0){
        sleepSuggestions.add('Light levels too high for ideal sleep. Consider removing any light sources.');
      }

      if (ambientLight > 200.0) {
        sleepSuggestions.add('Ambient light levels too high for ideal sleep. Consider removing any light sources.');
      }
      print(temp);
      if (temp <= 60.0 || temp >= 75.0) {
        if(temp <= 60.0){
          sleepSuggestions.add('Temperature levels too low for ideal sleep. Consider raising the temperature.');
        }else{
          sleepSuggestions.add('Temperature levels too high for ideal sleep. Consider lowering the temperature.');
        }
      }

      if (totalTime.isNotEmpty) {
        int sleepTime = int.parse(totalTime.split(' ')[0]);
        if (sleepTime < 7) {
          sleepSuggestions.add('You may need more sleep. Aim for at least 7 hours.');
        } else if (sleepTime > 12) {
          sleepSuggestions.add('You may be oversleeping. Consider reducing your total sleep time.');
        }
      }
    } catch (e) {
      print('Error parsing total time: $e');
    }

    setState(() {
      // Update the state with the sleep suggestions
    });
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