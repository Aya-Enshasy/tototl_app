import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_colors.dart';
import 'operation_store.dart';

class DeliverablesScreen extends StatefulWidget {
  const DeliverablesScreen({super.key, required this.mission});
  final Mission mission;
  @override
  State<DeliverablesScreen> createState() => _DeliverablesScreenState();
}

class _DeliverablesScreenState extends State<DeliverablesScreen> {
  final _picker = ImagePicker();
  final _note = TextEditingController();
  final List<File> _photos = [];
  PlatformFile? _report;
  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (image != null && mounted) setState(() => _photos.add(File(image.path)));
  }

  Future<void> _pickReport() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null && mounted)
      setState(() => _report = result.files.single);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.bg,
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
              ),
              const Expanded(
                child: Text(
                  'Deliverables',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.navy,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            widget.mission.application.job.title,
            style: const TextStyle(
              color: AppColors.navy,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Add the agreed site photos, files, and final report before submission.',
            style: TextStyle(color: AppColors.grey, fontSize: 13.5),
          ),
          const SizedBox(height: 22),
          _Section(
            title: 'Mission photos & video',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_photos.isEmpty)
                  const Text(
                    'No files added yet.',
                    style: TextStyle(color: AppColors.grey, fontSize: 12.5),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _photos
                        .map(
                          (file) => ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.file(
                              file,
                              width: 78,
                              height: 78,
                              fit: BoxFit.cover,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _pickPhoto,
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: const Text('Add photos or video'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _Section(
            title: 'Final report',
            child: _report == null
                ? OutlinedButton.icon(
                    onPressed: _pickReport,
                    icon: const Icon(Icons.upload_file_outlined),
                    label: const Text('Attach PDF report'),
                  )
                : Row(
                    children: [
                      const Icon(
                        Icons.picture_as_pdf_rounded,
                        color: AppColors.red,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _report!.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.navy,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => setState(() => _report = null),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 14),
          _Section(
            title: 'Completion note',
            child: TextField(
              controller: _note,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText:
                    'Summarize findings, completed inspections, and anything the company should know.',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: () {
                if (_photos.isEmpty && _report == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Add at least one photo or the final report before submitting.',
                      ),
                    ),
                  );
                  return;
                }
                OperationStore.instance.submitWork(widget.mission);
                Navigator.of(context).pop();
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: const Text(
                'Submit Deliverables',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(17),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppColors.cardBorder),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.navy,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 13),
        child,
      ],
    ),
  );
}
