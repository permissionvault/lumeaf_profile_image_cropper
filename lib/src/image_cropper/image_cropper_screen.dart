//image_cropper_screen.dart
part of '../../lumeaf_profile_image_cropper.dart';


class ImageCropScreen extends StatelessWidget {
  const ImageCropScreen({super.key, required this.sourceFile});

  final File sourceFile;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(create: (_) => ImageCropProvider()..loadImage(sourceFile), child: _CropView());
  }
}

class _CropView extends StatelessWidget {
  const _CropView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
        body: _CropArea()
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions();

  @override
  Widget build(BuildContext context) {
    final provider = context.read<ImageCropProvider>();
    final isCropping = context.select<ImageCropProvider, bool>((value) => value.isCropping);
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisAlignment: .spaceBetween,
        children: [
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
            },
      child: Text(
      'Cancel',
      style: theme.textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w500,
        color: Colors.white,
      ),
    ),
          ),
          TextButton(
            onPressed: isCropping
                ? null
                : () async {
              final file = await provider.cropImage();
                    if (context.mounted) {
                      Navigator.of(context).pop(file);
                    }
                  },
            child: isCropping
                ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator.adaptive())
                : Text('Done', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700,color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _CropArea extends StatefulWidget {
  const _CropArea();

  @override
  State<_CropArea> createState() => _CropAreaState();
}

class _CropAreaState extends State<_CropArea> {
  bool _layoutInitialized = false;
  bool showGuide = true;

  @override
  Widget build(BuildContext context) {
    final provider = context.read<ImageCropProvider>();
    final isLoading = context.select<ImageCropProvider, bool>((value) => value.isLoading);
    final uiImage = context.select<ImageCropProvider, ui.Image?>((value) => value.uiImage);
    final offSet = context.select<ImageCropProvider, Offset>((value) => value.offset);
    final scale = context.select<ImageCropProvider, double>((value) => value.scale);
    return LayoutBuilder(
      builder: (context, constraints) {
        final center = Offset(constraints.maxWidth / 2, constraints.maxHeight / 2);

        if (!_layoutInitialized && constraints.maxWidth > 0) {
          _layoutInitialized = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              context.read<ImageCropProvider>().initLayout(center: center, radius: 120);
            }
          });
        }

        if (isLoading || uiImage == null) {
          return const Center(child: CircularProgressIndicator.adaptive());
        }
        final theme = Theme.of(context);

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onScaleStart: provider.onScaleStart,
          onScaleUpdate: provider.onScaleUpdate,
          onScaleEnd: provider.onScaleEnd,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(
                painter: _ImagePainter(image: uiImage, offset: offSet, scale: scale),
              ),
              ClipPath(
                clipper: _InverseCircleClipper(center: center, radius: MediaQuery.sizeOf(context).width*.37),
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                  child: Container(color: Colors.black.withValues(alpha: 0.1)),
                ),
              ),
              CustomPaint(
                painter: _CropRingPainter(center: center, radius: MediaQuery.sizeOf(context).width*.37, color: theme.colorScheme.primary),
              ),
              Padding(
                padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 12),
                child: Align(
                  alignment: .topCenter,
                  child: Text(
                    "Move and Scale",
                    style: theme.textTheme.bodyLarge?.copyWith(color: Colors.white),
                  ),
                ),
              ),

              Positioned(bottom: MediaQuery.of(context).padding.bottom + 12, left: 0, right: 0, child: _Actions()),
            ],
          ),
        );
      },
    );
  }
}

class _ImagePainter extends CustomPainter {
  const _ImagePainter({required this.image, required this.offset, required this.scale});

  final ui.Image image;
  final Offset offset;
  final double scale;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height));

    final w = image.width * scale;
    final h = image.height * scale;
    final dest = Rect.fromLTWH(offset.dx - w / 2, offset.dy - h / 2, w, h);
    final src = Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
    canvas.drawImageRect(image, src, dest, Paint()..filterQuality = FilterQuality.high);
  }

  @override
  bool shouldRepaint(_ImagePainter old) => old.offset != offset || old.scale != scale || old.image != image;
}

class _CropRingPainter extends CustomPainter {
  const _CropRingPainter({required this.center, required this.radius, required this.color});

  final Offset center;
  final double radius;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_CropRingPainter old) => old.center != center || old.radius != radius;
}

class _InverseCircleClipper extends CustomClipper<Path> {
  const _InverseCircleClipper({required this.center, required this.radius});

  final Offset center;
  final double radius;

  @override
  Path getClip(Size size) => Path()
    ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
    ..addOval(Rect.fromCircle(center: center, radius: radius))
    ..fillType = PathFillType.evenOdd;

  @override
  bool shouldReclip(_InverseCircleClipper old) => old.center != center || old.radius != radius;
}
