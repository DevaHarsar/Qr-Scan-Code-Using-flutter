import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// ignore: depend_on_referenced_packages
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_code_scanner/result.dart';
// ignore: depend_on_referenced_packages
import 'package:qr_scanner_overlay/qr_scanner_overlay.dart';
import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';
// ignore: depend_on_referenced_packages
import 'package:qr_code_scanner/qrcodegenerator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart' as mlkit;
const bgColor = Color(0xfffafafa);

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  bool isScancompleted = false;
  bool isFlashon = false;
  bool iscamera = false;
  double zoomLevel = 1.0;
  double _baseZoom = 1.0;
  final double _minZoom = 1.0;
  final double _maxZoom = 4.0;
  MobileScannerController controller = MobileScannerController();

  @override
  void initState() {
    super.initState();
    // Set preferred orientation to portrait mode
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  @override
  void dispose() {
    // Reset preferred orientations to system default when disposing the page
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    // Dispose the scanner controller to stop camera and release resources
    controller.dispose();
    super.dispose();
  }

  void resetScanCompletionFlag() {
    setState(() {
      isScancompleted = false;
      print('Changed succesfully');
    });
  }

  Future<void> _pickImageAndScan() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      
      if (image != null) {
        // Use Google ML Kit for barcode scanning from image
        final inputImage = mlkit.InputImage.fromFilePath(image.path);
        final barcodeScanner = mlkit.BarcodeScanner(formats: [mlkit.BarcodeFormat.all]);
        
        try {
          final List<mlkit.Barcode> barcodes = await barcodeScanner.processImage(inputImage);
          
          if (barcodes.isNotEmpty) {
            String code = '';
            for (final barcode in barcodes) {
              code += barcode.rawValue ?? '';
            }
            
            if (code.isNotEmpty) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ResultScreen(
                    closeScreen: resetScanCompletionFlag,
                    code: code,
                  ),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No QR code found in image')),
              );
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No QR code found in image')),
            );
          }
        } finally {
          barcodeScanner.close();
        }
      }
    } catch (e) {
      print('Error scanning image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error scanning image: $e')),
      );
    }
  }
  


  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF181A20) : bgColor,
      drawer: Drawer(
        backgroundColor: isDark ? const Color(0xFF23272F) : Colors.white,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF23272F) : Colors.black26,
              ),
              child: Text(
                "QR CODE SCANNER",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ),
            ListTile(
              title: Text(
                'QR Code Generator',
                style: TextStyle(
                  fontSize: 18,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              leading: Icon(Icons.qr_code, color: isDark ? Colors.white : Colors.black),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => QrGenerator()));
              },
            ),
          ],
        ),
      ),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF23272F) : Colors.grey[200],
        actions: [
          IconButton(
            onPressed: _pickImageAndScan,
            icon: Icon(
              Icons.photo_library,
              color: isDark ? Colors.white : Colors.black,
            ),
            tooltip: 'Scan from Gallery',
          ),
          IconButton(
            onPressed: () {
              setState(() {
                isFlashon = !isFlashon;
              });
              controller.toggleTorch();
            },
            icon: Icon(
              Icons.flash_on,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                iscamera = !iscamera;
              });
              controller.switchCamera();
            },
            icon: Icon(
              Icons.camera_front,
              color: isDark ? Colors.white : Colors.black,
            ),
          )
        ],
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
        title: Text(
          "Qr Scan",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        toolbarHeight: 60,
        centerTitle: true,
      ),
      body: SizedBox(
        width: double.infinity,
        child: Column(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Place the Qr Code Here",
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Scanning will be done automatically",
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black54,
                      fontSize: 16,
                    ),
                  )
                ],
              ),
            ),
            Expanded(
              flex: 4,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onScaleStart: (details) {
                  // store initial zoom so scale is relative to where the user started
                  _baseZoom = zoomLevel;
                },
                onScaleUpdate: (details) {
                  // two-finger pinch to zoom: update zoomLevel relative to _baseZoom
                  if (details.scale != 1.0) {
                    double newZoom = (_baseZoom * details.scale).clamp(_minZoom, _maxZoom);
                    setState(() {
                      zoomLevel = newZoom;
                    });
                    _applyZoom(zoomLevel);
                  }
                },
                onDoubleTap: () {
                  // double-tap toggles between normal and 2x zoom
                  const double doubleTapZoom = 2.0;
                  double target = (zoomLevel > 1.2) ? 1.0 : doubleTapZoom;
                  setState(() {
                    zoomLevel = target;
                    _baseZoom = target;
                  });
                  _applyZoom(zoomLevel);
                },
                onTapUp: (details) {
                  // single tap: try to focus at tapped point if supported by controller
                  try {
                    (controller as dynamic).focusPoint(details.localPosition);
                  } catch (e) {
                    // If focusPoint isn't supported, devices will usually autofocus automatically.
                  }
                },
                child: Stack(
                  children: [
                    MobileScanner(
                      controller: controller,
                      fit: BoxFit.cover,
                      onDetect: (capture) async {
                        String code = '';
                        if (!isScancompleted) {
                          final barcodes = capture.barcodes;
                          for (final barcode in barcodes) {
                            final value = (barcode.rawValue ?? (barcode.displayValue ?? null))?.toString();
                            debugPrint('Barcode found! $value');
                            if (value != null) code += value;
                          }

                          if (code.isNotEmpty) {
                            setState(() {
                              isScancompleted = true;
                            });
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ResultScreen(
                                  closeScreen: resetScanCompletionFlag,
                                  code: code,
                                ),
                              ),
                            );
                          }
                        }
                      },
                    ),
                    QRScannerOverlay(
                      overlayColor: isDark ? const Color(0xFF181A20) : bgColor,
                      scanAreaHeight: 350,
                      scanAreaWidth: 350,
                      borderRadius: 15,
                      borderColor: Colors.blue,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Container(
                child: const Text("Developed by Dev Enterprises"),
                color: Colors.transparent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Helper methods placed after widget class
extension _ScannerControllerZoom on _AppState {
  Future<void> _applyZoom(double zoom) async {
    // Try several possible controller API names and ranges. Some mobile_scanner
    // versions expect absolute zoom factors (1..4), others expect normalized
    // values (0..1). Try common method names and fall back to normalized.
    final candidates = [
      (z) => (controller as dynamic).setZoomScale(z),
      (z) => (controller as dynamic).setZoom(z),
      (z) => (controller as dynamic).setZoomLevel(z),
      (z) => (controller as dynamic).setZoomFactor(z),
    ];

    for (final fn in candidates) {
      try {
        final res = fn(zoom);
        if (res is Future) await res;
        return;
      } catch (_) {}
    }

    // Try normalized value (0..1) derived from 1..4 range
    final normalized = ((zoom - _minZoom) / (_maxZoom - _minZoom)).clamp(0.0, 1.0);
    for (final fn in candidates) {
      try {
        final res = fn(normalized);
        if (res is Future) await res;
        return;
      } catch (_) {}
    }
  }
}

