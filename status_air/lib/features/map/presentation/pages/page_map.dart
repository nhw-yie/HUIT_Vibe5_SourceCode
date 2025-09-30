import 'package:flutter/material.dart';
import 'package:status_air/features/map/presentation/widgets/show_map.dart';
import '../../../../common/widgets/app_appbar.dart';
import '../../../../common/widgets/app_drawer.dart';

class HomeMap extends StatelessWidget {
  const HomeMap({super.key});

  @override
  Widget build(BuildContext context) {
    final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

    return Scaffold(
      key: scaffoldKey,
      appBar: AppAppBar(
        title: "Air Quality",
        scaffoldKey: scaffoldKey,
        onNotificationsTap: () {},
        onProfileTap: () {},
      ),
      drawer: const AppDrawer(),
      // Thay HomeContent bằng PollutionMapPage
      body: const PollutionMapPage(),
    );
  }
}
