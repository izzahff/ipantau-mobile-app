// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

/// Web-only: `<input type="file" accept="image/*">` and read bytes.
Future<Uint8List?> pickImageBytesFromBrowserFileInput() async {
  final input = html.FileUploadInputElement()
    ..accept = 'image/*'
    ..style.visibility = 'hidden';
  html.document.body!.append(input);
  try {
    input.click();
    await input.onChange.first;
    final files = input.files;
    if (files == null || files.isEmpty) return null;
    final file = files[0];
    final reader = html.FileReader();
    final done = Completer<void>();
    reader.onLoadEnd.listen((_) {
      if (!done.isCompleted) done.complete();
    });
    reader.readAsArrayBuffer(file);
    await done.future;
    final result = reader.result;
    if (result is ByteBuffer) return Uint8List.view(result);
    return null;
  } finally {
    input.remove();
  }
}
