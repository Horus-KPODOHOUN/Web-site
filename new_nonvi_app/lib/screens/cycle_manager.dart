import 'dart:math';

import 'package:flutter/material.dart';
import 'package:nonvis/config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CycleManager extends ChangeNotifier {
  static final CycleManager _instance = CycleManager._internal();
  factory CycleManager() => _instance;
  CycleManager._internal();

  final _secureStorage = const FlutterSecureStorage();

  String _userName = 'Utilisateur';
  String _selectedLanguage = 'Français';
  bool _notificationsEnabled = true;
  bool _isDarkMode = false;

  DateTime? _lastPeriodDate;
  int _cycleDuration = 28;
  int _periodDuration = 5;
  bool _isIrregularCycle = false;
  
  int _currentDay = 1;
  DateTime? _nextPeriod;
  String _cyclePhase = 'Phase folliculaire';
  DateTime? _nextOvulation;
  DateTime? _fertilityWindowStart;
  DateTime? _fertilityWindowEnd;
  int _daysUntilPeriod = 0;
  
  List<DateTime> _predictedPeriods = [];
  List<DateTime> _fertileDays = [];
  List<DateTime> _currentPeriodDays = [];
  List<CycleHistory> _cycleHistory = [];
  
  double _predictionConfidence = 0.0; // 0-1
  Map<DateTime, double> _periodProbabilities = {}; // Date -> probabilité
  
  bool _isSyncing = false;
  bool _isRefreshing = false;
  DateTime? _lastSync;
  String? _lastError;

  String get userName => _userName;
  String get selectedLanguage => _selectedLanguage;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get isDarkMode => _isDarkMode;
  DateTime? get lastPeriodDate => _lastPeriodDate;
  int get cycleDuration => _cycleDuration;
  int get periodDuration => _periodDuration;
  bool get isIrregularCycle => _isIrregularCycle;
  int get currentDay => _currentDay;
  DateTime? get nextPeriod => _nextPeriod;
  String get cyclePhase => _cyclePhase;
  DateTime? get nextOvulation => _nextOvulation;
  DateTime? get fertilityWindowStart => _fertilityWindowStart;
  DateTime? get fertilityWindowEnd => _fertilityWindowEnd;
  int get daysUntilPeriod => _daysUntilPeriod;
  List<DateTime> get predictedPeriods => _predictedPeriods;
  List<DateTime> get fertileDays => _fertileDays;
  List<DateTime> get currentPeriodDays => _currentPeriodDays;
  List<CycleHistory> get cycleHistory => _cycleHistory;
  double get predictionConfidence => _predictionConfidence;
  bool get isSyncing => _isSyncing;
  bool get isRefreshing => _isRefreshing;
  DateTime? get lastSync => _lastSync;
  String? get lastError => _lastError;

  Future<void> initialize() async {
    try {
      await _loadLocalData();
      await syncWithAPI();
    } catch (e) {
      debugPrint('❌ Erreur initialize: $e');
      _lastError = e.toString();
    }
  }

  Future<void> refreshData() async {
    if (_isRefreshing || _isSyncing) return;
    
    try {
      _isRefreshing = true;
      _lastError = null;
      notifyListeners();

      await syncWithAPI();
      
      await _recalculateAllCycleData();
      
      await _improvePredictin();
      
      debugPrint('✅ Rafraîchissement terminé');
      
    } catch (e) {
      debugPrint('❌ Erreur refresh: $e');
      _lastError = 'Erreur de rafraîchissement: $e';
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }

  Future<void> _loadLocalData() async {
    final prefs = await SharedPreferences.getInstance();
    
    _userName = prefs.getString('userName') ?? 'Utilisateur';
    _selectedLanguage = prefs.getString('selectedLanguage') ?? 'Français';
    _notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    
    final lastPeriodString = prefs.getString('lastPeriodDate');
    if (lastPeriodString != null) {
      _lastPeriodDate = DateTime.parse(lastPeriodString);
    }
    
    _cycleDuration = prefs.getInt('cycleDuration') ?? 28;
    _periodDuration = prefs.getInt('periodDuration') ?? 5;
    _isIrregularCycle = prefs.getBool('isIrregularCycle') ?? false;
    
    final historyJson = prefs.getString('cycleHistory');
    if (historyJson != null) {
      try {
        final List<dynamic> historyList = jsonDecode(historyJson);
        _cycleHistory = historyList
            .map((item) => CycleHistory.fromJson(item))
            .toList();
      } catch (e) {
        debugPrint('Erreur chargement historique: $e');
      }
    }
    
    await _recalculateAllCycleData();
    notifyListeners();
  }

  Future<void> syncWithAPI() async {
    if (_isSyncing) return;
    
    try {
      _isSyncing = true;
      notifyListeners();

      final token = await _secureStorage.read(key: 'userToken');
      if (token == null || token.isEmpty) {
        debugPrint(' Pas de token - mode hors ligne');
        return;
      }

      final response = await http.get(
        Uri.parse('$API_BASE_URL/cycle/current-data'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['success'] && data['cycleData'] != null) {
          final cycleData = data['cycleData'];
          
          _cycleDuration = cycleData['cycleDuration'] ?? 28;
          _periodDuration = cycleData['periodDuration'] ?? 5;
          _currentDay = cycleData['currentDay'] ?? 1;
          _cyclePhase = cycleData['cyclePhase'] ?? 'Phase folliculaire';
          
          if (cycleData['lastPeriodDate'] != null) {
            _lastPeriodDate = DateTime.parse(cycleData['lastPeriodDate']);
          }
          if (cycleData['nextPeriodDate'] != null) {
            _nextPeriod = DateTime.parse(cycleData['nextPeriodDate']);
          }
          if (cycleData['nextOvulationDate'] != null) {
            _nextOvulation = DateTime.parse(cycleData['nextOvulationDate']);
          }
          if (cycleData['fertilityWindowStart'] != null) {
            _fertilityWindowStart = DateTime.parse(cycleData['fertilityWindowStart']);
          }
          if (cycleData['fertilityWindowEnd'] != null) {
            _fertilityWindowEnd = DateTime.parse(cycleData['fertilityWindowEnd']);
          }

          if (cycleData['predictedPeriods'] != null) {
            _predictedPeriods = (cycleData['predictedPeriods'] as List)
                .map((d) => DateTime.parse(d))
                .toList();
          }
          if (cycleData['cycleHistory'] != null) {
            _cycleHistory = (cycleData['cycleHistory'] as List)
                .map((item) => CycleHistory.fromJson(item))
                .toList();
          }

          await _saveLocalData();
          _lastSync = DateTime.now();
          
          debugPrint('✅ Synchronisation réussie');
        }
      } else {
        debugPrint('⚠️ Erreur API: ${response.statusCode}');
        _lastError = 'Erreur serveur: ${response.statusCode}';
      }
      
    } catch (e) {
      debugPrint(' Erreur sync: $e');
      _lastError = 'Erreur de connexion';
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Future<void> _saveLocalData() async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.setInt('cycleDuration', _cycleDuration);
    await prefs.setInt('periodDuration', _periodDuration);
    await prefs.setBool('isIrregularCycle', _isIrregularCycle);
    
    if (_lastPeriodDate != null) {
      await prefs.setString('lastPeriodDate', _lastPeriodDate!.toIso8601String());
    }
    
    if (_cycleHistory.isNotEmpty) {
      final historyJson = jsonEncode(
        _cycleHistory.map((h) => h.toJson()).toList()
      );
      await prefs.setString('cycleHistory', historyJson);
    }
  }

  Future<void> _recalculateAllCycleData() async {
    if (_lastPeriodDate != null) {
      _calculateCurrentDay();
      _calculateNextPeriod();
      _calculateDaysUntilPeriod();
      _calculateCyclePhase();
      _calculateOvulation();
      _calculateFertilityWindow();
      await _calculateAdvancedPredictions();
      _calculateCurrentPeriodDays();
      _calculatePredictionConfidence();
    }
  }

  void _calculateCurrentDay() {
    if (_lastPeriodDate == null) return;
    
    final today = DateTime.now();
    final daysSinceLastPeriod = today.difference(_lastPeriodDate!).inDays;
    
    _currentDay = (daysSinceLastPeriod % _cycleDuration) + 1;
    if (_currentDay <= 0) _currentDay = 1;
  }

  void _calculateNextPeriod() {
    if (_lastPeriodDate == null) return;
    
    final today = DateTime.now();
    final daysSinceLastPeriod = today.difference(_lastPeriodDate!).inDays;
    
    int avgCycle = _cycleDuration;
    if (_cycleHistory.length >= 3) {
      final recentCycles = _cycleHistory.take(6).toList();
      final sum = recentCycles.fold<int>(0, (sum, cycle) => sum + (cycle.cycleLength ?? _cycleDuration));
      avgCycle = (sum / recentCycles.length).round();
    }
    
    final cyclesPassed = (daysSinceLastPeriod / avgCycle).floor();
    _nextPeriod = _lastPeriodDate!.add(Duration(days: avgCycle * (cyclesPassed + 1)));
  }

  void _calculateDaysUntilPeriod() {
    if (_nextPeriod == null) {
      _daysUntilPeriod = 0;
      return;
    }
    
    final today = DateTime.now();
    _daysUntilPeriod = _nextPeriod!.difference(today).inDays;
  }

  void _calculateCyclePhase() {
    if (_currentDay <= _periodDuration) {
      _cyclePhase = 'Menstruation';
    } else if (_currentDay <= 13) {
      _cyclePhase = 'Phase folliculaire';
    } else if (_currentDay <= 15) {
      _cyclePhase = 'Ovulation';
    } else {
      _cyclePhase = 'Phase lutéale';
    }
  }

  void _calculateOvulation() {
    if (_lastPeriodDate == null || _nextPeriod == null) return;
    _nextOvulation = _nextPeriod!.subtract(const Duration(days: 14));
  }

  void _calculateFertilityWindow() {
    if (_nextOvulation == null) return;
    _fertilityWindowStart = _nextOvulation!.subtract(const Duration(days: 5));
    _fertilityWindowEnd = _nextOvulation!.add(const Duration(days: 1));
  }

  Future<void> _calculateAdvancedPredictions() async {
    if (_lastPeriodDate == null) return;

    _predictedPeriods.clear();
    _fertileDays.clear();
    _periodProbabilities.clear();

    final today = DateTime.now();
    final daysSinceLastPeriod = today.difference(_lastPeriodDate!).inDays;
    
    int predictedCycle = _cycleDuration;
    int cycleVariation = 2;
    
    if (_cycleHistory.length >= 3) {
      final recentCycles = _cycleHistory
          .where((c) => c.cycleLength != null)
          .take(6)
          .map((c) => c.cycleLength!)
          .toList();
      
      if (recentCycles.isNotEmpty) {
        final avg = recentCycles.reduce((a, b) => a + b) / recentCycles.length;
        predictedCycle = avg.round();
        
        final variance = recentCycles
            .map((l) => (l - avg) * (l - avg))
            .reduce((a, b) => a + b) / recentCycles.length;
cycleVariation = sqrt(variance.abs()).ceil();     
   
        if (cycleVariation < 1) cycleVariation = 1;
        if (cycleVariation > 7) cycleVariation = 7;
      }
    }

    if (_isIrregularCycle) {
      cycleVariation = (cycleVariation * 1.5).ceil();
    }

    final cyclesPassed = (daysSinceLastPeriod / predictedCycle).floor();

    for (int i = cyclesPassed; i < cyclesPassed + 6; i++) {
      final basePeriodStart = _lastPeriodDate!.add(Duration(days: predictedCycle * i));
      
      if (basePeriodStart.isAfter(today.subtract(Duration(days: _periodDuration)))) {
        _predictedPeriods.add(basePeriodStart);
        _periodProbabilities[basePeriodStart] = 1.0;
        
        for (int variation = -cycleVariation; variation <= cycleVariation; variation++) {
          if (variation == 0) continue;
          
          final variedDate = basePeriodStart.add(Duration(days: variation));
          final probability = 1.0 - (variation.abs() / (cycleVariation + 2));
          _periodProbabilities[variedDate] = probability.clamp(0.0, 1.0);
        }

        final ovulationDay = basePeriodStart.add(Duration(days: predictedCycle - 14));
        for (int j = -5; j <= 1; j++) {
          final fertileDay = ovulationDay.add(Duration(days: j));
          if (!_fertileDays.any((d) => _isSameDay(d, fertileDay))) {
            _fertileDays.add(fertileDay);
          }
        }
      }
    }
  }

  void _calculateCurrentPeriodDays() {
    if (_lastPeriodDate == null) return;

    _currentPeriodDays.clear();
    for (int i = 0; i < _periodDuration; i++) {
      _currentPeriodDays.add(_lastPeriodDate!.add(Duration(days: i)));
    }
  }

  void _calculatePredictionConfidence() {
    if (_cycleHistory.isEmpty) {
      _predictionConfidence = 0.5;
      return;
    }

    final recentCycles = _cycleHistory
        .where((c) => c.cycleLength != null)
        .take(6)
        .map((c) => c.cycleLength!)
        .toList();
    
    if (recentCycles.length < 2) {
      _predictionConfidence = 0.6;
      return;
    }

    final avg = recentCycles.reduce((a, b) => a + b) / recentCycles.length;
    final variance = recentCycles
        .map((l) => (l - avg) * (l - avg))
        .reduce((a, b) => a + b) / recentCycles.length;
final stdDev = sqrt(variance);

    if (stdDev <= 2) {
      _predictionConfidence = 1.0 - (stdDev / 10);
    } else if (stdDev <= 5) {
      _predictionConfidence = 0.9 - ((stdDev - 2) / 15);
    } else {
      _predictionConfidence = 0.7 - ((stdDev - 5) / 20);
    }

    _predictionConfidence = _predictionConfidence.clamp(0.5, 1.0);

    if (_isIrregularCycle) {
      _predictionConfidence *= 0.85;
    }

    final historyBonus = (recentCycles.length / 12).clamp(0.0, 0.1);
    _predictionConfidence = (_predictionConfidence + historyBonus).clamp(0.5, 1.0);
  }

  Future<void> _improvePredictin() async {
    if (_cycleHistory.length < 3) return;
    final recentCycles = _cycleHistory.take(12).toList();
    
    final monthlyVariations = <int, List<int>>{};
    for (var cycle in recentCycles) {
      if (cycle.startDate != null && cycle.cycleLength != null) {
        final month = cycle.startDate!.month;
        monthlyVariations.putIfAbsent(month, () => []);
        monthlyVariations[month]!.add(cycle.cycleLength!);
      }
    }

    final currentMonth = DateTime.now().month;
    if (monthlyVariations.containsKey(currentMonth) && 
        monthlyVariations[currentMonth]!.length >= 2) {
      final monthAvg = monthlyVariations[currentMonth]!.reduce((a, b) => a + b) / 
                       monthlyVariations[currentMonth]!.length;
      
      _cycleDuration = ((cycleDuration * 0.7) + (monthAvg * 0.3)).round();
    }
  }

  double getPeriodProbability(DateTime day) {
    for (final periodDay in _currentPeriodDays) {
      if (_isSameDay(day, periodDay)) return 1.0;
    }

    for (final entry in _periodProbabilities.entries) {
      if (_isSameDay(day, entry.key)) {
        return entry.value;
      }
    }

    return 0.0;
  }

  bool isPeriodDay(DateTime day) {
    return getPeriodProbability(day) >= 0.8;
  }

  bool isPredictedPeriodDay(DateTime day) {
    final probability = getPeriodProbability(day);
    return probability > 0.3 && probability < 0.8;
  }

  bool isFertileDay(DateTime day) {
    for (final fertileDay in _fertileDays) {
      if (_isSameDay(day, fertileDay)) return true;
    }
    return false;
  }

  int getDaysUntilNextPeriod() => _daysUntilPeriod;

  String getNextPeriodText() {
    if (_daysUntilPeriod == 0) return "Aujourd'hui";
    if (_daysUntilPeriod == 1) return 'Demain';
    if (_daysUntilPeriod < 0) return 'En retard de ${_daysUntilPeriod.abs()} jours';
    return 'Dans $_daysUntilPeriod jours';
  }

  String getCyclePhaseEmoji() {
    switch (_cyclePhase) {
      case 'Menstruation': return '🩸';
      case 'Phase folliculaire': return '🌸';
      case 'Ovulation': return '🥚';
      case 'Phase lutéale': return '🌙';
      default: return '📊';
    }
  }

  String getConfidenceText() {
    if (_predictionConfidence >= 0.9) return 'Très fiable';
    if (_predictionConfidence >= 0.75) return 'Fiable';
    if (_predictionConfidence >= 0.6) return 'Modérée';
    return 'Estimée';
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year && 
           date1.month == date2.month && 
           date1.day == date2.day;
  }

  Future<void> updateCycleInfo({
    DateTime? lastPeriodDate,
    int? cycleDuration,
    int? periodDuration,
    bool? isIrregular,
  }) async {
    bool hasChanges = false;

    if (lastPeriodDate != null && lastPeriodDate != _lastPeriodDate) {
      _lastPeriodDate = lastPeriodDate;
      hasChanges = true;
    }

    if (cycleDuration != null && cycleDuration != _cycleDuration) {
      _cycleDuration = cycleDuration;
      hasChanges = true;
    }

    if (periodDuration != null && periodDuration != _periodDuration) {
      _periodDuration = periodDuration;
      hasChanges = true;
    }

    if (isIrregular != null && isIrregular != _isIrregularCycle) {
      _isIrregularCycle = isIrregular;
      hasChanges = true;
    }

    if (hasChanges) {
      await _saveLocalData();
      await _recalculateAllCycleData();
      await _syncCycleUpdateToAPI(
        lastPeriodDate: lastPeriodDate,
        cycleDuration: cycleDuration,
        periodDuration: periodDuration,
      );
      notifyListeners();
    }
  }

  Future<void> _syncCycleUpdateToAPI({
    DateTime? lastPeriodDate,
    int? cycleDuration,
    int? periodDuration,
  }) async {
    try {
      final token = await _secureStorage.read(key: 'userToken');
      if (token == null) return;

      final body = <String, dynamic>{};
      if (lastPeriodDate != null) {
        body['lastPeriodDate'] = lastPeriodDate.toIso8601String().split('T')[0];
      }
      if (cycleDuration != null) body['cycleDuration'] = cycleDuration;
      if (periodDuration != null) body['periodDuration'] = periodDuration;

      await http.put(
        Uri.parse('$API_BASE_URL/cycle/update'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 10));

      debugPrint('Cycle mis à jour sur le serveur');
    } catch (e) {
      debugPrint('Erreur sync update: $e');
    }
  }

  Future<void> startPeriod({DateTime? date}) async {
    final periodDate = date ?? DateTime.now();
    await updateCycleInfo(lastPeriodDate: periodDate);
    
    try {
      final token = await _secureStorage.read(key: 'userToken');
      if (token == null) return;

      await http.post(
        Uri.parse('$API_BASE_URL/cycle/start-period'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'date': periodDate.toIso8601String().split('T')[0],
        }),
      ).timeout(const Duration(seconds: 10));

      debugPrint('✅ Règles enregistrées');
    } catch (e) {
      debugPrint('⚠️ Erreur start period: $e');
    }
  }

  Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    
    _userName = 'Utilisateur';
    _lastPeriodDate = null;
    _cycleDuration = 28;
    _periodDuration = 5;
    _currentDay = 1;
    _nextPeriod = null;
    _cyclePhase = 'Phase folliculaire';
    _cycleHistory = [];
    _predictedPeriods = [];
    _fertileDays = [];
    _currentPeriodDays = [];
    
    notifyListeners();
  }
}

/// Classe pour l'historique des cycles
class CycleHistory {
  final DateTime? startDate;
  final DateTime? endDate;
  final int? cycleLength;
  final int? periodDuration;
  final String? notes;

  CycleHistory({
    this.startDate,
    this.endDate,
    this.cycleLength,
    this.periodDuration,
    this.notes,
  });

  factory CycleHistory.fromJson(Map<String, dynamic> json) {
    return CycleHistory(
      startDate: json['start_date'] != null ? DateTime.parse(json['start_date']) : null,
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date']) : null,
      cycleLength: json['cycle_length'],
      periodDuration: json['actual_period_duration'],
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'cycle_length': cycleLength,
      'actual_period_duration': periodDuration,
      'notes': notes,
    };
  }
}