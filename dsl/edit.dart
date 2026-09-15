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

/// Build 17 Shopping list: what to buy is grouped by aisle in shop order
/// (Fruit & veg, Meat & fish, Dairy & eggs, Bakery, Pantry, Frozen, Drinks &
/// snacks, Other), and Copy the list puts it on the clipboard to share.
void buildStarterEditFlow(App app) {
  app.raw((project) {
    updateCustomWidget(project, name: 'ShoppingListLive', code: _wShoppingListLive);
  });
}

const _wShoppingListLive = r'''
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// The shopping list, shared and live.
class ShoppingListLive extends StatefulWidget {
  const ShoppingListLive({super.key, this.width, this.height});

  final double? width;
  final double? height;

  @override
  State<ShoppingListLive> createState() => _ShoppingListLiveState();
}

class _ShoppingListLiveState extends State<ShoppingListLive> {
  static const _forest = Color(0xFF07533A);
  static const _ink = Color(0xFF202C24);
  static const _muted = Color(0xFF59665D);
  static const _sage = Color(0xFFEDF2E8);
  static const _border = Color(0xFFDCE3D7);

  String _for = '';
  String _listId = '';
  bool _loading = true;
  bool _offline = false;
  bool _adding = false;
  bool _basketBusy = false;
  List<Map<String, dynamic>> _items = const [];
  List<String> _again = const [];
  final Set<String> _busy = {};
  final _field = TextEditingController();
  RealtimeChannel? _channel;

  @override
  void dispose() {
    _field.dispose();
    _unsubscribe();
    super.dispose();
  }

  void _unsubscribe() {
    final c = _channel;
    _channel = null;
    if (c != null) SupaFlow.client.removeChannel(c);
  }

  void _subscribe(String listId) {
    _unsubscribe();
    _channel = SupaFlow.client
        .channel('shopping-$listId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'shopping_list_items',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'shopping_list_id',
            value: listId,
          ),
          callback: (_) {
            if (mounted) _load(quiet: true);
          },
        )
        .subscribe();
  }

  Future<void> _load({bool quiet = false}) async {
    final household = _for;
    if (household.isEmpty) return;
    if (!quiet && mounted) {
      setState(() {
        _loading = true;
        _offline = false;
      });
    }
    try {
      if (_listId.isEmpty) {
        // Creating a household seeds exactly one list, so the oldest is the one.
        final lists = await SupaFlow.client
            .from('shopping_lists')
            .select('id')
            .eq('household_id', household)
            .order('created_at')
            .limit(1);
        if ((lists as List).isNotEmpty) {
          _listId = lists.first['id'].toString();
          _subscribe(_listId);
        }
      }
      var items = <Map<String, dynamic>>[];
      if (_listId.isNotEmpty) {
        final rows = await SupaFlow.client
            .from('shopping_list_items')
            .select('id, name, is_purchased, created_at')
            .eq('shopping_list_id', _listId)
            .order('is_purchased', ascending: true)
            .order('created_at', ascending: true);
        items = List<Map<String, dynamic>>.from(rows as List);
      }
      // What ran out lately and is not on the list already.
      var again = <String>[];
      try {
        final since = DateTime.now()
            .toUtc()
            .subtract(const Duration(days: 21))
            .toIso8601String();
        final gone = await SupaFlow.client
            .from('food_items')
            .select('name, archived_at')
            .eq('household_id', household)
            .inFilter('status', ['consumed', 'discarded'])
            .gte('archived_at', since)
            .order('archived_at', ascending: false)
            .limit(60);
        final onList = items
            .map((i) => (i['name'] ?? '').toString().trim().toLowerCase())
            .toSet();
        final seen = <String>{};
        for (final g in gone as List) {
          final name = (g['name'] ?? '').toString().trim();
          final key = name.toLowerCase();
          if (name.isEmpty || onList.contains(key) || !seen.add(key)) continue;
          again.add(name);
          if (again.length >= 8) break;
        }
      } catch (_) {
        // Suggestions are a nicety; the list still works without them.
      }
      if (!mounted || household != _for) return;
      setState(() {
        _items = items;
        _again = again;
        _loading = false;
        _offline = false;
      });
    } catch (_) {
      if (!mounted) return;
      if (quiet && _items.isNotEmpty) return;
      setState(() {
        _loading = false;
        _offline = true;
      });
    }
  }

  void _say(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> _add([String? name]) async {
    final text = (name ?? _field.text).trim();
    if (text.isEmpty) {
      _say('Type something to add first.');
      return;
    }
    if (_adding) return;
    setState(() => _adding = true);
    final said = await addNameToShoppingList(text);
    if (!mounted) return;
    setState(() => _adding = false);
    if (said.isNotEmpty) {
      _say(said);
      return;
    }
    if (name == null) _field.clear();
    _load(quiet: true);
  }

  Future<void> _tick(Map<String, dynamic> item) async {
    final id = item['id'].toString();
    if (_busy.contains(id)) return;
    final now = item['is_purchased'] == true;
    setState(() {
      _busy.add(id);
      item['is_purchased'] = !now;
    });
    try {
      await SupaFlow.client
          .from('shopping_list_items')
          .update({'is_purchased': !now}).eq('id', id);
    } catch (_) {
      if (mounted) {
        setState(() => item['is_purchased'] = now);
        _say('Could not update the list. Check your signal and try again.');
      }
    } finally {
      if (mounted) setState(() => _busy.remove(id));
      _load(quiet: true);
    }
  }

  Future<void> _remove(Map<String, dynamic> item) async {
    final id = item['id'].toString();
    if (_busy.contains(id)) return;
    setState(() => _busy.add(id));
    try {
      await SupaFlow.client.from('shopping_list_items').delete().eq('id', id);
      if (mounted) {
        setState(() =>
            _items = _items.where((i) => i['id'].toString() != id).toList());
      }
    } catch (_) {
      if (mounted)
        _say('Could not remove it. Check your signal and try again.');
    } finally {
      if (mounted) setState(() => _busy.remove(id));
      _load(quiet: true);
    }
  }

  Future<void> _basket() async {
    if (_basketBusy) return;
    setState(() => _basketBusy = true);
    final said = await addBasketToKitchen();
    if (!mounted) return;
    setState(() => _basketBusy = false);
    _say(said.isEmpty ? 'Added to your kitchen.' : said);
    _load(quiet: true);
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();
    final t = FlutterFlowTheme.of(context);
    final household = FFAppState().currentHouseholdId;
    if (household.isNotEmpty && household != _for) {
      _for = household;
      _listId = '';
      _unsubscribe();
      WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    }

    final toBuy = _items.where((i) => i['is_purchased'] != true).toList();
    final inBasket = _items.where((i) => i['is_purchased'] == true).toList();

    return SizedBox(
      width: widget.width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!_loading && !_offline)
            Text(
              toBuy.isEmpty
                  ? (inBasket.isEmpty
                      ? 'Nothing on it yet'
                      : 'Everything is in the basket')
                  : '${toBuy.length} to buy${inBasket.isEmpty ? '' : ' · ${inBasket.length} in the basket'}',
              style: t.bodyLarge.copyWith(color: _muted, fontSize: 16),
            ),
          if (!_loading && !_offline && toBuy.isNotEmpty)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                style: TextButton.styleFrom(
                    foregroundColor: _forest,
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(48, 40)),
                onPressed: () async {
                  final text = [
                    'Shopping list',
                    for (final aisle in _aisles(toBuy)) ...[
                      '',
                      aisle.$1,
                      for (final i in aisle.$3) '- ${i['name']}',
                    ],
                  ].join('\n');
                  await Clipboard.setData(ClipboardData(text: text));
                  if (!mounted) return;
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(const SnackBar(
                        content: Text(
                            'List copied. Paste it into a message to share it.')));
                },
                icon: const Icon(Icons.copy_rounded, size: 18),
                label: const Text('Copy the list',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          const SizedBox(height: 16),
          // Add a line.
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _field,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _add(),
                  style: t.bodyLarge.copyWith(fontSize: 16, color: _ink),
                  decoration: InputDecoration(
                    labelText: 'Add something',
                    hintText: 'Milk, bin bags, coffee…',
                    filled: true,
                    fillColor: const Color(0xFFFFFDF7),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: _border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: _border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: _forest, width: 1.5),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 52,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                elevation: 3,
                shadowColor: const Color(0x99033C29),
                backgroundColor: _forest,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: _adding ? null : () => _add(),
              icon: const Icon(Icons.add, size: 20),
              label: Text('Add to the list',
                  style: t.bodyLarge.copyWith(
                      color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ),
          if (_again.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text('Buy again?',
                style: t.titleLarge.copyWith(
                    fontSize: 20, fontWeight: FontWeight.w800, color: _ink)),
            const SizedBox(height: 4),
            Text('Used up or thrown out lately. Tap to add.',
                style: t.bodyMedium.copyWith(color: _muted, fontSize: 14)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final name in _again)
                  Semantics(
                    button: true,
                    label: 'Add $name to the list',
                    child: InkWell(
                      borderRadius: BorderRadius.circular(999),
                      onTap: _adding ? null : () => _add(name),
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 44),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: _sage,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.add, size: 16, color: _forest),
                            const SizedBox(width: 4),
                            Text(name,
                                style: t.bodyMedium.copyWith(
                                    color: _forest,
                                    fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 24),
          if (_loading)
            Column(children: [
              for (var i = 0; i < 3; i++) ...[
                Container(
                  height: 56,
                  decoration: BoxDecoration(
                      color: _sage, borderRadius: BorderRadius.circular(14)),
                ),
                const SizedBox(height: 8),
              ],
            ])
          else if (_offline)
            _note(t, Icons.cloud_off_outlined, 'Can’t reach your list.',
                'No signal, or the connection dropped. It will show again when you are back online.')
          else if (_items.isEmpty)
            _note(t, Icons.shopping_basket_outlined, 'Nothing to buy yet.',
                'Add what you have run out of, and it will be here when you are at the shops.')
          else ...[
            if (toBuy.isNotEmpty)
              for (final aisle in _aisles(toBuy)) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
                  child: Row(children: [
                    Icon(aisle.$2, size: 18, color: _forest),
                    const SizedBox(width: 8),
                    Text(aisle.$1,
                        style: t.titleMedium.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: _forest)),
                    const SizedBox(width: 6),
                    Text('${aisle.$3.length}',
                        style: t.bodySmall.copyWith(color: _muted)),
                  ]),
                ),
                _group(t, aisle.$3),
              ],
            if (inBasket.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text('In the basket',
                  style: t.titleMedium.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: _muted)),
              const SizedBox(height: 8),
              _group(t, inBasket),
            ],
            const SizedBox(height: 20),
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
                onPressed: _basketBusy ? null : _basket,
                icon: const Icon(Icons.kitchen_outlined, size: 20),
                label: Text('Put the basket in my kitchen',
                    style: t.bodyLarge
                        .copyWith(color: _forest, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ---- aisles (build 17) ------------------------------------------------------
  // In shop order; an item goes in the first aisle whose words it contains.
  static const _aisleOrder = <(String, IconData, List<String>)>[
    ('Frozen', Icons.ac_unit, ['frozen', 'ice cream', 'gelato', 'ice block', 'icy pole']),
    ('Fruit & veg', Icons.eco_outlined, ['apple', 'banana', 'orange', 'lemon', 'lime', 'berr', 'strawberr', 'blueberr', 'raspberr', 'grape', 'pear', 'peach', 'plum', 'mango', 'melon', 'kiwi', 'avocado', 'lettuce', 'spinach', 'kale', 'rocket', 'salad', 'tomato', 'cucumber', 'capsicum', 'carrot', 'onion', 'garlic', 'potato', 'pumpkin', 'broccoli', 'cauliflower', 'cabbage', 'zucchini', 'eggplant', 'mushroom', 'celery', 'corn', 'herb', 'basil', 'coriander', 'parsley', 'mint', 'ginger', 'chilli', 'fruit', 'veg']),
    ('Meat & fish', Icons.set_meal_outlined, ['beef', 'steak', 'mince', 'chicken', 'pork', 'lamb', 'sausage', 'bacon', 'ham ', 'salami', 'turkey', 'fish', 'salmon', 'prawn', 'seafood', 'meat']),
    ('Dairy & eggs', Icons.egg_outlined, ['milk', 'cheese', 'yoghurt', 'yogurt', 'butter', 'cream', 'egg ', 'eggs']),
    ('Bakery', Icons.bakery_dining_outlined, ['bread', 'loaf', 'roll', 'bun', 'wrap', 'tortilla', 'pita', 'bagel', 'croissant', 'muffin', 'crumpet']),
    ('Pantry', Icons.kitchen_outlined, ['rice', 'pasta', 'noodle', 'flour', 'sugar', 'oil', 'vinegar', 'sauce', 'tin', 'can ', 'canned', 'beans', 'lentil', 'chickpea', 'oats', 'cereal', 'honey', 'jam', 'peanut butter', 'spice', 'salt', 'pepper', 'stock', 'coffee', 'tea ', 'tea', 'nuts', 'baking']),
    ('Drinks & snacks', Icons.local_cafe_outlined, ['juice', 'water', 'soda', 'cola', 'lemonade', 'drink', 'wine', 'beer', 'chips', 'crisps', 'chocolate', 'biscuit', 'cookie', 'snack', 'lollies']),
  ];

  List<(String, IconData, List<Map<String, dynamic>>)> _aisles(
      List<Map<String, dynamic>> items) {
    final byAisle = <String, List<Map<String, dynamic>>>{};
    for (final i in items) {
      final text = ' ${'${i['name'] ?? ''}'.toLowerCase()} ';
      var aisle = 'Other';
      for (final a in _aisleOrder) {
        if (a.$3.any((w) => text.contains(' $w'))) {
          aisle = a.$1;
          break;
        }
      }
      byAisle.putIfAbsent(aisle, () => []).add(i);
    }
    // Shown in walking order: frozen near the end, whatever order they are checked in.
    const shopOrder = ['Fruit & veg', 'Meat & fish', 'Dairy & eggs', 'Bakery', 'Pantry', 'Frozen', 'Drinks & snacks'];
    return [
      for (final name in shopOrder)
        for (final a in _aisleOrder)
          if (a.$1 == name && byAisle[name] != null) (name, a.$2, byAisle[name]!),
      if (byAisle['Other'] != null)
        ('Other', Icons.shopping_basket_outlined, byAisle['Other']!),
    ];
  }

  Widget _group(FlutterFlowTheme t, List<Map<String, dynamic>> items) {
    return Container(
      decoration: _uCard(20),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0)
              const Divider(
                  height: 1, thickness: 1, indent: 56, color: _border),
            _line(t, items[i]),
          ],
        ],
      ),
    );
  }

  Widget _line(FlutterFlowTheme t, Map<String, dynamic> item) {
    final done = item['is_purchased'] == true;
    final name = (item['name'] ?? '').toString();
    return Semantics(
      checked: done,
      label: name,
      child: InkWell(
        onTap: () => _tick(item),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 4, 4, 4),
            child: Row(
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 150),
                  child: Icon(
                    done ? Icons.check_circle : Icons.radio_button_unchecked,
                    key: ValueKey(done),
                    color: done ? _forest : _muted,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(name,
                      style: t.bodyLarge.copyWith(
                        fontSize: 16,
                        color: done ? _muted : _ink,
                        fontWeight: done ? FontWeight.w400 : FontWeight.w600,
                        decoration: done ? TextDecoration.lineThrough : null,
                      )),
                ),
                IconButton(
                  tooltip: 'Remove $name',
                  constraints:
                      const BoxConstraints(minWidth: 48, minHeight: 48),
                  onPressed: () => _remove(item),
                  icon: const Icon(Icons.close, color: _muted, size: 20),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _note(FlutterFlowTheme t, IconData icon, String title, String text) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _uCard(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: _sage, borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: _forest),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: t.titleMedium.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: _ink)),
                const SizedBox(height: 4),
                Text(text,
                    style: t.bodyMedium.copyWith(color: _muted, fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
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

/// Amounts in the person's units (My details → Units). Food is stored in
/// metric; imperial changes only what is shown.
String _uAmount(double? qty, String? unit) {
  if (FFAppState().unitSystem == 'imperial' && qty != null) {
    final u = (unit ?? '').trim().toLowerCase();
    double? v;
    var to = '';
    switch (u) {
      case 'g':
        v = qty / 28.3495;
        to = 'oz';
        if (v >= 16) {
          v = v / 16;
          to = 'lb';
        }
        break;
      case 'kg':
        v = qty * 2.20462;
        to = 'lb';
        break;
      case 'ml':
        v = qty / 29.5735;
        to = 'fl oz';
        break;
      case 'l':
        v = qty * 33.814;
        to = 'fl oz';
        break;
    }
    if (v != null) {
      final r = v < 10 ? (v * 10).round() / 10 : v.roundToDouble();
      final s = r == r.roundToDouble() ? r.round().toString() : r.toStringAsFixed(1);
      return '$s $to';
    }
  }
  return quantityLabel(qty, unit) ?? '';
}

/// The app's copy of the person's name, photo and units.
void _uRemember(String name, String photo, String units) {
  final a = FFAppState();
  if (a.profileName == name && a.profileAvatar == photo && a.unitSystem == units) {
    return;
  }
  a.update(() {
    a.profileName = name;
    a.profileAvatar = photo;
    a.unitSystem = units;
  });
}

/// Refreshes that copy, and the plan, from the profile (quietly; offline
/// keeps the old one). Before migration 10 there is no plan column: the plan
/// is 'open' and nothing is locked.
Future<void> _uLoadProfile() async {
  final uid = SupaFlow.client.auth.currentUser?.id;
  if (uid == null) return;
  Map<String, dynamic>? row;
  var plan = 'open';
  try {
    row = await SupaFlow.client
        .from('profiles')
        .select('display_name, avatar_url, unit_system, plan, plan_expires_at')
        .eq('id', uid)
        .maybeSingle();
    if (row != null) {
      final ends = DateTime.tryParse('${row['plan_expires_at'] ?? ''}');
      plan = row['plan'] == 'plus' && (ends == null || ends.isAfter(DateTime.now()))
          ? 'plus'
          : 'free';
    }
  } catch (e) {
    // 42703: the plan column is not there yet (migration 10 not run).
    if (!'$e'.contains('42703')) return;
    try {
      row = await SupaFlow.client
          .from('profiles')
          .select('display_name, avatar_url, unit_system')
          .eq('id', uid)
          .maybeSingle();
    } catch (_) {
      return;
    }
  }
  if (row == null) return;
  if (plan == 'free') {
    // Plus is shared across the household.
    final household = FFAppState().currentHouseholdId;
    if (household.isNotEmpty) {
      try {
        final members = await SupaFlow.client
            .from('household_members')
            .select('profile_id')
            .eq('household_id', household);
        final ids = [
          for (final m in members as List)
            if ('${m['profile_id']}' != uid) '${m['profile_id']}'
        ];
        if (ids.isNotEmpty) {
          final plans = await SupaFlow.client
              .from('profiles')
              .select('plan, plan_expires_at')
              .inFilter('id', ids);
          for (final p in plans as List) {
            final ends = DateTime.tryParse('${p['plan_expires_at'] ?? ''}');
            if (p['plan'] == 'plus' &&
                (ends == null || ends.isAfter(DateTime.now()))) {
              plan = 'household';
              break;
            }
          }
        }
      } catch (_) {}
    }
  }
  _uRemember('${row['display_name'] ?? ''}', '${row['avatar_url'] ?? ''}',
      row['unit_system'] == 'imperial' ? 'imperial' : 'metric');
  final a = FFAppState();
  if (a.plan != plan || (plan == 'free' && a.ideasGoals)) {
    a.update(() {
      a.plan = plan;
      // Fits my goals is Plus: a free account never keeps it switched on.
      if (plan == 'free') a.ideasGoals = false;
    });
  }
}

/// Plans (owner, 15 Sep): free or Plus, shared by the household - when anyone
/// in your household has Plus, everyone in it does. FFAppState().plan is
/// 'plus' (your own), 'household' (through a housemate), 'free', or 'open'
/// (no plan column yet - migration 10 not run - so nothing is locked).
bool _uPlus() => FFAppState().plan != 'free';

const _uPlusPerks = <(IconData, String)>[
  (Icons.calendar_month_outlined, 'Plan my week, with leftovers and «I ate this»'),
  (Icons.track_changes, 'Meals that fit your goals: calories and protein'),
  (Icons.document_scanner_outlined, 'Scan a whole shelf or a receipt at once'),
  (Icons.receipt_long_outlined, 'Receipts, prices and a weekly budget'),
  (Icons.menu_book_outlined, 'Your own recipe collection'),
  (Icons.groups_outlined, 'Meals for the whole household'),
];

/// A small «PLUS» tag for things that need Plus.
Widget _uPlusBadge() => Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFFE9B949), Color(0xFFC98A1B)]),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Text('PLUS',
          style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6)),
    );

Widget _uPlusStory(BuildContext context, String feature) {
  final t = FlutterFlowTheme.of(context);
  return Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(children: [
        Container(
          width: 48,
          height: 48,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [_uForestTop, _uForest]),
          ),
          child: const Icon(Icons.lock_outline, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 12),
        _uPlusBadge(),
      ]),
      const SizedBox(height: 14),
      Text('$feature is part of Use It Fresh Plus',
          style: t.headlineSmall.copyWith(
              fontSize: 22, fontWeight: FontWeight.w800, color: _uInk, height: 1.2)),
      const SizedBox(height: 6),
      Text('Your account is on the free plan. Plus adds:',
          style: t.bodyMedium.copyWith(color: _uMuted, fontSize: 15)),
      const SizedBox(height: 12),
      for (final p in _uPlusPerks)
        Padding(
          padding: const EdgeInsets.only(bottom: 9),
          child: Row(children: [
            Icon(p.$1, size: 20, color: _uForest),
            const SizedBox(width: 10),
            Expanded(
                child: Text(p.$2.replaceAll('«', '“').replaceAll('»', '”'),
                    style: t.bodyMedium.copyWith(color: _uInk, fontSize: 15))),
          ]),
        ),
      const SizedBox(height: 6),
      Text(
          'Free always includes your kitchen, date reminders, allergy exclusions, meal ideas, barcodes and single-food photos.',
          style: t.bodySmall.copyWith(color: _uMuted, fontSize: 13)),
      const SizedBox(height: 4),
      Text('Plus isn’t on sale yet.',
          style: t.bodySmall.copyWith(
              color: _uMuted, fontSize: 13, fontWeight: FontWeight.w700)),
    ],
  );
}

/// The lock as a sheet, for a Plus button on a free screen.
Future<void> _uPlusSheet(BuildContext context, String feature) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _uCream,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheet) => SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _uPlusStory(sheet, feature),
              const SizedBox(height: 18),
              _UButton('OK', onTap: () => Navigator.of(sheet).pop()),
            ],
          ),
        ),
      ),
    );

/// The lock as a whole screen, for a Plus page opened on a free account.
Widget _uPlusLock(BuildContext context, String feature) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Align(
        alignment: Alignment.centerLeft,
        child: _uBack(context, () {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        }),
      ),
      const SizedBox(height: 18),
      _USurface(
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
        child: _uPlusStory(context, feature),
      ),
    ],
  );
}


/// Freeze it (build 17): moves a food into the household's freezer, notes
/// when, and records a "frozen" event; Undo puts it back where it was.
/// Returns true when it was frozen.
Future<bool> _uFreeze(BuildContext context, String id, String name) async {
  final messenger = ScaffoldMessenger.of(context);
  void say(String text, [SnackBarAction? action]) => messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text), action: action));
  final household = FFAppState().currentHouseholdId;
  if (household.isEmpty || id.isEmpty) return false;
  try {
    final freezers = await SupaFlow.client
        .from('storage_locations')
        .select('id, name')
        .eq('household_id', household)
        .eq('location_type', 'freezer')
        .limit(1);
    if ((freezers as List).isEmpty) {
      say('Add a freezer in Profile → Storage first.');
      return false;
    }
    final freezer = freezers.first as Map;
    final before = await SupaFlow.client
        .from('food_items')
        .select('storage_location_id, frozen_at')
        .eq('id', id)
        .maybeSingle();
    final from = before?['storage_location_id'];
    await SupaFlow.client.from('food_items').update({
      'storage_location_id': freezer['id'],
      'frozen_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', id);
    try {
      await SupaFlow.client.from('food_item_events').insert({
        'food_item_id': id,
        'profile_id': SupaFlow.client.auth.currentUser?.id,
        'event_type': 'frozen',
        'from_value': {'storage_location_id': from},
        'to_value': {'storage_location_id': freezer['id']},
      });
    } catch (_) {}
    say(
        '$name is in the ${freezer['name']}. It keeps for months there.',
        SnackBarAction(
            label: 'Undo',
            onPressed: () async {
              try {
                await SupaFlow.client.from('food_items').update({
                  'storage_location_id': from,
                  'frozen_at': before?['frozen_at'],
                }).eq('id', id);
              } catch (_) {}
            }));
    return true;
  } catch (_) {
    say('Could not move it. Check your signal and try again.');
    return false;
  }
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
  final amount = _uAmount(qty, '${item['unit'] ?? ''}') ?? '';
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

