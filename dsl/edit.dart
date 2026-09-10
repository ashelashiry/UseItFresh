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

/// Unblock the iOS build: MutationObserver has no non-web stub.
///
/// letTapsThroughVideos already returns early off the web, but a runtime guard
/// does not help a COMPILE error. universal_html provides stubs for most of
/// dart:html so code like this still builds for a device; MutationObserver is
/// not among them, so the iOS archive died on
/// "Method not found: 'MutationObserver'".
///
/// The observer is dropped rather than replaced. It was belt-and-braces: the
/// timer sweep below it already re-applies the fix over the first few seconds,
/// which is the window platform views actually appear in. Everything else in
/// the action is untouched, so the web behaviour it was written for still
/// works.
///
/// Worth remembering: this is the first custom action in the project to face a
/// real device compile. Anything reaching for dart:html needs the same look
/// before the next build.
void buildStarterEditFlow(App app) {
  app.raw((project) {
    updateCustomAction(
      project,
      name: 'LetTapsThroughVideos',
      description:
          'Stops Flutter video platform views swallowing taps on the web. '
          'Does nothing on a device, where taps already work.',
      code: r'''
import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:universal_html/html.dart' as html;

/// Stops Flutter's video platform views from swallowing taps on the web.
///
/// A Flutter video on the web is a real <video> element the browser stacks on
/// top of the whole app, and the app's own layer is `pointer-events: none`.
/// Three elements have to be neutralised, and the third is the one that
/// matters: the <flt-platform-view-slot> Flutter hides inside a shadow root.
///
/// Web only — on iOS and Android the video is a texture inside the widget tree
/// and taps already work. Safe to call repeatedly.
Future<void> letTapsThroughVideos() async {
  if (!kIsWeb) return;

  void kill(html.Element el) =>
      el.style.setProperty('pointer-events', 'none', 'important');

  void harden() {
    for (final el in html.document
        .querySelectorAll('flt-platform-view, flt-platform-view *')) {
      kill(el);
    }
    // The slot lives in a shadow root, out of reach of any stylesheet.
    for (final host in html.document.querySelectorAll('*')) {
      final root = host.shadowRoot;
      if (root == null) continue;
      for (final el in root.querySelectorAll('flt-platform-view-slot')) {
        kill(el);
      }
    }
  }

  if (html.document.getElementById('ff-video-pointer-fix') == null) {
    final style = html.StyleElement()
      ..id = 'ff-video-pointer-fix'
      ..text =
          'flt-platform-view, flt-platform-view * { pointer-events: none !important; }';
    html.document.head?.append(style);
  }

  harden();
  // A platform view appears a frame or two after its widget mounts, and the
  // opening clip creates a second one when it plays, so re-apply for a while.
  //
  // This used to be backed by a MutationObserver as well. universal_html has
  // no non-web stub for it, so the symbol failed to COMPILE for iOS even
  // though the kIsWeb guard above meant it could never RUN there. The sweep
  // covers the same window on its own.
  for (final ms in const [50, 200, 600, 1200, 2400, 3600]) {
    Timer(Duration(milliseconds: ms), harden);
  }
}
''',
    );
  });
}
