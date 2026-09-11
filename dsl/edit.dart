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

/// Fix a line on the review list before adding it.
///
/// A receipt read can get a name wrong, or say more than the person wants
/// ("Medium white bread" for a plain loaf). Until now the only choice was to
/// remove the line and add the food by hand afterwards. Tapping a line now
/// opens a small screen for that one line: its name, editable, and what else
/// is known about it. Saving writes the line back in place, by position, with
/// only the name changed.
///
/// Why a screen of its own rather than an editable row: the rows are built
/// from the list by position, and a text field inside a row can stay tied to
/// the wrong line once a line above it is removed. One field on its own screen
/// has nothing to fall out of step with.
void buildStarterEditFlow(App app) {
  app.ensurePage(
    'ScanLinePage',
    description:
        'Correct the name of one line on the receipt or fridge-photo review '
        'list, before anything is added.',
    route: 'scan-line',
    // Defaults on every parameter, so a cold deep link cannot crash the page.
    params: {
      'index': int_.withDefault(-1),
      'name': string.withDefault(''),
      'category': string.withDefault(''),
      'quantity': int_.withDefault(1),
      'place': string.withDefault(''),
      'detail': string.withDefault(''),
    },
    onLoad: [SetFormField('ScanLineName', PageParam('name'))],
    body: Scaffold(
      body: Container(
        name: 'ScanLineBody',
        padding:
            const EdgeInsets.only(left: 20, right: 20, top: 12, bottom: 20),
        child: Column(
          scrollable: true,
          crossAxis: CrossAxis.stretch,
          spacing: 14,
          children: [
            Row(
              name: 'ScanLineBackRow',
              mainAxis: MainAxis.start,
              children: [
                Container(
                  name: 'ScanLineBack',
                  onTap: [NavigateBack()],
                  width: 44,
                  height: 44,
                  color: Colors.secondaryBackground,
                  borderColor: Colors.alternate,
                  borderWidth: 1,
                  borderRadius: 999,
                  child:
                      Icon('arrow_back', size: 20, color: Colors.primaryText),
                ),
              ],
            ),
            Text('Fix this line.',
                name: 'ScanLineHeadline',
                style: Styles.headlineMedium,
                color: Colors.primary),
            Text(
              PageParam('detail'),
              name: 'ScanLineDetail',
              style: Styles.bodyMedium,
              color: Colors.secondaryText,
            ),
            TextField(
              name: 'ScanLineName',
              label: 'Name',
              hint: 'What it is, in plain words',
            ),
            Button(
              'Save this line',
              name: 'ScanLineSave',
              width: double.infinity,
              height: 50,
              borderRadius: 14,
              color: Colors.primary,
              textColor: Colors.secondaryBackground,
              onTap: [
                If(
                  // Read from the field itself, not a page-state copy: a new
                  // field's change handler is debounced, and a tap straight
                  // after typing would save the previous value.
                  Equals(WidgetState('ScanLineName', WidgetStateProperty.text),
                      ''),
                  then: [Snackbar('Give it a name first.')],
                  orElse: [
                    UpdateAppState.updateItemAtIndex(
                      'scannedFoods',
                      PageParam('index'),
                      Struct(ff.Structs.scannedFood, {
                        'name': WidgetState(
                            'ScanLineName', WidgetStateProperty.text),
                        'category': PageParam('category'),
                        'quantity': PageParam('quantity'),
                        'place': PageParam('place'),
                        'detail': PageParam('detail'),
                      }),
                    ),
                    NavigateBack(),
                  ],
                ),
              ],
            ),
            Text(
              'Only the name changes here. Where it goes and its category stay '
              'as they were, and nothing is added until you tap Add on the list.',
              name: 'ScanLineNote',
              style: Styles.bodySmall,
              color: Colors.secondaryText,
            ),
          ],
        ),
      ),
    ),
  );

  // Tapping a line opens it. The remove button sits inside the row, and the
  // innermost tap target wins, so removing still works.
  final review = ff.Pages.scanReviewPage;
  app.editPage(review, (page) {
    page.ensureActions(
      review.widgets.byKey('Container_1gma093s').single,
      triggerType: FFActionTriggerType.ON_TAP,
      actions: [
        Navigate('ScanLinePage', params: {
          'index': const ItemRef().index,
          'name': const ItemRef()['name'],
          'category': const ItemRef()['category'],
          'quantity': const ItemRef()['quantity'],
          'place': const ItemRef()['place'],
          'detail': const ItemRef()['detail'],
        }),
      ],
    );
  });
}
