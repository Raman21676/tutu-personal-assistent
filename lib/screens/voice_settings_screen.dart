import 'package:flutter/material.dart';
import '../models/agent_model.dart';
import '../services/voice_service.dart';
import '../utils/helpers.dart';

/// Voice Settings Screen - Configure TTS settings
class VoiceSettingsScreen extends StatefulWidget {
  const VoiceSettingsScreen({super.key});

  @override
  State<VoiceSettingsScreen> createState() => _VoiceSettingsScreenState();
}

class _VoiceSettingsScreenState extends State<VoiceSettingsScreen> {
  final VoiceService _voiceService = VoiceService();
  
  double _speechRate = 0.5;
  double _pitch = 1.0;
  double _volume = 1.0;
  String _selectedLanguage = 'en-US';
  List<String> _availableLanguages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _voiceService.initialize();
    final languages = await _voiceService.getAvailableLanguages();
    setState(() {
      _availableLanguages = languages.cast<String>();
      _isLoading = false;
    });
  }

  Future<void> _previewVoice() async {
    await _voiceService.setSpeechRate(_speechRate);
    await _voiceService.setPitch(_pitch);
    await _voiceService.setVolume(_volume);
    await _voiceService.setLanguage(_selectedLanguage);
    
    await _voiceService.speak(
      'Hello! This is how I sound with the current settings. You can adjust my voice to your preference.',
      Agent(
        id: 'preview',
        name: 'Preview',
        role: 'preview',
        personality: '',
        avatar: '🎙️',
        createdAt: DateTime.now(),
        lastInteractionAt: DateTime.now(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice Settings'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Preview button
                Card(
                  child: InkWell(
                    onTap: _previewVoice,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.volume_up,
                            size: 32,
                            color: context.colors.primary,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Test Voice',
                            style: context.textTheme.titleLarge?.copyWith(
                              color: context.colors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Speech Rate
                _buildSliderSection(
                  title: 'Speech Rate',
                  subtitle: 'How fast the voice speaks',
                  value: _speechRate,
                  min: 0.1,
                  max: 1.0,
                  divisions: 9,
                  label: '${(_speechRate * 100).toInt()}%',
                  onChanged: (value) {
                    setState(() => _speechRate = value);
                    _voiceService.setSpeechRate(value);
                  },
                ),
                
                // Pitch
                _buildSliderSection(
                  title: 'Pitch',
                  subtitle: 'Voice pitch level',
                  value: _pitch,
                  min: 0.5,
                  max: 2.0,
                  divisions: 15,
                  label: '${(_pitch * 100).toInt()}%',
                  onChanged: (value) {
                    setState(() => _pitch = value);
                    _voiceService.setPitch(value);
                  },
                ),
                
                // Volume
                _buildSliderSection(
                  title: 'Volume',
                  subtitle: 'Voice volume level',
                  value: _volume,
                  min: 0.0,
                  max: 1.0,
                  divisions: 10,
                  label: '${(_volume * 100).toInt()}%',
                  onChanged: (value) {
                    setState(() => _volume = value);
                    _voiceService.setVolume(value);
                  },
                ),
                
                // Language
                const SizedBox(height: 16),
                Text(
                  'Language',
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _selectedLanguage,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.language),
                  ),
                  items: _availableLanguages.map((lang) {
                    return DropdownMenuItem(
                      value: lang,
                      child: Text(lang),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedLanguage = value);
                      _voiceService.setLanguage(value);
                    }
                  },
                ),
                
                const SizedBox(height: 32),
                
                // Info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.amber.shade700,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Voice settings are applied globally. Each agent can have its own voice gender (male/female) in their settings.',
                          style: TextStyle(
                            color: Colors.amber.shade900,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSliderSection({
    required String title,
    required String subtitle,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String label,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colors.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: context.colors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: context.colors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          label: label,
          onChanged: onChanged,
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
