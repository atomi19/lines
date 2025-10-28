import 'package:flutter/material.dart';
import 'package:lines/logic/database.dart';
import 'package:lines/widgets/build_button.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final db = AppDatabase();
  List<NotesItem> _notes =  [];

  int _currentSelectedNoteId = 0;

  // side panel variables
  double _panelWidth = 200;
  final double _minPanelWidth = 150;
  final double _maxPanelWidth = 300;
  static const double _closePanelWidth = 140;
  bool _isSidebarOpen = true;
  bool _isDraggingPanel = false;

  // text field controllers
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadNotes(); // load notes on app start
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
                  if(_notes.isEmpty) return;

                  final idToDelete = _currentSelectedNoteId;
                  await db.deleteNote(idToDelete);

                  setState(() {                    
                    _notes.removeWhere((note) => note.id == idToDelete);
                    if(_notes.isNotEmpty){
                      _currentSelectedNoteId = _notes.last.id;
                      _updateTextFields(_notes.last.title, _notes.last.content);
                    } else {
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
                decoration: BoxDecoration(
                  border: BoxBorder.fromLTRB(
                    right: BorderSide(width: 1, color: Colors.grey.shade200)
                  )
                ),
                child: ListView.builder(
                  itemCount: _notes.length,
                  itemBuilder: (BuildContext context, int index) {
                    return Container(
                      decoration: BoxDecoration(
                        color: _currentSelectedNoteId == _notes[index].id
                        ? Colors.grey.shade300 // selected note color
                        : Colors.white, // not selected note color
                        border: BoxBorder.fromLTRB(
                          bottom: BorderSide(width: 1, color: Colors.grey.shade300)
                        )
                      ),
                      child: ListTile(
                        title: Text(_notes[index].title),
                        subtitle: _notes[index].content.isNotEmpty 
                        ? Text(
                          _notes[index].content,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        )
                        : null,
                        onTap: ()  {
                          _currentSelectedNoteId = _notes[index].id;
                          _updateTextFields(
                            _notes[index].title,
                            _notes[index].content,
                          );
                          setState(() {});
                        }
                      )
                    );
                  }
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
                  }
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
                          Row(
                            spacing: 15,
                            children: [
                              // close sidebar button
                              buildIconButton(
                                onTap: () {
                                  setState(() {
                                    _isSidebarOpen = !_isSidebarOpen;
                                  });
                                }, 
                                icon: _isSidebarOpen ? Icons.chevron_left : Icons.view_sidebar_outlined
                              ),
                              // delete note button
                              buildIconButton(
                                onTap: () => _showAlertDialog(),
                                icon: Icons.delete_outlined
                              ),
                            ],
                          ),
                          // create new note button 
                          buildIconButton(
                            onTap: () async {
                              await db.addNote('', '');
                              await _loadNotes();
                              _currentSelectedNoteId = _notes.last.id;
                              _updateTextFields('', '');
                            }, 
                            icon: Icons.create_outlined
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