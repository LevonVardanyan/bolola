// import 'package:flutter/foundation.dart';
// import 'package:path/path.dart';
// import 'package:sqflite/sqflite.dart';
// import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart' show databaseFactoryFfiWeb;
//
// import '../models/media_category.dart';
// import '../models/media_group.dart';
// import '../models/media_item.dart';
// import '../models/medias.dart';
//
// class DatabaseProvider {
//   static Database? _database;
//
//   DatabaseProvider._();
//
//   static final DatabaseProvider db = DatabaseProvider._();
//
//   Future<Database> get database async {
//     if (_database != null) return _database!;
//
//     // if _database is null we instantiate it
//     _database = await initDB();
//     return _database!;
//   }
//
//   int dbVersion = 1;
//
//   initDB() async {
//     if (kIsWeb) databaseFactory = databaseFactoryFfiWeb;
//     String databasesPath = await getDatabasesPath();
//     String path = join(databasesPath, 'Bolola2.db');
// //    String path = '${documentsDirectory.path}/FamousStatements.db';
//
//     return await openDatabase(path, version: dbVersion, onOpen: (db) {}, onCreate: (Database db, int version) async {
//       await createItemsTable(db);
//       await createGroupsTable(db);
//       await createCategoriesTable(db);
//     }, onUpgrade: (db, oldVersion, newVersion) {});
//   }
//
//   Future<void> createItemsTable(Database db) async {
//     return db.execute("CREATE TABLE items_table("
//         "alias TEXT PRIMARY KEY,"
//         "shareCount INTEGER,"
//         "name TEXT,"
//         "groupAlias TEXT,"
//         "categoryAlias TEXT,"
//         "ordering INTEGER,"
//         "audioUrl TEXT,"
//         "videoUrl TEXT,"
//         "sourceUrl TEXT,"
//         "mimeType TEXT,"
//         "isFavorite INTEGER,"
//         "keywords TEXT,"
//         "relatedKeywords TEXT"
//         ")");
//   }
//
//   Future<void> createGroupsTable(Database db) async {
//     return db.execute("CREATE TABLE groups_table("
//         "alias TEXT PRIMARY KEY,"
//         "name TEXT,"
//         "iconUrl TEXT,"
//         "categoryAlias TEXT,"
//         "count INTEGER,"
//         "ordering INTEGER,"
//         "isNew INTEGER,"
//         "sortingTypes TEXT"
//         ")");
//   }
//
//   Future<void> createCategoriesTable(Database db) async {
//     return db.execute("CREATE TABLE categories_table("
//         "alias TEXT PRIMARY KEY,"
//         "name TEXT,"
//         "groups TEXT,"
//         "ordering INTEGER"
//         ")");
//   }
//
//   //
//   // Future<void> insertAllCategories(Medias medias) async {
//   //   final db = await database;
//   //   await db.delete("categories_table");
//   //   for (MediaCategory category in medias.categories!) {
//   //     await db.insert("categories_table", category.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
//   //   }
//   //   return;
//   // }
//
//   Future<void> insertAllMedias(Medias medias) async {
//     final db = await database;
//     await db.delete("categories_table");
//     await db.delete("groups_table");
//     for (MediaCategory category in medias.categories!) {
//       await db.insert("categories_table", category.toDBMap(), conflictAlgorithm: ConflictAlgorithm.replace);
//       for (MediaGroup group in category.groups!) {
//         await db.insert("groups_table", group.dataToDBMap(), conflictAlgorithm: ConflictAlgorithm.replace);
//         if (group.items?.isNotEmpty == true) await insertAllItems(group.items!);
//       }
//     }
//     return;
//   }
//
//   Future<Medias> getMediasFromDB() async {
//     final db = await database;
//     var categoriesRes = await db.rawQuery("SELECT * FROM categories_table ORDER BY ordering ASC");
//     List<MediaCategory> categories = categoriesRes.isNotEmpty ? categoriesRes.map((c) => MediaCategory.fromDBMap(c)).toList() : [];
//     if (categories.isEmpty) return Medias(categories: []);
//     Medias medias = Medias(categories: categories);
//     var groupsRes = await db.rawQuery("SELECT * FROM groups_table");
//     List<MediaGroup> groups = groupsRes.isNotEmpty ? groupsRes.map((c) => MediaGroup.dataFromDBMap(c)).toList() : [];
//     var itemsRes = await db.rawQuery("SELECT * FROM items_table ");
//     List<MediaItem> items = itemsRes.isNotEmpty ? itemsRes.map((c) => MediaItem.fromDBMap(c)).toList() : [];
//     for (MediaItem item in items) {
//       for (MediaGroup group in groups) {
//         if (group.items == null) group.items = [];
//         if (group.alias == item.groupAlias) {
//           group.items?.add(item);
//           break;
//         }
//       }
//     }
//     for (MediaGroup group in groups) {
//       for (MediaCategory category in categories) {
//         if (category.groups == null) category.groups = [];
//         if (group.categoryAlias == category.alias) {
//           category.groups?.add(group);
//           group.items?.shuffle();
//           break;
//         }
//       }
//     }
//     for (MediaCategory category in categories) {
//       category.groups?.sort((a, b) => a.ordering! - b.ordering!);
//     }
//     return medias;
//   }
//
//
//   Future<List<MediaItem>> getFavorites() async {
//     final db = await database;
//     final List<Map<String, dynamic>> res = await db.rawQuery("SELECT * FROM items_table WHERE isFavorite=1");
//     List<MediaItem> list = res.isNotEmpty ? res.map((c) => MediaItem.fromDBMap(c)).toList() : [];
//     return list.map((e) {
//       e.isFavorite = true;
//       return e;
//     }).toList();
//   }
//
//   Future<int> insertItem(MediaItem item) async {
//     final db = await database;
//
//     return db.insert("items_table", item.toDBMap(), conflictAlgorithm: ConflictAlgorithm.replace);
//   }
//
//   Future<void> insertAllItems(List<MediaItem> items) async {
//     if (items.isNotEmpty) {
//       var db = await database;
//
//       for (MediaItem item in items) {
//         await db.insert("items_table", item.toDBMap(), conflictAlgorithm: ConflictAlgorithm.replace);
//       }
//     }
//   }
//
// }
