# HeightGuesser - Height Estimation App

A Flutter application that estimates a person's height from an image using reference objects for scale.

## Features

- **Image Upload**: Take a photo or select from gallery
- **Reference Object Selection**: Choose from common objects with known dimensions
- **Height Estimation**: Accurate calculation with visual representation
- **User Profiles**: Save your profile and height history
- **History Tracking**: View past estimations with details

## Screenshots

(Screenshots will be added here)

## Getting Started

### Prerequisites

- Flutter SDK (3.5.0 or higher)
- Dart SDK (3.5.0 or higher)
- Android Studio / VS Code with Flutter extensions

### Installation

1. Clone the repository:
   ```
   git clone https://github.com/yourusername/heightguesser.git
   ```

2. Navigate to the project directory:
   ```
   cd heightguesser
   ```

3. Install dependencies:
   ```
   flutter pub get
   ```

4. Run the app:
   ```
   flutter run
   ```

## Technical Details

### Architecture

The app follows a Provider-based architecture for state management with the following components:

- **Models**: Data structures for user profiles, height estimations, and reference objects
- **Providers**: State management for user data and height estimations
- **Screens**: UI components for different app screens
- **Components**: Reusable UI widgets
- **Constants**: App-wide constants and theme definitions

### Dependencies

- **image_picker**: For camera and gallery access
- **image_cropper**: For image editing
- **provider**: For state management
- **shared_preferences**: For local data storage
- **path_provider**: For file system access
- **tflite_flutter**: For ML model integration (placeholder)

## Future Enhancements

- Implement ML-based object detection for automatic reference object identification
- Add cloud storage for user data and images
- Implement social sharing features
- Add more reference objects and improve accuracy

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Flutter team for the amazing framework
- All contributors and testers
