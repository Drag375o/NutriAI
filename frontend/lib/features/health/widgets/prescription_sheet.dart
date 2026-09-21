import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/colors.dart';
import '../../../app/theme/spacing.dart';
import '../../../app/theme/typography.dart';
import '../data/ocr_repository.dart';
import '../state/ocr_controller.dart';

/// Reads a prescription or medical letter and helps fill in conditions.
///
/// Three steps: choose an image, review what was read, write the
/// conditions. The review step is not optional — OCR misreads drug names
/// and dosages, and acting on unverified text would be worse than typing
/// it by hand.
Future<bool> showPrescriptionSheet(
  BuildContext context, {
  String? currentConditions,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: context.palette.paper,
    isScrollControlled: true,
    builder: (context) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: _PrescriptionForm(currentConditions: currentConditions),
    ),
  );
  return result ?? false;
}

enum _Stage { choose, reading, review }

class _PrescriptionForm extends ConsumerStatefulWidget {
  const _PrescriptionForm({this.currentConditions});

  final String? currentConditions;

  @override
  ConsumerState<_PrescriptionForm> createState() => _PrescriptionFormState();
}

class _PrescriptionFormState extends ConsumerState<_PrescriptionForm> {
  late final TextEditingController _conditions;
  final _extracted = TextEditingController();

  _Stage _stage = _Stage.choose;
  bool _busy = false;
  bool _poor = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _conditions = TextEditingController(text: widget.currentConditions ?? '');
  }

  @override
  void dispose() {
    _conditions.dispose();
    _extracted.dispose();
    super.dispose();
  }


  Future<void> _pick() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      // Downscaled before upload: a full-resolution phone photograph is
      // slower to send and no more accurate to read.
      maxWidth: 2000,
      imageQuality: 88,
    );

    if (picked == null) return;

    final bytes = await picked.readAsBytes();

    setState(() {
      _stage = _Stage.reading;
      _error = null;
    });

    try {
      final result = await ref.read(ocrControllerProvider.notifier).extract(
            bytes: bytes,
            filename: picked.name,
            contentType: _typeFor(picked.name.split('.').last),
          );

      if (!mounted) return;

      _extracted.text = result.text;
      setState(() {
        _stage = _Stage.review;
        _poor = result.likelyPoor;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _stage = _Stage.choose;
        _error = e.toString();
      });
    }
  }


  Future<void> _save() async {
    final entered = _conditions.text.trim();

    setState(() {
      _busy = true;
      _error = null;
    });

    final error =
        await ref.read(ocrControllerProvider.notifier).saveConditions(entered);

    if (!mounted) return;

    if (error != null) {
      setState(() {
        _busy = false;
        _error = error;
      });
      return;
    }

    Navigator.pop(context, true);
  }

  static String _typeFor(String? extension) => switch (extension) {
        'png' => 'image/png',
        'webp' => 'image/webp',
        _ => 'image/jpeg',
      };

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Read a prescription', style: text.headlineMedium),
                const SizedBox(height: AppSpacing.sm),
                // The privacy claim is specific, because a vague one would
                // be worth less than none.
                Text(
                  'The image is read on the machine running NutriAI and is '
                  'not stored or sent anywhere. Only the conditions you '
                  'confirm are saved.',
                  style: text.bodySmall,
                ),
                const SizedBox(height: AppSpacing.xl),

                if (_stage == _Stage.choose) _chooser(context),
                if (_stage == _Stage.reading) _reading(context),
                if (_stage == _Stage.review) _review(context),

                if (_error != null) ...[
                  const SizedBox(height: AppSpacing.lg),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: p.linen,
                      border:
                          Border(left: BorderSide(color: p.brick, width: 2)),
                    ),
                    child: Text(_error!, style: text.bodyMedium),
                  ),
                ],

                const SizedBox(height: AppSpacing.xl),
                Row(
                  children: [
                    TextButton(
                      onPressed:
                          _busy ? null : () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    const Spacer(),
                    if (_stage == _Stage.review)
                      ElevatedButton(
                        onPressed: _busy ? null : _save,
                        child: _busy
                            ? SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: p.onAccent,
                                ),
                              )
                            : const Text('Save conditions'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _chooser(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final available = ref.watch(ocrAvailableProvider);

    return available.when(
      loading: () => const SizedBox(height: 48),
      error: (_, __) => Text(
        'Text extraction is not available right now.',
        style: text.bodyMedium,
      ),
      data: (ok) {
        if (!ok) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: p.linen,
              border: Border(left: BorderSide(color: p.turmeric, width: 2)),
            ),
            child: Text(
              'Text extraction is not set up on this machine. You can still '
              'type your conditions in directly from the Health screen.',
              style: text.bodyMedium,
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            OutlinedButton(
              onPressed: _pick,
              child: const Text('Choose a photograph'),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'A flat, well-lit photograph of printed text reads best. '
              'Handwriting usually does not read well at all.',
              style: text.bodySmall,
            ),
          ],
        );
      },
    );
  }

  Widget _reading(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: LinearProgressIndicator(
            minHeight: 2,
            backgroundColor: p.clay,
            color: p.ember,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('Reading the image…', style: text.bodyLarge),
      ],
    );
  }

  Widget _review(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_poor) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: p.linen,
              border: Border(left: BorderSide(color: p.turmeric, width: 2)),
            ),
            child: Text(
              'That did not read well. Retaking the photograph may be quicker '
              'than correcting it.',
              style: text.bodyMedium,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],

        Text('WHAT WAS READ',
            style: AppTypography.mono(color: p.muted, size: 10.5)),
        const SizedBox(height: AppSpacing.sm),
        // Shown but not editable: correcting it would imply the text is
        // being used, and it is not. Only the conditions field is saved.
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxHeight: 200),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            border: Border.all(color: p.hair),
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
          child: SingleChildScrollView(
            child: SelectableText(
              _extracted.text,
              style: AppTypography.mono(color: p.char, size: 12),
            ),
          ),
        ),

        const SizedBox(height: AppSpacing.xl),
        Text(
          'Which conditions does this mention?',
          style: text.bodyLarge,
        ),
        const SizedBox(height: AppSpacing.xs),
        // Only conditions are kept. Medication is deliberately not stored
        // or reasoned about: that is a question for a prescribing doctor.
        Text(
          'Write them in your own words. Medication is not saved, and '
          'NutriAI will not advise on it.',
          style: text.bodySmall,
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _conditions,
          autofocus: true,
          minLines: 1,
          maxLines: 3,
          keyboardType: TextInputType.multiline,
          textInputAction: TextInputAction.newline,
          style: text.bodyLarge,
          decoration: const InputDecoration(
            hintText: 'e.g. Type 2 diabetes, high blood pressure',
            isDense: true,
          ),
        ),

        const SizedBox(height: AppSpacing.md),
        TextButton(
          onPressed: () => setState(() {
            _stage = _Stage.choose;
            _poor = false;
          }),
          child: const Text('Try another image'),
        ),
      ],
    );
  }
}