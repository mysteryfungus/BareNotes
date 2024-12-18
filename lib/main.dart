import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';


void main() {
  runApp(NoteApp());
}

class NoteApp extends StatefulWidget {
  @override
  _NoteAppState createState() => _NoteAppState();
}

final List<ThemeData> appThemes = [
  ThemeData.light(),
  ThemeData.dark(),
  ThemeData(
    brightness: Brightness.light,
    primaryColor: Colors.blue,
    colorScheme: ColorScheme.light(
      primary: Colors.blue,
      secondary: Colors.lightBlueAccent,
    ),
  ),
  ThemeData(
    brightness: Brightness.light,
    primaryColor: Colors.green,
    colorScheme: ColorScheme.light(
      primary: Colors.green,
      secondary: Colors.lightGreen,
    ),
  ),
  ThemeData(
    brightness: Brightness.dark,
    primaryColor: Colors.green,
    colorScheme: ColorScheme.dark(
      primary: Colors.green,
      secondary: Colors.lightGreen
    )
  )
];

class _NoteAppState extends State<NoteApp> {
  int selectedThemeIndex = 0;
  final List<Note> notes = [];

  @override
  void initState() {
    super.initState();
    _loadNotes();
    _loadTheme();
  }

  void changeTheme(int index) {
    setState(() {
      selectedThemeIndex = index;
    });
    _saveTheme(index);
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt('selectedThemeIndex') ?? 0;
    setState(() {
      selectedThemeIndex = themeIndex;
    });
  }

  Future<void> _loadNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final notesData = prefs.getString('notes') ?? '[]';

    setState(() {
      notes.clear();
      notes.addAll((jsonDecode(notesData) as List)
          .map((note) => Note(
        title: note['title'],
        content: note['content'],
      )));
    });
  }

  Future<void> _saveTheme(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('selectedThemeIndex', index);
  }

  Future<void> _saveNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final notesData = jsonEncode(notes.map((note) => {
      'title': note.title,
      'content': note.content,
    }).toList());

    await prefs.setString('notes', notesData);
  }

  void deleteAllNotes() {
    setState(() {
      notes.clear();
    });
    _saveNotes();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Note App',
      theme: appThemes[selectedThemeIndex],
      home: NoteListScreen(
        notes: notes,
        onChangeTheme: changeTheme,
        selectedThemeIndex: selectedThemeIndex,
        onDeleteAllNotes: deleteAllNotes,
        onSaveNotes: _saveNotes
      ),
    );
  }
}

class Note {
  String title;
  String content;

  Note({required this.title, required this.content});
}

class NoteListScreen extends StatefulWidget {
  final List<Note> notes;
  final Function(int) onChangeTheme;
  final VoidCallback onDeleteAllNotes;
  final VoidCallback onSaveNotes;
  final int selectedThemeIndex;

  NoteListScreen({
    required this.notes,
    required this.onChangeTheme,
    required this.onDeleteAllNotes,
    required this.onSaveNotes,
    required this.selectedThemeIndex
  });

  @override
  _NoteListScreenState createState() => _NoteListScreenState();
}

class _NoteListScreenState extends State<NoteListScreen> {
  bool isDeleteMode = false;

  void _addNote() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => NoteEditorScreen(
          selectedThemeIndex: widget.selectedThemeIndex,
          onSave: (title, content) {
            if (title.isEmpty) title = "Untitled";
            if (title.isNotEmpty || content.isNotEmpty) {
              setState(() {
                widget.notes.add(Note(
                  title: title,
                  content: content,
                ));
              });
              widget.onSaveNotes();
            }
          },
        ),
      ),
    );
  }

  void _toggleDeleteMode() {
    setState(() {
      isDeleteMode = !isDeleteMode;
    });
  }

  void _deleteNoteConfirm(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete note'),
        content: Text('Are you sure you want to delete this note?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                widget.notes.removeAt(index);
              });
              widget.onSaveNotes();  // Save notes after deletion
              Navigator.of(context).pop();
            },
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SettingsScreen(
          selectedThemeIndex: widget.selectedThemeIndex,
          onChangeTheme: widget.onChangeTheme,
          onDeleteAllNotes: widget.onDeleteAllNotes,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Simple Notes'),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: _openSettings,
          ),
          IconButton(
            icon: Icon(isDeleteMode ? Icons.cancel : Icons.delete),
            onPressed: _toggleDeleteMode,
          ),
        ],
      ),
      body: widget.notes.isEmpty
          ? Center(
        child: Text('No notes yet. Tap the + button to add one.'),
      )
          : GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 8.0,
          mainAxisSpacing: 8.0,
        ),
        padding: const EdgeInsets.all(8.0),
        itemCount: widget.notes.length,
        itemBuilder: (context, index) {
          final note = widget.notes[index];
          return Card(
            elevation: 4.0,
            child: InkWell(
              onTap: isDeleteMode
                  ? () => _deleteNoteConfirm(index)
                  : () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => NoteEditorScreen(
                      initialTitle: note.title,
                      initialContent: note.content,
                      selectedThemeIndex: widget.selectedThemeIndex,
                      onSave: (editedTitle, editedContent) {
                        if (editedTitle.isEmpty) editedTitle = "Untitled";
                        if (editedTitle.isNotEmpty || editedContent.isNotEmpty) {
                          setState(() {
                            widget.notes[index] = Note(
                              title: editedTitle,
                              content: editedContent,
                            );
                          });
                          widget.onSaveNotes();
                        }
                      },
                    ),
                  ),
                );
              },
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          note.title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16.0,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4.0),
                        Flexible(
                          child: Text(
                            note.content,
                            style: TextStyle(fontSize: 14.0),
                            maxLines: 6,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: isDeleteMode
          ? null
          : FloatingActionButton(
        onPressed: _addNote,
        child: Icon(Icons.add),
      ),
    );
  }
}

class NoteEditorScreen extends StatefulWidget {
  final String initialTitle;
  final String initialContent;
  final Function(String, String) onSave;
  final int selectedThemeIndex;

  NoteEditorScreen({
    this.initialTitle = '',
    this.initialContent = '',
    required this.onSave,
    required this.selectedThemeIndex
  });

  @override
  _NoteEditorScreenState createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  bool _isModified = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);
    _contentController = TextEditingController(text: widget.initialContent);

    _titleController.addListener(_onModified);
    _contentController.addListener(_onModified);
  }

  void _onModified() {
    setState(() {
      _isModified = true;
    });
  }

  Future<bool> _onWillPop() async {
    if (_isModified) {
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Unsaved changes'),
          content: Text('You have unsaved changes. Are you sure you want to discard them?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Discard'),
            ),
          ],
        ),
      );
      return result ?? false;
    }
    return true;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: appThemes[widget.selectedThemeIndex],
      child: WillPopScope(
        onWillPop: _onWillPop,
        child: Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                if (_isModified) Text('*'),
                Expanded(
                  child: TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      hintText: 'Untitled',
                      border: InputBorder.none,
                    ),
                    style: TextStyle(
                      fontSize: 20.0,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.save),
                onPressed: () {
                  widget.onSave(
                    _titleController.text.trim(),
                    _contentController.text.trim(),
                  );
                  setState(() {
                    _isModified = false;
                  });
                },
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _contentController,
              decoration: InputDecoration(
                hintText: 'Write your note here...',
              ),
              maxLines: null,
              expands: true,
              keyboardType: TextInputType.multiline,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\s\S]*')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  final int selectedThemeIndex;
  final Function(int) onChangeTheme;
  final VoidCallback onDeleteAllNotes;

  SettingsScreen({
    required this.selectedThemeIndex,
    required this.onChangeTheme,
    required this.onDeleteAllNotes,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: Column(
        children: [
          ListTile(
            title: Text('Select theme'),
            subtitle: Text('Choose your preferred app theme.'),
          ),
          for (int i = 0; i < appThemes.length; i++)
            RadioListTile<int>(
              value: i,
              groupValue: selectedThemeIndex,
              title: Text('Theme ${i + 1}'),
              onChanged: (value) {
                if (value != null) onChangeTheme(value);
              },
            ),
          Divider(),
          ListTile(
            title: Text('Delete All Notes'),
            onTap: () => _confirmDeleteAll(context),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAll(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete All Notes'),
        content: Text('Are you sure you want to delete all notes? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              onDeleteAllNotes();
              Navigator.of(context).pop();
            },
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }
}


