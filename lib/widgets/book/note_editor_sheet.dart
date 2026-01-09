import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/book_models.dart';

class NoteEditorSheet extends StatelessWidget {
  final MindNote? existingNote;

  const NoteEditorSheet({super.key, this.existingNote});

  @override
  Widget build(BuildContext context) {
    final tCtrl = TextEditingController(text: existingNote?.title);
    final bCtrl = TextEditingController(text: existingNote?.body);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        // Safe area for keyboard
        bottom: MediaQuery.of(context).viewInsets.bottom + 40,
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: tCtrl,
              textCapitalization: TextCapitalization.sentences,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              decoration: const InputDecoration(
                hintText: "Title",
                border: InputBorder.none,
              ),
            ),
            const Divider(),
            TextField(
              controller: bCtrl,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 5,
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
              decoration: const InputDecoration(
                hintText: "Start typing...",
                border: InputBorder.none,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (existingNote != null)
                  IconButton(
                    onPressed: () {
                      _deleteNote(existingNote!.id);
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                  ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    if (tCtrl.text.isNotEmpty) {
                      if (existingNote != null) {
                        _updateNote(existingNote!, tCtrl.text, bCtrl.text);
                      } else {
                        _addNote(tCtrl.text, bCtrl.text);
                      }
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("Save"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _addNote(String title, String body) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final newNote = MindNote(
      id: '',
      title: title,
      body: body,
      tag: "General",
      createdAt: DateTime.now(),
    );
    FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('mind_notes')
        .add(newNote.toMap());
  }

  void _updateNote(MindNote note, String t, String b) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('mind_notes')
        .doc(note.id)
        .update({'title': t, 'body': b});
  }

  void _deleteNote(String id) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('mind_notes')
        .doc(id)
        .delete();
  }
}
