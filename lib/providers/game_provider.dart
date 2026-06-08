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
  List<Contract> get availableContracts => _availableContracts.where((c) => c.isAvailable && !c.isExpired).toList();
  List<Contract> get myContracts => _myContracts;
  List<Warehouse> get myWarehouses => _myWarehouses;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get error => _error;

  void clearError() { _error = null; notifyListeners(); }

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
      debugPrint('Load company error: $e');
    }
  }

  Future<void> loadMyTrucks(String companyId) async {
    try {
      final resp = await _supabase.from('trucks').select().eq('company_id', companyId);
      _myTrucks = resp.map<Truck>((e) => Truck.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Load trucks error: $e');
    }
  }

  Future<void> loadMyDrivers(String companyId) async {
    try {
      final resp = await _supabase.from('drivers').select().eq('company_id', companyId);
      _myDrivers = resp.map<Driver>((e) => Driver.fromJson(e)).toList();
    } catch (e) {
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
      debugPrint('Load my contracts error: $e');
    }
  }

  Future<void> loadMyWarehouses(String companyId) async {
    try {
      final resp = await _supabase.from('warehouses').select().eq('company_id', companyId);
      _myWarehouses = resp.map<Warehouse>((e) => Warehouse.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Load warehouses error: $e');
    }
  }

  Future<void> loadAll(String companyId) async {
    _currentCompanyId = companyId;  // Cache for realtime
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await Future.wait([
        loadCities(),
        loadCompany(companyId),
        loadMyTrucks(companyId),
        loadMyDrivers(companyId),
        loadContracts(),
        loadMyContracts(companyId),
        loadMyWarehouses(companyId),
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
  Future<bool> buyTruck(String companyId, String truckType, String name, int startCityId) async {
    try {
      _isLoading = true; _error = null; notifyListeners();
      final info = GameConstants.findTruckType(truckType);
      if (info == null) { _error = 'Тип грузовика не найден'; return false; }
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
        // Find the truck that just got assigned (status = loading)
        final assignedTruck = _myTrucks.where((t) => t.contractId == contractId).firstOrNull;
        final truckName = assignedTruck?.name ?? 'Грузовик';
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

  Future<void> refuelTruck(String truckId, String companyId) async {
    try {
      final truck = _myTrucks.where((t) => t.id == truckId).firstOrNull;
      if (truck == null) return;
      final missingFuel = truck.maxFuel - truck.fuelLevel;
      final cost = (missingFuel * 1.5).round();
      if (cost <= 0) return;

      final comp = await _supabase.from('companies').select('money').eq('id', companyId).maybeSingle();
      final money = (comp?['money'] as num?)?.toInt() ?? 0;
      if (money < cost) { _error = 'Недостаточно средств для заправки'; notifyListeners(); return; }

      await _supabase.from('trucks').update({'fuel_level': truck.maxFuel}).eq('id', truckId);
      await _supabase.from('companies').update({'money': money - cost}).eq('id', companyId);
      await _supabase.from('transactions').insert({
        'company_id': companyId, 'type': 'refuel', 'description': 'Заправка: ${truck.name}', 'amount': -cost,
      });
      await loadMyTrucks(companyId);
      await loadCompany(companyId);
    } catch (e) {
      debugPrint('Refuel error: $e');
    }
  }

  Future<void> repairTruck(String truckId, String companyId) async {
    try {
      final truck = _myTrucks.where((t) => t.id == truckId).firstOrNull;
      if (truck == null || truck.condition >= 100) return;
      final cost = (100 - truck.condition) * GameConstants.repairCostPerPoint;

      final comp = await _supabase.from('companies').select('money').eq('id', companyId).maybeSingle();
      final money = (comp?['money'] as num?)?.toInt() ?? 0;
      if (money < cost) { _error = 'Недостаточно средств для ремонта'; notifyListeners(); return; }

      await _supabase.from('trucks').update({'condition_pct': 100}).eq('id', truckId);
      await _supabase.from('companies').update({'money': money - cost}).eq('id', companyId);
      await _supabase.from('transactions').insert({
        'company_id': companyId, 'type': 'repair', 'description': 'Ремонт: ${truck.name}', 'amount': -cost,
      });
      await loadMyTrucks(companyId);
      await loadCompany(companyId);
    } catch (e) {
      debugPrint('Repair error: $e');
    }
  }

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
      return true;
    } catch (e) { _error = 'Ошибка продажи: $e'; return false; }
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
      return true;
    } catch (e) { _error = 'Ошибка покупки склада: $e'; return false; }
    finally { _isLoading = false; notifyListeners(); }
  }

  @override
  void dispose() {
    stopRealtime();
    super.dispose();
  }
}
