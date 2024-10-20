
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: VoiceTranslator(),
    );
  }
}

class VoiceTranslator extends StatefulWidget {
  const VoiceTranslator({super.key});

  @override
  _VoiceTranslatorState createState() => _VoiceTranslatorState();
}

class _VoiceTranslatorState extends State<VoiceTranslator> {
  late FlutterTts _flutterTts;

  @override
  void initState() {
    super.initState();
    _flutterTts = FlutterTts();
  }

  Future banglaSpeak() async {
    await _flutterTts.setLanguage("bn-BD");
    await _flutterTts
        .setVoice({"name": "bn-bd-x-ban-network", "locale": "bn-BD"});
    await _flutterTts.speak("আমার নাম সবিতুর।আমি বাংলা ভাষা এ কথা বলতে পারি ");
    // if //result == 1) setState(() => ttsState = TtsState.playing);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bangla to Chinese Translator'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () {
                banglaSpeak();
              },
              child: const Text("click to Listen Bangla"),
            ),
          ],
        ),
      ),
    );
  }
}
