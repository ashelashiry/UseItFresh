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

/// Build 6: the photo map. A shelf photo with each food outlined and
/// numbered on it; tick (yes), cross (no) or fix each one; add the ticked ones.
///
/// The owner's brief: taking a photo of the fridge or pantry is the app.
/// Typing things in takes too long and nobody will do it. So:
///   * the photo reader returns an outline and a container type per food
///     (recognise-food, mode "shelf", after the next paste);
///   * the review is the photo itself, drawn by one custom widget
///     (ShelfReview), with the list below it and fixing done in place;
///   * one tap says where the photo was taken (Fridge / Freezer / Pantry), and
///     each food can be moved on its own;
///   * no dates to type: food gets a typical keep time from its category.
///
/// Receipts keep their list review: a receipt has nothing to outline.
///
/// Everything the photo map needs is new (MapFood, mapFoods, ReadShelfPhoto,
/// SaveMapFoods, ClearShelfScan, ShelfReview, MapReviewPage), so the receipt
/// flow cannot be disturbed by it. The Fridge photo tile moves over to it.
void buildStarterEditFlow(App app) {
  final mapFood = app.struct('MapFood', {
    'name': string,
    'category': string,
    'quantity': int_,
    // What it comes in: carton, jar, bottle, loose...
    'kind': string,
    // Its outline on the photo: "ymin,xmin,ymax,xmax" on a 0-1000 scale.
    'box': string,
    // The signed URL of the photo it was found on.
    'photo': string,
    // '' not checked yet, 'yes' add it, 'no' leave it out.
    'decision': string,
    // '' follows the photo's place; 'fridge' / 'freezer' / 'pantry' overrides.
    'place': string,
  });

  app.state('mapFoods', listOf(mapFood));
  app.state('mapPhotos', listOf(string));
  app.state('mapPlace', string.withDefault('fridge'));
  app.state('mapReading', bool_.withDefault(false));

  // -- reading a shelf photo ----------------------------------------------------
  app.customAction(
    'ReadShelfPhoto',
    args: {},
    returns: string,
    description:
        'Photographs one shelf, has its foods read and outlined, and adds them '
        "to the photo map. Returns 'ok', '' when the camera was closed, or a "
        'message.',
    code: r'''
import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

/// Photographs one shelf, has the foods on it read and outlined, and adds them
/// to the photo map.
///
/// Returns 'ok' when there is something to review, '' when the person backed
/// out of the camera (not an error, so nothing is said), and otherwise a
/// sentence saying why not.
///
/// The photo is kept until the map is saved or cleared, because the map is
/// drawn on it. A photo that gave nothing to review is deleted straight away.
Future<String> readShelfPhoto() async {
  const sorry = 'Could not read that photo. Try again closer up.';
  final household = FFAppState().currentHouseholdId;
  if (household.isEmpty) {
    return 'No household yet. Create or join one before adding food.';
  }

  final shot = await ImagePicker().pickImage(
    source: ImageSource.camera,
    maxWidth: 1600,
    maxHeight: 1600,
    imageQuality: 85,
  );
  if (shot == null) return '';

  FFAppState().update(() => FFAppState().mapReading = true);
  final storage = SupaFlow.client.storage.from('food-images');
  final path = '$household/shelf-${const Uuid().v4()}.jpg';
  var uploaded = false;
  var keep = false;
  try {
    final Uint8List bytes = await shot.readAsBytes();
    await storage.uploadBinary(
      path,
      bytes,
      fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: false),
    );
    uploaded = true;
    // An hour: long enough to go through the map. It is deleted on save.
    final url = await storage.createSignedUrl(path, 3600);

    final res = await SupaFlow.client.functions
        .invoke('recognise-food', body: {'imageUrl': url, 'mode': 'shelf'});
    final data = res.data;
    if (data is! Map) return sorry;
    if (data['error'] != null) return data['error'].toString();
    final raw = data['items'] is List ? data['items'] as List : const [];

    final foods = <MapFoodStruct>[];
    for (final r in raw) {
      if (r is! Map) continue;
      final said = (r['name'] ?? '').toString().trim();
      if (said.isEmpty) continue;
      final counted =
          r['quantity'] is num ? (r['quantity'] as num).round() : 1;
      foods.add(MapFoodStruct(
        // Sentence case, as the rest of the app writes food names.
        name: said[0].toUpperCase() + said.substring(1),
        category: (r['category'] ?? '').toString(),
        quantity: counted < 1 ? 1 : counted,
        kind: (r['kind'] ?? '').toString(),
        box: (r['box'] ?? '').toString(),
        photo: url,
        decision: '',
        place: '',
      ));
    }
    if (foods.isEmpty) {
      final note = (data['note'] ?? '').toString();
      return note.isNotEmpty ? note : sorry;
    }

    keep = true;
    FFAppState().update(() {
      FFAppState().mapPhotos = [...FFAppState().mapPhotos, url];
      FFAppState().mapFoods = [...FFAppState().mapFoods, ...foods];
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
    FFAppState().update(() => FFAppState().mapReading = false);
    if (uploaded && !keep) {
      try {
        await storage.remove([path]);
      } catch (_) {}
    }
  }
}
''',
  );

  // -- saving the ticked foods ----------------------------------------------------
  app.customAction(
    'SaveMapFoods',
    args: {},
    returns: string,
    description:
        'Adds every ticked food on the photo map in one insert, each in its '
        'place, then deletes the photos. Returns an empty string on success, '
        'or a message saying why not.',
    code: r'''
import 'package:supabase_flutter/supabase_flutter.dart';

/// Adds every ticked food on the photo map, in one insert, then deletes the
/// photos the map was drawn on.
///
/// One insert, so it is all or nothing. The map is emptied before the write,
/// so a second tap while the first is still saving finds nothing to add twice;
/// if the write fails, everything comes back.
Future<String> saveMapFoods() async {
  final all = List<MapFoodStruct>.of(FFAppState().mapFoods);
  final photos = List<String>.of(FFAppState().mapPhotos);
  final ticked = all.where((f) => f.decision == 'yes').toList();
  if (ticked.isEmpty) return 'Tick at least one food to add.';

  final household = FFAppState().currentHouseholdId;
  if (household.isEmpty) {
    return 'No household yet. Create or join one before adding food.';
  }
  final photoPlace =
      FFAppState().mapPlace.isEmpty ? 'fridge' : FFAppState().mapPlace;
  final uid = SupaFlow.client.auth.currentUser?.id;

  void putBack() => FFAppState().update(() {
        FFAppState().mapFoods = all;
        FFAppState().mapPhotos = photos;
      });

  FFAppState().update(() {
    FFAppState().mapFoods = [];
    FFAppState().mapPhotos = [];
  });
  try {
    final rows = await SupaFlow.client
        .from('storage_locations')
        .select('id, location_type, is_default')
        .eq('household_id', household);
    final locations = List<Map<String, dynamic>>.from(rows as List);
    String? locationFor(String type) {
      for (final l in locations) {
        if (l['location_type'] == type) return l['id'].toString();
      }
      for (final l in locations) {
        if (l['is_default'] == true) return l['id'].toString();
      }
      return locations.isEmpty ? null : locations.first['id'].toString();
    }

    await SupaFlow.client.from('food_items').insert([
      for (final f in ticked)
        {
          'household_id': household,
          'storage_location_id':
              locationFor(f.place.isEmpty ? photoPlace : f.place),
          'created_by': uid,
          'name': f.name,
          if (f.category.isNotEmpty) 'category': f.category,
          'quantity': f.quantity < 1 ? 1 : f.quantity,
          'source_type': 'fridge_scan',
        },
    ]);
  } on PostgrestException catch (error) {
    putBack();
    if (error.code == '42501') {
      return 'Your account is not allowed to add to this household.';
    }
    return error.message;
  } catch (_) {
    putBack();
    return 'Could not add them. Check your signal and try again.';
  }

  // The photos were only needed for the map.
  final paths = [for (final u in photos) _storagePath(u)]
      .whereType<String>()
      .toList();
  if (paths.isNotEmpty) {
    try {
      await SupaFlow.client.storage.from('food-images').remove(paths);
    } catch (_) {}
  }
  return '';
}

/// The object path inside the food-images bucket, from a signed URL.
String? _storagePath(String signedUrl) {
  const marker = '/object/sign/food-images/';
  final at = signedUrl.indexOf(marker);
  if (at < 0) return null;
  final rest = signedUrl.substring(at + marker.length);
  final q = rest.indexOf('?');
  return Uri.decodeComponent(q < 0 ? rest : rest.substring(0, q));
}
''',
  );

  // -- starting over --------------------------------------------------------------
  app.customAction(
    'ClearShelfScan',
    args: {},
    returns: string,
    description:
        'Empties the photo map and deletes its photos, so the next shelf starts '
        'fresh. Always returns an empty string.',
    code: r'''
import 'package:supabase_flutter/supabase_flutter.dart';

/// Empties the photo map and deletes its photos. Used when a new map starts
/// and when someone backs out of one, so photos never pile up in storage.
Future<String> clearShelfScan() async {
  final photos = List<String>.of(FFAppState().mapPhotos);
  FFAppState().update(() {
    FFAppState().mapFoods = [];
    FFAppState().mapPhotos = [];
    FFAppState().mapPlace = 'fridge';
  });
  final paths = [for (final u in photos) _storagePath(u)]
      .whereType<String>()
      .toList();
  if (paths.isNotEmpty) {
    try {
      await SupaFlow.client.storage.from('food-images').remove(paths);
    } catch (_) {}
  }
  return '';
}

/// The object path inside the food-images bucket, from a signed URL.
String? _storagePath(String signedUrl) {
  const marker = '/object/sign/food-images/';
  final at = signedUrl.indexOf(marker);
  if (at < 0) return null;
  final rest = signedUrl.substring(at + marker.length);
  final q = rest.indexOf('?');
  return Uri.decodeComponent(q < 0 ? rest : rest.substring(0, q));
}
''',
  );

  // -- what the page says -----------------------------------------------------------
  final nothingTicked = app.customFunction(
    'noMapYes',
    args: {'items': listOf(mapFood)},
    returns: bool_,
    description: 'Whether nothing on the photo map has been ticked yet.',
    code: r"""
return !(items ?? []).any((f) => f.decision == 'yes');
""",
  );

  // -- the photo map itself -----------------------------------------------------------
  app.customWidget(
    'ShelfReview',
    parameters: {},
    description:
        'The photo map: where the photo was taken, each photo with its foods '
        'outlined and numbered, and the list to tick, cross or fix each one. '
        'Reads and writes the photo map in app state.',
    code: r'''
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// The photo map: each shelf photo with its foods outlined and numbered, and
/// the list below to tick (yes), cross (no) or fix each one in place.
///
/// Reads the map from app state rather than taking it as a parameter:
/// FlutterFlow cannot pass a list to a custom widget.
class ShelfReview extends StatefulWidget {
  const ShelfReview({super.key, this.width, this.height});

  final double? width;
  final double? height;

  @override
  State<ShelfReview> createState() => _ShelfReviewState();
}

class _ShelfReviewState extends State<ShelfReview> {
  // The same words the category picker uses.
  static const _categoryNames = <String, String>{
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
  static const _places = <String, String>{
    'fridge': 'Fridge',
    'freezer': 'Freezer',
    'pantry': 'Pantry',
  };

  int _selected = -1;
  int _editing = -1;
  final Map<int, TextEditingController> _names = {};

  @override
  void dispose() {
    for (final c in _names.values) {
      c.dispose();
    }
    super.dispose();
  }

  MapFoodStruct _copy(MapFoodStruct f,
          {String? name, String? category, String? decision, String? place}) =>
      MapFoodStruct(
        name: name ?? f.name,
        category: category ?? f.category,
        quantity: f.quantity,
        kind: f.kind,
        box: f.box,
        photo: f.photo,
        decision: decision ?? f.decision,
        place: place ?? f.place,
      );

  void _change(int i, MapFoodStruct Function(MapFoodStruct) change) {
    FFAppState().update(() => FFAppState().updateMapFoodsAtIndex(i, change));
  }

  void _decide(int i, String decision) {
    final now = FFAppState().mapFoods[i].decision == decision ? '' : decision;
    _change(i, (f) => _copy(f, decision: now));
    final next = FFAppState().mapFoods.indexWhere((f) => f.decision.isEmpty);
    setState(() => _selected = next >= 0 ? next : i);
  }

  void _yesToTheRest() {
    FFAppState().update(() {
      final foods = FFAppState().mapFoods;
      for (var i = 0; i < foods.length; i++) {
        if (foods[i].decision.isEmpty) {
          FFAppState()
              .updateMapFoodsAtIndex(i, (f) => _copy(f, decision: 'yes'));
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();
    final t = FlutterFlowTheme.of(context);
    final foods = FFAppState().mapFoods;
    final photos = FFAppState().mapPhotos;
    final place =
        FFAppState().mapPlace.isEmpty ? 'fridge' : FFAppState().mapPlace;
    if (_selected >= foods.length) _selected = -1;
    final checked = foods.where((f) => f.decision.isNotEmpty).length;

    return SizedBox(
      width: widget.width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _placeChips(t, place),
          const SizedBox(height: 12),
          for (final url in photos) ...[
            _PhotoMap(
              url: url,
              selected: _selected,
              entries: [
                for (var i = 0; i < foods.length; i++)
                  if (foods[i].photo == url) MapEntry(i, foods[i]),
              ],
              onTap: (i) => setState(() => _selected = i),
            ),
            const SizedBox(height: 10),
          ],
          Row(
            children: [
              Expanded(
                child: Text(
                  '$checked of ${foods.length} checked',
                  style: t.bodySmall.copyWith(color: t.secondaryText),
                ),
              ),
              if (checked < foods.length)
                TextButton(
                  onPressed: _yesToTheRest,
                  child: Text(
                    'Yes to the rest',
                    style: t.bodySmall.copyWith(
                        color: t.primary, fontWeight: FontWeight.w700),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          for (var i = 0; i < foods.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _row(t, i, foods[i], place),
            ),
        ],
      ),
    );
  }

  Widget _placeChips(FlutterFlowTheme t, String place) => Wrap(
        spacing: 6,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text('This is the',
              style: t.bodySmall.copyWith(color: t.secondaryText)),
          for (final e in _places.entries)
            Semantics(
              button: true,
              selected: place == e.key,
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () =>
                    FFAppState().update(() => FFAppState().mapPlace = e.key),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: place == e.key ? t.primary : t.secondaryBackground,
                    border: Border.all(
                        color: place == e.key ? t.primary : t.alternate),
                  ),
                  child: Text(
                    e.value,
                    style: t.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: place == e.key ? Colors.white : t.primaryText,
                    ),
                  ),
                ),
              ),
            ),
        ],
      );

  Widget _row(FlutterFlowTheme t, int i, MapFoodStruct f, String place) {
    final yes = f.decision == 'yes';
    final no = f.decision == 'no';
    final selected = i == _selected;
    final where = _places[f.place.isEmpty ? place : f.place] ?? 'Fridge';
    final detail = <String>[
      if (f.quantity > 1) '${f.quantity}',
      if (f.kind.isNotEmpty) f.kind,
      _categoryNames[f.category] ?? 'No category',
      where,
    ].join(' · ');

    return Opacity(
      opacity: no ? 0.55 : 1,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
        decoration: BoxDecoration(
          color: t.secondaryBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? t.primary : t.alternate,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: yes
                        ? t.primary
                        : (no ? t.error.withOpacity(0.15) : t.accent1),
                  ),
                  child: Text(
                    '${i + 1}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: yes ? Colors.white : (no ? t.error : t.primary),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() {
                      _selected = i;
                      _editing = _editing == i ? -1 : i;
                    }),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          f.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: t.titleSmall.copyWith(
                            decoration: no ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        Text(
                          detail,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: t.bodySmall.copyWith(color: t.secondaryText),
                        ),
                      ],
                    ),
                  ),
                ),
                _round(t, '✓', yes, t.primary, () => _decide(i, 'yes'),
                    'Yes, add ${f.name}'),
                const SizedBox(width: 6),
                _round(t, '✕', no, t.error, () => _decide(i, 'no'),
                    'No, leave out ${f.name}'),
              ],
            ),
            if (_editing == i) _editor(t, i, f, place),
          ],
        ),
      ),
    );
  }

  Widget _round(FlutterFlowTheme t, String glyph, bool on, Color colour,
          VoidCallback onTap, String label) =>
      Semantics(
        button: true,
        label: label,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: on ? colour : t.secondaryBackground,
              border: Border.all(color: on ? colour : t.alternate),
            ),
            child: Text(
              glyph,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: on ? Colors.white : t.secondaryText,
              ),
            ),
          ),
        ),
      );

  Widget _editor(FlutterFlowTheme t, int i, MapFoodStruct f, String place) {
    final controller =
        _names.putIfAbsent(i, () => TextEditingController(text: f.name));
    InputDecoration look(String label) => InputDecoration(
          labelText: label,
          isDense: true,
          filled: true,
          fillColor: t.primaryBackground,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: t.alternate),
          ),
        );
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: controller,
            decoration: look('Name'),
            onChanged: (v) {
              if (v.trim().isNotEmpty) {
                _change(i, (x) => _copy(x, name: v.trim(), decision: 'yes'));
              }
            },
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value:
                      _categoryNames.containsKey(f.category) ? f.category : null,
                  isExpanded: true,
                  decoration: look('Category'),
                  items: [
                    for (final e in _categoryNames.entries)
                      DropdownMenuItem(
                        value: e.key,
                        child: Text(e.value, overflow: TextOverflow.ellipsis),
                      ),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      _change(i, (x) => _copy(x, category: v, decision: 'yes'));
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: f.place.isEmpty ? place : f.place,
                  isExpanded: true,
                  decoration: look('Kept in'),
                  items: [
                    for (final e in _places.entries)
                      DropdownMenuItem(value: e.key, child: Text(e.value)),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      _change(i, (x) => _copy(x, place: v, decision: 'yes'));
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// One photo with its foods outlined. The photo is shown at its own shape,
/// so an outline given on a 0-1000 scale lands where the food is.
class _PhotoMap extends StatefulWidget {
  const _PhotoMap({
    required this.url,
    required this.entries,
    required this.selected,
    required this.onTap,
  });

  final String url;
  final List<MapEntry<int, MapFoodStruct>> entries;
  final int selected;
  final void Function(int) onTap;

  @override
  State<_PhotoMap> createState() => _PhotoMapState();
}

class _PhotoMapState extends State<_PhotoMap> {
  double? _aspect;
  ImageStream? _stream;
  ImageStreamListener? _listener;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(_PhotoMap old) {
    super.didUpdateWidget(old);
    if (old.url != widget.url) _resolve();
  }

  void _resolve() {
    _stop();
    final stream = NetworkImage(widget.url).resolve(ImageConfiguration.empty);
    final listener = ImageStreamListener((info, _) {
      if (!mounted) return;
      setState(() => _aspect = info.image.width / info.image.height);
    }, onError: (_, __) {});
    stream.addListener(listener);
    _stream = stream;
    _listener = listener;
  }

  void _stop() {
    final stream = _stream, listener = _listener;
    if (stream != null && listener != null) stream.removeListener(listener);
  }

  @override
  void dispose() {
    _stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: AspectRatio(
        aspectRatio: _aspect ?? 3 / 4,
        child: LayoutBuilder(
          builder: (context, c) {
            final w = c.maxWidth, h = c.maxHeight;
            return Stack(
              children: [
                Positioned.fill(
                  child: Image.network(
                    widget.url,
                    fit: BoxFit.fill,
                    errorBuilder: (_, __, ___) => Container(color: t.alternate),
                  ),
                ),
                for (final e in widget.entries) ..._outline(t, e.key, e.value, w, h),
              ],
            );
          },
        ),
      ),
    );
  }

  List<Widget> _outline(
      FlutterFlowTheme t, int i, MapFoodStruct f, double w, double h) {
    final p = f.box.split(',').map((s) => double.tryParse(s.trim())).toList();
    if (p.length != 4 || p.any((v) => v == null)) return const [];
    final top = p[0]! / 1000 * h, left = p[1]! / 1000 * w;
    final bh = (p[2]! - p[0]!) / 1000 * h, bw = (p[3]! - p[1]!) / 1000 * w;
    if (bw < 6 || bh < 6) return const [];

    final yes = f.decision == 'yes', no = f.decision == 'no';
    final selected = i == widget.selected;
    final edge = yes
        ? const Color(0xFF3FD08B)
        : (no ? const Color(0xFFFF8E78) : Colors.white);
    final mark = yes ? '✓ ' : (no ? '✕ ' : '');
    final label = bw < 90 ? '${i + 1}' : '${i + 1} ${f.name}';

    return [
      Positioned(
        left: left,
        top: top,
        width: bw,
        height: bh,
        child: Semantics(
          button: true,
          label: '${i + 1}. ${f.name}',
          child: GestureDetector(
            onTap: () => widget.onTap(i),
            child: Container(
              alignment: Alignment.topLeft,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: no
                    ? Colors.black.withOpacity(0.45)
                    : (yes ? t.primary.withOpacity(0.14) : Colors.transparent),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: edge, width: yes ? 3 : 2),
                boxShadow: [
                  if (selected)
                    const BoxShadow(color: Colors.white, spreadRadius: 3)
                  else
                    const BoxShadow(color: Color(0x55000000), blurRadius: 2),
                ],
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                decoration: BoxDecoration(
                  color: yes ? t.primary : (no ? t.error : Colors.white),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$mark$label',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: (yes || no) ? Colors.white : t.primaryText,
                    decoration: no ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ];
  }
}
''',
  );

  // -- the review page --------------------------------------------------------------
  final readMore = [
    CallCustomAction.named(
      'ReadShelfPhoto',
      args: {},
      returnType: string,
      arguments: {},
      outputAs: 'readMore',
    ),
    // 'ok' needs nothing said: the new photo appears on the map.
    If(
      Not(Equals(ActionOutput('readMore'), 'ok')),
      then: [
        If(
          Not(Equals(ActionOutput('readMore'), '')),
          then: [Snackbar(ActionOutput('readMore'))],
        ),
      ],
    ),
  ];

  app.ensurePage(
    'MapReviewPage',
    description:
        'The photo map: shelf photos with their foods outlined, to tick, cross '
        'or fix before anything is added.',
    route: 'shelf-review',
    body: Scaffold(
      body: Container(
        name: 'MapReviewBody',
        padding:
            const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 20),
        child: Column(
          scrollable: true,
          crossAxis: CrossAxis.stretch,
          spacing: 12,
          children: [
            Row(
              name: 'MapReviewBackRow',
              mainAxis: MainAxis.start,
              children: [
                Container(
                  name: 'MapReviewBack',
                  // Backing out drops the map and deletes its photos.
                  onTap: [
                    CallCustomAction.named(
                      'ClearShelfScan',
                      args: {},
                      returnType: string,
                      arguments: {},
                      outputAs: 'clearedOnBack',
                    ),
                    NavigateBack(),
                  ],
                  width: 44,
                  height: 44,
                  color: Colors.secondaryBackground,
                  borderColor: Colors.alternate,
                  borderWidth: 1,
                  borderRadius: 999,
                  child:
                      Icon('arrow_back', size: 20, color: Colors.primaryText),
                ),
              ],
            ),
            Text('Check what we found.',
                name: 'MapReviewHeadline',
                style: Styles.headlineMedium,
                color: Colors.primary),
            Text(
              'Tap an outline or its line: ✓ to add it, ✕ to leave it out, or '
              'tap the name to fix it.',
              name: 'MapReviewLede',
              style: Styles.bodyMedium,
              color: Colors.secondaryText,
            ),
            Container(
              name: 'MapReading',
              visible: AppState('mapReading'),
              color: Colors.accent1,
              borderRadius: 14,
              padding: const EdgeInsets.only(
                  left: 16, right: 16, top: 14, bottom: 14),
              child: Row(
                crossAxis: CrossAxis.center,
                spacing: 12,
                children: [
                  ProgressBar.circular(size: 22, thickness: 3),
                  Expanded(
                    Text(
                      'Reading your photo. This takes a few seconds.',
                      name: 'MapReadingText',
                      style: Styles.bodyMedium,
                      color: Colors.primaryText,
                    ),
                  ),
                ],
              ),
            ),
            CustomWidget(
              widgetName: 'ShelfReview',
              name: 'MapReviewMap',
              arguments: {},
            ),
            Button(
              '+ Add another photo',
              name: 'MapReviewAnother',
              width: double.infinity,
              height: 48,
              borderRadius: 14,
              color: Colors.secondaryBackground,
              textColor: Colors.primary,
              onTap: readMore,
            ),
            Text(
              'No dates to type. Each food gets a typical keep time for where '
              'it is kept. Add a printed date later if you want an exact '
              'reminder.',
              name: 'MapReviewKeeps',
              style: Styles.bodySmall,
              color: Colors.secondaryText,
            ),
            Text(
              'Tick at least one food to add it.',
              name: 'MapReviewNoneTicked',
              visible: CustomFunction(nothingTicked,
                  args: {'items': AppState('mapFoods')}),
              style: Styles.bodySmall,
              color: Colors.secondaryText,
            ),
            Button(
              'Add the ticked foods to your kitchen',
              name: 'MapReviewAdd',
              visible: Not(CustomFunction(nothingTicked,
                  args: {'items': AppState('mapFoods')})),
              width: double.infinity,
              height: 50,
              borderRadius: 14,
              color: Colors.primary,
              textColor: Colors.secondaryBackground,
              onTap: [
                CallCustomAction.named(
                  'SaveMapFoods',
                  args: {},
                  returnType: string,
                  arguments: {},
                  outputAs: 'savedMap',
                ),
                If(
                  Equals(ActionOutput('savedMap'), ''),
                  then: [
                    Snackbar('Added to your kitchen.'),
                    Navigate(ff.Pages.inventoryPage),
                  ],
                  orElse: [Snackbar(ActionOutput('savedMap'))],
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  // -- the Fridge photo tile opens the photo map --------------------------------------
  final scan = ff.Pages.scanAddPage;
  app.editPage(scan, (page) {
    page.ensureActions(
      scan.widgets.byKey('Container_u78daphn').single,
      triggerType: FFActionTriggerType.ON_TAP,
      actions: [
        // A fresh map each time: photos from an unfinished one are deleted.
        CallCustomAction.named(
          'ClearShelfScan',
          args: {},
          returnType: string,
          arguments: {},
          outputAs: 'clearedForShelf',
        ),
        CallCustomAction.named(
          'ReadShelfPhoto',
          args: {},
          returnType: string,
          arguments: {},
          outputAs: 'readShelf',
        ),
        If(
          Equals(ActionOutput('readShelf'), 'ok'),
          then: [Navigate('MapReviewPage')],
          orElse: [
            If(
              Not(Equals(ActionOutput('readShelf'), '')),
              then: [Snackbar(ActionOutput('readShelf'))],
            ),
          ],
        ),
      ],
    );
  });
}
