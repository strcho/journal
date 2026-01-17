import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';
import 'journal.dart';

class JournalRepository {
  JournalRepository._(this._isar);

  final Isar _isar;

  static const _defaultJournalUuid = '00000000-0000-0000-0000-000000000001';
  static const _defaultJournalName = '日常';

  static Future<JournalRepository> open(Isar isar) async {
    final repo = JournalRepository._(isar);
    await repo._ensureDefaultJournal();
    return repo;
  }

  Future<void> _ensureDefaultJournal() async {
    final defaultJournal = await _isar.journals
        .filter()
        .uuidEqualTo(_defaultJournalUuid)
        .findFirst();

    if (defaultJournal == null) {
      final now = DateTime.now();
      final journal = Journal()
        ..uuid = _defaultJournalUuid
        ..name = _defaultJournalName
        ..color = null
        ..createdAt = now
        ..updatedAt = now
        ..deletedAt = null
        ..isDirty = true
        ..serverRevision = null;

      await _isar.writeTxn(() async {
        await _isar.journals.put(journal);
      });
    }
  }

  Future<Journal?> getDefaultJournal() async {
    return await _isar.journals
        .filter()
        .uuidEqualTo(_defaultJournalUuid)
        .findFirst();
  }

  Stream<List<Journal>> watchJournals() {
    return _isar.journals
        .filter()
        .deletedAtIsNull()
        .sortByUpdatedAtDesc()
        .watch(fireImmediately: true);
  }

  Future<List<Journal>> getJournals() async {
    return await _isar.journals
        .filter()
        .deletedAtIsNull()
        .sortByUpdatedAtDesc()
        .findAll();
  }

  Future<Journal?> getJournalById(String uuid) async {
    return await _isar.journals.filter().uuidEqualTo(uuid).findFirst();
  }

  Future<void> saveJournal(Journal journal) async {
    await _isar.writeTxn(() async {
      journal.isDirty = true;
      await _isar.journals.put(journal);
    });
  }

  Future<Journal> createJournal({required String name, String? color}) async {
    final now = DateTime.now();
    final journal = Journal()
      ..uuid = const Uuid().v4()
      ..name = name
      ..color = color
      ..createdAt = now
      ..updatedAt = now
      ..deletedAt = null
      ..isDirty = true
      ..serverRevision = null;

    await _isar.writeTxn(() async {
      await _isar.journals.put(journal);
    });

    return journal;
  }

  Future<void> updateJournal(String uuid, {String? name, String? color}) async {
    await _isar.writeTxn(() async {
      final journal = await _isar.journals
          .filter()
          .uuidEqualTo(uuid)
          .findFirst();

      if (journal == null) {
        throw Exception('Journal not found');
      }

      if (uuid == _defaultJournalUuid && name != null) {
        throw Exception('Default journal name cannot be changed');
      }

      if (name != null) {
        journal.name = name;
      }
      if (color != null) {
        journal.color = color;
      }
      journal.updatedAt = DateTime.now();
      journal.isDirty = true;

      await _isar.journals.put(journal);
    });
  }

  Future<void> deleteJournal(String uuid) async {
    if (uuid == _defaultJournalUuid) {
      throw Exception('Default journal cannot be deleted');
    }

    await _isar.writeTxn(() async {
      final journal = await _isar.journals
          .filter()
          .uuidEqualTo(uuid)
          .findFirst();

      if (journal == null) {
        throw Exception('Journal not found');
      }

      if (journal.deletedAt != null) {
        return;
      }

      journal.deletedAt = DateTime.now();
      journal.updatedAt = DateTime.now();
      journal.isDirty = true;

      await _isar.journals.put(journal);
    });
  }
}
