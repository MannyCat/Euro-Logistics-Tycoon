import 'package:flutter/material.dart';

void main() {
  runApp(const ShippingManagerApp());
}

class ShippingManagerApp extends StatelessWidget {
  const ShippingManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shipping Manager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF2196F3),
        brightness: Brightness.dark,
      ),
      home: const Scaffold(
        body: Center(
          child: Text('Shipping Manager — Starting Fresh'),
        ),
      ),
    );
  }
}
