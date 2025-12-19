import 'package:flutter/material.dart';
import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/services.dart';
// avoid importing homepage to prevent circular dependency; use theme colors instead
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
// ignore: depend_on_referenced_packages
import 'package:url_launcher/url_launcher_string.dart';
class ResultScreen extends StatefulWidget {
  final String code;
  final Function() closeScreen;

  const ResultScreen({super.key, required this.closeScreen, required this.code});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
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

  void _launchUrl() async {
    var url = widget.code.trim();
    if (!url.startsWith(RegExp(r'https?://'))) {
      url = 'https://$url';
    }
    if (await canLaunchUrlString(url)) {
      await launchUrlString(url, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cannot open link')));
    }
  }

  String _getDisplayLabel() {
    final lower = widget.code.toLowerCase();
    if (lower.contains('upi')) return 'UPI Payment';
    if (lower.startsWith('http') || lower.startsWith('www') || lower.startsWith('https')) return 'Website/URL';
    if (lower.startsWith('tel:') || RegExp(r'^\+?\d{7,}$').hasMatch(widget.code)) return 'Phone Number';
    if (lower.startsWith('mailto:') || (widget.code.contains('@') && !widget.code.contains(' '))) return 'Email Address';
    if (lower.startsWith('sms:')) return 'SMS Message';
    if (lower.startsWith('begin:vcard')) return 'Contact (vCard)';
    if (widget.code.contains(RegExp(r'^[0-9]*$'))) return 'Barcode';
    return 'QR Code';
  }

  IconData _getActionIcon() {
    final label = _getDisplayLabel();
    switch (label) {
      case 'Phone Number':
        return Icons.call;
      case 'Email Address':
        return Icons.email;
      case 'Website/URL':
        return Icons.language;
      case 'UPI Payment':
        return Icons.payment;
      case 'SMS Message':
        return Icons.sms;
      case 'Contact (vCard)':
        return Icons.person;
      default:
        return Icons.open_in_browser;
    }
  }

  String _getActionLabel() {
    final label = _getDisplayLabel();
    switch (label) {
      case 'Phone Number':
        return 'Call';
      case 'Email Address':
        return 'Send Email';
      case 'Website/URL':
        return 'Open Link';
      case 'UPI Payment':
        return 'Pay Now';
      case 'SMS Message':
        return 'Send SMS';
      case 'Contact (vCard)':
        return 'View Contact';
      default:
        return 'Open';
    }
  }

  Future<void> _handleScanned() async {
    final data = widget.code.trim();
    if (data.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No data to open')));
      return;
    }

    final lower = data.toLowerCase();

    // vCard: show content and allow copy/share
    if (lower.startsWith('begin:vcard')) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Contact (vCard)'),
          content: SingleChildScrollView(child: Text(data)),
          actions: [
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: data));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Contact copied')));
              },
              child: const Text('Copy'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
      return;
    }

    // UPI Payment
    if (lower.contains('upi://') || lower.contains('upi:')) {
      if (await canLaunchUrlString(data)) {
        await launchUrlString(data, mode: LaunchMode.externalApplication);
        return;
      }
    }

    // HTTP/HTTPS/WWW -> open in browser
    if (lower.startsWith('http://') || lower.startsWith('https://') || lower.startsWith('www.')) {
      final url = data.startsWith(RegExp(r'https?://')) ? data : 'https://$data';
      if (await canLaunchUrlString(url)) {
        await launchUrlString(url, mode: LaunchMode.externalApplication);
        return;
      }
    }

    // mailto
    if (lower.startsWith('mailto:') || (data.contains('@') && !data.contains(' '))) {
      final mail = data.startsWith('mailto:') ? data : 'mailto:$data';
      if (await canLaunchUrlString(mail)) {
        await launchUrlString(mail, mode: LaunchMode.externalApplication);
        return;
      }
    }

    // SMS
    if (lower.startsWith('sms:')) {
      if (await canLaunchUrlString(data)) {
        await launchUrlString(data, mode: LaunchMode.externalApplication);
        return;
      }
    }

    // Telephone numbers (plain digits) or tel: scheme
    final phoneRe = RegExp(r'^\+?\d{7,}$');
    if (lower.startsWith('tel:') || phoneRe.hasMatch(data)) {
      final tel = data.startsWith('tel:') ? data : 'tel:$data';
      if (await canLaunchUrlString(tel)) {
        await launchUrlString(tel, mode: LaunchMode.externalApplication);
        return;
      }
    }

    // Nothing matched: show the scanned text with actions
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Scanned:', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            SelectableText(data),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.copy),
              label: const Text('Copy'),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: data));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied')));
              },
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.share),
              label: const Text('Share'),
              onPressed: () {
                Navigator.pop(context);
                Share.share(data);
              },
            ),
          ],
        ),
      ),
    );
  }
  
  
  


  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    String displayLabel = _getDisplayLabel();
    
    return WillPopScope(
      onWillPop: () async {
        widget.closeScreen();
        return true;
      },
      child: Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text(
            "Scan Result",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          toolbarHeight: 60,
          centerTitle: true,
          elevation: 0,
          leading: IconButton(
            onPressed: () {
              Navigator.pop(context);
              widget.closeScreen();
            },
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 20),
              // QR Code Display
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[850] : Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                margin: const EdgeInsets.symmetric(horizontal: 20),
                child: QrImageView(
                  data: widget.code,
                  size: 200,
                  version: QrVersions.auto,
                  gapless: false,
                  embeddedImage: const AssetImage('assets/images/embeded.png'),
                  embeddedImageStyle: const QrEmbeddedImageStyle(
                    size: Size(60, 60),
                  ),
                ),
              ),
              const SizedBox(height: 25),
              // Scanned Result Label
              Text(
                  displayLabel,
                  style: TextStyle(
                    color: isDarkMode ? Colors.blue : Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              const SizedBox(height: 15),
              // Content Box with Text
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[900] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.blue.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    widget.code,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black87,
                      fontSize: 16,
                      height: 1.5,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              // Action Buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    // Primary Action Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        icon: Icon(_getActionIcon(), color: isDarkMode ? Colors.white : Colors.black),
                        label: Text(_getActionLabel(), style: TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
                        onPressed: _handleScanned,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDarkMode ? Colors.blue : Colors.grey[200],
                          foregroundColor: isDarkMode ? Colors.white : Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: isDarkMode ? Colors.white.withOpacity(0.5) : Colors.black.withOpacity(0.3), width: 1.5),
                          ),
                          elevation: isDarkMode ? 8 : 4,
                          shadowColor: isDarkMode ? Colors.blue.withOpacity(0.5) : Colors.black.withOpacity(0.3),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Copy Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton.icon(
                        icon: Icon(Icons.copy, color: isDarkMode ? Colors.white : Colors.black),
                        label: Text('Copy', style: TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: widget.code));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Copied to clipboard'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isDarkMode ? Colors.white : Colors.black,
                          side: BorderSide(color: isDarkMode ? Colors.white : Colors.black, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Share Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton.icon(
                        icon: Icon(Icons.share, color: isDarkMode ? Colors.white : Colors.black),
                        label: Text('Share', style: TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
                        onPressed: () {
                          Share.share(widget.code);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isDarkMode ? Colors.white : Colors.black,
                          side: BorderSide(color: isDarkMode ? Colors.white : Colors.black, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
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
      ),
    );
  }
}
