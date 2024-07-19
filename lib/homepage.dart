
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// ignore: depend_on_referenced_packages
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_code_scanner/result.dart';
// ignore: depend_on_referenced_packages
import 'package:qr_scanner_overlay/qr_scanner_overlay.dart';
// ignore: depend_on_referenced_packages
// ignore: depend_on_referenced_packages
import 'package:qr_code_scanner/qrcodegenerator.dart';
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
    super.dispose();
  }

  void resetScanCompletionFlag() {
    setState(() {
      isScancompleted = false;
      print('Changed succesfully');
    });
  }
  


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
           
            children: [
               const DrawerHeader(decoration: BoxDecoration(color: Colors.black26), child:Text("QR CODE SCANNER",style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold,),)),
               ListTile(
                title:  const Text('QR Code Generator',style: TextStyle(
                  fontSize: 18,
                  color: Colors.black
                   ),),
                leading:const Icon(Icons.qr_code),
                onTap: (){
                  Navigator.push(context, MaterialPageRoute(builder: (context)=>QrGenerator()));
                },
              ),],
          )
       
               
        
        ),
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                isFlashon = !isFlashon;
              });
              controller.toggleTorch();
            },
            icon: Icon(
              Icons.flash_on,
              color: isFlashon ? Colors.blue : Colors.grey,
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
              color: iscamera ? Colors.blue : Colors.grey,
            ),
          )
        ],
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text(
          "Qr Code Scanner",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),

        toolbarHeight: 60,
        centerTitle: true,
        // leading: IconButton(icon:,),
      ),
      body: SizedBox(
        width: double.infinity,
        child: Column(
          children: [
            const Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Place the Qr Code Here",
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  Text(
                    "Scanning will be done automatically",
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 16,
                    ),
                  )
                ],
              ),
            ),
            Expanded(
                flex: 4,
                child: Stack(
                  children: [
                    MobileScanner(
                        controller: controller,
                        onDetect: (capture) {
                          String code = '';
                          if (!isScancompleted) {
                            final List<Barcode> barcodes = capture.barcodes;
                            // Initialize code variable
                            // Iterate through each barcode and concatenate raw values
                            for (final barcode in barcodes) {
                              debugPrint('Barcode found!${barcode.rawValue}');
                              // Concatenate raw value with a space separator
                              code += barcode.rawValue.toString();
                            }
                          }
                              if (isFlashon) {
                          controller.toggleTorch(); // Turn off the torch
                     setState(() {
                         isFlashon = false; // Update the state to reflect the torch being off
                        });
                           }
                          if (!isScancompleted) {
                            isScancompleted = true; // Set scan completion flag
                        
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ResultScreen(
                                  closeScreen: resetScanCompletionFlag,
                                  code: code,
                                ),
                                
                              ),
                            );
                          }
                        }),
                    QRScannerOverlay(
                      overlayColor: bgColor,
                      // scanAreaSize: Size.square(500),
                      scanAreaHeight: 350,
                      scanAreaWidth: 350,
                      borderRadius: 15,
                      borderColor: Colors.blue,
                    )
                  ],
                )),
          //       const SizedBox(height: 10,),
          //     ElevatedButton(
          //  onPressed: () {
          //   // Add your onPressed logic here
          //   _pickImageAndScan(context);
          //           },
          //  style: ElevatedButton.styleFrom(
          //        backgroundColor: Color.fromARGB(218, 186, 184, 184),
          //       elevation: 0, // Remove elevation
          //     shadowColor: Colors.transparent, // Remove shadow
          //   //  padding: EdgeInsets.zero, // Remove padding
          //     ),
          // child: const Row(
          //    mainAxisSize: MainAxisSize.min,
          //   children: [
          //      Icon(
          //        Icons.photo_library,
          //       color: Colors.black45, // Customize icon color
          //         ),
          //      SizedBox(width: 13), // Adjust spacing between icon and text
          //     Text(
          //     "Scan Image from Gallery",
          //      style: TextStyle(
          //     fontSize: 18,
          //      color: Colors.black87,
          //      ),
          //     ),
          //     ],
          //       ),
          //   ),
            const SizedBox(height: 20),
            Expanded(
                child: Container(
              child: const Text("Developed by Dev Enterprises"),
              color: Colors.transparent,
            )),
          ],
        ),
      ),
    );
  }
}
