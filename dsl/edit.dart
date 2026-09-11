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

/// The two lines that still said "empty" offline now say what they know.
///
/// Push A re-pointed the kitchen subtitle and Profile's household line at
/// loaded-aware functions with `bindText`, and the offline walk showed both
/// still reading "Nothing in here yet" and "No household yet". The generated
/// code still called kitchenCount and householdRole: `bindText` did not
/// displace the existing binding. So each text is replaced outright with a
/// fresh one bound to the new function, matching its look.
///
/// The kitchen subtitle's 14pt size is a style override the DSL `Text` cannot
/// express; it goes back on as a fast-lane fontSize patch after this push.
void buildStarterEditFlow(App app) {
  final kitchenLine = CustomFunctionHandle(
    name: 'kitchenLine',
    args: {
      'rows': listOf(ff.Tables.foodItemsStatus),
      'ok': bool_,
      'offline': bool_,
    },
    returnType: string,
  );
  final householdLine = CustomFunctionHandle(
    name: 'householdLine',
    args: {'rows': listOf(ff.Tables.households), 'uid': string, 'ok': bool_},
    returnType: string,
  );

  final inv = ff.Pages.inventoryPage;
  app.editPage(inv, (page) {
    page.ensureReplaced(
      inv.widgets.byKey('Text_403jzbco').single,
      Text(
        CustomFunction(kitchenLine, args: {
          'rows': State(inv.state.allItems),
          'ok': State('loadedOk'),
          'offline': State('offline'),
        }),
        name: 'InventoryLede',
        style: Styles.bodySmall,
        color: Colors.secondaryText,
        maxLines: 3,
      ),
    );
  });

  final profile = ff.Pages.profilePage;
  app.editPage(profile, (page) {
    page.ensureReplaced(
      profile.widgets.byKey('Text_qg7xk5rt').single,
      Text(
        CustomFunction(householdLine, args: {
          'rows': State('households'),
          'uid': const AuthUser(AuthUserField.userId),
          'ok': State('loadedOk'),
        }),
        name: 'ProfileRole',
        style: Styles.bodySmall,
        color: Colors.secondaryText,
      ),
    );
  });
}
