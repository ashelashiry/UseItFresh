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

/// Big thing 1: a camera in the app, with the modes on it.
///
/// Owner, 14 Sep: "can we not show those as buttons on the camera?" The phone's
/// own camera (image_picker) cannot carry buttons, so the app gets its own:
/// CameraPage with SmartCamera — a live preview, Shelf / Receipt / Barcode /
/// Type it, a shutter, a gallery button for a photo already taken, flash, and
/// a close button. Reading happens on the camera; it then opens the photo map
/// or the receipt review, or says why nothing was added and stays.
///
/// So that the camera and the old picker buttons read photos the same way,
/// the reading moves into two actions that take the photo as a file:
/// ReadShelfShot and ReadReceiptShot. ReadShelfPhoto and ReadPhotoFoods keep
/// their names and behaviour and now pick a photo, then call them.
void buildStarterEditFlow(App app) {
  app.pubDependency('camera', '^0.11.2');

  app.customAction(
    'ReadShelfShot',
    args: {'shot': uploadedFile},
    returns: string,
    description:
        'Reads the foods on one shelf photo into the photo map, or — for the '
        'first photo — a receipt into the receipt review. ok, or why not.',
    code: _readShelfShot,
  );
  app.customAction(
    'ReadReceiptShot',
    args: {'shot': uploadedFile},
    returns: string,
    description:
        'Reads the foods on a receipt photo into the receipt review. ok, or '
        'why not.',
    code: _readReceiptShot,
  );
  app.raw((project) {
    updateCustomAction(project, name: 'ReadShelfPhoto', code: _readShelfPhoto);
    updateCustomAction(project, name: 'ReadPhotoFoods', code: _readPhotoFoods);
  });

  app.customWidget(
    'SmartCamera',
    parameters: {'mode': string},
    description:
        'Full-screen camera with Shelf, Receipt, Barcode and Type it; reads '
        'the photo and opens the photo map or the receipt review.',
    code: _smartCamera,
  );

  app.ensurePage(
    'CameraPage',
    route: '/camera',
    description: 'The in-app camera: take a shelf or receipt photo, or switch to '
        'barcode or typing.',
    params: {'mode': string.withDefault('shelf')},
    body: Scaffold(
      body: CustomWidget(
        widgetName: 'SmartCamera',
        name: 'CameraView',
        arguments: {'mode': PageParam('mode')},
      ),
    ),
  );
}

const _readShelfPhoto = r'''
import 'package:image_picker/image_picker.dart';

/// Photographs one shelf with the phone's camera and reads it (ReadShelfShot).
///
/// Returns 'ok' when there is something to review, '' when the person backed
/// out of the camera (not an error, so nothing is said), and otherwise a
/// sentence saying why not.
Future<String> readShelfPhoto() async {
  if (FFAppState().currentHouseholdId.isEmpty) {
    return 'No household yet. Create or join one before adding food.';
  }
  // Only the first photo of a map can turn out to be a receipt, which is long
  // and printed small, so it gets more pixels.
  final first = FFAppState().mapFoods.isEmpty;
  final shot = await ImagePicker().pickImage(
    source: ImageSource.camera,
    maxWidth: first ? 2000 : 1600,
    maxHeight: first ? 3200 : 1600,
    imageQuality: 85,
  );
  if (shot == null) return '';
  final bytes = await shot.readAsBytes();
  return readShelfShot(FFUploadedFile(name: 'shelf.jpg', bytes: bytes));
}
''';

const _readPhotoFoods = r'''
import 'package:image_picker/image_picker.dart';

/// Photographs a receipt (or, with 'shelf', a shelf) with the phone's camera
/// and reads it (ReadReceiptShot / ReadShelfShot).
///
/// Returns 'ok' when there is something to review, '' when the person backed
/// out of the camera (not an error, so nothing is said), and otherwise a
/// sentence saying why not.
Future<String> readPhotoFoods(String? mode) async {
  if (FFAppState().currentHouseholdId.isEmpty) {
    return 'No household yet. Create or join one before adding food.';
  }
  final shelf = mode == 'shelf';
  final shot = await ImagePicker().pickImage(
    source: ImageSource.camera,
    // Receipts are long and the print is small, so they get more pixels.
    maxWidth: shelf ? 1600 : 2000,
    maxHeight: shelf ? 1600 : 3200,
    imageQuality: 85,
  );
  if (shot == null) return '';
  final file = FFUploadedFile(name: 'photo.jpg', bytes: await shot.readAsBytes());
  return shelf ? readShelfShot(file) : readReceiptShot(file);
}
''';

const _readShelfShot = r'''
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

/// Reads one shelf photo: the foods on it, outlined, added to the photo map.
///
/// On the first photo of a map the function is also asked whether the photo
/// is a receipt; when it is, its lines go into the receipt review instead and
/// `receiptFromCamera` is set, so whatever took the photo opens that review.
///
/// Returns 'ok' when there is something to review, '' when there was no photo,
/// and otherwise a sentence saying why not. The photo is kept while the map is
/// open, because the map is drawn on it; a photo that gave nothing, or was a
/// receipt (shop, time, part of a card number), is deleted straight away.
Future<String> readShelfShot(FFUploadedFile? shot) async {
  const sorry = 'Could not read that photo. Try again closer up.';
  final household = FFAppState().currentHouseholdId;
  if (household.isEmpty) {
    return 'No household yet. Create or join one before adding food.';
  }
  final bytes = shot?.bytes;
  if (bytes == null || bytes.isEmpty) return '';
  final first = FFAppState().mapFoods.isEmpty;

  FFAppState().update(() => FFAppState().mapReading = true);
  final storage = SupaFlow.client.storage.from('food-images');
  final path = '$household/shelf-${const Uuid().v4()}.jpg';
  var uploaded = false;
  var keep = false;
  try {
    await storage.uploadBinary(
      path,
      bytes,
      fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: false),
    );
    uploaded = true;
    // An hour: long enough to go through the map. It is deleted on save.
    final url = await storage.createSignedUrl(path, 3600);

    final res = await SupaFlow.client.functions.invoke('recognise-food',
        body: {'imageUrl': url, 'mode': 'shelf', 'detectReceipt': first});
    final data = res.data;
    if (data is! Map) return sorry;
    if (data['error'] != null) return data['error'].toString();
    final raw = data['items'] is List ? data['items'] as List : const [];

    if (data['receipt'] == true) {
      final lines = await _receiptLines(raw, household);
      if (lines.isEmpty) {
        final note = (data['note'] ?? '').toString();
        return note.isNotEmpty
            ? note
            : 'Could not read that receipt. Try a flatter, brighter photo.';
      }
      FFAppState().update(() {
        FFAppState().scannedFoods = lines;
        FFAppState().scannedFrom = 'receipt';
        FFAppState().receiptFromCamera = true;
      });
      return 'ok';
    }

    final foods = <MapFoodStruct>[];
    for (final r in raw) {
      if (r is! Map) continue;
      final said = (r['name'] ?? '').toString().trim();
      if (said.isEmpty) continue;
      final counted = r['quantity'] is num ? (r['quantity'] as num).round() : 1;
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

// A private copy: the actions index exports only each action's own name.
/// Receipt lines as the receipt review shows them: a plain name, the place
/// each kind of food usually lives in this household, and the detail line.
Future<List<ScannedFoodStruct>> _receiptLines(
    List raw, String household) async {
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

  final rows = await SupaFlow.client
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

  final lines = <ScannedFoodStruct>[];
  for (final r in raw) {
    if (r is! Map) continue;
    final said = (r['name'] ?? '').toString().trim();
    if (said.isEmpty) continue;
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
    lines.add(ScannedFoodStruct(
      name: name,
      category: labels.containsKey(category) ? category : '',
      quantity: quantity,
      place: place == null ? '' : place['id'].toString(),
      detail: detail,
    ));
  }
  return lines;
}
''';

const _readReceiptShot = r'''
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

/// Reads a receipt photo into the receipt review (`scannedFoods`).
///
/// Returns 'ok' when there is something to review, '' when there was no photo,
/// and otherwise a sentence saying why not. The photo is deleted as soon as it
/// has been read: a receipt carries the shop, the time and part of a card
/// number, and none of it is needed.
Future<String> readReceiptShot(FFUploadedFile? shot) async {
  const sorry = 'Could not read that receipt. Try a flatter, brighter photo.';
  final household = FFAppState().currentHouseholdId;
  if (household.isEmpty) {
    return 'No household yet. Create or join one before adding food.';
  }
  final bytes = shot?.bytes;
  if (bytes == null || bytes.isEmpty) return '';

  FFAppState().update(() => FFAppState().scanReading = true);
  final storage = SupaFlow.client.storage.from('food-images');
  final path = '$household/scan-${const Uuid().v4()}.jpg';
  var uploaded = false;
  try {
    await storage.uploadBinary(
      path,
      bytes,
      fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: false),
    );
    uploaded = true;
    // Ten minutes: it is read once, straight away, and then deleted.
    final url = await storage.createSignedUrl(path, 600);

    final res = await SupaFlow.client.functions
        .invoke('recognise-food', body: {'imageUrl': url, 'mode': 'receipt'});
    final data = res.data;
    if (data is! Map) return sorry;
    if (data['error'] != null) return data['error'].toString();
    final raw = data['items'] is List ? data['items'] as List : const [];
    if (raw.isEmpty) {
      final note = (data['note'] ?? '').toString();
      return note.isNotEmpty ? note : sorry;
    }
    final lines = await _receiptLines(raw, household);
    if (lines.isEmpty) return sorry;
    FFAppState().update(() {
      FFAppState().scannedFoods = lines;
      FFAppState().scannedFrom = 'receipt';
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

/// Receipt lines as the receipt review shows them: a plain name, the place
/// each kind of food usually lives in this household, and the detail line.
Future<List<ScannedFoodStruct>> _receiptLines(
    List raw, String household) async {
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

  final rows = await SupaFlow.client
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

  final lines = <ScannedFoodStruct>[];
  for (final r in raw) {
    if (r is! Map) continue;
    final said = (r['name'] ?? '').toString().trim();
    if (said.isEmpty) continue;
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
    lines.add(ScannedFoodStruct(
      name: name,
      category: labels.containsKey(category) ? category : '',
      quantity: quantity,
      place: place == null ? '' : place['id'].toString(),
      detail: detail,
    ));
  }
  return lines;
}
''';

const _smartCamera = r'''
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

/// The app's own camera, with what to photograph chosen on it.
///
/// Shelf: one shelf, read into the photo map (a receipt is recognised and goes
/// to the receipt review instead). Receipt: read into the receipt review.
/// Barcode and Type it hand over to their screens. A photo already on the
/// phone can be chosen instead. If the camera cannot start — no camera, or
/// access turned off — it says so and offers the gallery or typing.
class SmartCamera extends StatefulWidget {
  const SmartCamera({super.key, this.width, this.height, this.mode});

  final double? width;
  final double? height;
  final String? mode;

  @override
  State<SmartCamera> createState() => _SmartCameraState();
}

class _SmartCameraState extends State<SmartCamera> with WidgetsBindingObserver {
  static const _forest = Color(0xFF07533A);
  static const _leaf = Color(0xFF83BD43);

  static const _modes = <(String, String, IconData)>[
    ('shelf', 'Shelf', Icons.kitchen_outlined),
    ('receipt', 'Receipt', Icons.receipt_long_outlined),
    ('barcode', 'Barcode', Icons.qr_code_scanner),
    ('type', 'Type it', Icons.edit_outlined),
  ];

  CameraController? _controller;
  bool _starting = true;
  String _problem = '';
  bool _reading = false;
  bool _flash = false;
  bool _pressed = false;
  late String _mode;

  @override
  void initState() {
    super.initState();
    _mode = widget.mode == 'receipt' ? 'receipt' : 'shelf';
    WidgetsBinding.instance.addObserver(this);
    _start();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final c = _controller;
    if (state == AppLifecycleState.inactive) {
      if (c != null && c.value.isInitialized) {
        _controller = null;
        c.dispose();
        if (mounted) setState(() {});
      }
    } else if (state == AppLifecycleState.resumed && _controller == null) {
      _start();
    }
  }

  Future<void> _start() async {
    if (mounted) setState(() => _starting = true);
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        _problem = 'There is no camera on this device.';
        return;
      }
      final back = cameras.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.back,
          orElse: () => cameras.first);
      final c = CameraController(back, ResolutionPreset.veryHigh,
          enableAudio: false, imageFormatGroup: ImageFormatGroup.jpeg);
      await c.initialize();
      try {
        await c.setFlashMode(FlashMode.off);
      } catch (_) {}
      if (!mounted) {
        await c.dispose();
        return;
      }
      _controller = c;
      _problem = '';
    } on CameraException catch (e) {
      _problem = e.code.contains('Denied') || e.code.contains('denied')
          ? 'Camera access is turned off for Use It Fresh. Turn it on in Settings, or choose a photo instead.'
          : 'The camera could not start. Choose a photo instead, or try again.';
    } catch (_) {
      _problem = 'The camera could not start. Choose a photo instead, or try again.';
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  // ---- actions ---------------------------------------------------------------

  void _close() {
    final router = GoRouter.of(context);
    if (router.canPop()) {
      router.pop();
    } else {
      router.goNamed('HomePage');
    }
  }

  void _choose(String mode) {
    if (_reading) return;
    final router = GoRouter.of(context);
    if (mode == 'barcode') {
      router.pushReplacementNamed('BarcodeScanPage');
    } else if (mode == 'type') {
      router.pushReplacementNamed('AddFoodItemPage');
    } else {
      setState(() => _mode = mode);
    }
  }

  Future<void> _toggleFlash() async {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    final next = !_flash;
    try {
      await c.setFlashMode(next ? FlashMode.always : FlashMode.off);
      setState(() => _flash = next);
    } catch (_) {}
  }

  Future<void> _shoot() async {
    final c = _controller;
    if (_reading || c == null || !c.value.isInitialized || c.value.isTakingPicture) {
      return;
    }
    try {
      final picture = await c.takePicture();
      await _read(await picture.readAsBytes());
    } catch (_) {
      if (mounted) _say('The photo was not taken. Try again.');
    }
  }

  Future<void> _gallery() async {
    if (_reading) return;
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 2000,
      maxHeight: 3200,
      imageQuality: 85,
    );
    if (picked == null) return;
    await _read(await picked.readAsBytes());
  }

  Future<void> _read(Uint8List bytes) async {
    if (_reading) return;
    setState(() => _reading = true);
    // Taken now: after the read this widget may be gone.
    final router = GoRouter.of(context);
    final root = Navigator.of(context, rootNavigator: true);
    final file = FFUploadedFile(name: 'camera.jpg', bytes: bytes);
    var left = false;
    try {
      if (_mode == 'receipt') {
        final said = await readReceiptShot(file);
        if (said == 'ok') {
          left = true;
          router.pushReplacementNamed('ScanReviewPage');
        } else if (said.isNotEmpty && root.mounted) {
          await _explain(root.context, 'Receipt not added', said);
        }
      } else {
        await clearShelfScan();
        final said = await readShelfShot(file);
        if (said == 'ok') {
          left = true;
          if (FFAppState().receiptFromCamera) {
            FFAppState().receiptFromCamera = false;
            router.pushReplacementNamed('ScanReviewPage');
          } else {
            router.pushReplacementNamed('MapReviewPage');
          }
        } else if (said.isNotEmpty && root.mounted) {
          await _explain(root.context, 'Nothing added', said);
        }
      }
    } finally {
      if (!left && mounted) setState(() => _reading = false);
    }
  }

  void _say(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  static Future<void> _explain(BuildContext host, String title, String said) {
    return showDialog<void>(
      context: host,
      builder: (dialog) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title),
        content: Text(said),
        actions: [
          TextButton(
            style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
            onPressed: () => Navigator.of(dialog).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // ---- screen ----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);
    final c = _controller;
    final ready = c != null && c.value.isInitialized;
    final receipt = _mode == 'receipt';
    return ColoredBox(
      color: Colors.black,
      child: SizedBox.expand(
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (ready)
              ClipRect(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: c.value.previewSize?.height ?? 1080,
                    height: c.value.previewSize?.width ?? 1920,
                    child: CameraPreview(c),
                  ),
                ),
              ),
            if (ready && !_reading) _frame(t, receipt),
            if (!ready && !_starting) _unavailable(t),
            if (_starting)
              const Center(
                  child: CircularProgressIndicator(color: Colors.white)),
            // Top: close and flash.
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(
                    children: [
                      _roundButton(Icons.close, 'Close', _close, filled: true),
                      const Spacer(),
                      if (ready)
                        _roundButton(_flash ? Icons.flash_on : Icons.flash_off,
                            _flash ? 'Flash on' : 'Flash off', _toggleFlash),
                    ],
                  ),
                ),
              ),
            ),
            // Bottom: modes, then gallery and shutter.
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x00000000), Color(0xCC000000)],
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              for (final m in _modes) ...[
                                _modeChip(t, m),
                                const SizedBox(width: 8),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _roundButton(Icons.photo_library_outlined,
                                'Choose a photo', _gallery),
                            _shutter(ready),
                            const SizedBox(width: 48, height: 48),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (_reading) _readingOverlay(t),
          ],
        ),
      ),
    );
  }

  Widget _frame(FlutterFlowTheme t, bool receipt) {
    return LayoutBuilder(builder: (context, box) {
      final w = box.maxWidth * (receipt ? 0.62 : 0.86);
      final h = receipt ? box.maxHeight * 0.52 : box.maxHeight * 0.32;
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(receipt ? 'Lay the receipt flat, all of it in the frame' : 'Fit one shelf in the frame',
                textAlign: TextAlign.center,
                style: t.bodyLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    shadows: const [Shadow(color: Colors.black54, blurRadius: 6)])),
            const SizedBox(height: 12),
            AnimatedContainer(
              duration: MediaQuery.of(context).disableAnimations
                  ? Duration.zero
                  : const Duration(milliseconds: 220),
              width: w,
              height: h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _modeChip(FlutterFlowTheme t, (String, String, IconData) m) {
    final on = _mode == m.$1;
    return Semantics(
      button: true,
      selected: on,
      label: m.$2,
      child: GestureDetector(
        onTap: () => _choose(m.$1),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: on ? Colors.white : const Color(0x33FFFFFF),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(m.$3, size: 18, color: on ? _forest : Colors.white),
              const SizedBox(width: 6),
              Text(m.$2,
                  style: t.bodyMedium.copyWith(
                      fontWeight: FontWeight.w800,
                      color: on ? _forest : Colors.white)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _roundButton(IconData icon, String label, VoidCallback onTap,
          {bool filled = false}) =>
      Semantics(
        button: true,
        label: label,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: filled ? _forest : const Color(0x4D000000),
              border: filled ? null : Border.all(color: const Color(0x80FFFFFF)),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
        ),
      );

  Widget _shutter(bool ready) {
    final still = MediaQuery.of(context).disableAnimations;
    return Semantics(
      button: true,
      enabled: ready && !_reading,
      label: _mode == 'receipt' ? 'Take the receipt photo' : 'Take the shelf photo',
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        onTap: ready ? _shoot : null,
        child: AnimatedScale(
          scale: (_pressed && !still) ? 0.92 : 1,
          duration: const Duration(milliseconds: 120),
          child: Opacity(
            opacity: ready ? 1 : 0.4,
            child: Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
              ),
              padding: const EdgeInsets.all(5),
              child: const DecoratedBox(
                decoration:
                    BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _readingOverlay(FlutterFlowTheme t) => Positioned.fill(
        child: ColoredBox(
          color: const Color(0xB3000000),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 44,
                  height: 44,
                  child: CircularProgressIndicator(color: _leaf, strokeWidth: 4),
                ),
                const SizedBox(height: 16),
                Text(
                    _mode == 'receipt'
                        ? 'Reading your receipt…'
                        : 'Reading your photo…',
                    style: t.titleMedium.copyWith(
                        color: Colors.white, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text('This takes a few seconds.',
                    style: t.bodyMedium.copyWith(color: Colors.white70)),
              ],
            ),
          ),
        ),
      );

  Widget _unavailable(FlutterFlowTheme t) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.no_photography_outlined,
                  color: Colors.white, size: 48),
              const SizedBox(height: 16),
              Text(_problem,
                  textAlign: TextAlign.center,
                  style: t.bodyLarge.copyWith(color: Colors.white, height: 1.4)),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: _forest,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _gallery,
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Choose a photo'),
                ),
              ),
              TextButton(
                style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    minimumSize: const Size(48, 48)),
                onPressed: _start,
                child: const Text('Try the camera again'),
              ),
            ],
          ),
        ),
      );
}
''';
