import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../constants/theme_constants.dart';
import '../../../../services/localization_service.dart';

/// Area 10 — scan a barcode with the phone camera.
///
/// Pops with the decoded string on the first successful read. Used at POS,
/// goods receipt, stock counts and dispatch instead of typing a code.
class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({this.title, super.key});

  final String? title;

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool _handled = false;
  String? _torchError;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) {
      return;
    }
    final String? code = capture.barcodes
        .map((Barcode b) => b.rawValue)
        .firstWhere((String? v) => v != null && v.isNotEmpty,
            orElse: () => null);
    if (code == null) {
      return;
    }
    _handled = true;
    Navigator.of(context).pop(code);
  }

  @override
  Widget build(BuildContext context) {
    final LocalizationService loc = LocalizationService.instance;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          widget.title ?? loc.translate('scan_barcode'),
          style: const TextStyle(color: Colors.white),
        ),
        actions: <Widget>[
          IconButton(
            icon: ValueListenableBuilder<MobileScannerState>(
              valueListenable: _controller,
              builder: (_, MobileScannerState state, __) => Icon(
                state.torchState == TorchState.on
                    ? Icons.flash_on
                    : Icons.flash_off,
                color: Colors.white,
              ),
            ),
            onPressed: () async {
              try {
                await _controller.toggleTorch();
              } on Exception {
                setState(
                    () => _torchError = loc.translate('torch_unavailable'));
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.cameraswitch, color: Colors.white),
            onPressed: _controller.switchCamera,
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            // Without this, a real camera failure (permission denied, no
            // camera on this device/emulator, hardware in use elsewhere)
            // renders as a silent black screen with no clue why.
            errorBuilder: (BuildContext context, MobileScannerException error) =>
                _ScannerErrorView(error: error),
            placeholderBuilder: (BuildContext context) => const ColoredBox(
              color: Colors.black,
              child: Center(
                child: CircularProgressIndicator(color: Colors.white70),
              ),
            ),
          ),
          _ScanFrameOverlay(),
          Positioned(
            left: 0,
            right: 0,
            bottom: 24.h,
            child: Column(
              children: <Widget>[
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 24.w),
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    _torchError ?? loc.translate('align_barcode_in_frame'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                SizedBox(height: 12.h),
                TextButton(
                  onPressed: () => _promptManualEntry(context),
                  child: Text(
                    loc.translate('enter_code_manually'),
                    style: const TextStyle(
                      color: ThemeConstants.primaryCyan,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _promptManualEntry(BuildContext context) async {
    final LocalizationService loc = LocalizationService.instance;
    // No TextEditingController here on purpose: disposing one right after
    // showDialog resolves races the dialog's still-animating exit
    // transition reading it - "used after being disposed", then cascading
    // Overlay/GlobalKey errors. Plain onChanged has nothing to dispose.
    String draft = '';

    final String? code = await showDialog<String>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        backgroundColor: ThemeConstants.primaryBlue,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Text(loc.translate('enter_code_manually'),
            style: ThemeConstants.headingStyle),
        content: TextField(
          autofocus: true,
          style: ThemeConstants.bodyStyle,
          decoration:
              ThemeConstants.invInputDecoration(loc.translate('barcode')),
          onChanged: (String v) => draft = v,
          onSubmitted: (String v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(loc.translate('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, draft.trim()),
            child: Text(loc.translate('ok')),
          ),
        ],
      ),
    );

    if (code != null && code.isNotEmpty && mounted) {
      Navigator.of(context).pop(code);
    }
  }
}

/// A simple square viewfinder frame drawn over the camera preview.
class _ScanFrameOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: Center(
          child: Container(
            width: 240.w,
            height: 240.w,
            decoration: BoxDecoration(
              border: Border.all(color: ThemeConstants.primaryOrange, width: 3),
              borderRadius: BorderRadius.circular(20.r),
            ),
          ),
        ),
      );
}

/// Shown in place of the camera preview when it genuinely fails to start -
/// permission denied, no camera on this device, or the camera is busy in
/// another app. Without this the screen would just be a silent black
/// rectangle, indistinguishable from "still loading".
class _ScannerErrorView extends StatelessWidget {
  const _ScannerErrorView({required this.error});

  final MobileScannerException error;

  String _messageFor(LocalizationService loc) => switch (error.errorCode) {
        MobileScannerErrorCode.permissionDenied =>
          loc.translate('camera_permission_denied'),
        MobileScannerErrorCode.unsupported =>
          loc.translate('camera_unsupported_device'),
        _ => loc.translate('camera_unavailable'),
      };

  @override
  Widget build(BuildContext context) {
    final LocalizationService loc = LocalizationService.instance;

    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 32.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(Icons.videocam_off_outlined, color: Colors.white54, size: 48.sp),
              SizedBox(height: 16.h),
              Text(
                _messageFor(loc),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white),
              ),
              SizedBox(height: 8.h),
              Text(
                error.errorDetails?.message ?? error.errorCode.name,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Opens the scanner and returns the decoded string, or null if cancelled.
/// The one call every screen needing a scan should use.
Future<String?> scanBarcode(BuildContext context, {String? title}) =>
    Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        builder: (_) => BarcodeScannerScreen(title: title),
        fullscreenDialog: true,
      ),
    );
