import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/book_models.dart';
import 'book_search_delegate.dart';

class BookDetailsSheet extends StatefulWidget {
  final Book book;
  const BookDetailsSheet({super.key, required this.book});

  @override
  State<BookDetailsSheet> createState() => _BookDetailsSheetState();
}

class _BookDetailsSheetState extends State<BookDetailsSheet>
    with SingleTickerProviderStateMixin {
  bool _isEditing = false;
  late AnimationController _wiggleController;

  @override
  void initState() {
    super.initState();
    _wiggleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _wiggleController.dispose();
    super.dispose();
  }

  void _toggleEditMode() {
    setState(() {
      _isEditing = !_isEditing;
      if (_isEditing)
        _wiggleController.repeat(reverse: true);
      else
        _wiggleController.reset();
    });
  }

  void _startReadingBook(BuildContext context, Book newBook) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final batch = FirebaseFirestore.instance.batch();
    final userBooksRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('books');
    final activeSnapshot = await userBooksRef
        .where('status', isEqualTo: 'reading')
        .get();
    for (var doc in activeSnapshot.docs) {
      if (doc.id != newBook.id)
        batch.update(doc.reference, {'status': 'wishlist'});
    }
    batch.update(userBooksRef.doc(newBook.id), {
      'status': 'reading',
      'lastRead': FieldValue.serverTimestamp(),
    });
    await batch.commit();
    if (context.mounted) Navigator.pop(context);
  }

  void _confirmDelete(Book book) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Delete Book?",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "You have read ${book.currentPage} pages.\nThis cannot be undone.",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text(
                        "Cancel",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _deleteBook(book.id);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text("Delete"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _deleteBook(String bookId) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('books')
        .doc(bookId)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
        actions: [
          if (_isEditing)
            TextButton(
              onPressed: _toggleEditMode,
              child: const Text(
                "Done",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.book.id != 'dummy') ...[
                Text(
                  "Currently Reading",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: widget.book.coverUrl.isNotEmpty
                            ? Image.network(
                                widget.book.coverUrl,
                                width: 50,
                                height: 75,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                width: 50,
                                height: 75,
                                color: Colors.grey,
                              ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.book.title,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                            Text(
                              widget.book.author,
                              style: const TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: widget.book.progress,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "${(widget.book.progress * 100).toInt()}% Complete",
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Up Next",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  if (!_isEditing)
                    IconButton(
                      icon: const Icon(
                        Icons.add_circle_outline,
                        color: Colors.blue,
                      ),
                      onPressed: () => showSearch(
                        context: context,
                        delegate: BookSearchDelegate(),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(FirebaseAuth.instance.currentUser?.uid)
                    .collection('books')
                    .where('status', isEqualTo: 'wishlist')
                    .snapshots(),
                builder: (context, snapshot) {
                  final uniqueTitles = <String>{};
                  final books = (snapshot.data?.docs ?? [])
                      .map(
                        (d) => Book.fromMap(
                          d.data() as Map<String, dynamic>,
                          d.id,
                        ),
                      )
                      .where((b) => uniqueTitles.add(b.title))
                      .toList();

                  if (books.isEmpty)
                    return Container(
                      padding: const EdgeInsets.all(24),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.withOpacity(0.1)),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Center(
                        child: Text(
                          "Your reading list is empty",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    );

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 0.65,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                    itemCount: books.length,
                    itemBuilder: (ctx, i) {
                      final b = books[i];
                      return GestureDetector(
                        onLongPress: () {
                          if (!_isEditing) _toggleEditMode();
                        },
                        onTap: () {
                          if (_isEditing)
                            _confirmDelete(b);
                          else
                            showModalBottomSheet(
                              context: context,
                              useSafeArea: true,
                              builder: (c) => SafeArea(
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 40),
                                  child: Wrap(
                                    children: [
                                      ListTile(
                                        leading: const Icon(
                                          Icons.play_circle_outline,
                                          color: Colors.blue,
                                        ),
                                        title: const Text("Start Reading"),
                                        onTap: () {
                                          Navigator.pop(c);
                                          _startReadingBook(context, b);
                                        },
                                      ),
                                      ListTile(
                                        leading: const Icon(
                                          Icons.delete_outline,
                                          color: Colors.red,
                                        ),
                                        title: const Text("Delete Book"),
                                        onTap: () {
                                          Navigator.pop(c);
                                          _confirmDelete(b);
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                        },
                        child: AnimatedBuilder(
                          animation: _wiggleController,
                          builder: (context, child) => Transform.rotate(
                            angle: _isEditing
                                ? 0.02 *
                                      (i.isEven ? 1 : -1) *
                                      (_wiggleController.value - 0.5)
                                : 0.0,
                            child: child,
                          ),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Column(
                                children: [
                                  Expanded(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.1,
                                            ),
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: b.coverUrl.isNotEmpty
                                            ? Image.network(
                                                b.coverUrl,
                                                fit: BoxFit.cover,
                                              )
                                            : Container(color: Colors.grey),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    b.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                              if (_isEditing)
                                Positioned(
                                  top: -8,
                                  left: -8,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.remove,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
