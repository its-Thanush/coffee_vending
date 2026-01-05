import 'package:coffee_vending/Screens/adminLogin/tab/AdminScreenLoginT.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;

class VendingMachineScreen extends StatefulWidget {
  const VendingMachineScreen({Key? key}) : super(key: key);

  @override
  State<VendingMachineScreen> createState() => _VendingMachineScreenState();
}

class _VendingMachineScreenState extends State<VendingMachineScreen> {
  String? selectedItem;
  late Timer _timer;
  DateTime _currentTime = DateTime.now();
  bool isBrewAnimating = false;
  double brewProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _currentTime = DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    final days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    final months = ['January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'];

    return '${days[date.weekday % 7]}, ${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatTime(DateTime date) {
    int hour = date.hour;
    String period = hour >= 12 ? 'PM' : 'AM';
    hour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);

    String minute = date.minute.toString().padLeft(2, '0');
    String second = date.second.toString().padLeft(2, '0');

    return '$hour:$minute:$second $period';
  }

  void _startBrewing() {
    setState(() {
      isBrewAnimating = true;
      brewProgress = 0.0;
    });

    Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (brewProgress >= 1.0) {
        timer.cancel();
        setState(() {
          isBrewAnimating = false;
          brewProgress = 0.0;
        });
        _showBrewComplete();
      } else {
        setState(() {
          brewProgress += 0.01;
        });
      }
    });
  }

  void _showBrewComplete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 32),
            const SizedBox(width: 12),
            const Text('Brewing Complete!'),
          ],
        ),
        content: const Text('Your beverage is ready. Please collect it.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                selectedItem = null;
              });
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.brown.shade900,
              Colors.brown.shade700,
              Colors.brown.shade800,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                _buildHeader(),
                const SizedBox(height: 20),
                Expanded(
                  child: Column(
                    children: [
                      Expanded(flex: 1, child: _buildCoffeeSection()),
                      const SizedBox(height: 20),
                      Expanded(flex: 1, child: _buildTeaSection()),
                      const SizedBox(height: 20),
                      Expanded(flex: 1, child: _buildEssentialsSection()),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: selectedItem != null ? _buildBrewButton() : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }


  Widget _buildBrewButton() {
    const double size = 120; // 👈 reduced radius source

    return GestureDetector(
      onTap: isBrewAnimating ? null : _startBrewing,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.brown.withOpacity(0.6),
              blurRadius: 18,   // reduced
              spreadRadius: 5,  // reduced
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Background circle
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(
                  color: Colors.brown.shade800,
                  width: 4, // slightly thinner
                ),
              ),
            ),

            // Coffee filling animation
            ClipOval(
              child: Stack(
                children: [
                  Container(
                    width: size,
                    height: size,
                    color: Colors.transparent,
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 30),
                      height: size * brewProgress,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.brown.shade400,
                            Colors.brown.shade700,
                            Colors.brown.shade900,
                          ],
                        ),
                      ),
                      child: CustomPaint(
                        painter: WavePainter(brewProgress),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Button content
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.coffee_maker,
                  size: 40, // reduced
                  color:
                  isBrewAnimating ? Colors.white : Colors.brown.shade900,
                ),
                const SizedBox(height: 8),
                Text(
                  isBrewAnimating ? 'BREWING' : 'BREW',
                  style: TextStyle(
                    fontSize: 18, // reduced
                    fontWeight: FontWeight.bold,
                    color: isBrewAnimating
                        ? Colors.white
                        : Colors.brown.shade900,
                    letterSpacing: 2,
                  ),
                ),
                if (isBrewAnimating)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${(brewProgress * 100).toInt()}%',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Beverage Selection',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.brown.shade900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatDate(_currentTime),
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.brown.shade600,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              SizedBox(height: 10),
              Text(
                _formatTime(_currentTime),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.brown.shade900,
                ),
              ),
              IconButton(
                splashRadius: 1,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>  adminScreenLogin(),
                      ),
                    );
                  }, icon: Icon(Icons.admin_panel_settings,color: Colors.brown.shade900,))
            ],
          )
          
        ],
      ),
    );
  }

  Widget _buildCoffeeSection() {
    return _buildSection(
      title: 'Coffee',
      icon: Icons.coffee,
      iconColor: Colors.amber.shade700,
      items: [
        ItemData('Strong Coffee', 'c1', Colors.brown.shade900,
            imagePath: 'assets/images/strong-espresso-coffee.jpg'),
        ItemData('Lite Coffee', 'c2', Colors.brown.shade600,
            imagePath: 'assets/images/light-latte-coffee.jpg'),
        ItemData('Black Coffee', 'c3', Colors.grey.shade900,
            imagePath: 'assets/images/black-americano-coffee.jpg'),
        ItemData('Espresso', 'c4', Colors.brown.shade800,
            imagePath: 'assets/images/strong-espresso-coffee.jpg'),
      ],
    );
  }

  Widget _buildTeaSection() {
    return _buildSection(
      title: 'Tea',
      icon: Icons.local_cafe,
      iconColor: Colors.orange.shade700,
      items: [
        ItemData('Strong Tea', 't1', Colors.orange.shade900,
            imagePath: 'assets/images/strong-hot-tea.jpg'),
        ItemData('Lite Tea', 't2', Colors.orange.shade600,
            imagePath: 'assets/images/light-milk-tea.jpg'),
        ItemData('Black Tea', 't3', Colors.grey.shade800,
            imagePath: 'assets/images/black-tea-cup.jpg'),
      ],
    );
  }

  Widget _buildEssentialsSection() {
    return _buildSection(
      title: 'Essentials',
      icon: Icons.whatshot,
      iconColor: Colors.blue.shade400,
      items: [
        ItemData('Hot Milk', 'e1', Colors.grey.shade100,
            textColor: Colors.grey.shade800,
            imagePath: 'assets/images/glass-of-hot-milk.jpg'),
        ItemData('Hot Water', 'e2', Colors.blue.shade100,
            textColor: Colors.grey.shade800,
            imagePath: 'assets/images/steaming-hot-water-cup.jpg'),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<ItemData> items,
  }) {
    return Container(
      padding:  EdgeInsets.symmetric(horizontal: 10,vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 24),
               SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: items.map((item) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: _buildItemCard(item),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(ItemData item) {
    final isSelected = selectedItem == item.id;

    return GestureDetector(
      onTap: () {
        setState(() {
          if (selectedItem == item.id) {
            selectedItem = null;
          } else {
            selectedItem = item.id;
          }
        });
      },
      child: Container(
        height:110,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? Border.all(color: Colors.amber, width: 3)
              : Border.all(color: Colors.white.withOpacity(0.3), width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isSelected ? 0.5 : 0.3),
              blurRadius: isSelected ? 16 : 8,
              offset: Offset(0, isSelected ? 6 : 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                item.imagePath,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(color: item.color);
                },
              ),

              // Gradient Overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.3),
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const SizedBox(height: 5),
                    Text(
                      item.name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Selection Indicator
              if (isSelected)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.amber.withOpacity(0.5),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class ItemData {
  final String name;
  final String id;
  final Color color;
  final Color? textColor;
  final String imagePath;

  ItemData(this.name, this.id, this.color, {this.textColor, required this.imagePath});
}

class WavePainter extends CustomPainter {
  final double progress;

  WavePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.brown.shade800.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    final path = Path();
    final waveHeight = 8.0;
    final waveLength = size.width / 2;

    path.moveTo(0, 0);

    for (double i = 0; i <= size.width; i++) {
      path.lineTo(
        i,
        waveHeight * math.sin((i / waveLength * 2 * math.pi) + (progress * 10)),
      );
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(WavePainter oldDelegate) => true;
}