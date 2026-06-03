import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/game_constants.dart';

// ===================== MODELS =====================

class Ship {
  final String id;
  final String ownerId;
  final String shipTypeId;
  final String name;
  final String status; // idle, in_transit, in_dock, maintenance
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
      shipTypeId: json['ship_type_id'] as String? ?? '',
      name: json['name'] as String? ?? 'Безымянный',
      status: json['status'] as String? ?? 'idle',
      condition: (json['condition'] as num?)?.toInt() ?? 100,
      fuelLevel: (json['fuel_level'] as num?)?.toDouble() ?? 0.0,
      maxFuel: (json['max_fuel'] as num?)?.toDouble() ?? 0.0,
      currentPortId: json['current_port_id'] as String?,
      destinationPortId: json['destination_port_id'] as String?,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
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
        'condition': condition,
        'fuel_level': fuelLevel,
        'max_fuel': maxFuel,
        'current_port_id': currentPortId,
        'destination_port_id': destinationPortId,
        'created_at': createdAt.toIso8601String(),
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
  final String id;
  final String portId;
  final String goodId;
  final int buyPrice;
  final int sellPrice;
  final int available;
  final DateTime updatedAt;

  const PortPrice({
    required this.id,
    required this.portId,
    required this.goodId,
    required this.buyPrice,
    required this.sellPrice,
    required this.available,
    required this.updatedAt,
  });

  factory PortPrice.fromJson(Map<String, dynamic> json) {
    return PortPrice(
      id: json['id'] as String? ?? '',
      portId: json['port_id'] as String? ?? '',
      goodId: json['good_id'] as String? ?? '',
      buyPrice: (json['buy_price'] as num?)?.toInt() ?? 0,
      sellPrice: (json['sell_price'] as num?)?.toInt() ?? 0,
      available: (json['available'] as num?)?.toInt() ?? 0,
      updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

class Voyage {
  final String id;
  final String shipId;
  final String ownerId;
  final String originPortId;
  final String destinationPortId;
  final String? goodId;
  final int quantity;
  final double distance;
  final double estimatedHours;
  final DateTime startedAt;
  final DateTime? eta;
  final String status; // active, completed, cancelled
  final int? revenue;
  final int? fuelCost;

  const Voyage({
    required this.id,
    required this.shipId,
    required this.ownerId,
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
      ownerId: json['owner_id'] as String? ?? '',
      originPortId: json['origin_port_id'] as String? ?? '',
      destinationPortId: json['destination_port_id'] as String? ?? '',
      goodId: json['good_id'] as String?,
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      distance: (json['distance'] as num?)?.toDouble() ?? 0.0,
      estimatedHours: (json['estimated_hours'] as num?)?.toDouble() ?? 0.0,
      startedAt: DateTime.tryParse(json['started_at'] as String? ?? '') ??
          DateTime.now(),
      eta: json['eta'] != null
          ? DateTime.tryParse(json['eta'] as String)
          : null,
      status: json['status'] as String? ?? 'active',
      revenue: (json['revenue'] as num?)?.toInt(),
      fuelCost: (json['fuel_cost'] as num?)?.toInt(),
    );
  }

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
  final String type; // income, expense, loan, loan_repay
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
      ownerId: json['owner_id'] as String? ?? '',
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

  factory ShipMarketListing.fromJson(Map<String, dynamic> json) {
    return ShipMarketListing(
      id: json['id'] as String? ?? '',
      shipId: json['ship_id'] as String? ?? '',
      sellerId: json['seller_id'] as String? ?? '',
      sellerName: json['seller_name'] as String? ?? 'Неизвестно',
      shipName: json['ship_name'] as String? ?? 'Безымянный',
      shipTypeId: json['ship_type_id'] as String? ?? '',
      condition: (json['condition'] as num?)?.toInt() ?? 100,
      price: (json['price'] as num?)?.toInt() ?? 0,
      listedAt: DateTime.tryParse(json['listed_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

class Employee {
  final String id;
  final String ownerId;
  final String name;
  final String role; // captain, engineer, sailor, broker
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
      skill: (json['skill'] as num?)?.toInt() ?? 1,
      salary: (json['salary'] as num?)?.toInt() ?? 0,
      assignedPortId: json['assigned_port_id'] as String?,
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
  final int monthsRemaining;
  final DateTime takenAt;
  final String status; // active, paid, defaulted

  const Loan({
    required this.id,
    required this.ownerId,
    required this.amount,
    required this.remaining,
    required this.interestRate,
    required this.termMonths,
    required this.monthsRemaining,
    required this.takenAt,
    required this.status,
  });

  factory Loan.fromJson(Map<String, dynamic> json) {
    return Loan(
      id: json['id'] as String? ?? '',
      ownerId: json['owner_id'] as String? ?? '',
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      remaining: (json['remaining'] as num?)?.toInt() ?? 0,
      interestRate: (json['interest_rate'] as num?)?.toDouble() ?? 0.0,
      termMonths: (json['term_months'] as num?)?.toInt() ?? 0,
      monthsRemaining: (json['months_remaining'] as num?)?.toInt() ?? 0,
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
  final String status; // active, building, idle
  final String? inputGoodId;
  final String? outputGoodId;
  final DateTime createdAt;

  const Factory({
    required this.id,
    required this.ownerId,
    required this.type,
    this.portId,
    required this.level,
    required this.status,
    this.inputGoodId,
    this.outputGoodId,
    required this.createdAt,
  });

  factory Factory.fromJson(Map<String, dynamic> json) {
    return Factory(
      id: json['id'] as String? ?? '',
      ownerId: json['owner_id'] as String? ?? '',
      type: json['type'] as String? ?? '',
      portId: json['port_id'] as String?,
      level: (json['level'] as num?)?.toInt() ?? 1,
      status: json['status'] as String? ?? 'idle',
      inputGoodId: json['input_good_id'] as String?,
      outputGoodId: json['output_good_id'] as String?,
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
  SupabaseClient? _supabase;

  GameProvider() {
    try {
      _supabase = Supabase.instance.client;
    } catch (_) {
      _supabase = null;
    }
  }

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
  String? get _userId => _supabase?.auth.currentUser?.id;

  // ===================== LOAD METHODS =====================

  Future<void> loadPorts() async {
    // Ports are defined in GameConstants — use those
    _allPorts = GameConstants.ports;
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
    try {
      final response = await _supabase
          .from('port_market')
          .select()
          .eq('port_id', portId);
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
      final response =
          await _supabase.from('voyages').select().eq('owner_id', uid);
      _myVoyages = response.map<Voyage>((e) => Voyage.fromJson(e)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('loadMyVoyages error: $e');
    }
  }

  Future<void> loadShipMarket() async {
    try {
      final response = await _supabase
          .from('ship_market')
          .select()
          .eq('status', 'active');
      _shipMarketListings =
          response.map<ShipMarketListing>((e) => ShipMarketListing.fromJson(e))
              .toList();
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
      _myListings =
          response.map<ShipMarketListing>((e) => ShipMarketListing.fromJson(e))
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
          .eq('owner_id', uid)
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
          .eq('owner_id', uid)
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
      final activeV = _myVoyages.where((v) => v.status == 'active').length;
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

      // Check money
      final profileResponse = await _supabase
          .from('profiles')
          .select('money')
          .eq('id', uid)
          .maybeSingle();
      final currentMoney = (profileResponse?['money'] as num?)?.toInt() ?? 0;
      if (currentMoney < shipType.basePrice) {
        _errorMessage = 'Недостаточно средств для покупки';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final maxFuel = shipType.dwt * GameConstants.fuelTankMultiplier;

      // Insert ship
      final newShip = {
        'owner_id': uid,
        'ship_type_id': shipTypeId,
        'name': shipName.trim(),
        'status': 'idle',
        'condition': 100,
        'fuel_level': maxFuel * 0.5,
        'max_fuel': maxFuel,
        'current_port_id': 'rotterdam', // default starting port
      };
      await _supabase.from('ships').insert(newShip);

      // Deduct money
      await _supabase
          .from('profiles')
          .update({'money': currentMoney - shipType.basePrice}).eq('id', uid);

      // Record transaction
      await _supabase.from('transactions').insert({
        'owner_id': uid,
        'type': 'expense',
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

      // Get ship info
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

      // Get seller company name
      final profileResponse = await _supabase
          .from('profiles')
          .select('company_name')
          .eq('id', uid)
          .maybeSingle();
      final sellerName =
          (profileResponse?['company_name'] as String?) ?? 'Неизвестно';

      // Create market listing
      await _supabase.from('ship_market').insert({
        'ship_id': shipId,
        'seller_id': uid,
        'seller_name': sellerName,
        'ship_name': ship.name,
        'ship_type_id': ship.shipTypeId,
        'condition': ship.condition,
        'price': price,
        'status': 'active',
      });

      // Update ship status to on_market
      await _supabase
          .from('ships')
          .update({'status': 'on_market'}).eq('id', shipId);

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

      // Get listing
      final listingResponse = await _supabase
          .from('ship_market')
          .select()
          .eq('id', listingId)
          .eq('status', 'active')
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

      // Check buyer money
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
            'Недостаточно средств. Нужно: \$${totalCost.toStringAsFixed(0)} (включая комиссию)';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Get seller profile
      final sellerProfileResponse = await _supabase
          .from('profiles')
          .select('money')
          .eq('id', listing.sellerId)
          .maybeSingle();
      final sellerMoney =
          (sellerProfileResponse?['money'] as num?)?.toInt() ?? 0;

      // Update buyer money
      await _supabase
          .from('profiles')
          .update({'money': buyerMoney - totalCost}).eq('id', uid);

      // Update seller money
      await _supabase
          .from('profiles')
          .update({'money': sellerMoney + listing.price})
          .eq('id', listing.sellerId);

      // Transfer ship ownership
      await _supabase.from('ships').update({
        'owner_id': uid,
        'status': 'idle',
        'current_port_id': 'rotterdam',
        'destination_port_id': null,
      }).eq('id', listing.shipId);

      // Mark listing as sold
      await _supabase
          .from('ship_market')
          .update({'status': 'sold'}).eq('id', listingId);

      // Buyer transaction
      await _supabase.from('transactions').insert({
        'owner_id': uid,
        'type': 'expense',
        'description':
            'Покупка с рынка: ${listing.shipName} (комиссия: \$$fee)',
        'amount': -totalCost,
      });

      // Seller transaction
      await _supabase.from('transactions').insert({
        'owner_id': listing.sellerId,
        'type': 'income',
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

      // Get ship
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

      // Calculate distance (haversine simplified)
      final distance = _calculateDistance(
        originPort.latitude,
        originPort.longitude,
        destPort.latitude,
        destPort.longitude,
      );

      final shipType = GameConstants.findShipType(ship.shipTypeId);
      final speed = shipType?.speed ?? 12.0;
      final estimatedHours = distance / speed;

      // Calculate fuel needed
      final fuelNeeded = distance * (shipType?.fuelPerNm ?? 20.0);
      if (ship.fuelLevel < fuelNeeded) {
        _errorMessage =
            'Недостаточно топлива. Нужно: ${fuelNeeded.toStringAsFixed(0)} л.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final startedAt = DateTime.now();
      final eta = startedAt.add(Duration(
          milliseconds: (estimatedHours * 3600000).round()));

      // Create voyage
      final voyage = {
        'ship_id': shipId,
        'owner_id': uid,
        'origin_port_id': ship.currentPortId,
        'destination_port_id': destPortId,
        'good_id': goodId,
        'quantity': quantity,
        'distance': distance,
        'estimated_hours': estimatedHours,
        'started_at': startedAt.toIso8601String(),
        'eta': eta.toIso8601String(),
        'status': 'active',
        'fuel_cost': (fuelNeeded * GameConstants.fuelPricePerLiter).round(),
      };
      await _supabase.from('voyages').insert(voyage);

      // Update ship
      await _supabase.from('ships').update({
        'status': 'in_transit',
        'destination_port_id': destPortId,
        'fuel_level': ship.fuelLevel - fuelNeeded,
        'last_voyage_at': startedAt.toIso8601String(),
        'current_port_id': null,
      }).eq('id', shipId);

      // Deduct condition
      final newCondition =
          (ship.condition - GameConstants.conditionLossPerVoyage)
              .clamp(0, 100)
              .round();
      await _supabase
          .from('ships')
          .update({'condition': newCondition}).eq('id', shipId);

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

      // Get ship
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

      // Check money
      final profileResponse = await _supabase
          .from('profiles')
          .select('money')
          .eq('id', uid)
          .maybeSingle();
      final currentMoney = (profileResponse?['money'] as num?)?.toInt() ?? 0;
      if (currentMoney < cost) {
        _errorMessage = 'Недостаточно средств для заправки';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Update ship fuel
      await _supabase
          .from('ships')
          .update({'fuel_level': ship.fuelLevel + fillAmount}).eq('id', shipId);

      // Deduct money
      await _supabase
          .from('profiles')
          .update({'money': currentMoney - cost}).eq('id', uid);

      // Record transaction
      await _supabase.from('transactions').insert({
        'owner_id': uid,
        'type': 'expense',
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

  Future<bool> hireEmployee(String role, String name, String? portId) async {
    final uid = _userId;
    if (uid == null) return false;

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

      // Check money (1 month salary for hiring)
      final profileResponse = await _supabase
          .from('profiles')
          .select('money')
          .eq('id', uid)
          .maybeSingle();
      final currentMoney = (profileResponse?['money'] as num?)?.toInt() ?? 0;
      if (currentMoney < salary) {
        _errorMessage = 'Недостаточно средств для найма';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      await _supabase.from('employees').insert({
        'owner_id': uid,
        'name': name.trim(),
        'role': role,
        'skill': 1,
        'salary': salary,
        'assigned_port_id': portId,
      });

      // Deduct money
      await _supabase
          .from('profiles')
          .update({'money': currentMoney - salary}).eq('id', uid);

      await _supabase.from('transactions').insert({
        'owner_id': uid,
        'type': 'expense',
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
      final totalRepay = (amount * (1 + interestRate * termMonths / 12))
          .ceil();

      await _supabase.from('loans').insert({
        'owner_id': uid,
        'amount': amount,
        'remaining': totalRepay,
        'interest_rate': interestRate,
        'term_months': termMonths,
        'months_remaining': termMonths,
        'status': 'active',
      });

      // Add money
      final profileResponse = await _supabase
          .from('profiles')
          .select('money')
          .eq('id', uid)
          .maybeSingle();
      final currentMoney = (profileResponse?['money'] as num?)?.toInt() ?? 0;
      await _supabase
          .from('profiles')
          .update({'money': currentMoney + amount}).eq('id', uid);

      await _supabase.from('transactions').insert({
        'owner_id': uid,
        'type': 'loan',
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
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371.0; // km
    final dLat = _degToRad(lat2 - lat1);
    final dLon = _degToRad(lon2 - lon1);
    final a = _sin(dLat / 2) * _sin(dLat / 2) +
        _cos(_degToRad(lat1)) *
            _cos(_degToRad(lat2)) *
            _sin(dLon / 2) *
            _sin(dLon / 2);
    final c = 2 * _atan2(_sqrt(a), _sqrt(1 - a));
    return R * c;
  }

  double _degToRad(double deg) => deg * math.pi / 180.0;
  double _sin(double x) => math.sin(x);
  double _cos(double x) => math.cos(x);
  double _sqrt(double x) => math.sqrt(x);
  double _atan2(double y, double x) => math.atan2(y, x);

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ---- Get ships in a specific port ----
  List<Ship> getShipsInPort(String portId) {
    return _myShips.where((s) => s.currentPortId == portId && s.status == 'idle').toList();
  }
}
