enum ImageQuality {
  low,
  medium,
  high,
  original,
}

extension ImageQualityExtension on ImageQuality {
  String get displayName {
    switch (this) {
      case ImageQuality.low:
        return 'Low';
      case ImageQuality.medium:
        return 'Medium';
      case ImageQuality.high:
        return 'High';
      case ImageQuality.original:
        return 'Original';
    }
  }

  int get qualityValue {
    switch (this) {
      case ImageQuality.low:
        return 30;
      case ImageQuality.medium:
        return 60;
      case ImageQuality.high:
        return 85;
      case ImageQuality.original:
        return 100;
    }
  }

  int? get maxWidth {
    switch (this) {
      case ImageQuality.low:
        return 800;
      case ImageQuality.medium:
        return 1200;
      case ImageQuality.high:
        return 1920;
      case ImageQuality.original:
        return null;
    }
  }

  int? get maxHeight {
    switch (this) {
      case ImageQuality.low:
        return 600;
      case ImageQuality.medium:
        return 900;
      case ImageQuality.high:
        return 1440;
      case ImageQuality.original:
        return null;
    }
  }
}
