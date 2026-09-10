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

/// Already on the list is a success, not a failure.
///
/// The action reported "X is already on the list" as an error string. It is
/// not an error: the wanted end state — that thing is on the next shop — is
/// already true. Returning empty keeps the meaning of the return value clean
/// (empty means "it is done"), which matters because the caller no longer
/// shows this message and would otherwise be quietly ignoring a real failure.
void buildStarterEditFlow(App app) {
  app.raw((project) {
    updateCustomAction(
      project,
      name: 'AddItemToShoppingList',
      description:
          'Puts a food item on the household shopping list as a replacement. '
          'Returns an empty string on success, or a message saying why not.',
      code: r'''
import 'package:supabase_flutter/supabase_flutter.dart';

/// Adds the named item to the household's shopping list.
///
/// Reads the name and household from the item itself, so the list entry always
/// matches the thing being settled.
Future<String> addItemToShoppingList(String? itemId) async {
  final id = (itemId ?? '').trim();
  if (id.isEmpty) return 'No item to add.';

  try {
    final item = await SupaFlow.client
        .from('food_items')
        .select('name, household_id')
        .eq('id', id)
        .maybeSingle();
    if (item == null) return 'Could not find that item.';

    final name = (item['name'] ?? '').toString().trim();
    final household = (item['household_id'] ?? '').toString();
    if (name.isEmpty || household.isEmpty) return 'Could not find that item.';

    // Creating a household seeds exactly one list, so the oldest is the one.
    final lists = await SupaFlow.client
        .from('shopping_lists')
        .select('id')
        .eq('household_id', household)
        .order('created_at')
        .limit(1);
    if (lists.isEmpty) return 'This household has no shopping list yet.';

    // Already there and not yet bought: the wanted end state already holds,
    // so this reports success rather than adding a second line for one thing.
    final already = await SupaFlow.client
        .from('shopping_list_items')
        .select('id')
        .eq('shopping_list_id', lists.first['id'])
        .eq('name', name)
        .eq('is_purchased', false);
    if (already.isNotEmpty) return '';

    await SupaFlow.client.from('shopping_list_items').insert({
      'shopping_list_id': lists.first['id'],
      'name': name,
      'source': 'replacement',
      // Required by the insert policy, not merely a record of who did it.
      'created_by': SupaFlow.client.auth.currentUser?.id,
    });
    return '';
  } on PostgrestException catch (error) {
    if (error.code == '42501') {
      return 'Your account is not allowed to add to this list.';
    }
    return error.message;
  } catch (error) {
    return 'Could not add it to the list. $error';
  }
}
''',
    );
  });
}
