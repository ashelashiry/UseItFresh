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

/// Hybrid review follow-ups: What you used shows "–" and "no activity
/// recorded" for an empty month instead of a measured-looking zero; joining a
/// household says it switches the app to that household.
void buildStarterEditFlow(App app) {
  app.editPage(ff.Pages.householdSetupPage, (page) {
    page.update(ff.Pages.householdSetupPage.widgets.byKey('Text_7r01imgg').single, (patch) {
      patch.text('Join another household');
    });
    page.update(ff.Pages.householdSetupPage.widgets.byKey('TextField_pmsdcf3h').single, (patch) {
      patch.textFieldHint('Invite code. Joining switches the app to that household.');
    });
  });
  app.raw((project) {
    updateCustomWidget(project, name: 'WasteChart', code: _wWasteChart);
  });
}

const _wWasteChart = r'''
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
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December'
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
          .inFilter('status', ['consumed', 'discarded']).gte(
              'archived_at', months.first.start.toUtc().toIso8601String());
      for (final r in rows as List) {
        final at =
            DateTime.tryParse((r['archived_at'] ?? '').toString())?.toLocal();
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
    final pct =
        chosen.total == 0 ? null : (chosen.used * 100 / chosen.total).round();

    return Container(
      width: widget.width,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: _uCard(20),
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
                ? '${_monthNames[chosen.start.month - 1]}: no activity recorded, which is not the same as nothing wasted.'
                : '${_monthNames[chosen.start.month - 1]}: ${chosen.used} used, ${chosen.thrown} thrown out — $pct% used.',
            style: t.bodyLarge.copyWith(
                fontSize: 15, color: _ink, fontWeight: FontWeight.w600),
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
            decoration:
                BoxDecoration(color: c, borderRadius: BorderRadius.circular(3)),
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
            Text(m.total == 0 ? '–' : '${m.total}',
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
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4)),
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
                            : const BorderRadius.vertical(
                                top: Radius.circular(4)),
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

// ---- Hybrid material (design brief, 15 Sep) --------------------------------
// Cream canvas over a blurred food background (set on the page), sculpted
// cream surfaces, forest gradient primary buttons, calm date badges.

const _uForest = Color(0xFF07533A);
const _uForestTop = Color(0xFF176C50);
const _uInk = Color(0xFF202C24);
const _uMuted = Color(0xFF59665D);
const _uSage = Color(0xFFE6EDDF);
const _uLine = Color(0xFFCDD4C3);
const _uCream = Color(0xFFF7F7F0);

bool _uStill(BuildContext c) => MediaQuery.of(c).disableAnimations;

/// A sculpted cream surface: warm diagonal gradient, thin sage border, a
/// narrow white top highlight, a 2px lower edge and a soft shadow.
class _USurface extends StatelessWidget {
  const _USurface({
    required this.child,
    this.padding = EdgeInsets.zero,
    this.radius = 22,
    this.onTap,
    this.label,
    this.tint,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;
  final String? label;
  final List<Color>? tint;

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(radius);
    final body = Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: tint ?? const [Color(0xFFFFFEF9), Color(0xFFF3F3E9)],
        ),
        borderRadius: r,
        border: Border.all(color: _uLine),
        boxShadow: const [
          BoxShadow(color: Color(0xFFD2D8C9), offset: Offset(0, 2)),
          BoxShadow(
              color: Color(0x14263824), offset: Offset(0, 8), blurRadius: 16),
        ],
      ),
      child: ClipRRect(
        borderRadius: r,
        child: Stack(
          children: [
            Padding(padding: padding, child: child),
            // The narrow white highlight along the top edge.
            const Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: 1.5,
              child: ColoredBox(color: Color(0xCCFFFFFF)),
            ),
          ],
        ),
      ),
    );
    if (onTap == null) return body;
    return _UPress(onTap: onTap!, label: label, radius: radius, child: body);
  }
}

/// A tap target that sinks 1px while pressed (tonal only with reduced motion).
class _UPress extends StatefulWidget {
  const _UPress({
    required this.child,
    required this.onTap,
    this.label,
    this.radius = 16,
    this.enabled = true,
  });

  final Widget child;
  final VoidCallback onTap;
  final String? label;
  final double radius;
  final bool enabled;

  @override
  State<_UPress> createState() => _UPressState();
}

class _UPressState extends State<_UPress> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final still = _uStill(context);
    return Semantics(
      button: true,
      enabled: widget.enabled,
      label: widget.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown:
            widget.enabled ? (_) => setState(() => _down = true) : null,
        onTapUp: (_) => setState(() => _down = false),
        onTapCancel: () => setState(() => _down = false),
        onTap: widget.enabled ? widget.onTap : null,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 100),
          opacity: widget.enabled ? (_down && still ? 0.85 : 1) : 0.55,
          child: AnimatedSlide(
            duration: const Duration(milliseconds: 100),
            offset: _down && !still ? const Offset(0, 0.01) : Offset.zero,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// Buttons: one forest primary per task, cream secondaries, quiet text links.
class _UButton extends StatelessWidget {
  const _UButton(
    this.text, {
    required this.onTap,
    this.icon,
    this.kind = 'primary',
    this.busy = false,
    this.trailing = false,
  });

  final String text;
  final VoidCallback? onTap;
  final IconData? icon;
  final String kind; // primary | secondary | danger
  final bool busy;
  final bool trailing;

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);
    final primary = kind == 'primary';
    final danger = kind == 'danger';
    final fg = primary
        ? Colors.white
        : (danger ? const Color(0xFFB42318) : _uForest);
    final iconW = icon == null ? null : Icon(icon, size: 20, color: fg);
    final label = Text(text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: t.bodyLarge.copyWith(
            color: fg,
            fontSize: primary ? 16 : 15,
            fontWeight: primary ? FontWeight.w700 : FontWeight.w600));
    final content = busy
        ? SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: fg))
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (iconW != null && !trailing) ...[iconW, const SizedBox(width: 8)],
              Flexible(child: label),
              if (iconW != null && trailing) ...[const SizedBox(width: 8), iconW],
            ],
          );
    final box = Container(
      constraints: BoxConstraints(minHeight: primary ? 52 : 48),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: primary
              ? const [_uForestTop, _uForest]
              : const [Color(0xFFFFFEFA), Color(0xFFEDF0E4)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: primary
                ? const Color(0xFF06422E)
                : (danger ? const Color(0xFFEBC5BF) : const Color(0xFFCCD7C2))),
        boxShadow: primary
            ? const [
                BoxShadow(color: Color(0xFF033C29), offset: Offset(0, 3)),
                BoxShadow(
                    color: Color(0x2007533A),
                    offset: Offset(0, 6),
                    blurRadius: 10),
              ]
            : const [BoxShadow(color: Color(0xFFD6DFCC), offset: Offset(0, 2))],
      ),
      child: content,
    );
    return _UPress(
      onTap: onTap ?? () {},
      enabled: onTap != null && !busy,
      label: text,
      child: box,
    );
  }
}

/// The date badge from dateBadge(): "Label|tone".
Widget _uBadge(BuildContext context, String spec, {double size = 12}) {
  if (spec.isEmpty) return const SizedBox.shrink();
  final parts = spec.split('|');
  final tone = parts.length > 1 ? parts[1] : 'calm';
  const tones = <String, (Color, Color)>{
    'urgent': (Color(0xFFFDE3E0), Color(0xFFB42318)),
    'warm': (Color(0xFFFFEAD4), Color(0xFF884311)),
    'calm': (Color(0xFFE6EDDF), Color(0xFF335837)),
    'cold': (Color(0xFFE1ECF7), Color(0xFF285E8E)),
  };
  final c = tones[tone] ?? tones['calm']!;
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
        color: c.$1, borderRadius: BorderRadius.circular(8)),
    child: Text(parts.first,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: FlutterFlowTheme.of(context).bodySmall.copyWith(
            color: c.$2, fontSize: size, fontWeight: FontWeight.w600)),
  );
}

/// A compact picture stand-in when no suitable photo exists: the food's name
/// set small and calm, never a borrowed photo of a different food or form.
Widget _uFallback(BuildContext context, String name, {double height = 110}) {
  final t = FlutterFlowTheme.of(context);
  return Container(
    height: height,
    color: const Color(0xFFE4E9D9),
    alignment: Alignment.center,
    padding: const EdgeInsets.symmetric(horizontal: 12),
    child: Text(name.toUpperCase(),
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: t.bodyMedium.copyWith(
            color: const Color(0xFF526845),
            letterSpacing: 2,
            fontSize: 14,
            fontWeight: FontWeight.w600)),
  );
}

/// The back control on ordinary pages: a cream square with a forest arrow.
Widget _uBack(BuildContext context, VoidCallback onTap) => _UPress(
      onTap: onTap,
      label: 'Back',
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFFFFFDF4),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFCDD6C4)),
          boxShadow: const [
            BoxShadow(color: Color(0xFFD6DFCC), offset: Offset(0, 2))
          ],
        ),
        child: const Icon(Icons.arrow_back, color: _uForest, size: 22),
      ),
    );

/// A food card for the two-column grids: picture, two-line name, amount and
/// the date badge.
Widget _uFoodCard(BuildContext context, Map item, {required VoidCallback onTap}) {
  final t = FlutterFlowTheme.of(context);
  final name = '${item['name'] ?? ''}';
  final photo = foodPhoto(name, '${item['image_url'] ?? ''}') ?? '';
  final qty = item['quantity'] is num ? (item['quantity'] as num).toDouble() : null;
  final amount = quantityLabel(qty, '${item['unit'] ?? ''}') ?? '';
  final badge = dateBadge(
        '${item['computed_status'] ?? ''}',
        item['days_left'] is num ? (item['days_left'] as num).round() : null,
        DateTime.tryParse('${item['printed_date'] ?? ''}'),
        '${item['printed_date_type'] ?? ''}',
        '${item['status_basis'] ?? ''}',
      ) ??
      '';
  return _USurface(
    radius: 20,
    onTap: onTap,
    label: '$name. ${badge.split('|').first}',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 110,
          child: photo.isEmpty
              ? _uFallback(context, name)
              : Image.network(photo,
                  fit: BoxFit.cover,
                  cacheWidth: 480,
                  errorBuilder: (_, __, ___) => _uFallback(context, name)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(11, 10, 11, 11),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: t.titleSmall.copyWith(
                      fontSize: 16,
                      height: 1.2,
                      fontWeight: FontWeight.w700,
                      color: _uInk)),
              const SizedBox(height: 4),
              Text(amount.isEmpty ? ' ' : amount,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.bodySmall.copyWith(color: _uMuted, fontSize: 13)),
              const SizedBox(height: 8),
              _uBadge(context, badge),
            ],
          ),
        ),
      ],
    ),
  );
}

/// Food close to its date, the one rule Home, Inventory and Use soon share:
/// past or at its limit, "use soon", or three days or fewer; never frozen.
bool _uSoon(Map item) {
  final status = '${item['computed_status'] ?? ''}';
  if (status == 'frozen' || status == 'consumed' || status == 'discarded') {
    return false;
  }
  if (const {'past_use_by', 'use_today', 'use_soon', 'past_best_before'}
      .contains(status)) {
    return true;
  }
  final d = item['days_left'];
  return d is num && d <= 3;
}

/// The sculpted card as a decoration, for existing layouts.
BoxDecoration _uCard(double radius) => BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFFEF9), Color(0xFFF3F3E9)],
      ),
      borderRadius: BorderRadius.circular(radius < 18 ? radius : 22),
      border: Border.all(color: _uLine),
      boxShadow: const [
        BoxShadow(color: Color(0xFFD2D8C9), offset: Offset(0, 2)),
        BoxShadow(color: Color(0x14263824), offset: Offset(0, 8), blurRadius: 16),
      ],
    );

/// The ordinary back control: a cream square with a forest arrow.
BoxDecoration _uBackDeco() => BoxDecoration(
      color: const Color(0xFFFFFDF4),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFCDD6C4)),
      boxShadow: const [BoxShadow(color: Color(0xFFD6DFCC), offset: Offset(0, 2))],
    );
''';

