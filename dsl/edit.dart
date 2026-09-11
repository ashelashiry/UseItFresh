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

/// Build 5, part B: "Can't reach your kitchen" on the item screen and on Add
/// food, with Try again.
///
/// Part A gated both page-loads. This adds what they say instead, at the top
/// of each screen, and a Try again that reruns that screen's own check and
/// load in place. Every action output on a page needs its own name, so the
/// retry chains carry a Retry suffix.
///
/// Add food's card is honest about what still works: the form can be filled
/// in, but nothing can be saved until the connection is back.
void buildStarterEditFlow(App app) {
  final firstHouseholdId = CustomFunctionHandle(
    name: 'firstHouseholdId',
    args: {'rows': listOf(ff.Tables.households), 'current': string},
    returnType: string,
  );

  List<DslAction> gated(String tag, List<DslAction> chain,
          {List<DslAction> after = const []}) =>
      [
        CallCustomAction.named(
          'CanReachKitchen',
          args: {},
          returnType: bool_,
          arguments: {},
          outputAs: 'reach$tag',
        ),
        If(
          Equals(ActionOutput('reach$tag'), false),
          then: [SetState('offline', true)],
          orElse: [
            SetState('offline', false),
            ...chain,
            SetState('loadedOk', true),
            ...after,
          ],
        ),
      ];

  final item = ff.Pages.foodItemPage;
  final add = ff.Pages.addFoodItemPage;

  List<DslAction> itemLoad(String tag) => [
        PostgresQuery(
          ff.Tables.foodItemsStatus,
          outputAs: 'loadedItem$tag',
          query: PostgresQuerySpec(
            filters: [
              PostgresFilter('id',
                  relation: PostgresFilterRelation.equalTo,
                  value: PageParam('itemId')),
            ],
          ),
        ),
        SetState(item.state.item, ActionOutput('loadedItem$tag')),
      ];

  List<DslAction> addLoad(String tag) => [
        PostgresQuery(
          ff.Tables.households,
          outputAs: 'householdsForScope$tag',
          query: PostgresQuerySpec(
            orderBys: const [PostgresOrderBy('created_at')],
          ),
        ),
        UpdateAppState.set(
          ff.AppState.currentHouseholdId,
          CustomFunction(firstHouseholdId, args: {
            'rows': ActionOutput('householdsForScope$tag'),
            'current': AppState(ff.AppState.currentHouseholdId),
          }),
        ),
        PostgresQuery(
          ff.Tables.storageLocations,
          outputAs: 'locationsForHousehold$tag',
          query: PostgresQuerySpec(
            filters: [
              PostgresFilter(
                'household_id',
                relation: PostgresFilterRelation.equalTo,
                value: AppState(ff.AppState.currentHouseholdId),
              ),
            ],
            orderBys: const [
              PostgresOrderBy('location_type'),
              PostgresOrderBy('name'),
            ],
          ),
        ),
        SetState(add.state.locations, ActionOutput('locationsForHousehold$tag')),
      ];

  // A barcode find that arrived while offline is still waiting in app state,
  // so the retry fills the form from it too once the connection is back.
  List<DslAction> barcodePrefill() => [
        If(
          Not(Equals(AppState(ff.AppState.scanName), '')),
          then: [
            SetState(add.state.itemName, AppState(ff.AppState.scanName)),
            SetFormField(add.widgets.byKey('TextField_k6exjii3').single,
                AppState(ff.AppState.scanName)),
            SetFormField(add.widgets.byKey('DropDown_iefh7jg2').single,
                AppState(ff.AppState.scanCategory)),
            SetState(add.state.category, AppState(ff.AppState.scanCategory)),
            SetState(add.state.photoUrl, AppState(ff.AppState.scanImageUrl)),
            SetState(add.state.barcode, AppState(ff.AppState.scanBarcode)),
            UpdateAppState.set(ff.AppState.scanName, ''),
            UpdateAppState.set(ff.AppState.scanBrand, ''),
            UpdateAppState.set(ff.AppState.scanCategory, ''),
            UpdateAppState.set(ff.AppState.scanImageUrl, ''),
            UpdateAppState.set(ff.AppState.scanQuantity, ''),
            UpdateAppState.set(ff.AppState.scanBarcode, ''),
          ],
        ),
      ];

  Container offlineCard(String name, String body, List<DslAction> retry) =>
      Container(
        name: name,
        visible: State('offline'),
        color: Colors.accent1,
        borderRadius: 24,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxis: CrossAxis.center,
          spacing: 10,
          children: [
            Icon('wifi_off', size: 30, color: Colors.primary),
            Text(
              'Can’t reach your kitchen.',
              name: '${name}Title',
              style: Styles.titleMedium,
              color: Colors.primary,
              textAlign: TextAlign.center,
            ),
            Text(
              body,
              name: '${name}Body',
              style: Styles.bodySmall,
              color: Colors.secondaryText,
              textAlign: TextAlign.center,
            ),
            Button(
              'Try again',
              name: '${name}Retry',
              width: double.infinity,
              height: 48,
              borderRadius: 14,
              color: Colors.primary,
              textColor: Colors.secondaryBackground,
              onTap: retry,
            ),
          ],
        ),
      );

  // Item screen: first in the body, above the name.
  app.editPage(item, (page) {
    page.ensureInsertedBefore(
      item.widgets.byKey('Text_4oc4iodb').single,
      offlineCard(
        'ItemOffline',
        'No signal, or the connection dropped. This item will show again as '
            'soon as you are back online.',
        gated('ItemRetry', itemLoad('Retry')),
      ),
    );
  });

  // Add food: first in the form, above the photo.
  app.editPage(add, (page) {
    page.ensureInsertedBefore(
      add.widgets.byKey('Column_rr37vtu0').single,
      offlineCard(
        'AddOffline',
        'No signal, or the connection dropped. You can fill this in, but it '
            'cannot be saved until you are back online.',
        gated('AddRetry', addLoad('Retry'), after: barcodePrefill()),
      ),
    );
  });
}
