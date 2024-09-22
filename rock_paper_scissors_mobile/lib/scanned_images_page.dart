import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:rock_paper_scissors_mobile/appointment_page.dart';
import 'package:rock_paper_scissors_mobile/classes.dart';
import 'package:rock_paper_scissors_mobile/scanner_screen.dart';

class ScannedImagesPage extends StatefulWidget {
  const ScannedImagesPage({
    super.key,
    required this.scannedImages,
  });

  final List<ScannedImage>? scannedImages;

  @override
  State<ScannedImagesPage> createState() => _ScannedImagesPageState();
}

const order = {
  DetectionClasses.heavy: 1,
  DetectionClasses.moderate: 2,
  DetectionClasses.minor: 3,
  DetectionClasses.undamaged: 4,
};

class _ScannedImagesPageState extends State<ScannedImagesPage> {
  bool hasHeavy = false;
  bool hasModerate = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    sortDamages();
    openAlertDialog();
  }

  sortDamages() {
    widget.scannedImages
        ?.sort((a, b) => order[a.detected]!.compareTo(order[b.detected]!));
    hasHeavy = widget.scannedImages
            ?.any((image) => image.detected == DetectionClasses.heavy) ??
        false;
    hasModerate = widget.scannedImages
            ?.any((image) => image.detected == DetectionClasses.moderate) ??
        false;
  }

  openAlertDialog() {
    if (hasHeavy || hasModerate) {
      WidgetsBinding.instance.addPostFrameCallback((e) {
        AwesomeDialog(
          context: context,
          dialogType: DialogType.info,
          animType: AnimType.rightSlide,
          title: 'OMG !!!!!!!!!',
          desc:
              'We detected${hasHeavy ? ' heavy' : ''}${hasHeavy && hasModerate ? ' and' : ''}${hasModerate ? ' moderate' : ''} damage. Please make an appointment immediately from the appointment system and we will send you professionals. ',
          btnCancelOnPress: () {},
          btnOkOnPress: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AppointmentPage(),
              ),
            );
          },
        ).show();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Scanned Images'),
      ),
      body: GridView.count(
        crossAxisCount: 2,
        children: [
          ...widget.scannedImages!.map((e) {
            return Column(
              children: [
                Image.file(
                  e.image,
                  fit: BoxFit.cover,
                  height: 150,
                ),
                Text(
                  "Detected: ${e.detected.label}",
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.blue,
                  ),
                ),
              ],
            );
          })
        ],
      ),
    );
  }
}
