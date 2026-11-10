import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

Future<String> readProductPhoto(String path) async {
  final input = InputImage.fromFilePath(path);
  final parts = <String>[];

  final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  try {
    final recognized = await textRecognizer.processImage(input);
    if (recognized.text.trim().isNotEmpty) parts.add(recognized.text);
  } catch (_) {
    // A failed read should still leave the photo labels usable.
  } finally {
    await textRecognizer.close();
  }

  final labeler = ImageLabeler(options: ImageLabelerOptions(confidenceThreshold: 0.6));
  try {
    final labels = await labeler.processImage(input);
    parts.addAll(labels.map((label) => label.label).where((label) => label.trim().isNotEmpty));
  } catch (_) {
    // Labels are optional when the picture has no clear subject.
  } finally {
    await labeler.close();
  }

  return parts.join('\n');
}
