import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
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

    // Generate a unique file path for this recording
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

    log("Bangla audio recorded at: $_filePath");
    // Send the recorded file to the Flask server
    final request = http.MultipartRequest(
      'POST',
      Uri.parse(
          'https://461b-103-60-161-26.ngrok-free.app/bangla_voice_to_chinese_voice'),
    );
    request.files.add(await http.MultipartFile.fromPath('file', _filePath));

    final response = await request.send();
    if (response.statusCode == 200) {
      final translatedText = await response.stream.bytesToString();
      print(translatedText);
      _speakChinese(translatedText);
    } else {
      print('Failed to get response: ${response.statusCode}');
    }
    print("Bangla to Chinese translation request done.");
  }

  // Record Chinese voice and save in .wav format
  Future<void> _recordChinese() async {
    if (_isChineseRecording) return;

    // Generate a unique file path for this recording
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
    // Send the recorded file to the Flask server
    final request = http.MultipartRequest(
      'POST',
      Uri.parse(
          'https://461b-103-60-161-26.ngrok-free.app/chinese_voice_to_bangla'),
    );
    request.files.add(await http.MultipartFile.fromPath('file', _filePath));

    final response = await request.send();
    if (response.statusCode == 200) {
      final translatedText = await response.stream.bytesToString();
      _speakBangla(translatedText);
    } else {
      print('Failed to get response: ${response.statusCode}');
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
        title: const Text('Bangla to Chinese Translator'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _isBanglaRecording ? _stopAndTranslateBanglaToChinese : _recordBangla,
              child: Text(_isBanglaRecording ? "Stop Recording (Bangla)" : "Record Bangla Voice"),
            ),

                        ElevatedButton(
              onPressed: _isChineseRecording ? _stopAndTranslateChineseToBangla : _recordChinese,
              child: Text(_isChineseRecording ? "Stop Recording (Chinese)" : "Record Chinese Voice"),
            ),
          ],
        ),
      ),
    );
  }
}
