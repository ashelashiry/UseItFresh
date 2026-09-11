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

/// Food with no photo gets a plain plate, never a blank or a borrowed picture.
///
/// Three photo functions could hand the image widget an empty address — for
/// meat, fish, bread, frozen food and anything unrecognised. That widget
/// throws on an empty address: the kitchen showed a blank white block on
/// those cards, and the browser logged an uncaught error. Receipts made it
/// common, because nothing added from a receipt has a photo of its own.
///
/// Two borrowed pictures went too: fruit used the tomatoes (so Bananas showed
/// tomatoes), and the "Use these next" card fell back to spinach for
/// everything (so chicken showed spinach). A picture that passes for a
/// different food is worse than a plain one.
///
/// A custom function's code is the BODY only; the signature comes from the
/// declared arguments (see HANDOVER, section 5).
void buildStarterEditFlow(App app) {
  app.raw((project) {
    updateCustomFunction(
      project,
      name: 'foodImage',
      code: r'''
const root =
    'https://cdn.jsdelivr.net/gh/ashelashiry/UseItFresh@b50424f12bd372d81c9cd44d895b62c25d1329e7/design/v3/food';

final own = (imageUrl ?? '').trim();
if (own.isNotEmpty) return own;

// Named ingredients the guide gives specific photography for.
final n = (name ?? '').toLowerCase();
for (final entry in {
  'spinach': 'spinach',
  'mushroom': 'mushrooms',
  'tomato': 'tomatoes',
  'egg': 'eggs',
  'yogurt': 'yogurt',
  'yoghurt': 'yogurt',
  'pasta': 'pasta',
}.entries) {
  if (n.contains(entry.key)) return '$root/${entry.value}.webp';
}

// Otherwise the category's illustrative image, where one is honest. Fruit
// has none: it borrowed the tomatoes, which put tomatoes on a card for
// bananas. Never empty — the image widget throws on an empty address.
switch (category ?? '') {
  case 'vegetables':
    return '$root/spinach.webp';
  case 'eggs':
    return '$root/eggs.webp';
  case 'dairy':
    return '$root/yogurt.webp';
  case 'pantry_dry':
  case 'cooked_leftovers':
    return '$root/pasta.webp';
  default:
    return '$root/placeholder.webp';
}
''',
    );

    updateCustomFunction(
      project,
      name: 'itemPhoto',
      code: r'''
const root =
    'https://cdn.jsdelivr.net/gh/ashelashiry/UseItFresh@b50424f12bd372d81c9cd44d895b62c25d1329e7/design/v3/food';
// Never empty: the item screen's photo widget throws on an empty address.
const plain = '$root/placeholder.webp';
if (rows == null || rows.isEmpty) return plain;
final r = rows.first;
final own = (r.imageUrl ?? '').trim();
if (own.isNotEmpty) return own;
final n = (r.name ?? '').toLowerCase();
for (final e in {
  'spinach': 'spinach',
  'mushroom': 'mushrooms',
  'tomato': 'tomatoes',
  'egg': 'eggs',
  'yogurt': 'yogurt',
  'yoghurt': 'yogurt',
  'pasta': 'pasta',
}.entries) {
  if (n.contains(e.key)) return '$root/${e.value}.webp';
}
switch (r.category ?? '') {
  case 'vegetables':
    return '$root/spinach.webp';
  case 'eggs':
    return '$root/eggs.webp';
  case 'dairy':
    return '$root/yogurt.webp';
  case 'pantry_dry':
  case 'cooked_leftovers':
    return '$root/pasta.webp';
  default:
    return plain;
}
''',
    );

    updateCustomFunction(
      project,
      name: 'heroImage',
      code: r'''
const root =
    'https://cdn.jsdelivr.net/gh/ashelashiry/UseItFresh@b50424f12bd372d81c9cd44d895b62c25d1329e7/design/v3/food';
if (rows == null || rows.isEmpty) return '$root/spinach.webp';
final first = rows.first;
final own = (first.imageUrl ?? '').trim();
if (own.isNotEmpty) return own;
final n = (first.name ?? '').toLowerCase();
for (final e in {
  'spinach': 'spinach',
  'mushroom': 'mushrooms',
  'tomato': 'tomatoes',
  'egg': 'eggs',
  'yogurt': 'yogurt',
  'yoghurt': 'yogurt',
  'pasta': 'pasta',
}.entries) {
  if (n.contains(e.key)) return '$root/${e.value}.webp';
}
// The same category pictures as the cards, and the plain plate otherwise.
// It used to fall back to spinach for everything, so chicken showed spinach.
switch (first.category ?? '') {
  case 'vegetables':
    return '$root/spinach.webp';
  case 'eggs':
    return '$root/eggs.webp';
  case 'dairy':
    return '$root/yogurt.webp';
  case 'pantry_dry':
  case 'cooked_leftovers':
    return '$root/pasta.webp';
  default:
    return '$root/placeholder.webp';
}
''',
    );
  });
}
