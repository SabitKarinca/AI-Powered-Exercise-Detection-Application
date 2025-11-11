AI-Powered Exercise Detection Application
Project Overview

This project is an AI-powered mobile application designed to detect and evaluate exercise movements in real time. Using a deep learning model trained on custom-labeled exercise images, the app can classify common exercises and provide feedback on their correctness.

The system supports offline functionality and works on Android devices using Flutter and TensorFlow Lite (TFLite).

Features

Real-time exercise recognition using camera or gallery images.

Detects multiple exercises (e.g., squat, plank, squat up, squat down).

Provides confidence scores for predictions.

Highlights whether the exercise posture is correct or needs adjustment.

Displays top-3 predictions if confidence is low.

Offline operation, no internet required for inference.

Technologies Used

Flutter – UI and mobile app development.

TensorFlow Lite (TFLite) – Model inference on-device.

Dart – Application logic.

Image Processing – Preprocessing images for model input.

Custom Dataset – Collected and labeled images for exercise detection.

Dataset

The exercise dataset was custom-created and labeled by the project developer. It contains images of exercises from different angles to ensure robust model training.

Format: JPG/PNG images

Classes: Squat Up, Squat Down, Plank

Sample dataset structure:

dataset/
├─ squat_up/
├─ squat_down/
└─ plank/


Screenshots of the app interface can be added below:
(Leave space here for your images)

Installation

Clone the repository.

Ensure Flutter SDK is installed.

Add TFLite model files to assets/models/:

assets/models/exercise_classifier.tflite
assets/models/labels.txt


Update pubspec.yaml:

flutter:
  assets:
    - assets/models/exercise_classifier.tflite
    - assets/models/labels.txt


Install dependencies:

flutter pub get


Run the app:

flutter run

Model Training

The TFLite model was trained on Google Colab using a custom exercise dataset.

Framework: TensorFlow / Keras

Input size: 224 x 224 RGB images

Epochs: 50

Output: Softmax probabilities for each class

The model was exported as TensorFlow Lite (.tflite) for on-device inference. Previous models with version mismatches are also included in the legacy_models/ folder for reference.

Application Screens

(Leave space for screenshots)

Home Screen – Select an image from gallery or camera.

Detection Result – Shows predicted exercise and confidence score.

Low Confidence Feedback – Suggests alternative angles if prediction is uncertain.

Project Structure
lib/
├─ main.dart              # Main application
├─ exercise_classifier.dart  # TFLite model integration
assets/
├─ models/
│  ├─ exercise_classifier.tflite
│  └─ labels.txt
dataset/
├─ squat_up/
├─ squat_down/
└─ plank/
legacy_models/
├─ old_model_v1.tflite
├─ old_model_v2.tflite

How It Works

The user selects an image from the gallery or camera.

The image is preprocessed to 224x224 size and normalized.

TFLite interpreter runs inference on the image.

The app returns the predicted exercise with confidence score.

If the score is below the threshold (30%), top-3 predictions are shown with feedback.

Notes

The app works completely offline.

Preprocessing includes padding, center-crop, and normalization for reliable results.

Confidence threshold is 0.3, ensuring flexibility for different lighting and angles.

License

Specify your license here (MIT, Apache, etc.).
