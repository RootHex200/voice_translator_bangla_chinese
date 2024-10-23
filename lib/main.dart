import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart'; // For timestamp formatting

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
  late FlutterSoundRecorder _recorder;
  late String _filePath;
  bool _isBanglaRecording = false;
  bool _isChineseRecording = false;
  String? _selectedLanguagePair = "Bangla to Chinese"; // Default selection

  @override
  void initState() {
    super.initState();
    _flutterTts = FlutterTts();
    _recorder = FlutterSoundRecorder();
    _initRecorder();
  }

  Future _initRecorder() async {
    await Permission.microphone.request();
    await Permission.storage.request();
    await _recorder.openRecorder();
  }

  // Generate a unique file path for the recording
  Future<String> _generateUniqueFilePath() async {
    final dir =
        await getApplicationDocumentsDirectory(); // Get the app directory
    final timestamp = DateFormat('yyyyMMdd_HHmmss')
        .format(DateTime.now()); // Create a timestamp
    return '${dir.path}/recorded_voice_$timestamp.wav'; // Unique file name
  }

  // Record Bangla voice and save in .wav format
  Future<void> _recordBangla() async {
    if (_isBanglaRecording) return;

    _filePath = await _generateUniqueFilePath();
    await _recorder.startRecorder(toFile: _filePath, codec: Codec.pcm16WAV);
    setState(() {
      _isBanglaRecording = true;
    });
  }

  // Stop recording and send to Python server for Bangla to Chinese translation
  Future<void> _stopAndTranslateBanglaToChinese() async {
    if (!_isBanglaRecording) return;
    await _recorder.stopRecorder();
    setState(() {
      _isBanglaRecording = false;
    });

    // log("Bangla audio recorded at: $_filePath");
    final request = http.MultipartRequest(
      'POST',
      Uri.parse(
          'https://sabitur.hitaishi.com.bd/voice/bangla_voice_to_chinese_voice'),
    );
    request.files.add(await http.MultipartFile.fromPath('file', _filePath));

    final response = await request.send();
    if (response.statusCode == 200) {
      final translatedText = await response.stream.bytesToString();
      _speakChinese(translatedText);
    } else {
    }
  }

  // Record Chinese voice and save in .wav format
  Future<void> _recordChinese() async {
    if (_isChineseRecording) return;

    _filePath = await _generateUniqueFilePath();
    await _recorder.startRecorder(toFile: _filePath, codec: Codec.pcm16WAV);
    setState(() {
      _isChineseRecording = true;
    });
  }

  // Stop recording and send to Python server for Chinese to Bangla translation
  Future<void> _stopAndTranslateChineseToBangla() async {
    if (!_isChineseRecording) return;
    await _recorder.stopRecorder();
    setState(() {
      _isChineseRecording = false;
    });

    log("Chinese audio recorded at: $_filePath");
    final request = http.MultipartRequest(
      'POST',
      Uri.parse(
          'https://sabitur.hitaishi.com.bd/voice/chinese_voice_to_bangla'),
    );
    request.files.add(await http.MultipartFile.fromPath('file', _filePath));

    final response = await request.send();
    if (response.statusCode == 200) {
      final translatedText = await response.stream.bytesToString();
      _speakBangla(translatedText);
    } else {
    }
  }

  // Text-to-Speech function to speak Bangla
  Future<void> _speakBangla(String text) async {
    await _flutterTts.setLanguage("bn-BD");
    await _flutterTts.speak(text);
  }

  // Text-to-Speech function to speak Chinese
  Future<void> _speakChinese(String text) async {
    await _flutterTts.setLanguage("zh-CN");
    await _flutterTts.speak(text);
  }

  @override
  void dispose() {
    _recorder.closeRecorder();
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xff001f4d),
        title: const Text(
          'Voice Translator',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(
                "assets/images/bg.jpg"), // Replace with your actual image path
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding:const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.white, // Set the background color to white
                    borderRadius:
                        BorderRadius.circular(5.0), // Set the border radius
                  ),
                  child: DropdownButton<String>(
                    value: _selectedLanguagePair,
                    items: const [
                      DropdownMenuItem(
                        value: "Bangla to Chinese",
                        child: Text("Bangla to Chinese"),
                      ),
                      DropdownMenuItem(
                        value: "Chinese to Bangla",
                        child: Text("Chinese to Bangla"),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedLanguagePair = value!;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 20),

                // Conditionally show record button based on selection
                if (_selectedLanguagePair == "Bangla to Chinese") ...[
                  const Text(
                    "Bangla To Chinese",
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  GestureDetector(
                    onTap: _isBanglaRecording
                        ? _stopAndTranslateBanglaToChinese
                        : _recordBangla,
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.pinkAccent,
                      child: _isBanglaRecording
                          ? const Icon(
                              Icons.record_voice_over,
                              size: 40,
                            )
                          : const Icon(
                              Icons.mic,
                              size: 40,
                            ),
                    ),
                  ),
                ] else if (_selectedLanguagePair == "Chinese to Bangla") ...[
                  const Text(
                    "Chinese To Bangla",
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  GestureDetector(
                    onTap: _isChineseRecording
                        ? _stopAndTranslateChineseToBangla
                        : _recordChinese,
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.pinkAccent,
                      child: _isChineseRecording
                          ? const Icon(
                              Icons.record_voice_over,
                              size: 40,
                            )
                          : const Icon(
                              Icons.mic,
                              size: 40,
                            ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
