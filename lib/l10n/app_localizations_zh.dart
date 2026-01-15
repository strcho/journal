// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'DayOne';

  @override
  String get searchEntriesHint => '搜索日记';

  @override
  String get noEntriesTitle => '还没有日记';

  @override
  String get noEntriesBody => '点击 + 开始记录第一篇日记。';

  @override
  String get newEntry => '新建日记';

  @override
  String get untitled => '未命名';

  @override
  String get noContent => '暂无内容';

  @override
  String get editEntryTitle => '编辑日记';

  @override
  String get newEntryTitle => '新建日记';

  @override
  String get entryTitleLabel => '标题';

  @override
  String get entryDateLabel => '日记日期';

  @override
  String get entryDatePickerHelp => '选择日记日期';

  @override
  String entryDateTodayLabel(String date) {
    return '$date（今天）';
  }

  @override
  String get insertImage => '插入图片';

  @override
  String get moreFormatting => '更多格式';

  @override
  String get entryDetailTitle => '日记';

  @override
  String get entryNotFound => '未找到日记。';

  @override
  String get deleteEntryTitle => '删除日记？';

  @override
  String get deleteEntryMessage => '此操作会从日记中移除该条内容。';

  @override
  String get cancel => '取消';

  @override
  String get delete => '删除';

  @override
  String get settingsTitle => '设置';

  @override
  String get appLockTitle => '应用锁';

  @override
  String get appLockSubtitleChecking => '正在检查设备安全...';

  @override
  String get appLockSubtitleEnabled => '使用生物识别或设备密码';

  @override
  String get appLockSubtitleUnavailable => '设备认证不可用';

  @override
  String get lockAfterLabel => '锁定时间';

  @override
  String get lockAfterImmediately => '立即锁定';

  @override
  String get lockAfter1Min => '1 分钟后';

  @override
  String get lockAfter5Min => '5 分钟后';

  @override
  String get lockAfter15Min => '15 分钟后';

  @override
  String get appLockTipsTitle => '应用锁提示';

  @override
  String get appLockTipsBody => '- 使用设备生物识别或密码\n- 仅在应用进入后台后生效\n- 建议保持系统安全设置开启';

  @override
  String get learnMore => '了解更多';

  @override
  String get appLockHelpTitle => '应用锁说明';

  @override
  String get appLockHelpBody =>
      '应用锁依赖设备认证。如果你在系统层关闭生物识别或密码，应用锁将无法使用。\n\n锁定时间仅在应用进入后台时生效，使用过程中不会自动锁定。';

  @override
  String get ok => '确定';

  @override
  String get journalLockedTitle => '日记已锁定';

  @override
  String get journalLockedBody => '请先验证身份。';

  @override
  String get unlock => '解锁';

  @override
  String get unlockReason => '解锁日记';

  @override
  String get enableAppLockReason => '开启应用锁';

  @override
  String get disableAppLockReason => '关闭应用锁';

  @override
  String get calendarTitle => '日历';

  @override
  String entriesOnDateTitle(String date) {
    return '$date 的日记';
  }
}
