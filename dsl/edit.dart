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

/// Fields look like the rest of the app.
///
/// Every text field was filled with no fill colour set, so it fell back to a
/// grey wash while every other surface in v3 is white on a gentle border. The
/// forms read as a different app from the screens around them.
///
/// White fill, 1px alternate border, 14px radius — the same treatment as the
/// cards and rows. The inventory search is left alone: it deliberately has no
/// border of its own because it sits inside one.
void buildStarterEditFlow(App app) {
  const fields = <String, List<String>>{
    'resetPassword': ['TextField_sybqsats'],
    'signIn': ['TextField_o2faty06', 'TextField_kadw7ppq'],
    'signUp': ['TextField_5z7qq1pu', 'TextField_bve20b4b', 'TextField_fys6541l'],
    'household': ['TextField_cg0goaa0', 'TextField_pmsdcf3h'],
    'onboarding': ['TextField_w2d30f74'],
    'updatePassword': ['TextField_julyevbl', 'TextField_6ekzr6it'],
    'storage': ['TextField_utlynq7w'],
    'addFood': ['TextField_k6exjii3'],
  };
  final pages = <String, dynamic>{
    'resetPassword': ff.Pages.resetPasswordPage,
    'signIn': ff.Pages.signInPage,
    'signUp': ff.Pages.signUpPage,
    'household': ff.Pages.householdSetupPage,
    'onboarding': ff.Pages.onboardingPage,
    'updatePassword': ff.Pages.updatePasswordPage,
    'storage': ff.Pages.storageLocationsPage,
    'addFood': ff.Pages.addFoodItemPage,
  };

  fields.forEach((which, keys) {
    final handle = pages[which];
    app.editPage(handle, (page) {
      for (final key in keys) {
        page.mutateNode(handle.widgets.byKey(key).single, (node) {
          final decoration =
              node.props.ensureTextField().ensureInputDecoration();
          decoration.ensureFilledValue().inputValue = true;
          decoration.ensureFillColorValue().ensureInputValue().themeColor =
              FFColor_ThemeColor.SECONDARY_BACKGROUND;
          decoration.inputBorderType =
              FFInputDecoration_InputBorderType.outline;
          decoration.ensureBorderWidthValue().inputValue = 1;
          decoration.ensureBorderColorValue().ensureInputValue().themeColor =
              FFColor_ThemeColor.ALTERNATE;
          decoration.ensureFocusBorderColorValue().ensureInputValue()
              .themeColor = FFColor_ThemeColor.PRIMARY;
          final radius = decoration.ensureBorderRadius()
            ..type = FFBorderRadius_BorderRadiusType.FF_BORDER_RADIUS_ALL;
          radius.ensureAllValue().inputValue = 14;
        });
      }
    });
  });
}
