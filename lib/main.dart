import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const PASScanner());
}

class PASScanner extends StatelessWidget {
  const PASScanner({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PAS Scanner',
      home: const HomePage(),
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? webhookUrl;

  @override
  void initState() {
    super.initState();
    loadWebhook();
  }

  Future<void> loadWebhook() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      webhookUrl = prefs.getString("webhook") ?? "";
    });
  }

  Future<void> saveWebhook(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("webhook", url);
    loadWebhook();
  }

  Future<void> sendToWebhook(String data) async {
    if (webhookUrl == null || webhookUrl!.isEmpty) return;
    try {
      await http.post(Uri.parse(webhookUrl!),
          body: {"qrdata": data});
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("PAS Scanner"),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              TextEditingController c =
                  TextEditingController(text: webhookUrl);
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Set Webhook URL"),
                  content: TextField(
                    controller: c,
                    decoration:
                        const InputDecoration(labelText: "Webhook URL"),
                  ),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Cancel")),
                    TextButton(
                        onPressed: () {
                          saveWebhook(c.text);
                          Navigator.pop(context);
                        },
                        child: const Text("Save")),
                  ],
                ),
              );
            },
          )
        ],
      ),
      body: MobileScanner(
        onDetect: (capture) {
          final barcode = capture.barcodes.first;
          final value = barcode.rawValue ?? "";
          sendToWebhook(value);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Scanned: $value")),
          );
        },
      ),
    );
  }
}
