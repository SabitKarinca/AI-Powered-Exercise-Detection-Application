
# AI-Powered Exercise Recognition Application

## Features
- Real-time exercise recognition  
- Evaluates correctness of exercise form  
- Works offline with embedded TensorFlow Lite model  
- Displays top predictions and confidence scores  
- User-friendly interface for mobile devices  

## Screenshots
*(Add screenshots of the app here, e.g., main screen, camera input, and result screen)*  

## Installation
1. Clone the repository:  
```bash
git clone https://github.com/SabitKarinca/AI-Powered-Exercise-Detection-Application
````

2. Navigate to the project folder:

```bash
cd your_project_folder
```

3. Install dependencies:

```bash
flutter pub get
```

4. Run the app:

```bash
flutter run
```

## Model

* TensorFlow Lite `.tflite` model is stored in `assets/models/`
* Labels file: `assets/models/labels.txt`
* Trained using a custom dataset on Google Colab
* Older models with version conflicts are included for reference

## Notes

* Tested on Android devices
* Ensure Flutter and TFLite versions are compatible with the model
* Confidence threshold is set at **30%** for valid predictions

## Keywords

AI, Fitness, Exercise Detection, Flutter, TensorFlow Lite, Mobile Application


