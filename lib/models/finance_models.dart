import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FinanceBucket {
  final String id;
  final String name;
  final double limit;
  final double spent; // Calculated locally based on transactions
  final int iconCode;
  final int colorValue;
  final bool isFixed;

  FinanceBucket({
    required this.id,
    required this.name,
    required this.limit,
    this.spent = 0.0,
    required this.iconCode,
    required this.colorValue,
    this.isFixed = false,
  });

  IconData get icon => IconData(iconCode, fontFamily: 'MaterialIcons');
  Color get color => Color(colorValue);

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'limit': limit,
      'iconCode': iconCode,
      'colorValue': colorValue,
      'isFixed': isFixed,
      'userId': 'test_user', // Hardcoded for now
    };
  }

  factory FinanceBucket.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FinanceBucket(
      id: doc.id,
      name: data['name'] ?? 'Unknown',
      limit: (data['limit'] ?? 0.0).toDouble(),
      iconCode: data['iconCode'] ?? 57522, // Default icon
      colorValue: data['colorValue'] ?? 4280391411, // Default color (blueish)
      isFixed: data['isFixed'] ?? false,
    );
  }

  FinanceBucket copyWith({double? spent, double? limit}) {
    return FinanceBucket(
      id: id,
      name: name,
      limit: limit ?? this.limit,
      spent: spent ?? this.spent,
      iconCode: iconCode,
      colorValue: colorValue,
      isFixed: isFixed,
    );
  }
}

class FinanceTransaction {
  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final String categoryId;
  final bool isExpense;
  final int? iconCode;
  final int? colorValue;

  FinanceTransaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.categoryId,
    this.isExpense = true,
    this.iconCode,
    this.colorValue,
  });

  IconData? get icon => iconCode != null
      ? IconData(iconCode!, fontFamily: 'MaterialIcons')
      : null;
  Color? get color => colorValue != null ? Color(colorValue!) : null;

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'amount': amount,
      'date': Timestamp.fromDate(date),
      'categoryId': categoryId,
      'isExpense': isExpense,
      'iconCode': iconCode,
      'colorValue': colorValue,
      'userId': 'test_user',
    };
  }

  factory FinanceTransaction.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FinanceTransaction(
      id: doc.id,
      title: data['title'] ?? '',
      amount: (data['amount'] ?? 0.0).toDouble(),
      date: (data['date'] as Timestamp).toDate(),
      categoryId: data['categoryId'] ?? 'income',
      isExpense: data['isExpense'] ?? true,
      iconCode: data['iconCode'],
      colorValue: data['colorValue'],
    );
  }
}
