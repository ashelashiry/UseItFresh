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

/// Every household-scoped screen resolves the household itself.
///
/// The add screen offered no locations at all on a fresh install: its query
/// filters on `currentHouseholdId`, and that is only set by whichever screen
/// happens to run first. Open the app and go straight to Scan → Add manually
/// and there was nothing to choose from — the filter matched an empty string.
///
/// Depending on visit order is the bug. Each screen that needs the household
/// now asks for it first, and `firstHouseholdId` keeps whatever is already held
/// if it is still valid, so this costs one cheap query and never flips the
/// household underneath someone.
///
/// Home and Inventory get the same treatment. Their queries were not scoped at
/// all — row security returns every household you belong to, so with more than
/// one they would mix items from all of them into one kitchen.
///
/// The app-state field is referenced through its typed handle. An earlier pass
/// concluded the handle compiled to an empty `where` clause; that was wrong -
/// the chain had been skipped wholesale by ensureActions, so the old unfiltered
/// query was simply still there.
void buildStarterEditFlow(App app) {
  final firstHouseholdId = app.customFunction(
    'firstHouseholdId',
    args: {'rows': listOf(ff.Tables.households), 'current': string},
    returns: string,
    description:
        'Keeps the current household if it is still one you belong to, '
        'otherwise falls back to the oldest one.',
    code: r"""
if (rows == null || rows.isEmpty) return '';
final ids = rows.map((r) => r.id).toList();
final held = (current ?? '').trim();
if (held.isNotEmpty && ids.contains(held)) return held;
return ids.first;
""",
  );

  /// The two actions that settle which household a screen is looking at.
  List<DslAction> resolveHousehold() => [
        PostgresQuery(
          ff.Tables.households,
          outputAs: 'householdsForScope',
          query: PostgresQuerySpec(
            orderBys: const [PostgresOrderBy('created_at')],
          ),
        ),
        UpdateAppState.set(
          ff.AppState.currentHouseholdId,
          CustomFunction(firstHouseholdId, args: {
            'rows': const ActionOutput('householdsForScope'),
            'current': AppState(ff.AppState.currentHouseholdId),
          }),
        ),
      ];

  PostgresFilter thisHousehold(String column) => PostgresFilter(
        column,
        relation: PostgresFilterRelation.equalTo,
        value: AppState(ff.AppState.currentHouseholdId),
      );

  // ---- Add food: locations for this household only ------------------------
  app.editPageOnLoad(ff.Pages.addFoodItemPage, [
    ...resolveHousehold(),
    PostgresQuery(
      ff.Tables.storageLocations,
      outputAs: 'locationsForHousehold',
      query: PostgresQuerySpec(
        filters: [thisHousehold('household_id')],
        orderBys: const [
          PostgresOrderBy('location_type'),
          PostgresOrderBy('name'),
        ],
      ),
    ),
    SetState(
      ff.Pages.addFoodItemPage.state.locations,
      const ActionOutput('locationsForHousehold'),
    ),
  ]);

  // ---- Inventory: this household's food ----------------------------------
  app.editPageOnLoad(ff.Pages.inventoryPage, [
    ...resolveHousehold(),
    PostgresQuery(
      ff.Tables.foodItemsStatus,
      outputAs: 'kitchenForHousehold',
      query: PostgresQuerySpec(
        filters: [thisHousehold('household_id')],
        orderBys: const [
          PostgresOrderBy('urgency_rank'),
          PostgresOrderBy('days_left'),
        ],
      ),
    ),
    SetState(ff.Pages.inventoryPage.state.allItems,
        const ActionOutput('kitchenForHousehold')),
    SetState(ff.Pages.inventoryPage.state.items,
        const ActionOutput('kitchenForHousehold')),
  ]);

  // ---- Home: the greeting, and what to use first --------------------------
  app.editPageOnLoad(ff.Pages.homePage, [
    ...resolveHousehold(),
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
      outputAs: 'urgentForHousehold',
      query: PostgresQuerySpec(
        filters: [thisHousehold('household_id')],
        orderBys: const [
          PostgresOrderBy('urgency_rank'),
          PostgresOrderBy('days_left'),
        ],
      ),
    ),
    SetState(ff.Pages.homePage.state.useFirst,
        const ActionOutput('urgentForHousehold')),
  ]);
}
