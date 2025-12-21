import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_code_scanner/result.dart'; // Ensure this path is correct
import 'package:qr_scanner_overlay/qr_scanner_overlay.dart';
import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:qr_code_scanner/qrcodegenerator.dart'; // Ensure this path is correct
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart'
    as mlkit;
import 'package:url_launcher/url_launcher.dart'; 
import 'package:share_plus/share_plus.dart';

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
  
  // Zoom Variables
  double zoomLevel = 1.0;
  double _baseZoom = 1.0;
  final double _minZoom = 1.0;
  final double _maxZoom = 4.0;
  
  late MobileScannerController controller;
  bool _isControllerInitialized = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    
    controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
    );
    
    _initializeZoom();
  }

  Future<void> _initializeZoom() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      try {
        // Set to normalized 0.0 (which is 1x zoom in hardware)
        await controller.setZoomScale(0.0);
        setState(() {
          zoomLevel = 1.0; // Display as 1.0x
          _baseZoom = 1.0;
          _isControllerInitialized = true;
        });
        debugPrint('Zoom initialized to 1.0x');
      } catch (e) {
        debugPrint('Error initializing zoom: $e');
      }
    }
  }

  // --- NEW DRAWER ITEM BUILDER (Clean Style) ---
  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      leading: Icon(
        icon,
        color: isDark ? Colors.white70 : Colors.black54, // Neutral colors
        size: 26,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), 
    );
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    controller.dispose();
    super.dispose();
  }

  void resetScanCompletionFlag() async {
    if (isFlashon) {
      try {
        await controller.toggleTorch();
      } catch (e) {
        debugPrint('Error toggling torch: $e');
      }
    }
    
    setState(() {
      isScancompleted = false;
      isFlashon = false;
      zoomLevel = 1.0;
      _baseZoom = 1.0;
    });
    
    try {
      await controller.setZoomScale(0.0);
      debugPrint('Zoom reset to 1.0x');
    } catch (e) {
      debugPrint('Error resetting zoom: $e');
    }
    
    try {
      await controller.start();
    } catch (e) {
      debugPrint('Error restarting scanner: $e');
    }
  }

  // --- ZOOM HELPERS ---
  double _displayToNormalized(double displayZoom) {
    return (displayZoom - 1.0) / 3.0;
  }

  double _normalizedToDisplay(double normalizedZoom) {
    return 1.0 + (normalizedZoom * 3.0);
  }

  Future<void> _animateZoom(double targetDisplayZoom) async {
    final startZoom = zoomLevel;
    final steps = 10;
    final increment = (targetDisplayZoom - startZoom) / steps;
    
    for (int i = 1; i <= steps; i++) {
      final currentDisplayZoom = startZoom + (increment * i);
      final normalizedZoom = _displayToNormalized(currentDisplayZoom);
      
      try {
        await controller.setZoomScale(normalizedZoom);
      } catch (e) {
        debugPrint('Zoom animation error: $e');
      }
      
      await Future.delayed(const Duration(milliseconds: 20));
      
      if (mounted) {
        setState(() {
          zoomLevel = currentDisplayZoom;
          _baseZoom = currentDisplayZoom;
        });
      }
    }
  }

  // --- GALLERY SCAN (ML KIT) ---
  Future<void> _pickImageAndScan() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        final inputImage = mlkit.InputImage.fromFilePath(image.path);
        final barcodeScanner =
            mlkit.BarcodeScanner(formats: [mlkit.BarcodeFormat.all]);

        try {
          final List<mlkit.Barcode> barcodes =
              await barcodeScanner.processImage(inputImage);

          if (barcodes.isNotEmpty) {
            final barcode = barcodes.first;

            String details = "Type: ${barcode.type.name.toUpperCase()}\n"
                "Format: ${barcode.format.name.toUpperCase()}\n"
                "Data: ${barcode.rawValue ?? 'No data found'}";

            if (mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ResultScreen(
                    closeScreen: resetScanCompletionFlag,
                    code: details,
                  ),
                ),
              );
            }
          } else {
            _showSnackBar('No QR/Barcode found in image');
          }
        } finally {
          barcodeScanner.close();
        }
      }
    } catch (e) {
      _showSnackBar('Error scanning image: $e');
    }
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF181A20) : bgColor,
      
      // 🎨 NEW PROFESSIONAL DRAWER
      drawer: Drawer(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 70, 20, 30),
              color: isDark ? Colors.black : const Color(0xFF212121),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.qr_code_2,
                      size: 35,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        "QR MASTER",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        "Pro Scanner",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 15),

            // Menu Items
            _buildDrawerItem(
              icon: Icons.qr_code_scanner_rounded,
              title: 'QR Generator',
              isDark: isDark,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const QrGenerator()),
                );
              },
            ),
            
            _buildDrawerItem(
              icon: Icons.share_rounded,
              title: 'Share App',
              isDark: isDark,
              onTap: () {
                Navigator.pop(context);
                Share.share(
                  'Check out this QR Scanner! https://play.google.com/store/apps/details?id=com.dev.qr_code_scanner',
                );
              },
            ),
            
            _buildDrawerItem(
              icon: Icons.star_rounded,
              title: 'Rate Us',
              isDark: isDark,
              onTap: () async {
                Navigator.pop(context);
                final Uri url = Uri.parse(
                  'https://play.google.com/store/apps/details?id=com.dev.qr_code_scanner',
                );
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                }
              },
            ),
            
            const Spacer(),
            
            // Footer
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Divider(color: isDark ? Colors.white10 : Colors.black12),
                    const SizedBox(height: 15),
                    Text(
                      "Dev Enterprises © 2025",
                      style: TextStyle(
                        color: isDark ? Colors.white54 : Colors.black54,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "v1.0.0",
                      style: TextStyle(
                        color: isDark ? Colors.white30 : Colors.black38,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF23272F) : Colors.grey[200],
        actions: [
          IconButton(
            onPressed: _pickImageAndScan,
            icon: Icon(Icons.photo_library,
                color: isDark ? Colors.white : Colors.black),
            tooltip: 'Scan from Gallery',
          ),
          IconButton(
            onPressed: () async {
              try {
                await controller.toggleTorch();
                setState(() => isFlashon = !isFlashon);
              } catch (e) {
                debugPrint('Flash toggle error: $e');
                _showSnackBar('Could not toggle flash');
              }
            },
            icon: Icon(
              isFlashon ? Icons.flash_on : Icons.flash_off,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          IconButton(
            onPressed: () async {
              try {
                await controller.switchCamera();
                setState(() => iscamera = !iscamera);
                // Reset zoom after camera switch
                await Future.delayed(const Duration(milliseconds: 300));
                await controller.setZoomScale(0.0);
                setState(() {
                  zoomLevel = 1.0;
                  _baseZoom = 1.0;
                });
              } catch (e) {
                debugPrint('Camera switch error: $e');
              }
            },
            icon: Icon(Icons.camera_front,
                color: isDark ? Colors.white : Colors.black),
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
            
            // SCANNER & ZOOM AREA
            Expanded(
              flex: 4,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onScaleStart: (details) {
                  _baseZoom = zoomLevel;
                },
                onScaleUpdate: (details) {
                  double newDisplayZoom = (_baseZoom * details.scale).clamp(_minZoom, _maxZoom);
                  double normalizedZoom = _displayToNormalized(newDisplayZoom);
                  
                  controller.setZoomScale(normalizedZoom).catchError((e) {
                    debugPrint('Zoom error: $e');
                  });
                  
                  if (mounted) {
                    setState(() {
                      zoomLevel = newDisplayZoom;
                    });
                  }
                },
                onScaleEnd: (details) {
                  _baseZoom = zoomLevel;
                  debugPrint('Zoom set to: ${zoomLevel.toStringAsFixed(1)}x');
                },
                onDoubleTap: () async {
                  double targetZoom = (zoomLevel > 1.5) ? 1.0 : 2.0;
                  await _animateZoom(targetZoom);
                  debugPrint('Double tap zoom: ${targetZoom.toStringAsFixed(1)}x');
                },
                child: Stack(
                  children: [
                    MobileScanner(
                      controller: controller,
                      fit: BoxFit.cover,
                      onDetect: (capture) async {
                        if (isScancompleted) return;

                        final List<Barcode> barcodes = capture.barcodes;

                        if (barcodes.isNotEmpty) {
                          final Barcode firstBarcode = barcodes.first;

                          if (firstBarcode.rawValue != null && 
                              firstBarcode.rawValue!.isNotEmpty &&
                              !isScancompleted) {
                            
                            String displayDetails =
                                "Type: ${firstBarcode.type.name.toUpperCase()}\n"
                                "Format: ${firstBarcode.format.name.toUpperCase()}\n"
                                "Data: ${firstBarcode.rawValue ?? 'Unknown'}";

                            debugPrint('Valid Barcode found: $displayDetails');
                            
                            setState(() {
                              isScancompleted = true;
                            });
                            
                            try {
                              await controller.stop();
                            } catch (e) {
                              debugPrint('Error stopping scanner: $e');
                            }
                            
                            if (isFlashon) {
                              try {
                                await controller.toggleTorch();
                                if (mounted) {
                                  setState(() {
                                    isFlashon = false;
                                  });
                                }
                              } catch (e) {
                                debugPrint('Error turning off flash: $e');
                              }
                            }
                            
                            if (!mounted) return;
                            
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ResultScreen(
                                  closeScreen: resetScanCompletionFlag,
                                  code: displayDetails,
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
                    // Zoom level indicator
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${zoomLevel.toStringAsFixed(1)}x',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Bottom Footer
            const Expanded(
              child: Center(
                child: Text("Developed by Dev Enterprises",
                    style: TextStyle(
                        color: Colors.grey, fontWeight: FontWeight.w500)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}