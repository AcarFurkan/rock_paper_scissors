enum DetectionClasses { heavy, minor, moderate, undamaged }

extension DetectionClassesExtension on DetectionClasses {
  String get label {
    switch (this) {
      case DetectionClasses.heavy:
        return "heavy damage";
      case DetectionClasses.minor:
        return "minor damage";
      case DetectionClasses.moderate:
        return "moderate damage";
      case DetectionClasses.undamaged:
        return "undamaged";
    }
  }
}


