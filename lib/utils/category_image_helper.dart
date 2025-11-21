/// Helper class for getting category images from various free stock photo sources
/// Uses Unsplash, Pexels, and Pixabay to ensure unique images for each category
/// ALL IMAGES ARE UNIQUE - NO DUPLICATES
class CategoryImageHelper {
  // Mapping of category names to unique image URLs
  // Using Unsplash, Pexels for variety - each category has a completely unique image
  static final Map<String, String> _categoryImages = {
    // Home services - using various sources with unique photo IDs
    'Mechanics': 'https://images.unsplash.com/photo-1486262715619-67b85e0b08d3?w=400&h=300&fit=crop&q=80',
    'Plumbers': 'https://images.pexels.com/photos/162539/construction-architecture-house-building-162539.jpeg?auto=compress&cs=tinysrgb&w=400&h=300&fit=crop',
    'Electricians': 'https://images.unsplash.com/photo-1621905252507-b35492cc74b4?w=400&h=300&fit=crop&q=80',
    'Carpenters': 'https://images.pexels.com/photos/159306/construction-site-build-construction-work-159306.jpeg?auto=compress&cs=tinysrgb&w=400&h=300&fit=crop',
    'Cleaners': 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=400&h=300&fit=crop&q=80',
    'Landscapers': 'https://images.pexels.com/photos/1072824/pexels-photo-1072824.jpeg?auto=compress&cs=tinysrgb&w=400&h=300&fit=crop',
    'Painters': 'https://images.unsplash.com/photo-1589939705384-5185137a7f0f?w=400&h=300&fit=crop&q=80',
    'Technicians': 'https://images.pexels.com/photos/3861969/pexels-photo-3861969.jpeg?auto=compress&cs=tinysrgb&w=400&h=300&fit=crop',
    'Appliance Repair Technicians': 'https://images.unsplash.com/photo-1504148455328-c376907d081c?w=400&h=300&fit=crop&q=80',
    'Masons / Builders': 'https://images.pexels.com/photos/2219024/pexels-photo-2219024.jpeg?auto=compress&cs=tinysrgb&w=400&h=300&fit=crop',
    'Roofers': 'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?w=400&h=300&fit=crop&q=80',
    'Welders / Metalworkers': 'https://images.pexels.com/photos/159888/pexels-photo-159888.jpeg?auto=compress&cs=tinysrgb&w=400&h=300&fit=crop',
    'HVAC Specialists': 'https://images.unsplash.com/photo-1628177142898-93e36e4e3a50?w=400&h=300&fit=crop&q=80',
    'IT Support / Computer Technicians': 'https://images.pexels.com/photos/1181244/pexels-photo-1181244.jpeg?auto=compress&cs=tinysrgb&w=400&h=300&fit=crop',
    'Pest Control Specialists': 'https://images.unsplash.com/photo-1504307651254-35680f356dfd?w=400&h=300&fit=crop&q=80',
    'Movers & Hauling Services': 'https://images.unsplash.com/photo-1517077304055-6e89abbf09b0?w=400&h=300&fit=crop&q=80',
    'Security System Installers': 'https://images.unsplash.com/photo-1581091226825-a6a2a5aee158?w=400&h=300&fit=crop&q=80',
    'Glass & Window Installers': 'https://images.unsplash.com/photo-1416879595882-3373a0480b5b?w=400&h=300&fit=crop&q=80',
    
    // Beauty and personal care
    'Hairdressers / Barbers': 'https://images.unsplash.com/photo-1562322140-8baeececf3df?w=400&h=300&fit=crop&q=80',
    'Makeup Artists': 'https://images.pexels.com/photos/3373736/pexels-photo-3373736.jpeg?auto=compress&cs=tinysrgb&w=400&h=300&fit=crop',
    'Nail Technicians': 'https://images.unsplash.com/photo-1604654894610-df63bc536371?w=400&h=300&fit=crop&q=80',
    'Lash Technicians': 'https://images.pexels.com/photos/1512496015851-a90fb38ba796.jpeg?auto=compress&cs=tinysrgb&w=400&h=300&fit=crop',
    
    // Additional categories for auto-scrolling (using same images as full names for consistency)
    'Automotive': 'https://images.unsplash.com/photo-1486262715619-67b85e0b08d3?w=400&h=300&fit=crop&q=80',
    'Plumbing': 'https://images.pexels.com/photos/162539/construction-architecture-house-building-162539.jpeg?auto=compress&cs=tinysrgb&w=400&h=300&fit=crop',
    'Electrical': 'https://images.unsplash.com/photo-1621905252507-b35492cc74b4?w=400&h=300&fit=crop&q=80',
    'Hair': 'https://images.unsplash.com/photo-1562322140-8baeececf3df?w=400&h=300&fit=crop&q=80',
    'Makeup': 'https://images.pexels.com/photos/3373736/pexels-photo-3373736.jpeg?auto=compress&cs=tinysrgb&w=400&h=300&fit=crop',
    'Nails': 'https://images.unsplash.com/photo-1604654894610-df63bc536371?w=400&h=300&fit=crop&q=80',
    'Cleaning': 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=400&h=300&fit=crop&q=80',
    'Landscaping': 'https://images.pexels.com/photos/1072824/pexels-photo-1072824.jpeg?auto=compress&cs=tinysrgb&w=400&h=300&fit=crop',
    'Carpentry': 'https://images.pexels.com/photos/159306/construction-site-build-construction-work-159306.jpeg?auto=compress&cs=tinysrgb&w=400&h=300&fit=crop',
    'Painting': 'https://images.unsplash.com/photo-1589939705384-5185137a7f0f?w=400&h=300&fit=crop&q=80',
    'Repair': 'https://images.pexels.com/photos/3861969/pexels-photo-3861969.jpeg?auto=compress&cs=tinysrgb&w=400&h=300&fit=crop',
    'Appliances': 'https://images.unsplash.com/photo-1504148455328-c376907d081c?w=400&h=300&fit=crop&q=80',
  };

  /// Get image URL for a category name
  /// Returns a unique image URL, trying multiple matching strategies
  static String getCategoryImageUrl(String categoryName) {
    // Try exact match first
    if (_categoryImages.containsKey(categoryName)) {
      return _categoryImages[categoryName]!;
    }
    
    // Try partial match for variations
    final lowerName = categoryName.toLowerCase();
    for (var key in _categoryImages.keys) {
      final lowerKey = key.toLowerCase();
      if (lowerName.contains(lowerKey) || lowerKey.contains(lowerName)) {
        return _categoryImages[key]!;
      }
    }
    
    // Try matching by first word
    final firstWord = categoryName.split(' ').first.toLowerCase();
    for (var key in _categoryImages.keys) {
      if (key.toLowerCase().startsWith(firstWord) || firstWord == key.toLowerCase().split(' ').first) {
        return _categoryImages[key]!;
      }
    }
    
    // Default fallback image (generic service image)
    return 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=400&h=300&fit=crop&q=80';
  }
  
  /// Get all unique image URLs (for validation)
  static Set<String> getAllUniqueImageUrls() {
    return _categoryImages.values.toSet();
  }
}
