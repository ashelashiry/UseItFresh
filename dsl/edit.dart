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
// Two seconds of black after the tap.
//
// Measured: frames at 0.30s, 0.90s and 1.60s after the tap were empty, and
// only at 2.50s did anything appear. The cause is a gap in the layering. The
// closed fridge was bound to "while pending", so the tap removed it
// instantly; the opening clip took its place, and a clip that has not
// finished loading draws nothing. Between those two facts sat two seconds of
// the scaffold's background.
//
// The closed fridge now stays until the FORM appears, sitting under the clip
// the whole way. Its last state is a shut door and the clip's first frame is
// the same shut door, so the changeover is invisible, and if the clip is slow
// the screen shows a fridge rather than nothing.
//
// The warm-up was also still naming the v9 file. Replacing the page-load chain
// did not update it — the chain's shape was unchanged, so the existing action
// node was left as it was, argument and all. Rewriting the string in place
// instead, which does not depend on the chain being rebuilt.
// ---------------------------------------------------------------------------

const _kOldClip = 'fridge-opening-v9-912.webp';
const _kNewClip =
    'https://storage.googleapis.com/flutterflow-io-6f20.appspot.com'
    '/projects/fridge-wise-gvpy0s/assets/g98rh4e8sl38/fridge-opening-v10.webp';

void buildStarterEditFlow(App app) {
  app.editPage(ff.Pages.signInPage, (page) {
    page.bindVisible(
      ff.Pages.signInPage.widgets.byPath('SignInPage.body[0].children[1]').single,
      Not(State(ff.Pages.signInPage.state.formShown)),
    );
  });

  app.raw((project) {
    final page = findPage(project, name: 'SignInPage');
    if (page == null) return;
    for (final trigger in page.node.triggerActions) {
      _retargetWarmUp(trigger.rootAction);
    }
  });
}

/// Points any warm-up call still naming the retired clip at the current one.
void _retargetWarmUp(FFActionNode node) {
  if (node.hasAction() && node.action.hasCustomAction()) {
    for (final arg
        in node.action.customAction.argumentValues.arguments.values) {
      // serializedValue holds the bare string, not a JSON literal — wrapping
      // it in quotes shipped a URL with the quote marks in it.
      final raw = arg.value.inputValue.serializedValue;
      if (raw.contains(_kOldClip) || raw.contains('"')) {
        arg.value.inputValue.serializedValue = _kNewClip;
      }
    }
  }
  if (node.hasFollowUpAction()) _retargetWarmUp(node.followUpAction);
}
