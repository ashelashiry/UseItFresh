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

/// Declare the photo argument the action body already takes, and pass it.
///
/// The body grew a sixth parameter, `imageUrl`, but the declared argument list
/// stayed at five, so codegen emitted a five-argument call against a
/// six-argument function and the build stopped.
///
/// Both halves have to land in the same push: the validator refuses a declared
/// argument that a call site does not supply, so declaring it alone fails and
/// wiring it alone has nothing to wire.
///
/// The five live arguments are kept EXACTLY as they are — their keys are what
/// every existing call site's values are filed under, so replacing them
/// orphans the values. The new one is a deep copy of an existing String
/// argument, renamed, so its data type is identical in shape to the ones the
/// project already accepts rather than one reconstructed by hand.
void buildStarterEditFlow(App app) {
  app.raw((project) {
    final action = findCustomAction(project, name: 'CreateFoodItem');
    if (action == null) throw StateError('CreateFoodItem is missing.');

    final existing = action.arguments.toList();
    if (existing.any((p) => p.identifier.name == 'imageUrl')) {
      print('imageUrl is already declared; leaving the arguments alone.');
      return;
    }

    final template =
        existing.firstWhere((p) => p.identifier.name == 'category');
    final imageUrl = template.deepCopy();
    imageUrl.ensureIdentifier()
      ..name = 'imageUrl'
      ..key = 'imgurlkey';

    updateCustomAction(
      project,
      name: 'CreateFoodItem',
      arguments: [...existing, imageUrl],
    );
  });

  // The confirm button hands the photo over with everything else. The output
  // variable is renamed because ensureActions leaves a chain alone when it
  // judges it equal to the one already there, and an added argument is not
  // enough of a difference on its own.
  app.editPage(ff.Pages.addFoodReviewPage, (page) {
    page.ensureActions(
      ff.Pages.addFoodReviewPage.widgets.byKey('Button_sm2avojh').single,
      triggerType: FFActionTriggerType.ON_TAP,
      actions: [
        CallCustomAction.named(
          'CreateFoodItem',
          args: {
            'name': string,
            'category': string,
            'locationId': string,
            'printedDate': dateTime,
            'printedDateType': string,
            'imageUrl': string,
          },
          returnType: string,
          arguments: {
            'name': Param('name'),
            'category': Param('category'),
            'locationId': Param('locationId'),
            'printedDate': Param('printedDate'),
            'printedDateType': Param('printedDateType'),
            'imageUrl': Param('imageUrl'),
          },
          outputAs: 'savedOutcome',
        ),
        If(
          Equals(const ActionOutput('savedOutcome'), ''),
          then: [
            Snackbar('Added to your kitchen.'),
            Navigate(ff.Pages.inventoryPage),
          ],
          orElse: [Snackbar(const ActionOutput('savedOutcome'))],
        ),
      ],
    );
  });
}
