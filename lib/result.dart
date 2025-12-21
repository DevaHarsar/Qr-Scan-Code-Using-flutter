import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class ResultScreen extends StatefulWidget {
  final String code;
  final Function() closeScreen;

  const ResultScreen(
      {super.key, required this.closeScreen, required this.code});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  late BannerAd _bannerAd;
  bool _isBannerAdReady = false;

  @override
  void initState() {
    super.initState();
    _initBannerAd();
  }

  void _initBannerAd() {
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

  @override
  void dispose() {
    _bannerAd.dispose();
    super.dispose();
  }

  // --- HELPER 1: Extract Clean Data (Removes "Type:..." prefix) ---
  // Used for Actions (Search, Copy, Share)
  String _getRawContent() {
    if (widget.code.startsWith('Type:')) {
      final lines = widget.code.split('\n');
      for (final line in lines) {
        if (line.startsWith('Data: ')) {
          return line.substring(6).trim(); // Removes "Data: "
        }
      }
    }
    return widget.code.trim(); // Fallback
  }

  // --- HELPER 2: Extract Format (To distinguish Barcode vs QR) ---
  String _getFormat() {
    if (widget.code.startsWith('Type:')) {
      final lines = widget.code.split('\n');
      for (final line in lines) {
        if (line.startsWith('Format: ')) {
          return line.substring(8).trim().toUpperCase();
        }
      }
    }
    return 'UNKNOWN';
  }

  // --- LOGIC: Identify Content Type ---
  String _getDisplayLabel() {
    final rawData = _getRawContent();
    final lower = rawData.toLowerCase();
    final format = _getFormat();

    // 1. Product Barcodes
    if (format.contains('EAN') ||
        format.contains('UPC') ||
        format.contains('ISBN') ||
        format.contains('PRODUCT')) {
      return 'Product Barcode';
    }

    // 2. Standard QR Types
    if (lower.contains('upi://') || lower.contains('pa=')) return 'UPI Payment';
    if (lower.startsWith('http') || lower.contains('www.'))
      return 'Website/URL';
    if (lower.startsWith('tel:')) return 'Phone Number';
    if (lower.startsWith('mailto:') ||
        (rawData.contains('@') && !rawData.contains(' ')))
      return 'Email Address';
    if (lower.startsWith('smsto:') || lower.startsWith('sms:'))
      return 'SMS / Message';
    if (lower.startsWith('wifi:')) return 'WiFi Network';

    // 3. Fallback
    if (RegExp(r'^\+?\d{7,}$').hasMatch(rawData)) {
      if (format.contains('QR')) return 'Phone Number';
    }

    return 'Text / Data';
  }

  IconData _getActionIcon() {
    switch (_getDisplayLabel()) {
      case 'Product Barcode':
        return Icons.shopping_cart;
      case 'Phone Number':
        return Icons.call;
      case 'Email Address':
        return Icons.email;
      case 'Website/URL':
        return Icons.language;
      case 'UPI Payment':
        return Icons.payment;
      case 'WiFi Network':
        return Icons.wifi;
      case 'SMS / Message':
        return Icons.message;
      default:
        return Icons.search;
    }
  }

  String _getActionLabel() {
    switch (_getDisplayLabel()) {
      case 'Product Barcode':
        return 'Search Product';
      case 'Phone Number':
        return 'Call Now';
      case 'Email Address':
        return 'Send Email';
      case 'Website/URL':
        return 'Open Link';
      case 'UPI Payment':
        return 'Pay Now';
      case 'WiFi Network':
        return 'Connect/View';
      case 'SMS / Message':
        return 'Send Message';
      default:
        return 'Web Search';
    }
  }

  // --- CORE ACTION HANDLER ---
  Future<void> _handleScanned() async {
    final data = _getRawContent(); // USE RAW DATA FOR ACTIONS
    final label = _getDisplayLabel();

    try {
      Uri? targetUri;

      if (label == 'Product Barcode' || label == 'Text / Data') {
        targetUri = Uri.parse('https://www.google.com/search?q=$data');
      } else if (label == 'Website/URL') {
        String url = data;
        if (!url.startsWith('http')) url = 'https://$url';
        targetUri = Uri.parse(url);
      } else if (label == 'UPI Payment') {
        targetUri = Uri.parse(data.trim());
      } else if (label == 'Phone Number') {
        targetUri = Uri.parse('tel:$data');
      } else if (label == 'Email Address') {
        targetUri = Uri.parse('mailto:$data');
      } else if (label == 'SMS / Message') {
        targetUri = Uri.parse('sms:$data');
      }

      if (targetUri != null) {
        // FIX: Don't use 'await canLaunchUrl(targetUri)' for UPI
        // Just try to launch it. If it fails, the bool result will be false.
        bool launched = await launchUrl(
          targetUri,
          mode: LaunchMode.externalApplication, // Critical for UPI apps
        );

        if (!launched) {
          // Only show the error sheet if the launch actually failed
          _showCopyShareSheet(data);
        }
      } else {
        _showCopyShareSheet(data);
      }
    } catch (e) {
      _showCopyShareSheet(data);
    }
  }

  void _showCopyShareSheet(String data) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Action Failed',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 10),
            const Text(
                'Could not open this content directly. You can copy or share it below.'),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                    child: _buildOptionBtn(
                        Icons.copy,
                        'Copy',
                        () => Clipboard.setData(ClipboardData(text: data)),
                        isDarkMode)),
                const SizedBox(width: 10),
                Expanded(
                    child: _buildOptionBtn(Icons.share, 'Share',
                        () => Share.share(data), isDarkMode)),
              ],
            )
          ],
        ),
      ),
    );
  }

  // --- STYLED OPTION BUTTON (Copy/Share) ---
  Widget _buildOptionBtn(
      IconData icon, String label, VoidCallback onTap, bool isDarkMode) {
    return OutlinedButton.icon(
      icon: Icon(icon),
      label: Text(label),
      onPressed: () {
        onTap();
        if (label == 'Copy') {
          // Close sheet if opened via sheet, or check if context valid
          if (Navigator.canPop(context)) {
            // Only pop if this was called from the bottom sheet fallback
            // Navigator.pop(context); // Optional: decide if you want to close sheet
          }
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Copied to clipboard!')));
        }
      },
      style: OutlinedButton.styleFrom(
        // FIXED: Text Color based on theme
        foregroundColor: isDarkMode ? Colors.white : Colors.black,
        // FIXED: Border Color based on theme
        side: BorderSide(
            color: isDarkMode ? Colors.white54 : Colors.black54, width: 1.5),
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      onPopInvoked: (didPop) => widget.closeScreen(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Scan Result"),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            onPressed: () {
              widget.closeScreen();
              Navigator.pop(context);
            },
          ),
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 30),

              // 1. QR IMAGE PREVIEW (With Embedded Asset Logo)
              Center(
                child: Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.blue.withOpacity(0.2),
                          blurRadius: 15,
                          spreadRadius: 5)
                    ],
                  ),
                  child: QrImageView(
                    data: _getRawContent(), // The scanned data
                    size: 180,
                    version: QrVersions.auto,
                    // 1. Link to your asset image
                    embeddedImage:
                        const AssetImage('assets/images/embeded.png'),
                    // 2. Style the logo (Size)
                    embeddedImageStyle: const QrEmbeddedImageStyle(
                      size: Size(
                          40, 40), // Adjust size (usually 15-20% of QR size)
                    ),
                    // 3. Set High Error Correction so the logo doesn't break scanning
                    errorCorrectionLevel: QrErrorCorrectLevel.H,
                  ),
                ),
              ),

              // 2. SMART LABEL - Moved down slightly to avoid crowding
              const SizedBox(height: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _getDisplayLabel(),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ),

              const SizedBox(height: 25), // Spacing between label and box

              // 3. ENHANCED CONTENT BOX (Better UX)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 25),
                padding: const EdgeInsets.all(20),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.white10 : Colors.grey[100],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue.withOpacity(0.2)),
                ),
                child: SelectableText.rich(
                  TextSpan(
                    children: [
                      // Line 1: Type Label
                      const TextSpan(
                        text: "Type: ",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.blue),
                      ),
                      // Line 1: Type Value
                      TextSpan(
                        text: "${_getDisplayLabel()}\n\n",
                        style: const TextStyle(fontWeight: FontWeight.normal),
                      ),
                      // Line 2: Data Label
                      const TextSpan(
                        text: "Data: ",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.blue),
                      ),
                      // Line 2: Data Value (The actual link or text)
                      TextSpan(
                        text: _getRawContent(),
                        style: const TextStyle(fontWeight: FontWeight.normal),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, height: 1.4),
                ),
              ),
              const SizedBox(height: 30),

              // 4. MAIN ACTION BUTTON (Uses Raw Data)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton.icon(
                        icon: Icon(_getActionIcon()),
                        label: Text(_getActionLabel(),
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        onPressed: _handleScanned,
                        style: ElevatedButton.styleFrom(
                          // Fixed: Button color logic
                          backgroundColor:
                              isDarkMode ? Colors.blue : Colors.blue,
                          foregroundColor: Colors.white,
                          side: isDarkMode
                              ? const BorderSide(
                                  color: Colors.white24, width: 1)
                              : null,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15)),
                          elevation: isDarkMode ? 0 : 2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 5. COPY & SHARE BUTTONS (Styled & Using Raw Data)
                    Row(
                      children: [
                        Expanded(
                          child: _buildOptionBtn(
                              Icons.copy,
                              'Copy',
                              () => Clipboard.setData(
                                  ClipboardData(text: _getRawContent())),
                              isDarkMode),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: _buildOptionBtn(Icons.share, 'Share',
                              () => Share.share(_getRawContent()), isDarkMode),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // 6. BANNER AD
        bottomNavigationBar: _isBannerAdReady
            ? SafeArea(
                child: SizedBox(
                  height: _bannerAd.size.height.toDouble(),
                  child: AdWidget(ad: _bannerAd),
                ),
              )
            : null,
      ),
    );
  }
}
