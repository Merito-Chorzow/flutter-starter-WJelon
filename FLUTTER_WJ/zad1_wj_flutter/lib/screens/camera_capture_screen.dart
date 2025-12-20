import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class CameraCaptureResult {
  final XFile file;
  CameraCaptureResult(this.file);
}

class CameraCaptureScreen extends StatefulWidget {
  const CameraCaptureScreen({super.key});

  @override
  State<CameraCaptureScreen> createState() => _CameraCaptureScreenState();
}

class _CameraCaptureScreenState extends State<CameraCaptureScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  Future<void>? _initFuture;

  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _disposeCamera();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final ctrl = _controller;
    if (ctrl == null) return;

    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      _disposeCamera();
    } else if (state == AppLifecycleState.resumed) {
      _startCamera();
    }
  }

  Future<void> _disposeCamera() async {
    final ctrl = _controller;
    _controller = null;
    _initFuture = null;
    if (ctrl != null) {
      try {
        await ctrl.dispose();
      } catch (_) {}
    }
  }

  Future<void> _startCamera() async {
    setState(() {
      _error = null;
      _initFuture = null;
    });

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _error = "Brak dostepnej kamery na urzadzeniu/emulatorze.");
        return;
      }

      final selected = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      final ctrl = CameraController(
        selected,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      final init = ctrl.initialize();
      setState(() {
        _controller = ctrl;
        _initFuture = init;
      });

      await init;
      if (!mounted) return;
      setState(() {});
    } catch (e) {
      setState(() => _error = "Blad uruchomienia kamery: $e");
    }
  }

  Future<void> _capture() async {
    if (_busy) return;

    final ctrl = _controller;
    if (ctrl == null) return;

    setState(() => _busy = true);

    try {
      await (_initFuture ?? Future.value());
      if (!ctrl.value.isInitialized) {
        throw Exception("Kamera nie jest gotowa.");
      }

      final file = await ctrl.takePicture();

      if (!mounted) return;
      Navigator.pop(context, CameraCaptureResult(file));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Nie udalo sie zrobic zdjecia: $e")),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    Widget body;

    if (_error != null) {
      body = Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 44, color: scheme.onSurfaceVariant),
              const SizedBox(height: 10),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _startCamera,
                icon: const Icon(Icons.refresh),
                label: const Text("Sprobuj ponownie"),
              ),
            ],
          ),
        ),
      );
    } else if (_controller == null || _initFuture == null) {
      body = const Center(child: CircularProgressIndicator());
    } else {
      body = FutureBuilder<void>(
        future: _initFuture,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final ctrl = _controller!;
          if (!ctrl.value.isInitialized) {
            return const Center(child: Text("Kamera nie gotowa."));
          }

          return SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: ctrl.value.previewSize?.height ?? 1,
                height: ctrl.value.previewSize?.width ?? 1,
                child: CameraPreview(ctrl),
              ),
            ),
          );
        },
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(child: body),

            // Gorny pasek z back
            Positioned(
              top: 12,
              left: 12,
              child: CircleAvatar(
                backgroundColor: Colors.black.withOpacity(0.45),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),

            // Dolny przycisk na srodku
            Positioned(
              left: 0,
              right: 0,
              bottom: 22,
              child: Center(
                child: GestureDetector(
                  onTap: _busy ? null : _capture,
                  child: Container(
                    width: 78,
                    height: 78,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.15),
                      border: Border.all(color: Colors.white.withOpacity(0.9), width: 3),
                    ),
                    child: _busy
                        ? const Padding(
                            padding: EdgeInsets.all(22),
                            child: CircularProgressIndicator(strokeWidth: 3),
                          )
                        : Center(
                            child: Container(
                              width: 56,
                              height: 56,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                              ),
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
