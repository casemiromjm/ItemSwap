// image_handler.dart
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;

Future<void> pickImage(Function(String) onImagePicked) async {
  if (kIsWeb) {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );

    if (result != null) {
      final file = result.files.single;
      final compressedImageBase64 = await _compressImageFile(file.bytes!);
      onImagePicked(compressedImageBase64); // Callback with the image data
    }
  } else {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      final compressedImageBase64 = await _compressImageFile(bytes);
      onImagePicked(compressedImageBase64); // Callback with the image data
    }
  }
}

Future<String> _compressImageFile(
  Uint8List imageBytes, {
  int maxWidth = 200,
  int maxHeight = 200,
  int quality = 30,
}) async {
  img.Image? image = img.decodeImage(imageBytes);

  if (image != null) {
    img.Image resizedImage = img.copyResize(
      image,
      width: maxWidth,
      height: maxHeight,
    );
    List<int> compressedBytes = img.encodeJpg(resizedImage, quality: quality);
    return base64Encode(compressedBytes);
  } else {
    throw Exception('Failed to compress image');
  }
}