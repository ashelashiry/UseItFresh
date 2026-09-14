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

/// Big thing 3, step 2 of 2: the live shopping list.
///
/// ShoppingListLive does what the page did — add, tick into the basket,
/// remove, put the basket in the kitchen, with the same words — and adds:
///
///  * live: a change anyone in the household makes shows at once (Supabase
///    realtime on shopping_list_items, already in the publication);
///  * Buy again?: foods used up or thrown out in the last three weeks and not
///    already on the list, one tap each.
void buildStarterEditFlow(App app) {
  app.customWidget(
    'ShoppingListLive',
    parameters: {},
    description:
        'The household shopping list, live for everyone: add, tick, remove, '
        'put the basket in the kitchen, and buy again what ran out.',
    code: _shoppingListLive,
  );

  final shop = ff.Pages.shoppingListPage;
  app.editPage(shop, (page) {
    page.ensureInsertedAfter(
      shop.widgets.byKey('Text_ez7qs242').single, // "Shopping list."
      CustomWidget(widgetName: 'ShoppingListLive', name: 'ShoppingLive', arguments: {}),
    );
  });
}

const _shoppingListLive = r'''
import 'package:flutter/material.dart';
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
        final since =
            DateTime.now().toUtc().subtract(const Duration(days: 21)).toIso8601String();
        final gone = await SupaFlow.client
            .from('food_items')
            .select('name, archived_at')
            .eq('household_id', household)
            .inFilter('status', ['consumed', 'discarded'])
            .gte('archived_at', since)
            .order('archived_at', ascending: false)
            .limit(60);
        final onList = items.map((i) => (i['name'] ?? '').toString().trim().toLowerCase()).toSet();
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
        setState(() => _items = _items.where((i) => i['id'].toString() != id).toList());
      }
    } catch (_) {
      if (mounted) _say('Could not remove it. Check your signal and try again.');
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
                  ? (inBasket.isEmpty ? 'Nothing on it yet' : 'Everything is in the basket')
                  : '${toBuy.length} to buy${inBasket.isEmpty ? '' : ' · ${inBasket.length} in the basket'}',
              style: t.bodyLarge.copyWith(color: _muted, fontSize: 16),
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
                    fillColor: Colors.white,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
                backgroundColor: _forest,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _adding ? null : () => _add(),
              icon: const Icon(Icons.add, size: 20),
              label: Text('Add to the list',
                  style: t.bodyLarge.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
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
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                                    color: _forest, fontWeight: FontWeight.w700)),
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
            if (toBuy.isNotEmpty) _group(t, toBuy),
            if (inBasket.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text('In the basket',
                  style: t.titleMedium.copyWith(
                      fontSize: 16, fontWeight: FontWeight.w800, color: _muted)),
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _basketBusy ? null : _basket,
                icon: const Icon(Icons.kitchen_outlined, size: 20),
                label: Text('Put the basket in my kitchen',
                    style: t.bodyLarge.copyWith(color: _forest, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _group(FlutterFlowTheme t, List<Map<String, dynamic>> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const Divider(height: 1, thickness: 1, indent: 56, color: _border),
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
                  constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: _sage, borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: _forest),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: t.titleMedium.copyWith(
                        fontSize: 18, fontWeight: FontWeight.w800, color: _ink)),
                const SizedBox(height: 4),
                Text(text, style: t.bodyMedium.copyWith(color: _muted, fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
''';
