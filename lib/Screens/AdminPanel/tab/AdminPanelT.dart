import 'package:flutter/material.dart';

class Adminpanel extends StatefulWidget {
  const Adminpanel({super.key});

  @override
  State<Adminpanel> createState() => _AdminpanelState();
}

class _AdminpanelState extends State<Adminpanel> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Delay Settings
  final Map<String, Map<String, int>> _delaySettings = {
    'strongCoffee': {'cpDelay': 0, 'cpOnTime': 0, 'milkDelay': 0, 'milkOnTime': 0, 'waterDelay': 0, 'waterOnTime': 0},
    'liteCoffee': {'cpDelay': 0, 'cpOnTime': 0, 'milkDelay': 0, 'milkOnTime': 0, 'waterDelay': 0, 'waterOnTime': 0},
    'blackCoffee': {'ctpDelay': 0, 'ctpOnTime': 0, 'waterDelay': 0, 'waterOnTime': 0},
    'strongTea': {'ttpDelay': 0, 'ttpOnTime': 0, 'milkDelay': 0, 'milkOnTime': 0, 'waterDelay': 0, 'waterOnTime': 0},
    'liteTea': {'ttpDelay': 0, 'ttpOnTime': 0, 'milkDelay': 0, 'milkOnTime': 0, 'waterDelay': 0, 'waterOnTime': 0},
    'blackTea': {'ttpDelay': 0, 'ttpOnTime': 0, 'waterDelay': 0, 'waterOnTime': 0},
    'dipTea': {'waterDelay': 0, 'waterOnTime': 0, 'milkDelay': 0, 'milkOnTime': 0},
    'hotMilk': {'milkDelay': 0, 'milkOnTime': 0, 'waterDelay': 0, 'waterOnTime': 0},
    'hotWater': {'waterValveDelay': 0, 'waterValveOnTime': 0},
  };

  // Brewing Settings
  double _coffeeTemp = 85.0;
  double _teaTemp = 90.0;

  // Cleaning Settings
  int _teaClean = 10;
  int _coffeeClean = 10;
  int _milkClean = 15;

  // Reverse Timing
  int _milkPump = 5;
  int _teaPump = 5;
  int _coffeePump = 5;


  final Map<String, int> _drinkCounts = {
    'Strong Coffee': 0,
    'Lite Coffee': 0,
    'Black Coffee': 0,
    'Strong Tea': 0,
    'Lite Tea': 0,
    'Black Tea': 0,
    'Dip Tea': 0,
    'Hot Milk': 0,
    'Hot Water': 0,
  };

  final Map<String, bool> _showCountControls = {
    'Strong Coffee': false,
    'Lite Coffee': false,
    'Black Coffee': false,
    'Strong Tea': false,
    'Lite Tea': false,
    'Black Tea': false,
    'Dip Tea': false,
    'Hot Milk': false,
    'Hot Water': false,
  };

  String _companyName = '';
  int _configDelay = 0;

  int _teaCleanDelay = 0;
  int _coffeeCleanDelay = 0;
  int _milkCleanDelay = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _saveSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Settings saved successfully!'),
        backgroundColor: Color(0xFF6B4423),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: const Color(0xFF6B4423),
        foregroundColor: Colors.white,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Admin Panel', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            Text('Machine Configuration', style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: Colors.white70)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              onPressed: _saveSettings,
              label: const Text('SAVE', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF6B4423),
                elevation: 4,
                shadowColor: Colors.black45,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          isScrollable: false,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          tabs: const [
            Tab(icon: Icon(Icons.timer, size: 20), text: 'Delays'),
            Tab(icon: Icon(Icons.thermostat, size: 20), text: 'Brewing'),
            Tab(icon: Icon(Icons.cleaning_services, size: 20), text: 'Cleaning'),
            Tab(icon: Icon(Icons.replay, size: 20), text: 'Reverse'),
            Tab(icon: Icon(Icons.format_list_numbered, size: 20), text: 'Counts'),
            Tab(icon: Icon(Icons.settings, size: 20), text: 'Config'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDelaySettings(),
          _buildBrewingSettings(),
          _buildCleaningSettings(),
          _buildReverseSettings(),
          _buildCountsSettings(),
          _buildConfigSettings(),
        ],
      ),
    );
  }

  // Delay Settings Tab
  Widget _buildDelaySettings() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildInfoCard('Configure timing delays and on-time duration for each beverage component.'),
          const SizedBox(height: 16),
          _buildDelayCard('Strong Coffee', 'strongCoffee', [
            {'key': 'cpDelay', 'label': 'Coffee Pump Delay', 'onTimeKey': 'cpOnTime'},
            {'key': 'milkDelay', 'label': 'Milk Pump Delay', 'onTimeKey': 'milkOnTime'},
            {'key': 'waterDelay', 'label': 'Hot Water Pump Delay', 'onTimeKey': 'waterOnTime'},
          ]),
          _buildDelayCard('Lite Coffee', 'liteCoffee', [
            {'key': 'cpDelay', 'label': 'Coffee Pump Delay', 'onTimeKey': 'cpOnTime'},
            {'key': 'milkDelay', 'label': 'Milk Pump Delay', 'onTimeKey': 'milkOnTime'},
            {'key': 'waterDelay', 'label': 'Hot Water Pump Delay', 'onTimeKey': 'waterOnTime'},
          ]),
          _buildDelayCard('Black Coffee', 'blackCoffee', [
            {'key': 'ctpDelay', 'label': 'Coffee Pump Delay', 'onTimeKey': 'ctpOnTime'},
            {'key': 'waterDelay', 'label': 'Hot Water Pump Delay', 'onTimeKey': 'waterOnTime'},
          ]),
          _buildDelayCard('Strong Tea', 'strongTea', [
            {'key': 'ttpDelay', 'label': 'Tea Pump Delay', 'onTimeKey': 'ttpOnTime'},
            {'key': 'milkDelay', 'label': 'Milk Pump Delay', 'onTimeKey': 'milkOnTime'},
            {'key': 'waterDelay', 'label': 'Hot Water Pump Delay', 'onTimeKey': 'waterOnTime'},
          ]),
          _buildDelayCard('Lite Tea', 'liteTea', [
            {'key': 'ttpDelay', 'label': 'Tea Pump Delay', 'onTimeKey': 'ttpOnTime'},
            {'key': 'milkDelay', 'label': 'Milk Pump Delay', 'onTimeKey': 'milkOnTime'},
            {'key': 'waterDelay', 'label': 'Hot Water Pump Delay', 'onTimeKey': 'waterOnTime'},
          ]),
          _buildDelayCard('Black Tea', 'blackTea', [
            {'key': 'ttpDelay', 'label': 'Tea Pump Delay', 'onTimeKey': 'ttpOnTime'},
            {'key': 'waterDelay', 'label': 'Hot Water Pump Delay', 'onTimeKey': 'waterOnTime'},
          ]),
          _buildDelayCard('Dip Tea', 'dipTea', [
            {'key': 'waterDelay', 'label': 'Hot Water Pump Delay', 'onTimeKey': 'waterOnTime'},
            {'key': 'milkDelay', 'label': 'Milk Pump Delay', 'onTimeKey': 'milkOnTime'},
          ]),
          _buildDelayCard('Hot Milk', 'hotMilk', [
            {'key': 'milkDelay', 'label': 'Milk Pump Delay', 'onTimeKey': 'milkOnTime'},
            {'key': 'waterDelay', 'label': 'Hot Water Pump Delay', 'onTimeKey': 'waterOnTime'},
          ]),
          _buildDelayCard('Hot Water', 'hotWater', [
            {'key': 'waterValveDelay', 'label': 'Hot Water Valve Delay', 'onTimeKey': 'waterValveOnTime'},
          ]),
        ],
      ),
    );
  }

  Widget _buildDelayCard(String title, String beverageKey, List<Map<String, String>> fields) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.local_cafe, color: const Color(0xFF6B4423), size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...fields.map((field) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildDelayRow(
                field['label']!,
                _delaySettings[beverageKey]![field['key']]!,
                _delaySettings[beverageKey]![field['onTimeKey']!]!,
                    (delayValue) {
                  setState(() {
                    _delaySettings[beverageKey]![field['key']!] = delayValue;
                  });
                },
                    (onTimeValue) {
                  setState(() {
                    _delaySettings[beverageKey]![field['onTimeKey']!] = onTimeValue;
                  });
                },
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildDelayRow(String label, int delayValue, int onTimeValue, Function(int) onDelayChanged, Function(int) onTimeChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            // Delay controls
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Delay', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => delayValue > 0 ? onDelayChanged(delayValue - 1) : null,
                        icon: const Icon(Icons.remove_circle_outline),
                        color: const Color(0xFF6B4423),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6B4423).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$delayValue sec',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF6B4423)),
                        ),
                      ),
                      IconButton(
                        onPressed: () => onDelayChanged(delayValue + 1),
                        icon: const Icon(Icons.add_circle_outline),
                        color: const Color(0xFF6B4423),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // On Time controls
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('On Time', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => onTimeValue > 0 ? onTimeChanged(onTimeValue - 1) : null,
                        icon: const Icon(Icons.remove_circle_outline),
                        color: const Color(0xFF6B4423),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6B4423).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$onTimeValue sec',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF6B4423)),
                        ),
                      ),
                      IconButton(
                        onPressed: () => onTimeChanged(onTimeValue + 1),
                        icon: const Icon(Icons.add_circle_outline),
                        color: const Color(0xFF6B4423),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Brewing Settings Tab
  Widget _buildBrewingSettings() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildInfoCard('Set optimal brewing temperatures for coffee and tea (20-99°C).'),
          const SizedBox(height: 16),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildTemperatureSlider(
                    'Coffee Brewing Temperature',
                    _coffeeTemp,
                    Icons.coffee,
                    Colors.brown,
                        (value) => setState(() => _coffeeTemp = value),
                  ),
                  const Divider(height: 40),
                  _buildTemperatureSlider(
                    'Tea Brewing Temperature',
                    _teaTemp,
                    Icons.emoji_food_beverage,
                    Colors.green,
                        (value) => setState(() => _teaTemp = value),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemperatureSlider(String label, double value, IconData icon, Color color, Function(double) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 12),
            Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: value,
                min: 20,
                max: 99,
                divisions: 79,
                activeColor: color,
                label: '${value.round()}°C',
                onChanged: onChanged,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Text(
                '${value.round()}°C',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Cleaning Settings Tab
  Widget _buildCleaningSettings() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildInfoCard('Configure automatic cleaning delay and duration for each component.'),
          const SizedBox(height: 16),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildCleaningItem('Tea Cleaning', _teaClean, _teaCleanDelay, Icons.emoji_food_beverage, Colors.green,
                          (value) => setState(() => _teaClean = value),
                          (delay) => setState(() => _teaCleanDelay = delay)),
                  const Divider(height: 32),
                  _buildCleaningItem('Coffee Cleaning', _coffeeClean, _coffeeCleanDelay, Icons.coffee, Colors.brown,
                          (value) => setState(() => _coffeeClean = value),
                          (delay) => setState(() => _coffeeCleanDelay = delay)),
                  const Divider(height: 32),
                  _buildCleaningItem('Milk Cleaning', _milkClean, _milkCleanDelay, Icons.water_drop, Colors.blue,
                          (value) => setState(() => _milkClean = value),
                          (delay) => setState(() => _milkCleanDelay = delay)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCleaningItem(String label, int value, int delayValue, IconData icon, Color color, Function(int) onChanged, Function(int) onDelayChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Delay', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => delayValue > 0 ? onDelayChanged(delayValue - 1) : null,
                        icon: const Icon(Icons.remove_circle_outline),
                        color: color,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('$delayValue sec', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
                      ),
                      IconButton(
                        onPressed: () => onDelayChanged(delayValue + 1),
                        icon: const Icon(Icons.add_circle_outline),
                        color: color,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Duration', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => value > 0 ? onChanged(value - 1) : null,
                        icon: const Icon(Icons.remove_circle_outline),
                        color: color,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('$value sec', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
                      ),
                      IconButton(
                        onPressed: () => onChanged(value + 1),
                        icon: const Icon(Icons.add_circle_outline),
                        color: color,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Reverse Timing Tab
  Widget _buildReverseSettings() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildInfoCard('Set delay timing to reverse pumps and return liquid to storage.'),
          const SizedBox(height: 16),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildReverseItem('Milk Pump Reverse', _milkPump, Icons.water_drop, Colors.blue,
                          (value) => setState(() => _milkPump = value)),
                  const Divider(height: 32),
                  _buildReverseItem('Tea Pump Reverse', _teaPump, Icons.emoji_food_beverage, Colors.green,
                          (value) => setState(() => _teaPump = value)),
                  const Divider(height: 32),
                  _buildReverseItem('Coffee Pump Reverse', _coffeePump, Icons.coffee, Colors.brown,
                          (value) => setState(() => _coffeePump = value)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountsSettings() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildInfoCard('Track beverage consumption counts. Long press to adjust, tap reset to clear.'),
          const SizedBox(height: 16),
          ..._drinkCounts.keys.map((drink) => _buildCountItem(drink)).toList(),
        ],
      ),
    );
  }

  Widget _buildCountItem(String drinkName) {
    IconData icon;
    Color color;

    if (drinkName.contains('Coffee')) {
      icon = Icons.coffee;
      color = Colors.brown;
    } else if (drinkName.contains('Tea')) {
      icon = Icons.emoji_food_beverage;
      color = Colors.green;
    } else if (drinkName.contains('Milk')) {
      icon = Icons.water_drop;
      color = Colors.blue;
    } else {
      icon = Icons.local_drink;
      color = Colors.cyan;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(drinkName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text('Total served', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
            ),
            if (_showCountControls[drinkName]!)
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      setState(() {
                        if (_drinkCounts[drinkName]! > 0) {
                          _drinkCounts[drinkName] = _drinkCounts[drinkName]! - 1;
                        }
                      });
                    },
                    icon: const Icon(Icons.remove_circle_outline),
                    color: color,
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            GestureDetector(
              onLongPress: () {
                Future.delayed(const Duration(seconds: 7), () {
                  setState(() {
                    _showCountControls[drinkName] = !_showCountControls[drinkName]!;
                  });
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_drinkCounts[drinkName]}',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
                ),
              ),
            ),
            if (_showCountControls[drinkName]!)
              Row(
                children: [
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _drinkCounts[drinkName] = _drinkCounts[drinkName]! + 1;
                      });
                    },
                    icon: const Icon(Icons.add_circle_outline),
                    color: color,
                  ),
                ],
              ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () {
                setState(() {
                  _drinkCounts[drinkName] = 0;
                  _showCountControls[drinkName] = false;
                });
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              child: const Text('RESET', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigSettings() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildInfoCard('Configure company information and general machine settings.'),
          const SizedBox(height: 16),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.business, color: const Color(0xFF6B4423), size: 24),
                      const SizedBox(width: 12),
                      const Text('Company Name', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Enter company name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFF6B4423), width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _companyName = value;
                      });
                    },
                  ),
                  const Divider(height: 40),
                  Row(
                    children: [
                      Icon(Icons.timer, color: const Color(0xFF6B4423), size: 24),
                      const SizedBox(width: 12),
                      const Text('ScreenSaver Timer', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => _configDelay > 0 ? setState(() => _configDelay--) : null,
                        icon: const Icon(Icons.remove_circle_outline),
                        color: const Color(0xFF6B4423),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6B4423).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$_configDelay sec',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF6B4423)),
                        ),
                      ),
                      IconButton(
                        onPressed: () => setState(() => _configDelay++),
                        icon: const Icon(Icons.add_circle_outline),
                        color: const Color(0xFF6B4423),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReverseItem(String label, int value, IconData icon, Color color, Function(int) onChanged) {
    return Row(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                children: [
                  IconButton(
                    onPressed: () => value > 0 ? onChanged(value - 1) : null,
                    icon: const Icon(Icons.remove_circle_outline),
                    color: color,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('$value sec', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
                  ),
                  IconButton(
                    onPressed: () => onChanged(value + 1),
                    icon: const Icon(Icons.add_circle_outline),
                    color: color,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Helper Widgets
  Widget _buildInfoCard(String text) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF6B4423).withOpacity(0.1),
        border: Border.all(color: const Color(0xFF6B4423).withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: const Color(0xFF6B4423)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Color(0xFF6B4423), fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberInput(String label, int value, Function(int) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.grey[700]),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        TextField(
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            suffixText: 'sec',
            suffixStyle: TextStyle(fontSize: 11, color: Colors.grey[600]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF6B4423), width: 2),
            ),
          ),
          controller: TextEditingController(text: value.toString()),
          onChanged: (val) => onChanged(int.tryParse(val) ?? 0),
        ),
      ],
    );
  }
}