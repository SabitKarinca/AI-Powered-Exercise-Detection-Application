// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'exercise_classifier.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Egzersiz Uygulaması',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'Roboto',
      ),
      home: const MyHomePage(title: 'Egzersiz Uygulaması'),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> 
    with TickerProviderStateMixin {
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  ExerciseClassifier _classifier = ExerciseClassifier();
  
  String _detectedExercise = '';
  bool _isValidImage = true;
  // ignore: unused_field
  String _errorMessage = '';
  bool _showResult = false;
  bool _isLoading = false;
  bool _modelLoaded = false;
  Map<String, double> _results = {};
  List<MapEntry<String, double>> _topPredictions = [];
  
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late AnimationController _resultController;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _resultAnimation;

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _resultController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.elasticOut));
    
    _resultAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _resultController, curve: Curves.bounceOut),
    );
    
    _slideController.forward();
    
    // Model yükleme
    _loadModel();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    _resultController.dispose();
    _classifier.dispose();
    super.dispose();
  }

  Future<void> _loadModel() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      await _classifier.loadModel();
      setState(() {
        _modelLoaded = true;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading model: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Model yüklenirken hata oluştu: $e';
      });
    }
  }

  Future<void> _classifyImage() async {
    if (_selectedImage == null || !_modelLoaded) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final results = await _classifier.classifyImage(_selectedImage!);
      final predictedClass = _classifier.getPredictedClass(results);
      final maxConfidence = _classifier.getMaxConfidence(results);
      
      // En iyi 3 tahmini manuel olarak alalım
      final sortedResults = results.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final topPredictions = sortedResults.take(3).toList();
      
      setState(() {
        _results = results;
        _detectedExercise = predictedClass;
        _topPredictions = topPredictions;
        _isLoading = false;
        _showResult = true;
        
        // Basitleştirilmiş güven skoruna göre geçerlilik kontrolü
        // Eşiği 0.3'e düşürdük (daha esnek)
        if (maxConfidence > 0.3) {
          _isValidImage = true;
          _errorMessage = '';
        } else {
          _isValidImage = false;
          _errorMessage = 'Düşük güven skoru (${(maxConfidence * 100).toStringAsFixed(1)}%). '
              'Daha net bir görüntü veya farklı açı deneyin.';
        }
      });
      
      _resultController.forward();
    } catch (e) {
      print('Error classifying image: $e');
      setState(() {
        _isLoading = false;
        _isValidImage = false;
        _errorMessage = 'Görüntü analiz edilirken hata oluştu: $e';
        _showResult = true;
      });
      _resultController.forward();
    }
  }

  Future<void> _pickImage() async {
    if (!_modelLoaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Model henüz yükleniyor, lütfen bekleyin...')),
      );
      return;
    }
    
    setState(() {
      _showResult = false;
    });
    
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85, // Kaliteyi biraz düşürüyoruz
    );
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
      await _classifyImage();
    }
  }

  Future<void> _pickImageFromCamera() async {
    if (!_modelLoaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Model henüz yükleniyor, lütfen bekleyin...')),
      );
      return;
    }
    
    setState(() {
      _showResult = false;
    });
    
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
      await _classifyImage();
    }
  }

  void _resetApp() {
    setState(() {
      _selectedImage = null;
      _showResult = false;
      _detectedExercise = '';
      _errorMessage = '';
      _isValidImage = true;
      _results = {};
      _topPredictions = [];
    });
    _resultController.reset();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF00b4db),
              const Color(0xFF0083b0),
              const Color(0xFF006b8a),
              const Color(0xFF004d5c),
            ],
            stops: const [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: SlideTransition(
            position: _slideAnimation,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: _showResult ? _buildResultScreen() : _buildMainScreen(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainScreen() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        // Başlık
        Container(
          margin: const EdgeInsets.only(bottom: 60),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 25,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.fitness_center_rounded,
                  size: 60,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 25),
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Colors.white, Colors.white70],
                ).createShader(bounds),
                child: const Text(
                  'Egzersiz Uygulaması',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 2.0,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _modelLoaded 
                    ? 'Egzersiz pozunuzu analiz edelim'
                    : 'Model yükleniyor...',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white.withOpacity(0.9),
                  fontWeight: FontWeight.w300,
                ),
              ),
              if (_modelLoaded) ...[
                const SizedBox(height: 8),
                Text(
                  'Güven eşiği: 30%', // Sabit değer olarak gösterelim
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.7),
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ],
            ],
          ),
        ),
        
        // Placeholder alanı
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: Container(
                height: 200,
                width: 200,
                margin: const EdgeInsets.only(bottom: 80),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.2),
                      Colors.white.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.4),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.camera_alt_rounded,
                  size: 80,
                  color: Colors.white70,
                ),
              ),
            );
          },
        ),
        
        // Butonlar veya loading
        _isLoading
            ? Container(
                padding: const EdgeInsets.all(30),
                child: Column(
                  children: [
                    const CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 4,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _modelLoaded 
                          ? 'Egzersiz analiz ediliyor...'
                          : 'Model yükleniyor...',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildAnimatedButton(
                    onPressed: _modelLoaded ? _pickImage : null,
                    icon: Icons.photo_library_rounded,
                    label: 'Galeri',
                    color: const Color(0xFF4dd0e1),
                  ),
                  _buildAnimatedButton(
                    onPressed: _modelLoaded ? _pickImageFromCamera : null,
                    icon: Icons.camera_alt_rounded,
                    label: 'Kamera',
                    color: const Color(0xFF26c6da),
                  ),
                ],
              ),
      ],
    );
  }

  Widget _buildResultScreen() {
    return FadeTransition(
      opacity: _resultAnimation,
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Sonuç başlığı
            Container(
              margin: const EdgeInsets.only(bottom: 50),
              child: const Text(
                'Analiz Sonucu',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.5,
                ),
              ),
            ),

            // Seçilen görüntüyü göster
            if (_selectedImage != null) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 30),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.file(
                    _selectedImage!,
                    height: 200,
                    width: 200,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ],

            // Sonuç kartı
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(30),
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.25),
                    Colors.white.withOpacity(0.15),
                  ],
                ),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 30,
                    offset: const Offset(0, 15),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // İkon
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _isValidImage 
                          ? Colors.green.withOpacity(0.8)
                          : Colors.orange.withOpacity(0.8), // Kırmızı yerine turuncu
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (_isValidImage ? Colors.green : Colors.orange)
                              .withOpacity(0.4),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Icon(
                      _isValidImage 
                          ? Icons.check_circle_rounded
                          : Icons.warning_rounded, // error yerine warning
                      color: Colors.white,
                      size: 50,
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Sonuç metni
                  Text(
                    _isValidImage
                        ? 'Yapılan hareket: $_detectedExercise'
                        : 'Belirsiz Sonuç',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 15),
                  
                  // Güven skoru ve detaylar
                  if (_isValidImage && _results.isNotEmpty) ...[
                    Text(
                      'Güven skoru: ${(_classifier.getMaxConfidence(_results) * 100).toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Tebrikler! Egzersiz pozunuz doğru tespit edildi.',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ] else ...[
                    // Hata durumunda en iyi tahminleri göster
                    if (_topPredictions.isNotEmpty) ...[
                      Text(
                        'En yakın tahminler:',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      ..._topPredictions.take(3).map((prediction) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          '• ${prediction.key}: ${(prediction.value * 100).toStringAsFixed(1)}%',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      // ignore: unnecessary_to_list_in_spreads
                      )).toList(),
                      const SizedBox(height: 15),
                      Text(
                        'Daha net bir görüntü veya farklı açı deneyin.',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ],
              ),
            ),
            
            const SizedBox(height: 60),
            
            // Tekrar dene butonu
            GestureDetector(
              onTap: _resetApp,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF4dd0e1),
                      Color(0xFF26c6da),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF26c6da).withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.refresh_rounded,
                      size: 24,
                      color: Colors.white,
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Tekrar Dene',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedButton({
    required VoidCallback? onPressed,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    final isEnabled = onPressed != null;
    
    return GestureDetector(
      onTap: onPressed,
      child: Opacity(
        opacity: isEnabled ? 1.0 : 0.5,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color, color.withOpacity(0.8)],
            ),
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}