import 'package:ai_object_detector/controller/scan_controller.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CameraView extends StatelessWidget {
  const CameraView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange[800],
      body: Padding(
        padding: const EdgeInsets.only(top: 100),
        child: GetBuilder<ScanController>(
          init: ScanController(),
          builder: (controller) {
            return controller.isCameraInitialized.value
                ? Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Obx(() => Text(
                    "Command: ${controller.recognizedWords.value}",
                    style: const TextStyle(fontSize: 18, color: Colors.white),
                  )),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Obx(() => Text(
                    "Target: ${controller.recognizedWord.value}",
                    style: const TextStyle(fontSize: 18, color: Colors.white),
                  )),
                ),
                Expanded(
                  child: Stack(
                    children: [
                      Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()..scale(1.0, 1.0, 1.0),
                        child: CameraPreview(controller.cameraController),
                      ),
                      ...controller.detectedObjects.map((detectedObject) {
                        return Positioned(
                          top: detectedObject['y'] * context.height * 0.65,
                          right: (1 - detectedObject['x'] - detectedObject['w']) * context.width,
                          child: Container(
                            width: detectedObject['w'] * context.width,
                            height: detectedObject['h'] * context.height * 0.65,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.green, width: 4.0),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  detectedObject['label'],
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
                Transform.translate(
                  offset: const Offset(0, -20),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange[400],
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () {
                            controller.clearTarget();
                          },
                          child: const Text("Clear Target"),
                        ),
                        Obx(() => ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange[400],
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () {
                            controller.toggleMicrophone();
                          },
                          child: Text(controller.isMicrophoneActive.value
                              ? "Turn Off Microphone"
                              : "Turn On Microphone"),
                        )),
                      ],
                    ),
                  ),
                ),
              ],
            )
                : const Center(
              child: Text(
                "Loading Preview...",
                style: TextStyle(color: Colors.white),
              ),
            );
          },
        ),
      ),
    );
  }
}