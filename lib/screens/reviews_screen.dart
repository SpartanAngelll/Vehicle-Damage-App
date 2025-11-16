import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../models/user_state.dart';
import '../models/review_models.dart';
import '../services/review_service.dart';
import '../services/firebase_firestore_service.dart';
import '../widgets/review_card.dart';
import '../widgets/web_layout.dart';
import '../widgets/profile_avatar.dart';

class ReviewsScreen extends StatefulWidget {
  final String? professionalId; // If null, shows current user's reviews
  final String? professionalName;

  const ReviewsScreen({
    Key? key,
    this.professionalId,
    this.professionalName,
  }) : super(key: key);

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  final ReviewService _reviewService = ReviewService();
  final FirebaseFirestoreService _firestoreService = FirebaseFirestoreService();
  List<dynamic> _reviews = []; // Can be CustomerReview or ProfessionalReview
  bool _isLoading = true;
  String? _error;
  double _averageRating = 0.0;
  int _totalReviews = 0;
  Map<String, dynamic>? _userInfo;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final userState = Provider.of<UserState>(context, listen: false);
      final targetId = widget.professionalId ?? userState.userId;
      
      if (targetId == null) {
        throw Exception('User ID not found');
      }

      // Determine if we're viewing a professional's reviews or a customer's reviews
      final isViewingProfessional = widget.professionalId != null || 
          userState.isServiceProfessional || 
          userState.isRepairman;
      
      // Load reviews based on role
      if (isViewingProfessional) {
        // Load customer reviews (reviews received by the professional)
        final customerReviews = await _reviewService.getProfessionalReviews(targetId);
        setState(() {
          _reviews = customerReviews;
        });
      } else {
        // Load professional reviews (reviews received by the customer/owner)
        final professionalReviews = await _reviewService.getCustomerReviews(targetId);
        setState(() {
          _reviews = professionalReviews;
        });
      }

      // Load rating statistics
      final stats = isViewingProfessional
          ? await _reviewService.getProfessionalRatingStats(targetId)
          : await _reviewService.getCustomerRatingStats(targetId);
      
      // Load user info
      final userInfo = await _firestoreService.getUserProfile(targetId);
      
      setState(() {
        _averageRating = stats.averageRating;
        _totalReviews = stats.totalReviews;
        _userInfo = userInfo;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ [ReviewsScreen] Error loading reviews: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = kIsWeb;
    final userState = Provider.of<UserState>(context, listen: false);
    final title = widget.professionalName != null 
        ? 'Reviews for ${widget.professionalName}'
        : 'My Reviews';

    if (isWeb) {
      final screenWidth = MediaQuery.of(context).size.width;
      final maxContentWidth = (screenWidth > 1400 ? 1200.0 : 1100.0);

      return WebLayout(
        currentRoute: '/reviews',
        child: Center(
          child: Container(
            constraints: BoxConstraints(maxWidth: maxContentWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with user info and stats
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: _buildHeader(context, userState),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: _buildBody(),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: _buildHeader(context, userState),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, UserState userState) {
    final displayName = widget.professionalName ?? 
        _userInfo?['fullName'] ?? 
        userState.fullName ?? 
        'User';
    final displayEmail = _userInfo?['email'] ?? 
        userState.email ?? 
        '';
    final photoUrl = _userInfo?['profilePhotoUrl'] ?? 
        userState.profilePhotoUrl;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ProfileAvatar(
              profilePhotoUrl: photoUrl,
              radius: 32,
              fallbackIcon: Icons.person,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (displayEmail.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      displayEmail,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Rating stats
        if (_totalReviews > 0) ...[
          Row(
            children: [
              Icon(
                Icons.star,
                color: Colors.amber,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                _averageRating.toStringAsFixed(1),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                '(${_totalReviews} ${_totalReviews == 1 ? 'review' : 'reviews'})',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ] else ...[
          Text(
            'No ratings yet',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading reviews',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadReviews,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_reviews.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.star_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No reviews yet',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              widget.professionalName != null
                  ? '${widget.professionalName} hasn\'t received any reviews yet.'
                  : 'You haven\'t received any reviews yet.',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadReviews,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _reviews.length,
        itemBuilder: (context, index) {
          final review = _reviews[index];
          // Handle both CustomerReview and ProfessionalReview types
          if (review is CustomerReview) {
            return ReviewCard(
              review: review,
              showProfessionalInfo: widget.professionalId == null,
            );
          } else if (review is ProfessionalReview) {
            return ProfessionalReviewCard(review: review);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}
