import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:flutter/foundation.dart';

class BarcodeService {
  final MobileScannerController _controller = MobileScannerController();
  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  Future<String?> scanImage(String path) async {
    try {
      final BarcodeCapture? capture = await _controller.analyzeImage(path);
      if (capture != null && capture.barcodes.isNotEmpty) {
        return capture.barcodes.first.displayValue;
      }
    } catch (e) {
      debugPrint('Error scanning image for barcode: $e');
    }
    return null;
  }

  Future<String?> extractTextFromImage(String path) async {
    try {
      final inputImage = InputImage.fromFilePath(path);
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
      return recognizedText.text;
    } catch (e) {
      debugPrint('Error extracting text from image: $e');
      return null;
    }
  }

  void dispose() {
    _controller.dispose();
    _textRecognizer.close();
  }
}
