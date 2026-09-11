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

/// Food names from a photo in sentence case.
///
/// The receipt read came back as "Semi-skimmed milk"; the shelf read came
/// back as "brown mushrooms". Everything else in the app writes food names in
/// sentence case, so the first letter is raised before the review list.
void buildStarterEditFlow(App app) {
  app.raw((project) {
    updateCustomAction(
      project,
      name: 'ReadPhotoFoods',
      code: r'''
import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

/// Reads several foods from one photo: a till receipt, or a fridge shelf.
///
/// Returns 'ok' when there is something to review, '' when the person backed
/// out of the camera (not an error, so nothing is said), and otherwise a
/// sentence saying why not.
///
/// The photo is deleted as soon as it has been read. A receipt carries the
/// shop, the time and part of a card number, and none of it is needed.
///
/// Each food is given a place from its category (milk to the fridge, peas to
/// the freezer, pasta to the cupboard) using this household's own locations,
/// so the review screen can say where it will go.
Future<String> readPhotoFoods(String? mode) async {
  final kind = mode == 'shelf' ? 'shelf' : 'receipt';
  final sorry = kind == 'receipt'
      ? 'Could not read that receipt. Try a flatter, brighter photo.'
      : 'Could not read that photo. Try again closer up.';

  final household = FFAppState().currentHouseholdId;
  if (household.isEmpty) {
    return 'No household yet. Create or join one before adding food.';
  }

  final shot = await ImagePicker().pickImage(
    source: ImageSource.camera,
    // Receipts are long and the print is small, so they get more pixels.
    maxWidth: kind == 'receipt' ? 2000 : 1600,
    maxHeight: kind == 'receipt' ? 3200 : 1600,
    imageQuality: 85,
  );
  if (shot == null) return '';

  FFAppState().update(() => FFAppState().scanReading = true);
  final client = SupaFlow.client;
  final storage = client.storage.from('food-images');
  final path = '$household/scan-${const Uuid().v4()}.jpg';
  var uploaded = false;
  try {
    final Uint8List bytes = await shot.readAsBytes();
    await storage.uploadBinary(
      path,
      bytes,
      fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: false),
    );
    uploaded = true;
    // Ten minutes: it is read once, straight away, and then deleted.
    final url = await storage.createSignedUrl(path, 600);

    final res = await client.functions
        .invoke('recognise-food', body: {'imageUrl': url, 'mode': kind});
    final data = res.data;
    if (data is! Map) return sorry;
    if (data['error'] != null) return data['error'].toString();
    final raw = data['items'] is List ? data['items'] as List : const [];
    if (raw.isEmpty) {
      final note = (data['note'] ?? '').toString();
      return note.isNotEmpty ? note : sorry;
    }

    // The same words the category picker uses.
    const labels = <String, String>{
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
    // Where each kind of food usually lives. Unknown goes to the default.
    const homes = <String, String>{
      'dairy': 'fridge',
      'meat_poultry': 'fridge',
      'seafood': 'fridge',
      'eggs': 'fridge',
      'cooked_leftovers': 'fridge',
      'fruit': 'fridge',
      'vegetables': 'fridge',
      'frozen': 'freezer',
      'bread_bakery': 'pantry',
      'pantry_dry': 'pantry',
      'condiments_sauces': 'pantry',
      'infant_food': 'pantry',
    };

    final rows = await client
        .from('storage_locations')
        .select('id, name, location_type, is_default')
        .eq('household_id', household);
    final places = List<Map<String, dynamic>>.from(rows as List);
    Map<String, dynamic>? fallback;
    for (final p in places) {
      if (p['is_default'] == true) {
        fallback = p;
        break;
      }
    }
    fallback ??= places.isNotEmpty ? places.first : null;
    Map<String, dynamic>? placeFor(String category) {
      final type = homes[category];
      if (type != null) {
        for (final p in places) {
          if (p['location_type'] == type) return p;
        }
      }
      return fallback;
    }

    final foods = <ScannedFoodStruct>[];
    for (final r in raw) {
      if (r is! Map) continue;
      final said = (r['name'] ?? '').toString().trim();
      if (said.isEmpty) continue;
      // Sentence case, as the rest of the app writes food names. A shelf
      // photo sometimes comes back in lower case ("brown mushrooms").
      final name = said[0].toUpperCase() + said.substring(1);
      final category = (r['category'] ?? '').toString();
      final counted = r['quantity'] is num ? (r['quantity'] as num).round() : 1;
      final quantity = counted < 1 ? 1 : counted;
      final place = placeFor(category);
      final detail = <String>[
        if (quantity > 1) '$quantity of them',
        labels[category] ?? 'No category',
        if (place != null) (place['name'] ?? '').toString(),
      ].where((s) => s.isNotEmpty).join(' · ');
      foods.add(ScannedFoodStruct(
        name: name,
        category: labels.containsKey(category) ? category : '',
        quantity: quantity,
        place: place == null ? '' : place['id'].toString(),
        detail: detail,
      ));
    }
    if (foods.isEmpty) return sorry;

    FFAppState().update(() {
      FFAppState().scannedFoods = foods;
      FFAppState().scannedFrom = kind;
    });
    return 'ok';
  } on FunctionException catch (error) {
    final details = error.details;
    if (details is Map && details['error'] != null) {
      return details['error'].toString();
    }
    return sorry;
  } catch (_) {
    return sorry;
  } finally {
    FFAppState().update(() => FFAppState().scanReading = false);
    if (uploaded) {
      try {
        await storage.remove([path]);
      } catch (_) {}
    }
  }
}
''',
    );
  });
}
