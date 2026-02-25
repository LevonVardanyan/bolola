import 'dart:convert';


import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../resources/models/media_category.dart';
import '../resources/models/media_group.dart';
import '../resources/models/media_item.dart';

//
class UploadDevWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.red,
        body: Center(
          child: SizedBox(
            width: 100,
            height: 100,
            child: InkWell(
              onTap: () async {},
              child: Container(
                color: Colors.grey,
                child: Center(
                  child: Text("start"),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<MediaGroup> readJson() async {
    final String response = await rootBundle.loadString('assets/output.json');
    final data = await json.decode(response);
    MediaGroup group = MediaGroup.dataFromMap(data);
    group.items = MediaGroup.itemsFromMap(data).items;
    group.count = group.items?.length ?? 0;
    return group;
  }

  Future<List<MediaCategory>> readAllCategoriesJson() async {
    final String response = await rootBundle.loadString('assets/categories.json');
    List<dynamic> categoriesData = await json.decode(response);

    Map<String, MediaCategory> categories = {};
    for (Map data in categoriesData) {
      MediaCategory category = MediaCategory(groups: [], name: data["name"], alias: data["alias"]);
      var groupsData = data["groups"];
      for (var k = 0; k < groupsData.length; k++) {
        MediaGroup group = MediaGroup.dataFromMap(groupsData[k]);
        var groupsItemsData = groupsData[k]["items"];
        for (var j = 0; j < groupsItemsData.length; j++) {
          MediaItem item = MediaItem.fromMap(groupsItemsData[j]);
          group.items?.add(item);
        }
        category.groups?.add(group);
      }
      categories[category.alias!] = category;
    }
    return [];
  }
}

// var karginTv = ["kargin_multer", "kargin_haghordum_1", "kargin_haghordum_2", "kargin_haghordum_3"];

var movies = [
  "mer_bak_1",
  "korats_molorvats",
  "hreshneri_gayl",
  "mer_bak_2",
];

var shows = [
  "kargin_haghordum",
  "kargin_multer",
  "kargin_haghordum_2",
  "vozniner",
  "kisabac_lusamutner",
  "stepan_partamyan",
  "tigran_karapetich",
  "mixed_shows"
];

var political = [
  "tigran_arzakantsyan",
  "gagik_tsarukyan",
  "serj_sargsyan",
  "galust_sahakyan",
  "nikol_pashinyan",
  "samvel_aleksanyan",
  "hovik_aghazaryan",
  "naira_zohrabyan",
  "manvel_grigoryan",
  "mixed_political",
  "seyran_saroyan",
  "vardan_ghukasyan_qaxaqapet",
  "vova_gasparyan",
  "gevorg_petrosyan",
  "araqel_movsisyan",
  "edmon_maruqyan",
  "robert_qocharyan",
  "ararat_mirzoyan",
  "karen_karapetyan",
  "armen_ashotyan",
  "eduard_sharmazanov",
  "tigran_sargsyan"
];

var people = [
  "cirki_tnoren",
  "90_akanner",
  "barev_vahag",
  "hhk_tati",
  "mixed_people",
];
