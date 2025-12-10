import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;

class ScannerPage extends StatefulWidget {
  final String webhook;
  ScannerPage({required this.webhook});

  @override
  _ScannerPageState createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  bool sent = false;
  bool sending = false;

  Future<void> sendToWebhook(String data) async {
    if (widget.webhook.isEmpty) return;
    setState(()=> sending = true);
    try {
      final res = await http.post(
        Uri.parse(widget.webhook),
        headers: {'Content-Type':'application/json'},
        body: '{"qrdata":"$data"}',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Webhook response: ${res.statusCode}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Send failed: $e')),
      );
    } finally {
      setState(()=> sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Scan QR'),
      ),
      body: MobileScanner(
        allowDuplicates: false,
        onDetect: (capture) async {
          if (sent) return;
          final code = capture.barcodes.first.rawValue ?? '';
          sent = true;
          if (widget.webhook.isNotEmpty) {
            await sendToWebhook(code);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Webhook not set')));
          }
          Navigator.pop(context, code);
        },
      ),
    );
  }
}
