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

/// v3 — the badge aligns itself.
///
/// Setting the wrapping container's child alignment never reached the generated
/// code, so the pill kept filling the stretch column and reading as a banner.
/// Aligning inside the widget is under our own control and is harmless on the
/// cards, where the row already sizes it.
///
/// `parameters:` is omitted deliberately: passing it drops the dimensions
/// parameter FlutterFlow injects into every custom widget.
void buildStarterEditFlow(App app) {
  app.raw((project) {
    updateCustomWidget(
      project,
      name: 'FoodStatusBadge',
      code: r'''
import 'package:flutter/material.dart';

class FoodStatusBadge extends StatelessWidget {
  const FoodStatusBadge({
    super.key,
    this.width,
    this.height,
    required this.status,
    required this.label,
  });

  final double? width;
  final double? height;
  final String? status;
  final String? label;

  // (foreground, background, icon) per computed status.
  static const _looks = <String, (Color, Color, IconData)>{
    'fresh': (Color(0xFF285B34), Color(0xFFEAF3E5), Icons.check_circle_outline),
    'use_soon': (Color(0xFF79500F), Color(0xFFFFF1D4), Icons.schedule),
    'use_today': (Color(0xFF934017), Color(0xFFFFEADD), Icons.priority_high),
    'past_best_before':
        (Color(0xFF69516E), Color(0xFFF1EAF4), Icons.help_outline),
    'past_use_by': (Color(0xFFA02929), Color(0xFFFCE8E6), Icons.dangerous_outlined),
    'frozen': (Color(0xFF275E85), Color(0xFFE7F2FA), Icons.ac_unit),
    'consumed': (Color(0xFF47594A), Color(0xFFEEF2EC), Icons.done_all),
    'discarded': (Color(0xFFA02929), Color(0xFFFCE8E6), Icons.delete_outline),
  };

  static const _unknown =
      (Color(0xFF59615D), Color(0xFFEDF0ED), Icons.help_outline);

  @override
  Widget build(BuildContext context) {
    final look = _looks[status ?? ''] ?? _unknown;
    final words = (label ?? '').trim();
    if (words.isEmpty) return const SizedBox.shrink();

    // Align, so a stretched parent does not turn the pill into a banner.
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: look.$2,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(look.$3, size: 13, color: look.$1),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                words,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: look.$1,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
''',
    );
  });
}
