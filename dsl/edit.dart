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

/// Product pictures, source 3: receipt foods matched to product photos, by
/// name and country, confirmed by the person (owner, 14 Sep).
///
/// ProductPhotoPicker searches Open Food Facts among products sold in the
/// person's country (profiles.country_code; choosable, default Australia),
/// shows the packs, and uses only the one tapped: copied into the household's
/// storage, credited, and recorded in product_images with the country and the
/// person's share consent. A food's photo sheet gets "Find the product photo";
/// a receipt in Receipts gets "Find product photos for N foods", one at a time.
void buildStarterEditFlow(App app) {
  app.customWidget(
    'ProductPhotoPicker',
    parameters: {'itemId': string, 'foodName': string},
    description:
        'Find a product photo for one food on Open Food Facts, by name and '
        'country; the person picks the pack.',
    code: _productPhotoPicker,
  );
  app.raw((project) {
    updateCustomWidget(project, name: 'FoodDetail', code: _foodDetail);
    updateCustomWidget(project, name: 'ReceiptHistory', code: _receiptHistory);
  });
}

const _productPhotoPicker = r'''
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

/// Find the product photo for one food (owner, 14 Sep: product pictures by
/// country, "packaged differently in different countries").
///
/// Searches Open Food Facts for the food's name among products sold in the
/// person's country, shows the packs it finds, and uses the one the person
/// taps — nothing is picked for them. The chosen photo is copied into the
/// household's own storage (so the food's screen credits Open Food Facts),
/// and recorded in product_images with the country and the person's sharing
/// choice. Shown inside a bottom sheet; closes with true when a photo is used.
class ProductPhotoPicker extends StatefulWidget {
  const ProductPhotoPicker({
    super.key,
    this.width,
    this.height,
    this.itemId,
    this.foodName,
  });

  final double? width;
  final double? height;
  final String? itemId;
  final String? foodName;

  @override
  State<ProductPhotoPicker> createState() => _ProductPhotoPickerState();
}

class _ProductPhotoPickerState extends State<ProductPhotoPicker> {
  static const _forest = Color(0xFF07533A);
  static const _ink = Color(0xFF202C24);
  static const _muted = Color(0xFF59665D);
  static const _sage = Color(0xFFEDF2E8);
  static const _border = Color(0xFFDCE3D7);

  static const _countries = <String, String>{
    'AU': 'Australia',
    'NZ': 'New Zealand',
    'GB': 'the UK',
    'IE': 'Ireland',
    'US': 'the US',
    'CA': 'Canada',
    'FR': 'France',
    'DE': 'Germany',
  };

  final _query = TextEditingController();
  String _country = 'AU';
  bool _searching = false;
  bool _using = false;
  String _note = '';
  List<Map<String, String>> _found = const [];

  @override
  void initState() {
    super.initState();
    _query.text = (widget.foodName ?? '').trim();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    final uid = SupaFlow.client.auth.currentUser?.id;
    if (uid != null) {
      try {
        final p = await SupaFlow.client
            .from('profiles')
            .select('country_code')
            .eq('id', uid)
            .maybeSingle();
        final cc = '${p?['country_code'] ?? ''}'.toUpperCase();
        if (_countries.containsKey(cc)) _country = cc;
      } catch (_) {}
    }
    if (mounted) _search();
  }

  Future<void> _setCountry(String cc) async {
    setState(() => _country = cc);
    final uid = SupaFlow.client.auth.currentUser?.id;
    if (uid != null) {
      try {
        await SupaFlow.client
            .from('profiles')
            .update({'country_code': cc}).eq('id', uid);
      } catch (_) {}
    }
    _search();
  }

  Future<void> _search() async {
    final q = _query.text.trim();
    if (q.isEmpty) return;
    setState(() {
      _searching = true;
      _note = '';
    });
    final url = Uri.parse(
        'https://${_country.toLowerCase()}.openfoodfacts.org/cgi/search.pl'
        '?search_terms=${Uri.encodeQueryComponent(q)}&search_simple=1'
        '&action=process&json=1&page_size=12'
        '&fields=code,product_name,brands,image_front_small_url');
    try {
      final res = await http.get(url, headers: {
        'User-Agent': 'UseItFresh/1.0 (https://useitfresh.app)',
      }).timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) throw 'status ${res.statusCode}';
      final body = json.decode(res.body);
      final products = body is Map && body['products'] is List
          ? body['products'] as List
          : const [];
      final found = <Map<String, String>>[
        for (final p in products)
          if (p is Map && '${p['image_front_small_url'] ?? ''}'.startsWith('https://'))
            {
              'code': '${p['code'] ?? ''}',
              'name': '${p['product_name'] ?? ''}'.trim(),
              'brand': '${p['brands'] ?? ''}'.split(',').first.trim(),
              'image': '${p['image_front_small_url']}',
            }
      ];
      if (!mounted) return;
      setState(() {
        _found = found;
        _searching = false;
        _note = found.isEmpty
            ? 'No photos found for “$q” in ${_countries[_country]}. Try a shorter name or a brand.'
            : '';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _searching = false;
        _note = 'Could not reach the product database. Check your signal.';
      });
    }
  }

  Future<void> _use(Map<String, String> p) async {
    final id = (widget.itemId ?? '').trim();
    if (id.isEmpty || _using) return;
    setState(() => _using = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final client = SupaFlow.client;
    final storage = client.storage.from('food-images');
    String? path;
    try {
      final food = await client
          .from('food_items')
          .select('household_id, name, image_url')
          .eq('id', id)
          .single();
      final household = '${food['household_id']}';
      final small = p['image']!;
      final larger = small.replaceFirst(RegExp(r'\.200\.jpg$'), '.400.jpg');
      var res =
          await http.get(Uri.parse(larger)).timeout(const Duration(seconds: 12));
      if (res.statusCode != 200 && larger != small) {
        res = await http.get(Uri.parse(small)).timeout(const Duration(seconds: 12));
      }
      if (res.statusCode != 200 || res.bodyBytes.isEmpty) throw 'no image';
      path = '$household/product-${const Uuid().v4()}.jpg';
      await storage.uploadBinary(path, res.bodyBytes,
          fileOptions:
              const FileOptions(contentType: 'image/jpeg', upsert: false));
      final signed = await storage.createSignedUrl(path, 60 * 60 * 24 * 365);
      await client.from('food_items').update({'image_url': signed}).eq('id', id);

      // The picture it replaced, if the app stored it.
      final old = _storagePath('${food['image_url'] ?? ''}');
      if (old != null) {
        try {
          await storage.remove([old]);
        } catch (_) {}
      }
      // What the app knows about this product's picture, and whether this
      // person agreed to share product photos beyond the household.
      try {
        var consent = false;
        final uid = client.auth.currentUser?.id;
        if (uid != null) {
          final s = await client
              .from('user_settings')
              .select('share_product_photos')
              .eq('profile_id', uid)
              .maybeSingle();
          consent = s?['share_product_photos'] == true;
        }
        final code = p['code'] ?? '';
        await client.from('product_images').insert({
          'household_id': household,
          if (RegExp(r'^[0-9]{6,14}$').hasMatch(code)) 'barcode': code,
          'name_key': '${food['name'] ?? p['name']}'.trim().toLowerCase(),
          'country_code': _country,
          'storage_path': path,
          'source': 'open_food_facts',
          'licence': 'Open Food Facts contributors, CC BY-SA',
          'share_consent': consent,
          'created_by': uid,
        });
      } catch (_) {}
      messenger.showSnackBar(const SnackBar(
          content: Text('Photo added. Credit: Open Food Facts.')));
      navigator.pop(true);
    } catch (_) {
      if (path != null) {
        try {
          await storage.remove([path]);
        } catch (_) {}
      }
      if (mounted) {
        setState(() => _using = false);
        messenger.showSnackBar(const SnackBar(
            content: Text('Could not use that photo. Check your signal.')));
      }
    }
  }

  static String? _storagePath(String signedUrl) {
    const marker = '/object/sign/food-images/';
    final at = signedUrl.indexOf(marker);
    if (at < 0) return null;
    final rest = signedUrl.substring(at + marker.length);
    final q = rest.indexOf('?');
    return Uri.decodeComponent(q < 0 ? rest : rest.substring(0, q));
  }

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);
    return SizedBox(
      width: widget.width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Find the product photo',
              style: t.headlineSmall.copyWith(
                  fontSize: 24, fontWeight: FontWeight.w800, color: _ink)),
          const SizedBox(height: 4),
          Text('Pick the pack that matches yours. Packs differ from country to country.',
              style: t.bodyMedium.copyWith(color: _muted, fontSize: 14)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _query,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _search(),
                  decoration: InputDecoration(
                    hintText: 'Name or brand',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: _border),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                style: IconButton.styleFrom(
                    backgroundColor: _forest,
                    minimumSize: const Size(52, 52)),
                tooltip: 'Search',
                onPressed: _searching ? null : _search,
                icon: const Icon(Icons.search, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final e in _countries.entries) ...[
                  ChoiceChip(
                    label: Text(e.value),
                    selected: _country == e.key,
                    selectedColor: _sage,
                    onSelected: (_) => _setCountry(e.key),
                  ),
                  const SizedBox(width: 6),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (_searching || _using)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(color: _forest)),
              ),
            )
          else if (_note.isNotEmpty)
            Text(_note, style: t.bodyLarge.copyWith(color: _muted, fontSize: 16))
          else
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.72,
              children: [
                for (final p in _found)
                  Semantics(
                    button: true,
                    label: 'Use ${p['name']}',
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => _use(p),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: _border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: Image.network(p['image']!,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) =>
                                      Container(color: _sage)),
                            ),
                            const SizedBox(height: 4),
                            Text(
                                [p['brand'], p['name']]
                                    .where((s) => (s ?? '').isNotEmpty)
                                    .join(' · '),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: t.bodySmall
                                    .copyWith(color: _ink, fontSize: 11)),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          const SizedBox(height: 8),
          Text('Photos from Open Food Facts, used with credit.',
              style: t.bodySmall.copyWith(color: _muted, fontSize: 12)),
        ],
      ),
    );
  }
}
''';

const _foodDetail = r'''
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Everything about one food, photo first.
class FoodDetail extends StatefulWidget {
  const FoodDetail({super.key, this.width, this.height, this.itemId});

  final double? width;
  final double? height;
  final String? itemId;

  @override
  State<FoodDetail> createState() => _FoodDetailState();
}

class _FoodDetailState extends State<FoodDetail> {
  static const _forest = Color(0xFF07533A);
  static const _ink = Color(0xFF202C24);
  static const _muted = Color(0xFF59665D);
  static const _sage = Color(0xFFEDF2E8);
  static const _border = Color(0xFFDCE3D7);

  static const _food =
      'https://cdn.jsdelivr.net/gh/ashelashiry/UseItFresh@b50424f12bd372d81c9cd44d895b62c25d1329e7/design/v3/food';

  List<FoodItemsStatusRow> _rows = const [];
  bool _loading = true;
  bool _offline = false;
  bool _replace = false;
  bool _busy = false;
  bool _photoBusy = false;

  String get _id => (widget.itemId ?? '').trim();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load({bool quiet = false}) async {
    if (!quiet && mounted) {
      setState(() {
        _loading = true;
        _offline = false;
      });
    }
    try {
      final rows = await FoodItemsStatusTable()
          .queryRows(queryFn: (q) => q.eqOrNull('id', _id));
      if (!mounted) return;
      setState(() {
        _rows = rows;
        _loading = false;
        _offline = false;
      });
    } catch (_) {
      if (!mounted) return;
      if (quiet && _rows.isNotEmpty) return;
      setState(() {
        _loading = false;
        _offline = true;
      });
    }
  }

  String _field(String name) => itemField(_rows, name) ?? '';

  String? get _photo {
    if (_rows.isEmpty) return null;
    final r = _rows.first;
    final own = (r.imageUrl ?? '').trim();
    if (own.isNotEmpty) return own;
    final n = (r.name ?? '').toLowerCase();
    const exact = {
      'spinach': 'spinach',
      'mushroom': 'mushrooms',
      'tomato': 'tomatoes',
      'egg': 'eggs',
      'yogurt': 'yogurt',
      'yoghurt': 'yogurt',
      'pasta': 'pasta',
    };
    for (final e in exact.entries) {
      if (n.contains(e.key)) return '$_food/${e.value}.webp';
    }
    return null;
  }

  /// How long a food has, in words, on a colour that says how soon (owner,
  /// 14 Sep: "bold, on a coloured pill"). Red: past its use-by, use today, or
  /// two days or less. Orange: three to seven days, or past best-before. Green:
  /// more than a week. Blue: frozen, with no countdown — the clock does not
  /// run in the freezer, so there is nothing to count.
  static (String, Color, Color)? _timePill(String status, Object? daysLeft) {
    const red = (Color(0xFFB42318), Color(0xFFFDE3E0));
    const orange = (Color(0xFFB54708), Color(0xFFFFE9D1));
    const green = (Color(0xFF1E6B3A), Color(0xFFDDF0E2));
    const blue = (Color(0xFF285E8E), Color(0xFFE1ECF7));
    const grey = (Color(0xFF59665D), Color(0xFFEDF2E8));
    switch (status) {
      case 'frozen':
        return ('Frozen', blue.$1, blue.$2);
      case 'past_use_by':
        return ('Past use-by', red.$1, red.$2);
      case 'past_best_before':
        return ('Past best before', orange.$1, orange.$2);
      case 'use_today':
        return ('Use today', red.$1, red.$2);
      case 'unknown':
        return ('No date', grey.$1, grey.$2);
      case 'consumed':
      case 'discarded':
        return null;
    }
    final days = daysLeft is num ? daysLeft.round() : null;
    if (days == null) return null;
    final label = days <= 0
        ? 'Use today'
        : (days == 1 ? '1 day left' : '$days days left');
    final c = days <= 2 ? red : (days <= 7 ? orange : green);
    return (label, c.$1, c.$2);
  }

  static Widget _pill(FlutterFlowTheme t, (String, Color, Color) p,
          {double size = 13}) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
            color: p.$3, borderRadius: BorderRadius.circular(999)),
        child: Text(p.$1,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: t.bodySmall.copyWith(
                color: p.$2, fontWeight: FontWeight.w800, fontSize: size)),
      );

  static (Color, Color) _statusColours(String status) {
    switch (status) {
      case 'fresh':
        return (const Color(0xFF285B34), const Color(0xFFEAF3E5));
      case 'use_soon':
        return (const Color(0xFF79500F), const Color(0xFFFFF1D4));
      case 'use_today':
        return (const Color(0xFF934017), const Color(0xFFFFEADD));
      case 'past_best_before':
        return (const Color(0xFF69516E), const Color(0xFFF1EAF4));
      case 'past_use_by':
        return (const Color(0xFFA02929), const Color(0xFFFCE8E6));
      case 'frozen':
        return (const Color(0xFF2F5F8A), const Color(0xFFE4EEF7));
      default:
        return (_muted, _sage);
    }
  }

  // ---- actions ---------------------------------------------------------------

  bool get _hasOwnPhoto =>
      _rows.isNotEmpty && (_rows.first.imageUrl ?? '').trim().isNotEmpty;

  /// Take a photo, choose one, or remove the one it has.
  Future<void> _changePhoto() async {
    if (_photoBusy || _busy) return;
    final t = FlutterFlowTheme.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final own = _hasOwnPhoto;
    Widget option(BuildContext c, IconData icon, String label, String value,
            {Color colour = _ink}) =>
        ListTile(
          minVerticalPadding: 14,
          leading: Icon(icon, color: colour == _ink ? _forest : colour),
          title: Text(label,
              style: t.bodyLarge.copyWith(
                  fontSize: 16, color: colour, fontWeight: FontWeight.w600)),
          onTap: () => Navigator.of(c).pop(value),
        );
    final source = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (c) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(own ? 'Change the photo' : 'Add a photo',
                    style: t.titleLarge.copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: _ink)),
              ),
              option(c, Icons.photo_camera_outlined, 'Take a photo', 'camera'),
              option(c, Icons.photo_library_outlined, 'Choose from your photos',
                  'gallery'),
              option(c, Icons.travel_explore, 'Find the product photo',
                  'product'),
              if (own)
                option(
                    c, Icons.hide_image_outlined, 'Remove the photo', 'remove',
                    colour: const Color(0xFFB42318)),
            ],
          ),
        ),
      ),
    );
    if (source == null || !mounted) return;
    if (source == 'product') {
      final used = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: const Color(0xFFF7F7F0),
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (sheet) => ConstrainedBox(
          constraints: BoxConstraints(
              maxHeight: MediaQuery.of(sheet).size.height * 0.9),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                  20, 20, 20, 20 + MediaQuery.of(sheet).viewInsets.bottom),
              child: ProductPhotoPicker(itemId: _id, foodName: _field('name')),
            ),
          ),
        ),
      );
      if (used == true && mounted) await _load(quiet: true);
      return;
    }
    setState(() => _photoBusy = true);
    try {
      final said = await changeFoodPhoto(_id, source);
      if (said == 'ok') {
        messenger.showSnackBar(SnackBar(
            content:
                Text(source == 'remove' ? 'Photo removed.' : 'Photo saved.')));
        await _load(quiet: true);
      } else if (said.isNotEmpty) {
        messenger.showSnackBar(SnackBar(content: Text(said)));
      }
    } finally {
      if (mounted) setState(() => _photoBusy = false);
    }
  }

  void _back() {
    final router = GoRouter.of(context);
    if (router.canPop()) {
      router.pop();
    } else {
      router.goNamed('InventoryPage');
    }
  }

  Future<void> _edit() async {
    await context.pushNamed('EditItemPage', queryParameters: {'itemId': _id});
    if (mounted) _load(quiet: true);
  }

  Future<void> _settle(String outcome) async {
    if (_busy) return;
    setState(() => _busy = true);
    final router = GoRouter.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final id = _id;
    final name = _field('name');
    try {
      if (_replace) {
        final listed = await addItemToShoppingList(id);
        if (listed.isNotEmpty) {
          messenger.showSnackBar(SnackBar(content: Text(listed)));
          return;
        }
      }
      final said = await settleFoodItem(id, outcome);
      if (said.isNotEmpty) {
        messenger.showSnackBar(SnackBar(content: Text(said)));
        return;
      }
      messenger.showSnackBar(SnackBar(
        duration: const Duration(seconds: 6),
        content: Text(outcome == 'consumed'
            ? 'Good. Nothing wasted.'
            : 'Thrown out and recorded.'),
        action: SnackBarAction(
          label: 'Undo',
          textColor: const Color(0xFFB9E08F),
          onPressed: () async {
            final back = await unsettleFoodItem(id);
            messenger.showSnackBar(SnackBar(
                content: Text(back.isEmpty
                    ? '${name.isEmpty ? 'It' : name} is back in your kitchen.'
                    : back)));
            if (back.isEmpty) {
              router.pushNamed('FoodItemPage', queryParameters: {'itemId': id});
            }
          },
        ),
      ));
      router.pushNamed('InventoryPage');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ---- page ----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);
    Widget body;
    if (_loading) {
      body = _skeleton();
    } else if (_offline) {
      body = _message(t,
          icon: Icons.cloud_off_outlined,
          title: 'Can’t reach your kitchen.',
          text:
              'No signal, or the connection dropped. This item will show again as soon as you are back online.',
          action: 'Try again',
          onAction: _load);
    } else if (_rows.isEmpty) {
      body = _message(t,
          icon: Icons.kitchen_outlined,
          title: 'Not in your kitchen.',
          text: 'This food has been used, thrown out or removed.',
          action: 'Back to your kitchen',
          onAction: () => context.goNamed('InventoryPage'));
    } else {
      body = _food_(t);
    }
    return SizedBox(
      width: widget.width,
      child: AnimatedSwitcher(
        duration: MediaQuery.of(context).disableAnimations
            ? Duration.zero
            : const Duration(milliseconds: 200),
        child: KeyedSubtree(
          key: ValueKey(
              _loading ? 'l' : (_offline ? 'o' : (_rows.isEmpty ? 'e' : 'f'))),
          child: body,
        ),
      ),
    );
  }

  // Forest with a white arrow on every screen (owner, 14 Sep: green back
  // buttons), so it stands out on a photo and on cream alike.
  Widget _backButton({bool onPhoto = true}) => Semantics(
        button: true,
        label: 'Back',
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: _back,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _forest,
              shape: BoxShape.circle,
              boxShadow: onPhoto
                  ? const [BoxShadow(color: Color(0x33000000), blurRadius: 8)]
                  : null,
            ),
            child: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
          ),
        ),
      );

  // Top right of the photo: a camera, with words while there is no picture so
  // the empty tile says what to do.
  Widget _photoButton(FlutterFlowTheme t) {
    final own = _hasOwnPhoto;
    return Semantics(
      button: true,
      label: own ? 'Change the photo' : 'Add a photo',
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: _photoBusy ? null : _changePhoto,
        child: Container(
          height: 44,
          padding: EdgeInsets.symmetric(horizontal: own ? 0 : 14),
          width: own ? 44 : null,
          decoration: BoxDecoration(
            color: _forest,
            borderRadius: BorderRadius.circular(999),
            boxShadow: const [
              BoxShadow(color: Color(0x33000000), blurRadius: 8)
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.photo_camera_outlined,
                  color: Colors.white, size: 21),
              if (!own) ...[
                const SizedBox(width: 6),
                Text('Add a photo',
                    style: t.bodyMedium.copyWith(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _food_(FlutterFlowTheme t) {
    final name = _field('name');
    final status = _field('status');
    final label = _field('statusLabel');
    final detail = _field('detail');
    final pill = _timePill(status, _rows.first.daysLeft);
    // The pill already says how long is left; the card adds only advice
    // ("Throw this out", "Check it before using"), and nothing for frozen.
    final advice =
        status == 'past_use_by' || status == 'past_best_before' ? detail : '';
    final photo = _photo;
    final category = _field('category');

    Widget tile() => Container(
          color: _sage,
          alignment: Alignment.center,
          child: const Icon(Icons.restaurant, color: _forest, size: 56),
        );

    final rows = <(IconData, String, String)>[
      (Icons.scale_outlined, 'How much', _field('quantity')),
      (Icons.kitchen_outlined, 'Kept in', _field('where')),
      (Icons.category_outlined, 'Category', category),
      (Icons.info_outline, 'How this was worked out', _field('basis')),
      (
        Icons.event_outlined,
        'Added',
        _field('added').replaceFirst('Added ', '')
      ),
    ].where((r) => r.$3.trim().isNotEmpty).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Photo, with the name and status over its lower edge.
        SizedBox(
          height: 300,
          child: Stack(
            fit: StackFit.expand,
            children: [
              photo == null
                  ? tile()
                  : Image.network(photo,
                      fit: BoxFit.cover, errorBuilder: (_, __, ___) => tile()),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x33000000),
                      Color(0x00000000),
                      Color(0xB3000000)
                    ],
                    stops: [0, 0.35, 1],
                  ),
                ),
              ),
              Positioned(left: 16, top: 16, child: _backButton()),
              Positioned(right: 16, top: 16, child: _photoButton(t)),
              if (_photoBusy)
                const ColoredBox(
                  color: Color(0x66000000),
                  child: Center(
                    child: SizedBox(
                      width: 36,
                      height: 36,
                      child: CircularProgressIndicator(
                          strokeWidth: 3, color: Colors.white),
                    ),
                  ),
                ),
              // Open Food Facts photos are free to use with credit. Our own
              // copies of them are stored as "product-…" in the household folder.
              if (photo != null && photo.contains('/product-'))
                Positioned(
                  right: 16,
                  top: 68,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0x99000000),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text('Photo: Open Food Facts',
                        style: t.bodySmall.copyWith(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              Positioned(
                left: 20,
                right: 20,
                bottom: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (pill != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _pill(t, pill, size: 14),
                      ),
                    Text(name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: t.headlineMedium.copyWith(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            height: 1.1)),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // The date that matters, and where it came from.
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _sage,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14)),
                      child: const Icon(Icons.calendar_today_outlined,
                          color: _forest, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_field('date'),
                              style: t.titleMedium.copyWith(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: _ink)),
                          const SizedBox(height: 2),
                          Text(_field('dateSource'),
                              style: t.bodyMedium
                                  .copyWith(fontSize: 14, color: _muted)),
                          if (advice.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(advice,
                                style: t.bodyMedium.copyWith(
                                    fontSize: 15,
                                    color: _ink,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // The other facts, as rows in one card.
              if (rows.isNotEmpty)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _border),
                  ),
                  child: Column(
                    children: [
                      for (var i = 0; i < rows.length; i++) ...[
                        if (i > 0)
                          const Divider(
                              height: 1,
                              thickness: 1,
                              indent: 52,
                              color: _border),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(rows[i].$1, color: _forest, size: 20),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(rows[i].$2,
                                        style: t.bodySmall.copyWith(
                                            fontSize: 13,
                                            color: _muted,
                                            fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 2),
                                    Text(rows[i].$3,
                                        style: t.bodyLarge.copyWith(
                                            fontSize: 16, color: _ink)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              const SizedBox(height: 24),
              // When it is gone, put it on the list.
              Semantics(
                toggled: _replace,
                label: 'Put it on the shopping list',
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => setState(() => _replace = !_replace),
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 52),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _replace ? _forest : _border),
                    ),
                    child: Row(
                      children: [
                        Icon(
                            _replace
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            color: _replace ? _forest : _muted,
                            size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text('Put it on the shopping list',
                              style: t.bodyLarge.copyWith(
                                  fontSize: 16,
                                  color: _ink,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: _forest,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: _forest.withOpacity(0.5),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: _busy ? null : () => _settle('consumed'),
                        icon: const Icon(Icons.check, size: 20),
                        label: Text('I used it',
                            style: t.bodyLarge.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _ink,
                          side: const BorderSide(color: _border),
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: _busy ? null : () => _settle('discarded'),
                        icon: const Icon(Icons.delete_outline, size: 20),
                        label: Text('Throw it out',
                            style: t.bodyLarge.copyWith(
                                color: _ink, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Center(
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                      minimumSize: const Size(48, 48),
                      foregroundColor: _forest),
                  onPressed: _busy ? null : _edit,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: Text('Edit details',
                      style: t.bodyLarge.copyWith(
                          color: _forest, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _skeleton() {
    Widget block(double h, {double r = 20}) => Container(
          height: h,
          decoration: BoxDecoration(
              color: _sage, borderRadius: BorderRadius.circular(r)),
        );
    return Semantics(
      label: 'Loading this food',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(children: [
            block(300, r: 0),
            Positioned(left: 16, top: 16, child: _backButton()),
          ]),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(children: [
              block(92),
              const SizedBox(height: 12),
              block(220),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _message(FlutterFlowTheme t,
      {required IconData icon,
      required String title,
      required String text,
      required String action,
      required VoidCallback onAction}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _backButton(onPhoto: false),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      color: _sage, borderRadius: BorderRadius.circular(16)),
                  child: Icon(icon, color: _forest, size: 28),
                ),
                const SizedBox(height: 16),
                Text(title,
                    style: t.titleLarge.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: _ink)),
                const SizedBox(height: 6),
                Text(text,
                    style: t.bodyLarge
                        .copyWith(fontSize: 16, color: _muted, height: 1.4)),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: _forest,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: onAction,
                    child: Text(action,
                        style: t.bodyLarge.copyWith(
                            color: Colors.white, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
''';

const _receiptHistory = r'''
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Receipts (owner, 14 Sep: "summary of how many items, scanned date, purchase
/// date/time and location of the receipt").
///
/// Every receipt the household has added, newest first: the shop, where it
/// is, when it was bought, how many items, the total, and when it was scanned.
/// A receipt opens to its lines with what was paid and what became of each
/// food. Deleting a receipt keeps the food; only the record goes. No photo of
/// a receipt is ever kept.
class ReceiptHistory extends StatefulWidget {
  const ReceiptHistory({super.key, this.width, this.height});

  final double? width;
  final double? height;

  @override
  State<ReceiptHistory> createState() => _ReceiptHistoryState();
}

class _ReceiptHistoryState extends State<ReceiptHistory> {
  static const _forest = Color(0xFF07533A);
  static const _ink = Color(0xFF202C24);
  static const _muted = Color(0xFF59665D);
  static const _sage = Color(0xFFEDF2E8);
  static const _border = Color(0xFFDCE3D7);
  static const _cream = Color(0xFFF7F7F0);
  static const _red = Color(0xFFB42318);

  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec'
  ];

  String _for = '';
  bool _loading = true;
  bool _offline = false;
  bool _notReady = false;
  List<Map> _receipts = const [];

  Future<void> _load(String household, {bool quiet = false}) async {
    if (!quiet && mounted) {
      setState(() {
        _loading = true;
        _offline = false;
      });
    }
    try {
      final rows = await SupaFlow.client
          .from('receipts')
          .select(
              'id, shop_name, shop_location, purchased_at, scanned_at, item_count, total_amount, currency')
          .eq('household_id', household)
          .order('scanned_at', ascending: false)
          .limit(100);
      if (!mounted || household != _for) return;
      setState(() {
        _receipts = [for (final r in rows as List) r as Map];
        _loading = false;
        _offline = false;
        _notReady = false;
      });
    } on PostgrestException catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _notReady = error.code == '42P01' || error.code == 'PGRST205';
        _offline = !_notReady;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _offline = true;
      });
    }
  }

  static String _when(Object? iso, {bool time = true}) {
    final d = DateTime.tryParse('${iso ?? ''}')?.toLocal();
    if (d == null) return '';
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final clock =
        '$h:${d.minute.toString().padLeft(2, '0')} ${d.hour < 12 ? 'am' : 'pm'}';
    final day = '${_days[d.weekday - 1]} ${d.day} ${_months[d.month - 1]}'
        '${d.year != DateTime.now().year ? ' ${d.year}' : ''}';
    return time ? '$day, $clock' : day;
  }

  static String _money(Object? amount, Object? currency) {
    if (amount is! num || amount <= 0) return '';
    const symbols = {
      'AUD': r'$',
      'NZD': r'$',
      'USD': r'$',
      'CAD': r'$',
      'GBP': '£',
      'EUR': '€'
    };
    final code = '${currency ?? ''}';
    final symbol = symbols[code] ?? (code.isEmpty ? r'$' : '$code ');
    return '$symbol${amount.toStringAsFixed(2)}';
  }

  void _say(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  void _back() {
    final router = GoRouter.of(context);
    if (router.canPop()) {
      router.pop();
    } else {
      router.goNamed('ProfilePage');
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();
    final t = FlutterFlowTheme.of(context);
    final household = FFAppState().currentHouseholdId;
    if (household.isNotEmpty && household != _for) {
      _for = household;
      WidgetsBinding.instance.addPostFrameCallback((_) => _load(household));
    }

    Widget content;
    if (household.isEmpty) {
      content = _message(t, Icons.group_outlined, 'No household yet.',
          'Create or join a household first.', null);
    } else if (_loading) {
      content = Column(children: [
        for (var i = 0; i < 3; i++) ...[
          Container(
            height: 92,
            decoration: BoxDecoration(
                color: _sage, borderRadius: BorderRadius.circular(20)),
          ),
          const SizedBox(height: 12),
        ],
      ]);
    } else if (_notReady) {
      content = _message(t, Icons.construction_outlined,
          'Receipts are almost ready.', 'Try again soon.', () => _load(_for));
    } else if (_offline) {
      content = _message(
          t,
          Icons.cloud_off_outlined,
          'Can’t reach your receipts.',
          'No signal, or the connection dropped. Try again when you are back online.',
          () => _load(_for));
    } else if (_receipts.isEmpty) {
      content = _message(
          t,
          Icons.receipt_long_outlined,
          'No receipts yet.',
          'Scan a receipt from the Scan tab. Once its food is added, it shows here with the shop, the date and what you paid.',
          null);
    } else {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final r in _receipts) ...[
            _row(t, r),
            const SizedBox(height: 12),
          ],
        ],
      );
    }

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Semantics(
                button: true,
                label: 'Back',
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: _back,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                        color: _forest, shape: BoxShape.circle),
                    child: const Icon(Icons.arrow_back,
                        color: Colors.white, size: 22),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Receipts.',
                style: t.headlineMedium.copyWith(
                    fontSize: 32, fontWeight: FontWeight.w800, color: _ink)),
            const SizedBox(height: 4),
            Text(
                _receipts.isEmpty
                    ? 'What your household bought, shop by shop.'
                    : (_receipts.length == 1
                        ? '1 receipt, shared with your household.'
                        : '${_receipts.length} receipts, shared with your household.'),
                style: t.bodyLarge.copyWith(color: _muted, fontSize: 16)),
            const SizedBox(height: 20),
            content,
          ],
        ),
      ),
    );
  }

  Widget _row(FlutterFlowTheme t, Map r) {
    final shop = '${r['shop_name'] ?? ''}'.trim();
    final place = '${r['shop_location'] ?? ''}'.trim();
    final bought = _when(r['purchased_at']);
    final count = r['item_count'] is num ? (r['item_count'] as num).round() : 0;
    final total = _money(r['total_amount'], r['currency']);
    return Semantics(
      button: true,
      label: shop.isEmpty ? 'Receipt' : shop,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _open(t, r),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    color: _sage, borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.receipt_long_outlined,
                    color: _forest, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(shop.isEmpty ? 'Shop not read' : shop,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: t.bodyLarge.copyWith(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: _ink)),
                    if (place.isNotEmpty)
                      Text(place,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: t.bodyMedium
                              .copyWith(color: _muted, fontSize: 14)),
                    Text(
                        bought.isEmpty
                            ? 'Purchase time not read'
                            : 'Bought $bought',
                        style:
                            t.bodyMedium.copyWith(color: _ink, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(
                        [
                          count == 1 ? '1 item' : '$count items',
                          if (total.isNotEmpty) total,
                          'scanned ${_when(r['scanned_at'], time: false)}',
                        ].join(' · '),
                        style:
                            t.bodySmall.copyWith(color: _muted, fontSize: 13)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: _muted),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _open(FlutterFlowTheme t, Map r) async {
    List<Map> lines = const [];
    final state = <String, String>{};
    final noPhoto = <(String, String)>[];
    try {
      final rows = await SupaFlow.client
          .from('receipt_items')
          .select('name, quantity, unit_price, line_total, food_item_id')
          .eq('receipt_id', r['id'].toString())
          .order('created_at');
      lines = [for (final x in rows as List) x as Map];
      final ids = [
        for (final l in lines)
          if (l['food_item_id'] != null) l['food_item_id'].toString()
      ];
      if (ids.isNotEmpty) {
        final foods = await SupaFlow.client
            .from('food_items')
            .select('id, status, name, image_url')
            .inFilter('id', ids);
        for (final f in foods as List) {
          final m = f as Map;
          state[m['id'].toString()] = '${m['status'] ?? ''}';
          final gone = m['status'] == 'consumed' || m['status'] == 'discarded';
          if (!gone && '${m['image_url'] ?? ''}'.trim().isEmpty) {
            noPhoto.add((m['id'].toString(), '${m['name'] ?? ''}'));
          }
        }
      }
    } catch (_) {
      if (mounted) _say('Could not open this receipt. Check your signal.');
      return;
    }
    if (!mounted) return;
    final shop = '${r['shop_name'] ?? ''}'.trim();
    final place = '${r['shop_location'] ?? ''}'.trim();
    final total = _money(r['total_amount'], r['currency']);
    final remove = await showModalBottomSheet<Object>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _cream,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheet) => ConstrainedBox(
        constraints:
            BoxConstraints(maxHeight: MediaQuery.of(sheet).size.height * 0.88),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(shop.isEmpty ? 'Receipt' : shop,
                    style: t.headlineSmall.copyWith(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: _ink)),
                if (place.isNotEmpty)
                  Text(place,
                      style: t.bodyLarge.copyWith(color: _muted, fontSize: 16)),
                const SizedBox(height: 4),
                Text(
                    [
                      if (_when(r['purchased_at']).isNotEmpty)
                        'Bought ${_when(r['purchased_at'])}',
                      'Scanned ${_when(r['scanned_at'])}',
                    ].join(' · '),
                    style: t.bodyMedium.copyWith(color: _muted, fontSize: 14)),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _border),
                  ),
                  child: Column(
                    children: [
                      for (var i = 0; i < lines.length; i++) ...[
                        if (i > 0)
                          const Divider(
                              height: 1, thickness: 1, color: _border),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                        '${lines[i]['quantity'] is num && (lines[i]['quantity'] as num) > 1 ? '${(lines[i]['quantity'] as num).round()} × ' : ''}${lines[i]['name']}',
                                        style: t.bodyLarge.copyWith(
                                            fontSize: 16, color: _ink)),
                                    Text(
                                        _fate(state[
                                            '${lines[i]['food_item_id']}']),
                                        style: t.bodySmall.copyWith(
                                            color: _muted, fontSize: 13)),
                                  ],
                                ),
                              ),
                              Text(
                                  _money(lines[i]['line_total'], r['currency']),
                                  style: t.bodyLarge.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: _ink)),
                            ],
                          ),
                        ),
                      ],
                      if (lines.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(14),
                          child: Text('No lines kept for this receipt.',
                              style: t.bodyMedium.copyWith(color: _muted)),
                        ),
                    ],
                  ),
                ),
                if (total.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text('Receipt total',
                            style: t.bodyLarge.copyWith(
                                fontWeight: FontWeight.w700, color: _ink)),
                      ),
                      Text(total,
                          style: t.titleMedium.copyWith(
                              fontWeight: FontWeight.w800, color: _ink)),
                    ],
                  ),
                  Text(
                      'The total includes anything on the receipt that was not food.',
                      style: t.bodySmall.copyWith(color: _muted, fontSize: 13)),
                ],
                if (noPhoto.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 52,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _forest,
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: _forest),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () => Navigator.of(sheet).pop('photos'),
                      icon: const Icon(Icons.travel_explore, size: 20),
                      label: Text(
                          noPhoto.length == 1
                              ? 'Find the product photo for 1 food'
                              : 'Find product photos for ${noPhoto.length} foods',
                          style: t.bodyLarge.copyWith(
                              color: _forest, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                TextButton.icon(
                  style: TextButton.styleFrom(
                      minimumSize: const Size(48, 48), foregroundColor: _red),
                  onPressed: () => Navigator.of(sheet).pop(true),
                  icon: const Icon(Icons.delete_outline, size: 20),
                  label: Text('Delete this receipt',
                      style: t.bodyLarge
                          .copyWith(color: _red, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (remove == 'photos' && mounted) {
      // One food at a time; closing a sheet skips that food.
      var added = 0;
      for (final (id, name) in noPhoto) {
        if (!mounted) return;
        final used = await showModalBottomSheet<bool>(
          context: context,
          isScrollControlled: true,
          backgroundColor: _cream,
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          builder: (sheet) => ConstrainedBox(
            constraints: BoxConstraints(
                maxHeight: MediaQuery.of(sheet).size.height * 0.9),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                    20, 20, 20, 20 + MediaQuery.of(sheet).viewInsets.bottom),
                child: ProductPhotoPicker(itemId: id, foodName: name),
              ),
            ),
          ),
        );
        if (used == true) added++;
      }
      if (mounted && noPhoto.length > 1) {
        _say(added == 0
            ? 'No photos added.'
            : (added == 1 ? '1 photo added.' : '$added photos added.'));
      }
      return;
    }
    if (remove != true || !mounted) return;
    final sure = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Delete this receipt?'),
        content: const Text(
            'The record of this shop goes for everyone in your household. The food stays in your kitchen.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(d).pop(false),
              child: const Text('Keep it')),
          TextButton(
              onPressed: () => Navigator.of(d).pop(true),
              child: const Text('Delete', style: TextStyle(color: _red))),
        ],
      ),
    );
    if (sure != true || !mounted) return;
    try {
      await SupaFlow.client
          .from('receipts')
          .delete()
          .eq('id', r['id'].toString());
      await _load(_for, quiet: true);
      if (mounted) _say('Receipt deleted. The food is still in your kitchen.');
    } catch (_) {
      if (mounted) _say('Could not delete it. Check your signal.');
    }
  }

  static String _fate(String? status) {
    switch (status) {
      case null:
        return 'Not added to the kitchen';
      case 'consumed':
        return 'Used';
      case 'discarded':
        return 'Thrown out';
      default:
        return 'In your kitchen';
    }
  }

  Widget _message(FlutterFlowTheme t, IconData icon, String title, String text,
      VoidCallback? retry) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: _sage, borderRadius: BorderRadius.circular(16)),
            child: Icon(icon, color: _forest, size: 28),
          ),
          const SizedBox(height: 16),
          Text(title,
              style: t.titleLarge.copyWith(
                  fontSize: 22, fontWeight: FontWeight.w800, color: _ink)),
          const SizedBox(height: 6),
          Text(text,
              style: t.bodyLarge
                  .copyWith(fontSize: 16, color: _muted, height: 1.4)),
          if (retry != null) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: _forest,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: retry,
                child: Text('Try again',
                    style: t.bodyLarge.copyWith(
                        color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
''';
