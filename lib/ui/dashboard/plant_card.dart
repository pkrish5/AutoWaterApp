import 'package:flutter/material.dart';
import '../../models/plant.dart';
import '../widgets/liquid_gauge.dart';

class PlantCard extends StatelessWidget {
  final Plant plant;

  const PlantCard({super.key, required this.plant});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Text(plant.nickname, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            // Use Stack to overlay the archetype image on the gauge
            Stack(
              alignment: Alignment.bottomCenter,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(50),
                  child: Container(
                    height: 100, width: 100,
                    color: Colors.blue.withOpacity(0.1),
                    child: LiquidGauge(level: plant.waterPercentage),
                  ),
                ),
                // Placeholder for your cartoony plant sprite
                Image.asset('assets/images/${plant.archetype.toLowerCase()}.png', height: 80),
              ],
            ),
            const SizedBox(height: 10),
            Text("Streak: ${plant.streak} days 🔥"),
          ],
        ),
      ),
    );
  }
}