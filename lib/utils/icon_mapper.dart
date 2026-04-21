import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class IconMapper {
  static IconData getIcon(String name) {
    switch (name) {
      case 'food':
        return MdiIcons.food;
      case 'shopping':
        return MdiIcons.shopping;
      case 'bus':
        return MdiIcons.bus;
      case 'home-variant':
      case 'home-city':
        return MdiIcons.homeCity;
      case 'movie':
        return MdiIcons.movie;
      case 'hospital':
        return MdiIcons.hospital;
      case 'school':
        return MdiIcons.school;
      case 'heart':
        return MdiIcons.heart;
      case 'cog-outline':
        return MdiIcons.cogOutline;
      case 'plus':
        return MdiIcons.plus;
      case 'cash-multiple':
        return MdiIcons.cashMultiple;
      case 'format-list-bulleted':
        return MdiIcons.formatListBulleted;
      case 'chart-pie':
        return MdiIcons.chartPie;
      case 'account-outline':
        return MdiIcons.accountOutline;
      case 'account':
        return MdiIcons.account;
      case 'magnify':
        return MdiIcons.magnify;
      case 'chevron-down':
        return MdiIcons.chevronDown;
      case 'chevron-right':
        return MdiIcons.chevronRight;
      case 'signal':
        return MdiIcons.signal;
      case 'wifi':
        return MdiIcons.wifi;
      case 'battery':
        return MdiIcons.battery;
      case 'calendar-blank':
        return MdiIcons.calendarBlank;
      case 'pencil-outline':
        return MdiIcons.pencilOutline;
      case 'backspace-outline':
        return MdiIcons.backspaceOutline;
      case 'calendar-month-outline':
        return MdiIcons.calendarMonthOutline;
      case 'arrow-left':
        return MdiIcons.arrowLeft;
      case 'menu':
        return MdiIcons.menu;
      case 'file-export-outline':
        return MdiIcons.fileExportOutline;
      case 'cloud-sync-outline':
        return MdiIcons.cloudSyncOutline;
      case 'trash-can-outline':
        return MdiIcons.trashCanOutline;
      case 'palette-outline':
        return MdiIcons.paletteOutline;
      case 'bell-outline':
        return MdiIcons.bellOutline;
      case 'shield-lock-outline':
        return MdiIcons.shieldLockOutline;
      case 'information-outline':
        return MdiIcons.informationOutline;
      case 'star-outline':
        return MdiIcons.starOutline;
      default:
        return MdiIcons.helpCircleOutline;
    }
  }
}
