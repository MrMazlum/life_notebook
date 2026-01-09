import 'package:flutter/material.dart';
import '../../models/book_models.dart';
import 'book_details_sheet.dart';
import 'update_progress_dialog.dart';

class BookHero extends StatelessWidget {
  final Book? book;
  final bool isDark;
  final Function(int) onProgressLogged; // Changed name to match page logic

  const BookHero({
    super.key,
    required this.book,
    required this.isDark,
    required this.onProgressLogged,
  });

  @override
  Widget build(BuildContext context) {
    if (book == null) {
      return GestureDetector(
        onTap: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          builder: (_) => BookDetailsSheet(
            book: Book(
              id: 'dummy',
              title: '',
              author: '',
              coverUrl: '',
              totalPages: 0,
              currentPage: 0,
              status: '',
            ),
          ),
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.grey.withOpacity(0.1)),
          ),
          child: Column(
            children: [
              Icon(
                Icons.auto_stories_outlined,
                size: 40,
                color: Colors.grey.shade400,
              ),
              SizedBox(height: 12),
              Text(
                "Tap to view Library & Stats",
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => BookDetailsSheet(book: book!),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF1565C0), const Color(0xFF0D47A1)]
                : [const Color(0xFF42A5F5), const Color(0xFF1976D2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 70,
                  height: 105,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: book!.coverUrl.isNotEmpty
                        ? Image.network(book!.coverUrl, fit: BoxFit.cover)
                        : Container(
                            color: Colors.amber,
                            child: const Icon(Icons.book, color: Colors.white),
                          ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book!.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          height: 1.1,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "by ${book!.author}",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: book!.progress,
                          backgroundColor: Colors.black12,
                          color: Colors.white,
                          minHeight: 6,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "${(book!.progress * 100).toInt()}% Complete",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 40,
              child: ElevatedButton(
                onPressed: () => showDialog(
                  context: context,
                  builder: (_) => UpdateProgressDialog(
                    book: book!,
                    onUpdate: (p) {
                      // Calculate delta if possible, otherwise just update total
                      onProgressLogged(p - book!.currentPage);
                    },
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.2),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text("Log Pages"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
