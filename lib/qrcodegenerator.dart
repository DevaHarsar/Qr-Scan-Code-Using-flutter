import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:image_picker/image_picker.dart';

class QrGenerator extends StatefulWidget {
  const QrGenerator({Key? key}) : super(key: key);

  @override
  _QrGeneratorState createState() => _QrGeneratorState();
}

class _QrGeneratorState extends State<QrGenerator> {
  String userInput = '';
  File? customImage;
  GlobalKey globalKey = GlobalKey();

  Future<void> _shareQRCode() async {
    try {
      RenderRepaintBoundary boundary =
          globalKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage();
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      Directory tempDir = await getTemporaryDirectory();
      String tempPath = tempDir.path;

      File tempFile = File('$tempPath/qrcode.png');
      await tempFile.writeAsBytes(pngBytes);

      // ignore: deprecated_member_use
      await Share.shareFiles(['$tempPath/qrcode.png'], text: 'QR Code');
    } catch (e) {
      print('Error sharing QR code: $e');
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to share QR code')));
    }
  }

  Future<void> _saveQRCode() async {
    try {
      RenderRepaintBoundary boundary =
          globalKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage();
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      await ImageGallerySaver.saveImage(pngBytes, name: 'qrcode.png');
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('QR Code saved to gallery')));
    } catch (e) {
      print('Error saving QR code: $e');
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to save QR code')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('QR Code Generator'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareQRCode,
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveQRCode,
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                decoration: const InputDecoration(
                  labelText: 'Enter Text for QR Code',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() {
                    userInput = value;
                  });
                },
              ),
            ),
            SizedBox(
              width: 200,
              height: 200,
              child: RepaintBoundary(
                key: globalKey,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    QrImageView(
                      data: userInput,
                      version: QrVersions.auto,
                      size: 200.0,
                      backgroundColor: Colors.white,
                    ),
                    if (customImage != null)
                      Image.file(
                        customImage!,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      ),
                  ],
                ),
              ),
            ),
            // ElevatedButton(
            //   onPressed: () async {
            //     final pickedImage = await ImagePicker().pickImage(source: ImageSource.gallery);
            //     if (pickedImage != null) {
            //       setState(() {
            //         customImage = File(pickedImage.path);
            //       });
            //     }
            //   },
            //   child: Text('Pick Custom Image'),
            // ),
          ],
        ),
      ),
    );
  }
}
