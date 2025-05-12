import 'package:flutter/material.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final void Function(int) onTabChange;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTabChange,
  });

static const _navItems = [
  (icon: Icons.home, label: 'Dashboard'),  // Changed from 'Home' to 'Dashboard'
  (icon: Icons.group, label: 'Social'),
  (icon: Icons.extension, label: 'Activities'),
  (icon: Icons.explore, label: 'Discovery'),  // Changed from 'Discover' to 'Discovery'
];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(
          _navItems.length,
          (index) => _buildNavItem(
            _navItems[index].icon,
            _navItems[index].label,
            index,
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = index == currentIndex;
    return GestureDetector(
      onTap: () => onTabChange(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.grey.shade800 : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? Colors.white : Colors.grey),
            if (isSelected)
              Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Text(label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    )),
              ),
          ],
        ),
      ),
    );
  }
}