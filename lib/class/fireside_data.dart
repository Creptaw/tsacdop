import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:html/parser.dart';
import 'package:tsacdop/local_storage/sqflite_localpodcast.dart';

class FiresideData {
  final String id;
  final String link;

  String _background;
  String get background => _background;
  List<PodcastHost> _hosts;
  List<PodcastHost> get hosts => _hosts;
  FiresideData(this.id, this.link);

  DBHelper dbHelper = DBHelper();

  Future fatchData() async {
    Response response = await Dio().get(link);
    if (response.statusCode == 200) {
      var doc = parse(response.data);
      RegExp reg = RegExp(r'https(.+)jpg');
      String backgroundImage = reg.stringMatch(doc.body
          .getElementsByClassName('hero-background')
          .first
          .attributes
          .toString());
      var ul = doc.body.getElementsByClassName('episode-hosts').first.children;
      List<PodcastHost> hosts = [];
      ul.forEach((element) {
        PodcastHost host;
        String name = element.text.trim();
        String image =
            element.children.first.children.first.attributes.toString();
        host = PodcastHost(name, reg.stringMatch(image));
        hosts.add(host);
      });
      List<String> data = [
        id,
        backgroundImage,
        json.encode({'hosts': hosts.map((host) => host.toJson()).toList()})
      ];
      await dbHelper.saveFiresideData(data);
    }
  }

  Future getData() async{
    List<String> data = await dbHelper.getFiresideData(id);
    _background = data[0];
    _hosts = json
        .decode(data[1])['hosts']
        .cast<Map<String, Object>>()
        .map<PodcastHost>(PodcastHost.fromJson)
        .toList();
  }
}

class PodcastHost {
  final String image;
  final String name;
  PodcastHost(this.name, this.image);

  Map<String, Object> toJson() {
    return {'name': name, 'image': image};
  }

  static PodcastHost fromJson(Map<String, Object> json) {
    return PodcastHost(json['name'] as String, json['image'] as String);
  }
}
