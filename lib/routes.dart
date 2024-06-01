import 'package:flutter/material.dart';
import 'home.dart';
import 'allMusic.dart';


final Map<String, Widget Function(BuildContext)> namedRoutes = {
  '/home': (context) => MusicApp(),
  '/allmusic': (context) => AllMusic(),
};