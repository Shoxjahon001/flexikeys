// Run with:  flutter test test/icon_gen_test.dart
//
// Generates assets/icon/app_icon.png (1024×1024) using Flutter's canvas so
// the output is pixel-perfect and matches the in-app CloudMascot exactly.

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flexikeys/widgets/cloud_mascot.dart';

void main() {
  test('generate app icon PNG', () async {
    const int size = 1024;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Paint the icon at square 1024×1024 (background + cloud)
    const CloudIconPainter(withBackground: true)
        .paint(canvas, const Size(1024, 1024));

    final picture = recorder.endRecording();
    final image = await picture.toImage(size, size);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);

    if (data == null) throw Exception('Failed to encode PNG');

    final file = File('assets/icon/app_icon.png');
    await file.writeAsBytes(data.buffer.asUint8List());

    print('✓ Saved ${file.path}  (${data.lengthInBytes ~/ 1024} KB)');
  });
}
