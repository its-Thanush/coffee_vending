import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'app_settings.dart';

/// Singleton service that wraps all Isar database operations.
/// Provides a centralized place to read/write all app settings.
///
/// Usage:
///   await DatabaseHelper.instance.init();  // Call once in main()
///   final settings = await DatabaseHelper.instance.getSettings();
///   settings.coffeeTemp = 90.0;
///   await DatabaseHelper.instance.saveSettings(settings);
class DatabaseHelper {
  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  late Isar _isar;
  bool _isInitialized = false;

  /// Initialize the Isar database. Must be called once before any operations.
  Future<void> init() async {
    if (_isInitialized) return;

    final dir = await getApplicationDocumentsDirectory();
    _isar = await Isar.open(
      [AppSettingsSchema],
      directory: dir.path,
      name: 'coffee_vending_db',
    );
    _isInitialized = true;

    // Ensure a default settings row exists
    final existing = await _isar.appSettings.get(0);
    if (existing == null) {
      await _isar.writeTxn(() async {
        await _isar.appSettings.put(AppSettings());
      });
    }
  }

  /// Get the current settings (always id = 0)
  Future<AppSettings> getSettings() async {
    return (await _isar.appSettings.get(0)) ?? AppSettings();
  }

  /// Save settings back to the database
  Future<void> saveSettings(AppSettings settings) async {
    settings.id = 0; // Ensure singleton
    await _isar.writeTxn(() async {
      await _isar.appSettings.put(settings);
    });
  }

  /// Update a single field without loading full settings first.
  /// Pass a callback that modifies the settings object.
  Future<void> updateSettings(
    void Function(AppSettings settings) updater,
  ) async {
    final settings = await getSettings();
    updater(settings);
    await saveSettings(settings);
  }

  /// Clear all data and reset to defaults
  Future<void> resetAll() async {
    await _isar.writeTxn(() async {
      await _isar.appSettings.clear();
      await _isar.appSettings.put(AppSettings());
    });
  }

  // ═══════════════════════════════════════════════════════════
  //  CONVENIENCE GETTERS - Delay Settings as Map
  // ═══════════════════════════════════════════════════════════

  /// Get delay settings for a specific beverage key as a Map
  /// matching the existing _delaySettings map format
  Map<String, int> getDelayMap(AppSettings s, String beverageKey) {
    switch (beverageKey) {
      case 'strongCoffee':
        return {
          'cpDelay': s.strongCoffeeCpDelay,
          'cpOnTime': s.strongCoffeeCpOnTime,
          'milkDelay': s.strongCoffeeMilkDelay,
          'milkOnTime': s.strongCoffeeMilkOnTime,
          'waterDelay': s.strongCoffeeWaterDelay,
          'waterOnTime': s.strongCoffeeWaterOnTime,
        };
      case 'liteCoffee':
        return {
          'cpDelay': s.liteCoffeeCpDelay,
          'cpOnTime': s.liteCoffeeCpOnTime,
          'milkDelay': s.liteCoffeeMilkDelay,
          'milkOnTime': s.liteCoffeeMilkOnTime,
          'waterDelay': s.liteCoffeeWaterDelay,
          'waterOnTime': s.liteCoffeeWaterOnTime,
        };
      case 'blackCoffee':
        return {
          'ctpDelay': s.blackCoffeeCtpDelay,
          'ctpOnTime': s.blackCoffeeCtpOnTime,
          'waterDelay': s.blackCoffeeWaterDelay,
          'waterOnTime': s.blackCoffeeWaterOnTime,
        };
      case 'strongTea':
        return {
          'ttpDelay': s.strongTeaTtpDelay,
          'ttpOnTime': s.strongTeaTtpOnTime,
          'milkDelay': s.strongTeaMilkDelay,
          'milkOnTime': s.strongTeaMilkOnTime,
          'waterDelay': s.strongTeaWaterDelay,
          'waterOnTime': s.strongTeaWaterOnTime,
        };
      case 'liteTea':
        return {
          'ttpDelay': s.liteTeaTtpDelay,
          'ttpOnTime': s.liteTeaTtpOnTime,
          'milkDelay': s.liteTeaMilkDelay,
          'milkOnTime': s.liteTeaMilkOnTime,
          'waterDelay': s.liteTeaWaterDelay,
          'waterOnTime': s.liteTeaWaterOnTime,
        };
      case 'blackTea':
        return {
          'ttpDelay': s.blackTeaTtpDelay,
          'ttpOnTime': s.blackTeaTtpOnTime,
          'waterDelay': s.blackTeaWaterDelay,
          'waterOnTime': s.blackTeaWaterOnTime,
        };
      case 'dipTea':
        return {
          'waterDelay': s.dipTeaWaterDelay,
          'waterOnTime': s.dipTeaWaterOnTime,
          'milkDelay': s.dipTeaMilkDelay,
          'milkOnTime': s.dipTeaMilkOnTime,
        };
      case 'hotMilk':
        return {
          'milkDelay': s.hotMilkMilkDelay,
          'milkOnTime': s.hotMilkMilkOnTime,
          'waterDelay': s.hotMilkWaterDelay,
          'waterOnTime': s.hotMilkWaterOnTime,
        };
      case 'hotWater':
        return {
          'waterValveDelay': s.hotWaterWaterValveDelay,
          'waterValveOnTime': s.hotWaterWaterValveOnTime,
        };
      default:
        return {};
    }
  }

  /// Set delay settings from a Map back into the AppSettings object
  void setDelayMap(AppSettings s, String beverageKey, Map<String, int> delays) {
    switch (beverageKey) {
      case 'strongCoffee':
        s.strongCoffeeCpDelay = delays['cpDelay'] ?? 0;
        s.strongCoffeeCpOnTime = delays['cpOnTime'] ?? 0;
        s.strongCoffeeMilkDelay = delays['milkDelay'] ?? 0;
        s.strongCoffeeMilkOnTime = delays['milkOnTime'] ?? 0;
        s.strongCoffeeWaterDelay = delays['waterDelay'] ?? 0;
        s.strongCoffeeWaterOnTime = delays['waterOnTime'] ?? 0;
        break;
      case 'liteCoffee':
        s.liteCoffeeCpDelay = delays['cpDelay'] ?? 0;
        s.liteCoffeeCpOnTime = delays['cpOnTime'] ?? 0;
        s.liteCoffeeMilkDelay = delays['milkDelay'] ?? 0;
        s.liteCoffeeMilkOnTime = delays['milkOnTime'] ?? 0;
        s.liteCoffeeWaterDelay = delays['waterDelay'] ?? 0;
        s.liteCoffeeWaterOnTime = delays['waterOnTime'] ?? 0;
        break;
      case 'blackCoffee':
        s.blackCoffeeCtpDelay = delays['ctpDelay'] ?? 0;
        s.blackCoffeeCtpOnTime = delays['ctpOnTime'] ?? 0;
        s.blackCoffeeWaterDelay = delays['waterDelay'] ?? 0;
        s.blackCoffeeWaterOnTime = delays['waterOnTime'] ?? 0;
        break;
      case 'strongTea':
        s.strongTeaTtpDelay = delays['ttpDelay'] ?? 0;
        s.strongTeaTtpOnTime = delays['ttpOnTime'] ?? 0;
        s.strongTeaMilkDelay = delays['milkDelay'] ?? 0;
        s.strongTeaMilkOnTime = delays['milkOnTime'] ?? 0;
        s.strongTeaWaterDelay = delays['waterDelay'] ?? 0;
        s.strongTeaWaterOnTime = delays['waterOnTime'] ?? 0;
        break;
      case 'liteTea':
        s.liteTeaTtpDelay = delays['ttpDelay'] ?? 0;
        s.liteTeaTtpOnTime = delays['ttpOnTime'] ?? 0;
        s.liteTeaMilkDelay = delays['milkDelay'] ?? 0;
        s.liteTeaMilkOnTime = delays['milkOnTime'] ?? 0;
        s.liteTeaWaterDelay = delays['waterDelay'] ?? 0;
        s.liteTeaWaterOnTime = delays['waterOnTime'] ?? 0;
        break;
      case 'blackTea':
        s.blackTeaTtpDelay = delays['ttpDelay'] ?? 0;
        s.blackTeaTtpOnTime = delays['ttpOnTime'] ?? 0;
        s.blackTeaWaterDelay = delays['waterDelay'] ?? 0;
        s.blackTeaWaterOnTime = delays['waterOnTime'] ?? 0;
        break;
      case 'dipTea':
        s.dipTeaWaterDelay = delays['waterDelay'] ?? 0;
        s.dipTeaWaterOnTime = delays['waterOnTime'] ?? 0;
        s.dipTeaMilkDelay = delays['milkDelay'] ?? 0;
        s.dipTeaMilkOnTime = delays['milkOnTime'] ?? 0;
        break;
      case 'hotMilk':
        s.hotMilkMilkDelay = delays['milkDelay'] ?? 0;
        s.hotMilkMilkOnTime = delays['milkOnTime'] ?? 0;
        s.hotMilkWaterDelay = delays['waterDelay'] ?? 0;
        s.hotMilkWaterOnTime = delays['waterOnTime'] ?? 0;
        break;
      case 'hotWater':
        s.hotWaterWaterValveDelay = delays['waterValveDelay'] ?? 0;
        s.hotWaterWaterValveOnTime = delays['waterValveOnTime'] ?? 0;
        break;
    }
  }

  // ═══════════════════════════════════════════════════════════
  //  CONVENIENCE - Drink Counts as Map
  // ═══════════════════════════════════════════════════════════

  /// Get drink counts as a Map matching the existing _drinkCounts format
  Map<String, int> getDrinkCounts(AppSettings s) {
    return {
      'Strong Coffee': s.strongCoffeeCount,
      'Lite Coffee': s.liteCoffeeCount,
      'Black Coffee': s.blackCoffeeCount,
      'Strong Tea': s.strongTeaCount,
      'Lite Tea': s.liteTeaCount,
      'Black Tea': s.blackTeaCount,
      'Dip Tea': s.dipTeaCount,
      'Hot Milk': s.hotMilkCount,
      'Hot Water': s.hotWaterCount,
    };
  }

  /// Set drink counts from Map back into AppSettings
  void setDrinkCounts(AppSettings s, Map<String, int> counts) {
    s.strongCoffeeCount = counts['Strong Coffee'] ?? 0;
    s.liteCoffeeCount = counts['Lite Coffee'] ?? 0;
    s.blackCoffeeCount = counts['Black Coffee'] ?? 0;
    s.strongTeaCount = counts['Strong Tea'] ?? 0;
    s.liteTeaCount = counts['Lite Tea'] ?? 0;
    s.blackTeaCount = counts['Black Tea'] ?? 0;
    s.dipTeaCount = counts['Dip Tea'] ?? 0;
    s.hotMilkCount = counts['Hot Milk'] ?? 0;
    s.hotWaterCount = counts['Hot Water'] ?? 0;
  }

  /// Get limit counts as a Map
  Map<String, int> getLimitCounts(AppSettings s) {
    return {
      'Strong Coffee': s.strongCoffeeLimitCount,
      'Lite Coffee': s.liteCoffeeLimitCount,
      'Black Coffee': s.blackCoffeeLimitCount,
      'Strong Tea': s.strongTeaLimitCount,
      'Lite Tea': s.liteTeaLimitCount,
      'Black Tea': s.blackTeaLimitCount,
      'Dip Tea': s.dipTeaLimitCount,
      'Hot Milk': s.hotMilkLimitCount,
      'Hot Water': s.hotWaterLimitCount,
    };
  }

  /// Set limit counts from Map back into AppSettings
  void setLimitCounts(AppSettings s, Map<String, int> counts) {
    s.strongCoffeeLimitCount = counts['Strong Coffee'] ?? 0;
    s.liteCoffeeLimitCount = counts['Lite Coffee'] ?? 0;
    s.blackCoffeeLimitCount = counts['Black Coffee'] ?? 0;
    s.strongTeaLimitCount = counts['Strong Tea'] ?? 0;
    s.liteTeaLimitCount = counts['Lite Tea'] ?? 0;
    s.blackTeaLimitCount = counts['Black Tea'] ?? 0;
    s.dipTeaLimitCount = counts['Dip Tea'] ?? 0;
    s.hotMilkLimitCount = counts['Hot Milk'] ?? 0;
    s.hotWaterLimitCount = counts['Hot Water'] ?? 0;
  }

  /// Get jump counts as a Map
  Map<String, int> getJumpCounts(AppSettings s) {
    return {
      'Strong Coffee': s.strongCoffeeJumpCount,
      'Lite Coffee': s.liteCoffeeJumpCount,
      'Black Coffee': s.blackCoffeeJumpCount,
      'Strong Tea': s.strongTeaJumpCount,
      'Lite Tea': s.liteTeaJumpCount,
      'Black Tea': s.blackTeaJumpCount,
      'Dip Tea': s.dipTeaJumpCount,
      'Hot Milk': s.hotMilkJumpCount,
      'Hot Water': s.hotWaterJumpCount,
    };
  }

  /// Set jump counts from Map back into AppSettings
  void setJumpCounts(AppSettings s, Map<String, int> counts) {
    s.strongCoffeeJumpCount = counts['Strong Coffee'] ?? 0;
    s.liteCoffeeJumpCount = counts['Lite Coffee'] ?? 0;
    s.blackCoffeeJumpCount = counts['Black Coffee'] ?? 0;
    s.strongTeaJumpCount = counts['Strong Tea'] ?? 0;
    s.liteTeaJumpCount = counts['Lite Tea'] ?? 0;
    s.blackTeaJumpCount = counts['Black Tea'] ?? 0;
    s.dipTeaJumpCount = counts['Dip Tea'] ?? 0;
    s.hotMilkJumpCount = counts['Hot Milk'] ?? 0;
    s.hotWaterJumpCount = counts['Hot Water'] ?? 0;
  }
}
