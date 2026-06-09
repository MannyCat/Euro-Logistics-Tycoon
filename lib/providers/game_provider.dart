import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/game_constants.dart';
import '../models/city.dart';
import '../models/company.dart';
import '../models/truck.dart';
import '../models/driver.dart';
import '../models/contract.dart';
import '../models/warehouse.dart';
import '../models/achievement.dart';
import '../models/clan.dart';
import '../utils/pathfinder.dart';
import '../models/event_log.dart';
import '../models/garage.dart';
import '../models/clan_mission.dart';
import '../models/chat_message.dart';
import '../models/market_listing.dart';
import 'package:shared_preferences/shared_preferences.dart';

double haversineKm(double lat1, double lon1, double lat2, double lon2) {
  const R = 6371.0;
  final dLat = (lat2 - lat1) * math.pi / 180;
  final dLon = (lon2 - lon1) * math.pi / 180;
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(lat1 * math.pi / 180) * math.cos(lat2 * math.pi / 180) *
          math.sin(dLon / 2) * math.sin(dLon / 2);
  return R * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
}

class GameProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  StreamSubscription<List<Map<String, dynamic>>>? _contractSub;
  StreamSubscription<List<Map<String, dynamic>>>? _truckSub;
  Timer? _fuelPriceTimer;

  // Current company ID (cached for realtime filters)
  String? _currentCompanyId;

  // State
  List<City> _cities = [];
  Company? _company;
  List<Truck> _myTrucks = [];
  List<Driver> _myDrivers = [];
  List<Contract> _availableContracts = [];
  List<Contract> _myContracts = [];
  List<Warehouse> _myWarehouses = [];
  List<Achievement> _myAchievements = [];
  List<Map<String, dynamic>> _leaderboard = [];
  Clan? _myClan;
  List<ClanMember> _clanMembers = [];
  List<Map<String, dynamic>> _clanLeaderboard = [];
  List<EventLog> _eventLog = [];
  List<Garage> _myGarages = [];
  List<ClanMission> _clanMissions = [];
  List<ChatMessage> _clanMessages = [];
  List<MarketListing> _marketListings = [];
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _error;

  // Getters
  List<City> get cities => _cities;
  City? getCityById(int id) {
    for (final c in _cities) { if (c.id == id) return c; }
    return null;
  }
  Company? get company => _company;
  List<Truck> get myTrucks => _myTrucks;
  List<Truck> get idleTrucks => _myTrucks.where((t) => t.isIdle && t.condition >= 20).toList();
  List<Truck> get transitTrucks => _myTrucks.where((t) => t.isInTransit).toList();
  List<Driver> get myDrivers => _myDrivers;
  List<Driver> get availableDrivers => _myDrivers.where((d) => d.isAvailable).toList();
  List<Driver> get assignedDrivers => _myDrivers.where((d) => d.isAssigned).toList();
  List<Driver> get tiredDrivers => _myDrivers.where((d) => d.isTired).toList();
  double get avgSkillLevel => _myDrivers.isEmpty ? 0.0 : _myDrivers.map((d) => d.skillLevel).reduce((a, b) => a + b) / _myDrivers.length;
  List<Contract> get availableContracts => _availableContracts.where((c) => c.isAvailable && !c.isExpired).toList();
  List<Contract> get myContracts => _myContracts;
  List<Warehouse> get myWarehouses => _myWarehouses;
  List<Achievement> get myAchievements => _myAchievements;
  List<Map<String, dynamic>> get leaderboard => _leaderboard;
  Set<String> get unlockedAchievementIds => _myAchievements.map((a) => a.id).toSet();
  Clan? get myClan => _myClan;
  List<ClanMember> get clanMembers => _clanMembers;
  List<Map<String, dynamic>> get clanLeaderboard => _clanLeaderboard;
  List<EventLog> get eventLog => _eventLog;
  List<Garage> get myGarages => _myGarages;
  List<ClanMission> get clanMissions => _clanMissions;
  List<ChatMessage> get clanMessages => _clanMessages;
  List<MarketListing> get marketListings => _marketListings;
  String? get myClanRole {
    for (final m in _clanMembers) {
      if (m.companyId == _currentCompanyId) return m.role;
    }
    return null;
  }
  bool get isInClan => _myClan != null;
  bool get isClanLeader => myClanRole == 'leader';
  bool get canManageClan => myClanRole == 'leader' || myClanRole == 'officer';
  int get achievementCount => _myAchievements.length;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get error => _error;

  /// Total garage slots in a specific city (0 if no garage owned there).
  int truckSlotsInCity(int cityId) {
    final garage = _myGarages.where((g) => g.cityId == cityId).firstOrNull;
    return garage?.slots ?? 0;
  }

  /// Number of idle trucks parked at a specific city.
  int parkedTrucksInCity(int cityId) {
    return _myTrucks.where((t) => t.currentCityId == cityId && t.isIdle).length;
  }

  /// Whether there is a free slot to park another truck in the city.
  bool canParkAtCity(int cityId) {
    final slots = truckSlotsInCity(cityId);
    if (slots == 0) return false;
    return parkedTrucksInCity(cityId) < slots;
  }

  /// Whether player owns a garage in the given city.
  bool hasGarageInCity(int cityId) {
    return _myGarages.any((g) => g.cityId == cityId);
  }

  /// Get garage in a specific city, or null.
  Garage? garageInCity(int cityId) {
    return _myGarages.where((g) => g.cityId == cityId).firstOrNull;
  }

  void clearError() { _error = null; notifyListeners(); }

  // ===== COMPANY CUSTOMIZATION (stored locally) =====
  String companyIcon = 'local_shipping';
  String companyColorHex = 'F5C542';

  Future<void> loadCompanyCustomization() async {
    final prefs = await SharedPreferences.getInstance();
    companyIcon = prefs.getString('company_icon') ?? 'local_shipping';
    companyColorHex = prefs.getString('company_color_hex') ?? 'F5C542';
    notifyListeners();
  }

  Future<void> setCompanyIcon(String icon) async {
    companyIcon = icon;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('company_icon', icon);
    notifyListeners();
  }

  Future<void> setCompanyColor(String colorHex) async {
    companyColorHex = colorHex;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('company_color_hex', colorHex);
    notifyListeners();
  }

  // ===== REALTIME SUBSCRIPTIONS =====
  void startRealtime() {
    try {
      _contractSub?.cancel();
      _truckSub?.cancel();

      _contractSub = _supabase
          .from('contracts')
          .stream(primaryKey: ['id'])
          .listen((List<Map<String, dynamic>> data) {
            // Filter to only available & non-expired contracts
            _availableContracts = data
                .map<Contract>((e) => Contract.fromJson(e))
                .where((c) => c.isAvailable && !c.isExpired)
                .toList();
            notifyListeners();
          });

      _truckSub = _supabase
          .from('trucks')
          .stream(primaryKey: ['id'])
          .listen((List<Map<String, dynamic>> data) {
            // Use cached companyId instead of deriving from truck list
            // to avoid race condition when _myTrucks is empty on startup
            if (_currentCompanyId == null) return;
            _myTrucks = data
                .where((e) => e['company_id'] == _currentCompanyId)
                .map<Truck>((e) => Truck.fromJson(e))
                .toList();
            notifyListeners();
          });

      debugPrint('Realtime subscriptions started');
    } catch (e) {
      debugPrint('Realtime error: $e');
    }
  }

  void stopRealtime() {
    _contractSub?.cancel();
    _truckSub?.cancel();
    _contractSub = null;
    _truckSub = null;
  }

  // ===== LOAD =====
  Future<void> loadCities() async {
    try {
      final resp = await _supabase.from('cities').select().order('name');
      _cities = resp.map<City>((e) => City.fromJson(e)).toList();
    } catch (e) {
      _error = 'Ошибка загрузки городов';
      debugPrint('Load cities error: $e');
    }
  }

  Future<void> loadCompany(String companyId) async {
    try {
      final resp = await _supabase.from('companies').select().eq('id', companyId).maybeSingle();
      if (resp != null) {
        _company = Company.fromJson(resp);
      }
    } catch (e) {
      _error = 'Ошибка загрузки компании';
      debugPrint('Load company error: $e');
    }
  }

  Future<void> loadMyTrucks(String companyId) async {
    try {
      final resp = await _supabase.from('trucks').select().eq('company_id', companyId);
      _myTrucks = resp.map<Truck>((e) => Truck.fromJson(e)).toList();
    } catch (e) {
      _error = 'Ошибка загрузки грузовиков';
      debugPrint('Load trucks error: $e');
    }
  }

  Future<void> loadMyDrivers(String companyId) async {
    try {
      final resp = await _supabase.from('drivers').select().eq('company_id', companyId);
      _myDrivers = resp.map<Driver>((e) => Driver.fromJson(e)).toList();
    } catch (e) {
      _error = 'Ошибка загрузки водителей';
      debugPrint('Load drivers error: $e');
    }
  }

  Future<void> loadContracts() async {
    try {
      final resp = await _supabase.from('contracts')
          .select()
          .eq('status', 'available')
          .gte('expires_at', DateTime.now().toUtc().toIso8601String())
          .order('reward', ascending: false)
          .limit(50);
      _availableContracts = resp.map<Contract>((e) => Contract.fromJson(e)).toList();
    } catch (e) {
      _error = 'Ошибка загрузки контрактов';
      debugPrint('Load contracts error: $e');
    }
  }

  Future<void> loadMyContracts(String companyId) async {
    try {
      final resp = await _supabase.from('contracts')
          .select()
          .eq('assigned_company_id', companyId)
          .order('created_at', ascending: false)
          .limit(30);
      _myContracts = resp.map<Contract>((e) => Contract.fromJson(e)).toList();
    } catch (e) {
      _error = 'Ошибка загрузки моих контрактов';
      debugPrint('Load my contracts error: $e');
    }
  }

  Future<void> loadMyWarehouses(String companyId) async {
    try {
      final resp = await _supabase.from('warehouses').select().eq('company_id', companyId);
      _myWarehouses = resp.map<Warehouse>((e) => Warehouse.fromJson(e)).toList();
    } catch (e) {
      _error = 'Ошибка загрузки складов';
      debugPrint('Load warehouses error: $e');
    }
  }

  Future<void> loadMyAchievements(String companyId) async {
    try {
      final resp = await _supabase.from('achievements').select().eq('company_id', companyId);
      _myAchievements = resp.map<Achievement>((e) => Achievement.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Load achievements error: $e'); // non-critical, don't set _error
    }
  }

  Future<void> loadMyClan(String companyId) async {
    try {
      final resp = await _supabase
          .from('clan_members')
          .select('clan_id, role')
          .eq('company_id', companyId)
          .maybeSingle();
      if (resp != null && resp['clan_id'] != null) {
        final clanId = resp['clan_id'] as String;
        await loadClanDetails(clanId);
        // Load clan missions and chat in parallel
        await Future.wait([
          loadClanMissions(clanId),
          loadClanMessages(clanId),
        ]);
      } else {
        _myClan = null;
        _clanMembers = [];
        _clanMissions = [];
        _clanMessages = [];
      }
    } catch (e) {
      debugPrint('Load my clan error: $e');
    }
  }

  Future<void> loadClanDetails(String clanId) async {
    try {
      final details = await _supabase.rpc('get_clan_details', params: {'p_clan_id': clanId});
      if (details != null && details is Map<String, dynamic>) {
        final clanData = details['clan'] as Map<String, dynamic>?;
        if (clanData != null) {
          _myClan = Clan.fromJson(Map<String, dynamic>.from(clanData));
        }
        final membersData = details['members'] as List<dynamic>?;
        _clanMembers = (membersData ?? []).map<ClanMember>((e) {
          return ClanMember.fromJson(Map<String, dynamic>.from(e as Map));
        }).toList();
      }
    } catch (e) {
      debugPrint('Load clan details error: $e');
    }
  }

  Future<void> loadClanMissions(String clanId) async {
    try {
      final resp = await _supabase.rpc('get_clan_missions', params: {'p_clan_id': clanId});
      _clanMissions = (resp as List?)
          ?.map<ClanMission>((e) => ClanMission.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList() ?? [];
    } catch (e) {
      debugPrint('Load clan missions error: $e');
    }
  }

  Future<void> loadClanMessages(String clanId) async {
    try {
      final resp = await _supabase.rpc('get_clan_messages', params: {'p_clan_id': clanId});
      _clanMessages = (resp as List?)
          ?.map<ChatMessage>((e) => ChatMessage.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList() ?? [];
    } catch (e) {
      debugPrint('Load clan messages error: $e');
    }
  }

  Future<void> loadMyGarages(String companyId) async {
    try {
      final resp = await _supabase.from('garages').select().eq('company_id', companyId);
      _myGarages = resp.map<Garage>((e) => Garage.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Load garages error: $e'); // non-critical
    }
  }

  Future<void> loadEventLog(String companyId) async {
    try {
      final resp = await _supabase
          .from('event_log')
          .select()
          .eq('company_id', companyId)
          .order('created_at', ascending: false)
          .limit(50);
      _eventLog = resp.map<EventLog>((e) => EventLog.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Load event log error: $e');
    }
  }

  Future<void> loadClanLeaderboard() async {
    try {
      final resp = await _supabase.rpc('clan_leaderboard');
      _clanLeaderboard = List<Map<String, dynamic>>.from(resp as List? ?? []);
    } catch (e) {
      debugPrint('Load clan leaderboard error: $e');
    }
  }

  Future<void> loadMarketListings() async {
    try {
      final resp = await _supabase
          .from('market_listings')
          .select()
          .gte('expires_at', DateTime.now().toUtc().toIso8601String())
          .order('created_at', ascending: false)
          .limit(50);
      _marketListings = resp.map<MarketListing>((e) => MarketListing.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Load market listings error: $e');
    }
  }

  Future<void> loadLeaderboard() async {
    try {
      final resp = await _supabase.from('leaderboard').select().limit(20);
      _leaderboard = List<Map<String, dynamic>>.from(resp);
    } catch (e) {
      debugPrint('Load leaderboard error: $e');
    }
  }

  /// Check and unlock achievements. Returns list of newly unlocked IDs.
  Future<List<String>> checkAchievements(String companyId) async {
    try {
      final resp = await _supabase.rpc('check_achievements', params: {'p_company_id': companyId});
      final newIds = <String>[];
      for (final row in resp) {
        final aid = row['achievement_id'] as String?;
        final isNew = row['is_new'] as bool? ?? false;
        if (aid != null && isNew) newIds.add(aid);
      }
      if (newIds.isNotEmpty) {
        await loadMyAchievements(companyId);
        await loadCompany(companyId);
      }
      return newIds;
    } catch (e) {
      debugPrint('Check achievements error: $e');
      return [];
    }
  }

  Future<void> loadAll(String companyId) async {
    _currentCompanyId = companyId;  // Cache for realtime
    _isLoading = true;
    _error = null;
    notifyListeners();
    // Update dynamic prices and weather on load
    GameConstants.updateAllDynamic();
    // Start periodic price/weather update (every 60 seconds)
    _fuelPriceTimer?.cancel();
    _fuelPriceTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      GameConstants.updateAllDynamic();
      notifyListeners();
    });
    try {
      await Future.wait([
        loadCities(),
        loadCompany(companyId),
        loadMyTrucks(companyId),
        loadMyDrivers(companyId),
        loadContracts(),
        loadMyContracts(companyId),
        loadMyWarehouses(companyId),
        loadMyAchievements(companyId),
        loadLeaderboard(),
        loadMyClan(companyId),
        loadClanLeaderboard(),
        loadEventLog(companyId),
        loadMyGarages(companyId),
        loadMarketListings(),
        loadCompanyCustomization(),
      ]);
      // Try to complete expired contracts server-side
      await _supabase.rpc('complete_expired_contracts');
      // Reload after completion
      await Future.wait([
        loadMyTrucks(companyId),
        loadMyContracts(companyId),
        loadCompany(companyId),
        loadContracts(),
      ]);
      _isInitialized = true;
    } catch (e) {
      _error = 'Ошибка загрузки: $e';
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> refreshAll(String companyId) async {
    _currentCompanyId = companyId;  // Update cached companyId
    try {
      await Future.wait([
        loadMyTrucks(companyId),
        loadMyContracts(companyId),
        loadCompany(companyId),
        loadContracts(),
      ]);
      // Check for completions
      await _supabase.rpc('complete_expired_contracts');
      await Future.wait([
        loadMyTrucks(companyId),
        loadMyContracts(companyId),
        loadCompany(companyId),
      ]);
    } catch (e) {
      debugPrint('Refresh error: $e');
    }
  }

  // ===== LOG EVENT HELPER =====
  Future<void> logEvent({
    required String companyId,
    required String eventType,
    required String title,
    String description = '',
    String iconName = 'info',
    String colorHex = '66BB6A',
    Map<String, dynamic> metadata = const {},
  }) async {
    try {
      await _supabase.rpc('log_event', params: {
        'p_company_id': companyId,
        'p_event_type': eventType,
        'p_title': title,
        'p_description': description,
        'p_icon_name': iconName,
        'p_color_hex': colorHex,
        'p_metadata': metadata,
      });
    } catch (e) {
      debugPrint('Log event error: $e');
    }
  }

  // ===== PATHFINDING =====
  PathResult? findRoute(int fromCityId, int toCityId) {
    if (_cities.isEmpty) return null;
    return PathFinder.findRoute(_cities, fromCityId, toCityId);
  }

  // ===== FIND NEAREST TRUCK =====
  Truck? findNearestIdleTruck(int originCityId) {
    if (_myTrucks.isEmpty || _cities.isEmpty) return null;
    Truck? nearest;
    double minDist = double.infinity;
    final origin = getCityById(originCityId);
    if (origin == null) return idleTrucks.isNotEmpty ? idleTrucks.first : null;

    for (final truck in idleTrucks) {
      if (truck.currentCityId != null) {
        final city = getCityById(truck.currentCityId!);
        if (city != null) {
          final dist = haversineKm(origin.latitude, origin.longitude, city.latitude, city.longitude);
          if (dist < minDist) {
            minDist = dist;
            nearest = truck;
          }
        }
      }
    }
    return nearest ?? (idleTrucks.isNotEmpty ? idleTrucks.first : null);
  }

  // ===== ACTIONS =====
  Future<bool> buyGarage(String companyId, int cityId) async {
    try {
      _isLoading = true; _error = null; notifyListeners();
      final city = getCityById(cityId);
      if (city == null) { _error = 'Город не найден'; return false; }
      if (hasGarageInCity(cityId)) { _error = 'Гараж уже куплен'; return false; }

      final resp = await _supabase.rpc('buy_garage', params: {
        'p_company_id': companyId,
        'p_city_id': cityId,
      });
      if (resp == true) {
        await Future.wait([loadMyGarages(companyId), loadCompany(companyId)]);
        await logEvent(
          companyId: companyId,
          eventType: 'garage_bought',
          title: 'Гараж куплен',
          description: 'Гараж открыт в городе ${city.name}',
          iconName: 'garage',
          colorHex: 'FF9800',
          metadata: {'city_name': city.name},
        );
        return true;
      }
      _error = 'Не удалось купить гараж';
      return false;
    } catch (e) { _error = 'Ошибка покупки гаража: $e'; return false; }
    finally { _isLoading = false; notifyListeners(); }
  }

  Future<bool> expandGarage(String companyId, int cityId) async {
    try {
      _isLoading = true; _error = null; notifyListeners();
      final garage = garageInCity(cityId);
      if (garage == null) { _error = 'Гараж не найден'; return false; }
      if (garage.isMaxLevel) { _error = 'Максимальный размер гаража'; return false; }

      final resp = await _supabase.rpc('expand_garage', params: {
        'p_company_id': companyId,
        'p_city_id': cityId,
      });
      if (resp == true) {
        await Future.wait([loadMyGarages(companyId), loadCompany(companyId)]);
        final city = getCityById(cityId);
        await logEvent(
          companyId: companyId,
          eventType: 'garage_expanded',
          title: 'Гараж расширен',
          description: 'Гараж в городе ${city?.name ?? "#$cityId"} увеличен до ${garage.slots + 2} слотов',
          iconName: 'garage',
          colorHex: 'FF9800',
          metadata: {'city_id': cityId, 'new_slots': garage.slots + 2},
        );
        return true;
      }
      _error = 'Не удалось расширить гараж';
      return false;
    } catch (e) { _error = 'Ошибка расширения: $e'; return false; }
    finally { _isLoading = false; notifyListeners(); }
  }

  Future<bool> buyTruck(String companyId, String truckType, String name, int startCityId) async {
    try {
      _isLoading = true; _error = null; notifyListeners();
      final info = GameConstants.findTruckType(truckType);
      if (info == null) { _error = 'Тип грузовика не найден'; return false; }

      // Garage check: must have a garage in the city with free slots
      if (!hasGarageInCity(startCityId)) {
        _error = 'Нужен гараж в этом городе';
        return false;
      }
      if (!canParkAtCity(startCityId)) {
        _error = 'Гараж полон — нет свободных мест';
        return false;
      }

      // Check money server-side
      final comp = await _supabase.from('companies').select('money').eq('id', companyId).maybeSingle();
      final money = (comp?['money'] as num?)?.toInt() ?? 0;
      if (money < info.price) { _error = 'Недостаточно средств (нужно: ${GameConstants.formatMoney(info.price)})'; return false; }

      await _supabase.from('trucks').insert({
        'company_id': companyId,
        'truck_type': truckType,
        'name': name,
        'status': 'idle',
        'condition_pct': 100,
        'fuel_level': info.fuel.toDouble(),
        'max_fuel': info.fuel.toDouble(),
        'current_city_id': startCityId,
        'purchase_price': info.price,
      });
      await _supabase.from('companies').update({'money': money - info.price}).eq('id', companyId);
      await _supabase.from('transactions').insert({
        'company_id': companyId,
        'type': 'truck_purchase',
        'description': 'Покупка: $name',
        'amount': -info.price,
      });
      await loadMyTrucks(companyId);
      await loadCompany(companyId);
      await logEvent(
        companyId: companyId,
        eventType: 'truck_purchased',
        title: 'Грузовик куплен',
        description: 'Приобретён $name ($truckType)',
        iconName: 'truck_purchased',
        colorHex: '42A5F5',
        metadata: {'truck_name': name, 'truck_type': truckType, 'amount': -info.price},
      );
      return true;
    } catch (e) { _error = 'Ошибка покупки: $e'; return false; }
    finally { _isLoading = false; notifyListeners(); }
  }

  Future<bool> hireDriver(String companyId) async {
    try {
      _isLoading = true; _error = null; notifyListeners();
      final comp = await _supabase.from('companies').select('money').eq('id', companyId).maybeSingle();
      final money = (comp?['money'] as num?)?.toInt() ?? 0;
      final cost = GameConstants.driverBaseSalary * GameConstants.driverHireCostMultiplier;
      if (money < cost) { _error = 'Недостаточно средств (нужно: ${GameConstants.formatMoney(cost)})'; return false; }

      final first = GameConstants.driverFirstNames[math.Random().nextInt(GameConstants.driverFirstNames.length)];
      final last = GameConstants.driverLastNames[math.Random().nextInt(GameConstants.driverLastNames.length)];
      await _supabase.from('drivers').insert({
        'company_id': companyId,
        'name': '$first $last',
        'skill_level': 1 + math.Random().nextInt(4),
        'salary_daily': GameConstants.driverBaseSalary + math.Random().nextInt(200),
        'status': 'available',
        'xp': 0,
        'trips_completed': 0,
        'fatigue': 0,
        'speed_skill': math.Random().nextInt(10),
        'fuel_efficiency_skill': math.Random().nextInt(10),
        'reliability_skill': math.Random().nextInt(10),
      });
      await _supabase.from('companies').update({'money': money - cost}).eq('id', companyId);
      await _supabase.from('transactions').insert({
        'company_id': companyId,
        'type': 'driver_hire',
        'description': 'Найм: $first $last',
        'amount': -cost,
      });
      await loadMyDrivers(companyId);
      await loadCompany(companyId);
      await logEvent(
        companyId: companyId,
        eventType: 'driver_hired',
        title: 'Водитель нанят',
        description: '$first $last присоединился к компании',
        iconName: 'driver_hired',
        colorHex: '64B5F6',
        metadata: {'driver_name': '$first $last', 'amount': -cost},
      );
      return true;
    } catch (e) { _error = 'Ошибка найма: $e'; return false; }
    finally { _isLoading = false; notifyListeners(); }
  }

  /// Accept contract. Always lets SQL find nearest idle truck via find_nearest_idle_truck().
  /// Returns (success, assignedTruckName) tuple.
  Future<({bool success, String truckName})> acceptContract({
    required String contractId,
    String? truckId,
    required String companyId,
  }) async {
    try {
      _isLoading = true; _error = null; notifyListeners();

      // Quick client-side check: do we have ANY idle truck?
      if (idleTrucks.isEmpty) {
        _error = 'Нет свободных грузовиков';
        return (success: false, truckName: '');
      }

      // Always pass null for p_truck_id — let SQL find nearest truck.
      // The SQL function has IF p_truck_id IS NULL THEN find_nearest... branch.
      // Passing a resolved truckId was causing the ELSE branch to be missing in SQL,
      // leaving v_truck_id as NULL and the function failing.
      final resp = await _supabase.rpc('accept_contract', params: {
        'p_contract_id': contractId,
        'p_truck_id': null,
        'p_company_id': companyId,
      });

      if (resp == true) {
        await Future.wait([
          loadMyTrucks(companyId),
          loadContracts(),
          loadMyContracts(companyId),
          loadCompany(companyId),
        ]);
        // Find truck and its assigned driver, grant driver XP
        final assignedTruck = _myTrucks.where((t) => t.contractId == contractId).firstOrNull;
        if (assignedTruck?.driverId != null) {
          try {
            await _supabase.rpc('driver_complete_trip', params: {'p_driver_id': assignedTruck!.driverId});
            await loadMyDrivers(companyId);
          } catch (e) {
            debugPrint('Driver XP grant error: $e'); // non-critical
          }
        }
        final truckName = assignedTruck?.name ?? 'Грузовик';
        // Look up contract for origin/destination info
        final contract = _myContracts.where((c) => c.id == contractId).firstOrNull;
        final originName = contract != null ? (getCityById(contract.originCityId)?.name ?? '') : '';
        final destName = contract != null ? (getCityById(contract.destinationCityId)?.name ?? '') : '';
        final routeStr = originName.isNotEmpty && destName.isNotEmpty ? ' $originName → $destName' : '';
        await logEvent(
          companyId: companyId,
          eventType: 'contract_accepted',
          title: 'Контракт принят',
          description: 'Грузовик «$truckName» отправлен$routeStr',
          iconName: 'contract_accepted',
          colorHex: '42A5F5',
          metadata: {
            'truck_name': truckName,
            if (originName.isNotEmpty) 'origin': originName,
            if (destName.isNotEmpty) 'destination': destName,
            if (contract != null) 'amount': contract.reward,
          },
        );
        return (success: true, truckName: truckName);
      } else {
        _error = 'Не удалось принять контракт (возможно, уже занят или нет грузовика в городе отправления)';
        return (success: false, truckName: '');
      }
    } catch (e) {
      _error = 'Ошибка контракта: $e';
      return (success: false, truckName: '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> assignDriver(String driverId, String truckId, String companyId) async {
    try {
      _isLoading = true; _error = null; notifyListeners();
      final resp = await _supabase.rpc('assign_driver', params: {
        'p_driver_id': driverId,
        'p_truck_id': truckId,
        'p_company_id': companyId,
      });
      if (resp == true) {
        await Future.wait([loadMyDrivers(companyId), loadMyTrucks(companyId)]);
        return true;
      }
      _error = 'Не удалось назначить водителя';
      return false;
    } catch (e) { _error = 'Ошибка назначения: $e'; return false; }
    finally { _isLoading = false; notifyListeners(); }
  }

  Future<bool> unassignDriver(String driverId, String companyId) async {
    try {
      _isLoading = true; _error = null; notifyListeners();
      final resp = await _supabase.rpc('unassign_driver', params: {
        'p_driver_id': driverId,
        'p_company_id': companyId,
      });
      if (resp == true) {
        await Future.wait([loadMyDrivers(companyId), loadMyTrucks(companyId)]);
        return true;
      }
      _error = 'Не удалось снять водителя';
      return false;
    } catch (e) { _error = 'Ошибка снятия: $e'; return false; }
    finally { _isLoading = false; notifyListeners(); }
  }

  Future<bool> restDriver(String driverId, String companyId) async {
    try {
      final resp = await _supabase.rpc('driver_rest', params: {
        'p_driver_id': driverId,
      });
      if (resp == true) {
        await loadMyDrivers(companyId);
        return true;
      }
      return false;
    } catch (e) { _error = 'Ошибка отдыха: $e'; return false; }
  }

  Future<bool> refuelTruck(String truckId, String companyId) async {
    try {
      final truck = _myTrucks.where((t) => t.id == truckId).firstOrNull;
      if (truck == null) { _error = 'Грузовик не найден'; notifyListeners(); return false; }
      final missingFuel = truck.maxFuel - truck.fuelLevel;
      if (missingFuel <= 0) return true; // already full
      final companyLevel = _company?.level ?? 1;
      final effectivePrice = GameConstants.effectiveFuelPrice(companyLevel);
      final cost = (missingFuel * effectivePrice).round();

      final comp = await _supabase.from('companies').select('money').eq('id', companyId).maybeSingle();
      final money = (comp?['money'] as num?)?.toInt() ?? 0;
      if (money < cost) { _error = 'Недостаточно средств для заправки (${GameConstants.formatMoney(cost)})'; notifyListeners(); return false; }

      await _supabase.from('trucks').update({'fuel_level': truck.maxFuel}).eq('id', truckId);
      await _supabase.from('companies').update({'money': money - cost}).eq('id', companyId);
      await _supabase.from('transactions').insert({
        'company_id': companyId, 'type': 'refuel', 'description': 'Заправка: ${truck.name}', 'amount': -cost,
      });
      await loadMyTrucks(companyId);
      await loadCompany(companyId);
      await logEvent(
        companyId: companyId,
        eventType: 'refuel',
        title: 'Заправка',
        description: '${truck.name} заправлен полностью',
        iconName: 'refuel',
        colorHex: 'F5C542',
        metadata: {'truck_name': truck.name, 'amount': -cost},
      );
      return true;
    } catch (e) { _error = 'Ошибка заправки: $e'; notifyListeners(); return false; }
  }

  Future<bool> repairTruck(String truckId, String companyId) async {
    try {
      final truck = _myTrucks.where((t) => t.id == truckId).firstOrNull;
      if (truck == null || truck.condition >= 100) { _error = truck == null ? 'Грузовик не найден' : 'Ремонт не нужен'; notifyListeners(); return false; }
      final cost = (100 - truck.condition) * GameConstants.repairCostPerPoint;

      final comp = await _supabase.from('companies').select('money').eq('id', companyId).maybeSingle();
      final money = (comp?['money'] as num?)?.toInt() ?? 0;
      if (money < cost) { _error = 'Недостаточно средств для ремонта (${GameConstants.formatMoney(cost)})'; notifyListeners(); return false; }

      await _supabase.from('trucks').update({'condition_pct': 100}).eq('id', truckId);
      await _supabase.from('companies').update({'money': money - cost}).eq('id', companyId);
      await _supabase.from('transactions').insert({
        'company_id': companyId, 'type': 'repair', 'description': 'Ремонт: ${truck.name}', 'amount': -cost,
      });
      await loadMyTrucks(companyId);
      await loadCompany(companyId);
      await logEvent(
        companyId: companyId,
        eventType: 'repair',
        title: 'Ремонт',
        description: '${truck.name} отремонтирован',
        iconName: 'repair',
        colorHex: 'EF5350',
        metadata: {'truck_name': truck.name, 'amount': -cost},
      );
      return true;
    } catch (e) { _error = 'Ошибка ремонта: $e'; notifyListeners(); return false; }
  }

  Future<bool> upgradeTruck(String truckId, String companyId, String upgradeType, String value) async {
    try {
      _isLoading = true; _error = null; notifyListeners();
      final resp = await _supabase.rpc('upgrade_truck', params: {
        'p_truck_id': truckId,
        'p_company_id': companyId,
        'p_upgrade_type': upgradeType,
        'p_value': value,
      });
      await Future.wait([loadMyTrucks(companyId), loadCompany(companyId)]);
      final truck = _myTrucks.where((t) => t.id == truckId).firstOrNull;
      final truckName = truck?.name ?? 'Грузовик';
      await logEvent(
        companyId: companyId,
        eventType: 'truck_upgrade',
        title: 'Улучшение грузовика',
        description: '$truckName: ${_upgradeTypeLabel(upgradeType)} → $value',
        iconName: 'upgrade',
        colorHex: '42A5F5',
        metadata: {'truck_name': truckName, 'upgrade_type': upgradeType, 'value': value},
      );
      return resp == true;
    } catch (e) {
      _error = 'Ошибка улучшения: $e';
      return false;
    }
    finally { _isLoading = false; notifyListeners(); }
  }

  String _upgradeTypeLabel(String type) => switch (type) {
    'engine' => 'Двигатель',
    'tank' => 'Топливный бак',
    'cabin' => 'Кабина',
    'paint' => 'Покраска',
    _ => type,
  };

  Future<bool> sellTruck(String truckId, String companyId, int sellPrice) async {
    try {
      final truck = _myTrucks.where((t) => t.id == truckId).firstOrNull;
      if (truck == null || !truck.isIdle) { _error = 'Можно продать только свободный грузовик'; return false; }

      final comp = await _supabase.from('companies').select('money').eq('id', companyId).maybeSingle();
      final money = (comp?['money'] as num?)?.toInt() ?? 0;

      await _supabase.from('trucks').delete().eq('id', truckId);
      await _supabase.from('companies').update({'money': money + sellPrice}).eq('id', companyId);
      await _supabase.from('transactions').insert({
        'company_id': companyId, 'type': 'truck_sale', 'description': 'Продажа: ${truck.name}', 'amount': sellPrice,
      });
      await loadMyTrucks(companyId);
      await loadCompany(companyId);
      await logEvent(
        companyId: companyId,
        eventType: 'truck_sold',
        title: 'Грузовик продан',
        description: '${truck.name} продан за ${GameConstants.formatMoney(sellPrice)}',
        iconName: 'truck_sold',
        colorHex: 'CE93D8',
        metadata: {'truck_name': truck.name, 'amount': sellPrice},
      );
      return true;
    } catch (e) { _error = 'Ошибка продажи: $e'; return false; }
  }

  /// List a truck on the player market (removes it from company)
  Future<bool> listTruckOnMarket(String truckId, String companyId, int price) async {
    try {
      _isLoading = true; _error = null; notifyListeners();
      final truck = _myTrucks.where((t) => t.id == truckId).firstOrNull;
      if (truck == null || !truck.isIdle) { _error = 'Можно продать только свободный грузовик'; return false; }

      final resp = await _supabase.rpc('list_truck_on_market', params: {
        'p_truck_id': truckId,
        'p_company_id': companyId,
        'p_price': price,
      });
      await Future.wait([loadMyTrucks(companyId), loadMarketListings()]);
      await logEvent(
        companyId: companyId,
        eventType: 'market_list',
        title: 'Грузовик выставлен на рынок',
        description: '${truck.name} — ${GameConstants.formatMoney(price)}',
        iconName: 'store',
        colorHex: 'F5C542',
        metadata: {'truck_name': truck.name, 'amount': price},
      );
      return resp != null;
    } catch (e) { _error = 'Ошибка выставления: $e'; return false; }
    finally { _isLoading = false; notifyListeners(); }
  }

  /// Buy an item from the player market
  Future<bool> buyFromMarket(String listingId, String companyId) async {
    try {
      _isLoading = true; _error = null; notifyListeners();
      final resp = await _supabase.rpc('buy_from_market', params: {
        'p_listing_id': listingId,
        'p_buyer_id': companyId,
      });
      if (resp == true) {
        await Future.wait([loadMyTrucks(companyId), loadCompany(companyId), loadMarketListings()]);
        return true;
      }
      _error = 'Не удалось купить лот';
      return false;
    } catch (e) { _error = 'Ошибка покупки: $e'; return false; }
    finally { _isLoading = false; notifyListeners(); }
  }

  Future<void> generateNewContracts() async {
    try {
      await _supabase.rpc('generate_contracts');
      await loadContracts();
    } catch (e) {
      debugPrint('Generate contracts error: $e');
    }
  }

  Future<bool> claimWarehouse(String companyId, int cityId) async {
    try {
      _isLoading = true; _error = null; notifyListeners();
      final city = getCityById(cityId);
      if (city == null) { _error = 'Город не найден'; return false; }

      // Check money
      final comp = await _supabase.from('companies').select('money').eq('id', companyId).maybeSingle();
      final money = (comp?['money'] as num?)?.toInt() ?? 0;
      if (money < city.warehouseCost) {
        _error = 'Недостаточно средств (нужно: ${GameConstants.formatMoney(city.warehouseCost)})';
        return false;
      }

      // Check if already claimed
      final existing = await _supabase.from('warehouses')
          .select()
          .eq('company_id', companyId)
          .eq('city_id', cityId)
          .maybeSingle();
      if (existing != null) { _error = 'Склад уже куплен'; return false; }

      await _supabase.from('warehouses').insert({
        'company_id': companyId,
        'city_id': cityId,
      });
      await _supabase.from('companies').update({'money': money - city.warehouseCost}).eq('id', companyId);
      await _supabase.from('transactions').insert({
        'company_id': companyId, 'type': 'warehouse', 'description': 'Склад: ${city.name}', 'amount': -city.warehouseCost,
      });
      await loadCompany(companyId);
      await loadMyWarehouses(companyId);  // Sync warehouses with map
      await logEvent(
        companyId: companyId,
        eventType: 'warehouse_bought',
        title: 'Склад куплен',
        description: 'Филиал открыт в городе ${city.name}',
        iconName: 'warehouse',
        colorHex: '42A5F5',
        metadata: {'city_name': city.name, 'amount': -city.warehouseCost},
      );
      return true;
    } catch (e) { _error = 'Ошибка покупки склада: $e'; return false; }
    finally { _isLoading = false; notifyListeners(); }
  }

  Future<bool> createClan(String companyId, String name, String tag, String description) async {
    try {
      _isLoading = true; _error = null; notifyListeners();
      final resp = await _supabase.rpc('create_clan', params: {
        'p_company_id': companyId,
        'p_name': name,
        'p_tag': tag,
        'p_description': description,
      });
      final clanId = resp as String?;
      if (clanId != null) {
        await loadMyClan(companyId);
        await loadClanLeaderboard();
        await loadMyTrucks(companyId);
        await loadCompany(companyId);
        await logEvent(
          companyId: companyId,
          eventType: 'clan_created',
          title: 'Клан создан',
          description: 'Клан «$name» [$tag] успешно создан',
          iconName: 'clan',
          colorHex: 'CE93D8',
          metadata: {'clan_name': name, 'clan_tag': tag},
        );
        return true;
      }
      _error = 'Не удалось создать клан';
      return false;
    } catch (e) { _error = 'Ошибка создания клана: $e'; return false; }
    finally { _isLoading = false; notifyListeners(); }
  }

  Future<bool> joinClan(String companyId, String clanId) async {
    try {
      _isLoading = true; _error = null; notifyListeners();
      final resp = await _supabase.rpc('join_clan', params: {
        'p_company_id': companyId,
        'p_clan_id': clanId,
      });
      if (resp == true) {
        await loadMyClan(companyId);
        await loadClanLeaderboard();
        await logEvent(
          companyId: companyId,
          eventType: 'clan_joined',
          title: 'Вступление в клан',
          description: 'Вы вступили в клан',
          iconName: 'clan',
          colorHex: 'CE93D8',
          metadata: {'clan_id': clanId},
        );
        return true;
      }
      _error = 'Не удалось вступить в клан';
      return false;
    } catch (e) { _error = 'Ошибка вступления: $e'; return false; }
    finally { _isLoading = false; notifyListeners(); }
  }

  Future<bool> leaveClan(String companyId) async {
    try {
      _isLoading = true; _error = null; notifyListeners();
      final resp = await _supabase.rpc('leave_clan', params: {'p_company_id': companyId});
      if (resp == true) {
        _myClan = null;
        _clanMembers = [];
        _clanMissions = [];
        _clanMessages = [];
        await loadClanLeaderboard();
        await logEvent(
          companyId: companyId,
          eventType: 'clan_left',
          title: 'Выход из клана',
          description: 'Вы покинули клан',
          iconName: 'clan',
          colorHex: 'EF5350',
          metadata: {},
        );
        return true;
      }
      _error = 'Не удалось покинуть клан';
      return false;
    } catch (e) { _error = 'Ошибка выхода: $e'; return false; }
    finally { _isLoading = false; notifyListeners(); }
  }

  Future<bool> kickClanMember(String companyId, String targetCompanyId) async {
    try {
      final resp = await _supabase.rpc('kick_clan_member', params: {
        'p_company_id': companyId,
        'p_target_company_id': targetCompanyId,
      });
      if (_myClan != null) await loadClanDetails(_myClan!.id);
      return resp == true;
    } catch (e) { _error = 'Ошибка исключения: $e'; return false; }
  }

  Future<bool> promoteMember(String companyId, String targetCompanyId, String newRole) async {
    try {
      final resp = await _supabase.rpc('set_clan_role', params: {
        'p_company_id': companyId,
        'p_target_company_id': targetCompanyId,
        'p_new_role': newRole,
      });
      if (_myClan != null) await loadClanDetails(_myClan!.id);
      return resp == true;
    } catch (e) { _error = 'Ошибка: $e'; return false; }
  }

  Future<void> refreshClan(String companyId) async {
    await loadMyClan(companyId);
    await loadClanLeaderboard();
  }

  Future<void> generateClanMissions() async {
    try {
      await _supabase.rpc('generate_clan_missions');
      if (_myClan != null) await loadClanMissions(_myClan!.id);
    } catch (e) {
      debugPrint('Generate clan missions error: $e');
    }
  }

  Future<bool> sendClanMessage(String companyId, String content) async {
    try {
      if (content.trim().isEmpty) return false;
      final resp = await _supabase.rpc('send_clan_message', params: {
        'p_company_id': companyId,
        'p_content': content.trim(),
      });
      if (resp != null && _myClan != null) {
        await loadClanMessages(_myClan!.id);
      }
      return resp != null;
    } catch (e) {
      _error = 'Ошибка отправки: $e';
      return false;
    }
  }

  @override
  void dispose() {
    _fuelPriceTimer?.cancel();
    stopRealtime();
    super.dispose();
  }
}
