import 'package:flutter/material.dart';
import 'package:status_air/features/home/presentation/widgets/home_show_index.dart';
import '../../../../common/widgets/app_appbar.dart';
import '../../../../common/widgets/app_drawer.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

    return Scaffold(
      key: scaffoldKey,
      appBar: AppAppBar(
        title: "Air Quality",
        scaffoldKey: scaffoldKey,
        onNotificationsTap: () {
        },
        onProfileTap: () {
        },
      ),
      drawer: const AppDrawer(),
      body: const HomeContent(),
    );
  }
}
