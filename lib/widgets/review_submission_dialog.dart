import 'package:flutter/material.dart';
import '../models/review_models.dart';
import '../services/review_service.dart';

/// Dialog for submitting a review and rating
class ReviewSubmissionDialog extends StatefulWidget {
  final String bookingId;
  final String reviewerId;
  final String reviewerName;
  final String? reviewerPhotoUrl;
  final String revieweeId;
  final String revieweeName;
  final ReviewType reviewType;
  final VoidCallback? onReviewSubmitted;

  const ReviewSubmissionDialog({
    Key? key,
    required this.bookingId,
    required this.reviewerId,
    required this.reviewerName,
    this.reviewerPhotoUrl,
    required this.revieweeId,
    required this.revieweeName,
    required this.reviewType,
    this.onReviewSubmitted,
  }) : super(key: key);

  @override
  State<ReviewSubmissionDialog> createState() => _ReviewSubmissionDialogState();

  /// Show the review submission dialog
  static Future<bool?> show(
    BuildContext context, {
    required String bookingId,
    required String reviewerId,
    required String reviewerName,
    String? reviewerPhotoUrl,
    required String revieweeId,
    required String revieweeName,
    required ReviewType reviewType,
    VoidCallback? onReviewSubmitted,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ReviewSubmissionDialog(
        bookingId: bookingId,
        reviewerId: reviewerId,
        reviewerName: reviewerName,
        reviewerPhotoUrl: reviewerPhotoUrl,
        revieweeId: revieweeId,
        revieweeName: revieweeName,
        reviewType: reviewType,
        onReviewSubmitted: onReviewSubmitted,
      ),
    );
  }
}

class _ReviewSubmissionDialogState extends State<ReviewSubmissionDialog> {
  final ReviewService _reviewService = ReviewService();
  final TextEditingController _reviewTextController = TextEditingController();
  
  int _selectedRating = 0;
  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _reviewTextController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (_selectedRating == 0) {
      setState(() {
        _error = 'Please select a rating';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      if (widget.reviewType == ReviewType.customerToProfessional) {
        await _reviewService.submitCustomerReview(
          bookingId: widget.bookingId,
          customerId: widget.reviewerId,
          customerName: widget.reviewerName,
          customerPhotoUrl: widget.reviewerPhotoUrl,
          professionalId: widget.revieweeId,
          professionalName: widget.revieweeName,
          rating: _selectedRating,
          reviewText: _reviewTextController.text.trim().isNotEmpty 
              ? _reviewTextController.text.trim() 
              : null,
        );
      } else {
        await _reviewService.submitProfessionalReview(
          bookingId: widget.bookingId,
          professionalId: widget.reviewerId,
          professionalName: widget.reviewerName,
          professionalPhotoUrl: widget.reviewerPhotoUrl,
          customerId: widget.revieweeId,
          customerName: widget.revieweeName,
          rating: _selectedRating,
          reviewText: _reviewTextController.text.trim().isNotEmpty 
              ? _reviewTextController.text.trim() 
              : null,
        );
      }

      if (mounted) {
        Navigator.of(context).pop(true);
        widget.onReviewSubmitted?.call();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Review submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          Icon(
            Icons.star_rate,
            color: Colors.amber[600],
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Rate ${widget.revieweeName}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Rating stars
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedRating = index + 1;
                        _error = null;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        index < _selectedRating ? Icons.star : Icons.star_border,
                        size: 40,
                        color: index < _selectedRating ? Colors.amber[600] : Colors.grey[400],
                      ),
                    ),
                  );
                }),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Rating description
            Center(
              child: Text(
                _getRatingDescription(_selectedRating),
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Review text field
            Text(
              'Write a review (optional)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _reviewTextController,
              maxLines: 4,
              maxLength: 500,
              decoration: InputDecoration(
                hintText: 'Share your experience...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Theme.of(context).primaryColor),
                ),
              ),
            ),
            
            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red[600], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: TextStyle(color: Colors.red[700]),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(false),
          child: const Text(
            'Cancel',
            style: TextStyle(fontSize: 16),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submitReview,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text(
                  'Submit Review',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
        ),
      ],
    );
  }

  String _getRatingDescription(int rating) {
    switch (rating) {
      case 1:
        return 'Poor';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Very Good';
      case 5:
        return 'Excellent';
      default:
        return 'Tap a star to rate';
    }
  }
}
