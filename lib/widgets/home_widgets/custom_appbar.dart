import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:safepath/utils/quotes.dart';

import '../../l10n/app_localizations.dart';


class CustomAppBar extends StatelessWidget {
  Function? onTap;
  int? quoteIndex;
  CustomAppBar({this.onTap, this.quoteIndex});

  @override
  Widget build(BuildContext context) {
    var localizations = AppLocalizations.of(context);
    return GestureDetector(
      onTap: () {
        onTap!();
      },
      child: Container(
        child:
        Text(localizations!.translate(sweetSayings[quoteIndex!]),
        style: TextStyle(fontSize: 22),),
      ),
    );
  }
}
