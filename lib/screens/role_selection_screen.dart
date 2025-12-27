import 'package:flutter/material.dart';
import 'package:ccet_alumini_app/screens/secondary/edit_profile_screen.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Role')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Are you a Student or Alumni?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                // Navigate as Student
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => const EditProfileScreen(
                      isOnboarding: true,
                    ), // Pass relevant params
                  ),
                );
              },
              child: const Text('Student'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Navigate as Alumni
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => const EditProfileScreen(
                      isOnboarding: true,
                    ), // Pass relevant params
                  ),
                );
              },
              child: const Text('Alumni'),
            ),
          ],
        ),
      ),
    );
  }
}
