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

/// The waste figures stop counting food that was put back.
///
/// Putting a food back leaves its "used" or "thrown out" event in place, which
/// is right — the history is append-only and it did happen. But the figures on
/// "What you used" are about outcomes, and a food sitting in the kitchen is
/// not an outcome. LoadWasteSummary now skips any event whose food has no
/// `archived_at`, which is exactly the food that came back.
void buildStarterEditFlow(App app) {
  app.raw((project) {
    updateCustomAction(project, name: 'LoadWasteSummary', code: _loadWasteSummary);
  });
}

const _loadWasteSummary = r'''
import 'package:supabase_flutter/supabase_flutter.dart';

/// Works out the household's use-versus-waste picture over the last 30 days.
///
/// Reads events rather than the items table because an item's current status
/// says what it is now; the event says what happened and when. Only the two
/// settling events count — 'created' and 'moved' are not outcomes.
///
/// One exception to reading only events: food that was put back. The event
/// stays, because the history is append-only and it did happen, but the food
/// is in the kitchen again — counting it as used or thrown out would
/// contradict what the kitchen shows. `archived_at` is what settling sets, so
/// an item without one has come back and is skipped.
Future<String> loadWasteSummary() async {
  final household = FFAppState().currentHouseholdId;
  if (household.isEmpty) {
    return 'No household yet. Create or join one first.';
  }

  // Reset first, so a failed reload cannot leave the previous household's
  // numbers on screen looking like this one's.
  FFAppState().wasteHeadline = '';
  FFAppState().wasteDetail = '';
  FFAppState().wasteWorst = '';
  FFAppState().wasteTrend = '';
  FFAppState().wasteUsedCount = 0;
  FFAppState().wasteBinnedCount = 0;
  FFAppState().wasteHasData = false;

  final now = DateTime.now().toUtc();
  final windowStart = now.subtract(const Duration(days: 30));
  final priorStart = now.subtract(const Duration(days: 60));

  List<dynamic> rows;
  try {
    // The embedded food_items select is what scopes this to the household and
    // brings the category along; row security already limits it to households
    // this person belongs to, and the filter picks the one they are looking at.
    rows = await SupaFlow.client
        .from('food_item_events')
        .select(
            'event_type, created_at, food_items!inner(category, household_id, archived_at)')
        .eq('food_items.household_id', household)
        .inFilter('event_type', ['consumed', 'discarded']).gte(
            'created_at', priorStart.toIso8601String());
  } on PostgrestException catch (error) {
    return error.message;
  } catch (error) {
    return 'Could not read your history. $error';
  }

  var used = 0;
  var binned = 0;
  var priorUsed = 0;
  var priorBinned = 0;
  final binnedByCategory = <String, int>{};

  for (final row in rows) {
    final at = DateTime.tryParse((row['created_at'] ?? '').toString());
    if (at == null) continue;
    // Put back since: the event stands, the outcome does not.
    final food = row['food_items'];
    final settled = food is Map && (food['archived_at'] ?? '').toString().isNotEmpty;
    if (!settled) continue;
    final recent = at.isAfter(windowStart);
    final consumed = row['event_type'] == 'consumed';

    if (recent) {
      if (consumed) {
        used++;
      } else {
        binned++;
        final item = row['food_items'];
        final category =
            (item is Map ? (item['category'] ?? '') : '').toString().trim();
        if (category.isNotEmpty) {
          binnedByCategory[category] = (binnedByCategory[category] ?? 0) + 1;
        }
      }
    } else {
      if (consumed) {
        priorUsed++;
      } else {
        priorBinned++;
      }
    }
  }

  final settled = used + binned;
  FFAppState().wasteUsedCount = used;
  FFAppState().wasteBinnedCount = binned;
  FFAppState().wasteHasData = settled > 0;

  if (settled == 0) {
    FFAppState().wasteHeadline = 'Nothing finished with yet.';
    FFAppState().wasteDetail =
        'When you mark something used up or thrown out, the pattern shows up '
        'here.';
    return '';
  }

  final pct = ((used / settled) * 100).round();
  FFAppState().wasteHeadline = '$used of $settled used up.';
  FFAppState().wasteDetail = settled == 1
      ? 'One thing finished with in the last 30 days.'
      : '$settled things finished with in the last 30 days. $pct% used, '
          '${100 - pct}% thrown out.';

  // The worst category, but only when there is enough to mean anything. Two
  // thrown-out items is not a pattern, and naming one would be inventing a
  // conclusion the data cannot carry.
  if (binned >= 3 && binnedByCategory.isNotEmpty) {
    final ranked = binnedByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = ranked.first;
    // A tie is not a worst.
    final tied = ranked.length > 1 && ranked[1].value == top.value;
    if (!tied && top.value >= 2) {
      FFAppState().wasteWorst = _label(top.key);
    }
  }

  // A comparison needs a previous month with something in it, or the first
  // month reads as a dramatic improvement over nothing.
  final priorSettled = priorUsed + priorBinned;
  if (priorSettled >= 3) {
    final priorPct = (priorUsed / priorSettled) * 100;
    final diff = pct - priorPct;
    if (diff >= 5) {
      FFAppState().wasteTrend = 'Better than the month before.';
    } else if (diff <= -5) {
      FFAppState().wasteTrend = 'Down on the month before.';
    } else {
      FFAppState().wasteTrend = 'About the same as the month before.';
    }
  }

  return '';
}

/// The words the picker offered, so this screen never shows a stored code.
String _label(String code) {
  const names = <String, String>{
    'dairy': 'Dairy',
    'meat_poultry': 'Meat & poultry',
    'seafood': 'Seafood',
    'eggs': 'Eggs',
    'cooked_leftovers': 'Cooked leftovers',
    'fruit': 'Fruit',
    'vegetables': 'Vegetables',
    'bread_bakery': 'Bread & bakery',
    'pantry_dry': 'Pantry & dry goods',
    'frozen': 'Frozen food',
    'condiments_sauces': 'Condiments & sauces',
    'infant_food': 'Infant food & formula',
  };
  return names[code] ?? code.replaceAll('_', ' ');
}
''';
