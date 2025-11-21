import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utils/category_image_helper.dart';

class GlowCard extends StatelessWidget {
  final Widget child;
  final Color? glowColor;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final double? width;
  final double? height;
  final double shadowBlur;
  final double shadowOpacity;

  const GlowCard({
    Key? key,
    required this.child,
    this.glowColor,
    this.backgroundColor,
    this.borderColor,
    this.borderRadius = 16.0,
    this.padding,
    this.margin,
    this.onTap,
    this.width,
    this.height,
    this.shadowBlur = 12.0,
    this.shadowOpacity = 0.15,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveGlowColor = glowColor ?? theme.colorScheme.primary;
    final effectiveBackgroundColor = backgroundColor ?? theme.colorScheme.surface;
    final effectiveBorderColor = borderColor ?? effectiveGlowColor.withOpacity(0.2);

    Widget cardContent = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        color: effectiveBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: effectiveGlowColor.withOpacity(shadowOpacity),
            blurRadius: shadowBlur,
            offset: Offset(0, 6),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: effectiveGlowColor.withOpacity(shadowOpacity * 0.5),
            blurRadius: shadowBlur * 0.5,
            offset: Offset(0, 3),
            spreadRadius: 0,
          ),
        ],
        border: Border.all(
          color: effectiveBorderColor,
          width: 1.5,
        ),
      ),
      child: padding != null
          ? Padding(
              padding: padding!,
              child: child,
            )
          : child,
    );

    if (onTap != null) {
      cardContent = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: cardContent,
        ),
      );
    }

    if (margin != null) {
      cardContent = Padding(
        padding: margin!,
        child: cardContent,
      );
    }

    return cardContent;
  }
}

// Predefined glow card variants for common use cases
class ServiceCategoryCard extends StatelessWidget {
  final String name;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final bool isSelected;
  final String? imageUrl;

  const ServiceCategoryCard({
    Key? key,
    required this.name,
    required this.icon,
    required this.color,
    this.onTap,
    this.isSelected = false,
    this.imageUrl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final backgroundImageUrl = imageUrl ?? CategoryImageHelper.getCategoryImageUrl(name);
    
    return GlowCard(
      glowColor: isSelected ? Colors.green : color,
      borderRadius: 20,
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Background image
            Positioned.fill(
              child: CachedNetworkImage(
                imageUrl: backgroundImageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: color.withOpacity(0.1),
                  child: Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: color.withOpacity(0.1),
                  child: Icon(
                    icon,
                    size: 40,
                    color: color,
                  ),
                ),
              ),
            ),
            // Gradient overlay for better text readability
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.1),
                      Colors.black.withOpacity(0.5),
                    ],
                  ),
                ),
              ),
            ),
            // Main content container
            Container(
              width: double.infinity,
              height: double.infinity,
              padding: EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Icon container with consistent sizing
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.4),
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        icon,
                        size: 24,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  
                  // Spacing between icon and text
                  SizedBox(height: 12),
                  
                  // Text container with proper constraints
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      child: Text(
                        name,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Inter',
                          color: Colors.white,
                          fontSize: 13,
                          height: 1.2,
                          shadows: [
                            Shadow(
                              offset: Offset(0, 1),
                              blurRadius: 4,
                              color: Colors.black.withOpacity(0.6),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Selection indicator
            if (isSelected)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 2,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.check,
                    size: 10,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class EstimateCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color? glowColor;

  const EstimateCard({
    Key? key,
    required this.child,
    this.onTap,
    this.glowColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      glowColor: glowColor ?? Theme.of(context).colorScheme.primary,
      borderRadius: 12,
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.only(bottom: 12),
      onTap: onTap,
      child: child,
    );
  }
}

class BookingCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color? glowColor;

  const BookingCard({
    Key? key,
    required this.child,
    this.onTap,
    this.glowColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      glowColor: glowColor ?? Theme.of(context).colorScheme.secondary,
      borderRadius: 12,
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.only(bottom: 12),
      onTap: onTap,
      child: child,
    );
  }
}

class ChatCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color? glowColor;

  const ChatCard({
    Key? key,
    required this.child,
    this.onTap,
    this.glowColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      glowColor: glowColor ?? Theme.of(context).colorScheme.tertiary,
      borderRadius: 12,
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.only(bottom: 12),
      onTap: onTap,
      child: child,
    );
  }
}
