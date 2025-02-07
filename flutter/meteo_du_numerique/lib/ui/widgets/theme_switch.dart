import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meteo_du_numerique/ui/widgets/settings_bottom_sheet.dart';

import '../../bloc/theme_bloc/theme_bloc.dart';
import '../../bloc/theme_bloc/theme_state.dart';

class ThemeSwitch extends StatelessWidget {
  const ThemeSwitch({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, state) {
        return Row(
          children: [
            IconButton(
              onPressed: () => _showThemeChooser(context),
              icon: const Icon(Icons.tune),
            ),
          ],
        );
      },
    );
  }

  void _showThemeChooser(BuildContext context) {
    FocusScope.of(context).unfocus();

    showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.only(top: 25),
                child: Text(
                  "Préférences",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 25.0, vertical: 5),
                child: Divider(),
              ),
              Padding(
                padding: EdgeInsets.only(top: 10.0, bottom: 50),
                child: SettingsBottomSheet(),
              ),
            ],
          );
        });
  }
}
