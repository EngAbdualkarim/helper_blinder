import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image_picker/image_picker.dart';
import 'package:translator/translator.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Image Labelling Assistant',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        brightness: Brightness.light,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const ImageLabelling(),
    );
  }
}

class ImageLabelling extends StatefulWidget {
  const ImageLabelling({Key? key}) : super(key: key);

  @override
  State<ImageLabelling> createState() => _ImageLabellingState();
}

class _ImageLabellingState extends State<ImageLabelling>
    with TickerProviderStateMixin {
  late InputImage _inputImage;
  File? _pickedImage;
  final imageLabeler =
      ImageLabeler(options: ImageLabelerOptions(confidenceThreshold: 0.8));
  final ImagePicker _imagePicker = ImagePicker();
  final translator = GoogleTranslator();
  final FlutterTts flutterTts = FlutterTts();

  String text = "";
  String translatedText = "";
  bool _isFirstTime = true;

  @override
  void initState() {
    super.initState();
    if (_isFirstTime) {
      _announceFirstTime();
      _isFirstTime = false;
    }
  }

  // Announce message when the app is opened for the first time
  _announceFirstTime() async {
    await flutterTts.setLanguage("ar");
    await flutterTts.speak("مساعدك الذكي كفيف");
  }

  // Pick image from gallery
  pickImageFromGallery() async {
    XFile? image = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    setState(() {
      _pickedImage = File(image.path);
    });

    _inputImage = InputImage.fromFile(_pickedImage!);
    identifyImage(_inputImage);
  }

  // Capture image from camera
  pickImageFromCamera() async {
    var status = await Permission.camera.request();
    if (status.isGranted) {
      XFile? image = await _imagePicker.pickImage(source: ImageSource.camera);
      if (image == null) return;

      setState(() {
        _pickedImage = File(image.path);
      });

      _inputImage = InputImage.fromFile(_pickedImage!);
      identifyImage(_inputImage);
    } else if (status.isPermanentlyDenied) {
      openAppSettings();
    }
  }

  // Identify image using Google ML Kit
  void identifyImage(InputImage inputImage) async {
    final List<ImageLabel> imageLabels =
        await imageLabeler.processImage(inputImage);

    if (imageLabels.isEmpty) {
      setState(() {
        text = "Unable to identify the image";
      });
      return;
    }

    // Display the label without showing confidence score in the UI
    for (ImageLabel img in imageLabels) {
      setState(() {
        text = "";
      });
      translateLabel(img.label);
    }
    imageLabeler.close();
  }

  // Translate label to Arabic and convert to speech
  void translateLabel(String label) async {
    var translation = await translator.translate(label, to: 'ar');
    setState(() {
      translatedText = translation.text;
    });

    // Convert translated text to Arabic speech
    await flutterTts.setLanguage("ar");
    await flutterTts.speak("أمامك $translatedText");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "التعرف على الصور",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 4,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.teal, Colors.greenAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.tealAccent.shade100],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(seconds: 1),
              curve: Curves.easeInOut,
              height: 300,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 5,
                    blurRadius: 7,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: _pickedImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.file(
                        _pickedImage!,
                        height: 300,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(
                        'images/default.png',
                        fit: BoxFit.cover,
                        height: 300,
                      ),
                    ),
            ),
            const SizedBox(height: 20),
            Text(
              text.isNotEmpty ? text : "اختر صورة",
              style: const TextStyle(
                  fontSize: 20,
                  color: Colors.black,
                  fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              translatedText.isNotEmpty ? "الترجمة: $translatedText" : "",
              style: const TextStyle(fontSize: 18, color: Colors.green),
              textAlign: TextAlign.center,
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.image, color: Colors.white),
                    label: const Text(
                      "اختر من المعرض",
                      style: TextStyle(fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: pickImageFromGallery,
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.camera_alt, color: Colors.white),
                    label: const Text(
                      "التقاط من الكاميرا",
                      style: TextStyle(fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: pickImageFromCamera,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
