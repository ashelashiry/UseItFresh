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

/// Owner's review (15 Sep): Inventory places as icon buttons - the icon with
/// its count beside it and the name underneath - and a sub-menu of food groups
/// for the chosen place (Freezer: meals, ice cream, meat & fish, fruit & veg,
/// bread & pastry; Pantry: tins, jars & sauces, rice, pasta & grains, baking &
/// spices, snacks & drinks).
void buildStarterEditFlow(App app) {
  app.raw((project) {
    updateCustomWidget(project, name: 'InventoryKitchen', code: _wInventoryKitchen);
  });
}

const _wInventoryKitchen = r'''
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Everything below "Your kitchen.": where the food is, and what to use first.
///
/// Hybrid design (brief, 15 Sep): a segmented place control with counts, an
/// always-visible search field, and the two-column grid of sculpted food
/// cards with two-line names, amounts and date badges that say their basis.
class InventoryKitchen extends StatefulWidget {
  const InventoryKitchen({super.key, this.width, this.height});

  final double? width;
  final double? height;

  @override
  State<InventoryKitchen> createState() => _InventoryKitchenState();
}

class _InventoryKitchenState extends State<InventoryKitchen> {
  static const _forest = Color(0xFF07533A);
  static const _ink = Color(0xFF202C24);
  static const _muted = Color(0xFF59665D);
  static const _sage = Color(0xFFEDF2E8);
  static const _border = Color(0xFFDCE3D7);

  static const _food =
      'https://cdn.jsdelivr.net/gh/ashelashiry/UseItFresh@b50424f12bd372d81c9cd44d895b62c25d1329e7/design/v3/food';

  static const _places = <String, String>{
    'all': 'All',
    'fridge': 'Fridge',
    'freezer': 'Freezer',
    'pantry': 'Pantry',
  };

  String _for = '';
  bool _loading = true;
  bool _failed = false;
  bool _busy = false;
  List<Map<String, dynamic>> _items = const [];
  String _place = 'all';
  String _group = 'all';
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  // ---- data ----------------------------------------------------------------

  Future<void> _load(String household, {bool quiet = false}) async {
    if (mounted && !quiet) {
      setState(() {
        _loading = true;
        _failed = false;
      });
    }
    try {
      final rows = await SupaFlow.client
          .from('food_items_status')
          .select(
              'id, name, category, category_display_name, quantity, unit, image_url, location_type, computed_status, status_label, status_detail, days_left, printed_date, printed_date_type, status_basis')
          .eq('household_id', household)
          .order('urgency_rank', ascending: true)
          .order('days_left', ascending: true);
      if (!mounted || household != _for) return;
      setState(() {
        _items = List<Map<String, dynamic>>.from(rows as List);
        _loading = false;
        _failed = false;
      });
    } catch (_) {
      if (!mounted || household != _for) return;
      // A quiet reload keeps what is on screen rather than blanking it.
      if (quiet && _items.isNotEmpty) return;
      setState(() {
        _failed = true;
        _loading = false;
      });
    }
  }

  Future<void> _run(Future<void> Function() go) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await go();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _open(Map<String, dynamic> item) async {
    await context.pushNamed('FoodItemPage',
        queryParameters: {'itemId': item['id'].toString()});
    if (mounted && _for.isNotEmpty) _load(_for, quiet: true);
  }

  Future<void> _photographShelf() async {
    await clearShelfScan();
    if (!mounted) return;
    await context.pushNamed('CameraPage', queryParameters: {'mode': 'shelf'});
    if (mounted && _for.isNotEmpty) _load(_for, quiet: true);
  }

  Future<void> _addByHand() async {
    await context.pushNamed('AddFoodItemPage');
    if (mounted && _for.isNotEmpty) _load(_for, quiet: true);
  }

  static String _place0(Map<String, dynamic> i) =>
      (i['location_type'] ?? '').toString().toLowerCase();

  List<Map<String, dynamic>> get _inPlace {
    final here = _place == 'all'
        ? _items
        : _items.where((i) => _place0(i) == _place).toList();
    if (_place == 'all' || _group == 'all') return here;
    return here.where((i) => _groupOf(i, _place) == _group).toList();
  }

  // ---- food groups (owner, 15 Sep) -------------------------------------------
  // Each place offers the groups that make sense there; a food belongs to the
  // first group (in that place's order) whose words appear in its name or
  // category. Words ending in a space must match a whole word.

  static const _groupInfo = <String, (String, IconData)>{
    'meals': ('Meals', Icons.lunch_dining_outlined),
    'meat': ('Meat & fish', Icons.set_meal_outlined),
    'veg': ('Fruit & veg', Icons.eco_outlined),
    'dairy': ('Dairy & eggs', Icons.egg_outlined),
    'bread': ('Bread & pastry', Icons.bakery_dining_outlined),
    'ice': ('Ice cream', Icons.icecream_outlined),
    'tins': ('Tins', Icons.takeout_dining_outlined),
    'jars': ('Jars & sauces', Icons.liquor_outlined),
    'grains': ('Rice, pasta & grains', Icons.rice_bowl_outlined),
    'baking': ('Baking & spices', Icons.cookie_outlined),
    'snacks': ('Snacks & drinks', Icons.local_cafe_outlined),
    'other': ('Other', Icons.more_horiz),
  };

  static const _placeGroups = <String, List<String>>{
    'fridge': ['meals', 'meat', 'dairy', 'veg', 'jars', 'bread', 'snacks', 'other'],
    'freezer': ['meals', 'ice', 'meat', 'veg', 'bread', 'other'],
    'pantry': ['tins', 'jars', 'grains', 'baking', 'snacks', 'bread', 'veg', 'other'],
  };

  static const _groupWords = <String, List<String>>{
    'meals': ['leftover', 'cooked', 'meal ', 'meals ', 'lasagne', 'lasagna', 'curry', 'soup', 'stew', 'casserole', 'bolognese', 'pizza', 'dumpling', 'sushi', 'fried rice', 'pie ', 'pies ', 'quiche', 'ready meal'],
    'meat': ['beef', 'steak', 'mince', 'chicken', 'pork', 'lamb', 'sausage', 'bacon', 'ham ', 'salami', 'prosciutto', 'chorizo', 'turkey', 'duck', 'veal', 'schnitzel', 'rump', 'drumstick', 'wings', 'fish', 'salmon', 'tuna', 'prawn', 'shrimp', 'seafood', 'mussel', 'calamari', 'squid', 'crab', 'barramundi', 'snapper', 'cod ', 'meat', 'burger', 'meatball', 'frankfurt', 'kangaroo'],
    'dairy': ['milk', 'cheese', 'cheddar', 'feta', 'mozzarella', 'parmesan', 'brie', 'halloumi', 'ricotta', 'yoghurt', 'yogurt', 'butter ', 'cream', 'custard', 'egg ', 'eggs ', 'kefir', 'dairy'],
    'veg': ['apple', 'banana', 'orange', 'lemon', 'lime', 'berr', 'grape', 'pear', 'peach', 'plum', 'mango', 'melon', 'kiwi', 'avocado', 'lettuce', 'spinach', 'kale', 'rocket', 'salad', 'tomato', 'cucumber', 'capsicum', 'pepper', 'carrot', 'onion', 'garlic', 'potato', 'pumpkin', 'broccoli', 'cauliflower', 'cabbage', 'zucchini', 'eggplant', 'mushroom', 'celery', 'corn', 'peas ', 'pea ', 'beans ', 'asparagus', 'beetroot', 'herb', 'basil', 'coriander', 'parsley', 'mint', 'ginger', 'chilli', 'fruit', 'veg', 'produce'],
    'bread': ['bread', 'loaf', 'roll ', 'rolls ', 'bun ', 'buns ', 'wrap', 'tortilla', 'pita', 'naan', 'bagel', 'croissant', 'muffin', 'crumpet', 'pastry', 'baguette', 'sourdough', 'bakery'],
    'ice': ['ice cream', 'gelato', 'sorbet', 'ice block', 'icy pole', 'dessert', 'frozen yoghurt', 'frozen yogurt'],
    'tins': ['can ', 'cans ', 'canned', 'tin ', 'tins ', 'tinned', 'baked beans', 'chickpea', 'kidney bean', 'black bean', 'cannellini', 'tuna', 'sardine', 'coconut milk', 'coconut cream', 'chopped tomato', 'diced tomato', 'condensed milk', 'beetroot slices'],
    'jars': ['jar ', 'jars ', 'sauce', 'jam ', 'honey', 'peanut butter', 'spread', 'mayo', 'mustard', 'ketchup', 'pesto', 'vinegar', 'oil ', 'paste', 'pickle', 'olive', 'relish', 'chutney', 'syrup', 'dressing', 'salsa', 'vegemite', 'nutella', 'tahini', 'capers', 'passata', 'hummus', 'dip '],
    'grains': ['rice', 'pasta', 'spaghetti', 'penne', 'fusilli', 'macaroni', 'lasagne sheet', 'noodle', 'oats', 'porridge', 'muesli', 'granola', 'cereal', 'flour', 'quinoa', 'couscous', 'lentil', 'barley', 'polenta', 'grain'],
    'baking': ['sugar', 'salt ', 'pepper ', 'spice', 'cinnamon', 'paprika', 'cumin', 'turmeric', 'baking', 'cocoa', 'yeast', 'stock', 'vanilla', 'gelatine', 'cornflour', 'herbs ', 'seasoning'],
    'snacks': ['chips', 'crisps', 'biscuit', 'cookie', 'chocolate', 'lolly', 'lollies', 'nuts', 'almond', 'cashew', 'peanut', 'cracker', 'popcorn', 'pretzel', 'bar ', 'bars ', 'tea ', 'coffee', 'juice', 'drink', 'water', 'soda', 'cola', 'lemonade', 'wine', 'beer', 'snack'],
  };

  static String _groupOf(Map<String, dynamic> i, String place) {
    final text = ' ${[
      i['name'],
      i['category'],
      i['category_display_name']
    ].map((v) => (v ?? '').toString().toLowerCase()).join(' ').replaceAll(RegExp(r'[^a-z]+'), ' ')} ';
    for (final g in _placeGroups[place] ?? const <String>[]) {
      for (final w in _groupWords[g] ?? const <String>[]) {
        if (text.contains(' $w')) return g;
      }
    }
    return 'other';
  }

  void _choosePlace(String place) => setState(() {
        _place = place;
        _group = 'all';
      });

  List<Map<String, dynamic>> get _shown {
    final q = _search.text.trim().toLowerCase();
    if (q.isEmpty) return _inPlace;
    return _inPlace.where((i) {
      final name = (i['name'] ?? '').toString().toLowerCase();
      final cat = (i['category_display_name'] ?? '').toString().toLowerCase();
      return name.contains(q) || cat.contains(q);
    }).toList();
  }

  static IconData _placeIcon(String place) {
    switch (place) {
      case 'fridge':
        return Icons.kitchen_outlined;
      case 'freezer':
        return Icons.ac_unit;
      case 'pantry':
        return Icons.inventory_2_outlined;
      default:
        return Icons.restaurant;
    }
  }

  // ---- page ----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();

    // A reminder was tapped: open Use soon.
    if (FFAppState().openUseSoon) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !FFAppState().openUseSoon) return;
        FFAppState().openUseSoon = false;
        context.pushNamed('UseSoonPage');
      });
    }
    final household = FFAppState().currentHouseholdId;
    final t = FlutterFlowTheme.of(context);
    if (household.isEmpty) {
      // The page's on-load is still choosing the household.
      return SizedBox(width: widget.width, child: _skeleton());
    }
    if (household != _for) {
      _for = household;
      _place = 'all';
      _group = 'all';
      _search.clear();
      WidgetsBinding.instance.addPostFrameCallback((_) => _load(household));
    }

    Widget body;
    String key;
    if (_loading) {
      body = _skeleton();
      key = 'loading';
    } else if (_failed) {
      body = _offline(t);
      key = 'offline';
    } else if (_items.isEmpty) {
      body = _emptyKitchen(t);
      key = 'empty';
    } else {
      body = _kitchen(t);
      key = 'kitchen';
    }

    return SizedBox(
      width: widget.width,
      child: AnimatedSwitcher(
        duration: MediaQuery.of(context).disableAnimations
            ? Duration.zero
            : const Duration(milliseconds: 200),
        child: KeyedSubtree(key: ValueKey(key), child: body),
      ),
    );
  }

  Widget _kitchen(FlutterFlowTheme t) {
    final soon = _items.where(_uSoon).length;
    final count = _items.length == 1 ? '1 item' : '${_items.length} items';
    final shown = _shown;
    final searching = _search.text.trim().isNotEmpty;

    Widget results;
    if (shown.isNotEmpty) {
      results = _grid(t, shown);
    } else if (searching) {
      results = _noMatches(t);
    } else {
      results = _emptyPlace(t);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          soon == 0 ? count : '$count · $soon to use soon',
          style: t.bodyLarge.copyWith(color: _muted, fontSize: 16),
        ),
        const SizedBox(height: 16),
        _placeControl(t),
        _groupMenu(t),
        if (_items.isNotEmpty) ...[
          const SizedBox(height: 12),
          _searchField(t),
        ],
        const SizedBox(height: 16),
        results,
      ],
    );
  }

  // ---- controls ------------------------------------------------------------

  Widget _placeControl(FlutterFlowTheme t) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFDEE6D5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFCBD6BF)),
      ),
      child: Row(
        children: [
          for (final e in _places.entries)
            Expanded(child: _segment(t, e.key, e.value)),
        ],
      ),
    );
  }

  /// A place as an icon with its count beside it and the name underneath
  /// (owner, 15 Sep).
  Widget _segment(FlutterFlowTheme t, String place, String label) {
    final on = _place == place;
    final n = place == 'all'
        ? _items.length
        : _items.where((i) => _place0(i) == place).length;
    return Semantics(
      button: true,
      selected: on,
      label: '$label, $n',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _choosePlace(place),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 66,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: on
                ? const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFFFFEFA), Color(0xFFF3F4EA)])
                : null,
            borderRadius: BorderRadius.circular(16),
            boxShadow: on
                ? const [
                    BoxShadow(color: Color(0xFFCBD6BF), offset: Offset(0, 2)),
                    BoxShadow(
                        color: Color(0x1A254221),
                        blurRadius: 6,
                        offset: Offset(0, 3))
                  ]
                : null,
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(place == 'all' ? Icons.grid_view_rounded : _placeIcon(place),
                        size: 22, color: on ? _forest : _ink),
                    const SizedBox(width: 5),
                    Text('$n',
                        style: t.bodyMedium.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: on ? _forest : _muted)),
                  ],
                ),
                const SizedBox(height: 3),
                Text(label,
                    style: t.bodySmall.copyWith(
                        fontSize: 12.5,
                        fontWeight: on ? FontWeight.w800 : FontWeight.w600,
                        color: on ? _forest : _ink)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// The chosen place's food groups, as a row of chips with counts.
  Widget _groupMenu(FlutterFlowTheme t) {
    final groups = _placeGroups[_place];
    Widget menu = const SizedBox(width: double.infinity);
    if (groups != null) {
      final here = _items.where((i) => _place0(i) == _place).toList();
      final counts = <String, int>{};
      for (final i in here) {
        final g = _groupOf(i, _place);
        counts[g] = (counts[g] ?? 0) + 1;
      }
      final shown = [
        'all',
        for (final g in groups)
          if ((counts[g] ?? 0) > 0) g
      ];
      if (shown.length > 2) {
        menu = Padding(
          padding: const EdgeInsets.only(top: 10),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final g in shown)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _groupChip(
                        t,
                        g,
                        g == 'all' ? 'All' : _groupInfo[g]!.$1,
                        g == 'all' ? null : _groupInfo[g]!.$2,
                        g == 'all' ? here.length : counts[g]!),
                  ),
              ],
            ),
          ),
        );
      }
    }
    return AnimatedSize(
      duration: MediaQuery.of(context).disableAnimations
          ? Duration.zero
          : const Duration(milliseconds: 180),
      alignment: Alignment.topCenter,
      child: menu,
    );
  }

  Widget _groupChip(
      FlutterFlowTheme t, String group, String label, IconData? icon, int n) {
    final on = _group == group;
    return Semantics(
      button: true,
      selected: on,
      label: '$label, $n',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _group = group),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          constraints: const BoxConstraints(minHeight: 40),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: on
                  ? const [_uForestTop, _uForest]
                  : const [Color(0xFFFFFEFA), Color(0xFFEFF2E7)],
            ),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
                color: on ? const Color(0xFF06422E) : const Color(0xFFCCD7C2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 17, color: on ? Colors.white : _forest),
                const SizedBox(width: 6),
              ],
              Text(label,
                  style: t.bodySmall.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: on ? Colors.white : _ink)),
              const SizedBox(width: 5),
              Text('$n',
                  style: t.bodySmall.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: on ? const Color(0xCCFFFFFF) : _muted)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _searchField(FlutterFlowTheme t) {
    return TextField(
      controller: _search,
      onChanged: (_) => setState(() {}),
      textInputAction: TextInputAction.search,
      style: t.bodyLarge.copyWith(fontSize: 16, color: _ink),
      decoration: InputDecoration(
        hintText: 'Search your food',
        hintStyle: t.bodyLarge.copyWith(fontSize: 16, color: _muted),
        prefixIcon: const Icon(Icons.search, color: _muted),
        suffixIcon: _search.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Clear search',
                icon: const Icon(Icons.close, color: _muted),
                onPressed: () => setState(_search.clear),
              ),
        filled: true,
        fillColor: const Color(0xFFFFFDF7),
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _uLine),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _uLine),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _forest, width: 1.5),
        ),
      ),
    );
  }

  // ---- grid ----------------------------------------------------------------

  Widget _grid(FlutterFlowTheme t, List<Map<String, dynamic>> items) {
    return LayoutBuilder(builder: (context, box) {
      const gap = 12.0;
      final w = (box.maxWidth - gap) / 2;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (final i in items)
            SizedBox(
                width: w, child: _uFoodCard(context, i, onTap: () => _open(i))),
        ],
      );
    });
  }

  // ---- states --------------------------------------------------------------

  Widget _skeleton() {
    return LayoutBuilder(builder: (context, box) {
      const gap = 12.0;
      final w = box.maxWidth.isFinite ? (box.maxWidth - gap) / 2 : 160.0;
      Widget block(double width, double h, double r) => Container(
            width: width,
            height: h,
            decoration: BoxDecoration(
                color: _sage, borderRadius: BorderRadius.circular(r)),
          );
      return Semantics(
        label: 'Loading your kitchen',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            block(140, 18, 8),
            const SizedBox(height: 16),
            block(double.infinity, 56, 16),
            const SizedBox(height: 16),
            Wrap(spacing: gap, runSpacing: gap, children: [
              for (var i = 0; i < 4; i++) block(w, w * 0.8 + 56, 20),
            ]),
          ],
        ),
      );
    });
  }

  Widget _message(
    FlutterFlowTheme t, {
    required IconData icon,
    required String title,
    required String body,
    required String action,
    required IconData actionIcon,
    required VoidCallback onAction,
    String? second,
    VoidCallback? onSecond,
  }) {
    return _USurface(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
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
          Text(body,
              style: t.bodyLarge
                  .copyWith(fontSize: 16, color: _muted, height: 1.4)),
          const SizedBox(height: 16),
          _UButton(action,
              icon: actionIcon, busy: _busy, onTap: _busy ? null : onAction),
          if (second != null && onSecond != null)
            Center(
              child: TextButton(
                style: TextButton.styleFrom(
                    minimumSize: const Size(48, 48), foregroundColor: _forest),
                onPressed: _busy ? null : onSecond,
                child: Text(second,
                    style: t.bodyLarge
                        .copyWith(color: _forest, fontWeight: FontWeight.w700)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _offline(FlutterFlowTheme t) => _message(
        t,
        icon: Icons.cloud_off_outlined,
        title: 'Can’t reach your kitchen.',
        body:
            'No signal, or the connection dropped. Your food will show again as soon as you are back online.',
        action: 'Try again',
        actionIcon: Icons.refresh,
        onAction: () => _load(_for),
      );

  Widget _emptyKitchen(FlutterFlowTheme t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _USurface(
          child: SizedBox(
            height: 190,
            child: Image.network('$_food/tomatoes.webp',
                fit: BoxFit.cover,
                semanticLabel: '',
                errorBuilder: (_, __, ___) => Container(color: _sage)),
          ),
        ),
        const SizedBox(height: 20),
        Text('Your fresh start.',
            style: t.titleLarge.copyWith(
                fontSize: 24, fontWeight: FontWeight.w800, color: _ink)),
        const SizedBox(height: 6),
        Text(
            'Add a few things you already have and this is where they will live.',
            style:
                t.bodyLarge.copyWith(fontSize: 16, color: _muted, height: 1.4)),
        const SizedBox(height: 16),
        _UButton('Add food',
            icon: Icons.add,
            busy: _busy,
            onTap: _busy ? null : () => _run(_photographShelf)),
        Center(
          child: TextButton(
            style: TextButton.styleFrom(
                minimumSize: const Size(48, 48), foregroundColor: _forest),
            onPressed: _busy ? null : () => _run(_addByHand),
            child: Text('Enter manually',
                style: t.bodyLarge
                    .copyWith(color: _forest, fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }

  Widget _emptyPlace(FlutterFlowTheme t) {
    final name = (_places[_place] ?? '').toLowerCase();
    switch (_place) {
      case 'fridge':
        return _message(t,
            icon: _placeIcon(_place),
            title: 'Nothing in the fridge yet.',
            body: 'Photograph a shelf to add what is on it.',
            action: 'Photograph a shelf',
            actionIcon: Icons.photo_camera_outlined,
            onAction: () => _run(_photographShelf),
            second: 'Enter manually',
            onSecond: () => _run(_addByHand));
      default:
        return _message(t,
            icon: _placeIcon(_place),
            title: 'Nothing in the $name yet.',
            body: _place == 'freezer'
                ? 'Food you freeze shows here, with how long it keeps.'
                : 'Dry food, tins and jars show here.',
            action: 'Add food',
            actionIcon: Icons.add,
            onAction: () => _run(_addByHand),
            second: 'See everything',
            onSecond: () => setState(() {
                  _place = 'all';
                  _group = 'all';
                }));
    }
  }

  Widget _noMatches(FlutterFlowTheme t) {
    final q = _search.text.trim();
    final where =
        _place == 'all' ? '' : ' in the ${_places[_place]!.toLowerCase()}';
    return _message(t,
        icon: Icons.search_off,
        title: 'Nothing matches “$q”$where.',
        body: 'Check the spelling, or search everywhere.',
        action: 'Clear search',
        actionIcon: Icons.close,
        onAction: () => setState(_search.clear),
        second: _place == 'all' ? null : 'Search everywhere',
        onSecond:
            _place == 'all'
                ? null
                : () => setState(() {
                      _place = 'all';
                      _group = 'all';
                    }));
  }
}

// ---- Hybrid material (design brief, 15 Sep) --------------------------------
// Cream canvas over a blurred food background (set on the page), sculpted
// cream surfaces, forest gradient primary buttons, calm date badges.

const _uForest = Color(0xFF07533A);
const _uForestTop = Color(0xFF176C50);
const _uInk = Color(0xFF202C24);
const _uMuted = Color(0xFF59665D);
const _uSage = Color(0xFFE6EDDF);
const _uLine = Color(0xFFCDD4C3);
const _uCream = Color(0xFFF7F7F0);

bool _uStill(BuildContext c) => MediaQuery.of(c).disableAnimations;

/// A sculpted cream surface: warm diagonal gradient, thin sage border, a
/// narrow white top highlight, a 2px lower edge and a soft shadow.
class _USurface extends StatelessWidget {
  const _USurface({
    required this.child,
    this.padding = EdgeInsets.zero,
    this.radius = 22,
    this.onTap,
    this.label,
    this.tint,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;
  final String? label;
  final List<Color>? tint;

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(radius);
    final body = Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: tint ?? const [Color(0xFFFFFEF9), Color(0xFFF3F3E9)],
        ),
        borderRadius: r,
        border: Border.all(color: _uLine),
        boxShadow: const [
          BoxShadow(color: Color(0xFFD2D8C9), offset: Offset(0, 2)),
          BoxShadow(
              color: Color(0x14263824), offset: Offset(0, 8), blurRadius: 16),
        ],
      ),
      child: ClipRRect(
        borderRadius: r,
        child: Stack(
          children: [
            Padding(padding: padding, child: child),
            // The narrow white highlight along the top edge.
            const Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: 1.5,
              child: ColoredBox(color: Color(0xCCFFFFFF)),
            ),
          ],
        ),
      ),
    );
    if (onTap == null) return body;
    return _UPress(onTap: onTap!, label: label, radius: radius, child: body);
  }
}

/// A tap target that sinks 1px while pressed (tonal only with reduced motion).
class _UPress extends StatefulWidget {
  const _UPress({
    required this.child,
    required this.onTap,
    this.label,
    this.radius = 16,
    this.enabled = true,
  });

  final Widget child;
  final VoidCallback onTap;
  final String? label;
  final double radius;
  final bool enabled;

  @override
  State<_UPress> createState() => _UPressState();
}

class _UPressState extends State<_UPress> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final still = _uStill(context);
    return Semantics(
      button: true,
      enabled: widget.enabled,
      label: widget.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown:
            widget.enabled ? (_) => setState(() => _down = true) : null,
        onTapUp: (_) => setState(() => _down = false),
        onTapCancel: () => setState(() => _down = false),
        onTap: widget.enabled ? widget.onTap : null,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 100),
          opacity: widget.enabled ? (_down && still ? 0.85 : 1) : 0.55,
          child: AnimatedSlide(
            duration: const Duration(milliseconds: 100),
            offset: _down && !still ? const Offset(0, 0.01) : Offset.zero,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// Buttons: one forest primary per task, cream secondaries, quiet text links.
class _UButton extends StatelessWidget {
  const _UButton(
    this.text, {
    required this.onTap,
    this.icon,
    this.kind = 'primary',
    this.busy = false,
    this.trailing = false,
  });

  final String text;
  final VoidCallback? onTap;
  final IconData? icon;
  final String kind; // primary | secondary | danger
  final bool busy;
  final bool trailing;

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);
    final primary = kind == 'primary';
    final danger = kind == 'danger';
    final fg = primary
        ? Colors.white
        : (danger ? const Color(0xFFB42318) : _uForest);
    final iconW = icon == null ? null : Icon(icon, size: 20, color: fg);
    final label = Text(text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: t.bodyLarge.copyWith(
            color: fg,
            fontSize: primary ? 16 : 15,
            fontWeight: primary ? FontWeight.w700 : FontWeight.w600));
    final content = busy
        ? SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: fg))
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (iconW != null && !trailing) ...[iconW, const SizedBox(width: 8)],
              Flexible(child: label),
              if (iconW != null && trailing) ...[const SizedBox(width: 8), iconW],
            ],
          );
    final box = Container(
      constraints: BoxConstraints(minHeight: primary ? 52 : 48),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: primary
              ? const [_uForestTop, _uForest]
              : const [Color(0xFFFFFEFA), Color(0xFFEDF0E4)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: primary
                ? const Color(0xFF06422E)
                : (danger ? const Color(0xFFEBC5BF) : const Color(0xFFCCD7C2))),
        boxShadow: primary
            ? const [
                BoxShadow(color: Color(0xFF033C29), offset: Offset(0, 3)),
                BoxShadow(
                    color: Color(0x2007533A),
                    offset: Offset(0, 6),
                    blurRadius: 10),
              ]
            : const [BoxShadow(color: Color(0xFFD6DFCC), offset: Offset(0, 2))],
      ),
      child: content,
    );
    return _UPress(
      onTap: onTap ?? () {},
      enabled: onTap != null && !busy,
      label: text,
      child: box,
    );
  }
}

/// The date badge from dateBadge(): "Label|tone".
Widget _uBadge(BuildContext context, String spec, {double size = 12}) {
  if (spec.isEmpty) return const SizedBox.shrink();
  final parts = spec.split('|');
  final tone = parts.length > 1 ? parts[1] : 'calm';
  const tones = <String, (Color, Color)>{
    'urgent': (Color(0xFFFDE3E0), Color(0xFFB42318)),
    'warm': (Color(0xFFFFEAD4), Color(0xFF884311)),
    'calm': (Color(0xFFE6EDDF), Color(0xFF335837)),
    'cold': (Color(0xFFE1ECF7), Color(0xFF285E8E)),
  };
  final c = tones[tone] ?? tones['calm']!;
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
        color: c.$1, borderRadius: BorderRadius.circular(8)),
    child: Text(parts.first,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: FlutterFlowTheme.of(context).bodySmall.copyWith(
            color: c.$2, fontSize: size, fontWeight: FontWeight.w600)),
  );
}

/// A compact picture stand-in when no suitable photo exists: the food's name
/// set small and calm, never a borrowed photo of a different food or form.
Widget _uFallback(BuildContext context, String name, {double height = 110}) {
  final t = FlutterFlowTheme.of(context);
  return Container(
    height: height,
    color: const Color(0xFFE4E9D9),
    alignment: Alignment.center,
    padding: const EdgeInsets.symmetric(horizontal: 12),
    child: Text(name.toUpperCase(),
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: t.bodyMedium.copyWith(
            color: const Color(0xFF526845),
            letterSpacing: 2,
            fontSize: 14,
            fontWeight: FontWeight.w600)),
  );
}

/// The back control on ordinary pages: a cream square with a forest arrow.
/// The one back button across the app (owner, 15 Sep): a soft frosted cream
/// circle with a slim forest chevron.
Widget _uBack(BuildContext context, VoidCallback onTap) => _UPress(
      onTap: onTap,
      label: 'Back',
      child: Container(
        width: 44,
        height: 44,
        decoration: _uBackDeco(),
        child: const Icon(Icons.arrow_back_ios_new_rounded,
            color: _uForest, size: 18),
      ),
    );

/// The food picture library (owner, 15 Sep): fresh-looking photos kept in
/// the repository (design/library) with an index the app downloads, so new
/// pictures arrive without a new build. The index carries the matching rules:
/// a phrase from `match` is in the food's name, every processed word in the
/// name (canned, frozen, sauce...) is in the item's `needs` or `allow`, one
/// of `needs` is present when given, and no `not` word is.
String _uLibRaw = '';
Map _uLib = const {};
final Map<String, String> _uLibHits = {};

String _uLibrary(String name, {bool freshOnly = false}) {
  final raw = FFAppState().foodLibrary;
  if (raw.isEmpty) return '';
  if (raw != _uLibRaw) {
    _uLibRaw = raw;
    _uLibHits.clear();
    try {
      final j = jsonDecode(raw);
      _uLib = j is Map ? j : const {};
    } catch (_) {
      _uLib = const {};
    }
  }
  final key = '${freshOnly ? 'f' : 'a'}|${name.toLowerCase()}';
  final known = _uLibHits[key];
  if (known != null) return known;
  final n = ' ${name.toLowerCase().replaceAll(RegExp(r'[^a-z]+'), ' ').trim()} ';
  bool has(String w) => n.contains(' $w ');
  List<String> words(Map m, String k) =>
      [for (final w in (m[k] is List ? m[k] as List : const [])) '$w'];
  final processed = words(_uLib, 'processed').where(has).toList();
  var best = '';
  var score = -1;
  for (final item in (_uLib['items'] is List ? _uLib['items'] as List : const [])) {
    if (item is! Map) continue;
    if (freshOnly && '${item['kind'] ?? ''}' != 'fresh') continue;
    final needs = words(item, 'needs');
    final allow = words(item, 'allow');
    if (words(item, 'not').any(has)) continue;
    if (needs.isNotEmpty && !needs.any(has)) continue;
    if (processed.any((w) => !needs.contains(w) && !allow.contains(w))) continue;
    for (final m in words(item, 'match')) {
      if (!has(m)) continue;
      final s = m.length + (needs.isNotEmpty ? 100 : 0);
      if (s > score) {
        score = s;
        best = '${_uLib['base'] ?? ''}${item['file'] ?? ''}';
      }
    }
  }
  if (_uLibHits.length > 500) _uLibHits.clear();
  _uLibHits[key] = best;
  return best;
}

/// A fresh-looking photo of the food, from the library first, or ''.
/// `freshOnly` keeps packaged pictures (dry pasta, a tin) off meal cards.
String _uFresh(String name, {bool freshOnly = false}) {
  final lib = _uLibrary(name, freshOnly: freshOnly);
  if (lib.isNotEmpty) return lib;
  return foodPhoto(name, '') ?? '';
}

/// Which picture a food shows (owner, 15 Sep): by default a fresh-looking
/// photo of that food when one matches it and its form, otherwise the
/// person's own photo or scan. "My photos first" in Profile swaps the order.
String _uPicture(String name, String own) {
  final mine = own.trim();
  final product = mine.contains('/product-') || mine.contains('openfoodfacts');
  for (final source in _uPictureOrder()) {
    if (source == 'stock') {
      final fresh = _uFresh(name);
      if (fresh.isNotEmpty) return fresh;
    } else if (source == 'scan') {
      if (mine.isNotEmpty && !product) return mine;
    } else if (source == 'product') {
      if (product) return mine;
    }
  }
  return '';
}

/// The owner's ranked picture sources, e.g. ['stock', 'scan', 'product'].
/// Older settings: 'stock' (fresh first) and 'own' (my photos first).
List<String> _uPictureOrder() {
  const all = ['stock', 'scan', 'product'];
  final saved = FFAppState().photoPreference;
  final order = saved == 'own'
      ? ['scan', 'product']
      : [for (final s in saved.split(',')) if (all.contains(s.trim())) s.trim()];
  for (final s in all) {
    if (!order.contains(s)) order.add(s);
  }
  return order.toSet().toList();
}

String _uPictureOrderLabel() {
  const names = {'stock': 'stock', 'scan': 'my scan', 'product': 'product'};
  return _uPictureOrder().map((s) => names[s]).join(', then ');
}

/// A food card for the two-column grids: picture, two-line name, amount and
/// the date badge.
Widget _uFoodCard(BuildContext context, Map item, {required VoidCallback onTap}) {
  final t = FlutterFlowTheme.of(context);
  final name = '${item['name'] ?? ''}';
  final photo = _uPicture(name, '${item['image_url'] ?? ''}');
  final qty = item['quantity'] is num ? (item['quantity'] as num).toDouble() : null;
  final amount = quantityLabel(qty, '${item['unit'] ?? ''}') ?? '';
  final badge = dateBadge(
        '${item['computed_status'] ?? ''}',
        item['days_left'] is num ? (item['days_left'] as num).round() : null,
        DateTime.tryParse('${item['printed_date'] ?? ''}'),
        '${item['printed_date_type'] ?? ''}',
        '${item['status_basis'] ?? ''}',
      ) ??
      '';
  return _USurface(
    radius: 20,
    onTap: onTap,
    label: '$name. ${badge.split('|').first}',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 110,
          child: photo.isEmpty
              ? _uFallback(context, name)
              : Image.network(photo,
                  fit: BoxFit.cover,
                  cacheWidth: 480,
                  errorBuilder: (_, __, ___) => _uFallback(context, name)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(11, 10, 11, 11),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: t.titleSmall.copyWith(
                      fontSize: 16,
                      height: 1.2,
                      fontWeight: FontWeight.w700,
                      color: _uInk)),
              const SizedBox(height: 4),
              Text(amount.isEmpty ? ' ' : amount,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.bodySmall.copyWith(color: _uMuted, fontSize: 13)),
              const SizedBox(height: 8),
              _uBadge(context, badge),
            ],
          ),
        ),
      ],
    ),
  );
}

/// Food close to its date, the one rule Home, Inventory and Use soon share:
/// past or at its limit, "use soon", or three days or fewer; never frozen.
bool _uSoon(Map item) {
  final status = '${item['computed_status'] ?? ''}';
  if (status == 'frozen' || status == 'consumed' || status == 'discarded') {
    return false;
  }
  if (const {'past_use_by', 'use_today', 'use_soon', 'past_best_before'}
      .contains(status)) {
    return true;
  }
  final d = item['days_left'];
  return d is num && d <= 3;
}

/// The sculpted card as a decoration, for existing layouts.
BoxDecoration _uCard(double radius) => BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFFEF9), Color(0xFFF3F3E9)],
      ),
      borderRadius: BorderRadius.circular(radius < 18 ? radius : 22),
      border: Border.all(color: _uLine),
      boxShadow: const [
        BoxShadow(color: Color(0xFFD2D8C9), offset: Offset(0, 2)),
        BoxShadow(color: Color(0x14263824), offset: Offset(0, 8), blurRadius: 16),
      ],
    );

/// The ordinary back control: a cream square with a forest arrow.
BoxDecoration _uBackDeco() => BoxDecoration(
      color: const Color(0xF2FFFDF4),
      shape: BoxShape.circle,
      border: Border.all(color: const Color(0xFFE2E8DA)),
      boxShadow: const [
        BoxShadow(color: Color(0x1F1E3A2B), offset: Offset(0, 2), blurRadius: 8)
      ],
    );
''';

