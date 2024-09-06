import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  runApp(MyApp(cameras: cameras));
}

class MyApp extends StatelessWidget {
  final List<CameraDescription> cameras;

  MyApp({required this.cameras});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OCR Camera App',
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.black,
        primaryColor: Color(0xFF06D001),
        hintColor: Colors.white,
        textTheme: TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white),
          headlineLarge: TextStyle(color: Color(0xFF06D001), fontSize: 32),
          headlineMedium: TextStyle(color: Color(0xFF06D001), fontSize: 24),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Color(0xFF06D001),
          ),
        ),
        appBarTheme: AppBarTheme(
          color: Colors.black,
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(
            color: Color(0xFF06D001),
            fontSize: 20,
          ),
        ),
      ),
      home: HomePage(cameras: cameras),
    );
  }
}

class HomePage extends StatefulWidget {
  final List<CameraDescription> cameras;

  HomePage({required this.cameras});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  CameraController? _cameraController;
  String _ocrText = 'Awaiting detection...';
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      _cameraController = CameraController(
        widget.cameras[0],
        ResolutionPreset.medium,
        enableAudio: false,
      );

      try {
        await _cameraController?.initialize();
        setState(() {});
      } catch (e) {
        print('Error initializing camera: $e');
      }
    } else {
      print("Camera permission denied");
      // Optionally, you could show an alert dialog to the user
    }
  }

  Future<void> _captureImage() async {
    if (_cameraController?.value.isInitialized ?? false) {
      try {
        final image = await _cameraController?.takePicture();
        if (image != null) {
          final imageBytes = await File(image.path).readAsBytes();
          await _sendImageToBackend(imageBytes);
        }
      } catch (e) {
        print('Error capturing image: $e');
      }
    } else {
      print("Camera is not initialized");
    }
  }

  Future<void> _sendImageToBackend(Uint8List imageBytes) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('http://192.168.1.7:8000/api/ocr/'),
      );

      request.files.add(http.MultipartFile.fromBytes(
        'image',
        imageBytes,
        filename: 'image.jpg',
        contentType: MediaType('image', 'jpeg'),
      ));

      print('Sending request to OCR API');
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      print('OCR API Response: $responseBody');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(responseBody);
        setState(() {
          _ocrText = responseData['text'];
        });
        // Optionally, you could call TTS function here.
        // await _sendTextToTTS(_ocrText);
      } else {
        setState(() {
          _ocrText = 'Failed to get text from image';
        });
      }
    } catch (e) {
      setState(() {
        _ocrText = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('VisionAid')),
      body: Column(
        children: [
          const SizedBox(height: 30,),
          Center(
            child: SizedBox(
              height: 400,
              child: _cameraController == null
                  ? Center(child: CircularProgressIndicator())
                  : _cameraController!.value.isInitialized
                      ? CameraPreview(_cameraController!)
                      : Center(child: Text('Camera not initialized', style: TextStyle(color: Colors.white))),
            ),
          ),
          SizedBox(height: 20,),
          ElevatedButton(
            onPressed: _captureImage,
            child: Text('Capture Image'),
          ),
          SizedBox(height: 10,),
          const Expanded(
            child: Padding(
              padding: EdgeInsets.all(8.0),
              child: SingleChildScrollView(
                child: Text(
                  // _ocrText,
                  'Blue box with "Hangyodon" written at the top',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }
}
