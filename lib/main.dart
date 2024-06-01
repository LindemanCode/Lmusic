import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'routes.dart';
import 'home.dart';
import 'playList.dart';
import 'play.dart';
import 'package:provider/provider.dart';
import 'provider.dart';
import 'services/service_locator.dart';

main() async {
    await setupServiceLocator();

    // 禁止横屏
    await SystemChrome.setPreferredOrientations(
      [
        DeviceOrientation.portraitUp,  // 竖屏 Portrait 模式
        DeviceOrientation.portraitDown,
        // DeviceOrientation.landscapeLeft, // 横屏 Landscape 模式
        // DeviceOrientation.landscapeRight,
      ],
    );

    runApp(
      ChangeNotifierProvider(
        create: (_) => PlayState(),
        child: MaterialApp(
          home: MusicApp(),
          routes: namedRoutes,
          debugShowCheckedModeBanner: false,
          onGenerateRoute: (RouteSettings settings) {
            final data = settings.arguments as Map<String, dynamic>;
            switch (settings.name) {
              case '/playlist':
                return MaterialPageRoute(builder: (_) => MPlayList(playListName: data['playListName']));
              case '/play':
                return MaterialPageRoute(builder: (_) => PlayMusic(listName: data['playListName'], songIdx: data['songIdx']));
              default:
                return null;
            }
          },
        ),
      ),
  );
}