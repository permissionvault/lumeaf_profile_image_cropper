
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:provider/provider.dart';

part 'src/image_cropper/image_cropper_provider.dart';
part 'src/image_cropper/image_cropper_screen.dart';

final class ProfileImageCropper {
  Future<File?> copeImage({
    required BuildContext context,
    required File imageFile,
  }) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ImageCropScreen(sourceFile: imageFile),
      ),
    );

    return result as File?;
  }}
