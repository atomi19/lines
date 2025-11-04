import 'package:flutter/material.dart';
import 'package:lines/logic/database.dart';
import 'package:lines/widgets/build_button.dart';
import 'package:lines/logic/shared_preferences_helper.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final db = AppDatabase();
  List<NotesItem> _notes =  [];
  List<NotesItem> _foundNotes = [];

  int _currentSelectedNoteId = 0;
  bool _isSearchingNotes = false;

  // side panel variables
  double _panelWidth = 200;
  static const double _minPanelWidth = 150;
  static const double _maxPanelWidth = 300;
  static const double _closePanelWidth = 140;
  bool _isSidebarOpen = true;
  bool _isDraggingPanel = false;

  // text field controllers
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadNotes(); // load notes on app start
    _loadSiderbarState();
    _loadPanelWidth();
  }

  // load notes from db
  Future<void> _loadNotes() async {
    final notes = await db.getAllNotes();
    setState(() {
      _notes = notes;
      _currentSelectedNoteId = notes.last.id;
      _updateTextFields(_notes.last.title, _notes.last.content);
    });
  }

  // load side panel width
  Future<void> _loadPanelWidth() async {
    final width = await getDouble(panelWidthKey);
    setState(() {
      // check if width is less then 150
      // if so then set it to 150
      // because if width is less then 150 and we will try to
      // drag panel, it will close immediately
      // otherwise just set it's width
      if(width != null && width < 150.0) {
        _panelWidth = 150.0;
      } else {
        _panelWidth = width ?? 150;
      }
    });
  }
  // load sidebar state (closed or not)
  Future<void> _loadSiderbarState() async {
    bool? value = await getBool(isSidebarOpenKey);
    setState(() {
      _isSidebarOpen = value ?? true;
    });
  }

  void _updateTextFields(String title, String content) {
    _titleController.text = title;
    _contentController.text = content;
  }

  // delete note confirm dialog
  void _showAlertDialog() {
    showDialog(
      context: context, 
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Delete note?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // cancel note deletion button
              buildTextButton(
                color: Colors.grey.shade100,
                hoverColor: Colors.grey.shade200,
                splashColor: Colors.grey.shade300, 
                buttonText: 'Cancel',
                buttonTextColor: Colors.black,
                onTap: () => Navigator.pop(context)
              ),
              // delete note button
              buildTextButton(
                color: Colors.red.shade600,
                hoverColor: Colors.red.shade500,
                splashColor: Colors.red.shade400,
                buttonText: 'Delete',
                buttonTextColor: Colors.white, 
                onTap: () async {
                  Navigator.pop(context);

                  final idToDelete = _currentSelectedNoteId;
                  await db.deleteNote(idToDelete);

                  setState(() {
                    _notes.removeWhere((note) => note.id == idToDelete);

                    // remove from found notes
                    if(_isSearchingNotes) {
                      _foundNotes.removeWhere((note) => note.id == idToDelete);
                    }

                    final currentList = _isSearchingNotes ? _foundNotes : _notes;

                    if(currentList.isNotEmpty) {
                      // there is notes in the list
                      final lastNote = currentList.last;
                      _currentSelectedNoteId = lastNote.id;
                      _updateTextFields(lastNote.title, lastNote.content);
                    } else {
                      // there is no notes in the list
                      _currentSelectedNoteId = 0;
                      _updateTextFields('', '');
                    }
                  });
                }
              )
            ],
          )
        ],
      )
    );
  }

  // more menu 
  void _showMoreMenu() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadiusGeometry.vertical(top: Radius.circular(10))
      ),
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.fromLTRB(0, 10, 0, 0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.create_outlined),
                  title: const Text('Create Note'),
                  onTap: () async {
                    Navigator.pop(context);
                    await db.addNote('', '');
                    await _loadNotes();
                    _currentSelectedNoteId = _notes.last.id;
                    _updateTextFields('', '');
                  },
                ),
                ListTile(
                  leading: Icon(Icons.delete_outlined, color: Colors.red.shade600,),
                  title: Text('Delete Note', style: TextStyle(color: Colors.red.shade600),),
                  onTap: () {
                    Navigator.pop(context);
                    _showAlertDialog();
                  },
                ),
              ],
            ),
          ),
        );
      }
    );
  }

  // build notes list 
  Widget _buildNotes({
    required List<NotesItem> notes
  }) {
    return ListView.builder(
      itemCount: notes.length,
      itemBuilder: (BuildContext context, int index) {
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 3),
          child: Material(
            color: _currentSelectedNoteId == notes[index].id
            //? Colors.grey.shade300 // selected note color
            ? Colors.grey.shade300
            : Colors.white, // not selected note color
            borderRadius: BorderRadius.circular(10),
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              title: Text(notes[index].title),
              subtitle: notes[index].content.isNotEmpty 
              ? Text(
                notes[index].content,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              )
              : null,
              onTap: ()  {
                _currentSelectedNoteId = notes[index].id;
                _updateTextFields(
                  notes[index].title,
                  notes[index].content,
                );
                setState(() {});
              }
            ), 
          ),
        );
      }
    );
  }

  void _handleNotesSearch(String query) {
    if(query.trim().isEmpty) {
      _isSearchingNotes = false;
    } else {
      _isSearchingNotes = true;
    }
    _searchNotes(query.toLowerCase());
    setState(() {});
  }

  // search for notes by title and content
  void _searchNotes(String query) {
    if(query.trim().isNotEmpty) {
      final foundNotes = _notes.where((note) => 
        note.title.toString().toLowerCase().contains(query) || 
        note.content.toString().toLowerCase().contains(query)
      );
      _foundNotes = foundNotes.toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Row(
          children: [
            // sidepanel with notes list
            _isSidebarOpen
            ? SizedBox(
              width: _panelWidth,
              child: Container(
                padding: EdgeInsets.fromLTRB(5, 0, 5, 5),
                child: Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.fromLTRB(0, 10, 0, 5),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.grey.shade100,
                      ),
                      child: TextField(
                        controller: _searchController,
                        cursorColor: Colors.black,
                        cursorWidth: 1,
                        decoration: InputDecoration(
                          hintText: 'Search notes',
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                          prefixIcon: Icon(Icons.search_outlined),
                          suffixIcon: _isSearchingNotes
                          ? MouseRegion(                            
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              child: Icon(Icons.clear_rounded),
                              onTap: () {
                                setState(() {
                                  _searchController.clear();
                                  _isSearchingNotes = false;
                                });
                              },
                            )
                          )
                          : null
                        ),
                        onChanged: (String query) => _handleNotesSearch(query)
                      ),
                    ),
                    Expanded(
                      child: _isSearchingNotes
                      // found notes or text placeholder if there is no found notes
                      ? _foundNotes.isEmpty
                        ? Center(
                          child: Text('No notes found', style: TextStyle(fontSize: 16, color: Colors.grey.shade600))
                        )
                        : _buildNotes(notes: _foundNotes)
                      // all notes
                      : _buildNotes(notes: _notes)
                    )
                  ],
                )
              )
            )
            : SizedBox(),
            // draggable side panel
            _isSidebarOpen 
            ? GestureDetector(
              behavior: HitTestBehavior.translucent,
              onHorizontalDragStart: (_) {
                setState(() {
                  _isDraggingPanel = true;
                });
              },
              onHorizontalDragUpdate: (details) {
                setState(() {
                  _panelWidth += details.delta.dx;
                  // check if panel should be closed
                  if(_panelWidth < _closePanelWidth) {
                    _isSidebarOpen = false;
                    saveBool(isSidebarOpenKey, false);
                  }
                  saveDouble(panelWidthKey, _panelWidth);
                  // max/min panel width 
                  _panelWidth = _panelWidth.clamp(_minPanelWidth, _maxPanelWidth);
                });
              },
              onHorizontalDragEnd: (_) {
                setState(() {
                  _isDraggingPanel = false;
                });
              },
              child: MouseRegion(
                cursor: SystemMouseCursors.resizeColumn,
                child: Container(
                  width: 6,
                  color: _isDraggingPanel ? Colors.grey.shade300 : Colors.grey.shade100,
                ),
              ),
            )
            : SizedBox(),
            // main content area
            Expanded(
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.all(10),
                    child: Container(
                      color: Colors.transparent,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // close/open sidebar button
                          buildIconButton(
                            onTap: () {
                              setState(() {
                                _isSidebarOpen = !_isSidebarOpen;
                                saveBool(isSidebarOpenKey, _isSidebarOpen);
                                if(_isSidebarOpen) {
                                  _isDraggingPanel = false;
                                }
                              });
                            }, 
                            icon: _isSidebarOpen ? Icons.chevron_left : Icons.view_sidebar_outlined
                          ),
                          // more menu button
                          buildIconButton(
                            onTap: () => _showMoreMenu(),
                            icon: Icons.more_horiz
                          )
                        ],
                      ),
                    )
                  ),
                  // if _notes is empty
                  // then show text placeholder
                  // otherwise show note itself
                  _notes.isEmpty 
                  ? Expanded(
                    child: Center(
                      child: Text(
                        'Create a Note',
                        style: TextStyle(fontSize: 25, fontWeight: FontWeight.w600)
                      ),
                    )
                  )
                  : Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // note title
                          TextField(
                            cursorColor: Colors.black,
                            cursorWidth: 1,
                            controller: _titleController,
                            decoration: InputDecoration(
                              hintText: 'Title',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.all(10),
                            ),
                            style: TextStyle(
                              fontSize: 30,
                            ),
                            onChanged: (String value) {
                              db.updateNote(id: _currentSelectedNoteId, title: value,);
                              // updated local notes list 
                              final index = _notes.indexWhere((note) => note.id == _currentSelectedNoteId);
                              if(index != -1) {
                                _notes[index] = _notes[index].copyWith(title: value);
                                setState(() {});
                              }
                            },
                          ),
                          // note content
                          TextField(
                            cursorColor: Colors.black,
                            cursorWidth: 1,
                            controller: _contentController,
                            maxLines: null,
                            decoration: InputDecoration(
                              hintText: 'Content',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.all(10),
                            ),
                            onChanged: (String value) {
                              db.updateNote(id: _currentSelectedNoteId, content: value);
                              // updated local notes list 
                              final index = _notes.indexWhere((note) => note.id == _currentSelectedNoteId);
                              if(index != -1) {
                                _notes[index] = _notes[index].copyWith(content: value);
                                setState(() {});
                              }
                            },
                          ),
                        ],
                      ),
                    )
                  ),
                  SizedBox(height: 10)
                ],
              )
            )
          ],
        )
      ),
    );
  }
}