import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:heroicons/heroicons.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/feedback_service.dart';
import '../../../../core/widgets/custom_popup.dart';

class RateAppDialog extends StatefulWidget {
  const RateAppDialog({super.key});

  @override
  State<RateAppDialog> createState() => _RateAppDialogState();
}

class _RateAppDialogState extends State<RateAppDialog> {
  final FeedbackService _feedbackService = FeedbackService();
  double _rating = 0;
  final TextEditingController _feedbackController = TextEditingController();
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const HeroIcon(HeroIcons.star, size: 48, color: Colors.amber),
            const SizedBox(height: 16),
            Text(
              'ให้คะแนนความพึงพอใจ',
              style: GoogleFonts.prompt(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
             Text(
              'ความคิดเห็นของคุณมีความหมายสำหรับเรา',
              style: GoogleFonts.prompt(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            RatingBar.builder(
              initialRating: 0,
              minRating: 1,
              direction: Axis.horizontal,
              allowHalfRating: false,
              itemCount: 5,
              itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
              itemBuilder: (context, _) => const Icon(
                Icons.star,
                color: Colors.amber,
              ),
              onRatingUpdate: (rating) {
                setState(() => _rating = rating);
              },
            ),
             const SizedBox(height: 24),
             TextField(
               controller: _feedbackController,
               decoration: InputDecoration(
                 hintText: 'ข้อเสนอแนะเพิ่มเติม (ไม่บังคับ)',
                 hintStyle: GoogleFonts.prompt(color: Colors.grey[400]),
                 border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                 filled: true,
                 fillColor: Colors.grey[50]
               ),
               maxLines: 3,
               style: GoogleFonts.prompt(),
             ),
             const SizedBox(height: 24),
             SizedBox(
               width: double.infinity,
               child: ElevatedButton(
                 onPressed: (_rating == 0 || _isSubmitting) ? null : _submit,
                 style: ElevatedButton.styleFrom(
                   backgroundColor: AppColors.primary,
                   padding: const EdgeInsets.symmetric(vertical: 14),
                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                 ),
                 child: _isSubmitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text('ส่งคะแนน', style: GoogleFonts.prompt(fontWeight: FontWeight.bold, color: Colors.white)),
               ),
             )
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    try {
      await _feedbackService.submitRating(
        rating: _rating.toInt(),
        feedback: _feedbackController.text.trim(),
        // Platform/Version usually from package_info_plus, omitted for brevity/simplicity as separate requirement
      );
      if (!mounted) return;
      Navigator.pop(context);
      CustomPopup.showSuccess(context, message: 'ขอบคุณสำหรับคะแนนครับ');
    } catch (e) {
      if (!mounted) return;
       Navigator.pop(context);
       // Fail silently or show error? Usually silent for ratings.
       CustomPopup.showError(context, message: 'ไม่สามารถส่งคะแนนได้ขณะนี้');
    }
  }
}
