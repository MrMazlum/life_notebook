import 'package:flutter/material.dart';
import '../../models/book_models.dart';
import 'book_details_sheet.dart';
import 'update_progress_dialog.dart';

class BookHero extends StatelessWidget {
  final Book? book;
  final List<Book> upNextBooks;
  final bool isDark;
  final Function(int) onProgressLogged;

  const BookHero({
    super.key,
    required this.book,
    this.upNextBooks = const [],
    required this.isDark,
    required this.onProgressLogged,
  });

  @override
  Widget build(BuildContext context) {
    if (book == null) {
      return GestureDetector(
        onTap: () => _openDetails(context),
        child: _buildEmptyState(context),
      );
    }

    return GestureDetector(
      onTap: () => _openDetails(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
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
              color: Colors.blue.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // COVER IMAGE
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
                const SizedBox(width: 16),

                // DETAILS COLUMN
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // TITLE + BUTTON ROW
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontSize: 13,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          // Compact Log Button
                          SizedBox(
                            height: 30,
                            child: ElevatedButton(
                              onPressed: () => showDialog(
                                context: context,
                                builder: (_) => UpdateProgressDialog(
                                  book: book!,
                                  onUpdate: (c, t) =>
                                      onProgressLogged(c - book!.currentPage),
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white.withValues(
                                  alpha: 0.25,
                                ),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                "Log",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // PROGRESS BAR & PERCENTAGE
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: book!.progress,
                              backgroundColor: Colors.black12,
                              color: Colors.white,
                              minHeight: 6,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "${(book!.progress * 100).toInt()}% Complete",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // --- UP NEXT SECTION ---
            if (upNextBooks.isNotEmpty) ...[
              const SizedBox(height: 16),
              Divider(color: Colors.white.withValues(alpha: 0.15), height: 1),
              const SizedBox(height: 12),

              Row(
                children: [
                  Text(
                    "Up Next",
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward,
                    size: 14,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              SizedBox(
                height: 45,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: upNextBooks.length,
                  itemBuilder: (context, index) {
                    final b = upNextBooks[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: b.coverUrl.isNotEmpty
                            ? Image.network(
                                b.coverUrl,
                                width: 30,
                                height: 45,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                width: 30,
                                height: 45,
                                color: Colors.white24,
                              ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _openDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => BookDetailsSheet(
        book:
            book ??
            Book(
              id: 'dummy',
              title: '',
              author: '',
              coverUrl: '',
              totalPages: 0,
              currentPage: 0,
              status: '',
            ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.auto_stories_outlined,
            size: 40,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          Text(
            "Tap to view Library & Stats",
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}
