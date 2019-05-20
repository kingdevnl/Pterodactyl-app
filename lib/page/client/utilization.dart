import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:flutter_sparkline/flutter_sparkline.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../globals.dart' as globals;
import '../auth/shared_preferences_helper.dart';

import 'dart:async';
import 'dart:convert';
import 'actionserver.dart';
import '../../main.dart';

class StatePage extends StatefulWidget {
  StatePage({Key key, this.server}) : super(key: key);
  final Stats server;

  @override
  _StatePageState createState() => _StatePageState();
}

class _StatePageState extends State<StatePage> {
  Map data;
  String _stats;
  int _memorycurrent;
  int _memorylimit;
  List<double> _cpu = [0.0].toList();
  int _diskcurrent;
  int _disklimit;
  Timer timer;

  Future getData() async {
    String _api = await SharedPreferencesHelper.getString("apiKey");
    String _url = await SharedPreferencesHelper.getString("panelUrl");
    String _https = await SharedPreferencesHelper.getString("https");

    http.Response response = await http.get(
      "$_https$_url/api/client/servers/${widget.server.id}/utilization",
      headers: {
        "Accept": "Application/vnd.pterodactyl.v1+json",
        "Content-Type": "application/json",
        "Authorization": "Bearer $_api"
      },
    );

    List<double> parseCpu(cpu) {
      List<double> result = [];
      cpu.forEach((f) => result.add(f.toDouble()));
      return result;
    }

    data = json.decode(response.body);

    setState(() {
      _stats = data["attributes"]["state"];
      _memorycurrent = data["attributes"]["memory"]["current"];
      _memorylimit = data["attributes"]["memory"]["limit"];
      _cpu = parseCpu(data["attributes"]["cpu"]["cores"]);
      _diskcurrent = data["attributes"]["disk"]["current"];
      _disklimit = data["attributes"]["disk"]["limit"];
    });
  }

  @override
  void initState() {
    getData();
    super.initState();
    timer = Timer.periodic(Duration(seconds: 5), (Timer t) => getData());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          elevation: 0.0,
          backgroundColor: globals.isDarkTheme ? null : Colors.transparent,
          leading: IconButton(
            color: globals.isDarkTheme ? Colors.white : Colors.black,
            onPressed: () {
              Navigator.of(context).pop();
              timer.cancel();
            }, 
            icon: Icon(
              Icons.arrow_back,
              color: globals.isDarkTheme ? Colors.white : Colors.black,
            ),
          ),
          title: Text(DemoLocalizations.of(context).trans('utilization_stats'),
              style: TextStyle(fontWeight: FontWeight.w700)),
        ),
        body: StaggeredGridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12.0,
          mainAxisSpacing: 12.0,
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          children: <Widget>[
            _buildTile(
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text("Stats:",
                              style: TextStyle(color: Colors.blueAccent)),
                          Text(
                              "$_stats" == "on"
                                  ? DemoLocalizations.of(context)
                                      .trans('utilization_stats_online')
                                  : DemoLocalizations.of(context)
                                      .trans('utilization_stats_offline'),
                              style: TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 20.0))
                        ],
                      ),
                      Material(
                          color: "$_stats" == "on" ? Colors.green : Colors.red,
                          shape: CircleBorder(),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Icon(
                                "$_stats" == "on"
                                    ? Icons.play_arrow
                                    : Icons.stop,
                                color: Colors.white,
                                size: 30.0),
                          )),
                    ]),
              ),
              //onTap: () {},
            ),
            _buildTile(
              Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                  DemoLocalizations.of(context)
                                      .trans('utilization_performance_cpu'),
                                  style: TextStyle(color: Colors.redAccent)),
                              Text(
                                  DemoLocalizations.of(context)
                                      .trans('utilization_cpu'),
                                  style: TextStyle(
                                      color: globals.isDarkTheme
                                          ? Colors.white
                                          : Colors.black,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 20.0)),
                            ],
                          ),
                        ],
                      ),
                      Padding(padding: EdgeInsets.only(bottom: 4.0)),
                      Sparkline(
                        data: _cpu.isNotEmpty ? _cpu : [0.0],
                        lineWidth: 5.0,
                        lineColor: Colors.greenAccent,
                      )
                    ],
                  )),
            ),
            _buildTile(
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                              DemoLocalizations.of(context)
                                  .trans('utilization_memory'),
                              style: TextStyle(color: Colors.blueAccent)),
                          Text(
                              "$_memorycurrent" == null
                                  ? DemoLocalizations.of(context)
                                      .trans('utilization_stats_offline')
                                  : "$_memorycurrent MB / $_memorylimit MB",
                              style: TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 20.0))
                        ],
                      ),
                      Material(
                          color: "$_memorycurrent" == "$_memorylimit"
                              ? Colors.red
                              : Colors.green,
                          shape: CircleBorder(),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Icon(Icons.memory,
                                color: Colors.white, size: 30.0),
                          )),
                    ]),
              ),
              //onTap: () {},
            ),
            _buildTile(
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                              DemoLocalizations.of(context)
                                  .trans('utilization_disk'),
                              style: TextStyle(color: Colors.blueAccent)),
                          Text(
                              "$_diskcurrent" == null
                                  ? DemoLocalizations.of(context)
                                      .trans('utilization_stats_offline')
                                  : "$_diskcurrent MB / $_disklimit MB",
                              style: TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 20.0))
                        ],
                      ),
                      Material(
                          color: "$_diskcurrent" == "$_disklimit"
                              ? Colors.red
                              : Colors.green,
                          shape: CircleBorder(),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Icon(Icons.sd_storage,
                                color: Colors.white, size: 30.0),
                          )),
                    ]),
              ),
              //onTap: () {},
            ),
          ],
          staggeredTiles: [
            StaggeredTile.extent(2, 110.0),
            StaggeredTile.extent(2, 220.0),
            StaggeredTile.extent(2, 110.0),
            StaggeredTile.extent(2, 110.0),
          ],
        ));
  }

  Widget _buildTile(Widget child, {Function() onTap}) {
    return Material(
        elevation: 14.0,
        borderRadius: BorderRadius.circular(12.0),
        shadowColor: globals.isDarkTheme ? Colors.grey[700] : Color(0x802196F3),
        child: InkWell(
            // Do onTap() if it isn't null, otherwise do print()
            onTap: onTap != null
                ? () => onTap()
                : () {
                    print('Not set yet');
                  },
            child: child));
  }
}
