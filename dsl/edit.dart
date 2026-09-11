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

/// "Can't reach your kitchen", with Try again.
///
/// Push A (off1) made the kitchen, Home and Profile stop claiming they are
/// empty when there is no signal. This adds what they say instead: a card on
/// the kitchen and on Home, and a Try again button that reruns that screen's
/// own load in place (the same check, the same queries) rather than
/// navigating anywhere and stacking a second copy of the screen.
///
/// Every action output on a page needs its own name, so the retry chains
/// carry a Retry suffix. This is its own push because an insert cannot share a
/// push with key-addressed rebinds on the same page.
void buildStarterEditFlow(App app) {
  final firstHouseholdId = CustomFunctionHandle(
    name: 'firstHouseholdId',
    args: {'rows': listOf(ff.Tables.households), 'current': string},
    returnType: string,
  );
  final kitchenState = CustomFunctionHandle(
    name: 'kitchenState',
    args: {
      'ok': bool_,
      'offline': bool_,
      'all': listOf(ff.Tables.foodItemsStatus),
      'shown': listOf(ff.Tables.foodItemsStatus),
      'query': string,
      'filter': string,
    },
    returnType: string,
  );

  /// The check, then either "offline" or the screen's own load and "loaded".
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

  final inv = ff.Pages.inventoryPage;
  final home = ff.Pages.homePage;

  List<DslAction> inventoryLoad(String tag) => [
        PostgresQuery(
          ff.Tables.households,
          outputAs: 'invHouseholds$tag',
          query: PostgresQuerySpec(
            orderBys: const [PostgresOrderBy('created_at')],
          ),
        ),
        UpdateAppState.set(
          ff.AppState.currentHouseholdId,
          CustomFunction(firstHouseholdId, args: {
            'rows': ActionOutput('invHouseholds$tag'),
            'current': AppState(ff.AppState.currentHouseholdId),
          }),
        ),
        PostgresQuery(
          ff.Tables.foodItemsStatus,
          outputAs: 'invItems$tag',
          query: PostgresQuerySpec(
            filters: [
              PostgresFilter(
                'household_id',
                relation: PostgresFilterRelation.equalTo,
                value: AppState(ff.AppState.currentHouseholdId),
              ),
            ],
            orderBys: const [
              PostgresOrderBy('urgency_rank'),
              PostgresOrderBy('days_left'),
            ],
          ),
        ),
        SetState(inv.state.allItems, ActionOutput('invItems$tag')),
        SetState(inv.state.items, ActionOutput('invItems$tag')),
      ];

  List<DslAction> homeLoad(String tag) => [
        PostgresQuery(
          ff.Tables.households,
          outputAs: 'householdsForHome$tag',
          query: PostgresQuerySpec(
              orderBys: const [PostgresOrderBy('created_at')]),
        ),
        SetState('households', ActionOutput('householdsForHome$tag')),
        UpdateAppState.set(
          ff.AppState.currentHouseholdId,
          CustomFunction(firstHouseholdId, args: {
            'rows': ActionOutput('householdsForHome$tag'),
            'current': AppState(ff.AppState.currentHouseholdId),
          }),
        ),
        PostgresQuery(
          ff.Tables.profiles,
          outputAs: 'profileForHome$tag',
          query: PostgresQuerySpec(
            filters: [
              PostgresFilter('id',
                  relation: PostgresFilterRelation.equalTo,
                  value: const AuthUser(AuthUserField.userId)),
            ],
          ),
        ),
        SetState(home.state.me, ActionOutput('profileForHome$tag')),
        PostgresQuery(
          ff.Tables.foodItemsStatus,
          outputAs: 'urgentForHome$tag',
          query: PostgresQuerySpec(
            filters: [
              PostgresFilter('household_id',
                  relation: PostgresFilterRelation.equalTo,
                  value: AppState(ff.AppState.currentHouseholdId)),
            ],
            orderBys: const [
              PostgresOrderBy('urgency_rank'),
              PostgresOrderBy('days_left'),
            ],
          ),
        ),
        SetState(home.state.useFirst, ActionOutput('urgentForHome$tag')),
      ];

  /// The card both screens show. Says what happened and what will happen,
  /// and does not guess at anything it cannot see.
  Container offlineCard(String name, Object visible, List<DslAction> retry) =>
      Container(
        name: name,
        visible: visible,
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
              'No signal, or the connection dropped. Your food will show '
              'again as soon as you are back online.',
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

  // Kitchen: first in the states column, shown only in the offline state.
  app.editPage(inv, (page) {
    page.ensureInsertedBefore(
      inv.widgets.byKey('Container_dfajl791').single,
      offlineCard(
        'InventoryOffline',
        Equals(
          CustomFunction(kitchenState, args: {
            'ok': State('loadedOk'),
            'offline': State('offline'),
            'all': State(inv.state.allItems),
            'shown': State(inv.state.items),
            'query': State(inv.state.query),
            'filter': State(inv.state.filter),
          }),
          'offline',
        ),
        gated('InvRetry', inventoryLoad('Retry'), after: [
          CallCustomAction.named(
            'ScheduleExpiryReminders',
            args: {},
            returnType: string,
            arguments: {},
            outputAs: 'invRescheduleRetry',
          ),
        ]),
      ),
    );
  });

  // Home: right under the greeting.
  app.editPage(home, (page) {
    page.ensureInsertedAfter(
      home.widgets.byKey('Column_8bi8tamu').single,
      offlineCard(
        'HomeOffline',
        State('offline'),
        gated('HomeRetry', homeLoad('Retry')),
      ),
    );
  });
}
