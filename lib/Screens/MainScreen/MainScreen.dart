import 'package:coffee_vending/allImports.dart';
import 'package:coffee_vending/helper/helper.dart';

class Mainscreen extends StatefulWidget {
  const Mainscreen({super.key});

  @override
  State<Mainscreen> createState() => _MainscreenState();
}

class _MainscreenState extends State<Mainscreen> {
  @override
  Widget build(BuildContext context) {
    return Responsive(
        mobile: SizedBox(),
        tablet: VendingMachineScreen(),
        desktop: SizedBox(),
    );
  }
}
