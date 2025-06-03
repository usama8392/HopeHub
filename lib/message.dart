import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:hopehub/Account_setting.dart';
import 'package:hopehub/Login.dart';
import 'package:hopehub/Main_Menu.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';

class AudioRecorderPage extends StatefulWidget {
  @override
  _AudioRecorderPageState createState() => _AudioRecorderPageState();
}

class _AudioRecorderPageState extends State<AudioRecorderPage> {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final RecorderController _waveformController = RecorderController();
  bool _isRecording = false;
  bool _isInitialized = false;
  bool _isLoading = false;
  List<String> _sentMessages = [];
  List<PlayerController?> _playerControllers = [];
  List<List<double>> _waveformDataList = [];
  List<Duration> _messageDurations = [];
  List<String> _messageTimestamps = [];

  @override
  void initState() {
    super.initState();
    _initializeRecorder();
  }

  Future<void> _initializeRecorder() async {
    var micPermission = await Permission.microphone.request();
    if (micPermission.isGranted) {
      try {
        await _recorder.openRecorder();
        setState(() => _isInitialized = true);
      } catch (e) {
        print('Error initializing recorder: $e');
      }
    }
  }

  Future<String> _getFilePath({bool isBot = false}) async {
    final directory = await getApplicationDocumentsDirectory();
    final prefix = isBot ? 'bot_response_' : 'audio_';
    return '${directory.path}/$prefix${DateTime.now().millisecondsSinceEpoch}.aac';
  }

  void _startRecording() async {
    if (!_isInitialized) return;
    try {
      final path = await _getFilePath();
      await _recorder.startRecorder(toFile: path, codec: Codec.aacADTS);
      _waveformController.record();
      setState(() => _isRecording = true);
    } catch (e) {
      print('Error starting recorder: $e');
    }
  }

  void _stopRecording() async {
    if (!_isRecording) return;
    try {
      final path = await _recorder.stopRecorder();
      _waveformController.stop();
      if (path != null) {
        final file = File(path);
        print("Sending file path: $path");
        print("File exists: ${file.existsSync()}");
        print("File length: ${file.lengthSync()}");

        await _addAudioMessage(path, isUser: true);
        _addLoadingMessage();
        await _sendToMLModel(path);
      }
      setState(() => _isRecording = false);
    } catch (e) {
      print('Error stopping recorder: $e');
    }
  }

  void _addLoadingMessage() {
    setState(() {
      _sentMessages.add("loading");
      _playerControllers.add(null);
      _waveformDataList.add([]);
      _messageDurations.add(Duration.zero);
      _messageTimestamps.add(TimeOfDay.now().format(context));
    });
  }

  Future<void> _replaceLoadingWithBotAudio(String botPath) async {
    int index = _sentMessages.indexOf("loading");
    if (index != -1) {
      PlayerController controller = PlayerController();
      await controller.preparePlayer(
        path: botPath,
        shouldExtractWaveform: true,
        noOfSamples: 1000,
      );
      List<double>? waveform = await controller.extractWaveformData(path: botPath);
      int durationInMillis = await controller.getDuration();
      Duration duration = Duration(milliseconds: durationInMillis);
      String timestamp = TimeOfDay.now().format(context);

      setState(() {
        _sentMessages[index] = botPath;
        _playerControllers[index] = controller;
        _waveformDataList[index] = waveform ?? [];
        _messageDurations[index] = duration;
        _messageTimestamps[index] = timestamp;
      });

      // Upload bot response audio
      await _uploadMessageToFirebase(botPath, isUser: false);
    }
  }

  Future<void> _addAudioMessage(String path, {required bool isUser}) async {
    PlayerController controller = PlayerController();
    await controller.preparePlayer(
      path: path,
      shouldExtractWaveform: true,
      noOfSamples: 1000,
    );
    List<double>? waveform = await controller.extractWaveformData(path: path);
    int durationInMillis = await controller.getDuration();
    Duration duration = Duration(milliseconds: durationInMillis);
    String timestamp = TimeOfDay.now().format(context);

    setState(() {
      _sentMessages.add(path);
      _playerControllers.add(controller);
      _waveformDataList.add(waveform ?? []);
      _messageDurations.add(duration);
      _messageTimestamps.add(timestamp);
    });

    // Upload user message audio
    await _uploadMessageToFirebase(path, isUser: isUser);
  }

  Future<void> _sendToMLModel(String userPath) async {
    setState(() => _isLoading = true);
    try {
      final uri = Uri.parse('https://web-production-5d0bc.up.railway.app/voice_assist');
      final request = http.MultipartRequest('POST', uri);
      final file = File(userPath);

      if (!file.existsSync()) {
        print('File does not exist');
        return;
      }

      request.files.add(await http.MultipartFile.fromPath(
        'audio',
        userPath,
        contentType: MediaType('audio', 'aac'),
      ));

      final response = await request.send();
      print("Status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final bytes = await response.stream.toBytes();
        final botPath = await _getFilePath(isBot: true);
        await File(botPath).writeAsBytes(bytes);
        await _replaceLoadingWithBotAudio(botPath);
      } else {
        final errorText = await response.stream.bytesToString();
        print('Server error: ${response.statusCode}');
        print('Error response: $errorText');
      }
    } catch (e) {
      print('Error sending to ML model: $e');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _uploadMessageToFirebase(String filePath, {required bool isUser}) async {
    try {
      final file = File(filePath);
      if (!file.existsSync()) {
        print('File does not exist for Firebase upload');
        return;
      }

      final fileName = file.uri.pathSegments.last;
      final ref = FirebaseStorage.instance.ref().child('chat_messages/$fileName');
      await ref.putFile(file);

      final downloadUrl = await ref.getDownloadURL();

      await FirebaseFirestore.instance.collection('messages').add({
        'url': downloadUrl,
        'sender': isUser ? 'user' : 'bot',
        'timestamp': FieldValue.serverTimestamp(),
      });

      print('Message uploaded to Firebase');
    } catch (e) {
      print('Error uploading to Firebase: $e');
    }
  }

  @override
  void dispose() {
    _recorder.closeRecorder();
    _waveformController.dispose();
    for (var controller in _playerControllers) {
      controller?.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xffC77398),
        title: const Text('Chat', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: const SideMenu(),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(10.0),
              itemCount: _sentMessages.length,
              itemBuilder: (context, index) {
                final path = _sentMessages[index];
                final isUser = path.contains("audio_");
                final isLoading = path == "loading";

                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: isUser
                            ? const EdgeInsets.only(left: 50.0, bottom: 10)
                            : const EdgeInsets.only(right: 50.0, bottom: 10),
                        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        child: isLoading
                            ? Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: const [
                            SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Color(0xffC77398),
                                strokeWidth: 2.5,
                              ),
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Generating response...',
                              style: TextStyle(fontSize: 14),
                            ),
                          ],
                        )
                            : Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                Icon(
                                  isUser ? Icons.person : Icons.smart_toy,
                                  size: 50,
                                  color: Color(0xffC77398),
                                ),
                                IconButton(
                                  icon: Icon(
                                    _playerControllers[index]!.playerState.isPlaying
                                        ? Icons.pause
                                        : Icons.play_arrow,
                                    color: Color(0xffC77398),
                                  ),
                                  onPressed: () async {
                                    if (_playerControllers[index]!.playerState.isPlaying) {
                                      await _playerControllers[index]!.pausePlayer();
                                    } else {
                                      await _playerControllers[index]!.startPlayer();
                                    }
                                    setState(() {});
                                  },
                                ),
                                AudioFileWaveforms(
                                  size: const Size(200, 40),
                                  playerController: _playerControllers[index]!,
                                  waveformType: WaveformType.fitWidth,
                                  playerWaveStyle: PlayerWaveStyle(
                                    waveThickness: 2.0,
                                    spacing: 3.0,
                                    fixedWaveColor: Colors.purple,
                                    liveWaveColor: Colors.deepPurpleAccent.withOpacity(0.6),
                                  ),

                                  waveformData: _waveformDataList[index],
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Text(
                              '${_messageDurations[index].inSeconds}s | ${_messageTimestamps[index]}',
                              style: TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Container(
            color: Colors.grey[200],
            padding: const EdgeInsets.all(10.0),
            child: Row(
              children: [
                Expanded(
                  child: AudioWaveforms(
                    size: const Size(double.infinity, 50.0),
                    recorderController: _waveformController,
                    waveStyle: const WaveStyle(
                      waveColor: Colors.blue,
                      extendWaveform: true,
                    ),
                  ),
                ),
                const SizedBox(width: 10.0),
                GestureDetector(
                  onTap: _isRecording ? _stopRecording : _startRecording,
                  child: CircleAvatar(
                    backgroundColor: _isRecording ? Colors.red : Color(0xffC77398),
                    radius: 30.0,
                    child: Icon(
                      _isRecording ? Icons.stop : Icons.mic,
                      color: Colors.white,
                      size: 30.0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


















class SideMenu extends StatelessWidget {
  const SideMenu({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Custom header with brain image and "MAIN MENU" text
          Container(
            height: 180, // Adjust height as needed
            decoration: const BoxDecoration(
              color: Color(0xffC77398),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Brain image
                Container(
                  width: 120,
                  height: 120,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(
                      image: AssetImage('assets/videos/brain.jpg'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // "MAIN MENU" text
                const Text(
                  'MAIN MENU',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // Rest of your existing menu items
          ListTile(
            leading: const Icon(
              Icons.new_releases,
              color: Color(0xffC77398),
            ),
            title: const Text('New Chat'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AudioRecorderPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(
              Icons.history,
              color: Color(0xffC77398),
            ),
            title: const Text('Chat History'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ChatHistoryScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(
              Icons.settings,
              color: Color(0xffC77398),
            ),
            title: const Text('Account Setting'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => Accountsetting()),
              );
            },
          ),
          ListTile(
            leading: const Icon(
              Icons.logout,
              color: Color(0xffC77398),
            ),
            title: const Text('Logout'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => Login()),
              );
            },
          ),
        ],
      ),
    );
  }
}





