import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBProvider {
  DBProvider._();
  static final DBProvider db = DBProvider._();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'life_companion.db');

    return await openDatabase(path, version: 2, onCreate: _onCreate, onOpen: _onOpen);
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE goals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT,
        level TEXT DEFAULT 'daily',
        parent_id INTEGER,
        start_date INTEGER,
        end_date INTEGER,
        remind_minutes INTEGER DEFAULT 0,
        repeat_rule TEXT,
        remind_time INTEGER,
        priority INTEGER DEFAULT 0,
        progress INTEGER DEFAULT 0,
        status TEXT DEFAULT 'active',
        created_at INTEGER,
        meaning TEXT,
        difficulty INTEGER DEFAULT 5,
        checkin_frequency INTEGER DEFAULT 5,
        checkin_days TEXT,
        micro_actions TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        goal_id INTEGER,
        title TEXT NOT NULL,
        done INTEGER DEFAULT 0,
        due_date INTEGER,
        FOREIGN KEY(goal_id) REFERENCES goals(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE moods (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        emoji TEXT,
        mood_tag TEXT,
        note TEXT,
        timestamp INTEGER,
        location_id INTEGER,
        intensity INTEGER DEFAULT 5,
        trigger TEXT,
        trigger_note TEXT,
        body_feeling TEXT,
        desire TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE locations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        latitude REAL,
        longitude REAL,
        address TEXT,
        timestamp INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE tracks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        start_time INTEGER,
        end_time INTEGER,
        distance REAL
      )
    ''');

    await db.execute('''
      CREATE TABLE track_points (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        track_id INTEGER,
        latitude REAL,
        longitude REAL,
        timestamp INTEGER,
        FOREIGN KEY(track_id) REFERENCES tracks(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE schedules (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT,
        start_time INTEGER,
        end_time INTEGER,
        repeat_rule TEXT,
        remind_minutes INTEGER,
        energy TEXT DEFAULT 'medium',
        priority TEXT DEFAULT 'normal',
        status TEXT DEFAULT 'pending',
        goal_id INTEGER,
        sound_path TEXT,
        vibrate INTEGER DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount REAL,
        type TEXT,
        category TEXT,
        note TEXT,
        timestamp INTEGER,
        location_id INTEGER,
        feeling TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE workouts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        start_time INTEGER,
        end_time INTEGER,
        distance_km REAL,
        steps INTEGER,
        calories INTEGER,
        note TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE entertainments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        media_type TEXT NOT NULL,
        title TEXT NOT NULL,
        creator TEXT,
        rating REAL,
        feeling TEXT,
        tags TEXT,
        timestamp INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE focus_sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        goal_id INTEGER NOT NULL,
        label TEXT NOT NULL,
        start_time INTEGER,
        end_time INTEGER,
        duration_seconds INTEGER DEFAULT 0,
        FOREIGN KEY(goal_id) REFERENCES goals(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE checkin_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        goal_id INTEGER NOT NULL,
        timestamp INTEGER,
        note TEXT,
        emotion TEXT,
        FOREIGN KEY(goal_id) REFERENCES goals(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE hobbies (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        category TEXT DEFAULT 'other',
        status TEXT DEFAULT 'want_try',
        abandon_reason TEXT,
        total_seconds INTEGER DEFAULT 0,
        created_at INTEGER,
        note TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE hobby_works (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        hobby_id INTEGER NOT NULL,
        title TEXT,
        image_path TEXT,
        note TEXT,
        emotion TEXT,
        created_at INTEGER,
        FOREIGN KEY(hobby_id) REFERENCES hobbies(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE body_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        record_type TEXT NOT NULL,
        timestamp INTEGER,
        sleep_time INTEGER,
        wake_time INTEGER,
        sleep_quality INTEGER,
        diet_content TEXT,
        diet_feeling TEXT,
        health_note TEXT,
        note TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE persons (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        relationship TEXT,
        birthday TEXT,
        preferences TEXT,
        note TEXT,
        created_at INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE relationship_moments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        person_id INTEGER,
        content TEXT,
        note TEXT,
        image_path TEXT,
        timestamp INTEGER,
        FOREIGN KEY(person_id) REFERENCES persons(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE inspirations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        record_type TEXT NOT NULL,
        content TEXT,
        source TEXT,
        tags TEXT,
        timestamp INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE gratitudes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        record_type TEXT NOT NULL,
        content TEXT,
        image_path TEXT,
        timestamp INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE milestones (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT,
        category TEXT,
        image_path TEXT,
        event_date INTEGER,
        created_at INTEGER
      )
    ''');
  }

  Future _onOpen(Database db) async {
    // Goals table migrations
    final goalInfo = await db.rawQuery("PRAGMA table_info('goals')");
    final goalCols = goalInfo.map((e) => e['name'] as String).toList();
    if (!goalCols.contains('repeat_rule')) {
      await db.execute("ALTER TABLE goals ADD COLUMN repeat_rule TEXT");
    }
    if (!goalCols.contains('remind_time')) {
      await db.execute("ALTER TABLE goals ADD COLUMN remind_time INTEGER");
    }

    // Create workouts table if missing
    await db.execute('''
      CREATE TABLE IF NOT EXISTS workouts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        start_time INTEGER,
        end_time INTEGER,
        distance_km REAL,
        steps INTEGER,
        calories INTEGER,
        note TEXT
      )
    ''');

    // Create entertainments table if missing
    await db.execute('''
      CREATE TABLE IF NOT EXISTS entertainments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        media_type TEXT NOT NULL,
        title TEXT NOT NULL,
        creator TEXT,
        rating REAL,
        feeling TEXT,
        tags TEXT,
        timestamp INTEGER,
        image_url TEXT
      )
    ''');

    // Add image_url column if missing
    final entInfo = await db.rawQuery("PRAGMA table_info('entertainments')");
    final entCols = entInfo.map((e) => e['name'] as String).toList();
    if (!entCols.contains('image_url')) {
      await db.execute("ALTER TABLE entertainments ADD COLUMN image_url TEXT");
    }

    // Create focus_sessions table if missing
    await db.execute('''
      CREATE TABLE IF NOT EXISTS focus_sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        goal_id INTEGER NOT NULL,
        label TEXT NOT NULL,
        start_time INTEGER,
        end_time INTEGER,
        duration_seconds INTEGER DEFAULT 0,
        FOREIGN KEY(goal_id) REFERENCES goals(id) ON DELETE CASCADE
      )
    ''');

    // Add route_json column to workouts if missing
    final wInfo = await db.rawQuery("PRAGMA table_info('workouts')");
    final wCols = wInfo.map((e) => e['name'] as String).toList();
    if (!wCols.contains('route_json')) {
      await db.execute("ALTER TABLE workouts ADD COLUMN route_json TEXT");
    }

    // Goals new columns migration
    if (!goalCols.contains('level')) {
      await db.execute("ALTER TABLE goals ADD COLUMN level TEXT DEFAULT 'daily'");
    }
    if (!goalCols.contains('parent_id')) {
      await db.execute("ALTER TABLE goals ADD COLUMN parent_id INTEGER");
    }
    if (!goalCols.contains('meaning')) {
      await db.execute("ALTER TABLE goals ADD COLUMN meaning TEXT");
    }
    if (!goalCols.contains('difficulty')) {
      await db.execute("ALTER TABLE goals ADD COLUMN difficulty INTEGER DEFAULT 5");
    }
    if (!goalCols.contains('checkin_frequency')) {
      await db.execute("ALTER TABLE goals ADD COLUMN checkin_frequency INTEGER DEFAULT 5");
    }
    if (!goalCols.contains('checkin_days')) {
      await db.execute("ALTER TABLE goals ADD COLUMN checkin_days TEXT");
    }
    if (!goalCols.contains('micro_actions')) {
      await db.execute("ALTER TABLE goals ADD COLUMN micro_actions TEXT");
    }

    // Create checkin_records table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS checkin_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        goal_id INTEGER NOT NULL,
        timestamp INTEGER,
        note TEXT,
        emotion TEXT,
        FOREIGN KEY(goal_id) REFERENCES goals(id) ON DELETE CASCADE
      )
    ''');

    // Create hobbies table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS hobbies (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        category TEXT DEFAULT 'other',
        status TEXT DEFAULT 'want_try',
        abandon_reason TEXT,
        total_seconds INTEGER DEFAULT 0,
        created_at INTEGER,
        note TEXT
      )
    ''');

    // Create hobby_works table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS hobby_works (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        hobby_id INTEGER NOT NULL,
        title TEXT,
        image_path TEXT,
        note TEXT,
        emotion TEXT,
        created_at INTEGER,
        FOREIGN KEY(hobby_id) REFERENCES hobbies(id) ON DELETE CASCADE
      )
    ''');

    // Mood table new columns
    final moodInfo = await db.rawQuery("PRAGMA table_info('moods')");
    final moodCols = moodInfo.map((e) => e['name'] as String).toList();
    if (!moodCols.contains('intensity')) {
      await db.execute("ALTER TABLE moods ADD COLUMN intensity INTEGER DEFAULT 5");
    }
    if (!moodCols.contains('trigger')) {
      await db.execute("ALTER TABLE moods ADD COLUMN trigger TEXT");
    }
    if (!moodCols.contains('trigger_note')) {
      await db.execute("ALTER TABLE moods ADD COLUMN trigger_note TEXT");
    }
    if (!moodCols.contains('body_feeling')) {
      await db.execute("ALTER TABLE moods ADD COLUMN body_feeling TEXT");
    }
    if (!moodCols.contains('desire')) {
      await db.execute("ALTER TABLE moods ADD COLUMN desire TEXT");
    }

    // Schedule table new columns
    final schInfo = await db.rawQuery("PRAGMA table_info('schedules')");
    final schCols = schInfo.map((e) => e['name'] as String).toList();
    if (!schCols.contains('energy')) {
      await db.execute("ALTER TABLE schedules ADD COLUMN energy TEXT DEFAULT 'medium'");
    }
    if (!schCols.contains('priority')) {
      await db.execute("ALTER TABLE schedules ADD COLUMN priority TEXT DEFAULT 'normal'");
    }
    if (!schCols.contains('status')) {
      await db.execute("ALTER TABLE schedules ADD COLUMN status TEXT DEFAULT 'pending'");
    }
    if (!schCols.contains('goal_id')) {
      await db.execute("ALTER TABLE schedules ADD COLUMN goal_id INTEGER");
    }
    if (!schCols.contains('sound_path')) {
      await db.execute("ALTER TABLE schedules ADD COLUMN sound_path TEXT");
    }
    if (!schCols.contains('vibrate')) {
      await db.execute("ALTER TABLE schedules ADD COLUMN vibrate INTEGER DEFAULT 1");
    }

    // Transaction table new columns
    final txInfo = await db.rawQuery("PRAGMA table_info('transactions')");
    final txCols = txInfo.map((e) => e['name'] as String).toList();
    if (!txCols.contains('feeling')) {
      await db.execute("ALTER TABLE transactions ADD COLUMN feeling TEXT");
    }

    // Workout new columns
    if (!wCols.contains('body_feeling')) {
      await db.execute("ALTER TABLE workouts ADD COLUMN body_feeling TEXT");
    }
    if (!wCols.contains('mood_before')) {
      await db.execute("ALTER TABLE workouts ADD COLUMN mood_before TEXT");
    }
    if (!wCols.contains('mood_after')) {
      await db.execute("ALTER TABLE workouts ADD COLUMN mood_after TEXT");
    }
    if (!wCols.contains('custom_tags')) {
      await db.execute("ALTER TABLE workouts ADD COLUMN custom_tags TEXT");
    }

    // Entertainment new columns
    if (!entCols.contains('status')) {
      await db.execute("ALTER TABLE entertainments ADD COLUMN status TEXT");
    }
    if (!entCols.contains('progress')) {
      await db.execute("ALTER TABLE entertainments ADD COLUMN progress TEXT");
    }
    if (!entCols.contains('mood_after')) {
      await db.execute("ALTER TABLE entertainments ADD COLUMN mood_after TEXT");
    }
    if (!entCols.contains('memorable_moment')) {
      await db.execute("ALTER TABLE entertainments ADD COLUMN memorable_moment TEXT");
    }
    if (!entCols.contains('personal_insight')) {
      await db.execute("ALTER TABLE entertainments ADD COLUMN personal_insight TEXT");
    }

    // New tables
    await db.execute('''
      CREATE TABLE IF NOT EXISTS body_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        record_type TEXT NOT NULL,
        timestamp INTEGER,
        sleep_time INTEGER,
        wake_time INTEGER,
        sleep_quality INTEGER,
        diet_content TEXT,
        diet_feeling TEXT,
        health_note TEXT,
        note TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS persons (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        relationship TEXT,
        birthday TEXT,
        preferences TEXT,
        note TEXT,
        created_at INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS relationship_moments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        person_id INTEGER,
        content TEXT,
        note TEXT,
        image_path TEXT,
        timestamp INTEGER,
        FOREIGN KEY(person_id) REFERENCES persons(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS inspirations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        record_type TEXT NOT NULL,
        content TEXT,
        source TEXT,
        tags TEXT,
        timestamp INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS gratitudes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        record_type TEXT NOT NULL,
        content TEXT,
        image_path TEXT,
        timestamp INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS milestones (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT,
        category TEXT,
        image_path TEXT,
        event_date INTEGER,
        created_at INTEGER
      )
    ''');

    // ── 索引（IF NOT EXISTS 保证幂等） ──
    await db.execute('CREATE INDEX IF NOT EXISTS idx_moods_timestamp ON moods(timestamp)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_schedules_start ON schedules(start_time)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_schedules_status ON schedules(status)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_transactions_timestamp ON transactions(timestamp)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_entertainments_timestamp ON entertainments(timestamp)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_entertainments_type ON entertainments(media_type)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_workouts_start ON workouts(start_time)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_body_records_type ON body_records(record_type, timestamp)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_gratitudes_timestamp ON gratitudes(timestamp)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_inspirations_timestamp ON inspirations(timestamp)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_checkin_goal ON checkin_records(goal_id, timestamp)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_focus_goal ON focus_sessions(goal_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_moments_person ON relationship_moments(person_id, timestamp)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_milestones_date ON milestones(event_date)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_goals_status ON goals(status)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_tasks_goal ON tasks(goal_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_hobby_works_hobby ON hobby_works(hobby_id)');

    // hobby_works: add media_type column
    final hwInfo = await db.rawQuery("PRAGMA table_info('hobby_works')");
    final hwCols = hwInfo.map((e) => e['name'] as String).toList();
    if (!hwCols.contains('media_type')) {
      await db.execute("ALTER TABLE hobby_works ADD COLUMN media_type TEXT DEFAULT 'image'");
    }
  }

  // Example helpers
  Future<int> insert(String table, Map<String, dynamic> values) async {
    final db = await database;
    return await db.insert(table, values);
  }

  Future<List<Map<String, dynamic>>> queryAll(String table) async {
    final db = await database;
    return await db.query(table, orderBy: 'id DESC');
  }

  Future<int> update(String table, Map<String, dynamic> values, int id) async {
    final db = await database;
    return await db.update(table, values, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> delete(String table, int id) async {
    final db = await database;
    return await db.delete(table, where: 'id = ?', whereArgs: [id]);
  }
}
