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

/// Keep scanned product photos in our own storage.
///
/// A barcode lookup gives the item Open Food Facts' photo link. Those links
/// change when a photo is replaced upstream, and an item should not lose its
/// picture because someone else edited a public database. So the photo is
/// copied into the household's own folder when the item is added.
///
/// Same signature as before — seven arguments, same names — so no call site
/// changes and nothing else needs to be in this push.
void buildStarterEditFlow(App app) {
  app.raw((project) {
    updateCustomAction(
      project,
      name: 'CreateFoodItem',
      description:
          'Adds one food item to the current household, copying an Open Food '
          'Facts photo into our own storage first. Returns an empty string on '
          'success, or a message explaining why it failed.',
      code: r'''
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

/// Adds a food item, and says why if it could not.
///
/// household_id is not null in the schema and has no default, so it has to be
/// supplied here; created_by records who added it. Both come from the session
/// rather than the form, so neither can be left out by a screen that forgets.
Future<String> createFoodItem(
  String? name,
  String? category,
  String? locationId,
  DateTime? printedDate,
  String? printedDateType,
  String? imageUrl,
  String? barcode,
) async {
  final trimmed = (name ?? '').trim();
  if (trimmed.isEmpty) return 'Give it a name first.';
  if ((locationId ?? '').isEmpty) return 'Choose where it is kept.';

  final household = FFAppState().currentHouseholdId;
  if (household.isEmpty) {
    return 'No household yet. Create or join one before adding food.';
  }

  final code = (barcode ?? '').trim();
  var photo = (imageUrl ?? '').trim();
  if (photo.contains('openfoodfacts.org/')) {
    photo = await _keepOwnCopy(photo, household);
  }

  // How it was added, most specific first. A barcode is a stronger claim
  // about what the thing IS than a photograph, so it wins when both are
  // present — which is exactly what happens when a lookup supplies the
  // product picture too.
  final source =
      code.isNotEmpty ? 'barcode' : (photo.isNotEmpty ? 'photo' : 'manual');

  try {
    await SupaFlow.client.from('food_items').insert({
      'household_id': household,
      'storage_location_id': locationId,
      'created_by': SupaFlow.client.auth.currentUser?.id,
      'name': trimmed,
      if ((category ?? '').isNotEmpty) 'category': category,
      if (photo.isNotEmpty) 'image_url': photo,
      if (code.isNotEmpty) 'barcode': code,
      if (printedDate != null)
        'printed_date': printedDate.toIso8601String().substring(0, 10),
      // A date type without a date says nothing and reads as though a date
      // was recorded, so it is only stored alongside one.
      if (printedDate != null && (printedDateType ?? '').isNotEmpty)
        'printed_date_type': printedDateType,
      'source_type': source,
    });
    return '';
  } on PostgrestException catch (error) {
    if (error.code == '42501') {
      return 'Your account is not allowed to add to this household.';
    }
    return error.message;
  } catch (error) {
    return 'Could not add it. $error';
  }
}

/// Our own copy of an Open Food Facts photo, or their link if it cannot be
/// made. A picture that may one day go stale is better than none, so a failed
/// copy never stops the food being added.
Future<String> _keepOwnCopy(String url, String household) async {
  // The lookup returns the 200px thumbnail. The item screen shows the photo
  // large, so the 400px display size is fetched when it exists.
  final larger = url.replaceFirst(RegExp(r'\.200\.jpg$'), '.400.jpg');
  try {
    var res = await http
        .get(Uri.parse(larger))
        .timeout(const Duration(seconds: 10));
    if (res.statusCode != 200 && larger != url) {
      res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
    }
    if (res.statusCode != 200 || res.bodyBytes.isEmpty) return url;

    final path = '$household/product-${const Uuid().v4()}.jpg';
    final storage = SupaFlow.client.storage.from('food-images');
    await storage.uploadBinary(
      path,
      res.bodyBytes,
      fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: false),
    );
    // A year, the same as a photo taken in the app.
    return await storage.createSignedUrl(path, 60 * 60 * 24 * 365);
  } catch (_) {
    return url;
  }
}
''',
    );
  });
}
