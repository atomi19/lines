import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';

part 'database.g.dart';

class NotesItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  TextColumn get content => text()();
}

@DriftDatabase(tables: [NotesItems])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

  // CRUD methods
  // create note
  Future<int> addNote(String title, String content) {
    return into(notesItems).insert(
      NotesItemsCompanion.insert(
        title: title, 
        content: content
      )
    );
  }

  // read note
  Future<List<NotesItem>> getAllNotes() {
    return select(notesItems).get();
  }

  // find note by id
  Future<NotesItem?> findNote(int id) async {
    return (select(notesItems)..where((note) => note.id.equals(id))).getSingleOrNull();
  }

  // update note
  Future<int> updateNote({
    required int id,
    String? title,
    String? content,
  }) {
    final companion = NotesItemsCompanion(
      title: title != null ? Value(title) : Value.absent(),
      content: content != null ? Value(content) : Value.absent(),
    );
    return (update(notesItems)..where((note) => note.id.equals(id))).write(companion);
  }

  // delete note
  Future<int> deleteNote(int id) {
    return (delete(notesItems)..where((note) => note.id.equals(id))).go();
  }

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'lines_database',
      native: const DriftNativeOptions(
        databaseDirectory: getApplicationSupportDirectory,
      ),
    );
  }
}