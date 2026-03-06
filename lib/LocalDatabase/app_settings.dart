import 'package:isar/isar.dart';

part 'app_settings.g.dart';

@collection
class AppSettings {
  Id id = 0; // Singleton - always use id 0

  // ═══════════════════════════════════════════
  //  DELAY SETTINGS (stored as JSON string)
  // ═══════════════════════════════════════════

  // Strong Coffee
  int strongCoffeeCpDelay = 0;
  int strongCoffeeCpOnTime = 0;
  int strongCoffeeMilkDelay = 0;
  int strongCoffeeMilkOnTime = 0;
  int strongCoffeeWaterDelay = 0;
  int strongCoffeeWaterOnTime = 0;

  // Lite Coffee
  int liteCoffeeCpDelay = 0;
  int liteCoffeeCpOnTime = 0;
  int liteCoffeeMilkDelay = 0;
  int liteCoffeeMilkOnTime = 0;
  int liteCoffeeWaterDelay = 0;
  int liteCoffeeWaterOnTime = 0;

  // Black Coffee
  int blackCoffeeCtpDelay = 0;
  int blackCoffeeCtpOnTime = 0;
  int blackCoffeeWaterDelay = 0;
  int blackCoffeeWaterOnTime = 0;

  // Strong Tea
  int strongTeaTtpDelay = 0;
  int strongTeaTtpOnTime = 0;
  int strongTeaMilkDelay = 0;
  int strongTeaMilkOnTime = 0;
  int strongTeaWaterDelay = 0;
  int strongTeaWaterOnTime = 0;

  // Lite Tea
  int liteTeaTtpDelay = 0;
  int liteTeaTtpOnTime = 0;
  int liteTeaMilkDelay = 0;
  int liteTeaMilkOnTime = 0;
  int liteTeaWaterDelay = 0;
  int liteTeaWaterOnTime = 0;

  // Black Tea
  int blackTeaTtpDelay = 0;
  int blackTeaTtpOnTime = 0;
  int blackTeaWaterDelay = 0;
  int blackTeaWaterOnTime = 0;

  // Dip Tea
  int dipTeaWaterDelay = 0;
  int dipTeaWaterOnTime = 0;
  int dipTeaMilkDelay = 0;
  int dipTeaMilkOnTime = 0;

  // Hot Milk
  int hotMilkMilkDelay = 0;
  int hotMilkMilkOnTime = 0;
  int hotMilkWaterDelay = 0;
  int hotMilkWaterOnTime = 0;

  // Hot Water
  int hotWaterWaterValveDelay = 0;
  int hotWaterWaterValveOnTime = 0;

  // ═══════════════════════════════════════════
  //  TEMPERATURES
  // ═══════════════════════════════════════════
  double coffeeTemp = 85.0;
  double teaTemp = 90.0;

  // ═══════════════════════════════════════════
  //  CLEANING SETTINGS
  // ═══════════════════════════════════════════
  int teaClean = 10;
  int coffeeClean = 10;
  int milkClean = 15;
  int teaCleanDelay = 0;
  int coffeeCleanDelay = 0;
  int milkCleanDelay = 0;

  // ═══════════════════════════════════════════
  //  PUMP SETTINGS
  // ═══════════════════════════════════════════
  int milkPump = 5;
  int teaPump = 5;
  int coffeePump = 5;

  // ═══════════════════════════════════════════
  //  PUMP SPEEDS
  // ═══════════════════════════════════════════
  double teaPumpSpeed = 120.0;
  double coffeePumpSpeed = 120.0;
  double milkPumpSpeed = 120.0;

  // ═══════════════════════════════════════════
  //  PUMP REVERSE / FORWARD
  // ═══════════════════════════════════════════
  double milkPumpDelay = 0.0;
  double milkPumpOnTime = 0.0;
  double milkPumpForwardTime = 0.0;

  double teaPumpDelay = 0.0;
  double teaPumpOnTime = 0.0;
  double teaPumpForwardTime = 0.0;

  double coffeePumpDelay = 0.0;
  double coffeePumpOnTime = 0.0;
  double coffeePumpForwardTime = 0.0;

  // ═══════════════════════════════════════════
  //  DRINK COUNTS (Actual)
  // ═══════════════════════════════════════════
  int strongCoffeeCount = 0;
  int liteCoffeeCount = 0;
  int blackCoffeeCount = 0;
  int strongTeaCount = 0;
  int liteTeaCount = 0;
  int blackTeaCount = 0;
  int dipTeaCount = 0;
  int hotMilkCount = 0;
  int hotWaterCount = 0;

  // ═══════════════════════════════════════════
  //  DRINK COUNTS (Limit)
  // ═══════════════════════════════════════════
  int strongCoffeeLimitCount = 0;
  int liteCoffeeLimitCount = 0;
  int blackCoffeeLimitCount = 0;
  int strongTeaLimitCount = 0;
  int liteTeaLimitCount = 0;
  int blackTeaLimitCount = 0;
  int dipTeaLimitCount = 0;
  int hotMilkLimitCount = 0;
  int hotWaterLimitCount = 0;

  // ═══════════════════════════════════════════
  //  DRINK COUNTS (Jump)
  // ═══════════════════════════════════════════
  int strongCoffeeJumpCount = 0;
  int liteCoffeeJumpCount = 0;
  int blackCoffeeJumpCount = 0;
  int strongTeaJumpCount = 0;
  int liteTeaJumpCount = 0;
  int blackTeaJumpCount = 0;
  int dipTeaJumpCount = 0;
  int hotMilkJumpCount = 0;
  int hotWaterJumpCount = 0;

  // ═══════════════════════════════════════════
  //  CONFIGURATION
  // ═══════════════════════════════════════════
  String companyName = '';
  String cleanAll = '';
  int configDelay = 0;

  // ═══════════════════════════════════════════
  //  BREWING STATE
  // ═══════════════════════════════════════════
  String currentBrewing = '';
  int remainingSeconds = 0;

  // ═══════════════════════════════════════════
  //  CLEANING STATE
  // ═══════════════════════════════════════════
  String cleanTea = '';
  String cleanCoffee = '';
  String cleanMilk = '';

  // ═══════════════════════════════════════════
  //  AUTHENTICATION
  // ═══════════════════════════════════════════
  String adminPassword = '987654';
  String staffPassword = '123456';

  // ═══════════════════════════════════════════
  //  USAGE TIMESTAMPS
  // ═══════════════════════════════════════════
  int lastMilkUsedTime = 0;
  int lastTeaUsedTime = 0;
  int lastCoffeeUsedTime = 0;
}
