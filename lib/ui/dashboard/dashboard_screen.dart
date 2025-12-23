import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../models/plant.dart';
import './plant_card.dart';
import 'add_plant_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final api = ApiService(auth.idToken!);

    return Scaffold(
      appBar: AppBar(title: const Text("My Digital Garden")),
      // ADD THIS BUTTON
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddPlantScreen())),
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<Plant>>(
        future: api.getPlants(auth.userId!),
        builder: (context, snapshot) {
  if (snapshot.connectionState == ConnectionState.waiting) {
    return const Center(child: CircularProgressIndicator());
  }
  
  // Handle API or Connection Errors
  if (snapshot.hasError) {
    return Center(child: Text("Sync Error: ${snapshot.error}"));
  }

  // Handle Empty State (New User)
  if (!snapshot.hasData || snapshot.data!.isEmpty) {
    return const Center(
      child: Text(
        "Your garden is empty!\nClick + to add your first plant.",
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 18, color: Colors.grey),
      ),
    );
  }

  return GridView.builder(
    padding: const EdgeInsets.all(16),
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2, 
      childAspectRatio: 0.8, // Adjust this to fit your PlantCard height
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
    ),
    itemCount: snapshot.data!.length,
    itemBuilder: (context, index) => PlantCard(plant: snapshot.data![index]),
  );
},
      ),
    );
  }
}