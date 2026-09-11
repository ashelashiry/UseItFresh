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

/// Offline, the main screens stop saying something false.
///
/// Walked with the network cut (offwalk.py, 11 Sep): a kitchen with three
/// foods said "Nothing in here yet", Home offered to set up a new household,
/// and Profile said "No household yet". Every on-load query throws when there
/// is no signal, nothing catches it, the chain stops, and the page keeps its
/// starting state — an empty list, which is exactly what the empty states are
/// keyed on. The kitchen's own listState was built to tell "not back yet" from
/// "empty", but FlutterFlow starts list state as [] rather than null, so its
/// "loading" branch could never fire.
///
/// The fix, per screen:
///   * a reachability check first (CanReachKitchen, a custom action that
///     catches its own failure — PostgresQuery has no failure branch);
///   * if unreachable, an `offline` flag and nothing else;
///   * otherwise the existing on-load, reproduced exactly, then `loadedOk`;
///   * everything that says "empty" or "no household" now also needs
///     `loadedOk`, through NEW functions that take it. The old functions are
///     left as they are, so no call site anywhere else can break.
///
/// Conditionals are terminal in this DSL (anything after an If is nested into
/// it), so each whole existing chain lives in the reachable branch.
///
/// The "can't reach your kitchen" cards with a Try again button are the next
/// push: an insert cannot share a push with key-addressed rebinds.
void buildStarterEditFlow(App app) {
  // -- the check --------------------------------------------------------------
  app.customAction(
    'CanReachKitchen',
    args: {},
    returns: bool_,
    description:
        'Whether the database can be reached right now. Returns true or '
        'false and never throws, so a screen can say it is offline instead of '
        'stopping half way through loading.',
    code: r'''
import 'package:supabase_flutter/supabase_flutter.dart';

/// Whether the database answers right now.
///
/// One row from a table every signed-in person can read. Any failure (no
/// signal, a timeout, the server down) is "no", never an exception.
Future<bool> canReachKitchen() async {
  try {
    await SupaFlow.client
        .from('households')
        .select('id')
        .limit(1)
        .timeout(const Duration(seconds: 8));
    return true;
  } catch (_) {
    return false;
  }
}
''',
  );

  // -- functions that know whether the load worked -----------------------------
  final kitchenState = app.customFunction(
    'kitchenState',
    args: {
      'ok': bool_,
      'offline': bool_,
      'all': listOf(ff.Tables.foodItemsStatus),
      'shown': listOf(ff.Tables.foodItemsStatus),
      'query': string,
      'filter': string,
    },
    returns: string,
    description:
        'Which state the kitchen list is in: offline, loading, empty, '
        'filtered or items. Says "empty" only after a load that worked.',
    code: r"""
if (offline == true) return 'offline';
if (ok != true) return 'loading';
final everything = all ?? [];
if (everything.isEmpty) return 'empty';
if (shown != null && shown.isNotEmpty) return 'items';
final searching = (query ?? '').trim().isNotEmpty;
final narrowed = (filter ?? 'all').trim().toLowerCase() != 'all';
return (searching || narrowed) ? 'filtered' : 'items';
""",
  );

  final kitchenLine = app.customFunction(
    'kitchenLine',
    args: {
      'rows': listOf(ff.Tables.foodItemsStatus),
      'ok': bool_,
      'offline': bool_,
    },
    returns: string,
    description:
        'The line under the Inventory heading. Says the kitchen is empty only '
        'after a load that worked.',
    code: r"""
if (offline == true) return 'Can’t reach your kitchen right now';
if (ok != true) return 'Checking your kitchen…';
final all = rows ?? [];
if (all.isEmpty) return 'Nothing in here yet';
final n = all.length;
final places = all
    .map((r) => (r.locationName ?? '').trim())
    .where((p) => p.isNotEmpty)
    .toSet()
    .toList()
  ..sort();
final count = n == 1 ? '1 item' : '$n items';
if (places.isEmpty) return count;
if (places.length == 1) return '$count · ${places.first.toLowerCase()}';
final last = places.removeLast();
return '$count · ${places.map((p) => p.toLowerCase()).join(', ')} & '
    '${last.toLowerCase()}';
""",
  );

  final householdLine = app.customFunction(
    'householdLine',
    args: {'rows': listOf(ff.Tables.households), 'uid': string, 'ok': bool_},
    returns: string,
    description:
        'The line under the name on Profile. Says "No household yet" only '
        'after a load that worked; blank while it has not.',
    code: r"""
if (ok != true) return '';
if (rows == null || rows.isEmpty) return 'No household yet';
final h = rows.first;
final owns = (h.ownerId ?? '') == (uid ?? '');
final name = (h.name ?? '').trim();
final where = name.isEmpty ? 'Your household' : name;
return owns ? '$where · Owner' : '$where · Member';
""",
  );

  final offerSetup = app.customFunction(
    'offerHouseholdSetup',
    args: {'rows': listOf(ff.Tables.households), 'ok': bool_},
    returns: bool_,
    description:
        'Whether Home should offer to set up a household: only when a load '
        'that worked found none. Offline it must not, or it invites a second '
        'household.',
    code: 'return ok == true && (rows == null || rows.isEmpty);',
  );

  // -- the flags ----------------------------------------------------------------
  for (final page in [
    ff.Pages.inventoryPage,
    ff.Pages.homePage,
    ff.Pages.profilePage,
  ]) {
    app.editPageState(page, (state) {
      state.ensureField('loadedOk', bool_.withDefault(false));
      state.ensureField('offline', bool_.withDefault(false));
    });
  }

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

  final firstHouseholdId = CustomFunctionHandle(
    name: 'firstHouseholdId',
    args: {'rows': listOf(ff.Tables.households), 'current': string},
    returnType: string,
  );

  // -- Inventory: notif5's chain, exactly, inside the check ---------------------
  final inv = ff.Pages.inventoryPage;
  app.editPageOnLoad(
    inv,
    gated(
      'Inv',
      [
        PostgresQuery(
          ff.Tables.households,
          outputAs: 'invHouseholds',
          query: PostgresQuerySpec(
            orderBys: const [PostgresOrderBy('created_at')],
          ),
        ),
        UpdateAppState.set(
          ff.AppState.currentHouseholdId,
          CustomFunction(firstHouseholdId, args: {
            'rows': const ActionOutput('invHouseholds'),
            'current': AppState(ff.AppState.currentHouseholdId),
          }),
        ),
        PostgresQuery(
          ff.Tables.foodItemsStatus,
          outputAs: 'invItems',
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
        // BOTH lists: allItems backs search and the filter chips, items is
        // what the grid draws. Setting only one silently breaks filtering.
        SetState(inv.state.allItems, const ActionOutput('invItems')),
        SetState(inv.state.items, const ActionOutput('invItems')),
      ],
      // After "loaded": a reminder hiccup must never hide the kitchen.
      after: [
        CallCustomAction.named(
          'ScheduleExpiryReminders',
          args: {},
          returnType: string,
          arguments: {},
          outputAs: 'invReschedule',
        ),
      ],
    ),
  );

  // -- Home: prompt.dart's chain, exactly, inside the check ---------------------
  app.editPageOnLoad(
    ff.Pages.homePage,
    gated('Home', [
      PostgresQuery(
        ff.Tables.households,
        outputAs: 'householdsForHome',
        query:
            PostgresQuerySpec(orderBys: const [PostgresOrderBy('created_at')]),
      ),
      SetState('households', const ActionOutput('householdsForHome')),
      UpdateAppState.set(
        ff.AppState.currentHouseholdId,
        CustomFunction(firstHouseholdId, args: {
          'rows': const ActionOutput('householdsForHome'),
          'current': AppState(ff.AppState.currentHouseholdId),
        }),
      ),
      PostgresQuery(
        ff.Tables.profiles,
        outputAs: 'profileForHome',
        query: PostgresQuerySpec(
          filters: [
            PostgresFilter('id',
                relation: PostgresFilterRelation.equalTo,
                value: const AuthUser(AuthUserField.userId)),
          ],
        ),
      ),
      SetState(ff.Pages.homePage.state.me, const ActionOutput('profileForHome')),
      PostgresQuery(
        ff.Tables.foodItemsStatus,
        outputAs: 'urgentForHome',
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
      SetState(ff.Pages.homePage.state.useFirst,
          const ActionOutput('urgentForHome')),
    ]),
  );

  // -- Profile: profile.dart's chain, exactly, inside the check -----------------
  app.editPageOnLoad(
    ff.Pages.profilePage,
    gated('Profile', [
      PostgresQuery(
        ff.Tables.profiles,
        outputAs: 'myProfile',
        query: PostgresQuerySpec(
          filters: [
            PostgresFilter('id',
                relation: PostgresFilterRelation.equalTo,
                value: const AuthUser(AuthUserField.userId)),
          ],
        ),
      ),
      SetState('me', const ActionOutput('myProfile')),
      PostgresQuery(
        ff.Tables.households,
        outputAs: 'myHouseholds',
        query:
            PostgresQuerySpec(orderBys: const [PostgresOrderBy('created_at')]),
      ),
      SetState('households', const ActionOutput('myHouseholds')),
    ]),
  );

  // -- what each screen says, now told whether the load worked -----------------
  DslExpression kitchenIs(String which) => Equals(
        CustomFunction(kitchenState, args: {
          'ok': State('loadedOk'),
          'offline': State('offline'),
          'all': State(inv.state.allItems),
          'shown': State(inv.state.items),
          'query': State(inv.state.query),
          'filter': State(inv.state.filter),
        }),
        which,
      );

  app.editPage(inv, (page) {
    page.bindVisible(
        inv.widgets.byKey('GridView_elxnrddg').single, kitchenIs('items'));
    page.bindVisible(
        inv.widgets.byKey('Container_dfajl791').single, kitchenIs('loading'));
    page.bindVisible(
        inv.widgets.byKey('Container_4l0ewk2n').single, kitchenIs('empty'));
    page.bindVisible(
        inv.widgets.byKey('Container_h8k9k2yy').single, kitchenIs('filtered'));
    page.bindText(
      inv.widgets.byKey('Text_403jzbco').single,
      CustomFunction(kitchenLine, args: {
        'rows': State(inv.state.allItems),
        'ok': State('loadedOk'),
        'offline': State('offline'),
      }),
    );
  });

  app.editPage(ff.Pages.homePage, (page) {
    page.bindVisible(
      ff.Pages.homePage.widgets.byKey('Container_y8xn4win').single,
      CustomFunction(offerSetup, args: {
        'rows': State('households'),
        'ok': State('loadedOk'),
      }),
    );
  });

  app.editPage(ff.Pages.profilePage, (page) {
    page.bindText(
      ff.Pages.profilePage.widgets.byKey('Text_qg7xk5rt').single,
      CustomFunction(householdLine, args: {
        'rows': State('households'),
        'uid': const AuthUser(AuthUserField.userId),
        'ok': State('loadedOk'),
      }),
    );
  });
}
