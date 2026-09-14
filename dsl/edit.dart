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
// ignore: implementation_imports
import 'package:flutterflow_ai/src/helpers/ensure_helpers.dart' show ensureDataStructField;
// ignore: implementation_imports
import 'package:flutterflow_ai/src/helpers/data_type_helpers.dart' show stringType;

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

/// Product image dataset, from day one (owner's business idea, 14 Sep): each
/// shelf-photo cut-out is recorded in product_images as source shelf_crop,
/// with the name, the person's country and their sharing consent (default
/// off). Nothing is shared anywhere; this only keeps the record honest.
void buildStarterEditFlow(App app) {
  app.raw((project) {
    updateCustomAction(project, name: 'SaveMapFoods', code: _saveMapFoods);
  });
}

const _saveMapFoods = r'''
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show compute;
import 'package:image/image.dart' as img;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

/// Adds every ticked food on the photo map, in one insert, each with its own
/// picture cut from the shelf photo, then deletes the shelf photos.
///
/// One insert, so it is all or nothing. The map is emptied before the write,
/// so a second tap while the first is still saving finds nothing to add twice;
/// if the write fails, everything comes back.
///
/// A food given a use-by date on the map is saved with it as the printed
/// date; the rest get the typical keep time for their category.
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

  final storage = SupaFlow.client.storage.from('food-images');
  // Each food's own picture, where one can be cut. Index-matched to `ticked`.
  final pictures = await _cutPictures(ticked, household, storage);

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
      for (var i = 0; i < ticked.length; i++)
        {
          'household_id': household,
          'storage_location_id': locationFor(
              ticked[i].place.isEmpty ? photoPlace : ticked[i].place),
          'created_by': uid,
          'name': ticked[i].name,
          if (ticked[i].category.isNotEmpty) 'category': ticked[i].category,
          'quantity': ticked[i].quantity < 1 ? 1 : ticked[i].quantity,
          'source_type': 'fridge_scan',
          if (pictures[i].isNotEmpty) 'image_url': pictures[i],
          if (DateTime.tryParse(ticked[i].useBy) != null) ...{
            'printed_date': ticked[i].useBy,
            'printed_date_type': 'use_by',
          },
        },
    ]);
  } on PostgrestException catch (error) {
    putBack();
    await _removeQuietly(storage, pictures);
    if (error.code == '42501') {
      return 'Your account is not allowed to add to this household.';
    }
    return error.message;
  } catch (_) {
    putBack();
    await _removeQuietly(storage, pictures);
    return 'Could not add them. Check your signal and try again.';
  }

  // Each cut-out is also a picture of that product, as sold here: recorded
  // with the person's country and their choice about sharing (off unless they
  // said yes). Extra: a failure here never affects the food.
  await _recordCrops(ticked, pictures, household, uid);

  // The shelf photos were only needed for the map; the cut pictures stay.
  final paths =
      [for (final u in photos) _storagePath(u)].whereType<String>().toList();
  if (paths.isNotEmpty) {
    try {
      await storage.remove(paths);
    } catch (_) {}
  }
  return '';
}

Future<void> _recordCrops(List<MapFoodStruct> foods, List<String> pictures,
    String household, String? uid) async {
  if (uid == null || !pictures.any((p) => p.isNotEmpty)) return;
  try {
    final client = SupaFlow.client;
    final profile = await client
        .from('profiles')
        .select('country_code')
        .eq('id', uid)
        .maybeSingle();
    final cc = '${profile?['country_code'] ?? ''}'.toUpperCase();
    final settings = await client
        .from('user_settings')
        .select('share_product_photos')
        .eq('profile_id', uid)
        .maybeSingle();
    final consent = settings?['share_product_photos'] == true;
    final rows = [
      for (var i = 0; i < foods.length && i < pictures.length; i++)
        if (_storagePath(pictures[i]) != null)
          {
            'household_id': household,
            'name_key': foods[i].name.trim().toLowerCase(),
            if (RegExp(r'^[A-Z]{2}$').hasMatch(cc)) 'country_code': cc,
            'storage_path': _storagePath(pictures[i]),
            'source': 'shelf_crop',
            'share_consent': consent,
            'created_by': uid,
          }
    ];
    if (rows.isNotEmpty) await client.from('product_images').insert(rows);
  } catch (_) {}
}

/// A signed URL for each ticked food's own picture, or '' where none could be
/// cut. Photos are downloaded once each; the cutting runs off the main thread
/// on the phone so the screen does not freeze.
Future<List<String>> _cutPictures(
    List<MapFoodStruct> foods, String household, StorageFileApi storage) async {
  final out = List<String>.filled(foods.length, '');
  final byPhoto = <String, List<int>>{};
  for (var i = 0; i < foods.length; i++) {
    if (foods[i].photo.isEmpty || _box(foods[i].box) == null) continue;
    byPhoto.putIfAbsent(foods[i].photo, () => []).add(i);
  }
  for (final entry in byPhoto.entries) {
    final path = _storagePath(entry.key);
    if (path == null) continue;
    try {
      final bytes = await storage.download(path);
      final boxes = [for (final i in entry.value) foods[i].box];
      final crops = await compute(_cropAll, {'bytes': bytes, 'boxes': boxes});
      for (var k = 0; k < entry.value.length; k++) {
        final crop = crops[k];
        if (crop == null) continue;
        final cropPath = '$household/item-${const Uuid().v4()}.jpg';
        await storage.uploadBinary(
          cropPath,
          crop,
          fileOptions:
              const FileOptions(contentType: 'image/jpeg', upsert: false),
        );
        // A year, the same as a photo taken on the Add food form.
        out[entry.value[k]] =
            await storage.createSignedUrl(cropPath, 60 * 60 * 24 * 365);
      }
    } catch (_) {
      // No picture for these foods; they are still added.
    }
  }
  return out;
}

/// Cuts each outline out of one photo. Runs in a background isolate on the
/// phone (compute), so it only takes plain data and returns plain data.
List<Uint8List?> _cropAll(Map<String, Object> args) {
  final bytes = args['bytes'] as Uint8List;
  final boxes = (args['boxes'] as List).cast<String>();
  final photo = img.decodeImage(bytes);
  if (photo == null) return List<Uint8List?>.filled(boxes.length, null);
  final oriented = img.bakeOrientation(photo);
  final w = oriented.width;
  final h = oriented.height;
  return [
    for (final b in boxes)
      () {
        final box = _box(b);
        if (box == null) return null;
        final (y0, x0, y1, x1) = box;
        // A little room around the packet, and no more: the rest of the fridge
        // is not the food's picture.
        final padX = (x1 - x0) * 0.06;
        final padY = (y1 - y0) * 0.06;
        final left = ((x0 - padX) / 1000 * w).clamp(0, w - 1).round();
        final top = ((y0 - padY) / 1000 * h).clamp(0, h - 1).round();
        final right = ((x1 + padX) / 1000 * w).clamp(1, w).round();
        final bottom = ((y1 + padY) / 1000 * h).clamp(1, h).round();
        final cw = right - left;
        final ch = bottom - top;
        // Too small to be a useful picture.
        if (cw < 80 || ch < 80) return null;
        var crop =
            img.copyCrop(oriented, x: left, y: top, width: cw, height: ch);
        if (crop.width > 640 || crop.height > 640) {
          crop = crop.width >= crop.height
              ? img.copyResize(crop, width: 640)
              : img.copyResize(crop, height: 640);
        }
        return Uint8List.fromList(img.encodeJpg(crop, quality: 82));
      }(),
  ];
}

/// "ymin,xmin,ymax,xmax" on 0-1000, as the photo function sends it.
(double, double, double, double)? _box(String s) {
  final parts = s.split(',').map((p) => double.tryParse(p.trim())).toList();
  if (parts.length != 4 || parts.any((p) => p == null)) return null;
  final (y0, x0, y1, x1) = (parts[0]!, parts[1]!, parts[2]!, parts[3]!);
  if (y1 <= y0 || x1 <= x0) return null;
  return (y0, x0, y1, x1);
}

Future<void> _removeQuietly(StorageFileApi storage, List<String> urls) async {
  final paths =
      [for (final u in urls) _storagePath(u)].whereType<String>().toList();
  if (paths.isEmpty) return;
  try {
    await storage.remove(paths);
  } catch (_) {}
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
''';
