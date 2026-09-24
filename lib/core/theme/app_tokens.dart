import 'package:flutter/material.dart';

import 'app_palette.dart';

@immutable
class AppColorSet {
  const AppColorSet({
    required this.ink,
    required this.inkMuted,
    required this.outline,
    required this.outlineStrong,
    required this.canvas,
    required this.surface,
    required this.surfaceMuted,
    required this.surfaceGlass,
    required this.surfaceGlassStrong,
    required this.primary,
    required this.primaryStrong,
    required this.primarySoft,
    required this.admin,
    required this.adminSoft,
    required this.member,
    required this.memberSoft,
    required this.warning,
    required this.warningSoft,
    required this.error,
    required this.errorSoft,
    required this.success,
    required this.successSoft,
    required this.info,
    required this.infoSoft,
    required this.glowPrimary,
    required this.glowSecondary,
    required this.glowMint,
    required this.navSurface,
    required this.navStroke,
    required this.navShadow,
    required this.pageGradient,
    required this.guestHeroGradient,
    required this.adminHeroGradient,
    required this.memberHeroGradient,
  });

  final Color ink;
  final Color inkMuted;
  final Color outline;
  final Color outlineStrong;
  final Color canvas;
  final Color surface;
  final Color surfaceMuted;
  final Color surfaceGlass;
  final Color surfaceGlassStrong;
  final Color primary;
  final Color primaryStrong;
  final Color primarySoft;
  final Color admin;
  final Color adminSoft;
  final Color member;
  final Color memberSoft;
  final Color warning;
  final Color warningSoft;
  final Color error;
  final Color errorSoft;
  final Color success;
  final Color successSoft;
  final Color info;
  final Color infoSoft;
  final Color glowPrimary;
  final Color glowSecondary;
  final Color glowMint;
  final Color navSurface;
  final Color navStroke;
  final Color navShadow;
  final List<Color> pageGradient;
  final List<Color> guestHeroGradient;
  final List<Color> adminHeroGradient;
  final List<Color> memberHeroGradient;
}

final class AppColorSets {
  const AppColorSets._();

  static const AppColorSet light = AppColorSet(
    ink: AppPalette.slateInk,
    inkMuted: AppPalette.slateMuted,
    outline: AppPalette.silverMist,
    outlineStrong: Color(0xFFBACDE3),
    canvas: AppPalette.polarWhite,
    surface: AppPalette.crystalWhite,
    surfaceMuted: Color(0xFFF3F8FD),
    surfaceGlass: Color(0xE6FFFFFF),
    surfaceGlassStrong: Color(0xF5FFFFFF),
    primary: AppPalette.blueGreen,
    primaryStrong: AppPalette.frenchBlue,
    primarySoft: Color(0xFFDFF7FD),
    admin: AppPalette.frenchBlue,
    adminSoft: Color(0xFFE4F0FF),
    member: AppPalette.turquoiseSurf,
    memberSoft: Color(0xFFE3FAFF),
    warning: AppPalette.solarAmber,
    warningSoft: Color(0xFFFFF4D9),
    error: AppPalette.emberCoral,
    errorSoft: Color(0xFFFFE8E8),
    success: AppPalette.neonLeaf,
    successSoft: Color(0xFFE7FBF1),
    info: AppPalette.brightTealBlue,
    infoSoft: Color(0xFFE5F4FF),
    glowPrimary: Color(0x3324C8FF),
    glowSecondary: Color(0x2610A0FF),
    glowMint: Color(0x2283F1D8),
    navSurface: Color(0xEEFFFFFF),
    navStroke: Color(0xB8D9EAF8),
    navShadow: Color(0x16013C8A),
    pageGradient: AppPalette.shellAtmosphere,
    guestHeroGradient: AppPalette.guestHero,
    adminHeroGradient: AppPalette.adminHero,
    memberHeroGradient: AppPalette.memberHero,
  );

  static const AppColorSet dark = AppColorSet(
    ink: AppPalette.crystalWhite,
    inkMuted: AppPalette.moonMist,
    outline: AppPalette.midnightOutline,
    outlineStrong: AppPalette.midnightOutlineStrong,
    canvas: AppPalette.midnightCanvas,
    surface: AppPalette.midnightSurface,
    surfaceMuted: AppPalette.midnightSurfaceRaised,
    surfaceGlass: Color(0xD90F1D2D),
    surfaceGlassStrong: Color(0xF515273B),
    primary: AppPalette.turquoiseSurf,
    primaryStrong: AppPalette.skyAqua,
    primarySoft: Color(0xFF123A4A),
    admin: AppPalette.skyAqua,
    adminSoft: Color(0xFF112E4A),
    member: AppPalette.auroraMint,
    memberSoft: Color(0xFF10362F),
    warning: AppPalette.solarAmber,
    warningSoft: Color(0xFF47340D),
    error: AppPalette.emberCoral,
    errorSoft: Color(0xFF4A252A),
    success: AppPalette.neonLeaf,
    successSoft: Color(0xFF163728),
    info: AppPalette.skyAqua,
    infoSoft: Color(0xFF13354C),
    glowPrimary: Color(0x3048CAE4),
    glowSecondary: Color(0x26023E8A),
    glowMint: Color(0x2283F1D8),
    navSurface: Color(0xEE112233),
    navStroke: Color(0x88385674),
    navShadow: Color(0x52000000),
    pageGradient: AppPalette.shellAtmosphereDark,
    guestHeroGradient: <Color>[
      AppPalette.deepTwilight,
      AppPalette.frenchBlue,
      AppPalette.brightTealBlue,
    ],
    adminHeroGradient: <Color>[
      AppPalette.deepTwilight,
      AppPalette.frenchBlue,
      AppPalette.brightTealBlue,
    ],
    memberHeroGradient: <Color>[
      AppPalette.frenchBlue,
      AppPalette.blueGreen,
      AppPalette.turquoiseSurf,
    ],
  );
}

final class AppColors {
  const AppColors._();

  static AppColorSet _active = AppColorSets.light;

  static AppColorSet schemeForBrightness(Brightness brightness) {
    return brightness == Brightness.dark
        ? AppColorSets.dark
        : AppColorSets.light;
  }

  static void applyBrightness(Brightness brightness) {
    _active = schemeForBrightness(brightness);
  }

  static Color get ink => _active.ink;
  static Color get inkOnLight => AppColorSets.light.ink;
  static Color get inkMuted => _active.inkMuted;
  static Color get inkMutedOnLight => AppColorSets.light.inkMuted;
  static Color get outline => _active.outline;
  static Color get outlineStrong => _active.outlineStrong;
  static Color get canvas => _active.canvas;
  static Color get surface => _active.surface;
  static Color get surfaceMuted => _active.surfaceMuted;
  static Color get surfaceGlass => _active.surfaceGlass;
  static Color get surfaceGlassStrong => _active.surfaceGlassStrong;
  static Color get primary => _active.primary;
  static Color get primaryStrong => _active.primaryStrong;
  static Color get primarySoft => _active.primarySoft;
  static Color get admin => _active.admin;
  static Color get adminSoft => _active.adminSoft;
  static Color get member => _active.member;
  static Color get memberSoft => _active.memberSoft;
  static Color get warning => _active.warning;
  static Color get warningSoft => _active.warningSoft;
  static Color get error => _active.error;
  static Color get errorSoft => _active.errorSoft;
  static Color get success => _active.success;
  static Color get successSoft => _active.successSoft;
  static Color get info => _active.info;
  static Color get infoSoft => _active.infoSoft;
  static Color get glowPrimary => _active.glowPrimary;
  static Color get glowSecondary => _active.glowSecondary;
  static Color get glowMint => _active.glowMint;
  static Color get navSurface => _active.navSurface;
  static Color get navStroke => _active.navStroke;
  static Color get navShadow => _active.navShadow;
  static List<Color> get pageGradient => _active.pageGradient;
  static List<Color> get guestHeroGradient => _active.guestHeroGradient;
  static List<Color> get adminHeroGradient => _active.adminHeroGradient;
  static List<Color> get memberHeroGradient => _active.memberHeroGradient;
}

final class AppSpacing {
  const AppSpacing._();

  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 40;
}

final class AppRadii {
  const AppRadii._();

  static const BorderRadius small = BorderRadius.all(Radius.circular(14));
  static const BorderRadius medium = BorderRadius.all(Radius.circular(20));
  static const BorderRadius large = BorderRadius.all(Radius.circular(28));
  static const BorderRadius xLarge = BorderRadius.all(Radius.circular(36));
  static const BorderRadius pill = BorderRadius.all(Radius.circular(999));
}

final class AppShadows {
  const AppShadows._();

  static List<BoxShadow> get soft => <BoxShadow>[
    BoxShadow(
      color: AppColors.navShadow.withValues(
        alpha: AppColors.canvas.computeLuminance() < 0.2 ? 0.34 : 0.1,
      ),
      blurRadius: 40,
      offset: const Offset(0, 20),
    ),
  ];

  static List<BoxShadow> get floating => <BoxShadow>[
    BoxShadow(
      color: AppColors.navShadow,
      blurRadius: 48,
      offset: const Offset(0, 22),
    ),
  ];

  static List<BoxShadow> get glow => <BoxShadow>[
    BoxShadow(
      color: AppColors.glowPrimary,
      blurRadius: 54,
      offset: const Offset(0, 0),
    ),
  ];
}
