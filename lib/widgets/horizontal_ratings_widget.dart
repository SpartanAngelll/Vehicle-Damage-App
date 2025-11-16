import 'package:flutter/material.dart';
import '../models/review_models.dart';
import '../services/review_service.dart';
import '../theme/app_theme.dart';
import '../screens/reviews_screen.dart';
import 'profile_avatar.dart';

class HorizontalRatingsWidget extends StatefulWidget {
  final String professionalId;
  final String professionalName;

  const HorizontalRatingsWidget({
    super.key,
    required this.professionalId,
    required this.professionalName,
  });

  @override
  State<HorizontalRatingsWidget> createState() => _HorizontalRatingsWidgetState();
}

class _HorizontalRatingsWidgetState extends State<HorizontalRatingsWidget> {
  final ReviewService _reviewService = ReviewService();
  final ScrollController _reviewsScrollController = ScrollController();
  List<CustomerReview> _reviews = [];
  bool _isLoading = true;
  double _averageRating = 0.0;
  int _totalReviews = 0;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  @override
  void dispose() {
    _reviewsScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadReviews() async {
    try {
      setState(() => _isLoading = true);
      
      // Get reviews for the professional
      final reviews = await _reviewService.getProfessionalReviews(widget.professionalId);
      
      // Get rating statistics
      final ratingStats = await _reviewService.getProfessionalRatingStats(widget.professionalId);
      
      setState(() {
        _reviews = reviews;
        _averageRating = ratingStats.averageRating;
        _totalReviews = ratingStats.totalReviews;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ [HorizontalRatingsWidget] Error loading reviews for ${widget.professionalId}: $e');
      print('❌ [HorizontalRatingsWidget] Error type: ${e.runtimeType}');
      // Set empty state on error
      setState(() {
        _reviews = [];
        _averageRating = 0.0;
        _totalReviews = 0;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: 200,
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_reviews.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.star_outline,
                size: 48,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'No Reviews Yet',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Be the first to review this professional!',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with average rating and total reviews
          Row(
            children: [
              Icon(
                Icons.star,
                color: Colors.black,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                _averageRating.toStringAsFixed(2),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$_totalReviews reviews',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Horizontal scrolling reviews with navigation arrows
          Stack(
            children: [
              SizedBox(
                height: 180,
                child: ListView.builder(
                  controller: _reviewsScrollController,
                  scrollDirection: Axis.horizontal,
                  itemCount: _reviews.length,
                  itemBuilder: (context, index) {
                    return _buildReviewCard(_reviews[index]);
                  },
                ),
              ),
              // Navigation arrows
              if (_reviews.length > 1) ...[
                // Previous arrow
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Material(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(20),
                      child: InkWell(
                        onTap: () {
                          if (_reviewsScrollController.hasClients) {
                            final newOffset = (_reviewsScrollController.offset - 300).clamp(
                              0.0,
                              _reviewsScrollController.position.maxScrollExtent,
                            );
                            _reviewsScrollController.animateTo(
                              newOffset,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          width: 40,
                          height: 40,
                          padding: const EdgeInsets.all(8),
                          child: const Icon(
                            Icons.chevron_left,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Next arrow
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Material(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(20),
                      child: InkWell(
                        onTap: () {
                          if (_reviewsScrollController.hasClients) {
                            final newOffset = (_reviewsScrollController.offset + 300).clamp(
                              0.0,
                              _reviewsScrollController.position.maxScrollExtent,
                            );
                            _reviewsScrollController.animateTo(
                              newOffset,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          width: 40,
                          height: 40,
                          padding: const EdgeInsets.all(8),
                          child: const Icon(
                            Icons.chevron_right,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Show all reviews button
          Center(
            child: Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextButton(
                onPressed: () => _showAllReviews(context),
                child: Text(
                  'Show all reviews',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
  }

  Widget _buildStarRating(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < rating.floor() 
              ? Icons.star 
              : (index < rating ? Icons.star_half : Icons.star_border),
          size: 16,
          color: Colors.amber[600],
        );
      }),
    );
  }

  void _showAllReviews(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ReviewsScreen(
          professionalId: widget.professionalId,
          professionalName: widget.professionalName,
        ),
      ),
    );
  }

  Widget _buildReviewCard(CustomerReview review) {
    // Debug logging removed - issue was fixed
    
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Reviewer info and rating
          Row(
            children: [
              // Avatar
              ProfileAvatar(
                profilePhotoUrl: review.customerPhotoUrl,
                radius: 18,
                backgroundColor: Colors.grey[200],
                fallbackIcon: Icons.person,
              ),
              const SizedBox(width: 12),
              // Name and rating
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.customerName,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _buildStarRating(review.rating.toDouble()),
                        const SizedBox(width: 8),
                        Text(
                          _formatDate(review.createdAt),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          // Review text
          if (review.reviewText != null && review.reviewText!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              review.reviewText!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.black87,
                height: 1.4,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return weeks == 1 ? '1 week ago' : '$weeks weeks ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return months == 1 ? '1 month ago' : '$months months ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return years == 1 ? '1 year ago' : '$years years ago';
    }
  }
}
