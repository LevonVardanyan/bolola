import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart' show databaseFactoryFfiWeb;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io' show Platform;

import '../models/media_category.dart';
import '../models/media_group.dart';
import '../models/media_item.dart';
import '../models/medias.dart';

/// Database constants for consistent reference
class DatabaseConstants {
  static const String dbName = 'Bolola2.db';
  static const int dbVersion = 4;
  static const String itemsTable = 'items_table';
  static const String groupsTable = 'groups_table';
  static const String categoriesTable = 'categories_table';
}

/// Custom database exception for better error handling
class DatabaseException implements Exception {
  final String message;

  DatabaseException(this.message);

  @override
  String toString() => 'DatabaseException: $message';
}

/// Refactored database provider with improved error handling, security, and performance
class DatabaseProvider {
  static Database? _database;
  static final DatabaseProvider _instance = DatabaseProvider._internal();

  DatabaseProvider._internal();

  /// Singleton instance
  factory DatabaseProvider() => _instance;

  /// Static getter for compatibility with existing code
  static DatabaseProvider get db => _instance;

  /// Get database instance with proper error handling
  Future<Database> get database async {
    try {
      if (_database != null && _database!.isOpen) return _database!;
      _database = await initDB();
      return _database!;
    } catch (e) {
      throw DatabaseException('Failed to initialize database: $e');
    }
  }

  /// Database version for migrations
  int get dbVersion => DatabaseConstants.dbVersion;

  /// Initialize database with proper setup
  Future<Database> initDB() async {
    try {
      // Initialize database factory based on platform
      await _initializeDatabaseFactory();

      String databasesPath = await getDatabasesPath();
      String path = join(databasesPath, DatabaseConstants.dbName);

      return await openDatabase(
        path,
        version: dbVersion,
        onOpen: (db) async {
          // Database opened successfully
        },
        onCreate: (Database db, int version) async {
          await _createAllTables(db);
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          await _onUpgrade(db, oldVersion, newVersion);
        },
      );
    } catch (e) {
      throw DatabaseException('Failed to initialize database: $e');
    }
  }

  /// Initialize the appropriate database factory for the current platform
  Future<void> _initializeDatabaseFactory() async {
    try {
      if (kIsWeb) {
        // Web platform
        databaseFactory = databaseFactoryFfiWeb;
        if (kDebugMode) print('DatabaseProvider: Initialized for Web platform');
      } else {
        // Check for desktop platforms
        bool isDesktop = false;
        try {
          isDesktop = Platform.isWindows || Platform.isLinux || Platform.isMacOS;
        } catch (e) {
          // Platform check failed, assume mobile
          isDesktop = false;
        }
        
        if (isDesktop) {
          // Desktop platforms (Windows, Linux, macOS)
          sqfliteFfiInit();
          databaseFactory = databaseFactoryFfi;
          if (kDebugMode) print('DatabaseProvider: Initialized for Desktop platform');
        } else {
          // Mobile platforms (iOS, Android) - use default sqflite
          if (kDebugMode) print('DatabaseProvider: Using default sqflite for Mobile platform');
        }
      }
    } catch (e) {
      // Fallback: if anything fails, let sqflite handle it with defaults
      if (kDebugMode) print('DatabaseProvider: Platform detection failed, using defaults: $e');
    }
  }

  /// Create all tables
  Future<void> _createAllTables(Database db) async {
    await createCategoriesTable(db);
    await createGroupsTable(db);
    await createItemsTable(db);
  }

  /// Handle database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2 && newVersion >= 2) {
      // Add imageUrl column to items_table (version 1 doesn't have this)
      await db.execute('ALTER TABLE ${DatabaseConstants.itemsTable} ADD COLUMN imageUrl TEXT');
      print('Database upgraded: Added imageUrl column to items_table');
    }
    
    if (oldVersion < 3 && newVersion >= 3) {
      // Add allKeywords column to items_table
      await db.execute('ALTER TABLE ${DatabaseConstants.itemsTable} ADD COLUMN allKeywords TEXT');
      print('Database upgraded: Added allKeywords column to items_table');
    }
    
    if (oldVersion < 4 && newVersion >= 4) {
      await db.execute('ALTER TABLE ${DatabaseConstants.itemsTable} ADD COLUMN fileName TEXT');
      print('Database upgraded: Added fileName column to items_table');
    }
  }

  /// Create items table with proper constraints
  Future<void> createItemsTable(Database db) async {
    try {
      await db.execute('''
        CREATE TABLE ${DatabaseConstants.itemsTable}(
          alias TEXT PRIMARY KEY,
          shareCount INTEGER DEFAULT 0,
          name TEXT,
          groupAlias TEXT,
          categoryAlias TEXT,
          ordering INTEGER DEFAULT 0,
          audioUrl TEXT,
          videoUrl TEXT,
          sourceUrl TEXT,
          imageUrl TEXT,
          mimeType TEXT,
          isFavorite INTEGER DEFAULT 0,
          keywords TEXT,
          relatedKeywords TEXT,
          allKeywords TEXT,
          fileName TEXT
        )
      ''');
    } catch (e) {
      throw DatabaseException('Failed to create items table: $e');
    }
  }

  /// Create groups table with proper constraints
  Future<void> createGroupsTable(Database db) async {
    try {
      await db.execute('''
        CREATE TABLE ${DatabaseConstants.groupsTable}(
          alias TEXT PRIMARY KEY,
          name TEXT,
          iconUrl TEXT,
          categoryAlias TEXT,
          count INTEGER DEFAULT 0,
          ordering INTEGER DEFAULT 0,
          isNew INTEGER DEFAULT 0,
          sortingTypes TEXT
        )
      ''');
    } catch (e) {
      throw DatabaseException('Failed to create groups table: $e');
    }
  }

  /// Create categories table
  Future<void> createCategoriesTable(Database db) async {
    try {
      await db.execute('''
        CREATE TABLE ${DatabaseConstants.categoriesTable}(
          alias TEXT PRIMARY KEY,
          name TEXT,
          groups TEXT,
          ordering INTEGER DEFAULT 0
        )
      ''');
    } catch (e) {
      throw DatabaseException('Failed to create categories table: $e');
    }
  }

  /// Insert all medias with transaction for data integrity
  Future<void> insertAllMedias(Medias medias) async {
    if (medias.categories == null || medias.categories!.isEmpty) {
      throw DatabaseException('No categories to insert');
    }

    try {
      final db = await database;

      await db.transaction((txn) async {
        // Clear existing data
        await txn.delete(DatabaseConstants.categoriesTable);
        await txn.delete(DatabaseConstants.groupsTable);
        await txn.delete(DatabaseConstants.itemsTable);

        // Insert categories and their nested data
        for (MediaCategory category in medias.categories!) {
          await txn.insert(
            DatabaseConstants.categoriesTable,
            category.toDBMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );

          if (category.groups != null) {
            for (MediaGroup group in category.groups!) {
              await txn.insert(
                DatabaseConstants.groupsTable,
                group.dataToDBMap(),
                conflictAlgorithm: ConflictAlgorithm.replace,
              );

              if (group.items?.isNotEmpty == true) {
                await _insertAllItemsInTransaction(txn, group.items!);
              }
            }
          }
        }
      });
    } catch (e) {
      throw DatabaseException('Failed to insert all medias: $e');
    }
  }

  /// Insert items within a transaction
  Future<void> _insertAllItemsInTransaction(Transaction txn, List<MediaItem> items) async {
    for (MediaItem item in items) {
      await txn.insert(
        DatabaseConstants.itemsTable,
        item.toDBMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  /// Get all medias from database with proper error handling
  Future<Medias> getMediasFromDB() async {
    try {
      final db = await database;

      // Get categories with proper ordering
      var categoriesRes = await db.query(
        DatabaseConstants.categoriesTable,
        orderBy: 'ordering ASC',
      );

      List<MediaCategory> categories = categoriesRes.isNotEmpty ? categoriesRes.map((c) => MediaCategory.fromDBMap(c)).toList() : [];

      if (categories.isEmpty) return Medias(categories: []);

      // Get groups
      var groupsRes = await db.query(DatabaseConstants.groupsTable);
      List<MediaGroup> groups = groupsRes.isNotEmpty ? groupsRes.map((c) => MediaGroup.dataFromDBMap(c)).toList() : [];

      // Get items
      var itemsRes = await db.query(DatabaseConstants.itemsTable);
      List<MediaItem> items = itemsRes.isNotEmpty ? itemsRes.map((c) => MediaItem.fromDBMap(c)).toList() : [];

      // Build relationships
      _buildMediaRelationships(categories, groups, items);

      return Medias(categories: categories);
    } catch (e) {
      throw DatabaseException('Failed to get medias from database: $e');
    }
  }

  /// Build relationships between categories, groups, and items
  void _buildMediaRelationships(
    List<MediaCategory> categories,
    List<MediaGroup> groups,
    List<MediaItem> items,
  ) {
    // Associate items with groups
    for (MediaItem item in items) {
      for (MediaGroup group in groups) {
        if (group.items == null) group.items = [];
        if (group.alias == item.groupAlias) {
          group.items!.add(item);
          break;
        }
      }
    }

    // Associate groups with categories
    for (MediaGroup group in groups) {
      for (MediaCategory category in categories) {
        if (category.groups == null) category.groups = [];
        if (group.categoryAlias == category.alias) {
          category.groups!.add(group);
          group.items?.shuffle();
          break;
        }
      }
    }

    // Sort groups by ordering
    for (MediaCategory category in categories) {
      category.groups?.sort((a, b) => (a.ordering ?? 0) - (b.ordering ?? 0));
    }
  }

  /// Get favorite items with proper error handling
  Future<List<MediaItem>> getFavorites() async {
    try {
      final db = await database;

      final List<Map<String, dynamic>> res = await db.query(
        DatabaseConstants.itemsTable,
        where: 'isFavorite = ?',
        whereArgs: [1],
      );

      List<MediaItem> list = res.isNotEmpty ? res.map((c) => MediaItem.fromDBMap(c)).toList() : [];

      return list.map((e) {
        e.isFavorite = true;
        return e;
      }).toList();
    } catch (e) {
      throw DatabaseException('Failed to get favorites: $e');
    }
  }


  /// Insert single item with error handling
  Future<int> insertItem(MediaItem item) async {
    try {
      final db = await database;

      return await db.insert(
        DatabaseConstants.itemsTable,
        item.toDBMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw DatabaseException('Failed to insert item: $e');
    }
  }

  /// Insert multiple items with batch operation for better performance
  Future<void> insertAllItems(List<MediaItem> items) async {
    if (items.isEmpty) return;

    try {
      final db = await database;

      await db.transaction((txn) async {
        await _insertAllItemsInTransaction(txn, items);
      });
    } catch (e) {
      throw DatabaseException('Failed to insert all items: $e');
    }
  }

  /// Add item to favorites
  Future<int> addFavorite(String alias) async {
    try {
      final db = await database;

      return await db.update(
        DatabaseConstants.itemsTable,
        {'isFavorite': 1},
        where: 'alias = ?',
        whereArgs: [alias],
      );
    } catch (e) {
      throw DatabaseException('Failed to add favorite: $e');
    }
  }

  /// Remove item from favorites (fixed method name and implementation)
  Future<int> unFavorite(String alias) async {
    try {
      final db = await database;

      return await db.update(
        DatabaseConstants.itemsTable,
        {'isFavorite': 0},
        where: 'alias = ?',
        whereArgs: [alias],
      );
    } catch (e) {
      throw DatabaseException('Failed to remove favorite: $e');
    }
  }


  /// Update item with error handling
  Future<int> updateItem(MediaItem item) async {
    try {
      final db = await database;

      return await db.update(
        DatabaseConstants.itemsTable,
        item.toDBMap(),
        where: 'alias = ?',
        whereArgs: [item.alias],
      );
    } catch (e) {
      throw DatabaseException('Failed to update item: $e');
    }
  }

  /// Delete item by alias
  Future<int> deleteItem(String alias) async {
    try {
      final db = await database;

      return await db.delete(
        DatabaseConstants.itemsTable,
        where: 'alias = ?',
        whereArgs: [alias],
      );
    } catch (e) {
      throw DatabaseException('Failed to delete item: $e');
    }
  }

  /// Search items by keywords
  Future<List<MediaItem>> searchItems(String query) async {
    try {
      final db = await database;

      final results = await db.query(
        DatabaseConstants.itemsTable,
        where: 'name LIKE ? OR keywords LIKE ? OR relatedKeywords LIKE ?',
        whereArgs: ['%$query%', '%$query%', '%$query%'],
        orderBy: 'ordering ASC',
      );

      return results.isNotEmpty ? results.map((c) => MediaItem.fromDBMap(c)).toList() : [];
    } catch (e) {
      throw DatabaseException('Failed to search items: $e');
    }
  }

  /// Get database statistics
  Future<Map<String, int>> getDatabaseStats() async {
    try {
      final db = await database;

      final categoriesCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM ${DatabaseConstants.categoriesTable}')) ?? 0;

      final groupsCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM ${DatabaseConstants.groupsTable}')) ?? 0;

      final itemsCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM ${DatabaseConstants.itemsTable}')) ?? 0;

      final favoritesCount =
          Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM ${DatabaseConstants.itemsTable} WHERE isFavorite = 1')) ?? 0;

      return {
        'categories': categoriesCount,
        'groups': groupsCount,
        'items': itemsCount,
        'favorites': favoritesCount,
      };
    } catch (e) {
      throw DatabaseException('Failed to get database stats: $e');
    }
  }

  /// Clear all data
  Future<void> clearAllData() async {
    try {
      final db = await database;

      await db.transaction((txn) async {
        await txn.delete(DatabaseConstants.itemsTable);
        await txn.delete(DatabaseConstants.groupsTable);
        await txn.delete(DatabaseConstants.categoriesTable);
      });
    } catch (e) {
      throw DatabaseException('Failed to clear all data: $e');
    }
  }

  /// Close database connection
  Future<void> closeDatabase() async {
    try {
      if (_database != null && _database!.isOpen) {
        await _database!.close();
        _database = null;
      }
    } catch (e) {
      throw DatabaseException('Failed to close database: $e');
    }
  }

  /// Check if database is initialized
  bool get isInitialized => _database != null && _database!.isOpen;

  /// Test database connection and initialization
  Future<bool> testConnection() async {
    try {
      final db = await database;
      
      // Try a simple query to test the connection
      await db.rawQuery('SELECT 1');
      
      if (kDebugMode) print('DatabaseProvider: Connection test successful');
      return true;
    } catch (e) {
      if (kDebugMode) print('DatabaseProvider: Connection test failed: $e');
      return false;
    }
  }
}
 