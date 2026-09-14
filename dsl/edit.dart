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

/// Big thing 5: what you used, month by month.
///
/// A six-month stacked bar chart under the 30-day figures on What you used:
/// used up (green, at the base) and thrown out (orange, above), with the
/// count and month under every bar, a legend, and the chosen month's numbers
/// in words ("August: 18 used, 4 thrown out — 82% used"). Tap a bar to choose
/// it. Colours validated for colour-blind separation; the lighter green is
/// under 3:1 against white, so every bar carries its numbers as text.
///
/// Honest limit: the app keeps no prices (receipt prices are deliberately
/// not read), so there is no "money saved" — counts only.
void buildStarterEditFlow(App app) {
  app.customWidget(
    'WasteChart',
    parameters: {},
    description:
        'Six months of food used up versus thrown out, as stacked bars with '
        'counts and a line in words for the chosen month.',
    code: _wasteChart,
  );

  final waste = ff.Pages.wasteHistoryPage;
  app.editPage(waste, (page) {
    page.ensureInsertedAfter(
      waste.widgets.byKey('Row_l9xgqat4').single, // the 30-day figures
      CustomWidget(widgetName: 'WasteChart', name: 'WasteMonths', arguments: {}),
    );
  });
}

const _wasteChart = r'''
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Six months of used up versus thrown out.
class WasteChart extends StatefulWidget {
  const WasteChart({super.key, this.width, this.height});

  final double? width;
  final double? height;

  @override
  State<WasteChart> createState() => _WasteChartState();
}

class _Month {
  _Month(this.start);
  final DateTime start;
  int used = 0;
  int thrown = 0;
  int get total => used + thrown;
}

class _WasteChartState extends State<WasteChart> {
  static const _ink = Color(0xFF202C24);
  static const _muted = Color(0xFF59665D);
  static const _border = Color(0xFFDCE3D7);
  static const _grid = Color(0xFFEDF2E8);
  // Validated pair (colour-blind separation passes; green is under 3:1 on
  // white, so counts are always shown as text).
  static const _usedColour = Color(0xFF5BAE72);
  static const _thrownColour = Color(0xFFB8461C);

  static const _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June', 'July',
    'August', 'September', 'October', 'November', 'December'
  ];

  String _for = '';
  bool _loading = true;
  List<_Month> _months = const [];
  int _chosen = 5;

  Future<void> _load(String household) async {
    final now = DateTime.now();
    final months = [
      for (var i = 5; i >= 0; i--) _Month(DateTime(now.year, now.month - i, 1)),
    ];
    try {
      final rows = await SupaFlow.client
          .from('food_items')
          .select('status, archived_at')
          .eq('household_id', household)
          .inFilter('status', ['consumed', 'discarded'])
          .gte('archived_at', months.first.start.toUtc().toIso8601String());
      for (final r in rows as List) {
        final at = DateTime.tryParse((r['archived_at'] ?? '').toString())?.toLocal();
        if (at == null) continue;
        for (final m in months) {
          if (at.year == m.start.year && at.month == m.start.month) {
            if (r['status'] == 'consumed') {
              m.used++;
            } else {
              m.thrown++;
            }
          }
        }
      }
      if (!mounted || household != _for) return;
      setState(() {
        _months = months;
        _loading = false;
        _chosen = 5;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();
    final t = FlutterFlowTheme.of(context);
    final household = FFAppState().currentHouseholdId;
    if (household.isNotEmpty && household != _for) {
      _for = household;
      WidgetsBinding.instance.addPostFrameCallback((_) => _load(household));
    }
    // Nothing yet: the page's own figures and note say so.
    if (_loading || _months.every((m) => m.total == 0)) {
      return const SizedBox.shrink();
    }
    final peak = _months.map((m) => m.total).reduce((a, b) => a > b ? a : b);
    final chosen = _months[_chosen];
    final pct = chosen.total == 0 ? null : (chosen.used * 100 / chosen.total).round();

    return Container(
      width: widget.width,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('The last six months',
              style: t.titleMedium.copyWith(
                  fontSize: 18, fontWeight: FontWeight.w800, color: _ink)),
          const SizedBox(height: 4),
          Row(
            children: [
              _key(t, _usedColour, 'Used up'),
              const SizedBox(width: 16),
              _key(t, _thrownColour, 'Thrown out'),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 176,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < _months.length; i++)
                  Expanded(child: _bar(t, i, peak)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, thickness: 1, color: _grid),
          const SizedBox(height: 10),
          Text(
            chosen.total == 0
                ? '${_monthNames[chosen.start.month - 1]}: nothing finished with yet.'
                : '${_monthNames[chosen.start.month - 1]}: ${chosen.used} used, ${chosen.thrown} thrown out — $pct% used.',
            style: t.bodyLarge.copyWith(fontSize: 15, color: _ink, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _key(FlutterFlowTheme t, Color c, String label) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(3)),
          ),
          const SizedBox(width: 6),
          Text(label, style: t.bodySmall.copyWith(color: _muted, fontSize: 13)),
        ],
      );

  Widget _bar(FlutterFlowTheme t, int i, int peak) {
    final m = _months[i];
    final on = i == _chosen;
    const plot = 120.0;
    final usedH = peak == 0 ? 0.0 : plot * m.used / peak;
    final thrownH = peak == 0 ? 0.0 : plot * m.thrown / peak;
    final month = _monthNames[m.start.month - 1];
    return Semantics(
      button: true,
      selected: on,
      label: '$month: ${m.used} used, ${m.thrown} thrown out',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _chosen = i),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text('${m.total}',
                style: t.bodySmall.copyWith(
                    fontSize: 12,
                    color: on ? _ink : _muted,
                    fontWeight: on ? FontWeight.w800 : FontWeight.w600)),
            const SizedBox(height: 4),
            SizedBox(
              width: 26,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (m.thrown > 0)
                    Container(
                      height: thrownH < 3 ? 3 : thrownH,
                      decoration: BoxDecoration(
                        color: _thrownColour,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                    ),
                  // A 2px gap between the two parts of the bar.
                  if (m.thrown > 0 && m.used > 0) const SizedBox(height: 2),
                  if (m.used > 0)
                    Container(
                      height: usedH < 3 ? 3 : usedH,
                      decoration: BoxDecoration(
                        color: _usedColour,
                        borderRadius: m.thrown > 0
                            ? BorderRadius.zero
                            : const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                    ),
                  if (m.total == 0) Container(height: 2, color: _grid),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: on ? const Color(0xFFEDF2E8) : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(month.substring(0, 3),
                  style: t.bodySmall.copyWith(
                      fontSize: 12,
                      color: on ? _ink : _muted,
                      fontWeight: on ? FontWeight.w800 : FontWeight.w500)),
            ),
          ],
        ),
      ),
    );
  }
}
''';
