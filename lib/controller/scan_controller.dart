import 'package:camera/camera.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_tflite/flutter_tflite.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:developer';
import 'package:flutter/services.dart' show rootBundle;
import 'package:vibration/vibration.dart';

class ScanController extends GetxController {
  late CameraController cameraController;
  late List<CameraDescription> cameras;
  late stt.SpeechToText speech;
  late FlutterTts flutterTts;

  var isCameraInitialized = false.obs;
  var cameraCount = 0;
  var x = 0.0, y = 0.0, w = 0.0, h = 0.0;
  var label = "";
  var detectedObjects = <Map<String, dynamic>>[].obs;
  var recognizedWord = "".obs;
  var recognizedWords = "".obs;
  var labels = <String>[].obs;

  var isMicrophoneActive = false.obs;

  final String modelFilePath = 'assets/efficientdet-tflite-lite0-detection.tflite';
  final String labelsFilePath = 'assets/efficientdet-tflite-lite0-detection.txt';
  void clearTarget() {
    recognizedWord.value = "";
  }
  @override
  void onInit() {
    super.onInit();
    initCamera();
    initTFLite();
    initSpeechToText();
    initTextToSpeech();
    loadLabels();

  }

  @override
  void dispose() {
    if (cameraController.value.isStreamingImages) {
      cameraController.stopImageStream();
    }
    cameraController.dispose();
    Tflite.close();
    super.dispose();
  }

  initCamera() async {
    if (await Permission.camera.request().isGranted) {
      cameras = await availableCameras();

      cameraController = CameraController(
        cameras[0],
        ResolutionPreset.max,
        imageFormatGroup: ImageFormatGroup.bgra8888,
      );
      await cameraController.initialize().then((value) {
        cameraController.startImageStream((image) {
          cameraCount++;
          if (cameraCount % 10 == 0) {
            cameraCount = 0;
            objectDetector(image);
          }
          update();
        });
      });
      isCameraInitialized(true);
      update();
    } else {
      log("Permission denied");
    }
  }

  initTFLite() async {
    await Tflite.loadModel(
      model: modelFilePath,
      labels: labelsFilePath,
      isAsset: true,
      numThreads: 1,
      useGpuDelegate: false,
    );
  }

  objectDetector(CameraImage image) async {
    var detector = await Tflite.detectObjectOnFrame(
      bytesList: image.planes.map((e) => e.bytes).toList(),
      model: "SSDMobileNet",
      asynch: true,
      imageHeight: image.height,
      imageWidth: image.width,
      imageMean: 127.5,
      imageStd: 127.5,
      rotation: 90,
      threshold: 0.4,
    );

    detectedObjects.clear();
    if (detector != null && detector.isNotEmpty) {
      for (var detectedObject in detector) {
        if (detectedObject['confidenceInClass'] * 100 > 45) {
          detectedObjects.add({
            'label': detectedObject['detectedClass'].toString(),
            'h': detectedObject['rect']['h'],
            'w': detectedObject['rect']['w'],
            'x': detectedObject['rect']['x'],
            'y': detectedObject['rect']['y'],
          });
        }
      }
      update();
      checkForMatchingBbox();
    }
  }

  initSpeechToText() {
    speech = stt.SpeechToText();
    speech.initialize(onStatus: (status) {
      if (status == 'done') {
      }
    });
  }

  initTextToSpeech() {
    flutterTts = FlutterTts();
  }


  startListening() {
    speech.listen(onResult: (result) {
      String recognizedText = result.recognizedWords;
      recognizedWords.value = recognizedText;
      String lastWord = recognizedText.split(" ").last.toLowerCase();
      if (labels.contains(lastWord)) {
        recognizedWord.value = lastWord;
        flutterTts.speak(lastWord);
        checkForMatchingBbox();
      }
    });
    isMicrophoneActive.value = true;
  }

  stopListening() {
    speech.stop();
    isMicrophoneActive.value = false;
  }

  // Toggle microphone on/off
  toggleMicrophone() {
    if (isMicrophoneActive.value) {
      stopListening();
    } else {
      startListening();
    }
  }

  loadLabels() async {
    final data = await rootBundle.loadString(labelsFilePath);
    final lines = data.split('\n');
    labels.addAll(lines.map((line) => line.toLowerCase().trim()));
  }

  checkForMatchingBbox() {
    for (var detectedObject in detectedObjects) {
      if (detectedObject['label'] == recognizedWord.value) {
        Vibration.vibrate();
        break;
      }
    }
  }
}
