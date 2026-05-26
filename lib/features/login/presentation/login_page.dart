import 'package:flutter/material.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Center(
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).shadowColor,
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Welcome To Maura Bastion System', 
                  style: Theme.of(context).textTheme.headlineMedium
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    // TODO:Handle login button press
                  },
                  child: Text('Login', style: Theme.of(context).textTheme.titleMedium),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
}