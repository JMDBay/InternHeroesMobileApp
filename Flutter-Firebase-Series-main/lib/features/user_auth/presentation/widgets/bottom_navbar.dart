import 'package:flutter/material.dart';

class BottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final void Function(int) onItemTapped;

  const BottomNavBar({
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      color: Colors.transparent, // Set color to transparent
      elevation: 0, // Remove elevation
      child: Container(
        height: kBottomNavigationBarHeight + MediaQuery.of(context).padding.bottom, // Adjusted height to remove bottom space
        decoration: BoxDecoration(
          color: Colors.white, // Set background color to white
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(10), // Add top left border radius
            topRight: Radius.circular(10), // Add top right border radius
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              spreadRadius: 1,
              blurRadius: 5,
              offset: Offset(0, 3), // changes position of shadow
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            InkWell(
              onTap: () => onItemTapped(0),
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Icon(Icons.book, color: selectedIndex == 0 ? Colors.yellow[800] : Colors.grey),
              ),
            ),
            InkWell(
              onTap: () => onItemTapped(1),
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Icon(Icons.message, color: selectedIndex == 1 ? Colors.yellow[800] : Colors.grey),
              ),
            ),
            InkWell(
              onTap: () => onItemTapped(2),
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Icon(Icons.add, color: selectedIndex == 2 ? Colors.yellow[800] : Colors.grey),
              ),
            ),
            InkWell(
              onTap: () => onItemTapped(3),
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Icon(Icons.calendar_today, color: selectedIndex == 3 ? Colors.yellow[800] : Colors.grey),
              ),
            ),
            InkWell(
              onTap: () => onItemTapped(4),
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Icon(Icons.account_circle, color: selectedIndex == 4 ? Colors.yellow[800] : Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
