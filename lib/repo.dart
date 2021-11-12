import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:ipfoam_client/note.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ipfoam_client/utils.dart';

class Repo with ChangeNotifier {
  static Map<String, CidWrap> cids = {};
  static Map<String, IidWrap> iids = {};

  Repo();

  void addNoteForCid(String cid, Note? note) {
    log("addNoteForCid");
    if (Utils.cidIsValid(cid) == false) {
      throw ("Empty cid can't arrive here");
    }
    cids[cid] ??= CidWrap(cid);
    cids[cid]?.note = note;
    if (note == null)
      cids[cid]?.status = RequestStatus.missing;
    else
      cids[cid]?.status = RequestStatus.loaded;
    log("Server. CID:" + cid + " Status: " + cids[cid]!.status.toString());
    notifyListeners();
  }

  void addCidForIid(String iid, String cid) {
    iids[iid] ??= IidWrap(iid);
    iids[iid]?.cid = cid;

    if (Utils.cidIsValid(cid) == false) {
      iids[iid]?.status = RequestStatus.missing;
    } else {
      iids[iid]?.status = RequestStatus.loaded;
    }

    log("Added iid " +
        iid +
        "CID: " +
        cid +
        " Status: " +
        iids[iid]!.status.toString());
  }

  CidWrap getNoteWrapByCid(String cid) {
    if (Utils.cidIsValid(cid) == false) {
      return CidWrap.invalid(cid);
    }

    cids[cid] ??= CidWrap(cid);
    log("Transform. CID:" + cid + " Status: " + cids[cid]!.status.toString());
    if (cids[cid]!.status == RequestStatus.undefined) {
      cids[cid]!.status = RequestStatus.needed;
    }

    return cids[cid]!;
  }

  IidWrap getCidWrapByIid(String iid) {
    if (Utils.cidIsValid(iid) == false) {
      return IidWrap.invalid(iid);
    }

    iids[iid] ??= IidWrap(iid);

    log("Transform start. IID: " +
        iid +
        " Status: " +
        iids[iid]!.status.toString());
    if (iids[iid]!.status == RequestStatus.undefined) {
      iids[iid]!.status = RequestStatus.needed;
    }

    log("Transform end. IID: " +
        iid +
        " Status: " +
        iids[iid]!.status.toString());
    // TODO this does not belong here
    if (iids[iid]!.status == RequestStatus.needed) fetchIIds();

    return iids[iid]!;
  }

  Future<void> fetchIIds() async {
    List<String> iidsToLoad = [];

    Repo.iids.forEach((iid, entry) {
      if (entry.status == RequestStatus.needed) {
        iidsToLoad.add(iid);
        entry.lastRequest = DateTime.now();
        entry.status = RequestStatus.requested;
      }
    });
    log("Server requesting " + iidsToLoad.toString());

    if (iidsToLoad.isEmpty) {
      log("Nothing to fetch");
      return;
    }
    var iidsEndPoint = "https://ipfoam-server-dc89h.ondigitalocean.app/iids/" +
        iidsToLoad.join(",");
    var result = await http.get(Uri.parse(iidsEndPoint));
    Map<String, dynamic> body = json.decode(result.body);
    log(body.toString());
    Map<String, dynamic> cids = body["data"]["cids"];
    Map<String, dynamic> blocks = body["data"]["blocks"];
    cids.forEach((iid, cid) {
      addCidForIid(iid, cid);
      if (Utils.cidIsValid(cid)) {
        if (Utils.blockIsValid(blocks[cid])) {
          Map<String, dynamic> block = blocks[cid];
          Note note = Note(cid: cid, block: block);
          addNoteForCid(cid, note);

          //List<String> dependencies = [];
          // dependencies.addAll(Utils.getIddTypesForBlock(block));
        }
      }
    });
  }
}

//undefined: default state. Is only in this state if no action has been done
//needed: A Transform manifested it wants it. But no attempt of getting it  has been done
//requested: It has been requested to an outside source but have not response yet
//missing: The outside source has returned an emptty request , regardless of the reason. Should not expect the source to have it under the same conditions
//loaded: Its loaded and stred in Repo
//failed: The request failed (ex: connectivity issues).
//invalid: The item requested or the content returned is invalid
enum RequestStatus {
  undefined,
  needed,
  requested,
  missing,
  loaded,
  failed,
  invalid
}

class CidWrap {
  DateTime? lastRequest;
  RequestStatus status = RequestStatus.undefined;
  String cid;
  Note? note;

  CidWrap(this.cid);
  CidWrap.invalid(this.cid) {
    status = RequestStatus.invalid;
  }
}

class IidWrap {
  DateTime? lastRequest;
  RequestStatus status = RequestStatus.undefined;
  String iid;
  String? cid;

  IidWrap(this.iid);
  IidWrap.invalid(this.iid) {
    status = RequestStatus.invalid;
  }
}
