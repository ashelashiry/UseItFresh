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

/// Build 5, part A: the item screen, Add food and the greeting stop
/// pretending when there is no signal.
///
/// The same pattern as the kitchen, Home and Profile in Build 4: a
/// reachability check first, then either an `offline` flag and nothing else,
/// or the screen's own page-load reproduced exactly and `loadedOk` at the end.
///
///   * Item screen: offline it would show an empty item with live "I used it"
///     and "Throw it out" buttons that cannot save. The actions now wait for
///     a load that worked.
///   * Add food: offline the "where is it kept" picker sat empty with no
///     reason given. The page-load is gated; its card comes in part B.
///   * Greeting (hiLineLoaded; the name greetingLine is already taken by an
///     original function): offline, Home said "Hi, ashraf.elashiry" (the email fallback
///     for a profile that did not load). It says "Hi" until the profile has
///     loaded. The text is replaced rather than rebound, because `bindText`
///     does not displace an existing binding (HANDOVER, section 5).
///
/// The "can't reach your kitchen" cards are part B: an insert cannot share a
/// push with key-addressed edits on the same page.
void buildStarterEditFlow(App app) {
  final hiLineLoaded = app.customFunction(
    'hiLineLoaded',
    args: {'rows': listOf(ff.Tables.profiles), 'email': string, 'ok': bool_},
    returns: string,
    description:
        'The short greeting above the headline, e.g. "Hi, Ash". Just "Hi" '
        'until the profile has loaded, so an offline start does not greet '
        'someone by their email address.',
    code: r"""
if (ok != true) return 'Hi';
var who = '';
if (rows != null && rows.isNotEmpty) {
  who = rows.first.displayName?.trim() ?? '';
}
if (who.isEmpty) {
  final address = email ?? '';
  final at = address.indexOf('@');
  who = at > 0 ? address.substring(0, at) : address;
}
return who.isEmpty ? 'Hi' : 'Hi, $who';
""",
  );

  for (final page in [ff.Pages.foodItemPage, ff.Pages.addFoodItemPage]) {
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

  // -- Item screen: its one query, exactly, inside the check -----------------
  final item = ff.Pages.foodItemPage;
  app.editPageOnLoad(
    item,
    gated('Item', [
      PostgresQuery(
        ff.Tables.foodItemsStatus,
        outputAs: 'loadedItem',
        query: PostgresQuerySpec(
          filters: [
            PostgresFilter('id',
                relation: PostgresFilterRelation.equalTo,
                value: PageParam('itemId')),
          ],
        ),
      ),
      SetState(item.state.item, const ActionOutput('loadedItem')),
    ]),
  );
  // "I used it", "Throw it out" and the replace toggle only once the item has
  // actually loaded: offline they would act on an item the screen cannot show.
  app.editPage(item, (page) {
    page.bindVisible(
        item.widgets.byKey('Column_01lid1tp').single, State('loadedOk'));
  });

  // -- Add food: bc8's chain, exactly, inside the check ----------------------
  // "Loaded" goes before the barcode prefill: that If is terminal in this DSL,
  // so anything written after it would be nested inside it.
  final add = ff.Pages.addFoodItemPage;
  app.editPageOnLoad(
    add,
    gated(
      'Add',
      [
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
        PostgresQuery(
          ff.Tables.storageLocations,
          outputAs: 'locationsForHousehold',
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
        SetState(add.state.locations, const ActionOutput('locationsForHousehold')),
      ],
      after: [
        // Start from the barcode find, if there is one (unchanged from bc8).
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
      ],
    ),
  );

  // -- Home: the greeting, replaced to wait for the profile -------------------
  final home = ff.Pages.homePage;
  app.editPage(home, (page) {
    page.ensureReplaced(
      home.widgets.byKey('Text_kuedjrmm').single,
      Text(
        CustomFunction(hiLineLoaded, args: {
          'rows': State(home.state.me),
          'email': const AuthUser(AuthUserField.email),
          'ok': State('loadedOk'),
        }),
        name: 'HomeHi',
        style: Styles.bodyLarge,
        color: Colors.secondaryText,
      ),
    );
  });
}
