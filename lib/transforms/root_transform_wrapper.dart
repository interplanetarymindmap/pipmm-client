import 'dart:math';

import 'package:flutter/material.dart';
import 'package:ipfoam_client/navigation.dart';
import 'package:ipfoam_client/transforms/interplanetary_text/interplanetary_text.dart';

class RootTransformWrapper extends StatefulWidget {
  RootTransformWrapper({
    Key? key,
  }) : super(key: key);

  @override
  State<RootTransformWrapper> createState() => RootTransformWrapperState();
}

class RootTransformWrapperState extends State<RootTransformWrapper> {
  List<dynamic> expr = [];

  initState() {
    super.initState();
    Navigation.onExprChanged = onExprChanged;
  }

  onExprChanged(List<dynamic> newExpr) {
    setState(() {
      expr = newExpr;
    });
  }

/*
  onRepoUpdate(List<dynamic> newExpr) {
    setState(() {});
  }
*/
  @override
  Widget build(BuildContext context) {
    return IPTFactory.getRootTransform(
        expr, Navigation.defaultOnTap);
  }
}
