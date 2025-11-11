// exercise_classifier.dart - İyileştirilmiş versiyon
import 'dart:typed_data';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class ExerciseClassifier {
  static const String _modelPath = 'assets/models/exercise_classifier.tflite';
  static const String _labelsPath = 'assets/models/labels.txt';
  
  void dispose() {
    _interpreter?.close();
    _interpreter = null;
  }
  Interpreter? _interpreter;
  List<String> _labels = [];
  
  static const int inputSize = 224;
  static const int numChannels = 3;
  
  // Güven skoru eşiği - daha esnek hale getiriyoruz
  static const double _confidenceThreshold = 0.3; // 0.7'den 0.3'e düşürdük
  
  /// Modeli ve etiketleri yükler
  Future<void> loadModel() async {
    try {
      // TFLite modelini yükle
      _interpreter = await Interpreter.fromAsset(_modelPath);
      
      // Etiket dosyasını yükle
      final labelsData = await rootBundle.loadString(_labelsPath);
      _labels = labelsData
          .split('\n')
          .map((label) => label.trim())
          .where((label) => label.isNotEmpty)
          .toList();
      
      print('Model başarıyla yüklendi');
      print('Sınıflar: $_labels');
      print('Model input shape: ${_interpreter!.getInputTensor(0).shape}');
      print('Model output shape: ${_interpreter!.getOutputTensor(0).shape}');
      
      // Model detaylarını yazdır
      _printModelDetails();
    } catch (e) {
      print('Model yüklenirken hata: $e');
      rethrow;
    }
  }
  
  /// Model detaylarını yazdırır (debug için)
  void _printModelDetails() {
    if (_interpreter == null) return;
    
    final inputTensor = _interpreter!.getInputTensor(0);
    final outputTensor = _interpreter!.getOutputTensor(0);
    
    print('Input tensor - shape: ${inputTensor.shape}, type: ${inputTensor.type}');
    print('Output tensor - shape: ${outputTensor.shape}, type: ${outputTensor.type}');
    print('Expected input size: $inputSize x $inputSize x $numChannels');
  }
  
  /// Görüntüyü sınıflandırır ve sonuçları döndürür - Geliştirilmiş Debug
  Future<Map<String, double>> classifyImage(File imageFile) async {
    if (_interpreter == null) {
      throw Exception('Model henüz yüklenmedi. Önce loadModel() çağırın.');
    }
    
    try {
      print('\n=== SINIFLANDIRMA BAŞLADI ===');
      print('Dosya yolu: ${imageFile.path}');
      print('Dosya boyutu: ${await imageFile.length()} bytes');
      

      final input = await _preprocessImage(imageFile);
      

      final outputShape = _interpreter!.getOutputTensor(0).shape;
      print('Output tensor shape: $outputShape');
      
      final output = List.filled(outputShape[1], 0.0).reshape([1, outputShape[1]]);
      
      final reshapedInput = input.reshape([1, inputSize, inputSize, numChannels]);
      print('Reshaped input shape: [1, $inputSize, $inputSize, $numChannels]');

      print('Model çalıştırılıyor...');
      final stopwatch = Stopwatch()..start();
      
      // Tahmin yap
      _interpreter!.run(reshapedInput, output);
      
      stopwatch.stop();
      print('İnferans süresi: ${stopwatch.elapsedMilliseconds}ms');
      

      final rawResults = output[0] as List<double>;
      
      
      print('\n=== HAM MODEL ÇIKTILARI ===');
      print('Toplam sınıf sayısı: ${rawResults.length}');
      print('Ham logits: $rawResults');
      
      
      final maxLogit = rawResults.reduce(math.max);
      final minLogit = rawResults.reduce(math.min);
      print('Max logit: $maxLogit, Min logit: $minLogit');
      
      // Softmax uygula
      final softmaxResults = _applySoftmax(rawResults);
      
      // Debug: Softmax sonuçlarını detaylı yazdır
      print('\n=== SOFTMAX SONUÇLARI ===');
      print('Softmax değerleri: $softmaxResults');
      
      // Softmax toplamının 1'e yakın olduğunu kontrol et
      final softmaxSum = softmaxResults.reduce((a, b) => a + b);
      print('Softmax toplamı: $softmaxSum (1.0\'a yakın olmalı)');
      
      // Sonuçları etiketlerle eşleştir
      final results = <String, double>{};
      for (int i = 0; i < _labels.length && i < softmaxResults.length; i++) {
        results[_labels[i]] = softmaxResults[i];
      }
      
      // DETAYLI SONUÇ ANALİZİ
      print('\n=== DETAYLI SONUÇLAR ===');
      final sortedResults = results.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      print('Tüm sınıf sonuçları:');
      for (int i = 0; i < sortedResults.length; i++) {
        final confidence = sortedResults[i].value * 100;
        print('${i + 1}. ${sortedResults[i].key}: ${confidence.toStringAsFixed(2)}%');
      }
      
      // En yüksek sonuç analizi
      final topResult = sortedResults.first;
      print('\nEn yüksek sonuç: ${topResult.key} (${(topResult.value * 100).toStringAsFixed(2)}%)');
      print('Güven eşiği: ${(_confidenceThreshold * 100).toStringAsFixed(1)}%');
      print('Eşik geçildi mi: ${topResult.value > _confidenceThreshold ? "EVET" : "HAYIR"}');
      
      // İkinci en yüksek ile fark
      if (sortedResults.length > 1) {
        final secondBest = sortedResults[1];
        final difference = (topResult.value - secondBest.value) * 100;
        print('İkinci en yüksek ile fark: ${difference.toStringAsFixed(2)}%');
      }
      
      print('=== SINIFLANDIRMA BİTTİ ===\n');
      
      return results;
    } catch (e) {
      print('Sınıflandırma hatası: $e');
      rethrow;
    }
  }
  
  /// Görüntüyü model için uygun formata dönüştürür - Debug ve Multiple Preprocessing Options
  Future<Float32List> _preprocessImage(File imageFile) async {
    try {
      // Görüntüyü oku
      final bytes = await imageFile.readAsBytes();
      img.Image? image = img.decodeImage(bytes);
      
      if (image == null) {
        throw Exception('Görüntü decode edilemedi');
      }
      
      print('=== GÖRÜNTÜ ÖN İŞLEME DEBUG ===');
      print('Orijinal görüntü boyutu: ${image.width}x${image.height}');
      print('Orijinal format: ${image.format}');
      
      // Görüntüyü RGB formatına çevir (eğer değilse)
      if (image.numChannels != 3) {
        image = img.Image.from(image);
        print('Görüntü RGB formatına çevrildi');
      }
      
      // Model input boyutuna göre yeniden boyutlandır
      // ÖNEMLİ: Farklı resize methodları deneyin
      image = _preprocessImageMultipleWays(image, inputSize, inputSize);
      
      print('İşlenmiş görüntü boyutu: ${image.width}x${image.height}');
      
      // Float32List oluştur
      final input = Float32List(inputSize * inputSize * numChannels);
      int bufferIndex = 0;
      
      // ÖNEMLİ: Pixel okuma sırasını kontrol edin (RGB vs BGR vs diğer)
      // Method 1: Standard RGB normalization [0,1]
      for (int y = 0; y < inputSize; y++) {
        for (int x = 0; x < inputSize; x++) {
          final pixel = image.getPixel(x, y);
          
          // Farklı normalizasyon yöntemlerini deneyin:
          
          // Yöntem 1: [0, 1] normalizasyonu (en yaygın)
          input[bufferIndex++] = pixel.r / 255.0;
          input[bufferIndex++] = pixel.g / 255.0;
          input[bufferIndex++] = pixel.b / 255.0;
          
          // Yöntem 2: [-1, 1] normalizasyonu (bazı modeller için)
          // input[bufferIndex++] = (pixel.r / 127.5) - 1.0;
          // input[bufferIndex++] = (pixel.g / 127.5) - 1.0;
          // input[bufferIndex++] = (pixel.b / 127.5) - 1.0;
          
          // Yöntem 3: ImageNet mean/std normalizasyonu
          // input[bufferIndex++] = (pixel.r / 255.0 - 0.485) / 0.229;
          // input[bufferIndex++] = (pixel.g / 255.0 - 0.456) / 0.224;
          // input[bufferIndex++] = (pixel.b / 255.0 - 0.406) / 0.225;
          
          // Yöntem 4: BGR sıralaması (OpenCV tarzı)
          // input[bufferIndex++] = pixel.b / 255.0;
          // input[bufferIndex++] = pixel.g / 255.0;
          // input[bufferIndex++] = pixel.r / 255.0;
        }
      }
      
      // Detaylı debug bilgileri
      print('Input array boyutu: ${input.length}');
      print('Beklenen boyut: ${inputSize * inputSize * numChannels}');
      print('İlk 12 pixel değeri (RGB): ${input.take(12).toList()}');
      print('Min değer: ${input.reduce(math.min)}');
      print('Max değer: ${input.reduce(math.max)}');
      print('Ortalama değer: ${input.reduce((a, b) => a + b) / input.length}');
      print('=== DEBUG BİTTİ ===\n');
      
      return input;
    } catch (e) {
      print('Görüntü ön işleme hatası: $e');
      rethrow;
    }
  }
  
  /// Farklı preprocessing yöntemlerini dener
  img.Image _preprocessImageMultipleWays(img.Image src, int targetWidth, int targetHeight) {
    print('Preprocessing yöntemi seçiliyor...');
    
    // Yöntem 1: Padding ile resize (aspect ratio korunur)
    return _resizeImageWithPadding(src, targetWidth, targetHeight);
    
    // Yöntem 2: Direkt resize (aspect ratio bozulur ama tam uyum)
    // return img.copyResize(src, width: targetWidth, height: targetHeight);
    
    // Yöntem 3: Center crop sonra resize
    // return _centerCropAndResize(src, targetWidth, targetHeight);
  }
  
  /// Center crop ve resize yöntemi
  img.Image _centerCropAndResize(img.Image src, int targetWidth, int targetHeight) {
    // En küçük boyutu bul
    final minDimension = math.min(src.width, src.height);
    
    // Merkezden kare şeklinde kırp
    final cropX = (src.width - minDimension) ~/ 2;
    final cropY = (src.height - minDimension) ~/ 2;
    
    final cropped = img.copyCrop(src, 
      x: cropX, 
      y: cropY, 
      width: minDimension, 
      height: minDimension
    );
    
    // Target boyutuna resize et
    return img.copyResize(cropped, width: targetWidth, height: targetHeight);
  }
  
  /// Görüntüyü aspect ratio'yu koruyarak yeniden boyutlandırır
  img.Image _resizeImageWithPadding(img.Image src, int targetWidth, int targetHeight) {
    // Aspect ratio'yu koru
    final srcAspect = src.width / src.height;
    final targetAspect = targetWidth / targetHeight;
    
    int newWidth, newHeight;
    
    if (srcAspect > targetAspect) {
      // Görüntü daha geniş
      newWidth = targetWidth;
      newHeight = (targetWidth / srcAspect).round();
    } else {
      // Görüntü daha uzun veya kare
      newHeight = targetHeight;
      newWidth = (targetHeight * srcAspect).round();
    }
    
    // Önce yeniden boyutlandır
    final resized = img.copyResize(src, width: newWidth, height: newHeight);
    
    // Hedef boyutta beyaz bir canvas oluştur
    final canvas = img.Image(width: targetWidth, height: targetHeight);
    img.fill(canvas, color: img.ColorRgb8(128, 128, 128)); // Gri arka plan
    
    // Resmi ortala
    final offsetX = (targetWidth - newWidth) ~/ 2;
    final offsetY = (targetHeight - newHeight) ~/ 2;
    
    img.compositeImage(canvas, resized, dstX: offsetX, dstY: offsetY);
    
    return canvas;
  }
  
  /// Softmax fonksiyonu - Numerik kararlılık için iyileştirilmiş
  List<double> _applySoftmax(List<double> logits) {
    if (logits.isEmpty) return [];
    
    // Numerik kararlılık için max değeri çıkar
    final maxLogit = logits.reduce((a, b) => a > b ? a : b);
    
    // Exp değerlerini hesapla
    final expValues = logits.map((x) {
      final expVal = math.exp(x - maxLogit);
      return expVal.isFinite ? expVal : 0.0; // NaN/Infinity kontrolü
    }).toList();
    
    // Sum hesapla
    final sumExp = expValues.reduce((a, b) => a + b);
    
    // Division by zero kontrolü
    if (sumExp == 0.0) {
      return List.filled(logits.length, 1.0 / logits.length);
    }
    
    // Normalize et
    return expValues.map((x) => x / sumExp).toList();
  }
  
  /// En yüksek güven skoruna sahip sınıfı döndürür
  String getPredictedClass(Map<String, double> results) {
    if (results.isEmpty) return 'Bilinmeyen';
    
    double maxConfidence = 0.0;
    String predictedClass = 'Bilinmeyen';
    
    results.forEach((className, confidence) {
      if (confidence > maxConfidence) {
        maxConfidence = confidence;
        predictedClass = className;
      }
    });
    
    return predictedClass;
  }
  
  /// En yüksek güven skorunu döndürür
  double getMaxConfidence(Map<String, double> results) {
    if (results.isEmpty) return 0.0;
    return results.values.reduce((a, b) => a > b ? a : b);
  }
  
  /// Güven skorunun yeterli olup olmadığını kontrol eder
  bool isConfidenceAcceptable(Map<String, double> results) {
    return getMaxConfidence(results) > _confidenceThreshold;
  }
  
  /// Alternatif tahmin metodunu döndürür (en yüksek 3 sonuç)
  List<MapEntry<String, double>> getTopPredictions(Map<String, double> results, {int topK = 3}) {
    final sortedResults = results.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedResults.take(topK).toList();
  }
  
  /// Model yüklü mü kontrol eder
  bool get isModelLoaded => _interpreter != null;
  
  /// Etiketleri döndürür
  List<String> get labels => List.from(_labels);
  
  /// Test için manuel tahmin fonksiyonu - Farklı ön işleme yöntemlerini dener
  Future<void> testDifferentPreprocessingMethods(File imageFile) async {
    if (_interpreter == null) {
      print('Model yüklenmemiş!');
      return;
    }
    
    print('\n=== FARKLI ÖN İŞLEME YÖNTEMLERİ TESTİ ===');
    
    final bytes = await imageFile.readAsBytes();
    img.Image? originalImage = img.decodeImage(bytes);
    
    if (originalImage == null) {
      print('Görüntü yüklenemedi!');
      return;
    }
    
    // Method 1: Center Crop + Resize
    await _testPreprocessingMethod(
      originalImage, 
      'Center Crop + Resize',
      (img.Image src) => _centerCropAndResize(src, inputSize, inputSize)
    );
    
    // Method 2: Padding + Resize  
    await _testPreprocessingMethod(
      originalImage,
      'Padding + Resize', 
      (img.Image src) => _resizeImageWithPadding(src, inputSize, inputSize)
    );
    
    // Method 3: Direct Resize
    await _testPreprocessingMethod(
      originalImage,
      'Direct Resize',
      (img.Image src) => img.copyResize(src, width: inputSize, height: inputSize)
    );
    
    print('=== TEST BİTTİ ===\n');
  }
  
  /// Belirli bir ön işleme yöntemini test eder
  Future<void> _testPreprocessingMethod(
    img.Image originalImage, 
    String methodName,
    img.Image Function(img.Image) preprocessFunc
  ) async {
    try {
      print('\n--- $methodName ---');
      
      // Görüntüyü işle
      final processedImage = preprocessFunc(originalImage);
      
      // Float32List'e çevir
      final input = Float32List(inputSize * inputSize * numChannels);
      int bufferIndex = 0;
      
      for (int y = 0; y < inputSize; y++) {
        for (int x = 0; x < inputSize; x++) {
          final pixel = processedImage.getPixel(x, y);
          input[bufferIndex++] = pixel.r / 255.0;
          input[bufferIndex++] = pixel.g / 255.0;
          input[bufferIndex++] = pixel.b / 255.0;
        }
      }
      
      // Model ile tahmin yap
      final outputShape = _interpreter!.getOutputTensor(0).shape;
      final output = List.filled(outputShape[1], 0.0).reshape([1, outputShape[1]]);
      final reshapedInput = input.reshape([1, inputSize, inputSize, numChannels]);
      
      _interpreter!.run(reshapedInput, output);
      
      final rawResults = output[0] as List<double>;
      final softmaxResults = _applySoftmax(rawResults);
      
      // Sonuçları göster
      final results = <String, double>{};
      for (int i = 0; i < _labels.length && i < softmaxResults.length; i++) {
        results[_labels[i]] = softmaxResults[i];
      }
      
      final sortedResults = results.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      print('En yüksek 3 sonuç:');
      for (int i = 0; i < math.min(3, sortedResults.length); i++) {
        print('  ${sortedResults[i].key}: ${(sortedResults[i].value * 100).toStringAsFixed(2)}%');
      }
      
    } catch (e) {
      print('$methodName hatası: $e');
    }
  }
  
  /// Güven eşiği değerini döndürür
  double get confidenceThreshold => _confidenceThreshold;
}