import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdfx/pdfx.dart';

const Color _viewerPage = Color(0xFFF5F8FB);
const Color _viewerInk = Color(0xFF071A35);
const Color _viewerMuted = Color(0xFF60748C);
const Color _viewerTeal = Color(0xFF078B98);
const Color _viewerTealSoft = Color(0xFFEAF9FA);
const Color _viewerBorder = Color(0xFFE6ECF1);

class PilotLicenseDocumentViewerScreen extends StatefulWidget {
  const PilotLicenseDocumentViewerScreen({
    super.key,
    required this.filePath,
    required this.fileName,
    this.mimeType = '',
  });

  final String filePath;
  final String fileName;
  final String mimeType;

  @override
  State<PilotLicenseDocumentViewerScreen> createState() =>
      _PilotLicenseDocumentViewerScreenState();
}

class _PilotLicenseDocumentViewerScreenState
    extends State<PilotLicenseDocumentViewerScreen> {
  PdfControllerPinch? _pdfController;
  bool _fileExists = true;

  bool get _isPdf {
    final mime = widget.mimeType.trim().toLowerCase();
    final name = widget.fileName.trim().toLowerCase();
    final path = widget.filePath.trim().toLowerCase();

    return mime == 'application/pdf' ||
        name.endsWith('.pdf') ||
        path.endsWith('.pdf');
  }

  bool get _isImage {
    final mime = widget.mimeType.trim().toLowerCase();
    if (mime.startsWith('image/')) return true;

    final value = '${widget.fileName} ${widget.filePath}'.toLowerCase();
    return value.endsWith('.png') ||
        value.endsWith('.jpg') ||
        value.endsWith('.jpeg') ||
        value.endsWith('.webp');
  }

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    );

    final file = File(widget.filePath);
    _fileExists = file.existsSync();

    if (_fileExists && _isPdf) {
      _pdfController = PdfControllerPinch(
        document: PdfDocument.openFile(widget.filePath),
      );
    }
  }

  @override
  void dispose() {
    _pdfController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _viewerPage,
      body: SafeArea(
        child: Column(
          children: [
            _ViewerHeader(
              fileName: widget.fileName.trim().isEmpty
                  ? 'Document'
                  : widget.fileName.trim(),
              onBack: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 2, 12, 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: _viewerBorder),
                    ),
                    child: _buildViewer(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewer() {
    if (!_fileExists) {
      return const _ViewerMessage(
        icon: Icons.file_download_off_outlined,
        title: 'File unavailable',
        message: 'The downloaded file is no longer available on this device.',
      );
    }

    if (_isPdf) {
      final controller = _pdfController;
      if (controller == null) {
        return const _ViewerMessage(
          icon: Icons.picture_as_pdf_outlined,
          title: 'Unable to preview PDF',
          message: 'The PDF viewer could not be prepared.',
        );
      }

      return Container(
        color: const Color(0xFFF1F4F7),
        child: PdfViewPinch(
          controller: controller,
          padding: 10,
          onDocumentError: (error) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                behavior: SnackBarBehavior.floating,
                backgroundColor: _viewerInk,
                margin: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                content: Text('Unable to display this PDF: $error'),
              ),
            );
          },
        ),
      );
    }

    if (_isImage) {
      return Container(
        color: const Color(0xFFF1F4F7),
        alignment: Alignment.center,
        child: InteractiveViewer(
          minScale: 0.8,
          maxScale: 5,
          boundaryMargin: const EdgeInsets.all(80),
          child: Image.file(
            File(widget.filePath),
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            errorBuilder: (_, __, ___) {
              return const _ViewerMessage(
                icon: Icons.broken_image_outlined,
                title: 'Unable to display image',
                message: 'This image could not be decoded on the device.',
              );
            },
          ),
        ),
      );
    }

    return _ViewerMessage(
      icon: Icons.insert_drive_file_outlined,
      title: 'Preview not supported',
      message: widget.mimeType.trim().isEmpty
          ? 'This file type cannot be previewed inside the app.'
          : 'Files of type ${widget.mimeType.trim()} cannot be previewed inside the app.',
    );
  }
}

class _ViewerHeader extends StatelessWidget {
  const _ViewerHeader({
    required this.fileName,
    required this.onBack,
  });

  final String fileName;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
      child: Row(
        children: [
          Material(
            color: Colors.white,
            shape: const CircleBorder(),
            elevation: 2,
            shadowColor: Colors.black.withOpacity(0.06),
            child: InkWell(
              onTap: onBack,
              customBorder: const CircleBorder(),
              child: const SizedBox(
                width: 40,
                height: 40,
                child: Icon(
                  Icons.arrow_back_rounded,
                  size: 20,
                  color: _viewerInk,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Document Preview',
                  style: TextStyle(
                    color: _viewerInk,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _viewerMuted,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _viewerTealSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.visibility_outlined,
              color: _viewerTeal,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }
}

class _ViewerMessage extends StatelessWidget {
  const _ViewerMessage({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: _viewerTealSoft,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: _viewerTeal, size: 29),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _viewerInk,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _viewerMuted,
                fontSize: 11.5,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
