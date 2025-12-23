import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../core/constants.dart';

class AddPlantScreen extends StatefulWidget {
  const AddPlantScreen({super.key});

  @override
  State<AddPlantScreen> createState() => _AddPlantScreenState();
}

class _AddPlantScreenState extends State<AddPlantScreen> {
  final _nameController = TextEditingController();
  String _selectedArchetype = 'Bushy';
  final List<String> _archetypes = ['Bushy', 'Vine', 'Spiky'];

  void _savePlant() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    
    // POST request to your verified AWS endpoint
    final response = await http.post(
      Uri.parse('${AppConstants.baseUrl}/plants'),
      headers: {
        'Authorization': auth.idToken!,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'nickname': _nameController.text,
        'archetype': _selectedArchetype,
        'userId': auth.userId,
      }),
    );

    if (response.statusCode == 200 && mounted) {
      Navigator.pop(context, true); // Return to dashboard and trigger refresh
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("New Digital Twin")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: "Plant Nickname", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: _selectedArchetype,
              items: _archetypes.map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
              onChanged: (val) => setState(() => _selectedArchetype = val!),
              decoration: const InputDecoration(labelText: "Growth Archetype", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _savePlant,
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
              child: const Text("Add to Garden"),
            ),
          ],
        ),
      ),
    );
  }
}