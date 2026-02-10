import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nonvis/screens/home.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileSetupPage extends StatefulWidget {
  const ProfileSetupPage({Key? key}) : super(key: key);

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  String _selectedLanguage = 'Français';

  final _nameController = TextEditingController();
  DateTime? _birthDate;
  String? _selectedRelationshipStatus;

  DateTime? _lastPeriodDate;
  int _cycleDuration = 28;
  int _periodDuration = 5;
  bool _irregularCycle = false;

  final List<String> _selectedGoals = [];

  bool _periodReminder = true;
  bool _ovulationReminder = true;
  bool _contraceptionReminder = false;
  bool _healthTips = true;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadUserPreferences();
  }

  void _loadUserPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedLanguage = prefs.getString('selectedLanguage') ?? 'Français';
    });
  }

  void _nextStep() {
    if (_currentStep < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeSetup();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _completeSetup() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('isProfileCompleted', true);
    await prefs.setBool('isFirstLaunch', false);
    await prefs.setString('userName', _nameController.text);
    await prefs.setString('selectedLanguage', _selectedLanguage);

    if (prefs.getString('userToken') == null) {
      await prefs.setString(
          'userToken', 'user_token_${DateTime.now().millisecondsSinceEpoch}');
    }

    if (_lastPeriodDate != null) {
      await prefs.setString('lastPeriodDate', _lastPeriodDate!.toIso8601String());
    }
    await prefs.setInt('cycleDuration', _cycleDuration);
    await prefs.setInt('periodDuration', _periodDuration);

    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => HomePage()));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            const Text(
              'Profil configuré avec succès ! 🎉',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  bool _canProceed() {
    switch (_currentStep) {
      case 0:
        return _nameController.text.length >= 3 &&
            _birthDate != null &&
            _selectedRelationshipStatus != null;
      case 1:
        return _lastPeriodDate != null || _irregularCycle;
      case 2:
        return _selectedGoals.isNotEmpty;
      case 3:
        return true;
      default:
        return false;
    }
  }

  Future<void> _selectBirthDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 20)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      locale: const Locale('fr', 'FR'),
    );
    if (picked != null && picked != _birthDate) {
      setState(() {
        _birthDate = picked;
      });
    }
  }

  Future<void> _selectLastPeriodDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 90)),
      lastDate: DateTime.now(),
      locale: const Locale('fr', 'FR'),
    );
    if (picked != null && picked != _lastPeriodDate) {
      setState(() {
        _lastPeriodDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildProgressBar(),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) {
                  setState(() => _currentStep = index);
                },
                children: [
                  _buildStep1BasicInfo(),
                  _buildStep2CycleInfo(),
                  _buildStep3Goals(),
                  _buildStep4Preferences(),
                ],
              ),
            ),
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          if (_currentStep > 0)
            IconButton(
              onPressed: _previousStep,
              icon: const Icon(Icons.arrow_back, color: Color(0xFF4A148C)),
            )
          else
            const SizedBox(width: 48),
          Expanded(
            child: Column(
              children: [
                Text(
                  'Configuration du profil',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4A148C),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Étape ${_currentStep + 1} sur 4',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => debugPrint('Audio aide'),
            icon: const Icon(Icons.volume_up, color: Color(0xFFE91E63)),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: List.generate(4, (index) {
          final isCompleted = index < _currentStep;
          final isCurrent = index == _currentStep;

          return Expanded(
            child: Container(
              height: 4,
              margin: EdgeInsets.only(right: index < 3 ? 8 : 0),
              decoration: BoxDecoration(
                color: isCompleted || isCurrent
                    ? const Color(0xFFE91E63)
                    : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStep1BasicInfo() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepTitle('Parle-nous de toi', '👋'),
          const SizedBox(height: 32),

          // Nom complet
          _buildLabel('Ton nom complet'),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              hintText: 'Ex: Marie Dupont',
              prefixIcon: const Icon(Icons.person_outline),
              filled: true,
              fillColor: Colors.grey[50],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: Color(0xFFE91E63), width: 2),
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),

          const SizedBox(height: 24),

          _buildLabel('Ta date de naissance'),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _selectBirthDate,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: [
                  const Icon(Icons.cake_outlined, color: Colors.grey),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _birthDate == null
                          ? 'Sélectionne ta date de naissance'
                          : '${_birthDate!.day}/${_birthDate!.month}/${_birthDate!.year}',
                      style: TextStyle(
                        fontSize: 16,
                        color:
                            _birthDate == null ? Colors.grey : Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          _buildLabel('Ton statut relationnel'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              'Célibataire',
              'En couple',
              'Mariée',
              'Autre',
            ].map((status) {
              final isSelected = _selectedRelationshipStatus == status;
              return GestureDetector(
                onTap: () =>
                    setState(() => _selectedRelationshipStatus = status),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color:
                        isSelected ? const Color(0xFFE91E63) : Colors.grey[100],
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFFE91E63)
                          : Colors.grey[300]!,
                      width: 2,
                    ),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFE91E63).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.lock_outline,
                    color: Color(0xFFE91E63), size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Tes informations sont privées et sécurisées',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
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

  Widget _buildStep2CycleInfo() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepTitle('Parlons de ton cycle', '🌸'),
          const SizedBox(height: 32),

          _buildLabel('Date de tes dernières règles'),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _selectLastPeriodDate,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _lastPeriodDate != null
                      ? const Color(0xFFE91E63)
                      : Colors.grey[300]!,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    color: _lastPeriodDate != null
                        ? const Color(0xFFE91E63)
                        : Colors.grey,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _lastPeriodDate == null
                          ? 'Sélectionne la date'
                          : '${_lastPeriodDate!.day}/${_lastPeriodDate!.month}/${_lastPeriodDate!.year}',
                      style: TextStyle(
                        fontSize: 16,
                        color: _lastPeriodDate == null
                            ? Colors.grey
                            : Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          _buildLabel('Durée moyenne de ton cycle'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$_cycleDuration jours',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE91E63),
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        if (_cycleDuration > 21) {
                          setState(() => _cycleDuration--);
                        }
                      },
                      icon: const Icon(Icons.remove_circle_outline),
                      color: const Color(0xFFE91E63),
                    ),
                    IconButton(
                      onPressed: () {
                        if (_cycleDuration < 45) {
                          setState(() => _cycleDuration++);
                        }
                      },
                      icon: const Icon(Icons.add_circle_outline),
                      color: const Color(0xFFE91E63),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          _buildLabel('Durée moyenne de tes règles'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$_periodDuration jours',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE91E63),
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        if (_periodDuration > 2) {
                          setState(() => _periodDuration--);
                        }
                      },
                      icon: const Icon(Icons.remove_circle_outline),
                      color: const Color(0xFFE91E63),
                    ),
                    IconButton(
                      onPressed: () {
                        if (_periodDuration < 10) {
                          setState(() => _periodDuration++);
                        }
                      },
                      icon: const Icon(Icons.add_circle_outline),
                      color: const Color(0xFFE91E63),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          CheckboxListTile(
            value: _irregularCycle,
            onChanged: (value) =>
                setState(() => _irregularCycle = value ?? false),
            title: const Text(
              'Mon cycle est irrégulier',
              style: TextStyle(fontSize: 15),
            ),
            activeColor: const Color(0xFFE91E63),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            controlAffinity: ListTileControlAffinity.leading,
          ),

          if (_irregularCycle) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      color: Colors.orange, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Pas de souci ! NONVI s\'adaptera à ton cycle',
                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStep3Goals() {
    final goals = [
      {
        'icon': '🩸',
        'title': 'Suivre mon cycle',
        'subtitle': 'Prédire mes règles'
      },
      {
        'icon': '🤰',
        'title': 'Planifier une grossesse',
        'subtitle': 'Identifier ma période fertile'
      },
      {
        'icon': '💊',
        'title': 'Éviter une grossesse',
        'subtitle': 'Contraception naturelle'
      },
      {
        'icon': '📊',
        'title': 'Mieux me connaître',
        'subtitle': 'Comprendre mon corps'
      },
      {
        'icon': '🏥',
        'title': 'Suivre ma santé',
        'subtitle': 'Symptômes & bien-être'
      },
      {
        'icon': '🌡️',
        'title': 'Gérer mes symptômes',
        'subtitle': 'Douleurs & humeurs'
      },
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepTitle('Tes objectifs', '🎯'),
          const SizedBox(height: 8),
          Text(
            'Choisis au moins un objectif (plusieurs possibles)',
            style: TextStyle(fontSize: 15, color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          ...goals.map((goal) {
            final isSelected = _selectedGoals.contains(goal['title']);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedGoals.remove(goal['title']);
                    } else {
                      _selectedGoals.add(goal['title'] as String);
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFE91E63).withOpacity(0.1)
                        : Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFFE91E63)
                          : Colors.grey[300]!,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFFE91E63)
                                : Colors.grey[300]!,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            goal['icon'] as String,
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              goal['title'] as String,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? const Color(0xFFE91E63)
                                    : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              goal['subtitle'] as String,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        const Icon(
                          Icons.check_circle,
                          color: Color(0xFFE91E63),
                          size: 28,
                        ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildStep4Preferences() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepTitle('Personnalise tes rappels', '🔔'),
          const SizedBox(height: 24),
          _buildReminderTile(
            icon: Icons.water_drop,
            title: 'Rappel des règles',
            subtitle: '2 jours avant',
            value: _periodReminder,
            onChanged: (value) => setState(() => _periodReminder = value),
          ),
          _buildReminderTile(
            icon: Icons.favorite,
            title: 'Rappel d\'ovulation',
            subtitle: 'Période fertile',
            value: _ovulationReminder,
            onChanged: (value) => setState(() => _ovulationReminder = value),
          ),
          _buildReminderTile(
            icon: Icons.medication,
            title: 'Rappel contraception',
            subtitle: 'Pilule quotidienne',
            value: _contraceptionReminder,
            onChanged: (value) =>
                setState(() => _contraceptionReminder = value),
          ),
          _buildReminderTile(
            icon: Icons.lightbulb_outline,
            title: 'Conseils santé',
            subtitle: 'Tips quotidiens',
            value: _healthTips,
            onChanged: (value) => setState(() => _healthTips = value),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFE91E63).withOpacity(0.1),
                  const Color(0xFF4A148C).withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.settings_outlined, color: Color(0xFFE91E63)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Tu pourras modifier ces paramètres à tout moment',
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReminderTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: SwitchListTile(
          value: value,
          onChanged: onChanged,
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
          secondary: Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: value
                  ? const Color(0xFFE91E63).withOpacity(0.1)
                  : Colors.grey[200],
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: value ? const Color(0xFFE91E63) : Colors.grey,
            ),
          ),
          activeColor: const Color(0xFFE91E63),
        ),
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousStep,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: Color(0xFFE91E63), width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Retour',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFE91E63),
                  ),
                ),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _canProceed() ? _nextStep : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE91E63),
                disabledBackgroundColor: Colors.grey[300],
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
              child: Text(
                _currentStep == 3 ? 'Terminer' : 'Suivant',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepTitle(String title, String emoji) {
    return Row(
      children: [
        Text(
          emoji,
          style: const TextStyle(fontSize: 32),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4A148C),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String label) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF4A148C),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: () => debugPrint('Audio: $label'),
          icon: const Icon(Icons.volume_up, size: 18, color: Color(0xFFE91E63)),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }
}
