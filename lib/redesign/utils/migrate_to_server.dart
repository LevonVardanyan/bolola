import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:politicsstatements/redesign/bloc/appBloc.dart';

import '../resources/repository.dart';
import '../resources/sourceData.dart';

//
class MigrateServerWidget extends StatefulWidget {
  @override
  State<MigrateServerWidget> createState() => _MigrateServerWidgetState();
}

class _MigrateServerWidgetState extends State<MigrateServerWidget> {
  AppBloc appBloc = AppBloc();

  @override
  void initState() {
    super.initState();
    initRepo();
    appBloc.fetchSources();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.blue,
        body: Center(
          child: SizedBox(
            width: 100,
            height: 100,
            child: InkWell(
              onTap: () async {
              },
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
