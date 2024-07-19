import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_code_scanner/homepage.dart';
import 'package:qr_flutter/qr_flutter.dart';
// ignore: depend_on_referenced_packages
import 'package:url_launcher/url_launcher_string.dart';
class ResultScreen extends StatelessWidget {
  final String code;
  final Function() closeScreen;

  const ResultScreen({super.key, required this.closeScreen, required this.code});
  void _launchUrl() async {
    if (await canLaunchUrlString(code)) {
      await launchUrlString(code);
    } else {
     Text("unable to find");
      
    }
  }
  
  

  @override
  Widget build(BuildContext context) {

    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: () async {
        closeScreen(); // Call closeScreen() when back button is pressed
        return true;
      },
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          title: const Text(
            "Qr Code Scanner",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          toolbarHeight: 60,
          centerTitle: true,
          leading: IconButton(
            onPressed: () {
              Navigator.pop(context);
              closeScreen();
            },
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.black87,
            ),
          ),
        ),
        body: Container(
          alignment: Alignment.center,
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                //show qr
                QrImageView(
                  data: code,
                  size: 150,
                  version: QrVersions.auto,
                   gapless: false,
                  embeddedImage: const AssetImage('assets/images/embeded.png'),
                embeddedImageStyle:const QrEmbeddedImageStyle(
                  size: Size(80, 80),
                   ),
                ),
                    
                const Text(
                  "Scanned Result",
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                  Column(
                  children: [
                    if (code.contains(RegExp(r'^[0-9]*$')))
                      Text(
                        "Barcode: $code",
                         
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 18,
                          letterSpacing: 1,
                        ),
                      )
                    else
                      Text(
                        "Qr Code: $code",
                        textAlign: TextAlign.center,
                        style:const TextStyle(
                          color: Colors.black87,
                          fontSize: 16,
                          letterSpacing: 1,
                        ),
                      ),
                  ],
                ),
                
                const SizedBox(
                  height: 10,
                ),
                SizedBox(
                  width: MediaQuery.of(context).size.width - 100,
                  height: 48,
                  child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                      ),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: code));
                      },
                      child: const Text(
                        "Copy",
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 16,
                          letterSpacing: 1,
                        ),
                      )),
                ),
                const SizedBox(height: 15),
                    
                SizedBox(
                  width: MediaQuery.of(context).size.width - 100,
                  height: 48,
                  child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                      ),
                      onPressed: _launchUrl,
                      child: const Text(
                        "Open Link",
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 16,
                          letterSpacing: 1,
                        ),
                      )),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
