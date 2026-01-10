import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/book_models.dart';

class BookSearchDelegate extends SearchDelegate {
  // DIRECT API CALL
  Future<List<Book>> _searchGoogleBooks(String query) async {
    if (query.trim().isEmpty) return [];

    final url = Uri.parse(
      'https://www.googleapis.com/books/v1/volumes?q=$query&maxResults=10&printType=books',
    );
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['items'] == null) return [];

      return (data['items'] as List).map((item) {
        final volume = item['volumeInfo'];
        String cover = '';
        if (volume['imageLinks'] != null) {
          cover = volume['imageLinks']['thumbnail'] ?? '';
          if (cover.startsWith('http://'))
            cover = cover.replaceFirst('http://', 'https://');
        }

        return Book(
          id: '',
          title: volume['title'] ?? 'Unknown',
          author: (volume['authors'] as List?)?.first ?? 'Unknown',
          coverUrl: cover,
          totalPages: volume['pageCount'] ?? 0,
          currentPage: 0,
          status: 'wishlist',
        );
      }).toList();
    }
    return [];
  }

  // DIRECT FIREBASE WRITE
  Future<void> _addBookToFirestore(BuildContext context, Book book) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final data = book.toMap();
    data['status'] = 'wishlist'; // Ensure it goes to Up Next
    data['lastRead'] = FieldValue.serverTimestamp();

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('books')
        .add(data);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Added "${book.title}" to Up Next')),
      );
    }
  }

  @override
  ThemeData appBarTheme(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Theme.of(context).copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: InputBorder.none,
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) => [
    IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
  ];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
    icon: const Icon(Icons.arrow_back),
    onPressed: () => close(context, null),
  );

  @override
  Widget buildResults(BuildContext context) => _buildSearchResults(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildSearchResults(context);

  Widget _buildSearchResults(BuildContext context) {
    if (query.trim().isEmpty) return const SizedBox();

    return FutureBuilder<List<Book>>(
      future: _searchGoogleBooks(query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final books = snapshot.data ?? [];
        if (books.isEmpty) {
          return const Center(child: Text("No books found"));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: books.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final book = books[index];
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: book.coverUrl.isNotEmpty
                    ? Image.network(book.coverUrl, width: 40, fit: BoxFit.cover)
                    : Container(width: 40, height: 60, color: Colors.grey),
              ),
              title: Text(
                book.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                book.author,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: IconButton(
                icon: const Icon(Icons.add_circle, color: Colors.blue),
                onPressed: () {
                  _addBookToFirestore(context, book);
                  close(context, null);
                },
              ),
            );
          },
        );
      },
    );
  }
}
