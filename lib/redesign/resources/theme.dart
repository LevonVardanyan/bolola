import 'package:flutter/material.dart';

const PRIMARY_COLOR = 0xff294533;

const LOGIN_BG_COLOR = 0xff212121;

class AppTheme {
  static const Color primaryColor = Color(PRIMARY_COLOR);

  static const Color actionBarGrey = Color(0xc21d1d1d);
  static const Color actionBarGreyNoAlpha = Color(0xff1d1d1d);

  static const Color blue900Alpha20 = Color(0x33202945);
  static const Color blue900Alpha50 = Color(0x7f202945);

  static const Color blue900 = Color(0xff202945);
  static const Color blue400 = Color(0xff60AFBB);
  static const Color blue200 = Color(0xffA6D1D6);
  static const Color blue100 = Color(0xffD7EDEF);
  static const Color homeButtonBlue = Color(0xffDAF0F7);
  static const Color blueGreen = Color(0xff69939E);

  static const Color grey100 = Color(0xffE4E5E9);
  static const Color black = Color(0xff000000);
  static const Color grey200 = Color(0xffD2D9DB);
  static const Color white = Color(0xffffffff);
  static const Color darkBg = Color(0xff0F0F0F);
  static const Color whiteTransparent = Color(0x00ffffff);
  static const Color blackTransparent = Color(0x00000000);
  static const Color mainBgTransparent = Color(0x0024293E);
  static const Color mainBg = mainBgColor;
  static const Color popupBg = Color(0xff1E1E1E);
  static const Color popupDividerColor = Color(0xff4F4F4F);
  static const Color textFieldBorder = Color(0xff4F4F4F);
  static const Color textFieldBG = Color(0xff1A1A1A);

  // static const Color mainTextColor = white;
  static const Color textColor = white;
  static const Color iconsColor = white;
  static const Color iconsGrey = Color(0xff828282);
  static const Color subTitleGrey = Color(0xff828282);
  static const Color infoGrey = Color(0xffb2b0b0);

  static const Color actionBarColor = Color(0xff1A1D2C);
  static const Color mainBgColor = Color(0xff24293E);

  static const Color transparent = Color(0x00000000);

  // ===== Media Palette (synced from audio_mixer_web_admin) =====
  static const Color primaryDark = Color(0xFF0D0D1A);
  static const Color surfaceDark = Color(0xFF151528);
  static const Color cardDark = Color(0xFF1C1C35);
  static const Color accentCyan = Color(0xFF00D9FF);
  static const Color accentMagenta = Color(0xFFFF006E);
  static const Color accentPurple = Color(0xFF8B5CF6);
  static const Color accentGreen = Color(0xFF00F5A0);
  static const Color accentOrange = Color(0xFFFF9F1C);
  static const Color textPrimary = Color(0xFFF0F0F5);
  static const Color textSecondary2 = Color(0xFF9090A8);
  static const Color dividerDark = Color(0xFF2A2A45);

  static const Color textColorAlpha50 = Color(0x7f202945);

  static const TextStyle itemTitleStyle = TextStyle(
    color: textColor,
    fontSize: (13),
    fontStyle: FontStyle.normal,
    fontWeight: FontWeight.w400,
  );
  static const TextStyle itemSubTitleStyle = TextStyle(
    color: subTitleGrey,
    fontSize: (12),
    fontStyle: FontStyle.normal,
    fontWeight: FontWeight.w400,
  );
  static const TextStyle itemInfoMessageStyle = TextStyle(
    color: infoGrey,
    fontSize: (14),
    fontStyle: FontStyle.normal,
    fontWeight: FontWeight.w400,
  );
  static const TextStyle activeTextsStyle = TextStyle(
    color: Color(0xffF2F2F2),
    fontSize: (16),
    fontStyle: FontStyle.normal,
    fontWeight: FontWeight.w400,
  );
  static const TextStyle passiveTextsStyle = TextStyle(
    color: Color(0xff4F4F4F),
    fontSize: (16),
    fontStyle: FontStyle.normal,
    fontWeight: FontWeight.w400,
  );
  static const TextStyle tabBarUnSelectedStyle = TextStyle(
    color: Color(0xff828282),
    fontSize: (16),
    fontStyle: FontStyle.normal,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle textFieldLabelStyle = TextStyle(
    color: Color(0xff747474),
    fontSize: (12),
    fontStyle: FontStyle.normal,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle textFieldHintStyle = TextStyle(
    color: Colors.white54,
    fontSize: (12),
    fontStyle: FontStyle.normal,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle drawerTileStyle = TextStyle(
    color: Color(0xffc9c9c9),
    fontSize: (14),
    fontStyle: FontStyle.normal,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle headingLStyle =
      TextStyle(color: textColor, fontSize: (32), fontStyle: FontStyle.normal, fontWeight: FontWeight.w400, letterSpacing: -0.96, height: 1.1);
  static const TextStyle headingMStyle =
      TextStyle(color: textColor, fontSize: (24), fontStyle: FontStyle.normal, fontWeight: FontWeight.w500, letterSpacing: -0.48, height: 1.1);
  static const TextStyle popupTitleStyle =
      TextStyle(color: textColor, fontSize: (18), fontStyle: FontStyle.normal, fontWeight: FontWeight.w600, letterSpacing: -0.48, height: 1.1);
  static const TextStyle headingSStyle = TextStyle(
    color: textColor,
    fontSize: (15),
    fontStyle: FontStyle.normal,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle headingSStyleWhite = TextStyle(
    color: white,
    fontSize: (16),
    fontStyle: FontStyle.normal,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle paragraphStyle = TextStyle(
    color: textColor,
    fontSize: (16),
    fontStyle: FontStyle.normal,
    fontWeight: FontWeight.w400,
  );
  static const TextStyle bodyStyle = TextStyle(
    color: textColor,
    fontSize: (16),
    fontStyle: FontStyle.normal,
    fontWeight: FontWeight.w400,
  );
  static const TextStyle bodyStyleWhite = TextStyle(
    color: white,
    fontSize: (16),
    fontStyle: FontStyle.normal,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle strongStyle = TextStyle(
    color: textColor,
    fontSize: (16),
    fontStyle: FontStyle.normal,
    fontWeight: FontWeight.w500,
  );
  static const TextStyle groupNameStyle = TextStyle(
    color: Color(0xffBDBDBD),
    fontSize: (14),
    fontStyle: FontStyle.normal,
    fontWeight: FontWeight.w400,
  );
  static const TextStyle strongStyleBlack = TextStyle(
    color: black,
    fontSize: (16),
    fontStyle: FontStyle.normal,
    fontWeight: FontWeight.w500,
  );
  static const TextStyle strongStyle2 = TextStyle(
    color: textColor,
    fontSize: (15),
    fontStyle: FontStyle.normal,
    fontWeight: FontWeight.w500,
  );
  static const TextStyle strongStyleBold = TextStyle(
    color: textColor,
    fontSize: (17),
    fontStyle: FontStyle.normal,
    fontWeight: FontWeight.bold,
  );
  static TextStyle strongStyleBlue900Alpha20 = TextStyle(
    color: blue400.withValues(alpha: 0.4),
    fontSize: (16),
    fontStyle: FontStyle.normal,
    fontWeight: FontWeight.w500,
  );
  static const TextStyle strongStyleWhite = TextStyle(
    color: white,
    fontSize: (16),
    fontStyle: FontStyle.normal,
    fontWeight: FontWeight.w500,
  );
  static const TextStyle strongStyleWhiteAlpha50 = TextStyle(
    color: Colors.white38,
    fontSize: (16),
    fontStyle: FontStyle.normal,
    fontWeight: FontWeight.w500,
  );
  static const TextStyle strongStyleWhite18 = TextStyle(
    color: white,
    fontSize: (18.5),
    fontStyle: FontStyle.normal,
    fontWeight: FontWeight.w500,
  );
  static const TextStyle strongAlpha50Style = TextStyle(
    color: textColorAlpha50,
    fontSize: (16),
    fontStyle: FontStyle.normal,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle smallStyle = TextStyle(
    color: textColor,
    fontSize: (13),
    fontStyle: FontStyle.normal,
    fontWeight: FontWeight.w400,
  );
  static const TextStyle smallStyle2 = TextStyle(
    color: textColor,
    fontSize: (11),
    fontStyle: FontStyle.normal,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle smallStrongStyle = TextStyle(
    color: textColor,
    fontSize: (12),
    fontStyle: FontStyle.normal,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle tabularStyle = TextStyle(
    color: textColor,
    fontSize: (12),
    fontStyle: FontStyle.normal,
    fontWeight: FontWeight.w400,
  );

  static const Duration animationDuration200 = Duration(milliseconds: 200);

  // ===== Media Component Constants =====
  static const double mediaCardRadius = 12.0;
  static const double mediaIconSize = 22.0;
  static const double mediaActionButtonSize = 40.0;
  static const double mediaItemSpacing = 6.0;
  static const double mediaCardPadding = 12.0;

  // ===== Media Text Styles =====
  static const TextStyle mediaItemTitleStyle = TextStyle(
    color: textPrimary,
    fontSize: 15,
    fontWeight: FontWeight.w500,
  );
  static const TextStyle mediaItemSubtitleStyle = TextStyle(
    color: textSecondary2,
    fontSize: 13,
    fontWeight: FontWeight.w400,
  );
  static const TextStyle mediaItemDurationStyle = TextStyle(
    color: textSecondary2,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    fontFeatures: [FontFeature.tabularFigures()],
  );
  static const TextStyle mediaTabLabelStyle = TextStyle(
    color: textPrimary,
    fontSize: 15,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle mediaTabLabelInactiveStyle = TextStyle(
    color: textSecondary2,
    fontSize: 15,
    fontWeight: FontWeight.w400,
  );
  static const TextStyle mediaControlLabelStyle = TextStyle(
    color: textSecondary2,
    fontSize: 13,
    fontWeight: FontWeight.w500,
  );
}
