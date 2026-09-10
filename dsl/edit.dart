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

/// Correct where a chocolate bar lands.
///
/// Driving the finished flow filed a Mars bar under "Bread & bakery", because
/// Open Food Facts tags it en:biscuits-and-cakes and that sat in the bakery
/// rule. Bakery implies days; a chocolate bar keeps for months, and the
/// category exists purely to estimate shelf life — so the wrong bucket is not
/// cosmetic, it would have made the app claim the thing was going off.
void buildStarterEditFlow(App app) {
  app.raw((project) {
    updateCustomAction(
      project,
      name: 'LookupBarcode',
      description:
        'Looks a barcode up in Open Food Facts and puts what it found into '
        'app state. Returns an empty string on success, or a message saying '
        'why not.',
    code: r'''
import 'dart:convert';

import 'package:http/http.dart' as http;

/// Looks up a barcode, and says why if it could not.
///
/// Returns '' when something usable was found. Every other outcome returns a
/// sentence a person can act on, because "lookup failed" tells them nothing
/// about whether to wait, retype, or give up and add it by hand.
Future<String> lookupBarcode(String? barcode) async {
  final code = (barcode ?? '').replaceAll(RegExp(r'[^0-9]'), '');
  if (code.length < 8) {
    return 'That does not look like a barcode. They are usually 8 to 14 digits.';
  }

  // Clear first, so a failed second lookup cannot leave the first one's
  // answer on screen looking like the new one.
  FFAppState().scanBarcode = code;
  FFAppState().scanName = '';
  FFAppState().scanBrand = '';
  FFAppState().scanCategory = '';
  FFAppState().scanImageUrl = '';
  FFAppState().scanQuantity = '';

  final url = Uri.parse(
      'https://world.openfoodfacts.org/api/v2/product/$code.json'
      '?fields=product_name,brands,categories_tags,image_front_small_url,quantity');

  http.Response res;
  try {
    res = await http.get(url, headers: {
      // Open Food Facts asks callers to identify themselves.
      'User-Agent': 'UseItFresh/1.0 (https://useitfresh.app)',
    }).timeout(const Duration(seconds: 12));
  } catch (error) {
    return 'Could not reach the product database. Check your connection, or '
        'add it by hand.';
  }

  // An unknown barcode comes back as 404, not as a 200 with a flag.
  if (res.statusCode == 404) {
    return 'No product found for $code. You can still add it by hand.';
  }
  if (res.statusCode != 200) {
    return 'The product database is not answering right now. Try again in a '
        'moment, or add it by hand.';
  }

  Map<String, dynamic> body;
  try {
    body = json.decode(res.body) as Map<String, dynamic>;
  } catch (_) {
    return 'The product database sent something unreadable.';
  }
  if (body['status'] != 1 || body['product'] == null) {
    return 'No product found for $code. You can still add it by hand.';
  }

  final product = body['product'] as Map<String, dynamic>;
  final name = (product['product_name'] ?? '').toString().trim();
  final brands = (product['brands'] ?? '').toString().trim();
  // brands is a comma-separated list, longest-established first; one is plenty.
  final brand = brands.isEmpty ? '' : brands.split(',').first.trim();

  if (name.isEmpty) {
    return 'That barcode is in the database but has no name yet. Add it by '
        'hand and it will still be recorded.';
  }

  final tags = <String>[
    for (final t in (product['categories_tags'] as List<dynamic>? ?? []))
      t.toString()
  ];

  FFAppState().scanName = name;
  FFAppState().scanBrand = brand;
  FFAppState().scanCategory = _categoryFor(tags);
  FFAppState().scanQuantity = (product['quantity'] ?? '').toString().trim();
  FFAppState().scanImageUrl =
      (product['image_front_small_url'] ?? '').toString().trim();
  return '';
}

/// Our category for a product, or '' when nothing matches confidently.
///
/// Order is precedence, most specific first. Storage beats ingredient: a bag
/// of frozen peas is 'frozen', not 'vegetables', because how it is kept is
/// what decides how long it lasts — and the shelf-life estimate is the whole
/// reason this app records a category at all.
///
/// Returning '' is a real answer. Leaving the picker empty is better than
/// filing yoghurt under pantry because a rule half-matched.
String _categoryFor(List<String> tags) {
  const rules = <String, List<String>>{
    'infant_food': ['en:baby-foods', 'en:baby-milks', 'en:infant-formulae',
        'en:baby-snacks'],
    'frozen': ['en:frozen-foods', 'en:frozen-desserts', 'en:ice-creams'],
    'eggs': ['en:eggs'],
    'seafood': ['en:seafood', 'en:fishes', 'en:fishes-and-their-products',
        'en:shellfish', 'en:canned-fishes'],
    'meat_poultry': ['en:meats-and-their-products', 'en:meats', 'en:poultry',
        'en:prepared-meats', 'en:charcuterie'],
    'dairy': ['en:dairies', 'en:milks', 'en:cheeses', 'en:yogurts',
        'en:fermented-milk-products', 'en:creams', 'en:butters'],
    // Fresh bakery only. Biscuits, cakes and chocolate bars are shelf-stable
    // and belong with dry goods: filing a chocolate bar as bakery would have
    // the app estimate a few days for something that keeps for months, and
    // that estimate is the only reason a category is recorded at all.
    'bread_bakery': ['en:breads', 'en:viennoiserie', 'en:pastries',
        'en:bakery-products'],
    'pantry_dry': ['en:biscuits-and-cakes', 'en:confectioneries',
        'en:chocolate-candies', 'en:candy-chocolate-bars',
        'en:sweet-snacks', 'en:crisps-and-chips'],
    'condiments_sauces': ['en:sauces', 'en:condiments', 'en:spreads',
        'en:dressings', 'en:mustards', 'en:vinegars'],
    'fruit': ['en:fresh-fruits', 'en:fruits'],
    'vegetables': ['en:fresh-vegetables', 'en:vegetables',
        'en:fruits-and-vegetables'],
  };

  final have = tags.toSet();
  for (final entry in rules.entries) {
    if (have.intersection(entry.value.toSet()).isNotEmpty) return entry.key;
  }
  // A packaged grocery matching nothing specific is usually ambient dry goods,
  // but only say so when the tags look like food at all.
  const ambient = {
    'en:plant-based-foods-and-beverages', 'en:plant-based-foods',
    'en:cereals-and-potatoes', 'en:groceries', 'en:canned-foods', 'en:snacks',
    'en:beverages', 'en:beverages-and-beverages-preparations',
  };
  if (have.intersection(ambient).isNotEmpty) return 'pantry_dry';
  return '';
}
''',
  );
  });
}
