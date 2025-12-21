import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:gal/gal.dart'; // For saving to gallery
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';

class QrGenerator extends StatefulWidget {
  const QrGenerator({super.key});

  @override
  State<QrGenerator> createState() => _QrGeneratorState();
}

class _QrGeneratorState extends State<QrGenerator> {
  final TextEditingController _textController = TextEditingController();
  String userInput = '';
  File? customImage;
  late BannerAd _bannerAd;
  bool _isBannerAdReady = false;

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
  }

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-8702370576330643/7461721807',
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => setState(() => _isBannerAdReady = true),
        onAdFailedToLoad: (ad, error) => ad.dispose(),
      ),
    )..load();
  }

  // --- 1. PICK & CROP IMAGE (CRASH PROOF VERSION) ---
  Future<void> _pickAndCropImage() async {
    final picker = ImagePicker();
    XFile? pickedFile;

    try {
      // Step A: Attempt standard pick
      pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 85,
      );

      // Step B: CRITICAL FIX for Android "Preview" Mode
      // If pickedFile is null, check if the app was killed and restarted
      if (pickedFile == null) {
        final LostDataResponse response = await picker.retrieveLostData();
        if (response.isEmpty) {
          debugPrint("User cancelled or no data found.");
          return;
        }
        if (response.file != null) {
          pickedFile = response.file; // Recover the lost image
          debugPrint("✅ Recovered lost image data: ${pickedFile?.path}");
        } else {
          debugPrint("❌ Recovered lost data error: ${response.exception}");
          return;
        }
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
      _showSnackBar("Failed to pick image");
      return;
    }

    // Step C: Proceed with Cropping (Standard Logic)
    if (pickedFile == null) return;

    try {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        compressFormat: ImageCompressFormat.png,
        compressQuality: 90,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Logo',
            toolbarColor: Colors.blue,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
            hideBottomControls: false,
          ),
          IOSUiSettings(
            title: 'Crop Logo',
            aspectRatioLockEnabled: true,
          ),
        ],
      );

      if (croppedFile != null) {
        setState(() => customImage = File(croppedFile.path));
        _showSnackBar("✓ Logo added successfully!");
      }
    } catch (e) {
      debugPrint("Error cropping image: $e");
    }
  }

  // --- 2. GENERATE HIGH-QUALITY IMAGE FOR SAVE/SHARE ---
  Future<void> _processAndShare(bool isSharing) async {
    if (userInput.isEmpty) return;
    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      const size = 1000.0;
      const logoSize = 200.0;
      const centerPos = size / 2;

      // A. Draw Solid White Background
      final whitePaint = Paint()..color = Colors.white;
      canvas.drawRect(const Rect.fromLTWH(0, 0, size, size), whitePaint);

      // B. Draw QR Code
      final qrPainter = QrPainter(
        data: userInput,
        version: 6,
        errorCorrectionLevel: QrErrorCorrectLevel.H,
        eyeStyle:
            const QrEyeStyle(eyeShape: QrEyeShape.circle, color: Colors.black),
        dataModuleStyle: const QrDataModuleStyle(
            dataModuleShape: QrDataModuleShape.circle, color: Colors.black),
      );
      qrPainter.paint(canvas, const Size(size, size));

      // C. Draw Logo with Clean White Gap
      if (customImage != null) {
        final Uint8List bytes = await customImage!.readAsBytes();
        final Completer<ui.Image> completer = Completer();
        ui.decodeImageFromList(
            bytes, (ui.Image img) => completer.complete(img));
        final logoImg = await completer.future;

        final gapSize = logoSize + 25;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: const Offset(centerPos, centerPos),
                width: gapSize,
                height: gapSize),
            const Radius.circular(30),
          ),
          whitePaint,
        );

        final src = Rect.fromLTWH(
            0, 0, logoImg.width.toDouble(), logoImg.height.toDouble());
        final dst = Rect.fromCenter(
            center: const Offset(centerPos, centerPos),
            width: logoSize,
            height: logoSize);
        canvas.drawImageRect(logoImg, src, dst, Paint());
      }

      // D. Finalize and Save/Share
      final picture = recorder.endRecording();
      final img = await picture.toImage(size.toInt(), size.toInt());
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      if (isSharing) {
        final tempDir = await getTemporaryDirectory();
        final file = await File('${tempDir.path}/qr_premium.png').create();
        await file.writeAsBytes(pngBytes);
        await Share.shareXFiles([XFile(file.path)],
            text: 'Scan my Professional QR!');
      } else {
        await Gal.putImageBytes(pngBytes,
            name: 'QR_Pro_${DateTime.now().millisecond}');
        _showSnackBar('Saved with logo to gallery!');
      }
    } catch (e) {
      _showSnackBar('Process failed: $e');
    }
  }

  void _showSnackBar(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  void dispose() {
    _textController.dispose();
    _bannerAd.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Advanced QR Creator'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // 1. INPUT FIELD WITH FLOATING LABEL
            TextField(
              controller: _textController,
              // 1. Center text vertically
              textAlignVertical: TextAlignVertical.center,
              decoration: InputDecoration(
                labelText: 'QR Content',
                hintText: 'Enter text, URL, or UPI ID',
                // 2. Remove "auto" to let it behave naturally
                // floatingLabelBehavior: FloatingLabelBehavior.auto,

                prefixIcon: const Icon(Icons.link),
                suffixIcon: userInput.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _textController.clear();
                          setState(() => userInput = "");
                        })
                    : null,
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Colors.blue, width: 2),
                ),
                // 3. CRITICAL FIX: Removes the large gap and centers content
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              ),
              onChanged: (v) => setState(() => userInput = v),
            ),
            const SizedBox(height: 20),

            // 2. LOGO BUTTON
            ElevatedButton.icon(
              onPressed: _pickAndCropImage,
              icon: Icon(customImage == null
                  ? Icons.add_photo_alternate
                  : Icons.cached),
              label: Text(customImage == null
                  ? "Add Custom Logo"
                  : "Change Brand Logo"),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 40),

            // 3. PREMIUM LIVE PREVIEW
            if (userInput.isNotEmpty)
              Card(
                elevation: 10,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28)),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: SizedBox(
                    width: 260,
                    height: 260,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Layer A: The Dense QR Code
                        QrImageView(
                          data: userInput,
                          version: 6,
                          size: 260,
                          errorCorrectionLevel: QrErrorCorrectLevel.H,
                          eyeStyle: const QrEyeStyle(
                              eyeShape: QrEyeShape.circle, color: Colors.black),
                          dataModuleStyle: const QrDataModuleStyle(
                              dataModuleShape: QrDataModuleShape.circle,
                              color: Colors.black),
                        ),

                        // Layer B: The Logo with White Gap
                        if (customImage != null)
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.all(5),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                customImage!,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              )
            else
              const Padding(
                padding: EdgeInsets.all(20),
                child: Opacity(
                    opacity: 0.5, child: Text("Enter content to generate QR")),
              ),

            const SizedBox(height: 40),

            // 4. SAVE & SHARE ACTIONS
            if (userInput.isNotEmpty) ...[
              _buildActionButton("Share Premium QR", Icons.share,
                  () => _processAndShare(true), Colors.blue),
              const SizedBox(height: 15),
              _buildActionButton("Save to Gallery", Icons.download,
                  () => _processAndShare(false), Colors.green),
            ]
          ],
        ),
      ),
      bottomNavigationBar: _isBannerAdReady
          ? SafeArea(
              child: Container(
                  color: Colors.white,
                  height: 60,
                  child: AdWidget(ad: _bannerAd)))
          : null,
    );
  }

  Widget _buildActionButton(String t, IconData i, VoidCallback a, Color color) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton.icon(
        onPressed: a,
        icon: Icon(i),
        label: Text(t,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 2,
        ),
      ),
    );
  }
}
