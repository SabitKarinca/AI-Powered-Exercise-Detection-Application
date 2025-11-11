# AI-Powered Exercise Recognition Application – Flutter & TensorFlow Lite

This project is a mobile application developed with Flutter for recognizing and evaluating exercise movements using a TensorFlow Lite model. The application allows users to select an image from the camera or gallery, processes the image on-device, and provides exercise predictions with confidence scores. It operates fully offline and supports multiple exercise types.

## Features
- Image selection from camera or gallery  
- Offline inference using a TensorFlow Lite model  
- Displays top-1 and top-3 predictions  
- Outputs confidence scores  
- Highlights whether exercise form is correct or needs adjustment  
- User-friendly interface for mobile devices  
- Low-confidence detection warning  

## Technologies Used
- Flutter  
- TensorFlow Lite (tflite_flutter)  
- Image Picker  
- Image Processing (image package)  
- Custom CNN Model exported as TensorFlow Lite  

## Project Structure
```

lib/
│── main.dart
│── exercise_classifier.dart

assets/
└── models/
├── exercise_classifier.tflite
└── labels.txt

````

## Installation
1. Install dependencies  
```bash
flutter pub get
````

2. Add model files
   Place the model and label files under `assets/models/`:

* exercise_classifier.tflite
* labels.txt

3. Add assets to `pubspec.yaml`

```yaml
assets:
  - assets/models/exercise_classifier.tflite
  - assets/models/labels.txt
```

4. Run the application

```bash
flutter run
```

## Model Workflow

The `ExerciseClassifier` class performs the following operations:

* Loads the TensorFlow Lite model
* Loads and parses the label file
* Resizes the input image to 224x224
* Converts the image into a tensor format
* Runs inference using TensorFlow Lite
* Applies softmax to obtain probabilities
* Extracts the top-1 prediction
* Extracts the top-3 predictions
* Maps class indices to exercise names

**Model input shape:** 1 x 224 x 224 x 3
**Model output:** Floating-point logits representing class probabilities

## Supported Exercise Types

The model supports the following exercises:

* Squat Up
* Squat Down
* Plank

## Packages Used

* tflite_flutter: ^0.10.4
* image_picker: ^1.1.0
* image: ^4.1.3

## Model Versions

**Final Model (Used in Application)**

* File: exercise_classifier.tflite
* Labels: labels.txt
  This is the active and working TensorFlow Lite model used by the Flutter application.

**Previous/Experimental Models**
Old or non-functional model attempts can be found under:

* model_training/old_models/
  These include earlier attempts that resulted in TFLite conversion errors, version mismatches, or unsupported operators. They are retained only for documentation and research history and are not used in the application.

## Screenshots

Below is a placeholder section for application screenshots. Replace the image paths with your own.

Home Screen | Result Screen

## Notes

* The application works completely offline.
* Label list length must match model output size.
* The implementation includes a fallback to avoid mismatches.
* The model expects RGB images with pixel values from 0 to 255.
* Confidence threshold is set at **30%** for valid predictions.

## Contribution

Contributions and suggestions are welcome. Please submit a pull request or open an issue for improvements.

## License

This project is released under the MIT License.


İstersen bundan sonra **dosya ve klasör yapısı önerisini** de aynı profesyonel düzende hazırlayıp verebilirim. Yapayım mı kanka?
```
