library;

import 'dart:io';

import 'package:flutterflow_ai/flutterflow_ai.dart';
// setPageRoute is the documented way to change a page's route, but it is not
// re-exported from the barrel (only findPage/findComponent are). Reaching into
// src/ is the workaround; the alternative -- poking routePath on
// ensurePageRouteSettings() -- skips route normalisation and is explicitly
// warned against.
// ignore: implementation_imports
import 'package:flutterflow_ai/src/helpers/routing_helpers.dart';
// ignore: implementation_imports
import 'package:flutterflow_ai/src/helpers/project_helpers.dart' show setInitialPage;

import 'package:ff_agent_useitfresh_fridge_wise_gvpy0s/flutterflow_project.dart'
    as ff;


Future<void> main(List<String> args) async {
  final options = _parseCliOptions(args);
  try {
    await flutterFlowAI(
      buildStarterEditFlow,
      apiKey: options.apiKey,
      baseUrl: options.baseUrl,
      projectName: options.projectName,
      projectId: options.projectId,
      findOrCreate: options.findOrCreate,
      allowNewProject: options.allowNewProject,
      dryRun: options.dryRun,
      commitMessage: options.commitMessage,
    );
  } catch (error) {
    stderr.writeln('Error: ${formatFlutterFlowAIError(error)}');
    exit(1);
  }
}

final class _CliOptions {
  const _CliOptions({
    this.apiKey,
    this.baseUrl,
    this.projectName,
    this.projectId,
    this.findOrCreate = false,
    this.allowNewProject = false,
    this.dryRun = false,
    this.commitMessage,
  });

  final String? apiKey;
  final String? baseUrl;
  final String? projectName;
  final String? projectId;
  final bool findOrCreate;
  final bool allowNewProject;
  final bool dryRun;
  final String? commitMessage;
}

_CliOptions _parseCliOptions(List<String> args) {
  String? apiKey;
  String? baseUrl;
  String? projectName;
  String? projectId;
  String? commitMessage;
  var findOrCreate = false;
  var allowNewProject = false;
  var dryRun = false;

  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    switch (arg) {
      case '--help':
      case '-h':
        _printUsage();
        exit(0);
      case '--api-key':
        apiKey = _requireValue(args, ++i, '--api-key');
      case '--base-url':
        baseUrl = _requireValue(args, ++i, '--base-url');
      case '--project-name':
        projectName = _requireValue(args, ++i, '--project-name');
      case '--project-id':
        projectId = _requireValue(args, ++i, '--project-id');
      case '--commit-message':
        commitMessage = _requireValue(args, ++i, '--commit-message');
      case '--find-or-create':
        findOrCreate = true;
      case '--allow-new-project':
        allowNewProject = true;
      case '--dry-run':
        dryRun = true;
      default:
        stderr.writeln('Unknown option: $arg');
        _printUsage();
        exit(64);
    }
  }

  return _CliOptions(
    apiKey: apiKey,
    baseUrl: baseUrl,
    projectName: projectName,
    projectId: projectId,
    findOrCreate: findOrCreate,
    allowNewProject: allowNewProject,
    dryRun: dryRun,
    commitMessage: commitMessage,
  );
}

String _requireValue(List<String> args, int index, String flag) {
  if (index >= args.length) {
    stderr.writeln('Missing value for $flag.');
    _printUsage();
    exit(64);
  }
  return args[index];
}

void _printUsage() {
  stdout.writeln('''
Run the starter FlutterFlow AI edit flow.

Usage:
  dart run dsl/edit.dart [options]

Options:
  --api-key <key>           FlutterFlow API key. Defaults to FF_API_KEY.
  --base-url <url>          Override the FlutterFlow API base URL.
  --project-name <name>     Create a new project with this name.
  --project-id <id>         Push into an existing project by ID.
  --find-or-create          Retry by reusing a same-name project before creating.
  --allow-new-project       Bypass the workspace binding guard and create a different project.
  --commit-message <text>   Commit message for the push.
  --dry-run                 Compile and validate without pushing.
  --help, -h                Show this help.
''');
}

// ---------------------------------------------------------------------------
// Home: the feature panel from the design pack.
//
// The panel component was built days ago and never placed. The pack puts it
// directly under the greeting, above "Use first" — a graphite block that gives
// the screen a centre of gravity instead of a list starting at the top.
//
// Its supporting line counts the real items rather than repeating the pack's
// example copy. A hero that says "3 items to check first today" when there are
// none is worse than no hero: it is the first thing anyone reads, and being
// wrong there costs more trust than the panel buys in polish.
// ---------------------------------------------------------------------------

/// Reminders do nothing in a browser, instead of throwing.
///
/// The Inventory page reschedules reminders every time it loads. The
/// notifications plugin has no web implementation, so in a browser its first
/// call reads a platform instance that was never set, and the page logged an
/// uncaught LateInitializationError on every visit to the kitchen at
/// localhost:8080. Reminders only exist on the phone, so on the web there is
/// nothing to schedule.
///
/// A custom ACTION's code is the complete function, imports and all.
void buildStarterEditFlow(App app) {
  app.raw((project) {
    updateCustomAction(
      project,
      name: 'ScheduleExpiryReminders',
      code: r'''
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Rebuilds every pending reminder from what is in the kitchen now.
Future<String> scheduleExpiryReminders() async {
  // Reminders live on the phone. The notifications plugin has no web
  // implementation, and calling it in a browser throws.
  if (kIsWeb) return '';

  final household = FFAppState().currentHouseholdId;
  if (household.isEmpty) return '';

  final user = SupaFlow.client.auth.currentUser?.id;
  if (user == null) return '';

  final plugin = FlutterLocalNotificationsPlugin();
  const settings = InitializationSettings(
    android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    iOS: DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    ),
  );
  await plugin.initialize(settings);
  tzdata.initializeTimeZones();

  // Whatever is pending is about to be wrong. Clear first, always.
  await plugin.cancelAll();

  // Preferences are per person, and absent means the schema's defaults.
  var enabled = true;
  var daysBefore = 2;
  try {
    final prefs = await SupaFlow.client
        .from('notification_preferences')
        .select('expiry_enabled, expiry_days_before')
        .eq('profile_id', user)
        .maybeSingle();
    if (prefs != null) {
      enabled = prefs['expiry_enabled'] as bool? ?? true;
      daysBefore = prefs['expiry_days_before'] as int? ?? 2;
    }
  } catch (_) {
    // No preferences row yet is not a failure; the defaults are sound.
  }

  if (!enabled) return '';

  List<dynamic> rows;
  try {
    rows = await SupaFlow.client
        .from('food_items_status')
        .select('id, name, estimated_expiry_at, printed_date, status')
        .eq('household_id', household);
  } on PostgrestException catch (error) {
    return error.message;
  } catch (error) {
    return 'Could not read your kitchen. $error';
  }

  final now = tz.TZDateTime.now(tz.local);
  var scheduled = 0;

  for (final row in rows) {
    // Settled items are finished with. Nothing to warn about.
    final status = (row['status'] ?? '').toString();
    if (status == 'consumed' || status == 'discarded') continue;

    final printed = DateTime.tryParse((row['printed_date'] ?? '').toString());
    final estimated =
        DateTime.tryParse((row['estimated_expiry_at'] ?? '').toString());
    final expiry = printed ?? estimated;
    // No date and no estimate means nothing to be right about.
    if (expiry == null) continue;

    final name = (row['name'] ?? '').toString().trim();
    if (name.isEmpty) continue;

    // Late morning: past the breakfast rush, early enough to change what you
    // cook tonight or what you buy on the way home.
    final target = tz.TZDateTime(
      tz.local,
      expiry.year,
      expiry.month,
      expiry.day,
      10,
    ).subtract(Duration(days: daysBefore));

    if (!target.isAfter(now)) continue;

    // iOS caps pending local notifications at 64 and silently drops the rest.
    // Stopping deliberately at 60 keeps room for anything added later in the
    // session, and the nearest dates are the ones worth keeping.
    if (scheduled >= 60) break;

    // A printed date is a fact; an estimate is the app's guess. They must not
    // read the same on a lock screen.
    final body = printed != null
        ? 'Its date is in $daysBefore ${daysBefore == 1 ? "day" : "days"}.'
        : 'Around $daysBefore ${daysBefore == 1 ? "day" : "days"} left, going '
            'by a typical shelf life. Worth checking.';

    await plugin.zonedSchedule(
      // The row id keeps this stable if the same item is rescheduled.
      row['id'].hashCode & 0x7FFFFFFF,
      'Use $name soon',
      body,
      target,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'expiry',
          'Food going off',
          channelDescription: 'Reminders before food needs using.',
          importance: Importance.defaultImportance,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
    scheduled++;
  }

  return '';
}
''',
    );

    // The permission request had the same fault: it meant to answer "no" on
    // the web, but called initialize() first, which throws in a browser
    // before that line is reached.
    updateCustomAction(
      project,
      name: 'AskNotificationPermission',
      code: r'''
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Asks for notification permission, and says whether we have it.
///
/// Safe to call more than once: the system only shows its prompt the first
/// time, and returns the standing answer after that.
Future<bool> askNotificationPermission() async {
  // Web: no local notifications, and the plugin throws if it is touched.
  if (kIsWeb) return false;

  final plugin = FlutterLocalNotificationsPlugin();

  const settings = InitializationSettings(
    android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    iOS: DarwinInitializationSettings(
      // Asked for explicitly below instead, so the prompt appears when the
      // person has just turned reminders on and knows why.
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    ),
  );
  await plugin.initialize(settings);

  final ios = plugin.resolvePlatformSpecificImplementation<
      IOSFlutterLocalNotificationsPlugin>();
  if (ios != null) {
    final granted = await ios.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
    return granted ?? false;
  }

  final android = plugin.resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>();
  if (android != null) {
    final granted = await android.requestNotificationsPermission();
    return granted ?? false;
  }

  // Desktop: no local notifications, and nothing to apologise for.
  return false;
}
''',
    );
  });
}
