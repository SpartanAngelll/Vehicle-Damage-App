import 'package:flutter/material.dart';
import '../widgets/responsive_layout.dart';
import '../utils/responsive_utils.dart';
import '../widgets/repair_professional_dashboard.dart';

class RepairmanDashboard extends StatefulWidget {
  const RepairmanDashboard({super.key});

  @override
  State<RepairmanDashboard> createState() => _RepairmanDashboardState();
}

class _RepairmanDashboardState extends State<RepairmanDashboard> {
  @override
  Widget build(BuildContext context) {
    return RepairProfessionalDashboard();
  }
}
