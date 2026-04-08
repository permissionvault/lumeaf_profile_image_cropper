part of '../../lumeaf_profile_image_cropper.dart';


base class ImageCropProvider extends ChangeNotifier {
  ImageCropProvider();

  File? sourceFile;
  ui.Image? _uiImage;

  ui.Image? get uiImage => _uiImage;

  double scale = 1.0;
  Offset offset = Offset.zero;

  double cropRadius = 0;
  Offset cropCenter = Offset.zero;

  Offset _dragStart = Offset.zero;
  Offset _offsetAtDragStart = Offset.zero;
  double _scaleAtGestureStart = 1.0;

  bool isLoading = false;
  bool isCropping = false;
  bool _layoutReady = false;
  bool _imageReady = false;

  Future<void> loadImage(File file) async {
    isLoading = true;
    notifyListeners();

    sourceFile = file;
    final bytes = await file.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    _uiImage = frame.image;

    _imageReady = true;
    _tryInit();
  }

  void initLayout({required Offset center, required double radius}) {
    cropCenter = center;
    cropRadius = radius;
    _layoutReady = true;
    _tryInit();
  }

  void _tryInit() {
    if (!_imageReady || !_layoutReady) return;

    final imgW = _uiImage!.width.toDouble();
    final imgH = _uiImage!.height.toDouble();

    final scaleW = (cropRadius * 2) / imgW;
    final scaleH = (cropRadius * 2) / imgH;
    scale = max(scaleW, scaleH);

    offset = cropCenter;

    isLoading = false;
    notifyListeners();
  }

  double get minScale {
    if (_uiImage == null || cropRadius == 0) return 1.0;
    final imgW = _uiImage!.width.toDouble();
    final imgH = _uiImage!.height.toDouble();
    final minDim = min(imgW, imgH);
    //modify this value to control how user can zoom out of image
    return ((cropRadius * 2) / minDim) * 0.9;
  }

  double get maxScale => minScale * 4.0;

  void onScaleStart(ScaleStartDetails details) {
    _dragStart = details.focalPoint;
    _offsetAtDragStart = offset;
    _scaleAtGestureStart = scale;
  }

  bool _hasMinHapticTriggered = false;
  bool _hasMaxHapticTriggered = false;

  void onScaleUpdate(ScaleUpdateDetails details) {
    if (details.pointerCount >= 2) {
      final newScale = (_scaleAtGestureStart * details.scale)
          .clamp(minScale, maxScale);

      if (newScale == minScale) {
        if (!_hasMinHapticTriggered) {
          HapticFeedback.mediumImpact();
          _hasMinHapticTriggered = true;
        }
      } else {
        _hasMinHapticTriggered = false;
      }

      if (newScale == maxScale) {
        if (!_hasMaxHapticTriggered) {
          HapticFeedback.mediumImpact();
          _hasMaxHapticTriggered = true;
        }
      } else {
        _hasMaxHapticTriggered = false;
      }

      scale = newScale;
    }

    final delta = details.focalPoint - _dragStart;
    offset = _offsetAtDragStart + delta;

    _clampOffset();
    notifyListeners();
  }

  void onScaleEnd(ScaleEndDetails details) {
    _clampOffset();
    notifyListeners();
  }

  void onSliderZoom(double value) {
    final newScale = value.clamp(minScale, maxScale);

    if (newScale == minScale) {
      if (!_hasMinHapticTriggered) {
        HapticFeedback.selectionClick();
        _hasMinHapticTriggered = true;
      }
    } else {
      _hasMinHapticTriggered = false;
    }

    if (newScale == maxScale) {
      if (!_hasMaxHapticTriggered) {
        HapticFeedback.selectionClick();
        _hasMaxHapticTriggered = true;
      }
    } else {
      _hasMaxHapticTriggered = false;
    }

    scale = newScale;
    _clampOffset();
    notifyListeners();
  }

  double get sliderValue => scale.clamp(minScale, maxScale);

  void _clampOffset() {
    if (_uiImage == null || cropRadius == 0) return;

    final imgW = _uiImage!.width * scale;
    final imgH = _uiImage!.height * scale;

    final imgLeft = offset.dx - imgW / 2;
    final imgRight = offset.dx + imgW / 2;
    final imgTop = offset.dy - imgH / 2;
    final imgBottom = offset.dy + imgH / 2;

    final circleLeft = cropCenter.dx - cropRadius;
    final circleRight = cropCenter.dx + cropRadius;
    final circleTop = cropCenter.dy - cropRadius;
    final circleBottom = cropCenter.dy + cropRadius;

    //restrict user movement on crop edges
    final allowedOverflow = cropRadius * 0.2;

    double dx = offset.dx;
    double dy = offset.dy;

    // LEFT boundary
    if (imgLeft > circleLeft + allowedOverflow) {
      dx -= (imgLeft - (circleLeft + allowedOverflow));
    }

    // RIGHT boundary
    if (imgRight < circleRight - allowedOverflow) {
      dx += ((circleRight - allowedOverflow) - imgRight);
    }

    // TOP boundary
    if (imgTop > circleTop + allowedOverflow) {
      dy -= (imgTop - (circleTop + allowedOverflow));
    }

    // BOTTOM boundary
    if (imgBottom < circleBottom - allowedOverflow) {
      dy += ((circleBottom - allowedOverflow) - imgBottom);
    }

    offset = Offset(dx, dy);
  }

  Future<File?> cropImage() async {
    if (_uiImage == null || sourceFile == null) return null;

    isCropping = true;
    notifyListeners();

    try {
      final imgW = _uiImage!.width.toDouble();
      final imgH = _uiImage!.height.toDouble();

      final drawLeft = offset.dx - (imgW * scale) / 2;
      final drawTop = offset.dy - (imgH * scale) / 2;

      final circleLeft = cropCenter.dx - cropRadius;
      final circleTop = cropCenter.dy - cropRadius;
      final diameter = cropRadius * 2;

      const outputSize = 512.0;

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      //  Fill with black background first (this becomes visible in out-of-bounds areas)
      canvas.drawRect(
        Rect.fromLTWH(0, 0, outputSize, outputSize),
        Paint()..color = Colors.black,
      );

      // Calculate where the image sits relative to the crop circle
      // Convert from screen coords to output coords
      final scaleToOutput = outputSize / diameter;

      final imgLeftInCircle = drawLeft - circleLeft;
      final imgTopInCircle = drawTop - circleTop;

      final dstLeft = imgLeftInCircle * scaleToOutput;
      final dstTop = imgTopInCircle * scaleToOutput;
      final dstW = imgW * scale * scaleToOutput;
      final dstH = imgH * scale * scaleToOutput;

      final dstRect = Rect.fromLTWH(dstLeft, dstTop, dstW, dstH);
      final srcRect = Rect.fromLTWH(0, 0, imgW, imgH);

      // Black background shows where image doesn't reach
      canvas.drawImageRect(
        _uiImage!,
        srcRect,
        dstRect,
        Paint()..filterQuality = FilterQuality.high,
      );

      final picture = recorder.endRecording();
      final renderedImage = await picture.toImage(
        outputSize.toInt(),
        outputSize.toInt(),
      );

      final byteData = await renderedImage.toByteData(
        format: ui.ImageByteFormat.png,
      );
      if (byteData == null) return null;

      final tempDir = Directory.systemTemp;
      final file = File(
        '${tempDir.path}/cropped_${DateTime.now().microsecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(byteData.buffer.asUint8List());

      return file;
    } catch (e) {
      debugPrint('Crop error: $e');
      return null;
    } finally {
      isCropping = false;
      notifyListeners();
    }
  }


  @override
  void dispose() {
    _uiImage?.dispose();
    super.dispose();
  }
}