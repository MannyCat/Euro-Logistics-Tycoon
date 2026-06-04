import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/game_constants.dart';
import '../utils/db_id_mapper.dart';

// ===================== HELPERS =====================

/// Convert a value that might be a DB integer ID into a GameConstants slug string.
String? _intOrStringToSlug(dynamic value) {
  if (value == null) return null;
  if (value is String) return value;
  if (value is int) {
    return DbIdMapper.portIntToSlug(value) ??
        DbIdMapper.goodIntToSlug(value) ??
        DbIdMapper.shipTypeIntToSlug(value) ??
        value.toString();
  }
  return value.toString();
}

/// Check if a voyage is currently "active" (in transit or loading).
bool _isVoyageActive(String status) {
  return status == 'in_transit' || status == 'loading';
}

// ===================== MODELS =====================

class Ship {
  final String id;
  final String ownerId;
  final String shipTypeId;
  final String name;
  final String status;
  final int condition;
  final double fuelLevel;
  final double maxFuel;
  final String? currentPortId;
  final String? destinationPortId;
  final DateTime createdAt;
  final DateTime? lastVoyageAt;

  const Ship({
    required this.id,
    required this.ownerId,
    required this.shipTypeId,
    required this.name,
    required this.status,
    required this.condition,
    required this.fuelLevel,
    required this.maxFuel,
    this.currentPortId,
    this.destinationPortId,
    required this.createdAt,
    this.lastVoyageAt,
  });

  factory Ship.fromJson(Map<String, dynamic> json) {
    return Ship(
      id: json['id'] as String? ?? '',
      ownerId: json['owner_id'] as String? ?? '',
      shipTypeId: _intOrStringToSlug(json['ship_type_id']) ?? '',
      name: json['name'] as String? ?? 'Безымянный',
      status: json['status'] as String? ?? 'idle',
      condition: (json['condition_pct'] as num?)?.toInt() ?? 100,
      fuelLevel: (json['fuel_level'] as num?)?.toDouble() ?? 0.0,
      maxFuel: (json['max_fuel'] as num?)?.toDouble() ?? 0.0,
      currentPortId: _intOrStringToSlug(json['current_port_id']),
      destinationPortId: _intOrStringToSlug(json['destination_port_id']),
      createdAt: DateTime.tryParse(json['purchased_at'] as String? ?? '') ??
          DateTime.now(),
      lastVoyageAt: json['last_voyage_at'] != null
          ? DateTime.tryParse(json['last_voyage_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'owner_id': ownerId,
        'ship_type_id': shipTypeId,
        'name': name,
        'status': status,
        'condition_pct': condition,
        'fuel_level': fuelLevel,
        'max_fuel': maxFuel,
        'current_port_id': currentPortId,
        'destination_port_id': destinationPortId,
        'purchased_at': createdAt.toIso8601String(),
        'last_voyage_at': lastVoyageAt?.toIso8601String(),
      };

  Ship copyWith({
    String? name,
    String? status,
    int? condition,
    double? fuelLevel,
    double? maxFuel,
    String? currentPortId,
    String? destinationPortId,
    DateTime? lastVoyageAt,
  }) {
    return Ship(
      id: id,
      ownerId: ownerId,
      shipTypeId: shipTypeId,
      name: name ?? this.name,
      status: status ?? this.status,
      condition: condition ?? this.condition,
      fuelLevel: fuelLevel ?? this.fuelLevel,
      maxFuel: maxFuel ?? this.maxFuel,
      currentPortId: currentPortId ?? this.currentPortId,
      destinationPortId: destinationPortId ?? this.destinationPortId,
      createdAt: createdAt,
      lastVoyageAt: lastVoyageAt ?? this.lastVoyageAt,
    );
  }
}

class PortPrice {
  final String portId;
  final String goodId;
  final int buyPrice;
  final int sellPrice;
  final int available;
  final DateTime updatedAt;

  const PortPrice({
    required this.portId,
    required this.goodId,
    required this.buyPrice,
    required this.sellPrice,
    required this.available,
    required this.updatedAt,
  });

  factory PortPrice.fromJson(Map<String, dynamic> json) {
    return PortPrice(
      portId: _intOrStringToSlug(json['port_id']) ?? '',
      goodId: _intOrStringToSlug(json['good_id']) ?? '',
      buyPrice: (json['buy_price'] as num?)?.toInt() ?? 0,
      sellPrice: (json['sell_price'] as num?)?.toInt() ?? 0,
      available: (json['available_quantity'] as num?)?.toInt() ?? 0,
      updatedAt: DateTime.tryParse(json['last_updated'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

class Voyage {
  final String id;
  final String shipId;
  final String originPortId;
  final String destinationPortId;
  final String? goodId;
  final int quantity;
  final double distance;
  final double estimatedHours;
  final DateTime startedAt;
  final DateTime? eta;
  final String status;
  final int? revenue;
  final int? fuelCost;

  const Voyage({
    required this.id,
    required this.shipId,
    required this.originPortId,
    required this.destinationPortId,
    this.goodId,
    required this.quantity,
    required this.distance,
    required this.estimatedHours,
    required this.startedAt,
    this.eta,
    required this.status,
    this.revenue,
    this.fuelCost,
  });

  factory Voyage.fromJson(Map<String, dynamic> json) {
    return Voyage(
      id: json['id'] as String? ?? '',
      shipId: json['ship_id'] as String? ?? '',
      originPortId: _intOrStringToSlug(json['origin_port_id']) ?? '',
      destinationPortId: _intOrStringToSlug(json['destination_port_id']) ?? '',
      goodId: _intOrStringToSlug(json['cargo_good_id']),
      quantity: (json['cargo_quantity'] as num?)?.toInt() ?? 0,
      distance: (json['distance_nm'] as num?)?.toDouble() ?? 0.0,
      estimatedHours: (json['estimated_hours'] as num?)?.toDouble() ?? 0.0,
      startedAt: DateTime.tryParse(
              json['departure_time'] as String? ?? '') ??
          DateTime.now(),
      eta: json['estimated_arrival'] != null
          ? DateTime.tryParse(json['estimated_arrival'] as String)
          : null,
      status: json['status'] as String? ?? '',
      revenue: (json['revenue'] as num?)?.toInt(),
      fuelCost: (json['fuel_consumed'] as num?)?.toInt(),
    );
  }

  bool get isActive => _isVoyageActive(status);

  double get progress {
    if (eta == null) return 0;
    final total = eta!.difference(startedAt).inSeconds;
    if (total <= 0) return 1.0;
    final elapsed = DateTime.now().difference(startedAt).inSeconds;
    return (elapsed / total).clamp(0.0, 1.0);
  }
}

class Transaction {
  final String id;
  final String ownerId;
  final String type;
  final String description;
  final int amount;
  final DateTime createdAt;

  const Transaction({
    required this.id,
    required this.ownerId,
    required this.type,
    required this.description,
    required this.amount,
    required this.createdAt,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String? ?? '',
      ownerId: json['player_id'] as String? ?? '',
      type: json['type'] as String? ?? '',
      description: json['description'] as String? ?? '',
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

class ShipMarketListing {
  final String id;
  final String shipId;
  final String sellerId;
  final String sellerName;
  final String shipName;
  final String shipTypeId;
  final int condition;
  final int price;
  final DateTime listedAt;

  const ShipMarketListing({
    required this.id,
    required this.shipId,
    required this.sellerId,
    required this.sellerName,
    required this.shipName,
    required this.shipTypeId,
    required this.condition,
    required this.price,
    required this.listedAt,
  });

  factory ShipMarketListing.fromJson(Map<String, dynamic> json,
      {Map<String, dynamic>? shipData}) {
    return ShipMarketListing(
      id: json['id'] as String? ?? '',
      shipId: json['ship_id'] as String? ?? '',
      sellerId: json['seller_id'] as String? ?? '',
      sellerName: 'Продавец',
      shipName: shipData?['name'] as String? ?? 'Безымянный',
      shipTypeId: _intOrStringToSlug(shipData?['ship_type_id']) ?? '',
      condition: (shipData?['condition_pct'] as num?)?.toInt() ?? 100,
      price: (json['asking_price'] as num?)?.toInt() ?? 0,
      listedAt: DateTime.tryParse(json['listed_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

class Employee {
  final String id;
  final String ownerId;
  final String name;
  final String role;
  final int skill;
  final int salary;
  final String? assignedPortId;
  final DateTime hiredAt;

  const Employee({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.role,
    required this.skill,
    required this.salary,
    this.assignedPortId,
    required this.hiredAt,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'] as String? ?? '',
      ownerId: json['owner_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      role: json['role'] as String? ?? '',
      skill: (json['skill_level'] as num?)?.toInt() ?? 1,
      salary: (json['salary_daily'] as num?)?.toInt() ?? 0,
      assignedPortId: _intOrStringToSlug(json['port_id']),
      hiredAt: DateTime.tryParse(json['hired_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

class Loan {
  final String id;
  final String ownerId;
  final int amount;
  final int remaining;
  final double interestRate;
  final int termMonths;
  final int monthsPaid;
  final DateTime takenAt;
  final String status;

  const Loan({
    required this.id,
    required this.ownerId,
    required this.amount,
    required this.remaining,
    required this.interestRate,
    required this.termMonths,
    required this.monthsPaid,
    required this.takenAt,
    required this.status,
  });

  int get monthsRemaining => (termMonths - monthsPaid).clamp(0, termMonths);

  factory Loan.fromJson(Map<String, dynamic> json) {
    return Loan(
      id: json['id'] as String? ?? '',
      ownerId: json['borrower_id'] as String? ?? '',
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      remaining: (json['remaining_balance'] as num?)?.toInt() ?? 0,
      interestRate: (json['interest_rate'] as num?)?.toDouble() ?? 0.0,
      termMonths: (json['total_months'] as num?)?.toInt() ?? 0,
      monthsPaid: (json['months_paid'] as num?)?.toInt() ?? 0,
      takenAt: DateTime.tryParse(json['taken_at'] as String? ?? '') ??
          DateTime.now(),
      status: json['status'] as String? ?? 'active',
    );
  }
}

class Factory {
  final String id;
  final String ownerId;
  final String type;
  final String? portId;
  final int level;
  final bool isRunning;
  final String? outputGoodId;
  final DateTime createdAt;

  const Factory({
    required this.id,
    required this.ownerId,
    required this.type,
    this.portId,
    required this.level,
    required this.isRunning,
    this.outputGoodId,
    required this.createdAt,
  });

  factory Factory.fromJson(Map<String, dynamic> json) {
    return Factory(
      id: json['id'] as String? ?? '',
      ownerId: json['owner_id'] as String? ?? '',
      type: json['factory_type'] as String? ?? '',
      portId: _intOrStringToSlug(json['port_id']),
      level: (json['level'] as num?)?.toInt() ?? 1,
      isRunning: json['is_running'] as bool? ?? false,
      outputGoodId: _intOrStringToSlug(json['output_good_id']),
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

// ===================== DASHBOARD DATA =====================

class DashboardData {
  final int activeShips;
  final int idleShips;
  final int inTransitShips;
  final int dockedShips;
  final int activeVoyages;
  final int totalShipsOwned;
  final int totalVoyagesCompleted;
  final int totalProfit;
  final List<Transaction> recentTransactions;

  const DashboardData({
    required this.activeShips,
    required this.idleShips,
    required this.inTransitShips,
    required this.dockedShips,
    required this.activeVoyages,
    required this.totalShipsOwned,
    required this.totalVoyagesCompleted,
    required this.totalProfit,
    required this.recentTransactions,
  });
}

// ===================== GAME PROVIDER =====================

class GameProvider extends ChangeNotifier {
  SupabaseClient get _supabase => Supabase.instance.client;

  // ---- State lists ----
  List<PortDefinition> _allPorts = [];
  List<Ship> _myShips = [];
  List<PortPrice> _currentPortPrices = [];
  List<Voyage> _myVoyages = [];
  List<ShipMarketListing> _shipMarketListings = [];
  List<ShipMarketListing> _myListings = [];
  List<Employee> _employees = [];
  List<Loan> _loans = [];
  List<Transaction> _transactions = [];
  List<Factory> _factories = [];

  DashboardData? _dashboardData;
  bool _isLoading = false;
  String? _errorMessage;

  // ---- Getters ----
  List<PortDefinition> get allPorts => _allPorts;
  List<Ship> get myShips => _myShips;
  List<PortPrice> get currentPortPrices => _currentPortPrices;
  List<Voyage> get myVoyages => _myVoyages;
  List<ShipMarketListing> get shipMarketListings => _shipMarketListings;
  List<ShipMarketListing> get myListings => _myListings;
  List<Employee> get employees => _employees;
  List<Loan> get loans => _loans;
  List<Transaction> get transactions => _transactions;
  List<Factory> get factories => _factories;
  DashboardData? get dashboardData => _dashboardData;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String _currentPortId = '';
  String get currentPortId => _currentPortId;

  // ---- Helper to get current user ID ----
  String? get _userId => _supabase.auth.currentUser?.id;

  // ---- Helper: get ships in a port by slug ----
  List<Ship> getShipsInPort(String portSlug) {
    return _myShips
        .where((s) => s.currentPortId == portSlug && s.status == 'idle')
        .toList();
  }

  // ===================== LOAD METHODS =====================

  Future<void> loadPorts() async {
    _allPorts = GameConstants.ports;
    await DbIdMapper.init(_supabase);
    notifyListeners();
  }

  Future<void> loadMyShips() async {
    final uid = _userId;
    if (uid == null) return;
    try {
      final response =
          await _supabase.from('ships').select().eq('owner_id', uid);
      _myShips = response.map<Ship>((e) => Ship.fromJson(e)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('loadMyShips error: $e');
    }
  }

  Future<void> loadMarketPrices(String portId) async {
    _currentPortId = portId;
    _currentPortPrices = [];

    final dbPortId = DbIdMapper.portSlugToInt(portId);
    if (dbPortId == null) {
      notifyListeners();
      return;
    }

    try {
      final response = await _supabase
          .from('port_market')
          .select()
          .eq('port_id', dbPortId);
      _currentPortPrices =
          response.map<PortPrice>((e) => PortPrice.fromJson(e)).toList();
    } catch (e) {
      _currentPortPrices = [];
      debugPrint('loadMarketPrices error: $e');
    }
    notifyListeners();
  }

  Future<void> loadMyVoyages() async {
    final uid = _userId;
    if (uid == null) return;
    try {
      final shipsResp = await _supabase
          .from('ships')
          .select('id')
          .eq('owner_id', uid);
      final shipIds =
          shipsResp.map<String>((e) => e['id'] as String).toList();

      if (shipIds.isEmpty) {
        _myVoyages = [];
        notifyListeners();
        return;
      }

      final response = await _supabase
          .from('voyages')
          .select()
          .inFilter('ship_id', shipIds);
      _myVoyages =
          response.map<Voyage>((e) => Voyage.fromJson(e)).toList();
      notifyListeners();
    } catch (e) {
      _myVoyages = [];
      debugPrint('loadMyVoyages error: $e');
    }
  }

  Future<void> loadShipMarket() async {
    try {
      final listings = await _supabase
          .from('ship_market')
          .select()
          .eq('status', 'listed');

      final List<ShipMarketListing> result = [];
      for (final listing in listings) {
        final shipId = listing['ship_id'] as String? ?? '';
        Map<String, dynamic>? shipData;
        if (shipId.isNotEmpty) {
          try {
            shipData = await _supabase
                .from('ships')
                .select('name, ship_type_id, condition_pct')
                .eq('id', shipId)
                .maybeSingle();
          } catch (_) {}
        }
        result.add(
            ShipMarketListing.fromJson(listing, shipData: shipData));
      }
      _shipMarketListings = result;
    } catch (e) {
      _shipMarketListings = [];
      debugPrint('loadShipMarket error: $e');
    }
    notifyListeners();
  }

  Future<void> loadMyListings() async {
    final uid = _userId;
    if (uid == null) return;
    try {
      final response =
          await _supabase.from('ship_market').select().eq('seller_id', uid);
      _myListings = response
          .map<ShipMarketListing>((e) => ShipMarketListing.fromJson(e))
          .toList();
    } catch (e) {
      _myListings = [];
      debugPrint('loadMyListings error: $e');
    }
    notifyListeners();
  }

  Future<void> loadEmployees() async {
    final uid = _userId;
    if (uid == null) return;
    try {
      final response =
          await _supabase.from('employees').select().eq('owner_id', uid);
      _employees =
          response.map<Employee>((e) => Employee.fromJson(e)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('loadEmployees error: $e');
    }
  }

  Future<void> loadLoans() async {
    final uid = _userId;
    if (uid == null) return;
    try {
      final response = await _supabase
          .from('loans')
          .select()
          .eq('borrower_id', uid)
          .eq('status', 'active');
      _loans = response.map<Loan>((e) => Loan.fromJson(e)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('loadLoans error: $e');
    }
  }

  Future<void> loadTransactions() async {
    final uid = _userId;
    if (uid == null) return;
    try {
      final response = await _supabase
          .from('transactions')
          .select()
          .eq('player_id', uid)
          .order('created_at', ascending: false);
      _transactions =
          response.map<Transaction>((e) => Transaction.fromJson(e)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('loadTransactions error: $e');
    }
  }

  Future<void> loadFactories() async {
    final uid = _userId;
    if (uid == null) return;
    try {
      final response =
          await _supabase.from('factories').select().eq('owner_id', uid);
      _factories =
          response.map<Factory>((e) => Factory.fromJson(e)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('loadFactories error: $e');
    }
  }

  Future<void> loadDashboard() async {
    final uid = _userId;
    if (uid == null) return;
    _isLoading = true;
    notifyListeners();

    try {
      await Future.wait([
        loadMyShips(),
        loadMyVoyages(),
        loadTransactions(),
      ]);

      final idle = _myShips.where((s) => s.status == 'idle').length;
      final transit = _myShips.where((s) => s.status == 'in_transit').length;
      final docked = _myShips.where((s) => s.status == 'in_dock').length;
      final activeV =
          _myVoyages.where((v) => v.isActive).length;
      final completedV =
          _myVoyages.where((v) => v.status == 'completed').length;

      int totalProfit = 0;
      for (final t in _transactions) {
        totalProfit += t.amount;
      }

      _dashboardData = DashboardData(
        activeShips: _myShips.length,
        idleShips: idle,
        inTransitShips: transit,
        dockedShips: docked,
        activeVoyages: activeV,
        totalShipsOwned: _myShips.length,
        totalVoyagesCompleted: completedV,
        totalProfit: totalProfit,
        recentTransactions: _transactions.take(10).toList(),
      );
    } catch (e) {
      debugPrint('loadDashboard error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ===================== ACTION METHODS =====================

  Future<bool> buyShip(String shipTypeId, String shipName) async {
    final uid = _userId;
    if (uid == null) return false;
    final shipType = GameConstants.findShipType(shipTypeId);
    if (shipType == null) return false;

    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final profileResponse = await _supabase
          .from('profiles')
          .select('money')
          .eq('id', uid)
          .maybeSingle();
      final currentMoney =
          (profileResponse?['money'] as num?)?.toInt() ?? 0;
      if (currentMoney < shipType.basePrice) {
        _errorMessage = 'Недостаточно средств для покупки';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final maxFuel = shipType.dwt * GameConstants.fuelTankMultiplier;
      final dbShipTypeId = DbIdMapper.shipTypeSlugToInt(shipTypeId);
      final dbPortId = DbIdMapper.portSlugToInt('rotterdam');

      if (dbShipTypeId == null || dbPortId == null) {
        _errorMessage = 'Ошибка маппинга типов в БД';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final newShip = {
        'owner_id': uid,
        'ship_type_id': dbShipTypeId,
        'name': shipName.trim(),
        'status': 'idle',
        'condition_pct': 100,
        'fuel_level': maxFuel * 0.5,
        'max_fuel': maxFuel,
        'current_port_id': dbPortId,
        'purchase_price': shipType.basePrice,
      };
      await _supabase.from('ships').insert(newShip);

      await _supabase
          .from('profiles')
          .update({'money': currentMoney - shipType.basePrice}).eq('id', uid);

      await _supabase.from('transactions').insert({
        'player_id': uid,
        'type': 'ship_purchase',
        'description': 'Покупка корабля: ${shipType.name}',
        'amount': -shipType.basePrice,
      });

      await loadMyShips();
      return true;
    } catch (e) {
      _errorMessage = 'Ошибка покупки корабля: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> sellShip(String shipId, int price) async {
    final uid = _userId;
    if (uid == null) return false;

    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final shipResponse = await _supabase
          .from('ships')
          .select()
          .eq('id', shipId)
          .eq('owner_id', uid)
          .maybeSingle();
      if (shipResponse == null) {
        _errorMessage = 'Корабль не найден';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      await _supabase.from('ship_market').insert({
        'ship_id': shipId,
        'seller_id': uid,
        'asking_price': price,
        'status': 'listed',
      });

      // Don't change ship status — ship_status_enum doesn't have 'on_market'
      // The ship_market listing itself tracks the sale status.

      await loadMyShips();
      await loadMyListings();
      return true;
    } catch (e) {
      _errorMessage = 'Ошибка выставления на продажу: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> buyFromMarket(String listingId) async {
    final uid = _userId;
    if (uid == null) return false;

    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final listingResponse = await _supabase
          .from('ship_market')
          .select()
          .eq('id', listingId)
          .eq('status', 'listed')
          .maybeSingle();
      if (listingResponse == null) {
        _errorMessage = 'Листинг не найден или уже продан';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final listing = ShipMarketListing.fromJson(listingResponse);
      if (listing.sellerId == uid) {
        _errorMessage = 'Нельзя купить свой собственный корабль';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final buyerProfileResponse = await _supabase
          .from('profiles')
          .select('money')
          .eq('id', uid)
          .maybeSingle();
      final buyerMoney =
          (buyerProfileResponse?['money'] as num?)?.toInt() ?? 0;

      final fee = (listing.price * GameConstants.marketFee).ceil();
      final totalCost = listing.price + fee;

      if (buyerMoney < totalCost) {
        _errorMessage =
            'Недостаточно средств. Нужно: \$${totalCost.toStringAsFixed(0)}';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final sellerProfileResponse = await _supabase
          .from('profiles')
          .select('money')
          .eq('id', listing.sellerId)
          .maybeSingle();
      final sellerMoney =
          (sellerProfileResponse?['money'] as num?)?.toInt() ?? 0;

      await _supabase
          .from('profiles')
          .update({'money': buyerMoney - totalCost}).eq('id', uid);
      await _supabase
          .from('profiles')
          .update({'money': sellerMoney + listing.price})
          .eq('id', listing.sellerId);

      // Transfer ship ownership — use owner_id (correct DB column)
      await _supabase.from('ships').update({
        'owner_id': uid,
        'status': 'idle',
        'current_port_id': null,
      }).eq('id', listing.shipId);

      await _supabase
          .from('ship_market')
          .update({'status': 'sold'}).eq('id', listingId);

      await _supabase.from('transactions').insert({
        'player_id': uid,
        'type': 'ship_market_purchase',
        'description': 'Покупка с рынка: ${listing.shipName}',
        'amount': -totalCost,
      });

      await _supabase.from('transactions').insert({
        'player_id': listing.sellerId,
        'type': 'ship_market_sale',
        'description': 'Продажа на рынке: ${listing.shipName}',
        'amount': listing.price,
      });

      await loadMyShips();
      await loadShipMarket();
      return true;
    } catch (e) {
      _errorMessage = 'Ошибка покупки с рынка: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> startVoyage(
      String shipId, String destPortId, String? goodId, int quantity) async {
    final uid = _userId;
    if (uid == null) return false;

    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final shipResponse = await _supabase
          .from('ships')
          .select()
          .eq('id', shipId)
          .eq('owner_id', uid)
          .maybeSingle();
      if (shipResponse == null) {
        _errorMessage = 'Корабль не найден';
        _isLoading = false;
        notifyListeners();
        return false;
      }
      final ship = Ship.fromJson(shipResponse);
      if (ship.status != 'idle') {
        _errorMessage = 'Корабль не готов к рейсу';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final originPort = GameConstants.findPort(ship.currentPortId ?? '');
      final destPort = GameConstants.findPort(destPortId);
      if (originPort == null || destPort == null) {
        _errorMessage = 'Порт отправления или назначения не найден';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final distance = _calculateDistance(
        originPort.latitude,
        originPort.longitude,
        destPort.latitude,
        destPort.longitude,
      );

      final shipType = GameConstants.findShipType(ship.shipTypeId);
      final speed = shipType?.speed ?? 12.0;
      final estimatedHours = distance / speed;

      final fuelNeeded = distance * (shipType?.fuelPerNm ?? 20.0);
      if (ship.fuelLevel < fuelNeeded) {
        _errorMessage =
            'Недостаточно топлива. Нужно: ${fuelNeeded.toStringAsFixed(0)} л.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final startedAt = DateTime.now();
      final eta = startedAt.add(
          Duration(milliseconds: (estimatedHours * 3600000).round()));

      final dbOriginId = DbIdMapper.portSlugToInt(ship.currentPortId);
      final dbDestId = DbIdMapper.portSlugToInt(destPortId);

      if (dbOriginId == null || dbDestId == null) {
        _errorMessage = 'Ошибка маппинга портов в БД';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // If cargo is selected, convert good slug
      int? dbGoodId;
      if (goodId != null) {
        dbGoodId = DbIdMapper.goodSlugToInt(goodId);
        if (dbGoodId == null) {
          _errorMessage = 'Груз не найден в БД';
          _isLoading = false;
          notifyListeners();
          return false;
        }
      }

      final voyage = {
        'ship_id': shipId,
        'origin_port_id': dbOriginId,
        'destination_port_id': dbDestId,
        'cargo_good_id': dbGoodId,
        'cargo_quantity': quantity,
        'status': 'in_transit',
        'departure_time': startedAt.toIso8601String(),
        'estimated_arrival': eta.toIso8601String(),
        'distance_nm': distance,
        'estimated_hours': estimatedHours,
        'fuel_consumed': fuelNeeded,
        'revenue': 0,
        'cost': (fuelNeeded * GameConstants.fuelPricePerLiter).round(),
      };
      await _supabase.from('voyages').insert(voyage);

      await _supabase.from('ships').update({
        'status': 'in_transit',
        'destination_port_id': dbDestId,
        'fuel_level': ship.fuelLevel - fuelNeeded,
        'last_voyage_at': startedAt.toIso8601String(),
        'current_port_id': null,
      }).eq('id', shipId);

      final newCondition =
          (ship.condition - GameConstants.conditionLossPerVoyage)
              .clamp(0, 100)
              .round();
      await _supabase
          .from('ships')
          .update({'condition_pct': newCondition}).eq('id', shipId);

      await loadMyShips();
      await loadMyVoyages();
      return true;
    } catch (e) {
      _errorMessage = 'Ошибка назначения рейса: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> buyFuel(String portId, String shipId, double liters) async {
    final uid = _userId;
    if (uid == null) return false;

    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final shipResponse = await _supabase
          .from('ships')
          .select()
          .eq('id', shipId)
          .eq('owner_id', uid)
          .maybeSingle();
      if (shipResponse == null) {
        _errorMessage = 'Корабль не найден';
        _isLoading = false;
        notifyListeners();
        return false;
      }
      final ship = Ship.fromJson(shipResponse);

      final fillAmount = liters.clamp(0, ship.maxFuel - ship.fuelLevel);
      if (fillAmount <= 0) {
        _errorMessage = 'Бак уже полон';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final cost = (fillAmount * GameConstants.fuelPricePerLiter).round();

      final profileResponse = await _supabase
          .from('profiles')
          .select('money')
          .eq('id', uid)
          .maybeSingle();
      final currentMoney =
          (profileResponse?['money'] as num?)?.toInt() ?? 0;
      if (currentMoney < cost) {
        _errorMessage = 'Недостаточно средств для заправки';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      await _supabase
          .from('ships')
          .update({'fuel_level': ship.fuelLevel + fillAmount}).eq('id', shipId);

      await _supabase
          .from('profiles')
          .update({'money': currentMoney - cost}).eq('id', uid);

      await _supabase.from('transactions').insert({
        'player_id': uid,
        'type': 'fuel',
        'description': 'Заправка: ${fillAmount.toStringAsFixed(0)} л.',
        'amount': -cost,
      });

      await loadMyShips();
      return true;
    } catch (e) {
      _errorMessage = 'Ошибка заправки: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> repairShip(String shipId) async {
    final uid = _userId;
    if (uid == null) return false;

    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final shipResponse = await _supabase
          .from('ships')
          .select()
          .eq('id', shipId)
          .eq('owner_id', uid)
          .maybeSingle();
      if (shipResponse == null) {
        _errorMessage = 'Корабль не найден';
        return false;
      }
      final ship = Ship.fromJson(shipResponse);

      final repairPoints = 100 - ship.condition;
      if (repairPoints <= 0) {
        _errorMessage = 'Корабль не нуждается в ремонте';
        return false;
      }

      final cost = (repairPoints * GameConstants.repairCostPerPoint).round();

      final profileResponse = await _supabase
          .from('profiles')
          .select('money')
          .eq('id', uid)
          .maybeSingle();
      final currentMoney =
          (profileResponse?['money'] as num?)?.toInt() ?? 0;
      if (currentMoney < cost) {
        _errorMessage = 'Недостаточно средств. Стоимость: \$$cost';
        return false;
      }

      await _supabase
          .from('ships')
          .update({'condition_pct': 100}).eq('id', shipId);

      await _supabase
          .from('profiles')
          .update({'money': currentMoney - cost}).eq('id', uid);

      await _supabase.from('transactions').insert({
        'player_id': uid,
        'type': 'repair',
        'description': 'Ремонт корабля: ${ship.name}',
        'amount': -cost,
      });

      await loadMyShips();
      return true;
    } catch (e) {
      _errorMessage = 'Ошибка ремонта: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> hireEmployee(String role, String name, String? portId) async {
    final uid = _userId;
    if (uid == null) return false;

    // Map old role names to DB enum values
    final dbRole = _mapEmployeeRole(role);

    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      int salary;
      switch (role) {
        case 'captain':
          salary = GameConstants.baseCaptainSalary;
          break;
        case 'engineer':
          salary = GameConstants.baseEngineerSalary;
          break;
        case 'sailor':
          salary = GameConstants.baseSailorSalary;
          break;
        case 'broker':
          salary = GameConstants.baseBrokerSalary;
          break;
        default:
          salary = 3000;
      }

      final profileResponse = await _supabase
          .from('profiles')
          .select('money')
          .eq('id', uid)
          .maybeSingle();
      final currentMoney =
          (profileResponse?['money'] as num?)?.toInt() ?? 0;
      if (currentMoney < salary) {
        _errorMessage = 'Недостаточно средств для найма';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      await _supabase.from('employees').insert({
        'owner_id': uid,
        'name': name.trim(),
        'role': dbRole,
        'skill_level': 1,
        'salary_daily': salary,
        'port_id': DbIdMapper.portSlugToInt(portId),
      });

      await _supabase
          .from('profiles')
          .update({'money': currentMoney - salary}).eq('id', uid);

      await _supabase.from('transactions').insert({
        'player_id': uid,
        'type': 'employee_hire',
        'description': 'Найм: $name ($role)',
        'amount': -salary,
      });

      await loadEmployees();
      return true;
    } catch (e) {
      _errorMessage = 'Ошибка найма сотрудника: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _mapEmployeeRole(String role) {
    switch (role) {
      case 'captain':
        return 'crew_manager';
      case 'engineer':
        return 'crew_manager';
      case 'sailor':
        return 'crew_manager';
      case 'broker':
        return 'agent';
      default:
        return 'agent';
    }
  }

  Future<bool> takeLoan(int amount, int termMonths) async {
    final uid = _userId;
    if (uid == null) return false;

    if (amount < GameConstants.minLoanAmount ||
        amount > GameConstants.maxLoanAmount) {
      _errorMessage =
          'Сумма кредита: от \$${GameConstants.minLoanAmount} до \$${GameConstants.maxLoanAmount}';
      notifyListeners();
      return false;
    }

    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final interestRate = GameConstants.maxLoanInterest;
      final totalRepay =
          (amount * (1 + interestRate * termMonths / 12)).ceil();
      final monthlyPayment = (totalRepay / termMonths).ceil();

      await _supabase.from('loans').insert({
        'borrower_id': uid,
        'amount': amount,
        'remaining_balance': totalRepay,
        'interest_rate': interestRate,
        'monthly_payment': monthlyPayment,
        'total_months': termMonths,
        'months_paid': 0,
        'status': 'active',
      });

      final profileResponse = await _supabase
          .from('profiles')
          .select('money')
          .eq('id', uid)
          .maybeSingle();
      final currentMoney =
          (profileResponse?['money'] as num?)?.toInt() ?? 0;
      await _supabase
          .from('profiles')
          .update({'money': currentMoney + amount}).eq('id', uid);

      await _supabase.from('transactions').insert({
        'player_id': uid,
        'type': 'credit',
        'description': 'Кредит: \$$amount на $termMonths мес.',
        'amount': amount,
      });

      await loadLoans();
      return true;
    } catch (e) {
      _errorMessage = 'Ошибка оформления кредита: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ---- Distance calculation (haversine) ----
  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const R = 6371.0; // km
    final dLat = _degToRad(lat2 - lat1);
    final dLon = _degToRad(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degToRad(lat1)) *
            math.cos(_degToRad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return R * c;
  }

  double _degToRad(double deg) => deg * math.pi / 180;
}
