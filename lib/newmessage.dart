import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class VoiceMessageUI extends StatefulWidget {
  @override
  _VoiceMessageUIState createState() => _VoiceMessageUIState();
}

class _VoiceMessageUIState extends State<VoiceMessageUI> {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final RecorderController _recorderController = RecorderController();
  bool _isRecording = false;
  String? _audioFilePath;

  @override
  void initState() {
    super.initState();
    _initializeRecorder();
  }

  Future<void> _initializeRecorder() async {
    await _recorder.openRecorder();
    _recorderController.reset();

    if (!await _recorder.isEncoderSupported(Codec.aacADTS)) {
      throw "AAC codec is not supported on this device";
    }
  }

  Future<String> _getFilePath() async {
    final directory = await getTemporaryDirectory();
    return "${directory.path}/recorded_audio_${DateTime.now().millisecondsSinceEpoch}.aac";
  }

  Future<void> _startRecording() async {
    setState(() => _isRecording = true);
    final path = await _getFilePath();

    await _recorder.startRecorder(
      toFile: path,
      codec: Codec.aacADTS,
      bitRate: 128000,
    );

    _recorderController.record();
    setState(() {
      _audioFilePath = path;
    });
  }

  Future<void> _stopRecording() async {
    await _recorder.stopRecorder();
    _recorderController.stop();
    setState(() {
      _isRecording = false;
    });
  }

  Widget _buildWaveform() {
    return Container(
      height: 60,
      color: Colors.black12,
      child: AudioWaveforms(
        size: Size(double.infinity, 60),
        recorderController: _recorderController,
        waveStyle: WaveStyle(
          waveColor: Colors.blue,
          middleLineColor: Colors.blueAccent,
          showMiddleLine: true,
          extendWaveform: true,
        ),
      ),
    );
  }

  Widget _buildAudioMessage() {
    if (_audioFilePath == null) return SizedBox.shrink();
    return GestureDetector(
      onTap: () async {
        try {
          if (_audioFilePath != null) {
            await _audioPlayer.play(DeviceFileSource(_audioFilePath!));
          }
        } catch (e) {
          print("Error playing audio: $e");
        }
      },
      child: Container(
        padding: EdgeInsets.all(10),
        margin: EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.play_arrow, color: Colors.blue),
            SizedBox(width: 10),
            Text("Play Message", style: TextStyle(color: Colors.black)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Voice Message UI'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                if (_isRecording) _buildWaveform(),
                _buildAudioMessage(),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(
                    _isRecording ? Icons.stop : Icons.mic,
                    size: 36,
                  ),
                  color: _isRecording ? Colors.red : Colors.blue,
                  onPressed: () async {
                    if (_isRecording) {
                      await _stopRecording();
                    } else {
                      await _startRecording();
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _recorder.closeRecorder();
    _audioPlayer.dispose();
    super.dispose();
  }
}
