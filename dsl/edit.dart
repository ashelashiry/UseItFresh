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
// ignore: implementation_imports
import 'package:flutterflow_ai/src/helpers/ensure_helpers.dart' show ensureDataStructField;
// ignore: implementation_imports
import 'package:flutterflow_ai/src/helpers/data_type_helpers.dart' show stringType;

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

/// Loose end, Reminders, step 2 of 2: RemindersSettings.
///
/// Shows what is actually saved (loading placeholder first), saves each change
/// straight away and rebuilds the reminders, keeps "Save reminders" and
/// "Reminders saved.", and says how reminders now arrive: one note a day that
/// opens Use soon.
void buildStarterEditFlow(App app) {
  app.customWidget(
    'RemindersSettings',
    parameters: {},
    description:
        'Reminder settings as saved: on or off, how many days before, saved as '
        'they change.',
    code: _remindersSettings,
  );

  final reminders = ff.Pages.remindersPage;
  app.editPage(reminders, (page) {
    page.ensureInsertedAfter(
      reminders.widgets.byKey('Text_udvfbz96').single, // "Reminders."
      CustomWidget(widgetName: 'RemindersSettings', name: 'ReminderControls', arguments: {}),
    );
  });
}

const _remindersSettings = r'''
import 'package:flutter/material.dart';

/// Reminder settings, as they are saved.
class RemindersSettings extends StatefulWidget {
  const RemindersSettings({super.key, this.width, this.height});

  final double? width;
  final double? height;

  @override
  State<RemindersSettings> createState() => _RemindersSettingsState();
}

class _RemindersSettingsState extends State<RemindersSettings> {
  static const _forest = Color(0xFF07533A);
  static const _ink = Color(0xFF202C24);
  static const _muted = Color(0xFF59665D);
  static const _sage = Color(0xFFEDF2E8);
  static const _border = Color(0xFFDCE3D7);

  bool _loading = true;
  bool _on = true;
  int _days = 2;
  bool _saving = false;
  String _note = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = SupaFlow.client.auth.currentUser?.id;
    try {
      if (user != null) {
        final row = await SupaFlow.client
            .from('notification_preferences')
            .select('expiry_enabled, expiry_days_before')
            .eq('profile_id', user)
            .maybeSingle();
        if (row != null) {
          _on = row['expiry_enabled'] as bool? ?? true;
          _days = row['expiry_days_before'] as int? ?? 2;
        }
      }
    } catch (_) {
      _note = 'Can’t reach your settings right now. What you see are the defaults.';
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<bool> _save({bool announce = false}) async {
    final user = SupaFlow.client.auth.currentUser?.id;
    if (user == null) return false;
    setState(() => _saving = true);
    try {
      await SupaFlow.client.from('notification_preferences').upsert({
        'profile_id': user,
        'expiry_enabled': _on,
        'expiry_days_before': _days,
      }, onConflict: 'profile_id');
      await scheduleExpiryReminders();
      if (mounted && announce) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Reminders saved.')));
      }
      return true;
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Could not save. Check your signal and try again.')));
      }
      return false;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _toggle() async {
    if (_saving) return;
    if (_on) {
      setState(() {
        _on = false;
        _note = 'Reminders are off.';
      });
      await _save();
      return;
    }
    final allowed = await askNotificationPermission();
    if (!mounted) return;
    if (!allowed) {
      setState(() => _note =
          'Your phone is blocking notifications for Use It Fresh. Settings > Notifications > Use It Fresh to allow them.');
      return;
    }
    setState(() {
      _on = true;
      _note = '';
    });
    await _save();
  }

  Future<void> _pickDays(int d) async {
    if (_saving || d == _days) return;
    setState(() => _days = d);
    await _save();
  }

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);
    if (_loading) {
      Widget block(double h) => Container(
            height: h,
            decoration:
                BoxDecoration(color: _sage, borderRadius: BorderRadius.circular(16)),
          );
      return SizedBox(
        width: widget.width,
        child: Column(children: [
          const SizedBox(height: 16),
          block(64),
          const SizedBox(height: 20),
          block(48),
          const SizedBox(height: 20),
          block(52),
        ]),
      );
    }

    return SizedBox(
      width: widget.width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          Semantics(
            toggled: _on,
            label: 'Remind me before food goes off',
            excludeSemantics: true,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: _toggle,
              child: Container(
                constraints: const BoxConstraints(minHeight: 64),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _border),
                ),
                child: Row(
                  children: [
                    Icon(_on ? Icons.notifications_active_outlined : Icons.notifications_off_outlined,
                        color: _forest, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text('Remind me before food goes off',
                          style: t.bodyLarge.copyWith(
                              fontSize: 16, fontWeight: FontWeight.w700, color: _ink)),
                    ),
                    Switch.adaptive(
                      value: _on,
                      activeColor: _forest,
                      onChanged: (_) => _toggle(),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_note.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(_note, style: t.bodyMedium.copyWith(color: _muted, fontSize: 14)),
          ],
          AnimatedOpacity(
            opacity: _on ? 1 : 0.45,
            duration: const Duration(milliseconds: 150),
            child: IgnorePointer(
              ignoring: !_on,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),
                  Text('How long before',
                      style: t.bodyMedium.copyWith(
                          fontSize: 14, fontWeight: FontWeight.w700, color: _muted)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      for (final d in const [1, 2, 3, 5]) ...[
                        Expanded(child: _dayChip(t, d)),
                        if (d != 5) const SizedBox(width: 8),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                        color: _sage, borderRadius: BorderRadius.circular(14)),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline, color: _forest, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                              'One note at 10am on the day, naming the foods that are $_days ${_days == 1 ? 'day' : 'days'} from their date. Tap it to mark what you used.',
                              style: t.bodyMedium.copyWith(color: _ink, fontSize: 14, height: 1.4)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 52,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: _forest,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _saving ? null : () => _save(announce: true),
              child: Text('Save reminders',
                  style: t.bodyLarge.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _dayChip(FlutterFlowTheme t, int d) {
    final on = _days == d;
    return Semantics(
      button: true,
      selected: on,
      label: d == 1 ? '1 day before' : '$d days before',
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _pickDays(d),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: on ? _forest : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: on ? _forest : _border),
          ),
          child: Text(d == 1 ? '1 day' : '$d days',
              style: t.bodyMedium.copyWith(
                  fontWeight: FontWeight.w800, color: on ? Colors.white : _ink)),
        ),
      ),
    );
  }
}
''';
