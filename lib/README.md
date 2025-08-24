# Vehicle Damage App - Code Organization

This Flutter app has been organized into a clean, maintainable structure following best practices.

## Folder Structure

### 📁 `models/`
Contains data structures and state management:
- `damage_report.dart` - DamageReport data model
- `app_state.dart` - AppState class extending ChangeNotifier for state management
- `models.dart` - Barrel file for easy imports

### 📁 `screens/`
Contains all UI pages/screens:
- `splash_screen.dart` - App splash screen
- `login_screen.dart` - User authentication screen
- `owner_dashboard.dart` - Vehicle owner's main interface
- `repairman_dashboard.dart` - Auto repair professional's interface
- `screens.dart` - Barrel file for easy imports

### 📁 `widgets/`
Contains reusable UI components:
- `damage_report_card.dart` - Reusable card widget for displaying damage reports
- `widgets.dart` - Barrel file for easy imports

### 📁 `services/`
Contains business logic and external integrations:
- `image_service.dart` - Service for handling image picking operations
- `services.dart` - Barrel file for easy imports

### 📁 `main.dart`
Clean main entry point that only handles:
- App initialization
- Provider setup
- Routing configuration

## Benefits of This Structure

1. **Separation of Concerns**: Each file has a single responsibility
2. **Reusability**: Widgets can be reused across different screens
3. **Maintainability**: Easy to find and modify specific functionality
4. **Scalability**: Easy to add new features without cluttering existing code
5. **Testing**: Each component can be tested independently
6. **Team Collaboration**: Multiple developers can work on different parts simultaneously

## Import Patterns

Use barrel files for clean imports:
```dart
import '../models/models.dart';
import '../screens/screens.dart';
import '../widgets/widgets.dart';
import '../services/services.dart';
```

## Adding New Features

1. **New Screen**: Add to `screens/` folder and export in `screens.dart`
2. **New Widget**: Add to `widgets/` folder and export in `widgets.dart`
3. **New Model**: Add to `models/` folder and export in `models.dart`
4. **New Service**: Add to `services/` folder and export in `services.dart`
