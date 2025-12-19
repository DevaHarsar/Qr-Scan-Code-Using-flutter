import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class QrGenerator extends StatefulWidget {
  const QrGenerator({Key? key}) : super(key: key);

  @override
  _QrGeneratorState createState() => _QrGeneratorState();
}

class _QrGeneratorState extends State<QrGenerator> {
  String userInput = '';
  File? customImage;
  GlobalKey globalKey = GlobalKey();
  late BannerAd _bannerAd;
  bool _isBannerAdReady = false;

  @override
  void initState() {
    super.initState();
    _bannerAd = BannerAd(
        adUnitId: 'ca-app-pub-8702370576330643/7461721807',
      size: AdSize.banner,
      request: AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          setState(() {
            _isBannerAdReady = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd.dispose();
    super.dispose();
  }

  Future<void> _shareQRCode() async {
    try {
      final qrValidationResult = QrValidator.validate(
        data: userInput,
        version: QrVersions.auto,
        errorCorrectionLevel: QrErrorCorrectLevel.L,
      );
      if (qrValidationResult.status == QrValidationStatus.valid) {
        final qrCode = qrValidationResult.qrCode!;
        final painter = QrPainter(
          data: userInput,
          version: QrVersions.auto,
          gapless: true,
          color: Colors.black,
          emptyColor: Colors.white,
        );
        final image = await painter.toImage(600);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        final pngBytes = byteData!.buffer.asUint8List();

        Directory tempDir = await getTemporaryDirectory();
        String tempPath = tempDir.path;

        File tempFile = File('$tempPath/qrcode.png');
        await tempFile.writeAsBytes(pngBytes);

        await Share.shareFiles(['$tempPath/qrcode.png'], text: 'QR Code');
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Invalid QR code data')));
      }
    } catch (e) {
      print('Error sharing QR code: $e');
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to share QR code')));
    }
  }

  Future<void> _saveQRCode() async {
    try {
      final qrValidationResult = QrValidator.validate(
        data: userInput,
        version: QrVersions.auto,
        errorCorrectionLevel: QrErrorCorrectLevel.L,
      );
      if (qrValidationResult.status == QrValidationStatus.valid) {
        final qrCode = qrValidationResult.qrCode!;
        final painter = QrPainter(
          data: userInput,
          version: QrVersions.auto,
          gapless: true,
          color: Colors.black,
          emptyColor: Colors.white,
        );
        final image = await painter.toImage(600);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        final pngBytes = byteData!.buffer.asUint8List();

        await Gal.putImageBytes(pngBytes, name: 'qrcode.png');
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('QR Code saved to gallery')));
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Invalid QR code data')));
      }
    } catch (e) {
      print('Error saving QR code: $e');
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to save QR code')));
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Code Generator', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.share, color: isDarkMode ? Colors.white : Colors.black),
            onPressed: _shareQRCode,
            tooltip: 'Share QR Code',
          ),
          IconButton(
            icon: Icon(Icons.save, color: isDarkMode ? Colors.white : Colors.black),
            onPressed: _saveQRCode,
            tooltip: 'Save QR Code',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Input Field
            TextField(
              decoration: InputDecoration(
                labelText: 'Enter Text for QR Code',
                hintText: 'Type URL, text, or any data',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: isDarkMode ? Colors.blue : Colors.black, width: 2),
                ),
                prefixIcon: const Icon(Icons.text_fields),
                suffixIcon: userInput.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() => userInput = '');
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                setState(() {
                  userInput = value;
                });
              },
            ),
            const SizedBox(height: 30),
            // QR Code Display
            if (userInput.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[850] : Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: isDarkMode ? Colors.black26 : Colors.black12,
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: RepaintBoundary(
                  key: globalKey,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      QrImageView(
                        data: userInput,
                        version: QrVersions.auto,
                        size: 250.0,
                        backgroundColor: Colors.transparent,
                        errorStateBuilder: (cxt, err) {
                          return Center(
                            child: Text(err.toString()),
                          );
                        },
                      ),
                      if (customImage != null)
                        Container(
                          decoration: BoxDecoration(
                            color: isDarkMode ? Colors.grey[800] : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: isDarkMode ? Colors.grey : Colors.grey.shade400, width: 2),
                          ),
                          padding: const EdgeInsets.all(4),
                          child: Image.file(
                            customImage!,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          ),
                        ),
                    ],
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[850] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                    width: 2,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.qr_code_2,
                      size: 80,
                      color: isDarkMode ? Colors.white70 : Colors.black45,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Enter text to generate QR code',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 30),
            // Action Buttons
            if (userInput.isNotEmpty)
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                          child: ElevatedButton.icon(
                      icon: Icon(Icons.share, color: isDarkMode ? Colors.white : Colors.black),
                      label: Text('Share QR Code', style: TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
                      onPressed: _shareQRCode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDarkMode ? Colors.blue : Colors.grey[200],
                        foregroundColor: isDarkMode ? Colors.white : Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: isDarkMode ? 5 : 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.save, color: isDarkMode ? Colors.white : Colors.black),
                      label: Text('Save to Gallery', style: TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
                      onPressed: _saveQRCode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDarkMode ? Colors.blue : Colors.grey[200],
                        foregroundColor: isDarkMode ? Colors.white : Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: isDarkMode ? 5 : 2,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
      // Banner ad at bottom
      bottomNavigationBar: _isBannerAdReady
          ? SizedBox(
              height: _bannerAd.size.height.toDouble() + 16,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: AdWidget(ad: _bannerAd),
              ),
            )
          : null,
    );
  }
}
