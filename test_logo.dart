import 'package:flutter/material.dart';

void main() {
  runApp(TestApp());
}

class TestApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Testing Logo Display', style: TextStyle(color: Colors.white)),
              SizedBox(height: 20),
              Image.asset(
                'assets/logo.png',
                width: 200,
                height: 200,
                errorBuilder: (context, error, stackTrace) {
                  return Column(
                    children: [
                      Icon(Icons.error, color: Colors.red, size: 50),
                      Text('Error loading logo: $error', style: TextStyle(color: Colors.white)),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
