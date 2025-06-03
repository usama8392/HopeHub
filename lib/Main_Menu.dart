import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hopehub/Account_setting.dart';
import 'package:hopehub/Login.dart';
import 'package:hopehub/message.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';

class ChatHistoryScreen extends StatefulWidget {
  const ChatHistoryScreen({Key? key}) : super(key: key);

  @override
  State<ChatHistoryScreen> createState() => _ChatHistoryScreenState();
}

class _ChatHistoryScreenState extends State<ChatHistoryScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final ValueNotifier<String?> currentlyPlayingUrl = ValueNotifier<String?>(null);
  final Set<String> loadingUrls = {};
  final Map<String, double> _playbackPositions = {};

  @override
  void dispose() {
    _audioPlayer.dispose();
    currentlyPlayingUrl.dispose();
    super.dispose();
  }

  bool _isPlaying(String url) {
    return currentlyPlayingUrl.value == url && _audioPlayer.playing;
  }

  Future<void> _playAudio(String url) async {
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No audio available')),
      );
      return;
    }

    final wasPlaying = _isPlaying(url);

    await _audioPlayer.stop();
    currentlyPlayingUrl.value = null;
    _playbackPositions[url] = 0;

    if (wasPlaying) return;

    loadingUrls.add(url);
    currentlyPlayingUrl.notifyListeners();

    try {
      await _audioPlayer.setUrl(url);
      loadingUrls.remove(url);
      currentlyPlayingUrl.value = url;

      // Start position updates
      _audioPlayer.positionStream.listen((position) {
        if (_audioPlayer.duration != null) {
          _playbackPositions[url] = position.inMilliseconds.toDouble() /
              _audioPlayer.duration!.inMilliseconds.toDouble();
          currentlyPlayingUrl.notifyListeners();
        }
      });

      await _audioPlayer.play();

      _audioPlayer.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          if (mounted && currentlyPlayingUrl.value == url) {
            currentlyPlayingUrl.value = null;
            _playbackPositions[url] = 0;
          }
        }
      });
    } catch (e) {
      print("⚠️ Audio error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to play audio")),
      );
      currentlyPlayingUrl.value = null;
    } finally {
      loadingUrls.remove(url);
      currentlyPlayingUrl.notifyListeners();
    }
  }

  // WhatsApp-like waveform data
  List<double> _generateWhatsAppWaveform() {
    return [
      0.2, 0.5, 0.8, 0.6, 0.4, 0.7, 0.9, 0.5, 0.3, 0.6,
      0.8, 0.4, 0.7, 0.5, 0.3, 0.6, 0.9, 0.7, 0.4, 0.6,
      0.3, 0.5, 0.8, 0.6, 0.4, 0.7, 0.5, 0.3, 0.6, 0.8
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xffC77398),
        title: const Text('Chat History', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: const SideMenu(),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('messages')
            .orderBy('timestamp', descending: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No messages found.'));
          }

          final messages = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(10.0),
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final message = messages[index];
              final sender = message['sender'];
              final url = message['url'] ?? '';
              final timestamp = (message['timestamp'] as Timestamp).toDate();

              return ValueListenableBuilder<String?>(
                valueListenable: currentlyPlayingUrl,
                builder: (context, currentUrl, _) {
                  final isPlayingThis = currentUrl == url && _audioPlayer.playing;
                  final isLoadingThis = loadingUrls.contains(url);
                  final progress = _playbackPositions[url] ?? 0.0;

                  return Align(
                    alignment: sender == 'user' ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: sender == 'user'
                          ? const EdgeInsets.only(left: 50.0, bottom: 10)
                          : const EdgeInsets.only(right: 50.0, bottom: 10),
                      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 12.0),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(
                                sender == 'user' ? Icons.person : Icons.smart_toy,
                                size: 40,
                                color: const Color(0xffC77398),
                              ),
                              const SizedBox(width: 8),
                              isLoadingThis
                                  ? const SizedBox(
                                height: 30,
                                width: 30,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation(Color(0xffC77398)),
                                ),
                              )
                                  : IconButton(
                                icon: Icon(
                                  isPlayingThis
                                      ? Icons.pause_circle_filled
                                      : Icons.play_circle_fill,
                                  color: const Color(0xffC77398),
                                  size: 30,
                                ),
                                onPressed: () {
                                  _playAudio(url);
                                },
                              ),
                              const SizedBox(width: 8),
                              if (url.isNotEmpty)
                                Container(
                                  height: 30,
                                  width: 180,
                                  child: CustomPaint(
                                    painter: WhatsAppWaveformPainter(
                                      samples: _generateWhatsAppWaveform(),
                                      progress: isPlayingThis ? progress : 0.0,
                                      isPlaying: isPlayingThis,
                                      activeColor: const Color(0xffC77398),
                                      inactiveColor: Colors.grey,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')} | ${timestamp.day}/${timestamp.month}/${timestamp.year}',
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class WhatsAppWaveformPainter extends CustomPainter {
  final List<double> samples;
  final double progress;
  final bool isPlaying;
  final Color activeColor;
  final Color inactiveColor;

  WhatsAppWaveformPainter({
    required this.samples,
    required this.progress,
    required this.isPlaying,
    required this.activeColor,
    required this.inactiveColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final barWidth = 3.0;
    final spacing = 2.0;
    final maxBarHeight = size.height;
    final centerY = size.height / 2;
    final progressWidth = size.width * progress;

    // Draw inactive portion first
    for (var i = 0; i < samples.length; i++) {
      final x = i * (barWidth + spacing);
      final barHeight = samples[i] * maxBarHeight;
      final top = centerY - barHeight / 2;

      final paint = Paint()
        ..color = inactiveColor
        ..style = PaintingStyle.fill;

      canvas.drawRect(
        Rect.fromLTWH(x, top, barWidth, barHeight),
        paint,
      );
    }

    // Draw active portion only if playing
    if (isPlaying) {
      for (var i = 0; i < samples.length; i++) {
        final x = i * (barWidth + spacing);
        if (x < progressWidth) {
          final barHeight = samples[i] * maxBarHeight;
          final top = centerY - barHeight / 2;

          final paint = Paint()
            ..color = activeColor
            ..style = PaintingStyle.fill;

          canvas.drawRect(
            Rect.fromLTWH(x, top, barWidth, barHeight),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(WhatsAppWaveformPainter oldDelegate) {
    return oldDelegate.samples != samples ||
        oldDelegate.progress != progress ||
        oldDelegate.isPlaying != isPlaying;
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
                MaterialPageRoute(builder: (context) =>AudioRecorderPage()),
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
                MaterialPageRoute(builder: (context) =>Accountsetting()),
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
                MaterialPageRoute(builder: (context) =>Login()),
              );
            },
          ),
        ],
      ),
    );
  }
}





