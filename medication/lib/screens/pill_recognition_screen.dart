import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:medication/services/pill_recognition_service.dart';

class PillRecognitionScreen extends StatefulWidget {
  const PillRecognitionScreen({super.key});

  @override
  State<PillRecognitionScreen> createState() => _PillRecognitionScreenState();
}

class _PillRecognitionScreenState extends State<PillRecognitionScreen> {
  File? _selectedImage;
  PillRecognitionResult? _result;
  bool _loading = false;
  String? _error;
  final ImagePicker _picker = ImagePicker();
  late PillRecognitionService _pillService;

  @override
  void initState() {
    super.initState();
    _pillService = PillRecognitionService();
    _initializeModel();
  }

  Future<void> _initializeModel() async {
    try {
      await _pillService.initialize();
      setState(() => _error = null);
    } catch (e) {
      setState(() => _error = 'Failed to load model: $e');
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, maxWidth: 600);
    if (picked != null) {
      setState(() {
        _selectedImage = File(picked.path);
        _result = null;
        _error = null;
      });
    }
  }

  Future<void> _runModelOnImage() async {
    if (_selectedImage == null) return;

    setState(() => _loading = true);

    try {
      final result = await _pillService.recognizePill(_selectedImage!);
      setState(() {
        _result = result;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _result = null;
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _pillService.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3FF),
      body: CustomScrollView(
        slivers: [
          // ── Modern Header ──
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.only(bottom: 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pill Scanner',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Identify your medications using AI',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Model Status / Error
                if (!_pillService.isInitialized && _error == null)
                  _buildStatusCard('Loading AI Model...', Icons.info_outline_rounded, Colors.orange),
                if (_error != null)
                  _buildStatusCard(_error!, Icons.error_outline_rounded, Colors.red),

                const SizedBox(height: 8),

                // Image Selection Area
                Center(
                  child: Container(
                    height: 280,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        )
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: _selectedImage != null
                          ? Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.file(_selectedImage!, fit: BoxFit.cover),
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [Colors.transparent, Colors.black.withOpacity(0.4)],
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 16,
                                  right: 16,
                                  child: FloatingActionButton.small(
                                    onPressed: () => setState(() {
                                      _selectedImage = null;
                                      _result = null;
                                    }),
                                    backgroundColor: Colors.white,
                                    child: const Icon(Icons.close_rounded, color: Colors.redAccent),
                                  ),
                                )
                              ],
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF5F3FF),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.add_a_photo_rounded, size: 48, color: Color(0xFF7C3AED)),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Take a photo of the pill',
                                  style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E)),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Ensure good lighting and focus',
                                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Picker Buttons
                Row(
                  children: [
                    Expanded(
                      child: _buildPickerButton(
                        label: 'Camera',
                        icon: Icons.camera_alt_rounded,
                        onTap: () => _pickImage(ImageSource.camera),
                        color: const Color(0xFF7C3AED),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildPickerButton(
                        label: 'Gallery',
                        icon: Icons.photo_library_rounded,
                        onTap: () => _pickImage(ImageSource.gallery),
                        color: const Color(0xFF0EA5E9),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Recognition Action
                if (_selectedImage != null && _result == null)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C3AED),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: _loading || !_pillService.isInitialized ? null : _runModelOnImage,
                    child: _loading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.auto_awesome_rounded),
                              SizedBox(width: 12),
                              Text('Start Recognition', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                            ],
                          ),
                  ),

                // Results Hero
                if (_result != null) ...[
                  const Text(
                    "Analysis Results",
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E)),
                  ),
                  const SizedBox(height: 16),
                  _buildResultHero(_result!.topPrediction),
                  const SizedBox(height: 24),
                  const Text(
                    "Alternative Matches",
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E)),
                  ),
                  const SizedBox(height: 16),
                  ..._result!.topThree.skip(1).map((p) => _buildResultTile(p)),
                ],

                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(String message, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(child: Text(message, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13))),
        ],
      ),
    );
  }

  Widget _buildPickerButton({required String label, required IconData icon, required VoidCallback onTap, required Color color}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(fontWeight: FontWeight.w700, color: color, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildResultHero(PillPrediction pred) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)]),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                'TOP MATCH'.toUpperCase(),
                style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.2),
              ),
              const Spacer(),
              Text(
                pred.percentage,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            pred.medicationName,
            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: pred.confidence,
              minHeight: 8,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultTile(PillPrediction pred) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F3FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.medication_rounded, color: Color(0xFF7C3AED), size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pred.medicationName,
                  style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E), fontSize: 15),
                ),
                Text(
                  '${pred.percentage} Match Confidence',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: Colors.grey.shade300),
        ],
      ),
    );
  }
}
