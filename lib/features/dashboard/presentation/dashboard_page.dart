import 'package:flutter/material.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,  // Or any other color you want for the page background
      child: Center(
        child: Text('Dashboard Page'),
      ),
    );
  }
}