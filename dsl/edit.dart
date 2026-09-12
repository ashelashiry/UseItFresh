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

/// The basket goes into the kitchen.
///
/// The loop stopped half way: you could tick something into the basket, then
/// had to type it in again as food. One button under the list now adds
/// everything you ticked and clears it off the list.
///
/// It started as a button on every line, which the compiler refused: a widget
/// inserted into a list template cannot read the line's id ("Item field access
/// \"id\" used outside a ListView builder"), and attaching the action by key
/// afterwards would not bind either. One button for the whole basket is the
/// better shape anyway — it matches how a shop ends, and it is one tap instead
/// of ten. So the per-line button and its action are removed here.
///
/// Food goes in where the app puts anything it was not told about: the
/// household's default location, as manually added, with no date, so it gets
/// the typical keep time for its category. No category is guessed; the item
/// screen is where that gets fixed.
void buildStarterEditFlow(App app) {
  app.removeCustomAction('AddBoughtToKitchen');

  app.customAction(
    'AddBasketToKitchen',
    args: {},
    returns: string,
    description:
        "Adds everything ticked on the shopping list to the kitchen and clears "
        "those lines. Returns '' when done, or a message saying why not.",
    code: _addBasketToKitchen,
  );

  final shopping = ff.Pages.shoppingListPage;
  app.editPage(shopping, (page) {
    page.ensureRemoved(shopping.widgets.byKey('Container_v9dh7zbk').single);
    page.ensureInsertedAfter(
      shopping.widgets.byKey('ListView_omu6zj3c').single,
      Button(
        'Put the basket in my kitchen',
        name: 'ShoppingBasketToKitchen',
        width: double.infinity,
        height: 50,
        borderRadius: 14,
        color: Colors.primary,
        textColor: Colors.secondaryBackground,
        onTap: [
          CallCustomAction.named(
            'AddBasketToKitchen',
            args: {},
            returnType: string,
            arguments: {},
            outputAs: 'basketSaid',
          ),
          If(
            Equals(ActionOutput('basketSaid'), ''),
            then: [
              Snackbar('Added to your kitchen.'),
              // Reopening reloads the list, now without those lines.
              Navigate(ff.Pages.shoppingListPage, replaceRoute: true),
            ],
            orElse: [Snackbar(ActionOutput('basketSaid'))],
          ),
        ],
      ),
    );
  });
}

const _addBasketToKitchen = r'''
import 'package:supabase_flutter/supabase_flutter.dart';

/// Adds everything ticked on the shopping list to the kitchen, then clears
/// those lines off the list.
///
/// One insert for the lot, so it is all or nothing. The lines are only
/// deleted after the food is safely in: a line that is still on the list is a
/// smaller annoyance than food that vanished on the way.
///
/// Quantities are rounded to whole things, because food_items counts things.
/// Nothing is guessed about category or dates.
Future<String> addBasketToKitchen() async {
  final household = FFAppState().currentHouseholdId;
  if (household.isEmpty) {
    return 'No household yet. Create or join one before adding food.';
  }

  try {
    // Creating a household seeds exactly one list, so the oldest is the one.
    final lists = await SupaFlow.client
        .from('shopping_lists')
        .select('id')
        .eq('household_id', household)
        .order('created_at')
        .limit(1);
    if ((lists as List).isEmpty) return 'This household has no shopping list yet.';

    final rows = await SupaFlow.client
        .from('shopping_list_items')
        .select('id, name, quantity')
        .eq('shopping_list_id', lists.first['id'])
        .eq('is_purchased', true);
    final bought = List<Map<String, dynamic>>.from(rows as List);
    if (bought.isEmpty) {
      return 'Tick what you have bought first, then this puts it away.';
    }

    // Where the household puts things by default; each can be moved after.
    final places = await SupaFlow.client
        .from('storage_locations')
        .select('id, is_default')
        .eq('household_id', household);
    final locations = List<Map<String, dynamic>>.from(places as List);
    String? where;
    for (final l in locations) {
      if (l['is_default'] == true) where = l['id'].toString();
    }
    if (where == null && locations.isNotEmpty) {
      where = locations.first['id'].toString();
    }

    final uid = SupaFlow.client.auth.currentUser?.id;
    final food = <Map<String, dynamic>>[];
    final done = <String>[];
    for (final line in bought) {
      final name = (line['name'] ?? '').toString().trim();
      if (name.isEmpty) continue;
      final counted =
          line['quantity'] is num ? (line['quantity'] as num).round() : 1;
      food.add({
        'household_id': household,
        'storage_location_id': where,
        'created_by': uid,
        'name': name,
        'quantity': counted < 1 ? 1 : counted,
        'source_type': 'manual',
      });
      done.add(line['id'].toString());
    }
    if (food.isEmpty) return 'Those lines have no names to add.';

    await SupaFlow.client.from('food_items').insert(food);
    await SupaFlow.client
        .from('shopping_list_items')
        .delete()
        .inFilter('id', done);
    return '';
  } on PostgrestException catch (error) {
    if (error.code == '42501') {
      return 'Your account is not allowed to add to this household.';
    }
    return error.message;
  } catch (_) {
    return 'Could not add them. Check your signal and try again.';
  }
}
''';
