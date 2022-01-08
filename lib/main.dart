import 'dart:io';
import 'package:flutter/material.dart';
import 'package:ipfoam_client/bridge.dart';
import 'dart:developer';
import 'package:ipfoam_client/repo.dart';
import 'package:ipfoam_client/transforms/colum_navigator.dart';
import 'package:ipfoam_client/transforms/root_transform_wrapper.dart';
import 'package:ipfoam_client/transforms/square.dart';
import 'package:provider/provider.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

void main() {
  HttpOverrides.global = MyHttpOverrides();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var repo = Repo();
    var navigation = Navigation();
    var bridge = Bridge();
    var square = Square(context, repo, navigation, bridge);

    var page = ChangeNotifierProvider.value(
        value: repo,
        child: Scaffold(
            body: ChangeNotifierProvider.value(
                value: navigation, child: RootTransformWrapper())));

    return MaterialApp(
      title: ' Interplanetary mind map',
      theme: ThemeData(
        fontFamily: 'OpenSans',
        canvasColor: Colors.white,
      ),
      home: page,
      onGenerateRoute: (settings) {
        if (settings.name != null) {
          final settingsUri = Uri.parse(settings.name!);
          square.processRoute(settingsUri);
          print(Uri.base);
          print(Uri.base.queryParameters);
          return PageRouteBuilder(
              pageBuilder: (_, __, ___) => page, settings: settings);
        }
      },
    );
  }
}


typedef NoteRequester = Function(List<String>);

class AbstractionReference {
  String? mid;
  String? iid;
  String? liid;
  String? tiid; //TypeIId (property)
  List<String>? path;
  String? cid;
  late String origin; // "mid:iid" or "cid"
  static String pathToken = "/";

  //An abstraction reference has the signature "mid:iid/tiid/path/" or "cid/tiid/path" or cid/path

  AbstractionReference.fromText(String text) {
    var t = text.split(AbstractionReference.pathToken);
    origin = t[0]; // "iid" or "cid"
    const midLength = 46;
    const liidLength=8;

    //if there is no token we can assume is a CID. Except whie mids are not implemented
    if (origin.length <= midLength) {
      cid = origin;
    } else if (origin.length == midLength+liidLength) {
      mid = origin.substring(0, midLength);
      liid = origin.substring(midLength, origin.length);
      iid = origin;
    } else {
      log("Error parssing expression:" + text);
    }

    if (t.length > 1) {
      var propertiesRuns = t..removeAt(0);
      tiid = propertiesRuns[0];
      if (propertiesRuns.length > 1) {
        path = propertiesRuns..remove(0);
      }
    }
    //print("mid:$mid iid:$iid tiid:$tiid path:$path");
  }

  bool isIid() {
    return iid != null;
  }

  bool isCid() {
    return cid != null;
  }
}
