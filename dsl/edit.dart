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

/// Hybrid design, batch 1 (brief 15 Sep): Add food tiles in soft tones with
/// purposes; the camera's four modes across one bar with Type as its own
/// button; Use soon as compact rows with date badges, Find meals, and actions
/// in a sheet; Receipts' empty screen with Scan a receipt; and the sculpted
/// cards, buttons and back controls on Shopping list, Storage, Reminders, Diet
/// & allergies, Profile, the receipt review, line editor, chart and pickers.
void buildStarterEditFlow(App app) {
  app.raw((project) {
    updateCustomWidget(project, name: 'AddOptions', code: _wAddOptions);
    updateCustomWidget(project, name: 'UseSoonList', code: _wUseSoonList);
    updateCustomWidget(project, name: 'SmartCamera', code: _wSmartCamera);
    updateCustomWidget(project, name: 'ReceiptHistory', code: _wReceiptHistory);
    updateCustomWidget(project, name: 'ShoppingListLive', code: _wShoppingListLive);
    updateCustomWidget(project, name: 'StorageLocationsLive', code: _wStorageLocationsLive);
    updateCustomWidget(project, name: 'RemindersSettings', code: _wRemindersSettings);
    updateCustomWidget(project, name: 'FoodPreferences', code: _wFoodPreferences);
    updateCustomWidget(project, name: 'ProfileMenu', code: _wProfileMenu);
    updateCustomWidget(project, name: 'ReceiptHeader', code: _wReceiptHeader);
    updateCustomWidget(project, name: 'ScanLineEditor', code: _wScanLineEditor);
    updateCustomWidget(project, name: 'WasteChart', code: _wWasteChart);
    updateCustomWidget(project, name: 'ReviewSummary', code: _wReviewSummary);
    updateCustomWidget(project, name: 'ProductPhotoPicker', code: _wProductPhotoPicker);
  });
}

const _wAddOptions = r'''
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// The four ways to add food (hybrid design, brief 15 Sep): large sculpted
/// tiles in soft tones, each with its icon, name and one line saying what it
/// is for, then "Enter manually" and a reassurance that nothing is added
/// before it is reviewed.
///
///   Photo    -> the Add food screen, which takes a single-item photo
///   Barcode  -> the barcode screen
///   Receipt  -> the camera set to Receipt
///   Shelf    -> the camera set to Shelf, on a fresh photo map
class AddOptions extends StatefulWidget {
  const AddOptions({super.key, this.width, this.height});

  final double? width;
  final double? height;

  @override
  State<AddOptions> createState() => _AddOptionsState();
}

class _AddOptionsState extends State<AddOptions> {
  // The supplied v3 line icons (24px grid, 1.8 stroke), drawn in forest.
  static const _camera =
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#07533A" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M3 6h5l2-3h4l2 3h5v15H3zM16 13a4 4 0 1 1-8 0 4 4 0 0 1 8 0Z"/></svg>';
  static const _barcode =
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#07533A" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M3 4v16m4-16v16m3-16v16m4-16v16m3-16v16m4-16v16"/></svg>';
  static const _receipt =
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#07533A" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M5 2v20l3-2 4 2 4-2 3 2V2l-3 2-4-2-4 2zM8 8h8m-8 4h8m-8 4h5"/></svg>';

  // A camera is already opening: a second tap must not open another.
  bool _busy = false;

  Future<void> _run(Future<void> Function() go) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await go();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _shelf() async {
    await clearShelfScan();
    if (!mounted) return;
    await context.pushNamed('CameraPage', queryParameters: {'mode': 'shelf'});
  }

  static Widget _svg(String source) =>
      SvgPicture.string(source, width: 40, height: 40);

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);
    Widget tile(String name, String purpose, Widget icon, List<Color> tone,
            Future<void> Function() go) =>
        _USurface(
          tint: tone,
          onTap: _busy ? null : () => _run(go),
          label: '$name. $purpose',
          padding: const EdgeInsets.all(18),
          child: SizedBox(
            height: 150,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                icon,
                const Spacer(),
                Text(name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.titleMedium.copyWith(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: _uForest)),
                const SizedBox(height: 4),
                Text(purpose,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: t.bodySmall.copyWith(
                        color: _uMuted, fontSize: 13, height: 1.3)),
              ],
            ),
          ),
        );

    return SizedBox(
      width: widget.width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: tile('Photo', 'One food or package', _svg(_camera),
                    const [Color(0xFFFFFEF9), Color(0xFFF3F3E9)], () async {
                  await context.pushNamed('AddFoodItemPage');
                }),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: tile('Barcode', 'Find a packaged food', _svg(_barcode),
                    const [Color(0xFFFCFAF0), Color(0xFFE2E8CF)], () async {
                  await context.pushNamed('BarcodeScanPage');
                }),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: tile('Receipt', 'Review a whole shop', _svg(_receipt),
                    const [Color(0xFFFFFDF6), Color(0xFFF0E4D0)], () async {
                  await context.pushNamed('CameraPage',
                      queryParameters: {'mode': 'receipt'});
                }),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: tile(
                    'Shelf',
                    'A shelf at a time',
                    const Icon(Icons.kitchen_outlined,
                        size: 40, color: _uForest),
                    const [Color(0xFFFCFFF7), Color(0xFFD9E6D1)],
                    _shelf),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Center(
            child: TextButton(
              onPressed:
                  _busy ? null : () => context.pushNamed('AddFoodItemPage'),
              style: TextButton.styleFrom(
                  minimumSize: const Size(48, 48), foregroundColor: _uForest),
              child: Text('Enter manually',
                  style: t.bodyLarge
                      .copyWith(color: _uForest, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 8),
          Text('You review the suggestions before adding anything.',
              style: t.bodyMedium.copyWith(color: _uMuted, fontSize: 14)),
        ],
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

const _wUseSoonList = r'''
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// Use soon: what is close to its date, to deal with in a few taps.
class UseSoonList extends StatefulWidget {
  const UseSoonList({super.key, this.width, this.height});

  final double? width;
  final double? height;

  @override
  State<UseSoonList> createState() => _UseSoonListState();
}

class _UseSoonListState extends State<UseSoonList> {
  static const _forest = Color(0xFF07533A);
  static const _ink = Color(0xFF202C24);
  static const _muted = Color(0xFF59665D);
  static const _sage = Color(0xFFEDF2E8);
  static const _border = Color(0xFFDCE3D7);

  static const _food =
      'https://cdn.jsdelivr.net/gh/ashelashiry/UseItFresh@b50424f12bd372d81c9cd44d895b62c25d1329e7/design/v3/food';

  String _for = '';
  bool _loading = true;
  bool _offline = false;
  List<Map<String, dynamic>> _items = const [];
  final Set<String> _busy = {};

  /// Close to its date: past it, today, "use soon", or three days or fewer.
  /// Frozen food is not counting down, so it is never here.
  static bool isSoon(Map<String, dynamic> i) {
    final status = (i['computed_status'] ?? '').toString();
    if (status == 'frozen' || status == 'consumed' || status == 'discarded') {
      return false;
    }
    if (const {'past_use_by', 'use_today', 'use_soon', 'past_best_before'}
        .contains(status)) {
      return true;
    }
    final d = i['days_left'];
    return d is num && d <= 3;
  }

  Future<void> _load(String household, {bool quiet = false}) async {
    if (!quiet && mounted) {
      setState(() {
        _loading = true;
        _offline = false;
      });
    }
    try {
      final rows = await SupaFlow.client
          .from('food_items_status')
          .select(
              'id, name, quantity, unit, image_url, location_name, computed_status, status_detail, days_left, printed_date, printed_date_type, status_basis')
          .eq('household_id', household)
          .order('urgency_rank', ascending: true)
          .order('days_left', ascending: true);
      if (!mounted || household != _for) return;
      setState(() {
        _items = List<Map<String, dynamic>>.from(rows as List)
            .where(isSoon)
            .toList();
        _loading = false;
        _offline = false;
      });
    } catch (_) {
      if (!mounted) return;
      if (quiet && _items.isNotEmpty) return;
      setState(() {
        _loading = false;
        _offline = true;
      });
    }
  }

  Future<void> _settle(Map<String, dynamic> item, String outcome) async {
    final id = item['id'].toString();
    if (_busy.contains(id)) return;
    setState(() => _busy.add(id));
    final messenger = ScaffoldMessenger.of(context);
    final name = (item['name'] ?? '').toString();
    final said = await settleFoodItem(id, outcome);
    if (!mounted) return;
    setState(() => _busy.remove(id));
    if (said.isNotEmpty) {
      messenger.showSnackBar(SnackBar(content: Text(said)));
      return;
    }
    setState(
        () => _items = _items.where((i) => i['id'].toString() != id).toList());
    messenger.showSnackBar(SnackBar(
      duration: const Duration(seconds: 6),
      content: Text(outcome == 'consumed'
          ? 'Good. Nothing wasted.'
          : 'Thrown out and recorded.'),
      action: SnackBarAction(
        label: 'Undo',
        textColor: const Color(0xFFB9E08F),
        onPressed: () async {
          final back = await unsettleFoodItem(id);
          messenger.showSnackBar(SnackBar(
              content: Text(back.isEmpty
                  ? '${name.isEmpty ? 'It' : name} is back in your kitchen.'
                  : back)));
          if (mounted && back.isEmpty) _load(_for, quiet: true);
        },
      ),
    ));
  }

  void _back() {
    final router = GoRouter.of(context);
    if (router.canPop()) {
      router.pop();
    } else {
      router.goNamed('HomePage');
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

    final count = _items.length;
    Widget content;
    if (_loading) {
      content = Column(children: [
        for (var i = 0; i < 3; i++) ...[
          Container(
            height: 120,
            decoration: BoxDecoration(
                color: _sage, borderRadius: BorderRadius.circular(20)),
          ),
          const SizedBox(height: 12),
        ],
      ]);
    } else if (_offline) {
      content = _message(
          t,
          Icons.cloud_off_outlined,
          'Can’t reach your kitchen.',
          'No signal, or the connection dropped. Try again when you are back online.',
          'Try again',
          () => _load(_for));
    } else if (_items.isEmpty) {
      content = _message(
          t,
          Icons.check_circle_outline,
          'Nothing needs using right now.',
          'When food gets close to its date, it shows here with a quick way to mark it used.',
          'Back to your kitchen',
          () => GoRouter.of(context).goNamed('InventoryPage'));
    } else {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final item in _items) ...[
            _row(t, item),
            const SizedBox(height: 12),
          ],
        ],
      );
    }

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Semantics(
                button: true,
                label: 'Back',
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: _back,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: _uBackDeco(),
                    child: const Icon(Icons.arrow_back, color: _uForest, size: 22),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Use soon.',
                style: t.headlineMedium.copyWith(
                    fontSize: 32, fontWeight: FontWeight.w800, color: _uForest)),
            if (!_loading && !_offline && count > 0) ...[
              const SizedBox(height: 4),
              Text(
                  count == 1
                      ? '1 food close to its date'
                      : '$count foods close to their dates',
                  style: t.bodyLarge.copyWith(color: _muted, fontSize: 16)),
              const SizedBox(height: 14),
              _UButton('Find meals that use them',
                  icon: Icons.restaurant_menu,
                  onTap: () => context.pushNamed('RecipesPage')),
            ],
            const SizedBox(height: 20),
            AnimatedSize(
              duration: MediaQuery.of(context).disableAnimations
                  ? Duration.zero
                  : const Duration(milliseconds: 200),
              alignment: Alignment.topCenter,
              child: content,
            ),
          ],
        ),
      ),
    );
  }

  /// One compact row: picture, name, amount and place, and the date badge.
  /// Tapping opens the food; the actions sit in a sheet, so the page is not a
  /// wall of equal Used / Throw out buttons (hybrid brief, 15 Sep).
  Widget _row(FlutterFlowTheme t, Map<String, dynamic> item) {
    final id = item['id'].toString();
    final name = (item['name'] ?? '').toString();
    final qty =
        item['quantity'] is num ? (item['quantity'] as num).toDouble() : null;
    final amount = quantityLabel(qty, (item['unit'] ?? '').toString()) ?? '';
    final where = (item['location_name'] ?? '').toString();
    final photo = foodPhoto(name, (item['image_url'] ?? '').toString()) ?? '';
    final badge = dateBadge(
          (item['computed_status'] ?? '').toString(),
          item['days_left'] is num ? (item['days_left'] as num).round() : null,
          DateTime.tryParse('${item['printed_date'] ?? ''}'),
          '${item['printed_date_type'] ?? ''}',
          '${item['status_basis'] ?? ''}',
        ) ??
        '';
    final busy = _busy.contains(id);
    return _USurface(
      radius: 20,
      label: '$name. ${badge.split('|').first}',
      onTap: () async {
        await context.pushNamed('FoodItemPage', queryParameters: {'itemId': id});
        if (mounted) _load(_for, quiet: true);
      },
      padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              width: 64,
              height: 64,
              child: photo.isEmpty
                  ? _uFallback(context, name.isEmpty ? '' : name[0], height: 64)
                  : Image.network(photo,
                      fit: BoxFit.cover,
                      cacheWidth: 200,
                      errorBuilder: (_, __, ___) => _uFallback(
                          context, name.isEmpty ? '' : name[0],
                          height: 64)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: t.titleMedium.copyWith(
                        fontSize: 16, fontWeight: FontWeight.w700, color: _ink)),
                const SizedBox(height: 2),
                Text([if (amount.isNotEmpty) amount, if (where.isNotEmpty) where].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.bodySmall.copyWith(color: _muted, fontSize: 13)),
                const SizedBox(height: 6),
                _uBadge(context, badge),
              ],
            ),
          ),
          busy
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: _uForest)),
                )
              : IconButton(
                  tooltip: 'Actions for $name',
                  icon: const Icon(Icons.more_horiz, color: _uForest),
                  onPressed: () => _actions(t, item),
                ),
        ],
      ),
    );
  }

  Future<void> _actions(FlutterFlowTheme t, Map<String, dynamic> item) async {
    final name = (item['name'] ?? '').toString();
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: _uCream,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheet) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(name,
                  style: t.headlineSmall.copyWith(
                      fontSize: 22, fontWeight: FontWeight.w800, color: _uInk)),
              const SizedBox(height: 16),
              _UButton('Used all of it',
                  icon: Icons.check,
                  onTap: () => Navigator.of(sheet).pop('consumed')),
              const SizedBox(height: 10),
              _UButton('Use some, or change details',
                  kind: 'secondary',
                  icon: Icons.tune,
                  onTap: () => Navigator.of(sheet).pop('open')),
              const SizedBox(height: 18),
              Center(
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                      minimumSize: const Size(48, 48),
                      foregroundColor: const Color(0xFFB42318)),
                  onPressed: () => Navigator.of(sheet).pop('discarded'),
                  icon: const Icon(Icons.delete_outline, size: 20),
                  label: Text('Throw it out',
                      style: t.bodyLarge.copyWith(
                          color: const Color(0xFFB42318),
                          fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted || choice == null) return;
    if (choice == 'open') {
      await context.pushNamed('FoodItemPage',
          queryParameters: {'itemId': item['id'].toString()});
      if (mounted) _load(_for, quiet: true);
      return;
    }
    if (choice == 'discarded') {
      final sure = await showDialog<bool>(
        context: context,
        builder: (d) => AlertDialog(
          backgroundColor: Colors.white,
          title: Text('Throw out $name?'),
          content: const Text('It is recorded in What you used. You can undo straight after.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(d).pop(false),
                child: const Text('Keep it')),
            TextButton(
                onPressed: () => Navigator.of(d).pop(true),
                child: const Text('Throw out',
                    style: TextStyle(color: Color(0xFFB42318)))),
          ],
        ),
      );
      if (sure != true || !mounted) return;
    }
    await _settle(item, choice);
  }

  Widget _message(FlutterFlowTheme t, IconData icon, String title, String text,
      String action, VoidCallback onAction) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: _uCard(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: _sage, borderRadius: BorderRadius.circular(16)),
            child: Icon(icon, color: _forest, size: 28),
          ),
          const SizedBox(height: 16),
          Text(title,
              style: t.titleLarge.copyWith(
                  fontSize: 22, fontWeight: FontWeight.w800, color: _ink)),
          const SizedBox(height: 6),
          Text(text,
              style: t.bodyLarge
                  .copyWith(fontSize: 16, color: _muted, height: 1.4)),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              style: FilledButton.styleFrom(
  elevation: 3,
  shadowColor: const Color(0x99033C29),
                backgroundColor: _forest,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: onAction,
              child: Text(action,
                  style: t.bodyLarge.copyWith(
                      color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
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

const _wSmartCamera = r'''
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

/// The app's own camera, with what to photograph chosen on it.
///
/// Shelf: one shelf, read into the photo map (a receipt is recognised and goes
/// to the receipt review instead). Receipt: read into the receipt review.
/// Barcode and Type it hand over to their screens. A photo already on the
/// phone can be chosen instead. If the camera cannot start — no camera, or
/// access turned off — it says so and offers the gallery or typing.
class SmartCamera extends StatefulWidget {
  const SmartCamera({super.key, this.width, this.height, this.mode});

  final double? width;
  final double? height;
  final String? mode;

  @override
  State<SmartCamera> createState() => _SmartCameraState();
}

class _SmartCameraState extends State<SmartCamera> with WidgetsBindingObserver {
  static const _forest = Color(0xFF07533A);
  static const _leaf = Color(0xFF83BD43);

  // Four modes across one bar, none cut off; typing is its own button.
  static const _modes = <(String, String, IconData)>[
    ('photo', 'Photo', Icons.photo_camera_outlined),
    ('shelf', 'Shelf', Icons.kitchen_outlined),
    ('receipt', 'Receipt', Icons.receipt_long_outlined),
    ('barcode', 'Barcode', Icons.qr_code_scanner),
  ];

  CameraController? _controller;
  bool _starting = true;
  String _problem = '';
  bool _reading = false;
  bool _flash = false;
  bool _pressed = false;
  late String _mode;

  @override
  void initState() {
    super.initState();
    _mode = widget.mode == 'receipt' ? 'receipt' : 'shelf';
    WidgetsBinding.instance.addObserver(this);
    _start();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final c = _controller;
    if (state == AppLifecycleState.inactive) {
      if (c != null && c.value.isInitialized) {
        _controller = null;
        c.dispose();
        if (mounted) setState(() {});
      }
    } else if (state == AppLifecycleState.resumed && _controller == null) {
      _start();
    }
  }

  Future<void> _start() async {
    if (mounted) setState(() => _starting = true);
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        _problem = 'There is no camera on this device.';
        return;
      }
      final back = cameras.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.back,
          orElse: () => cameras.first);
      final c = CameraController(back, ResolutionPreset.veryHigh,
          enableAudio: false, imageFormatGroup: ImageFormatGroup.jpeg);
      await c.initialize();
      try {
        await c.setFlashMode(FlashMode.off);
      } catch (_) {}
      if (!mounted) {
        await c.dispose();
        return;
      }
      _controller = c;
      _problem = '';
    } on CameraException catch (e) {
      _problem = e.code.contains('Denied') || e.code.contains('denied')
          ? 'Camera access is turned off for Use It Fresh. Turn it on in Settings, or choose a photo instead.'
          : 'The camera could not start. Choose a photo instead, or try again.';
    } catch (_) {
      _problem =
          'The camera could not start. Choose a photo instead, or try again.';
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  // ---- actions ---------------------------------------------------------------

  void _close() {
    final router = GoRouter.of(context);
    if (router.canPop()) {
      router.pop();
    } else {
      router.goNamed('HomePage');
    }
  }

  void _choose(String mode) {
    if (_reading) return;
    final router = GoRouter.of(context);
    if (mode == 'barcode') {
      router.pushReplacementNamed('BarcodeScanPage');
    } else if (mode == 'type' || mode == 'photo') {
      router.pushReplacementNamed('AddFoodItemPage');
    } else {
      setState(() => _mode = mode);
    }
  }

  Future<void> _toggleFlash() async {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    final next = !_flash;
    try {
      await c.setFlashMode(next ? FlashMode.always : FlashMode.off);
      setState(() => _flash = next);
    } catch (_) {}
  }

  Future<void> _shoot() async {
    final c = _controller;
    if (_reading ||
        c == null ||
        !c.value.isInitialized ||
        c.value.isTakingPicture) {
      return;
    }
    try {
      final picture = await c.takePicture();
      await _read(await picture.readAsBytes());
    } catch (_) {
      if (mounted) _say('The photo was not taken. Try again.');
    }
  }

  Future<void> _gallery() async {
    if (_reading) return;
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 2000,
      maxHeight: 3200,
      imageQuality: 85,
    );
    if (picked == null) return;
    await _read(await picked.readAsBytes());
  }

  Future<void> _read(Uint8List bytes) async {
    if (_reading) return;
    setState(() => _reading = true);
    // Taken now: after the read this widget may be gone.
    final router = GoRouter.of(context);
    final root = Navigator.of(context, rootNavigator: true);
    final file = FFUploadedFile(name: 'camera.jpg', bytes: bytes);
    var left = false;
    try {
      if (_mode == 'receipt') {
        final said = await readReceiptShot(file);
        if (said == 'ok') {
          left = true;
          router.pushReplacementNamed('ScanReviewPage');
        } else if (said.isNotEmpty && root.mounted) {
          await _explain(root.context, 'Receipt not added', said);
        }
      } else {
        await clearShelfScan();
        final said = await readShelfShot(file);
        if (said == 'ok') {
          left = true;
          if (FFAppState().receiptFromCamera) {
            FFAppState().receiptFromCamera = false;
            router.pushReplacementNamed('ScanReviewPage');
          } else {
            router.pushReplacementNamed('MapReviewPage');
          }
        } else if (said.isNotEmpty && root.mounted) {
          await _explain(root.context, 'Nothing added', said);
        }
      }
    } finally {
      if (!left && mounted) setState(() => _reading = false);
    }
  }

  void _say(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  static Future<void> _explain(BuildContext host, String title, String said) {
    return showDialog<void>(
      context: host,
      builder: (dialog) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title),
        content: Text(said),
        actions: [
          TextButton(
            style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
            onPressed: () => Navigator.of(dialog).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // ---- screen ----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);
    final c = _controller;
    final ready = c != null && c.value.isInitialized;
    final receipt = _mode == 'receipt';
    return ColoredBox(
      color: Colors.black,
      child: SizedBox.expand(
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (ready)
              ClipRect(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: c.value.previewSize?.height ?? 1080,
                    height: c.value.previewSize?.width ?? 1920,
                    child: CameraPreview(c),
                  ),
                ),
              ),
            if (ready && !_reading) _frame(t, receipt),
            if (!ready && !_starting) _unavailable(t),
            if (_starting)
              const Center(
                  child: CircularProgressIndicator(color: Colors.white)),
            // Top: close and flash.
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(
                    children: [
                      _roundButton(Icons.close, 'Close', _close, filled: true),
                      const Spacer(),
                      if (ready)
                        _roundButton(_flash ? Icons.flash_on : Icons.flash_off,
                            _flash ? 'Flash on' : 'Flash off', _toggleFlash),
                    ],
                  ),
                ),
              ),
            ),
            // Bottom: modes, then gallery and shutter.
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x00000000), Color(0xCC000000)],
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: const Color(0xA0142E24),
                            borderRadius: BorderRadius.circular(40),
                            border: Border.all(color: const Color(0x50FFFFFF)),
                          ),
                          child: Row(
                            children: [
                              for (final m in _modes)
                                Expanded(child: _modeChip(t, m)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _roundButton(Icons.photo_library_outlined,
                                'Choose a photo', _gallery),
                            _shutter(ready),
                            _roundButton(Icons.edit_outlined, 'Type it in',
                                () => _choose('type')),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (_reading) _readingOverlay(t),
          ],
        ),
      ),
    );
  }

  Widget _frame(FlutterFlowTheme t, bool receipt) {
    return LayoutBuilder(builder: (context, box) {
      final w = box.maxWidth * (receipt ? 0.62 : 0.86);
      final h = receipt ? box.maxHeight * 0.52 : box.maxHeight * 0.32;
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
                receipt
                    ? 'Lay the receipt flat, all of it in the frame'
                    : 'Fit one shelf in the frame',
                textAlign: TextAlign.center,
                style: t.bodyLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    shadows: const [
                      Shadow(color: Colors.black54, blurRadius: 6)
                    ])),
            const SizedBox(height: 12),
            AnimatedContainer(
              duration: MediaQuery.of(context).disableAnimations
                  ? Duration.zero
                  : const Duration(milliseconds: 220),
              width: w,
              height: h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _modeChip(FlutterFlowTheme t, (String, String, IconData) m) {
    final on = _mode == m.$1;
    return Semantics(
      button: true,
      selected: on,
      label: m.$2,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _choose(m.$1),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          constraints: const BoxConstraints(minHeight: 44),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: on ? const Color(0xFFFFFDF4) : Colors.transparent,
            borderRadius: BorderRadius.circular(40),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(m.$2,
                  style: t.bodyMedium.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: on ? _forest : Colors.white)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _roundButton(IconData icon, String label, VoidCallback onTap,
          {bool filled = false}) =>
      Semantics(
        button: true,
        label: label,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: filled ? _forest : const Color(0x4D000000),
              border:
                  filled ? null : Border.all(color: const Color(0x80FFFFFF)),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
        ),
      );

  Widget _shutter(bool ready) {
    final still = MediaQuery.of(context).disableAnimations;
    return Semantics(
      button: true,
      enabled: ready && !_reading,
      label: _mode == 'receipt'
          ? 'Take the receipt photo'
          : 'Take the shelf photo',
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        onTap: ready ? _shoot : null,
        child: AnimatedScale(
          scale: (_pressed && !still) ? 0.92 : 1,
          duration: const Duration(milliseconds: 120),
          child: Opacity(
            opacity: ready ? 1 : 0.4,
            child: Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
              ),
              padding: const EdgeInsets.all(5),
              child: const DecoratedBox(
                decoration:
                    BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _readingOverlay(FlutterFlowTheme t) => Positioned.fill(
        child: ColoredBox(
          color: const Color(0xB3000000),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 44,
                  height: 44,
                  child:
                      CircularProgressIndicator(color: _leaf, strokeWidth: 4),
                ),
                const SizedBox(height: 16),
                Text(
                    _mode == 'receipt'
                        ? 'Reading your receipt…'
                        : 'Reading your photo…',
                    style: t.titleMedium.copyWith(
                        color: Colors.white, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text('This takes a few seconds.',
                    style: t.bodyMedium.copyWith(color: Colors.white70)),
              ],
            ),
          ),
        ),
      );

  Widget _unavailable(FlutterFlowTheme t) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.no_photography_outlined,
                  color: Colors.white, size: 48),
              const SizedBox(height: 16),
              Text(_problem,
                  textAlign: TextAlign.center,
                  style:
                      t.bodyLarge.copyWith(color: Colors.white, height: 1.4)),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
  elevation: 3,
  shadowColor: const Color(0x99033C29),
                    backgroundColor: _forest,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _gallery,
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Choose a photo'),
                ),
              ),
              TextButton(
                style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    minimumSize: const Size(48, 48)),
                onPressed: _start,
                child: const Text('Try the camera again'),
              ),
            ],
          ),
        ),
      );
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

const _wReceiptHistory = r'''
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Receipts (owner, 14 Sep: "summary of how many items, scanned date, purchase
/// date/time and location of the receipt").
///
/// Every receipt the household has added, newest first: the shop, where it
/// is, when it was bought, how many items, the total, and when it was scanned.
/// A receipt opens to its lines with what was paid and what became of each
/// food. Deleting a receipt keeps the food; only the record goes. No photo of
/// a receipt is ever kept.
class ReceiptHistory extends StatefulWidget {
  const ReceiptHistory({super.key, this.width, this.height});

  final double? width;
  final double? height;

  @override
  State<ReceiptHistory> createState() => _ReceiptHistoryState();
}

class _ReceiptHistoryState extends State<ReceiptHistory> {
  static const _forest = Color(0xFF07533A);
  static const _ink = Color(0xFF202C24);
  static const _muted = Color(0xFF59665D);
  static const _sage = Color(0xFFEDF2E8);
  static const _border = Color(0xFFDCE3D7);
  static const _cream = Color(0xFFF7F7F0);
  static const _red = Color(0xFFB42318);

  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec'
  ];

  String _for = '';
  bool _loading = true;
  bool _offline = false;
  bool _notReady = false;
  List<Map> _receipts = const [];

  Future<void> _load(String household, {bool quiet = false}) async {
    if (!quiet && mounted) {
      setState(() {
        _loading = true;
        _offline = false;
      });
    }
    try {
      final rows = await SupaFlow.client
          .from('receipts')
          .select(
              'id, shop_name, shop_location, purchased_at, scanned_at, item_count, total_amount, currency')
          .eq('household_id', household)
          .order('scanned_at', ascending: false)
          .limit(100);
      if (!mounted || household != _for) return;
      setState(() {
        _receipts = [for (final r in rows as List) r as Map];
        _loading = false;
        _offline = false;
        _notReady = false;
      });
    } on PostgrestException catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _notReady = error.code == '42P01' || error.code == 'PGRST205';
        _offline = !_notReady;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _offline = true;
      });
    }
  }

  static String _when(Object? iso, {bool time = true}) {
    final d = DateTime.tryParse('${iso ?? ''}')?.toLocal();
    if (d == null) return '';
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final clock =
        '$h:${d.minute.toString().padLeft(2, '0')} ${d.hour < 12 ? 'am' : 'pm'}';
    final day = '${_days[d.weekday - 1]} ${d.day} ${_months[d.month - 1]}'
        '${d.year != DateTime.now().year ? ' ${d.year}' : ''}';
    return time ? '$day, $clock' : day;
  }

  static String _money(Object? amount, Object? currency) {
    if (amount is! num || amount <= 0) return '';
    const symbols = {
      'AUD': r'$',
      'NZD': r'$',
      'USD': r'$',
      'CAD': r'$',
      'GBP': '£',
      'EUR': '€'
    };
    final code = '${currency ?? ''}';
    final symbol = symbols[code] ?? (code.isEmpty ? r'$' : '$code ');
    return '$symbol${amount.toStringAsFixed(2)}';
  }

  void _say(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  void _back() {
    final router = GoRouter.of(context);
    if (router.canPop()) {
      router.pop();
    } else {
      router.goNamed('ProfilePage');
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

    Widget content;
    if (household.isEmpty) {
      content = _message(t, Icons.group_outlined, 'No household yet.',
          'Create or join a household first.', null);
    } else if (_loading) {
      content = Column(children: [
        for (var i = 0; i < 3; i++) ...[
          Container(
            height: 92,
            decoration: BoxDecoration(
                color: _sage, borderRadius: BorderRadius.circular(20)),
          ),
          const SizedBox(height: 12),
        ],
      ]);
    } else if (_notReady) {
      content = _message(t, Icons.construction_outlined,
          'Receipts are almost ready.', 'Try again soon.', () => _load(_for));
    } else if (_offline) {
      content = _message(
          t,
          Icons.cloud_off_outlined,
          'Can’t reach your receipts.',
          'No signal, or the connection dropped. Try again when you are back online.',
          () => _load(_for));
    } else if (_receipts.isEmpty) {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _message(
          t,
          Icons.receipt_long_outlined,
          'No receipts yet.',
          'Scan a receipt from the Scan tab. Once its food is added, it shows here with the shop, the date and what you paid.',
          null),
          const SizedBox(height: 14),
          _UButton('Scan a receipt',
              icon: Icons.receipt_long_outlined,
              onTap: () => context.pushNamed('CameraPage',
                  queryParameters: {'mode': 'receipt'})),
        ],
      );
    } else {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final r in _receipts) ...[
            _row(t, r),
            const SizedBox(height: 12),
          ],
        ],
      );
    }

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Semantics(
                button: true,
                label: 'Back',
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: _back,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: _uBackDeco(),
                    child: const Icon(Icons.arrow_back, color: _uForest, size: 22),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Receipts.',
                style: t.headlineMedium.copyWith(
                    fontSize: 32, fontWeight: FontWeight.w800, color: _uForest)),
            const SizedBox(height: 4),
            Text(
                _receipts.isEmpty
                    ? 'What your household bought, shop by shop.'
                    : (_receipts.length == 1
                        ? '1 receipt, shared with your household.'
                        : '${_receipts.length} receipts, shared with your household.'),
                style: t.bodyLarge.copyWith(color: _muted, fontSize: 16)),
            const SizedBox(height: 20),
            content,
          ],
        ),
      ),
    );
  }

  Widget _row(FlutterFlowTheme t, Map r) {
    final shop = '${r['shop_name'] ?? ''}'.trim();
    final place = '${r['shop_location'] ?? ''}'.trim();
    final bought = _when(r['purchased_at']);
    final count = r['item_count'] is num ? (r['item_count'] as num).round() : 0;
    final total = _money(r['total_amount'], r['currency']);
    return Semantics(
      button: true,
      label: shop.isEmpty ? 'Receipt' : shop,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _open(t, r),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: _uCard(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    color: _sage, borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.receipt_long_outlined,
                    color: _forest, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(shop.isEmpty ? 'Shop not read' : shop,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: t.bodyLarge.copyWith(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: _ink)),
                    if (place.isNotEmpty)
                      Text(place,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: t.bodyMedium
                              .copyWith(color: _muted, fontSize: 14)),
                    Text(
                        bought.isEmpty
                            ? 'Purchase time not read'
                            : 'Bought $bought',
                        style:
                            t.bodyMedium.copyWith(color: _ink, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(
                        [
                          count == 1 ? '1 item' : '$count items',
                          if (total.isNotEmpty) total,
                          'scanned ${_when(r['scanned_at'], time: false)}',
                        ].join(' · '),
                        style:
                            t.bodySmall.copyWith(color: _muted, fontSize: 13)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: _muted),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _open(FlutterFlowTheme t, Map r) async {
    List<Map> lines = const [];
    final state = <String, String>{};
    final noPhoto = <(String, String)>[];
    try {
      final rows = await SupaFlow.client
          .from('receipt_items')
          .select('name, quantity, unit_price, line_total, food_item_id')
          .eq('receipt_id', r['id'].toString())
          .order('created_at');
      lines = [for (final x in rows as List) x as Map];
      final ids = [
        for (final l in lines)
          if (l['food_item_id'] != null) l['food_item_id'].toString()
      ];
      if (ids.isNotEmpty) {
        final foods = await SupaFlow.client
            .from('food_items')
            .select('id, status, name, image_url')
            .inFilter('id', ids);
        for (final f in foods as List) {
          final m = f as Map;
          state[m['id'].toString()] = '${m['status'] ?? ''}';
          final gone = m['status'] == 'consumed' || m['status'] == 'discarded';
          if (!gone && '${m['image_url'] ?? ''}'.trim().isEmpty) {
            noPhoto.add((m['id'].toString(), '${m['name'] ?? ''}'));
          }
        }
      }
    } catch (_) {
      if (mounted) _say('Could not open this receipt. Check your signal.');
      return;
    }
    if (!mounted) return;
    final shop = '${r['shop_name'] ?? ''}'.trim();
    final place = '${r['shop_location'] ?? ''}'.trim();
    final total = _money(r['total_amount'], r['currency']);
    final remove = await showModalBottomSheet<Object>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _cream,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheet) => ConstrainedBox(
        constraints:
            BoxConstraints(maxHeight: MediaQuery.of(sheet).size.height * 0.88),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(shop.isEmpty ? 'Receipt' : shop,
                    style: t.headlineSmall.copyWith(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: _ink)),
                if (place.isNotEmpty)
                  Text(place,
                      style: t.bodyLarge.copyWith(color: _muted, fontSize: 16)),
                const SizedBox(height: 4),
                Text(
                    [
                      if (_when(r['purchased_at']).isNotEmpty)
                        'Bought ${_when(r['purchased_at'])}',
                      'Scanned ${_when(r['scanned_at'])}',
                    ].join(' · '),
                    style: t.bodyMedium.copyWith(color: _muted, fontSize: 14)),
                const SizedBox(height: 16),
                Container(
                  decoration: _uCard(16),
                  child: Column(
                    children: [
                      for (var i = 0; i < lines.length; i++) ...[
                        if (i > 0)
                          const Divider(
                              height: 1, thickness: 1, color: _border),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                        '${lines[i]['quantity'] is num && (lines[i]['quantity'] as num) > 1 ? '${(lines[i]['quantity'] as num).round()} × ' : ''}${lines[i]['name']}',
                                        style: t.bodyLarge.copyWith(
                                            fontSize: 16, color: _ink)),
                                    Text(
                                        _fate(state[
                                            '${lines[i]['food_item_id']}']),
                                        style: t.bodySmall.copyWith(
                                            color: _muted, fontSize: 13)),
                                  ],
                                ),
                              ),
                              Text(
                                  _money(lines[i]['line_total'], r['currency']),
                                  style: t.bodyLarge.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: _ink)),
                            ],
                          ),
                        ),
                      ],
                      if (lines.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(14),
                          child: Text('No lines kept for this receipt.',
                              style: t.bodyMedium.copyWith(color: _muted)),
                        ),
                    ],
                  ),
                ),
                if (total.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text('Receipt total',
                            style: t.bodyLarge.copyWith(
                                fontWeight: FontWeight.w700, color: _ink)),
                      ),
                      Text(total,
                          style: t.titleMedium.copyWith(
                              fontWeight: FontWeight.w800, color: _ink)),
                    ],
                  ),
                  Text(
                      'The total includes anything on the receipt that was not food.',
                      style: t.bodySmall.copyWith(color: _muted, fontSize: 13)),
                ],
                if (noPhoto.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 52,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _forest,
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: _forest),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () => Navigator.of(sheet).pop('photos'),
                      icon: const Icon(Icons.travel_explore, size: 20),
                      label: Text(
                          noPhoto.length == 1
                              ? 'Find the product photo for 1 food'
                              : 'Find product photos for ${noPhoto.length} foods',
                          style: t.bodyLarge.copyWith(
                              color: _forest, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                TextButton.icon(
                  style: TextButton.styleFrom(
                      minimumSize: const Size(48, 48), foregroundColor: _red),
                  onPressed: () => Navigator.of(sheet).pop(true),
                  icon: const Icon(Icons.delete_outline, size: 20),
                  label: Text('Delete this receipt',
                      style: t.bodyLarge
                          .copyWith(color: _red, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (remove == 'photos' && mounted) {
      // One food at a time; closing a sheet skips that food.
      var added = 0;
      for (final (id, name) in noPhoto) {
        if (!mounted) return;
        final used = await showModalBottomSheet<bool>(
          context: context,
          isScrollControlled: true,
          backgroundColor: _cream,
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          builder: (sheet) => ConstrainedBox(
            constraints: BoxConstraints(
                maxHeight: MediaQuery.of(sheet).size.height * 0.9),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                    20, 20, 20, 20 + MediaQuery.of(sheet).viewInsets.bottom),
                child: ProductPhotoPicker(itemId: id, foodName: name),
              ),
            ),
          ),
        );
        if (used == true) added++;
      }
      if (mounted && noPhoto.length > 1) {
        _say(added == 0
            ? 'No photos added.'
            : (added == 1 ? '1 photo added.' : '$added photos added.'));
      }
      return;
    }
    if (remove != true || !mounted) return;
    final sure = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Delete this receipt?'),
        content: const Text(
            'The record of this shop goes for everyone in your household. The food stays in your kitchen.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(d).pop(false),
              child: const Text('Keep it')),
          TextButton(
              onPressed: () => Navigator.of(d).pop(true),
              child: const Text('Delete', style: TextStyle(color: _red))),
        ],
      ),
    );
    if (sure != true || !mounted) return;
    try {
      await SupaFlow.client
          .from('receipts')
          .delete()
          .eq('id', r['id'].toString());
      await _load(_for, quiet: true);
      if (mounted) _say('Receipt deleted. The food is still in your kitchen.');
    } catch (_) {
      if (mounted) _say('Could not delete it. Check your signal.');
    }
  }

  static String _fate(String? status) {
    switch (status) {
      case null:
        return 'Not added to the kitchen';
      case 'consumed':
        return 'Used';
      case 'discarded':
        return 'Thrown out';
      default:
        return 'In your kitchen';
    }
  }

  Widget _message(FlutterFlowTheme t, IconData icon, String title, String text,
      VoidCallback? retry) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: _uCard(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: _sage, borderRadius: BorderRadius.circular(16)),
            child: Icon(icon, color: _forest, size: 28),
          ),
          const SizedBox(height: 16),
          Text(title,
              style: t.titleLarge.copyWith(
                  fontSize: 22, fontWeight: FontWeight.w800, color: _ink)),
          const SizedBox(height: 6),
          Text(text,
              style: t.bodyLarge
                  .copyWith(fontSize: 16, color: _muted, height: 1.4)),
          if (retry != null) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                style: FilledButton.styleFrom(
  elevation: 3,
  shadowColor: const Color(0x99033C29),
                  backgroundColor: _forest,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: retry,
                child: Text('Try again',
                    style: t.bodyLarge.copyWith(
                        color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ],
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

const _wShoppingListLive = r'''
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// The shopping list, shared and live.
class ShoppingListLive extends StatefulWidget {
  const ShoppingListLive({super.key, this.width, this.height});

  final double? width;
  final double? height;

  @override
  State<ShoppingListLive> createState() => _ShoppingListLiveState();
}

class _ShoppingListLiveState extends State<ShoppingListLive> {
  static const _forest = Color(0xFF07533A);
  static const _ink = Color(0xFF202C24);
  static const _muted = Color(0xFF59665D);
  static const _sage = Color(0xFFEDF2E8);
  static const _border = Color(0xFFDCE3D7);

  String _for = '';
  String _listId = '';
  bool _loading = true;
  bool _offline = false;
  bool _adding = false;
  bool _basketBusy = false;
  List<Map<String, dynamic>> _items = const [];
  List<String> _again = const [];
  final Set<String> _busy = {};
  final _field = TextEditingController();
  RealtimeChannel? _channel;

  @override
  void dispose() {
    _field.dispose();
    _unsubscribe();
    super.dispose();
  }

  void _unsubscribe() {
    final c = _channel;
    _channel = null;
    if (c != null) SupaFlow.client.removeChannel(c);
  }

  void _subscribe(String listId) {
    _unsubscribe();
    _channel = SupaFlow.client
        .channel('shopping-$listId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'shopping_list_items',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'shopping_list_id',
            value: listId,
          ),
          callback: (_) {
            if (mounted) _load(quiet: true);
          },
        )
        .subscribe();
  }

  Future<void> _load({bool quiet = false}) async {
    final household = _for;
    if (household.isEmpty) return;
    if (!quiet && mounted) {
      setState(() {
        _loading = true;
        _offline = false;
      });
    }
    try {
      if (_listId.isEmpty) {
        // Creating a household seeds exactly one list, so the oldest is the one.
        final lists = await SupaFlow.client
            .from('shopping_lists')
            .select('id')
            .eq('household_id', household)
            .order('created_at')
            .limit(1);
        if ((lists as List).isNotEmpty) {
          _listId = lists.first['id'].toString();
          _subscribe(_listId);
        }
      }
      var items = <Map<String, dynamic>>[];
      if (_listId.isNotEmpty) {
        final rows = await SupaFlow.client
            .from('shopping_list_items')
            .select('id, name, is_purchased, created_at')
            .eq('shopping_list_id', _listId)
            .order('is_purchased', ascending: true)
            .order('created_at', ascending: true);
        items = List<Map<String, dynamic>>.from(rows as List);
      }
      // What ran out lately and is not on the list already.
      var again = <String>[];
      try {
        final since = DateTime.now()
            .toUtc()
            .subtract(const Duration(days: 21))
            .toIso8601String();
        final gone = await SupaFlow.client
            .from('food_items')
            .select('name, archived_at')
            .eq('household_id', household)
            .inFilter('status', ['consumed', 'discarded'])
            .gte('archived_at', since)
            .order('archived_at', ascending: false)
            .limit(60);
        final onList = items
            .map((i) => (i['name'] ?? '').toString().trim().toLowerCase())
            .toSet();
        final seen = <String>{};
        for (final g in gone as List) {
          final name = (g['name'] ?? '').toString().trim();
          final key = name.toLowerCase();
          if (name.isEmpty || onList.contains(key) || !seen.add(key)) continue;
          again.add(name);
          if (again.length >= 8) break;
        }
      } catch (_) {
        // Suggestions are a nicety; the list still works without them.
      }
      if (!mounted || household != _for) return;
      setState(() {
        _items = items;
        _again = again;
        _loading = false;
        _offline = false;
      });
    } catch (_) {
      if (!mounted) return;
      if (quiet && _items.isNotEmpty) return;
      setState(() {
        _loading = false;
        _offline = true;
      });
    }
  }

  void _say(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> _add([String? name]) async {
    final text = (name ?? _field.text).trim();
    if (text.isEmpty) {
      _say('Type something to add first.');
      return;
    }
    if (_adding) return;
    setState(() => _adding = true);
    final said = await addNameToShoppingList(text);
    if (!mounted) return;
    setState(() => _adding = false);
    if (said.isNotEmpty) {
      _say(said);
      return;
    }
    if (name == null) _field.clear();
    _load(quiet: true);
  }

  Future<void> _tick(Map<String, dynamic> item) async {
    final id = item['id'].toString();
    if (_busy.contains(id)) return;
    final now = item['is_purchased'] == true;
    setState(() {
      _busy.add(id);
      item['is_purchased'] = !now;
    });
    try {
      await SupaFlow.client
          .from('shopping_list_items')
          .update({'is_purchased': !now}).eq('id', id);
    } catch (_) {
      if (mounted) {
        setState(() => item['is_purchased'] = now);
        _say('Could not update the list. Check your signal and try again.');
      }
    } finally {
      if (mounted) setState(() => _busy.remove(id));
      _load(quiet: true);
    }
  }

  Future<void> _remove(Map<String, dynamic> item) async {
    final id = item['id'].toString();
    if (_busy.contains(id)) return;
    setState(() => _busy.add(id));
    try {
      await SupaFlow.client.from('shopping_list_items').delete().eq('id', id);
      if (mounted) {
        setState(() =>
            _items = _items.where((i) => i['id'].toString() != id).toList());
      }
    } catch (_) {
      if (mounted)
        _say('Could not remove it. Check your signal and try again.');
    } finally {
      if (mounted) setState(() => _busy.remove(id));
      _load(quiet: true);
    }
  }

  Future<void> _basket() async {
    if (_basketBusy) return;
    setState(() => _basketBusy = true);
    final said = await addBasketToKitchen();
    if (!mounted) return;
    setState(() => _basketBusy = false);
    _say(said.isEmpty ? 'Added to your kitchen.' : said);
    _load(quiet: true);
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();
    final t = FlutterFlowTheme.of(context);
    final household = FFAppState().currentHouseholdId;
    if (household.isNotEmpty && household != _for) {
      _for = household;
      _listId = '';
      _unsubscribe();
      WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    }

    final toBuy = _items.where((i) => i['is_purchased'] != true).toList();
    final inBasket = _items.where((i) => i['is_purchased'] == true).toList();

    return SizedBox(
      width: widget.width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!_loading && !_offline)
            Text(
              toBuy.isEmpty
                  ? (inBasket.isEmpty
                      ? 'Nothing on it yet'
                      : 'Everything is in the basket')
                  : '${toBuy.length} to buy${inBasket.isEmpty ? '' : ' · ${inBasket.length} in the basket'}',
              style: t.bodyLarge.copyWith(color: _muted, fontSize: 16),
            ),
          const SizedBox(height: 16),
          // Add a line.
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _field,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _add(),
                  style: t.bodyLarge.copyWith(fontSize: 16, color: _ink),
                  decoration: InputDecoration(
                    labelText: 'Add something',
                    hintText: 'Milk, bin bags, coffee…',
                    filled: true,
                    fillColor: const Color(0xFFFFFDF7),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: _border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: _border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: _forest, width: 1.5),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 52,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
  elevation: 3,
  shadowColor: const Color(0x99033C29),
                backgroundColor: _forest,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: _adding ? null : () => _add(),
              icon: const Icon(Icons.add, size: 20),
              label: Text('Add to the list',
                  style: t.bodyLarge.copyWith(
                      color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ),
          if (_again.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text('Buy again?',
                style: t.titleLarge.copyWith(
                    fontSize: 20, fontWeight: FontWeight.w800, color: _ink)),
            const SizedBox(height: 4),
            Text('Used up or thrown out lately. Tap to add.',
                style: t.bodyMedium.copyWith(color: _muted, fontSize: 14)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final name in _again)
                  Semantics(
                    button: true,
                    label: 'Add $name to the list',
                    child: InkWell(
                      borderRadius: BorderRadius.circular(999),
                      onTap: _adding ? null : () => _add(name),
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 44),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: _sage,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.add, size: 16, color: _forest),
                            const SizedBox(width: 4),
                            Text(name,
                                style: t.bodyMedium.copyWith(
                                    color: _forest,
                                    fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 24),
          if (_loading)
            Column(children: [
              for (var i = 0; i < 3; i++) ...[
                Container(
                  height: 56,
                  decoration: BoxDecoration(
                      color: _sage, borderRadius: BorderRadius.circular(14)),
                ),
                const SizedBox(height: 8),
              ],
            ])
          else if (_offline)
            _note(t, Icons.cloud_off_outlined, 'Can’t reach your list.',
                'No signal, or the connection dropped. It will show again when you are back online.')
          else if (_items.isEmpty)
            _note(t, Icons.shopping_basket_outlined, 'Nothing to buy yet.',
                'Add what you have run out of, and it will be here when you are at the shops.')
          else ...[
            if (toBuy.isNotEmpty) _group(t, toBuy),
            if (inBasket.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text('In the basket',
                  style: t.titleMedium.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: _muted)),
              const SizedBox(height: 8),
              _group(t, inBasket),
            ],
            const SizedBox(height: 20),
            SizedBox(
              height: 52,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: _forest,
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: _forest),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _basketBusy ? null : _basket,
                icon: const Icon(Icons.kitchen_outlined, size: 20),
                label: Text('Put the basket in my kitchen',
                    style: t.bodyLarge
                        .copyWith(color: _forest, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _group(FlutterFlowTheme t, List<Map<String, dynamic>> items) {
    return Container(
      decoration: _uCard(20),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0)
              const Divider(
                  height: 1, thickness: 1, indent: 56, color: _border),
            _line(t, items[i]),
          ],
        ],
      ),
    );
  }

  Widget _line(FlutterFlowTheme t, Map<String, dynamic> item) {
    final done = item['is_purchased'] == true;
    final name = (item['name'] ?? '').toString();
    return Semantics(
      checked: done,
      label: name,
      child: InkWell(
        onTap: () => _tick(item),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 4, 4, 4),
            child: Row(
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 150),
                  child: Icon(
                    done ? Icons.check_circle : Icons.radio_button_unchecked,
                    key: ValueKey(done),
                    color: done ? _forest : _muted,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(name,
                      style: t.bodyLarge.copyWith(
                        fontSize: 16,
                        color: done ? _muted : _ink,
                        fontWeight: done ? FontWeight.w400 : FontWeight.w600,
                        decoration: done ? TextDecoration.lineThrough : null,
                      )),
                ),
                IconButton(
                  tooltip: 'Remove $name',
                  constraints:
                      const BoxConstraints(minWidth: 48, minHeight: 48),
                  onPressed: () => _remove(item),
                  icon: const Icon(Icons.close, color: _muted, size: 20),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _note(FlutterFlowTheme t, IconData icon, String title, String text) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _uCard(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: _sage, borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: _forest),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: t.titleMedium.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: _ink)),
                const SizedBox(height: 4),
                Text(text,
                    style: t.bodyMedium.copyWith(color: _muted, fontSize: 14)),
              ],
            ),
          ),
        ],
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

const _wStorageLocationsLive = r'''
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Where this household keeps food.
class StorageLocationsLive extends StatefulWidget {
  const StorageLocationsLive({super.key, this.width, this.height});

  final double? width;
  final double? height;

  @override
  State<StorageLocationsLive> createState() => _StorageLocationsLiveState();
}

class _StorageLocationsLiveState extends State<StorageLocationsLive> {
  static const _forest = Color(0xFF07533A);
  static const _ink = Color(0xFF202C24);
  static const _muted = Color(0xFF59665D);
  static const _sage = Color(0xFFEDF2E8);
  static const _border = Color(0xFFDCE3D7);

  static const _types = <String, String>{
    'fridge': 'Fridge',
    'freezer': 'Freezer',
    'pantry': 'Pantry',
    'other': 'Somewhere else',
  };

  String _for = '';
  bool _loading = true;
  bool _offline = false;
  bool _adding = false;
  List<Map<String, dynamic>> _places = const [];
  Map<String, int> _counts = const {};
  final _name = TextEditingController();
  String _type = 'other';

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _load({bool quiet = false}) async {
    final household = _for;
    if (household.isEmpty) return;
    if (!quiet && mounted) {
      setState(() {
        _loading = true;
        _offline = false;
      });
    }
    try {
      final rows = await SupaFlow.client
          .from('storage_locations')
          .select('id, name, location_type, is_default')
          .eq('household_id', household)
          .order('location_type')
          .order('name');
      final kept = await SupaFlow.client
          .from('food_items_status')
          .select('storage_location_id')
          .eq('household_id', household);
      final counts = <String, int>{};
      for (final k in kept as List) {
        final id = (k['storage_location_id'] ?? '').toString();
        if (id.isNotEmpty) counts[id] = (counts[id] ?? 0) + 1;
      }
      if (!mounted || household != _for) return;
      setState(() {
        _places = List<Map<String, dynamic>>.from(rows as List);
        _counts = counts;
        _loading = false;
        _offline = false;
      });
    } catch (_) {
      if (!mounted) return;
      if (quiet && _places.isNotEmpty) return;
      setState(() {
        _loading = false;
        _offline = true;
      });
    }
  }

  void _say(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> _add() async {
    if (_adding) return;
    setState(() => _adding = true);
    final said = await addStorageLocation(_name.text, _type);
    if (!mounted) return;
    setState(() => _adding = false);
    if (said.isNotEmpty) {
      _say(said);
      return;
    }
    _name.clear();
    _say('Location added.');
    _load(quiet: true);
  }

  Future<void> _remove(Map<String, dynamic> place) async {
    final id = place['id'].toString();
    final name = (place['name'] ?? '').toString();
    final n = _counts[id] ?? 0;
    final sure = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Remove $name?'),
        content: Text(n == 0
            ? 'Nothing is kept there at the moment.'
            : (n == 1
                ? 'The 1 food kept there stays in your kitchen, with no place recorded.'
                : 'The $n foods kept there stay in your kitchen, with no place recorded.')),
        actions: [
          TextButton(
            style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
            onPressed: () => Navigator.of(dialog).pop(false),
            child: const Text('Keep it'),
          ),
          TextButton(
            style: TextButton.styleFrom(
                minimumSize: const Size(48, 48),
                foregroundColor: const Color(0xFFB42318)),
            onPressed: () => Navigator.of(dialog).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (sure != true || !mounted) return;
    try {
      await SupaFlow.client.from('storage_locations').delete().eq('id', id);
      _say('$name removed.');
    } catch (_) {
      _say('Could not remove it. Check your signal and try again.');
    }
    _load(quiet: true);
  }

  static IconData _icon(String type) {
    switch (type) {
      case 'fridge':
        return Icons.kitchen_outlined;
      case 'freezer':
        return Icons.ac_unit;
      case 'pantry':
        return Icons.inventory_2_outlined;
      default:
        return Icons.shelves;
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();
    final t = FlutterFlowTheme.of(context);
    final household = FFAppState().currentHouseholdId;
    if (household.isNotEmpty && household != _for) {
      _for = household;
      WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    }

    Widget list;
    if (_loading) {
      list = Column(children: [
        for (var i = 0; i < 3; i++) ...[
          Container(
            height: 64,
            decoration: BoxDecoration(
                color: _sage, borderRadius: BorderRadius.circular(14)),
          ),
          const SizedBox(height: 8),
        ],
      ]);
    } else if (_offline) {
      list = Text(
          'Can’t reach your kitchen. Your places will show when you are back online.',
          style: t.bodyLarge.copyWith(color: _muted));
    } else if (_places.isEmpty) {
      list = Text('No places yet. Add where you keep food below.',
          style: t.bodyLarge.copyWith(color: _muted));
    } else {
      list = Container(
        decoration: _uCard(20),
        child: Column(
          children: [
            for (var i = 0; i < _places.length; i++) ...[
              if (i > 0)
                const Divider(
                    height: 1, thickness: 1, indent: 64, color: _border),
              _row(t, _places[i]),
            ],
          ],
        ),
      );
    }

    return SizedBox(
      width: widget.width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          list,
          const SizedBox(height: 28),
          Text('Add a location',
              style: t.titleLarge.copyWith(
                  fontSize: 20, fontWeight: FontWeight.w800, color: _ink)),
          const SizedBox(height: 12),
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.sentences,
            style: t.bodyLarge.copyWith(fontSize: 16, color: _ink),
            decoration: InputDecoration(
              labelText: 'Name',
              hintText: 'Garage freezer, fruit bowl…',
              filled: true,
              fillColor: const Color(0xFFFFFDF7),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: _border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: _border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: _forest, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text('Type',
              style: t.bodyMedium.copyWith(
                  fontSize: 14, fontWeight: FontWeight.w700, color: _muted)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final e in _types.entries)
                Semantics(
                  button: true,
                  selected: _type == e.key,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: () => setState(() => _type = e.key),
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 44),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: _type == e.key ? _forest : Colors.white,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                            color: _type == e.key ? _forest : _border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_icon(e.key),
                              size: 18,
                              color: _type == e.key ? Colors.white : _forest),
                          const SizedBox(width: 6),
                          Text(e.value,
                              style: t.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: _type == e.key ? Colors.white : _ink)),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 52,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
  elevation: 3,
  shadowColor: const Color(0x99033C29),
                backgroundColor: _forest,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: _adding ? null : _add,
              icon: const Icon(Icons.add, size: 20),
              label: Text('Add location',
                  style: t.bodyLarge.copyWith(
                      color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _row(FlutterFlowTheme t, Map<String, dynamic> place) {
    final id = place['id'].toString();
    final name = (place['name'] ?? '').toString();
    final type = (place['location_type'] ?? '').toString();
    final n = _counts[id] ?? 0;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 64),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  color: _sage, borderRadius: BorderRadius.circular(12)),
              child: Icon(_icon(type), color: _forest, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: t.bodyLarge.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _ink)),
                  Text(
                    '${_types[type] ?? 'Somewhere else'} · ${n == 1 ? '1 food' : '$n foods'}',
                    style: t.bodySmall.copyWith(color: _muted, fontSize: 13),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Remove $name',
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              onPressed: () => _remove(place),
              icon: const Icon(Icons.delete_outline, color: _muted),
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

const _wRemindersSettings = r'''
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
      _note =
          'Can’t reach your settings right now. What you see are the defaults.';
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
            decoration: BoxDecoration(
                color: _sage, borderRadius: BorderRadius.circular(16)),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: _uCard(20),
                child: Row(
                  children: [
                    Icon(
                        _on
                            ? Icons.notifications_active_outlined
                            : Icons.notifications_off_outlined,
                        color: _forest,
                        size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text('Remind me before food goes off',
                          style: t.bodyLarge.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: _ink)),
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
            Text(_note,
                style: t.bodyMedium.copyWith(color: _muted, fontSize: 14)),
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
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _muted)),
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
                        const Icon(Icons.info_outline,
                            color: _forest, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                              'One note at 10am on the day, naming the foods that are $_days ${_days == 1 ? 'day' : 'days'} from their date. Tap it to mark what you used.',
                              style: t.bodyMedium.copyWith(
                                  color: _ink, fontSize: 14, height: 1.4)),
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
  elevation: 3,
  shadowColor: const Color(0x99033C29),
                backgroundColor: _forest,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: _saving ? null : () => _save(announce: true),
              child: Text('Save reminders',
                  style: t.bodyLarge.copyWith(
                      color: Colors.white, fontWeight: FontWeight.w700)),
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
                  fontWeight: FontWeight.w800,
                  color: on ? Colors.white : _ink)),
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

const _wFoodPreferences = r'''
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Diets and allergies, saved to the profile and turned into words that meal
/// ideas leave out.
///
/// A diet here is a list of ingredients to avoid, not a badge: the app never
/// says a dish is vegan, it just does not build one from meat. The words are
/// blunt on purpose — "milk" also catches "buttermilk" — because leaving too
/// much out is a smaller harm than leaving in what someone cannot eat.
class FoodPreferences extends StatefulWidget {
  const FoodPreferences({super.key, this.width, this.height});

  final double? width;
  final double? height;

  @override
  State<FoodPreferences> createState() => _FoodPreferencesState();
}

class _FoodPreferencesState extends State<FoodPreferences> {
  static const _diets = <String, String>{
    'vegetarian': 'Vegetarian',
    'vegan': 'Vegan',
    'pescatarian': 'Pescatarian',
    'halal': 'Halal',
    'kosher': 'Kosher',
  };

  static const _dietWords = <String, List<String>>{
    'vegetarian': [
      'meat',
      'chicken',
      'turkey',
      'beef',
      'pork',
      'lamb',
      'bacon',
      'ham',
      'sausage',
      'fish',
      'salmon',
      'tuna',
      'prawn',
      'shellfish',
      'gelatine',
    ],
    'vegan': [
      'meat',
      'chicken',
      'turkey',
      'beef',
      'pork',
      'lamb',
      'bacon',
      'ham',
      'sausage',
      'fish',
      'salmon',
      'tuna',
      'prawn',
      'shellfish',
      'gelatine',
      'milk',
      'cheese',
      'butter',
      'cream',
      'yoghurt',
      'yogurt',
      'egg',
      'honey',
    ],
    'pescatarian': [
      'meat',
      'chicken',
      'turkey',
      'beef',
      'pork',
      'lamb',
      'bacon',
      'ham',
      'sausage',
    ],
    'halal': ['pork', 'bacon', 'ham', 'gelatine', 'wine', 'beer', 'alcohol'],
    'kosher': ['pork', 'bacon', 'ham', 'shellfish', 'prawn', 'squid'],
  };

  final Set<String> _chosen = {};
  final TextEditingController _allergies = TextEditingController();
  bool _loaded = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _allergies.dispose();
    super.dispose();
  }

  static List<String> _asWords(Object? value) {
    if (value is List) {
      return [
        for (final w in value)
          if ('$w'.trim().isNotEmpty) '$w'.trim(),
      ];
    }
    return const [];
  }

  Future<void> _load() async {
    final uid = SupaFlow.client.auth.currentUser?.id;
    if (uid == null) return;
    try {
      final row = await SupaFlow.client
          .from('profiles')
          .select('dietary_preferences, allergens')
          .eq('id', uid)
          .maybeSingle();
      if (!mounted || row == null) return;
      setState(() {
        _chosen
          ..clear()
          ..addAll(
              _asWords(row['dietary_preferences']).where(_diets.containsKey));
        _allergies.text = _asWords(row['allergens']).join(', ');
        _loaded = true;
      });
    } catch (_) {
      if (mounted) setState(() => _loaded = true);
    }
  }

  List<String> get _allergyWords => _allergies.text
      .split(RegExp(r'[,;\n]'))
      .map((w) => w.replaceAll(RegExp(r'\s+'), ' ').trim().toLowerCase())
      .where((w) => w.length >= 2)
      .toList();

  /// Everything the ideas should leave out: the allergies first, because they
  /// are the ones that matter most, then whatever the diets add.
  String get _avoid {
    final all = <String>[];
    for (final w in _allergyWords) {
      if (!all.contains(w)) all.add(w);
    }
    for (final diet in _chosen) {
      for (final w in _dietWords[diet] ?? const <String>[]) {
        if (!all.contains(w)) all.add(w);
      }
    }
    return all.join(', ');
  }

  Future<void> _save() async {
    final uid = SupaFlow.client.auth.currentUser?.id;
    if (uid == null || _saving) return;
    setState(() => _saving = true);
    var problem = '';
    try {
      await SupaFlow.client.from('profiles').update({
        'dietary_preferences': _chosen.toList(),
        'allergens': _allergyWords,
      }).eq('id', uid);
    } on PostgrestException catch (error) {
      problem = error.message;
    } catch (_) {
      problem = 'Could not save. Check your signal and try again.';
    }
    final avoid = _avoid;
    if (problem.isEmpty) {
      FFAppState().update(() => FFAppState().ideasAvoid = avoid);
    }
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(problem.isEmpty
          ? (avoid.isEmpty
              ? 'Saved. Ideas can use anything in your kitchen.'
              : 'Saved. Ideas will leave those out.')
          : problem),
    ));
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();
    final t = FlutterFlowTheme.of(context);
    final avoid = _avoid;

    return SizedBox(
      width: widget.width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _label(t, 'Allergies'),
          TextField(
            controller: _allergies,
            minLines: 1,
            maxLines: 3,
            textCapitalization: TextCapitalization.none,
            decoration: InputDecoration(
              hintText: 'Peanuts, sesame, shellfish…',
              isDense: true,
              filled: true,
              fillColor: t.secondaryBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: t.alternate),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: t.alternate),
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          _label(t, 'Diet'),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final e in _diets.entries)
                _chip(t, e.value, _chosen.contains(e.key), () {
                  setState(() => _chosen.contains(e.key)
                      ? _chosen.remove(e.key)
                      : _chosen.add(e.key));
                }),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              color: t.accent1,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'This is not a medical check.',
                  style: t.bodyMedium.copyWith(
                      color: t.primaryText, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ideas leave these foods out, but an idea is written by a '
                  'machine from the names of your food. Read the label on '
                  'anything you cook with, every time.',
                  style: t.bodySmall.copyWith(color: t.primaryText),
                ),
              ],
            ),
          ),
          if (_loaded && avoid.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              'Left out of ideas: $avoid',
              style: t.bodySmall.copyWith(color: t.secondaryText),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            height: 50,
            child: FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
  elevation: 3,
  shadowColor: const Color(0x99033C29),
                backgroundColor: t.primary,
                foregroundColor: t.secondaryBackground,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(_saving ? 'Saving…' : 'Save'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(FlutterFlowTheme t, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text,
          style: t.bodySmall
              .copyWith(color: t.secondaryText, fontWeight: FontWeight.w700),
        ),
      );

  Widget _chip(FlutterFlowTheme t, String text, bool on, VoidCallback onTap) =>
      Semantics(
        button: true,
        selected: on,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 40),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: on ? t.primary : t.secondaryBackground,
              border: Border.all(color: on ? t.primary : t.alternate),
            ),
            child: Text(
              text,
              style: t.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                color: on ? Colors.white : t.primaryText,
              ),
            ),
          ),
        ),
      );
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

const _wProfileMenu = r'''
import 'package:flutter/material.dart';

/// Profile settings, grouped and compact.
class ProfileMenu extends StatelessWidget {
  const ProfileMenu({super.key, this.width, this.height});

  final double? width;
  final double? height;

  static const _forest = Color(0xFF07533A);
  static const _ink = Color(0xFF202C24);
  static const _muted = Color(0xFF59665D);
  static const _sage = Color(0xFFEDF2E8);
  static const _border = Color(0xFFDCE3D7);

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _group(context, t, 'You', const [
            _Row('My details', Icons.badge_outlined, 'OnboardingPage'),
            _Row('Diet & allergies', Icons.no_food_outlined,
                'FoodPreferencesPage'),
            _Row('Security', Icons.lock_outline, 'UpdatePasswordPage'),
          ]),
          const SizedBox(height: 20),
          _group(context, t, 'Kitchen', const [
            _Row('Household', Icons.group_outlined, 'HouseholdSetupPage'),
            _Row('Storage', Icons.kitchen_outlined, 'StorageLocationsPage'),
            _Row('Shopping list', Icons.shopping_cart_outlined,
                'ShoppingListPage'),
            _Row('Receipts', Icons.receipt_long_outlined, 'ReceiptsPage'),
            _Row('Reminders', Icons.notifications_none, 'RemindersPage'),
            _Row('What you used', Icons.insights_outlined, 'WasteHistoryPage'),
          ]),
        ],
      ),
    );
  }

  Widget _group(BuildContext context, FlutterFlowTheme t, String heading,
      List<_Row> rows) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Semantics(
            header: true,
            child: Text(heading,
                style: t.bodyMedium.copyWith(
                    fontSize: 14, fontWeight: FontWeight.w700, color: _muted)),
          ),
        ),
        Container(
          decoration: _uCard(20),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < rows.length; i++) ...[
                if (i > 0)
                  const Divider(
                      height: 1, thickness: 1, indent: 64, color: _border),
                _tile(context, t, rows[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _tile(BuildContext context, FlutterFlowTheme t, _Row row) {
    return Semantics(
      button: true,
      label: row.title,
      excludeSemantics: true,
      child: InkWell(
        onTap: () => context.pushNamed(row.route),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      color: _sage, borderRadius: BorderRadius.circular(12)),
                  child: Icon(row.icon, color: _forest, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(row.title,
                      style: t.bodyLarge.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _ink)),
                ),
                const Icon(Icons.chevron_right, color: _muted, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Row {
  const _Row(this.title, this.icon, this.route);
  final String title;
  final IconData icon;
  final String route;
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

const _wReceiptHeader = r'''
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// The receipt at the top of the receipt review: shop, where, when, total.
///
/// What was read can be wrong, so "Fix" opens it for editing before the food
/// is added. Nothing shows for a shelf photo or typed food.
class ReceiptHeader extends StatefulWidget {
  const ReceiptHeader({super.key, this.width, this.height});

  final double? width;
  final double? height;

  @override
  State<ReceiptHeader> createState() => _ReceiptHeaderState();
}

class _ReceiptHeaderState extends State<ReceiptHeader> {
  static const _forest = Color(0xFF07533A);
  static const _ink = Color(0xFF202C24);
  static const _muted = Color(0xFF59665D);
  static const _sage = Color(0xFFEDF2E8);
  static const _border = Color(0xFFDCE3D7);
  static const _cream = Color(0xFFF7F7F0);

  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec'
  ];

  static Map<String, dynamic> _info() {
    try {
      final v = jsonDecode(FFAppState().scanReceipt);
      return v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  static void _write(Map<String, dynamic> info) =>
      FFAppState().update(() => FFAppState().scanReceipt = jsonEncode(info));

  static String _when(String iso) {
    final d = DateTime.tryParse(iso);
    if (d == null) return '';
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final hasTime = iso.contains('T');
    return '${_days[d.weekday - 1]} ${d.day} ${_months[d.month - 1]}'
        '${hasTime ? ', $h:${d.minute.toString().padLeft(2, '0')} ${d.hour < 12 ? 'am' : 'pm'}' : ''}';
  }

  static String _money(Object? amount, Object? currency) {
    if (amount is! num || amount <= 0) return '';
    const symbols = {
      'AUD': r'$',
      'NZD': r'$',
      'USD': r'$',
      'CAD': r'$',
      'GBP': '£',
      'EUR': '€'
    };
    final code = '${currency ?? ''}';
    return '${symbols[code] ?? (code.isEmpty ? r'$' : '$code ')}${amount.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();
    final t = FlutterFlowTheme.of(context);
    if (FFAppState().scannedFrom != 'receipt' ||
        FFAppState().scannedFoods.isEmpty) {
      return const SizedBox.shrink();
    }
    final info = _info();
    final shop = '${info['shop'] ?? ''}'.trim();
    final place = '${info['location'] ?? ''}'.trim();
    final when = _when('${info['purchasedAt'] ?? ''}');
    final total = _money(info['total'], info['currency']);
    return Container(
      width: widget.width,
      margin: const EdgeInsets.only(top: 4, bottom: 4),
      padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
      decoration: BoxDecoration(
        color: _sage,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.receipt_long_outlined, color: _forest, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(shop.isEmpty ? 'Shop not read' : shop,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.bodyLarge
                        .copyWith(fontWeight: FontWeight.w800, color: _ink)),
                Text(
                    [
                      if (place.isNotEmpty) place,
                      when.isEmpty ? 'time not read' : when,
                      if (total.isNotEmpty) total,
                    ].join(' · '),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: t.bodySmall.copyWith(color: _muted, fontSize: 13)),
              ],
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(
                minimumSize: const Size(48, 44), foregroundColor: _forest),
            onPressed: () => _fix(t, info),
            child: Text('Fix',
                style: t.bodyMedium
                    .copyWith(color: _forest, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Future<void> _fix(FlutterFlowTheme t, Map<String, dynamic> info) async {
    final shop = TextEditingController(text: '${info['shop'] ?? ''}');
    final place = TextEditingController(text: '${info['location'] ?? ''}');
    final total = TextEditingController(
        text: info['total'] is num && (info['total'] as num) > 0
            ? (info['total'] as num).toStringAsFixed(2)
            : '');
    var when = DateTime.tryParse('${info['purchasedAt'] ?? ''}');
    InputDecoration look(String label) => InputDecoration(
          labelText: label,
          filled: true,
          fillColor: const Color(0xFFFFFDF7),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _border),
          ),
        );
    final save = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _cream,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheet) => StatefulBuilder(
        builder: (sheet, redraw) => Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(sheet).viewInsets.bottom),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('The receipt',
                      style: t.headlineSmall.copyWith(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: _ink)),
                  const SizedBox(height: 16),
                  TextField(
                      controller: shop,
                      textCapitalization: TextCapitalization.words,
                      decoration: look('Shop')),
                  const SizedBox(height: 12),
                  TextField(
                      controller: place,
                      textCapitalization: TextCapitalization.words,
                      decoration: look('Where (branch or suburb)')),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      alignment: Alignment.centerLeft,
                      minimumSize: const Size(0, 56),
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: _border),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () async {
                      final now = DateTime.now();
                      final first = now.subtract(const Duration(days: 365));
                      // A misread date may be outside the range: start inside.
                      var init = when ?? now;
                      if (init.isAfter(now)) init = now;
                      if (init.isBefore(first)) init = first;
                      final day = await showDatePicker(
                        context: sheet,
                        initialDate: init,
                        firstDate: now.subtract(const Duration(days: 365)),
                        lastDate: now,
                      );
                      if (day == null) return;
                      final time = await showTimePicker(
                        context: sheet,
                        initialTime: TimeOfDay.fromDateTime(when ?? now),
                      );
                      redraw(() => when = DateTime(day.year, day.month, day.day,
                          time?.hour ?? 12, time?.minute ?? 0));
                    },
                    icon: const Icon(Icons.event, color: _forest),
                    label: Text(
                        when == null
                            ? 'When was it bought?'
                            : 'Bought ${_when(when!.toIso8601String())}',
                        style: t.bodyLarge.copyWith(color: _ink)),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                      controller: total,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: look('Total paid')),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 52,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
  elevation: 3,
  shadowColor: const Color(0x99033C29),
                        backgroundColor: _forest,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () => Navigator.of(sheet).pop(true),
                      child: Text('Save',
                          style: t.bodyLarge.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    if (save == true) {
      final amount =
          double.tryParse(total.text.replaceAll(RegExp(r'[^0-9.]'), ''));
      final d = when;
      _write({
        ...info,
        'shop': shop.text.trim(),
        'location': place.text.trim(),
        'purchasedAt': d == null
            ? ''
            : '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}T${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}',
        'total': amount == null ? 0 : (amount * 100).round() / 100,
      });
    }
    Future.delayed(const Duration(milliseconds: 500), () {
      shop.dispose();
      place.dispose();
      total.dispose();
    });
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

const _wScanLineEditor = r'''
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// One line of the scan review, fixed in place.
class ScanLineEditor extends StatefulWidget {
  const ScanLineEditor({super.key, this.width, this.height, this.lineIndex});

  final double? width;
  final double? height;
  final int? lineIndex;

  @override
  State<ScanLineEditor> createState() => _ScanLineEditorState();
}

class _ScanLineEditorState extends State<ScanLineEditor> {
  static const _forest = Color(0xFF07533A);
  static const _ink = Color(0xFF202C24);
  static const _muted = Color(0xFF59665D);
  static const _border = Color(0xFFDCE3D7);

  // The same words the category picker uses.
  static const _labels = <String, String>{
    'dairy': 'Dairy',
    'meat_poultry': 'Meat & poultry',
    'seafood': 'Seafood',
    'eggs': 'Eggs',
    'cooked_leftovers': 'Cooked leftovers',
    'fruit': 'Fruit',
    'vegetables': 'Vegetables',
    'bread_bakery': 'Bread & bakery',
    'pantry_dry': 'Pantry & dry goods',
    'frozen': 'Frozen food',
    'condiments_sauces': 'Condiments & sauces',
    'infant_food': 'Infant food & formula',
  };

  final _name = TextEditingController();
  final _price = TextEditingController();
  String _category = '';
  int _quantity = 1;
  String _place = '';
  List<Map<String, dynamic>> _places = const [];
  bool _placesLoaded = false;
  bool _started = false;

  int get _i => widget.lineIndex ?? -1;

  @override
  void initState() {
    super.initState();
    final foods = FFAppState().scannedFoods;
    if (_i >= 0 && _i < foods.length) {
      final f = foods[_i];
      _name.text = f.name;
      _category = f.category;
      _quantity = f.quantity < 1 ? 1 : f.quantity;
      _place = f.place;
      _price.text = f.price > 0 ? f.price.toStringAsFixed(2) : '';
      _started = true;
    }
    _loadPlaces();
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    super.dispose();
  }

  Future<void> _loadPlaces() async {
    final household = FFAppState().currentHouseholdId;
    if (household.isEmpty) return;
    try {
      final rows = await SupaFlow.client
          .from('storage_locations')
          .select('id, name, location_type')
          .eq('household_id', household)
          .order('location_type')
          .order('name');
      if (!mounted) return;
      setState(() {
        _places = List<Map<String, dynamic>>.from(rows as List);
        _placesLoaded = true;
      });
    } catch (_) {
      if (mounted) setState(() => _placesLoaded = true);
    }
  }

  static IconData _placeIcon(String type) {
    switch (type) {
      case 'fridge':
        return Icons.kitchen_outlined;
      case 'freezer':
        return Icons.ac_unit;
      case 'pantry':
        return Icons.inventory_2_outlined;
      default:
        return Icons.shelves;
    }
  }

  void _save() {
    final name = _name.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Give it a name first.')));
      return;
    }
    String placeName = '';
    for (final p in _places) {
      if (p['id'].toString() == _place)
        placeName = (p['name'] ?? '').toString();
    }
    final paid =
        double.tryParse(_price.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
    final price = paid > 0 ? (paid * 100).round() / 100 : 0.0;
    final detail = <String>[
      if (_quantity > 1) '$_quantity of them',
      _labels[_category] ?? 'No category',
      if (placeName.isNotEmpty) placeName,
      if (price > 0) '\$${price.toStringAsFixed(2)}',
    ].join(' · ');
    if (_i >= 0 && _i < FFAppState().scannedFoods.length) {
      FFAppState().update(() {
        FFAppState().updateScannedFoodsAtIndex(
          _i,
          (_) => ScannedFoodStruct(
            name: name[0].toUpperCase() + name.substring(1),
            category: _category,
            quantity: _quantity,
            place: _place,
            detail: detail,
            price: price,
          ),
        );
      });
    }
    GoRouter.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);
    if (!_started) {
      return Text('This line is no longer on the list.',
          style: t.bodyLarge.copyWith(color: _muted));
    }
    return SizedBox(
      width: widget.width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _label(t, 'Name'),
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.sentences,
            style: t.bodyLarge.copyWith(fontSize: 16, color: _ink),
            decoration: _box('e.g. Mandarins'),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _label(t, 'How many')),
              _stepper(Icons.remove, _quantity > 1,
                  () => setState(() => _quantity--)),
              SizedBox(
                width: 48,
                child: Text('$_quantity',
                    textAlign: TextAlign.center,
                    style: t.titleMedium.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: _ink)),
              ),
              _stepper(
                  Icons.add, _quantity < 24, () => setState(() => _quantity++)),
            ],
          ),
          const SizedBox(height: 20),
          _label(t, 'Price paid'),
          TextField(
            controller: _price,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: t.bodyLarge.copyWith(fontSize: 16, color: _ink),
            decoration: _box('Optional, for budgets'),
          ),
          const SizedBox(height: 20),
          _label(t, 'Kept in'),
          if (!_placesLoaded)
            Text('Loading your places…',
                style: t.bodyMedium.copyWith(color: _muted, fontSize: 14))
          else ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final p in _places)
                  _choice(
                    t,
                    (p['name'] ?? '').toString(),
                    _place == p['id'].toString(),
                    () => setState(() => _place = p['id'].toString()),
                    icon: _placeIcon((p['location_type'] ?? '').toString()),
                  ),
              ],
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                style: TextButton.styleFrom(
                    minimumSize: const Size(48, 48), foregroundColor: _forest),
                onPressed: () async {
                  await context.pushNamed('StorageLocationsPage');
                  if (mounted) _loadPlaces();
                },
                icon: const Icon(Icons.add, size: 18),
                label: Text('Add a place, like a fruit bowl',
                    style: t.bodyMedium
                        .copyWith(color: _forest, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
          const SizedBox(height: 12),
          _label(t, 'Category'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final e in _labels.entries)
                _choice(t, e.value, _category == e.key,
                    () => setState(() => _category = e.key)),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 52,
            child: FilledButton(
              style: FilledButton.styleFrom(
  elevation: 3,
  shadowColor: const Color(0x99033C29),
                backgroundColor: _forest,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: _save,
              child: Text('Save this line',
                  style: t.bodyLarge.copyWith(
                      color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(FlutterFlowTheme t, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: t.bodyMedium.copyWith(
                fontSize: 14, fontWeight: FontWeight.w700, color: _muted)),
      );

  InputDecoration _box(String hint) => InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFFFFDF7),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _forest, width: 1.5),
        ),
      );

  Widget _choice(FlutterFlowTheme t, String label, bool on, VoidCallback onTap,
          {IconData? icon}) =>
      Semantics(
        button: true,
        selected: on,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            constraints: const BoxConstraints(minHeight: 44),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: on ? _forest : Colors.white,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: on ? _forest : _border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18, color: on ? Colors.white : _forest),
                  const SizedBox(width: 6),
                ],
                Text(label,
                    style: t.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: on ? Colors.white : _ink)),
              ],
            ),
          ),
        ),
      );

  Widget _stepper(IconData icon, bool enabled, VoidCallback onTap) => Opacity(
        opacity: enabled ? 1 : 0.4,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: enabled ? onTap : null,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: _border),
            ),
            child: Icon(icon, color: _forest, size: 20),
          ),
        ),
      );
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
                ? '${_monthNames[chosen.start.month - 1]}: nothing finished with yet.'
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

const _wReviewSummary = r'''
import 'package:flutter/material.dart';

/// What will be recorded, as one card.
class ReviewSummary extends StatelessWidget {
  const ReviewSummary({
    super.key,
    this.width,
    this.height,
    this.foodName,
    this.category,
    this.locationLabel,
    this.printedDate,
    this.printedDateType,
  });

  final double? width;
  final double? height;
  final String? foodName;
  final String? category;
  final String? locationLabel;
  final DateTime? printedDate;
  final String? printedDateType;

  static const _forest = Color(0xFF07533A);
  static const _ink = Color(0xFF202C24);
  static const _muted = Color(0xFF59665D);
  static const _sage = Color(0xFFEDF2E8);
  static const _border = Color(0xFFDCE3D7);

  String _line(String field) =>
      reviewLine(field, foodName, category, locationLabel, printedDate,
          printedDateType) ??
      '';

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);
    final rows = <(IconData, String, String)>[
      (Icons.restaurant, 'What it is', _line('name')),
      (Icons.category_outlined, 'Category', _line('category')),
      (Icons.kitchen_outlined, 'Where it goes', _line('where')),
      (Icons.calendar_today_outlined, 'The date', _line('date')),
    ];
    final note = _line('dateNote');

    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: _uCard(20),
            child: Column(
              children: [
                for (var i = 0; i < rows.length; i++) ...[
                  if (i > 0)
                    const Divider(
                        height: 1, thickness: 1, indent: 52, color: _border),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(rows[i].$1, color: _forest, size: 20),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(rows[i].$2,
                                  style: t.bodySmall.copyWith(
                                      fontSize: 13,
                                      color: _muted,
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(height: 2),
                              Text(rows[i].$3.isEmpty ? 'Not set' : rows[i].$3,
                                  style: t.bodyLarge.copyWith(
                                      fontSize: i == 0 ? 18 : 16,
                                      fontWeight: i == 0
                                          ? FontWeight.w700
                                          : FontWeight.w400,
                                      color: _ink)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (note.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _sage,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, color: _forest, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(note,
                        style: t.bodyMedium
                            .copyWith(fontSize: 14, color: _ink, height: 1.4)),
                  ),
                ],
              ),
            ),
          ],
        ],
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

const _wProductPhotoPicker = r'''
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

/// Find the product photo for one food (owner, 14 Sep: product pictures by
/// country, "packaged differently in different countries").
///
/// Searches Open Food Facts for the food's name among products sold in the
/// person's country, shows the packs it finds, and uses the one the person
/// taps — nothing is picked for them. The chosen photo is copied into the
/// household's own storage (so the food's screen credits Open Food Facts),
/// and recorded in product_images with the country and the person's sharing
/// choice. Shown inside a bottom sheet; closes with true when a photo is used.
class ProductPhotoPicker extends StatefulWidget {
  const ProductPhotoPicker({
    super.key,
    this.width,
    this.height,
    this.itemId,
    this.foodName,
  });

  final double? width;
  final double? height;
  final String? itemId;
  final String? foodName;

  @override
  State<ProductPhotoPicker> createState() => _ProductPhotoPickerState();
}

class _ProductPhotoPickerState extends State<ProductPhotoPicker> {
  static const _forest = Color(0xFF07533A);
  static const _ink = Color(0xFF202C24);
  static const _muted = Color(0xFF59665D);
  static const _sage = Color(0xFFEDF2E8);
  static const _border = Color(0xFFDCE3D7);

  static const _countries = <String, String>{
    'AU': 'Australia',
    'NZ': 'New Zealand',
    'GB': 'the UK',
    'IE': 'Ireland',
    'US': 'the US',
    'CA': 'Canada',
    'FR': 'France',
    'DE': 'Germany',
  };

  final _query = TextEditingController();
  String _country = 'AU';
  bool _searching = false;
  bool _using = false;
  String _note = '';
  List<Map<String, String>> _found = const [];

  @override
  void initState() {
    super.initState();
    _query.text = (widget.foodName ?? '').trim();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    final uid = SupaFlow.client.auth.currentUser?.id;
    if (uid != null) {
      try {
        final p = await SupaFlow.client
            .from('profiles')
            .select('country_code')
            .eq('id', uid)
            .maybeSingle();
        final cc = '${p?['country_code'] ?? ''}'.toUpperCase();
        if (_countries.containsKey(cc)) _country = cc;
      } catch (_) {}
    }
    if (mounted) _search();
  }

  Future<void> _setCountry(String cc) async {
    setState(() => _country = cc);
    final uid = SupaFlow.client.auth.currentUser?.id;
    if (uid != null) {
      try {
        await SupaFlow.client
            .from('profiles')
            .update({'country_code': cc}).eq('id', uid);
      } catch (_) {}
    }
    _search();
  }

  Future<void> _search() async {
    if (!mounted) return;
    final q = _query.text.trim();
    if (q.isEmpty) return;
    setState(() {
      _searching = true;
      _note = '';
    });
    final url = Uri.parse(
        'https://${_country.toLowerCase()}.openfoodfacts.org/cgi/search.pl'
        '?search_terms=${Uri.encodeQueryComponent(q)}&search_simple=1'
        '&action=process&json=1&page_size=12'
        '&fields=code,product_name,brands,image_front_small_url');
    try {
      final res = await http.get(url, headers: {
        'User-Agent': 'UseItFresh/1.0 (https://useitfresh.app)',
      }).timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) throw 'status ${res.statusCode}';
      final body = json.decode(res.body);
      final products = body is Map && body['products'] is List
          ? body['products'] as List
          : const [];
      final found = <Map<String, String>>[
        for (final p in products)
          if (p is Map &&
              '${p['image_front_small_url'] ?? ''}'.startsWith('https://'))
            {
              'code': '${p['code'] ?? ''}',
              'name': '${p['product_name'] ?? ''}'.trim(),
              'brand': '${p['brands'] ?? ''}'.split(',').first.trim(),
              'image': '${p['image_front_small_url']}',
            }
      ];
      if (!mounted) return;
      setState(() {
        _found = found;
        _searching = false;
        _note = found.isEmpty
            ? 'No photos found for “$q” in ${_countries[_country]}. Try a shorter name or a brand.'
            : '';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _searching = false;
        _note = 'Could not reach the product database. Check your signal.';
      });
    }
  }

  Future<void> _use(Map<String, String> p) async {
    final id = (widget.itemId ?? '').trim();
    if (id.isEmpty || _using) return;
    setState(() => _using = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final client = SupaFlow.client;
    final storage = client.storage.from('food-images');
    String? path;
    try {
      final food = await client
          .from('food_items')
          .select('household_id, name, image_url')
          .eq('id', id)
          .single();
      final household = '${food['household_id']}';
      final small = p['image']!;
      final larger = small.replaceFirst(RegExp(r'\.200\.jpg$'), '.400.jpg');
      var res = await http
          .get(Uri.parse(larger))
          .timeout(const Duration(seconds: 12));
      if (res.statusCode != 200 && larger != small) {
        res = await http
            .get(Uri.parse(small))
            .timeout(const Duration(seconds: 12));
      }
      if (res.statusCode != 200 || res.bodyBytes.isEmpty) throw 'no image';
      path = '$household/product-${const Uuid().v4()}.jpg';
      await storage.uploadBinary(path, res.bodyBytes,
          fileOptions:
              const FileOptions(contentType: 'image/jpeg', upsert: false));
      final signed = await storage.createSignedUrl(path, 60 * 60 * 24 * 365);
      await client
          .from('food_items')
          .update({'image_url': signed}).eq('id', id);

      // The picture it replaced, if the app stored it.
      final old = _storagePath('${food['image_url'] ?? ''}');
      if (old != null) {
        try {
          await storage.remove([old]);
          await client.from('product_images').delete().eq('storage_path', old);
        } catch (_) {}
      }
      // What the app knows about this product's picture, and whether this
      // person agreed to share product photos beyond the household.
      try {
        var consent = false;
        final uid = client.auth.currentUser?.id;
        if (uid != null) {
          final s = await client
              .from('user_settings')
              .select('share_product_photos')
              .eq('profile_id', uid)
              .maybeSingle();
          consent = s?['share_product_photos'] == true;
        }
        final code = p['code'] ?? '';
        await client.from('product_images').insert({
          'household_id': household,
          if (RegExp(r'^[0-9]{6,14}$').hasMatch(code)) 'barcode': code,
          'name_key': '${food['name'] ?? p['name']}'.trim().toLowerCase(),
          'country_code': _country,
          'storage_path': path,
          'source': 'open_food_facts',
          'licence': 'Open Food Facts contributors, CC BY-SA',
          'share_consent': consent,
          'created_by': uid,
        });
      } catch (_) {}
      messenger.showSnackBar(const SnackBar(
          content: Text('Photo added. Credit: Open Food Facts.')));
      if (mounted) navigator.pop(true);
    } catch (_) {
      if (path != null) {
        try {
          await storage.remove([path]);
        } catch (_) {}
      }
      if (mounted) {
        setState(() => _using = false);
        messenger.showSnackBar(const SnackBar(
            content: Text('Could not use that photo. Check your signal.')));
      }
    }
  }

  static String? _storagePath(String signedUrl) {
    const marker = '/object/sign/food-images/';
    final at = signedUrl.indexOf(marker);
    if (at < 0) return null;
    final rest = signedUrl.substring(at + marker.length);
    final q = rest.indexOf('?');
    return Uri.decodeComponent(q < 0 ? rest : rest.substring(0, q));
  }

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);
    return SizedBox(
      width: widget.width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Find the product photo',
              style: t.headlineSmall.copyWith(
                  fontSize: 24, fontWeight: FontWeight.w800, color: _ink)),
          const SizedBox(height: 4),
          Text(
              'Pick the pack that matches yours. Packs differ from country to country.',
              style: t.bodyMedium.copyWith(color: _muted, fontSize: 14)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _query,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _search(),
                  decoration: InputDecoration(
                    hintText: 'Name or brand',
                    filled: true,
                    fillColor: const Color(0xFFFFFDF7),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: _border),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                style: IconButton.styleFrom(
                    backgroundColor: _forest, minimumSize: const Size(52, 52)),
                tooltip: 'Search',
                onPressed: _searching ? null : _search,
                icon: const Icon(Icons.search, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final e in _countries.entries) ...[
                  ChoiceChip(
                    label: Text(e.value),
                    selected: _country == e.key,
                    selectedColor: _sage,
                    onSelected: (_) => _setCountry(e.key),
                  ),
                  const SizedBox(width: 6),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (_searching || _using)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(color: _forest)),
              ),
            )
          else if (_note.isNotEmpty)
            Text(_note,
                style: t.bodyLarge.copyWith(color: _muted, fontSize: 16))
          else
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.72,
              children: [
                for (final p in _found)
                  Semantics(
                    button: true,
                    label: 'Use ${p['name']}',
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => _use(p),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: _uCard(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: Image.network(p['image']!,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) =>
                                      Container(color: _sage)),
                            ),
                            const SizedBox(height: 4),
                            Text(
                                [p['brand'], p['name']]
                                    .where((s) => (s ?? '').isNotEmpty)
                                    .join(' · '),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: t.bodySmall
                                    .copyWith(color: _ink, fontSize: 11)),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          const SizedBox(height: 8),
          Text('Photos from Open Food Facts, used with credit.',
              style: t.bodySmall.copyWith(color: _muted, fontSize: 12)),
        ],
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

