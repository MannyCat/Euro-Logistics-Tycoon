import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/game_constants.dart';
import '../models/city.dart';
import '../models/company.dart';
import '../models/truck.dart';
import '../models/driver.dart';
import '../models/contract.dart';

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

  // State
  List<City> _cities = [];
  Company? _company;
  List<Truck> _myTrucks = [];
  List<Driver> _myDrivers = [];
  List<Contract> _availableContracts = [];
  List<Contract> _myContracts = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<City> get cities => _cities;
  City? getCityById(int id) {
    for (final c in _cities) { if (c.id == id) return c; }
    return null;
  }
  Company? get company => _company;
  List<Truck> get myTrucks => _myTrucks;
  List<Truck> get idleTrucks => _myTrucks.where((t) => t.isIdle).toList();
  List<Truck> get transitTrucks => _myTrucks.where((t) => t.isInTransit).toList();
  List<Driver> get myDrivers => _myDrivers;
  List<Driver> get availableDrivers => _myDrivers.where((d) => d.isAvailable).toList();
  List<Contract> get availableContracts => _availableContracts.where((c) => c.isAvailable && !c.isExpired).toList();
  List<Contract> get myContracts => _myContracts;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ===== LOAD =====
  Future<void> loadCities() async {
    try {
      final resp = await _supabase.from('cities').select().order('name');
      _cities = resp.map<City>((e) => City.fromJson(e)).toList();
      notifyListeners();
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
      notifyListeners();
    } catch (e) {
      debugPrint('Load company error: $e');
    }
  }

  Future<void> loadMyTrucks(String companyId) async {
    try {
      final resp = await _supabase.from('trucks').select().eq('company_id', companyId);
      _myTrucks = resp.map<Truck>((e) => Truck.fromJson(e)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Load trucks error: $e');
    }
  }

  Future<void> loadMyDrivers(String companyId) async {
    try {
      final resp = await _supabase.from('drivers').select().eq('company_id', companyId);
      _myDrivers = resp.map<Driver>((e) => Driver.fromJson(e)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Load drivers error: $e');
    }
  }

  Future<void> loadContracts() async {
    try {
      final resp = await _supabase.from('contracts').select().eq('status', 'available').order('reward', ascending: false).limit(30);
      _availableContracts = resp.map<Contract>((e) => Contract.fromJson(e)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Load contracts error: $e');
    }
  }

  Future<void> loadMyContracts(String companyId) async {
    try {
      final resp = await _supabase.from('contracts').select().eq('assigned_company_id', companyId).order('created_at', ascending: false).limit(20);
      _myContracts = resp.map<Contract>((e) => Contract.fromJson(e)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Load my contracts error: $e');
    }
  }

  Future<void> loadAll(String companyId) async {
    _isLoading = true;
    notifyListeners();
    await Future.wait([
      loadCities(),
      loadCompany(companyId),
      loadMyTrucks(companyId),
      loadMyDrivers(companyId),
      loadContracts(),
      loadMyContracts(companyId),
    ]);
    // Complete expired contracts (client-side check)
    await _completeExpiredContracts(companyId);
    _isLoading = false;
    notifyListeners();
  }

  // ===== ACTIONS =====
  Future<bool> buyTruck(String companyId, String truckType, String name) async {
    try {
      _isLoading = true; _error = null; notifyListeners();
      final info = GameConstants.findTruckType(truckType);
      if (info == null) { _error = 'Тип грузовика не найден'; return false; }
      // Check money
      final comp = await _supabase.from('companies').select('money').eq('id', companyId).maybeSingle();
      final money = (comp?['money'] as num?)?.toInt() ?? 0;
      if (money < info.price) { _error = 'Недостаточно средств'; return false; }
      // Buy
      await _supabase.from('trucks').insert({
        'company_id': companyId, 'truck_type': truckType, 'name': name,
        'status': 'idle', 'condition_pct': 100, 'fuel_level': 100.0, 'max_fuel': info.fuel.toDouble(),
        'current_city_id': 1, // Start in London
        'purchase_price': info.price,
      });
      await _supabase.from('companies').update({'money': money - info.price}).eq('id', companyId);
      await _supabase.from('transactions').insert({
        'company_id': companyId, 'type': 'truck_purchase', 'description': 'Покупка: $name', 'amount': -info.price,
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
      final cost = GameConstants.driverBaseSalary * 30; // 30 days salary upfront
      if (money < cost) { _error = 'Недостаточно средств. Нужно: \u20AC$cost'; return false; }
      final first = GameConstants.driverFirstNames[math.Random().nextInt(GameConstants.driverFirstNames.length)];
      final last = GameConstants.driverLastNames[math.Random().nextInt(GameConstants.driverLastNames.length)];
      await _supabase.from('drivers').insert({
        'company_id': companyId, 'name': '$first $last', 'skill_level': 1 + math.Random().nextInt(4),
        'salary_daily': GameConstants.driverBaseSalary + math.Random().nextInt(200),
        'status': 'available',
      });
      await _supabase.from('companies').update({'money': money - cost}).eq('id', companyId);
      await _supabase.from('transactions').insert({
        'company_id': companyId, 'type': 'driver_hire', 'description': 'Найм: $first $last', 'amount': -cost,
      });
      await loadMyDrivers(companyId);
      await loadCompany(companyId);
      return true;
    } catch (e) { _error = 'Ошибка найма: $e'; return false; }
    finally { _isLoading = false; notifyListeners(); }
  }

  Future<bool> acceptContract(String contractId, String truckId, String companyId) async {
    try {
      _isLoading = true; _error = null; notifyListeners();
      final resp = await _supabase.rpc('accept_contract', params: {
        'p_contract_id': contractId, 'p_truck_id': truckId, 'p_company_id': companyId,
      });
      if (resp == true) {
        await Future.wait([loadMyTrucks(companyId), loadContracts(), loadMyContracts(companyId)]);
        return true;
      } else {
        _error = 'Не удалось принять контракт';
        return false;
      }
    } catch (e) { _error = 'Ошибка контракта: $e'; return false; }
    finally { _isLoading = false; notifyListeners(); }
  }

  Future<void> refuelTruck(String truckId, String companyId) async {
    try {
      final truck = _myTrucks.where((t) => t.id == truckId).firstOrNull;
      if (truck == null) return;
      final cost = ((1.0 - truck.fuelLevel / truck.maxFuel) * GameConstants.fuelCostPer100km).round();
      if (cost <= 0) return;
      await _supabase.from('trucks').update({'fuel_level': truck.maxFuel}).eq('id', truckId);
      await _supabase.from('companies').update({'money': _company!.money - cost}).eq('id', companyId);
      await loadMyTrucks(companyId);
      await loadCompany(companyId);
    } catch (e) { debugPrint('Refuel error: $e'); }
  }

  Future<void> repairTruck(String truckId, String companyId) async {
    try {
      final truck = _myTrucks.where((t) => t.id == truckId).firstOrNull;
      if (truck == null || truck.condition >= 100) return;
      final cost = (100 - truck.condition) * GameConstants.repairCostPerPoint;
      await _supabase.from('trucks').update({'condition_pct': 100}).eq('id', truckId);
      await _supabase.from('companies').update({'money': _company!.money - cost}).eq('id', companyId);
      await loadMyTrucks(companyId);
      await loadCompany(companyId);
    } catch (e) { debugPrint('Repair error: $e'); }
  }

  // Client-side contract completion check
  Future<void> _completeExpiredContracts(String companyId) async {
    try {
      final now = DateTime.now();
      for (final truck in _myTrucks) {
        if (truck.isInTransit && truck.estimatedArrival != null && now.isAfter(truck.estimatedArrival!)) {
          // Contract completed
          if (truck.contractId != null) {
            final contract = _myContracts.where((c) => c.id == truck.contractId).firstOrNull;
            final reward = contract?.reward ?? 0;
            await _supabase.from('contracts').update({'status': 'completed'}).eq('id', truck.contractId!);
            await _supabase.from('companies').update({'money': _company!.money + reward, 'xp': _company!.xp + (reward / 100).round()}).eq('id', companyId);
            await _supabase.from('transactions').insert({
              'company_id': companyId, 'type': 'contract_completed', 'description': 'Доставка завершена', 'amount': reward,
            });
          }
          await _supabase.from('trucks').update({
            'status': 'idle', 'current_city_id': truck.destinationCityId,
            'origin_city_id': null, 'destination_city_id': null, 'contract_id': null,
            'departure_time': null, 'estimated_arrival': null,
            'condition_pct': (truck.condition - GameConstants.conditionLossPerTrip).clamp(10, 100),
          }).eq('id', truck.id);
        }
        // Loading → in_transit after 30s
        if (truck.status == 'loading' && truck.departureTime != null && now.difference(truck.departureTime!).inSeconds > 30) {
          await _supabase.from('trucks').update({'status': 'in_transit'}).eq('id', truck.id);
        }
      }
    } catch (e) {
      debugPrint('Complete contracts error: $e');
    }
  }
}
