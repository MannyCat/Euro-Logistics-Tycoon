import 'package:flutter/material.dart';

/// Centralized icon mapping using Material Icons.
/// All screens reference icons from here for consistency.
class AppIcons {
  AppIcons._();

  // ===== NAVIGATION =====
  static const IconData contracts = Icons.description_outlined;
  static const IconData contractsOutlined = Icons.description_outlined;
  static const IconData fleet = Icons.local_shipping_outlined;
  static const IconData fleetOutlined = Icons.local_shipping_outlined;
  static const IconData drivers = Icons.people_outline;
  static const IconData driversOutlined = Icons.people_outline;
  static const IconData warehouses = Icons.warehouse_outlined;
  static const IconData warehousesOutlined = Icons.warehouse_outlined;
  static const IconData finances = Icons.receipt_long_outlined;
  static const IconData financesOutlined = Icons.receipt_long_outlined;
  static const IconData eventLog = Icons.history;
  static const IconData eventLogOutlined = Icons.history;
  static const IconData market = Icons.storefront_outlined;
  static const IconData marketOutlined = Icons.storefront_outlined;
  static const IconData leaderboard = Icons.emoji_events_outlined;
  static const IconData leaderboardOutlined = Icons.emoji_events_outlined;
  static const IconData achievements = Icons.military_tech_outlined;
  static const IconData achievementsOutlined = Icons.military_tech_outlined;
  static const IconData clan = Icons.shield_outlined;
  static const IconData clanOutlined = Icons.shield_outlined;
  static const IconData analytics = Icons.bar_chart_outlined;
  static const IconData analyticsOutlined = Icons.bar_chart_outlined;
  static const IconData settings = Icons.settings_outlined;
  static const IconData settingsOutlined = Icons.settings_outlined;

  // ===== ACTIONS =====
  static const IconData add = Icons.add;
  static const IconData addCircle = Icons.add_circle_outline;
  static const IconData close = Icons.close;
  static const IconData refresh = Icons.refresh;
  static const IconData edit = Icons.edit_outlined;
  static const IconData delete = Icons.delete_outline;
  static const IconData search = Icons.search;
  static const IconData filter = Icons.filter_list;
  static const IconData sort = Icons.swap_vert;
  static const IconData more = Icons.more_vert;
  static const IconData check = Icons.check;
  static const IconData checkCircle = Icons.check_circle_outline;
  static const IconData checkCircleOutline = Icons.check_circle_outline;
  static const IconData arrowRight = Icons.arrow_forward;
  static const IconData arrowForward = Icons.arrow_forward;
  static const IconData arrowUp = Icons.arrow_upward;
  static const IconData arrowDown = Icons.arrow_downward;
  static const IconData arrowLeft = Icons.arrow_back;
  static const IconData back = Icons.arrow_back;
  static const IconData forward = Icons.arrow_forward;

  // ===== TRUCK / TRANSPORT =====
  static const IconData truck = Icons.local_shipping;
  static const IconData truckLoading = Icons.local_shipping;
  static const IconData fuel = Icons.local_gas_station;
  static const IconData gasStation = Icons.local_gas_station;
  static const IconData wrench = Icons.build_outlined;
  static const IconData upgrade = Icons.arrow_upward;
  static const IconData sell = Icons.sell_outlined;
  static const IconData buy = Icons.shopping_cart_outlined;

  // ===== DRIVER =====
  static const IconData person = Icons.person_outline;
  static const IconData personAdd = Icons.person_add_outlined;
  static const IconData personRemove = Icons.person_remove_outlined;
  static const IconData personPin = Icons.person_pin_circle_outlined;
  static const IconData personOutline = Icons.person_outline;
  static const IconData people = Icons.people_outline;
  static const IconData groups = Icons.groups;
  static const IconData users = Icons.people_outline;

  // ===== WEATHER =====
  static const IconData sun = Icons.wb_sunny;
  static const IconData rain = Icons.water_drop;
  static const IconData fog = Icons.foggy;
  static const IconData snow = Icons.ac_unit;
  static const IconData cloud = Icons.cloud;
  static const IconData weatherIcon = Icons.cloud_outlined;

  // ===== TIME =====
  static const IconData darkMode = Icons.dark_mode_outlined;
  static const IconData lightMode = Icons.light_mode_outlined;
  static const IconData clock = Icons.schedule;
  static const IconData timer = Icons.timer_outlined;
  static const IconData hourglass = Icons.hourglass_empty;

  // ===== ACHIEVEMENTS =====
  static const IconData militaryTech = Icons.military_tech;
  static const IconData militaryTechOutlined = Icons.military_tech_outlined;
  static const IconData star = Icons.star_outlined;
  static const IconData trophy = Icons.emoji_events;
  static const IconData medal = Icons.military_tech;

  // ===== FINANCE =====
  static const IconData euro = Icons.euro_outlined;
  static const IconData money = Icons.payments_outlined;
  static const IconData accountBalance = Icons.account_balance_outlined;
  static const IconData income = Icons.trending_up;
  static const IconData expense = Icons.trending_down;

  // ===== MAP =====
  static const IconData map = Icons.map_outlined;
  static const IconData location = Icons.location_on_outlined;
  static const IconData locationCity = Icons.location_city_outlined;
  static const IconData public = Icons.public;
  static const IconData myLocation = Icons.my_location;
  static const IconData zoomIn = Icons.zoom_in;
  static const IconData zoomOut = Icons.zoom_out;
  static const IconData cropFree = Icons.crop_free;
  static const IconData tripOrigin = Icons.trip_origin;

  // ===== CLAN =====
  static const IconData shield = Icons.shield_outlined;
  static const IconData shieldOutline = Icons.shield_outlined;
  static const IconData chat = Icons.chat_outlined;
  static const IconData chatBubble = Icons.chat_bubble_outline;
  static const IconData chatOutline = Icons.chat_outlined;
  static const IconData send = Icons.send_outlined;
  static const IconData gavel = Icons.gavel_outlined;
  static const IconData addBusiness = Icons.add_business_outlined;

  // ===== STATUS =====
  static const IconData warning = Icons.warning_amber_outlined;
  static const IconData error = Icons.error_outline;
  static const IconData success = Icons.check_circle_outline;
  static const IconData info = Icons.info_outline;
  static const IconData loading = Icons.hourglass_top;
  static const IconData locked = Icons.lock_outline;

  // ===== MISC =====
  static const IconData menu = Icons.menu;
  static const IconData logout = Icons.logout_outlined;
  static const IconData inventory = Icons.inventory_2_outlined;
  static const IconData scheduleIcon = Icons.schedule;
  static const IconData bolt = Icons.bolt;
  static const IconData garage = Icons.garage_outlined;
  static const IconData verified = Icons.verified;
  static const IconData apps = Icons.apps_outlined;
  static const IconData flag = Icons.flag_outlined;
  static const IconData heart = Icons.favorite_outline;
  static const IconData crown = Icons.star;
  static const IconData rocket = Icons.rocket_launch_outlined;
  static const IconData diamond = Icons.diamond_outlined;
  static const IconData anchor = Icons.anchor;
  static const IconData eco = Icons.eco_outlined;
  static const IconData fire = Icons.local_fire_department_outlined;
  static const IconData lightning = Icons.bolt;
  static const IconData publicIcon = Icons.public;
  static const IconData seat = Icons.airline_seat_recline_extra_outlined;
  static const IconData bedtime = Icons.bedtime_outlined;
  static const IconData emojiEvents = Icons.emoji_events;
  static const IconData emojiEventsOutlined = Icons.emoji_events_outlined;
  static const IconData description = Icons.description_outlined;
  static const IconData descriptionOutlined = Icons.description_outlined;
  static const IconData receiptLong = Icons.receipt_long_outlined;
  static const IconData receiptLongOutlined = Icons.receipt_long_outlined;
  static const IconData history = Icons.history;
  static const IconData historyOutlined = Icons.history;
  static const IconData lockOutline = Icons.lock_outline;
  static const IconData waterDrop = Icons.water_drop;
  static const IconData wbSunny = Icons.wb_sunny;
  static const IconData acUnit = Icons.ac_unit;
  static const IconData airlineSeat = Icons.airline_seat_recline_extra_outlined;
  static const IconData localShipping = Icons.local_shipping_outlined;
  static const IconData shoppingBasket = Icons.shopping_basket_outlined;
  static const IconData addCircleOutline = Icons.add_circle_outline;
  static const IconData assignmentOutlined = Icons.assignment_outlined;
  static const IconData timerOff = Icons.timer_off_outlined;
  static const IconData directionsCar = Icons.directions_car_outlined;
  static const IconData localFireDepartment = Icons.local_fire_department_outlined;
  static const IconData inventory2 = Icons.inventory_2_outlined;
  static const IconData addCircleFill = Icons.add_circle;
  static const IconData scrollText = Icons.scrollText;
  static const IconData store = Icons.store;
  static const IconData barChart3 = Icons.bar_chart;
  static const IconData cloudFog = Icons.foggy;
  static const IconData arrowUpDown = Icons.swap_vert;
  static const IconData moreVertical = Icons.more_vert;
  static const IconData user = Icons.person;
  static const IconData userPlus = Icons.person_add;
  static const IconData userMinus = Icons.person_remove;
  static const IconData mapPin = Icons.location_on;
  static const IconData locateFixed = Icons.my_location;
  static const IconData maximize = Icons.maximize;
  static const IconData circleDot = Icons.circle;
  static const IconData messageCircle = Icons.chat_bubble_outline;
  static const IconData building = Icons.business;
  static const IconData building2 = Icons.business;
  static const IconData landmap = Icons.map;
}
