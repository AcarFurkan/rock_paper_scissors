import 'dart:developer';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rock_paper_scissors_mobile/admin_page.dart';
import 'package:rock_paper_scissors_mobile/appointment_page.dart';
import 'package:rock_paper_scissors_mobile/clasifier.dart';
import 'package:rock_paper_scissors_mobile/image_utils.dart';
import 'package:rock_paper_scissors_mobile/login_page.dart';
import 'package:rock_paper_scissors_mobile/scanned_images_page.dart';
import 'package:rock_paper_scissors_mobile/user.dart';
import 'package:rock_paper_scissors_mobile/user_preferences.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as imageLib;

import 'classes.dart';

const List<String> adminList = ['+905448716740', '+905448716739'];

class ControllerPage extends StatefulWidget {
  const ControllerPage({super.key});

  @override
  State<ControllerPage> createState() => _ControllerPageState();
}

class _ControllerPageState extends State<ControllerPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((e) {
      getLocalUser();
    });
  }

  getLocalUser() async {
    final user = await UserPreferences.getUser();
    if (adminList.contains(user?.phone)) {
      Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute<void>(
              builder: (BuildContext context) => AdminPage()),
          (Route<dynamic> route) => false);
    } else {
      Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute<void>(
              builder: (BuildContext context) => HomePage()),
          (Route<dynamic> route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

enum CameraStatus {
  galary,
  live,
  profile,
}

class _HomePageState extends State<HomePage> {
  CameraController? cameraController;
  late Interpreter interpreter;
  final classifier = Classifier();

  bool initialized = false;
  bool isbusy = false;
  DetectionClasses detected = DetectionClasses.undamaged;
  DateTime lastShot = DateTime.now();
  CameraStatus status = CameraStatus.galary;
  final PageController controller = PageController();
  final imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    initialize();
    WidgetsBinding.instance.addPostFrameCallback((e) {
      getLocalUser();
    });
  }

  User? user;
  getLocalUser() async {
    user = await UserPreferences.getUser();
    setState(() {});
  }

  Future<void> initialize() async {
    try {
      await classifier.loadModel();

      final cameras = await availableCameras();
      // Create a CameraController object
      cameraController = CameraController(
        cameras[0], // Choose the first camera in the list
        ResolutionPreset.max, // Choose a resolution preset
      ); // Todo:increase resolution

      // Initialize the CameraController and start the camera preview
      await cameraController!.initialize();
      // Listen for image frames
      await cameraController!.startImageStream((image) {
        // Make predictions every 1 second to avoid overloading the device
        if (DateTime.now().difference(lastShot).inSeconds > 1) {
          processCameraImage(image);
        }
      });

      setState(() {
        initialized = true;
      });
      activateLive();
    } catch (e) {
      log(e.toString());
    }
  }

  Future<void> processCameraImage(CameraImage cameraImage) async {
    try {
      if (isbusy) {
        return;
      }
      isbusy = true;

      final convertedImage = ImageUtils.convertYUV420ToImage(cameraImage);

      final result = await classifier.predict(convertedImage);

      if (detected != result) {
        setState(() {
          detected = result;
        });
      }
      isbusy = false;

      lastShot = DateTime.now();
    } catch (e) {
      isbusy = false;
    }
  }

  Future<void> processCameraImage2(File file) async {
    try {
      List<int> imageBytes = file.readAsBytesSync();

      final result =
          await classifier.predict(imageLib.decodeImage(imageBytes)!);

      if (detected != result) {
        setState(() {
          detected = result;
        });
      }
    } catch (e) {
      print('--------' * 55);
      print(e.toString());
      log(e.toString());
    }
  }

  Future<void> processCameraImages(List<File> files) async {
    try {
      setState(() {
        scanning = true;
      });
      scannedImages = [];
      List<List<int>> imageByteList =
          files.map((e) => e.readAsBytesSync()).toList();
      //List<int> imageBytes = file.readAsBytesSync();
      for (var i = 0; i < imageByteList.length; i++) {
        final result =
            await classifier.predict(imageLib.decodeImage(imageByteList[i])!);
        scannedImages ??= [];

        scannedImages?.add(ScannedImage(result, files[i]));
      }

      setState(() {
        scanning = false;
      });
      log('image progress completed');
    } catch (e) {
      setState(() {
        scanning = false;
      });
      print('--------' * 55);
      print(e.toString());
      log(e.toString());
    }
  }

  activateLive() async {
    if (status == CameraStatus.live &&
        cameraController?.value.isPreviewPaused == true) {
      // cameraController?.pausePreview();
      // await initialize();
      cameraController?.resumePreview();
    } else {
      cameraController?.pausePreview();
    }
    //  else if (cameraController != null) {
    //   await cameraController?.dispose();
    //   cameraController = null;
    // }
  }

  bool scanning = false;
  File? selectedImage;
  List<File>? selectedImages;

  List<ScannedImage>? scannedImages;

  @override
  Widget build(BuildContext context) {
    log('scanning: $scanning');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Safe Home AI'),
      ),
      bottomNavigationBar: BottomNavigationBar(
          currentIndex: status.index,
          onTap: (value) {
            setState(() {
              status = CameraStatus.values[value];
              controller.jumpToPage(value);
            });
            activateLive();
          },
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.browse_gallery), label: 'Gallery'),
            //BottomNavigationBarItem(icon: Icon(Icons.camera), label: 'Camera'),
            BottomNavigationBarItem(icon: Icon(Icons.live_help), label: 'Live'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ]),
      body: PageView(
        // controller: PageController(),
        controller: controller,
        onPageChanged: (value) {
          setState(() {
            status = CameraStatus.values[value];
          });
          activateLive();
        },
        children: [
          Container(
            child: scanning
                ? const Center(
                    child: Text('images are being processed...'),
                  )
                : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceEvenly,
                        children: [
                          if (Platform.isAndroid || Platform.isIOS)
                            Column(
                              children: [
                                IconButton(
                                  onPressed: () async {
                                    selectedImage = selectedImages =
                                        scannedImages = null;
                    
                                    final result =
                                        await imagePicker.pickImage(
                                      source: ImageSource.camera,
                                    );
                                    if (result != null) {
                                      selectedImage = File(result.path);
                                      processCameraImage2(
                                          selectedImage!);
                                      //image = objectDetection!.analyseImage(result.path);
                                      setState(() {});
                                    }
                                  },
                                  icon: const Icon(
                                    Icons.camera,
                                    size: 64,
                                  ),
                                ),
                                Text('Kameradan Cek')
                              ],
                            ),
                          Center(
                            child: Column(
                              children: [
                                IconButton(
                                  onPressed: () async {
                                    selectedImage = selectedImages =
                                        scannedImages = null;
                                    setState(() {
                                      scanning = true;
                                    });
                                    final result = await imagePicker
                                        .pickMultiImage(
                                            // source: ImageSource.gallery,
                                            );
                    
                                    //selectedImage = File(result.path);
                                    selectedImages = result
                                        .map(
                                          (e) => File(e.path),
                                        )
                                        .toList();
                                    setState(() {
                                      scanning = true;
                                    });
                                    await processCameraImages(result
                                        .map((e) => File(e.path))
                                        .toList());
                    
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              ScannedImagesPage(
                                            scannedImages:
                                                scannedImages,
                                          ),
                                        ));
                                  },
                                  icon: const Icon(
                                    Icons.photo,
                                    size: 64,
                                  ),
                                ),
                                Text('Galeriden Sec')
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // if (selectedImage != null)
                    //   Image.file(
                    //     selectedImage!,
                    //     fit: BoxFit.cover,
                    //   ),
                    // if (selectedImages != null && scannedImages == null)
                    //   Expanded(
                    //     child: GridView.count(
                    //       crossAxisCount: 2,
                    //       children: [
                    //         ...selectedImages!.map((e) {
                    //           return Image.file(
                    //             e,
                    //             fit: BoxFit.cover,
                    //           );
                    //         })
                    //       ],
                    //     ),
                    //   ),
                    // if (scannedImages != null)
                    //   Expanded(
                    //     child: GridView.count(
                    //       crossAxisCount: 2,
                    //       children: [
                    //         ...scannedImages!.map((e) {
                    //           return Column(
                    //             children: [
                    //               Image.file(
                    //                 e.image,
                    //                 fit: BoxFit.cover,
                    //                 height: 150,
                    //               ),
                    //               Text(
                    //                 "Detected: ${e.detected.label}",
                    //                 style: const TextStyle(
                    //                   fontSize: 14,
                    //                   color: Colors.blue,
                    //                 ),
                    //               ),
                    //             ],
                    //           );
                    //         })
                    //       ],
                    //     ),
                    //   ),
                    
                    // // Text(
                    // //   "Detected: ${detected.label}",
                    // //   style: const TextStyle(
                    // //     fontSize: 28,
                    // //     color: Colors.blue,
                    // //   ),
                    // // ),
                    // // scannedImages.map((e)=>)
                    // ElevatedButton(
                    //   onPressed: () {
                    //     Navigator.push(
                    //       context,
                    //       MaterialPageRoute(
                    //         builder: (context) => AppointmentPage(),
                    //       ),
                    //     );
                    //   },
                    //   child: const Text('Choose Photo From Galery'),
                    // )
                  ],
                ),
          ),
      
          Column(
            children: [
              if (initialized)
                SizedBox(
                  height: MediaQuery.of(context).size.height - 200,
                  width: MediaQuery.of(context).size.width,
                  child: CameraPreview(cameraController!),
                ),
              if (initialized)
                Text(
                  "Detected: ${detected.label}",
                  style: const TextStyle(
                    fontSize: 28,
                    color: Colors.blue,
                  ),
                )
              else
                const Center(
                  child: CircularProgressIndicator(),
                )
            ],
          ),
          Column(
            children: [
              if (user != null)
                Column(
                  children: [
                    ListTile(
                      title: Text('Isim: ${user!.name}'),
                    ),
                    ListTile(
                      title: Text('Telefon: ${user!.phone}'),
                    ),
                    ListTile(
                      title: Text('Sehir: ${user!.city}'),
                    ),
                    ListTile(
                      title: Text('Ilce: ${user!.district}'),
                    ),
                  ],
                ),
              ElevatedButton(
                onPressed: () async {
                  //clear user
      
                  await UserPreferences.removeUser();
                  Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute<void>(
                          builder: (BuildContext context) =>
                              const LoginPage()),
                      (Route<dynamic> route) => false);
                },
                child: const Text('Cikis Yap'),
              )
            ],
          ),
          // else
          //   const Center(
          //     child: CircularProgressIndicator(),
          //   )
        ],
      ),
    );
  }

  @override
  void dispose() {
    cameraController?.dispose();
    super.dispose();
  }
}

class ScannedImage {
  DetectionClasses detected;
  File image;

  ScannedImage(this.detected, this.image);
}
