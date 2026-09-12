import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdfx/pdfx.dart';

import '../../../../core/theme/app_colors.dart';

class CompanyDocumentViewerScreen extends StatefulWidget {
  const CompanyDocumentViewerScreen({
    super.key,
    required this.filePath,
    required this.fileName,
    this.mimeType = '',
  });

  final String filePath;
  final String fileName;
  final String mimeType;

  @override
  State<CompanyDocumentViewerScreen> createState() =>
      _CompanyDocumentViewerScreenState();
}

class _CompanyDocumentViewerScreenState
    extends State<CompanyDocumentViewerScreen> {
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
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              child: Row(
                children: [
                  Material(
                    color: Colors.white,
                    shape: const CircleBorder(),
                    child: InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      customBorder: const CircleBorder(),
                      child: const SizedBox(
                        width: 42,
                        height: 42,
                        child: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 17,
                          color: AppColors.navy,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Document Preview',
                          style: TextStyle(
                            color: AppColors.navy,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.fileName.trim().isEmpty
                              ? 'Company document'
                              : widget.fileName.trim(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.grey,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: AppColors.cardBorder),
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

      return ColoredBox(
        color: const Color(0xFFF1F4F7),
        child: PdfViewPinch(
          controller: controller,
          padding: 10,
          onDocumentError: (error) {
            if (!mounted) return;
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: AppColors.navy,
                  content: Text('Unable to display this PDF: $error'),
                ),
              );
          },
        ),
      );
    }

    if (_isImage) {
      return ColoredBox(
        color: const Color(0xFFF1F4F7),
        child: Center(
          child: InteractiveViewer(
            minScale: .8,
            maxScale: 5,
            boundaryMargin: const EdgeInsets.all(80),
            child: Image.file(
              File(widget.filePath),
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
              errorBuilder: (_, __, ___) => const _ViewerMessage(
                icon: Icons.broken_image_outlined,
                title: 'Unable to display image',
                message: 'This image could not be decoded on the device.',
              ),
            ),
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
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: AppColors.blueBg,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                icon,
                color: AppColors.blue,
                size: 27,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.navy,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.grey,
                fontSize: 12,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
