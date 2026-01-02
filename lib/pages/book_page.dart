import 'package:flutter/material.dart';

class BookPage extends StatelessWidget {
  const BookPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        '📚 Reading List will be listed here',
        style: TextStyle(fontSize: 24),
      ),
    );
  }
}