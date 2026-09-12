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

/// Design guide v4, Scan: the tiles use the supplied line icons.
///
/// The first version used stand-in Material icons because the kitchen icon
/// set has no camera, barcode or receipt. The v3 visual pack does, as 24px
/// line SVGs (1.8 stroke, round caps) — "use supplied SVGs", the guide says —
/// so the app gains flutter_svg and the tiles draw those, in forest.
///
/// The fridge is the one exception: there is no fridge icon in that line style
/// yet (only a differently drawn one in the kitchen set, which would look out
/// of place beside these). It keeps a stand-in until the owner's designer
/// supplies one; the icon list is in HANDOVER.
void buildStarterEditFlow(App app) {
  app.pubDependency('flutter_svg', '^2.0.10');

  app.raw((project) {
    updateCustomWidget(project, name: 'AddOptions', code: _addOptions);
  });
}

const _addOptions = r'''
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// The four ways to add food, as large tiles, with "Enter manually" beneath.
///
/// Each tile does exactly what its row on the old Scan screen did:
///   Photo    -> the Add food screen, which takes a single-item photo
///   Barcode  -> the barcode screen
///   Receipt  -> read a receipt photo, then review it (or say why not)
///   Fridge   -> a fresh photo map of a shelf
/// Labels stay next to the icons: icons alone are not enough.
class AddOptions extends StatefulWidget {
  const AddOptions({super.key, this.width, this.height});

  final double? width;
  final double? height;

  @override
  State<AddOptions> createState() => _AddOptionsState();
}

class _AddOptionsState extends State<AddOptions> {
  static const _forest = Color(0xFF07533A);
  static const _ink = Color(0xFF202C24);
  static const _sage = Color(0xFFEDF2E8);
  static const _border = Color(0xFFDCE3D7);

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

  Future<void> _receiptTap() async {
    final said = await readPhotoFoods('receipt');
    if (!mounted) return;
    if (said == 'ok') {
      context.pushNamed('ScanReviewPage');
    } else if (said.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(said)));
    }
  }

  Future<void> _fridgeTap() async {
    await clearShelfScan();
    if (!mounted) return;
    context.pushNamed('MapReviewPage');
  }

  static Widget _svg(String source) =>
      SvgPicture.string(source, width: 34, height: 34);

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);
    return SizedBox(
      width: widget.width,
      child: LayoutBuilder(
        builder: (context, box) {
          const gap = 12.0;
          final tileWidth = (box.maxWidth - gap) / 2;
          final tileHeight = (tileWidth * 0.9).clamp(140.0, 170.0);
          Widget tile(String label, Widget icon, Future<void> Function() go) =>
              _Tile(
                width: tileWidth,
                height: tileHeight,
                label: label,
                icon: icon,
                enabled: !_busy,
                onTap: () => _run(go),
                labelStyle: t.titleMedium.copyWith(
                    fontSize: 17, fontWeight: FontWeight.w700, color: _ink),
                sage: _sage,
                border: _border,
              );

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  tile('Photo', _svg(_camera), () async {
                    context.pushNamed('AddFoodItemPage');
                  }),
                  const SizedBox(width: gap),
                  tile('Barcode', _svg(_barcode), () async {
                    context.pushNamed('BarcodeScanPage');
                  }),
                ],
              ),
              const SizedBox(height: gap),
              Row(
                children: [
                  tile('Receipt', _svg(_receipt), _receiptTap),
                  const SizedBox(width: gap),
                  // Stand-in until a fridge icon in the same line style exists.
                  tile('Fridge',
                      const Icon(Icons.kitchen_outlined, size: 34, color: _forest),
                      _fridgeTap),
                ],
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton.icon(
                  onPressed: _busy
                      ? null
                      : () => context.pushNamed('AddFoodItemPage'),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(48, 48),
                    foregroundColor: _forest,
                  ),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: Text(
                    'Enter manually',
                    style: t.bodyLarge.copyWith(
                        color: _forest, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// One large tile: an icon well above a short label, the whole card tappable,
/// with an immediate pressed response (skipped when reduced motion is on).
class _Tile extends StatefulWidget {
  const _Tile({
    required this.width,
    required this.height,
    required this.label,
    required this.icon,
    required this.enabled,
    required this.onTap,
    required this.labelStyle,
    required this.sage,
    required this.border,
  });

  final double width;
  final double height;
  final String label;
  final Widget icon;
  final bool enabled;
  final VoidCallback onTap;
  final TextStyle labelStyle;
  final Color sage;
  final Color border;

  @override
  State<_Tile> createState() => _TileState();
}

class _TileState extends State<_Tile> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.of(context).disableAnimations;
    return Semantics(
      button: true,
      enabled: widget.enabled,
      label: widget.label,
      child: GestureDetector(
        onTapDown: widget.enabled ? (_) => setState(() => _down = true) : null,
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) => setState(() => _down = false),
        onTap: widget.enabled ? widget.onTap : null,
        child: AnimatedScale(
          scale: (_down && !still) ? 0.97 : 1,
          duration: const Duration(milliseconds: 150),
          child: AnimatedOpacity(
            opacity: widget.enabled ? 1 : 0.6,
            duration: const Duration(milliseconds: 150),
            child: Container(
              width: widget.width,
              height: widget.height,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: widget.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: widget.sage,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: widget.icon,
                  ),
                  const Spacer(),
                  Text(widget.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: widget.labelStyle),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
''';
