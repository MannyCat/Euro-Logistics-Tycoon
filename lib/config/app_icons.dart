import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Centralized icon mapping using Lucide Icons.
/// All screens reference icons from here for consistency.
class AppIcons {
  AppIcons._();

  // ===== NAVIGATION =====
  static const IconData contracts = LucideIcons.fileText;
  static const IconData contractsOutlined = LucideIcons.fileText;
  static const IconData fleet = LucideIcons.truck;
  static const IconData fleetOutlined = LucideIcons.truck;
  static const IconData drivers = LucideIcons.users;
  static const IconData driversOutlined = LucideIcons.users;
  static const IconData warehouses = LucideIcons.warehouse;
  static const IconData warehousesOutlined = LucideIcons.warehouse;
  static const IconData finances = LucideIcons.receipt;
  static const IconData financesOutlined = LucideIcons.receipt;
  static const IconData eventLog = LucideIcons.scrollText;
  static const IconData eventLogOutlined = LucideIcons.scrollText;
  static const IconData market = LucideIcons.store;
  static const IconData marketOutlined = LucideIcons.store;
  static const IconData leaderboard = LucideIcons.trophy;
  static const IconData leaderboardOutlined = LucideIcons.trophy;
  static const IconData achievements = LucideIcons.medal;
  static const IconData achievementsOutlined = LucideIcons.medal;
  static const IconData clan = LucideIcons.shield;
  static const IconData clanOutlined = LucideIcons.shield;
  static const IconData analytics = LucideIcons.barChart3;
  static const IconData analyticsOutlined = LucideIcons.barChart3;
  static const IconData settings = LucideIcons.settings;
  static const IconData settingsOutlined = LucideIcons.settings;

  // ===== ACTIONS =====
  static const IconData add = LucideIcons.plus;
  static const IconData addCircle = LucideIcons.circlePlus;
  static const IconData close = LucideIcons.x;
  static const IconData refresh = LucideIcons.refreshCw;
  static const IconData edit = LucideIcons.pencil;
  static const IconData delete = LucideIcons.trash2;
  static const IconData search = LucideIcons.search;
  static const IconData filter = LucideIcons.filter;
  static const IconData sort = LucideIcons.arrowUpDown;
  static const IconData more = LucideIcons.moreVertical;
  static const IconData check = LucideIcons.check;
  static const IconData checkCircle = LucideIcons.circleCheck;
  static const IconData checkCircleOutline = LucideIcons.circleCheck;
  static const IconData arrowRight = LucideIcons.arrowRight;
  static const IconData arrowForward = LucideIcons.arrowRight;
  static const IconData arrowUp = LucideIcons.arrowUp;
  static const IconData arrowDown = LucideIcons.arrowDown;
  static const IconData arrowLeft = LucideIcons.arrowLeft;
  static const IconData back = LucideIcons.chevronLeft;
  static const IconData forward = LucideIcons.chevronRight;

  // ===== TRUCK / TRANSPORT =====
  static const IconData truck = LucideIcons.truck;
  static const IconData truckLoading = LucideIcons.truck;
  static const IconData fuel = LucideIcons.fuel;
  static const IconData gasStation = LucideIcons.fuel;
  static const IconData wrench = LucideIcons.wrench;
  static const IconData upgrade = LucideIcons.arrowUpCircle;
  static const IconData sell = LucideIcons.tag;
  static const IconData buy = LucideIcons.shoppingCart;

  // ===== DRIVER =====
  static const IconData person = LucideIcons.user;
  static const IconData personAdd = LucideIcons.userPlus;
  static const IconData personRemove = LucideIcons.userMinus;
  static const IconData personPin = LucideIcons.mapPin;
  static const IconData personOutline = LucideIcons.user;
  static const IconData people = LucideIcons.users;
  static const IconData groups = LucideIcons.users;

  // ===== WEATHER =====
  static const IconData sun = LucideIcons.sun;
  static const IconData rain = LucideIcons.cloudRain;
  static const IconData fog = LucideIcons.cloudFog;
  static const IconData snow = LucideIcons.snowflake;
  static const IconData cloud = LucideIcons.cloud;

  // ===== TIME =====
  static const IconData darkMode = LucideIcons.moon;
  static const IconData lightMode = LucideIcons.sun;
  static const IconData clock = LucideIcons.clock;
  static const IconData timer = LucideIcons.timer;
  static const IconData hourglass = LucideIcons.hourglass;

  // ===== ACHIEVEMENTS =====
  static const IconData militaryTech = LucideIcons.award;
  static const IconData militaryTechOutlined = LucideIcons.award;
  static const IconData star = LucideIcons.star;
  static const IconData trophy = LucideIcons.trophy;
  static const IconData medal = LucideIcons.medal;

  // ===== FINANCE =====
  static const IconData euro = LucideIcons.euro;
  static const IconData money = LucideIcons.banknote;
  static const IconData accountBalance = LucideIcons.landmark;
  static const IconData income = LucideIcons.trendingUp;
  static const IconData expense = LucideIcons.trendingDown;

  // ===== MAP =====
  static const IconData map = LucideIcons.map;
  static const IconData location = LucideIcons.mapPin;
  static const IconData locationCity = LucideIcons.building2;
  static const IconData public = LucideIcons.globe;
  static const IconData myLocation = LucideIcons.locateFixed;
  static const IconData zoomIn = LucideIcons.zoomIn;
  static const IconData zoomOut = LucideIcons.zoomOut;
  static const IconData cropFree = LucideIcons.maximize;
  static const IconData tripOrigin = LucideIcons.circleDot;

  // ===== CLAN =====
  static const IconData shield = LucideIcons.shield;
  static const IconData shieldOutline = LucideIcons.shield;
  static const IconData chat = LucideIcons.messageCircle;
  static const IconData chatBubble = LucideIcons.messageCircle;
  static const IconData chatOutline = LucideIcons.messageCircle;
  static const IconData send = LucideIcons.send;
  static const IconData gavel = LucideIcons.gavel;
  static const IconData addBusiness = LucideIcons.building;

  // ===== STATUS =====
  static const IconData warning = LucideIcons.triangleAlert;
  static const IconData error = LucideIcons.circleX;
  static const IconData success = LucideIcons.circleCheck;
  static const IconData info = LucideIcons.info;
  static const IconData loading = LucideIcons.loader2;
  static const IconData locked = LucideIcons.lock;

  // ===== MISC =====
  static const IconData menu = LucideIcons.menu;
  static const IconData logout = LucideIcons.logOut;
  static const IconData inventory = LucideIcons.package;
  static const IconData schedule = LucideIcons.calendarClock;
  static const IconData bolt = LucideIcons.bolt;
  static const IconData garage = LucideIcons.warehouse;
  static const IconData verified = LucideIcons.badgeCheck;
  static const IconData apps = LucideIcons.layoutGrid;
  static const IconData flag = LucideIcons.flag;
  static const IconData heart = LucideIcons.heart;
  static const IconData crown = LucideIcons.crown;
  static const IconData rocket = LucideIcons.rocket;
  static const IconData diamond = LucideIcons.diamond;
  static const IconData anchor = LucideIcons.anchor;
  static const IconData eco = LucideIcons.leaf;
  static const IconData fire = LucideIcons.flame;
  static const IconData lightning = LucideIcons.zap;
  static const IconData publicIcon = LucideIcons.globe;
  static const IconData seat = LucideIcons.armchair;
  static const IconData bedtime = LucideIcons.moonStar;
  static const IconData emojiEvents = LucideIcons.trophy;
  static const IconData emojiEventsOutlined = LucideIcons.trophy;
  static const IconData description = LucideIcons.fileText;
  static const IconData descriptionOutlined = LucideIcons.fileText;
  static const IconData receiptLong = LucideIcons.receipt;
  static const IconData receiptLongOutlined = LucideIcons.receipt;
  static const IconData history = LucideIcons.history;
  static const IconData historyOutlined = LucideIcons.history;
  static const IconData lockOutline = LucideIcons.lock;
  static const IconData waterDrop = LucideIcons.droplets;
  static const IconData wbSunny = LucideIcons.sun;
  static const IconData acUnit = LucideIcons.snowflake;
  static const IconData airlineSeat = LucideIcons.armchair;
  static const IconData localShipping = LucideIcons.truck;
  static const IconData shoppingBasket = LucideIcons.shoppingCart;
  static const IconData addCircleOutline = LucideIcons.circlePlus;
  static const IconData assignmentOutlined = LucideIcons.clipboardList;
  static const IconData timerOff = LucideIcons.timerOff;
  static const IconData directionsCar = LucideIcons.car;
  static const IconData localFireDepartment = LucideIcons.flame;
  static const IconData inventory2 = LucideIcons.package;
}
