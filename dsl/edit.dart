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

/// The camera is the way in.
///
/// Agreed in the photo-map plan: tapping Scan or "Add food" opens the camera
/// straight away, and the other ways to add (receipt, barcode, typing) are
/// what you get if you close it.
///
/// How, given the app's navigation: the tabs are FlutterFlow's generated
/// NavBarPage, and the nav bar only reports which tab was tapped. The Scan tab
/// shows ScanAddPage, which is built fresh each time you arrive from another
/// tab, so its page-load runs on every arrival:
///   * Scan tab page-load: clear any unfinished map (deleting its photos),
///     then open the review screen on top.
///   * Review screen page-load: when its map is empty, open the camera. The
///     "Reading your photo" banner is on that screen, so there is always
///     feedback while it reads.
///   * Camera closed: go back. The Scan tab is still underneath, so it shows
///     the other ways to add and does not reopen the camera.
///   * A read that failed says why, then goes back the same way.
///
/// Home's "Add food" did nothing at all (it still showed the Phase 2
/// placeholder). It and the Fridge photo tile now open the review screen too.
///
/// Conditionals are terminal in this DSL, so "nothing read" and "failed" are
/// written as if/else rather than as steps after an If.
void buildStarterEditFlow(App app) {
  final mapEmpty = app.customFunction(
    'mapEmpty',
    args: {'items': listOf(ff.Structs.mapFood)},
    returns: bool_,
    description: 'Whether the photo map has no foods on it yet.',
    code: r"""
return (items ?? []).isEmpty;
""",
  );

  List<DslAction> clearThenMap(String tag) => [
        CallCustomAction.named(
          'ClearShelfScan',
          args: {},
          returnType: string,
          arguments: {},
          outputAs: tag,
        ),
        Navigate(ff.Pages.mapReviewPage),
      ];

  // -- review screen: open the camera when there is nothing to review yet ---------
  app.editPageOnLoad(ff.Pages.mapReviewPage, [
    If(
      CustomFunction(mapEmpty, args: {'items': AppState('mapFoods')}),
      then: [
        CallCustomAction.named(
          'ReadShelfPhoto',
          args: {},
          returnType: string,
          arguments: {},
          outputAs: 'readOnOpen',
        ),
        If(
          Equals(ActionOutput('readOnOpen'), ''),
          // Camera closed: back to wherever they came from.
          then: [NavigateBack()],
          orElse: [
            If(
              Not(Equals(ActionOutput('readOnOpen'), 'ok')),
              // Something went wrong: say what, then go back.
              then: [Snackbar(ActionOutput('readOnOpen')), NavigateBack()],
            ),
          ],
        ),
      ],
    ),
  ]);

  // -- review screen: after saving, the kitchen replaces it ------------------------
  // Pushed on top, Back from the kitchen landed on an empty review screen.
  // The same chain as before; only the navigation replaces instead of stacking
  // (and a new output name, because ensureActions only replaces a chain it sees
  // as different).
  final review = ff.Pages.mapReviewPage;
  app.editPage(review, (page) {
    page.ensureActions(
      review.widgets.byKey('Button_w6qln0ju').single,
      triggerType: FFActionTriggerType.ON_TAP,
      actions: [
        CallCustomAction.named(
          'SaveMapFoods',
          args: {},
          returnType: string,
          arguments: {},
          outputAs: 'savedMapNow',
        ),
        If(
          Equals(ActionOutput('savedMapNow'), ''),
          then: [
            Snackbar('Added to your kitchen.'),
            Navigate(ff.Pages.inventoryPage, replaceRoute: true),
          ],
          orElse: [Snackbar(ActionOutput('savedMapNow'))],
        ),
      ],
    );
  });

  // -- Scan tab: straight to the camera -------------------------------------------
  app.editPageOnLoad(ff.Pages.scanAddPage, clearThenMap('clearedOnScan'));

  final scan = ff.Pages.scanAddPage;
  app.editPage(scan, (page) {
    page.ensureActions(
      scan.widgets.byKey('Container_u78daphn').single,
      triggerType: FFActionTriggerType.ON_TAP,
      actions: clearThenMap('clearedBeforeMap'),
    );
  });

  // -- Home: "Add food" opens the camera ------------------------------------------
  final home = ff.Pages.homePage;
  app.editPage(home, (page) {
    page.ensureActions(
      home.widgets.byKey('Button_gpb5q4p0').single,
      triggerType: FFActionTriggerType.ON_TAP,
      actions: clearThenMap('clearedForAdd'),
    );
  });
}
