import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../core/constants.dart';

// =============================================================================
// HALAMAN SUPPORT - HYDROGROW ASSISTANT (REFINED)
// 1. Typing animation for bot responses.
// 2. Grouped Q&A entries in Firebase (one folder per interaction).
// 3. Removed 'role' field as requested.
// =============================================================================

class SupportPage extends StatefulWidget {
  const SupportPage({super.key});

  @override
  State<SupportPage> createState() => _SupportPageState();
}

class _SupportPageState extends State<SupportPage> with SingleTickerProviderStateMixin {
  bool isLoading = false;
  int cooldownTime = 0;
  Timer? _cooldownTimer;

  late AnimationController _entryController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  late final DatabaseReference _chatRef;

  // Initial bot message is separate from interaction history
  final Map<String, dynamic> _initialBotMessage = {
    "id": "initial",
    "text": "Sistem Online. Saya Synthesis AI. Ada yang bisa saya bantu terkait sistem hidroponik Anda?",
    "isUser": false,
  };

  late List<Map<String, dynamic>> messages;

  @override
  void initState() {
    super.initState();
    messages = [_initialBotMessage];
    _initializeFirebaseRef();

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = CurvedAnimation(parent: _entryController, curve: Curves.easeIn);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryController, curve: Curves.easeOutCubic));

    _entryController.forward();
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _entryController.dispose();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _initializeFirebaseRef() {
    final uid = _auth.currentUser?.uid ?? 'anonymous';
    _chatRef = FirebaseDatabase.instance.ref('support_chats/$uid');
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    setState(() => cooldownTime = 5);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (timer.tick >= 5) {
        timer.cancel();
        setState(() => cooldownTime = 0);
      } else {
        setState(() => cooldownTime = 5 - timer.tick);
      }
    });
  }

  Future<String> _getGeminiResponse(String prompt) async {
    final String? apiKey = dotenv.env['GROQ_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('GROQ_API_KEY tidak ditemukan di file .env');
    }
    final url = Uri.parse('https://api.groq.com/openai/v1/chat/completions');

    const String systemPrompt =
        "Kamu adalah Synthesis AI, asisten pintar khusus untuk aplikasi HydroGrow. "
        "ATURAN PENTING: Kamu HANYA boleh menjawab pertanyaan yang berkaitan dengan "
        "proyek HydroGrow, fitur aplikasi, hardware, software, tim, dan hal-hal yang "
        "tercantum di knowledge base berikut. Jika pertanyaan di luar topik tersebut, "
        "jawab dengan sopan: Maaf, saya hanya bisa menjawab pertanyaan seputar HydroGrow "
        "dan fitur-fiturnya. Jangan pernah menjawab pertanyaan di luar cakupan ini.\n\n"
        "FORMAT: Jangan gunakan tanda bintang, hash, atau format markdown apapun. "
        "Jawab dengan teks biasa yang ramah dalam bahasa Indonesia. Singkat dan jelas.\n\n"
        "KNOWLEDGE BASE HYDROGROW:\n\n"
        "PROYEK: HydroGrow Solar System X Roblox adalah sistem irigasi pintar berbasis IoT "
        "yang mengintegrasikan ESP32, sensor lingkungan, panel surya, dashboard aplikasi, "
        "Firebase Realtime Database, dan Digital Twin Roblox Studio untuk monitoring serta "
        "kontrol penyiraman tanaman secara real-time.\n\n"
        "TUJUAN: Monitoring tanaman real-time, penyiraman otomatis berdasarkan kelembapan tanah, "
        "menghemat air melalui smart irrigation, memanfaatkan energi terbarukan panel surya, "
        "menyediakan dashboard monitoring, dan Digital Twin Roblox.\n\n"
        "HARDWARE: ESP32 WROOM 32 sebagai pusat kendali, Capacitive Soil Moisture Sensor "
        "untuk kelembapan tanah, LDR untuk intensitas cahaya, INA219 Current Sensor untuk "
        "arus dan daya, Load Cell plus HX711 untuk berat tangki air, Relay 5V untuk kontrol "
        "pompa, Pompa Air DC, Panel Surya 5V, Baterai Li-Ion 18650.\n\n"
        "SOFTWARE: Flutter untuk aplikasi mobile dan web, Firebase Realtime Database untuk "
        "penyimpanan data, Roblox Studio dan Lua untuk Digital Twin, Telegram Bot untuk "
        "notifikasi, OpenAI untuk AI assistant.\n\n"
        "ARSITEKTUR: Sensor membaca data, ESP32 memproses, data dikirim ke Firebase, "
        "aplikasi membaca dari Firebase untuk ditampilkan, Digital Twin Roblox tersinkronisasi.\n\n"
        "FITUR APLIKASI:\n"
        "1. Dashboard - Monitoring real-time semua sensor (soil moisture, light intensity, "
        "water level, battery), grafik tren harian per jenis tanaman, indikator status sistem.\n"
        "2. Categories - Tambah, edit, hapus kategori tanaman. Setiap kategori punya box tanaman, "
        "jadwal aktif/nonaktif, threshold moisture min/max, dan status pompa.\n"
        "3. Device Control - Kontrol pompa manual, pengaturan threshold kelembapan tanah, "
        "threshold cahaya, threshold air, dan threshold baterai. Juga monitoring suhu.\n"
        "4. Schedule - Atur jadwal penyiraman otomatis per kategori tanaman, aktifkan atau "
        "nonaktifkan jadwal, lihat timeline jadwal yang berjalan hari ini.\n"
        "5. Monitoring - Tabel data sensor lengkap dengan riwayat, filter berdasarkan tanggal.\n"
        "6. Alerts - Notifikasi kelembapan rendah, air hampir habis, baterai lemah, "
        "gangguan perangkat, dan log peringatan sistem.\n"
        "7. Support - Chat dengan Synthesis AI untuk bertanya seputar HydroGrow.\n"
        "8. Export Data - Export data sensor ke format CSV, PDF, atau XLSX.\n"
        "9. Telegram Bot - Notifikasi real-time dikirim ke Telegram saat ada alert.\n\n"
        "SENSOR YANG DIPANTAU: Soil Moisture (kelembapan tanah %), Light Intensity "
        "(intensitas cahaya %), Water Level (level air %), Battery (daya baterai %).\n\n"
        "DIGITAL TWIN ROBLOX: Representasi virtual sistem fisik HydroGrow yang tersinkronisasi "
        "real-time melalui Firebase. Menampilkan kondisi tanaman, status pompa, kondisi tangki "
        "air, kondisi lingkungan, dan status sensor.\n\n"
        "TIM PENGEMBANG: Miftah Afreza Maulana (Project Manager, System Analyst), "
        "Muhammad Raihan Hidayah (Hardware Engineer, Embedded System), "
        "Satrio Brahmantyo (Fullstack Developer, Backend), "
        "Yoga Andrian R (Roblox Developer, Digital Twin Engineer).\n\n"
        "ANGGARAN: Total Rp 654.437 meliputi ESP32, sensor, relay, pompa, panel surya, "
        "baterai, hosting, dan VPS.\n\n"
        "METODE: Agile Development dengan Black Box Testing. Seluruh fitur berjalan sesuai "
        "kebutuhan sistem.";

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          "model": "llama-3.3-70b-versatile",
          "messages": [
            {"role": "system", "content": systemPrompt},
            {"role": "user", "content": prompt},
          ],
        }),
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final choices = data['choices'] as List?;
        if (choices != null && choices.isNotEmpty) {
          final content = choices[0]['message']?['content'] as String?;
          if (content != null && content.isNotEmpty) {
            return content;
          }
        }
        throw Exception('Response tidak memiliki choices');
      } else if (response.statusCode == 429) {
        throw Exception('RATE_LIMIT');
      }
      throw Exception("Error: ${response.statusCode}");
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _sendMessage() async {
    final userText = _controller.text.trim();
    if (userText.isEmpty || cooldownTime > 0 || isLoading) return;

    setState(() {
      messages.add({"isUser": true, "text": userText});
      _controller.clear();
      isLoading = true;
    });
    _scrollToBottom();

    try {
      final botText = await _getGeminiResponse(userText);

      // Save as one interaction folder in Firebase (Grouped Q&A)
      await _chatRef.push().set({
        'question': userText,
        'answer': botText,
        'timestamp': ServerValue.timestamp,
      });

      // Add bot response with typing effect
      _addBotResponseWithTyping(botText);
    } catch (e) {
      final errorMsg = e.toString().contains('RATE_LIMIT')
          ? "Batas permintaan tercapai. Synthesis AI perlu istirahat sebentar, coba lagi dalam 1-2 menit ya."
          : "Maaf, Synthesis AI gagal merespon. Silakan coba lagi.";
      setState(() {
        messages.add({
          "isUser": false,
          "text": errorMsg,
        });
      });
    } finally {
      setState(() => isLoading = false);
      _startCooldown();
      _scrollToBottom();
    }
  }

  void _addBotResponseWithTyping(String fullText) {
    final msgId = DateTime.now().microsecondsSinceEpoch.toString();
    setState(() {
      messages.add({"id": msgId, "isUser": false, "text": "", "isTyping": true});
    });

    String displayedText = "";
    int charIndex = 0;

    Timer.periodic(const Duration(milliseconds: 15), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final msgIndex = messages.indexWhere((m) => m["id"] == msgId);
      if (msgIndex == -1) {
        timer.cancel();
        return;
      }
      if (charIndex < fullText.length) {
        displayedText += fullText[charIndex];
        charIndex++;
        setState(() {
          messages[msgIndex]["text"] = displayedText;
        });
        _scrollToBottom();
      } else {
        setState(() {
          messages[msgIndex]["isTyping"] = false;
        });
        timer.cancel();
      }
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.3 : 0.05), blurRadius: 15)],
                  ),
                  child: Column(
                    children: [
                      _buildChatHeader(),
                      Expanded(
                        child: Container(
                          color: Theme.of(context).brightness == Brightness.dark ? Colors.black26 : AppColors.backgroundLight,
                          child: ListView.builder(
                            controller: _scrollController,
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.all(16),
                            itemCount: messages.length,
                            itemBuilder: (context, index) {
                              final msg = messages[index];
                              return _ChatBubble(
                                text: msg["text"],
                                isUser: msg["isUser"] ?? false,
                                isTyping: msg["isTyping"] ?? false,
                              );
                            },
                          ),
                        ),
                      ),
                      if (isLoading) const LinearProgressIndicator(color: AppColors.primary, minHeight: 2),
                      if (messages.length <= 2) _buildSuggestedQuestions(),
                      _buildChatInput(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChatHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.05) : AppColors.ink,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Row(
        children: [
          const Icon(Icons.smart_toy_rounded, color: AppColors.primary, size: 28),
          const SizedBox(width: 12),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Synthesis AI", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16), overflow: TextOverflow.ellipsis),
                Text("ONLINE ASSISTANT", style: TextStyle(color: AppColors.emerald, fontSize: 10, fontWeight: FontWeight.w800), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: () {
              _chatRef.remove();
              setState(() => messages = [_initialBotMessage]);
            },
            icon: const Icon(Icons.delete_sweep_outlined, color: Colors.redAccent, size: 18),
            label: const Text("Clear", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w700, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildChatInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.1))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              enabled: !isLoading && cooldownTime == 0,
              decoration: InputDecoration(
                hintText: cooldownTime > 0 ? "Wait $cooldownTime s..." : "Ask something...",
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.05) : AppColors.background,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: AppColors.primary,
            child: IconButton(
              onPressed: _sendMessage,
              icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestedQuestions() {
    final questions = [
      "Fitur HydroGrow?",
      "Sensor IoT?",
      "Cara Kerja?",
      "Data Sensor?",
    ];
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Wrap(
        spacing: 8,
        children: questions.map((q) => ActionChip(
          label: Text(q, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.primary)),
          onPressed: () { _controller.text = q; _sendMessage(); },
          backgroundColor: Theme.of(context).colorScheme.surface,
          side: const BorderSide(color: AppColors.primary),
        )).toList(),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final String text;
  final bool isUser;
  final bool isTyping;

  const _ChatBubble({required this.text, required this.isUser, this.isTyping = false});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
        decoration: BoxDecoration(
          color: isUser ? AppColors.primary : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isUser ? 20 : 0),
            bottomRight: Radius.circular(isUser ? 0 : 20),
          ),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: TextStyle(color: isUser ? Colors.white : (Theme.of(context).textTheme.bodyLarge?.color ?? AppColors.ink), fontSize: 13, height: 1.4),
            ),
            if (isTyping && text.isEmpty)
              const SizedBox(
                width: 20,
                height: 10,
                child: Row(
                  children: [
                    _Dot(), _Dot(), _Dot(),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Dot extends StatefulWidget {
  const _Dot();
  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))..repeat(reverse: true);
  }
  @override
  void dispose() { _controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Container(
        width: 4, height: 4,
        margin: const EdgeInsets.symmetric(horizontal: 1),
        decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.3 + _controller.value * 0.7), shape: BoxShape.circle),
      ),
    );
  }
}
