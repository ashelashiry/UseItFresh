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

/// Paid feature: Recipe collection (owner, 14 Sep: "save favourite recipes
/// and connect their ingredients to inventory and shopping").
///
/// RecipeCollectionPage: kept ideas and your own recipes; how many
/// ingredients are in the kitchen now; favourites, your own, can cook now;
/// missing ingredients to the shopping list; notes; add to the week; type in,
/// edit and delete your own. Recipes gets a "Your recipes" link and "See all"
/// next to Kept ideas. Needs migration 8 for own recipes, favourites and notes.
void buildStarterEditFlow(App app) {
  app.customWidget(
    'RecipeCollection',
    parameters: {},
    description:
        'Your recipes: kept ideas and your own, with what is in the kitchen, '
        'favourites, missing things to the list, and add to the week.',
    code: _recipeCollection,
  );
  app.raw((project) {
    updateCustomWidget(project, name: 'RecipesHome', code: _recipesHome);
  });
  app.ensurePage(
    'RecipeCollectionPage',
    route: '/recipes/collection',
    description: 'Your recipes: kept ideas and your own.',
    body: Scaffold(
      body: CustomWidget(
        widgetName: 'RecipeCollection',
        name: 'RecipeCollectionView',
        arguments: {},
      ),
    ),
  );
}

const _recipeCollection = r'''
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Recipe collection (owner, 14 Sep; a Plus feature): "save favourite recipes
/// and connect their ingredients to inventory and shopping".
///
/// Kept ideas and the household's own recipes in one place. Each says how
/// many of its ingredients are in the kitchen now; "Can cook now" shows only
/// the ones with everything. A recipe opens to its ingredients (in the kitchen
/// or not), one tap for the missing ones onto the shopping list, its steps,
/// notes, a favourite star, and "Add to my week". Your own recipes can be
/// typed in, edited and deleted.
class RecipeCollection extends StatefulWidget {
  const RecipeCollection({super.key, this.width, this.height});

  final double? width;
  final double? height;

  @override
  State<RecipeCollection> createState() => _RecipeCollectionState();
}

class _RecipeCollectionState extends State<RecipeCollection> {
  static const _forest = Color(0xFF07533A);
  static const _ink = Color(0xFF202C24);
  static const _muted = Color(0xFF59665D);
  static const _sage = Color(0xFFEDF2E8);
  static const _border = Color(0xFFDCE3D7);
  static const _cream = Color(0xFFF7F7F0);
  static const _red = Color(0xFFB42318);
  static const _gold = Color(0xFFB54708);

  static const _filters = <String, String>{
    'all': 'All',
    'favourites': 'Favourites',
    'own': 'Your own',
    'ready': 'Can cook now',
  };
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
  String _filter = 'all';
  List<Map> _recipes = const [];
  List<String> _kitchen = const [];
  final Set<String> _listed = {};

  Future<void> _load(String household, {bool quiet = false}) async {
    if (!quiet && mounted) {
      setState(() {
        _loading = true;
        _offline = false;
      });
    }
    try {
      List rows;
      try {
        rows = await SupaFlow.client
            .from('saved_recipes')
            .select(
                'id, title, recipe_data, source, servings, is_favourite, notes, created_at')
            .eq('household_id', household)
            .order('created_at', ascending: false)
            .limit(200);
      } on PostgrestException {
        // Before migration 8: the collection still shows kept ideas.
        rows = await SupaFlow.client
            .from('saved_recipes')
            .select('id, title, recipe_data, created_at')
            .eq('household_id', household)
            .order('created_at', ascending: false)
            .limit(200);
      }
      final foods = await SupaFlow.client
          .from('food_items_status')
          .select('name, computed_status')
          .eq('household_id', household)
          .limit(300);
      if (!mounted || household != _for) return;
      setState(() {
        _recipes = [for (final r in rows) r as Map];
        _kitchen = [
          for (final f in foods as List)
            if (!const ['consumed', 'discarded', 'past_use_by']
                .contains('${(f as Map)['computed_status']}'))
              '${f['name'] ?? ''}'.trim().toLowerCase()
        ];
        _loading = false;
        _offline = false;
      });
    } catch (_) {
      if (!mounted) return;
      if (quiet && _recipes.isNotEmpty) return;
      setState(() {
        _loading = false;
        _offline = true;
      });
    }
  }

  static List<String> _words(Object? v) => v is List
      ? [
          for (final x in v)
            if ('$x'.trim().isNotEmpty) '$x'.trim()
        ]
      : <String>[];

  static String _stem(String w) {
    final s = w.trim().toLowerCase();
    if (s.length > 4 && s.endsWith('es')) return s.substring(0, s.length - 2);
    if (s.length > 3 && s.endsWith('s')) return s.substring(0, s.length - 1);
    return s;
  }

  static Map _data(Map r) =>
      r['recipe_data'] is Map ? r['recipe_data'] as Map : const {};

  /// Every ingredient: for an idea, what it used and what it needed.
  static List<String> _ingredients(Map r) {
    final d = _data(r);
    final own = _words(d['ingredients']);
    if (own.isNotEmpty) return own;
    return [..._words(d['uses']), ..._words(d['extras'])];
  }

  bool _inKitchen(String ingredient) {
    final i = ingredient.toLowerCase();
    final si = _stem(i);
    for (final k in _kitchen) {
      if (k.isEmpty) continue;
      final sk = _stem(k);
      if (k == i || (sk.length > 2 && i.contains(sk)) || (si.length > 2 && k.contains(si))) {
        return true;
      }
    }
    return false;
  }

  (int, int) _have(Map r) {
    final all = _ingredients(r);
    return (all.where(_inKitchen).length, all.length);
  }

  List<Map> get _shown {
    final list = _recipes.where((r) {
      switch (_filter) {
        case 'favourites':
          return r['is_favourite'] == true;
        case 'own':
          return r['source'] == 'own';
        case 'ready':
          final (have, all) = _have(r);
          return all > 0 && have == all;
      }
      return true;
    }).toList();
    list.sort((a, b) {
      final fa = a['is_favourite'] == true ? 0 : 1;
      final fb = b['is_favourite'] == true ? 0 : 1;
      if (fa != fb) return fa - fb;
      final (ha, aa) = _have(a);
      final (hb, ab) = _have(b);
      final ra = aa == 0 ? 0.0 : ha / aa;
      final rb = ab == 0 ? 0.0 : hb / ab;
      return rb.compareTo(ra);
    });
    return list;
  }

  void _say(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  String _why(Object error) {
    if (error is PostgrestException && error.code == '42501') {
      return 'Your account is not allowed to change this household’s recipes.';
    }
    if (error is PostgrestException &&
        (error.code == '42703' || error.code == 'PGRST204')) {
      return 'Your own recipes are almost ready. Try again soon.';
    }
    return 'Could not save that. Check your signal and try again.';
  }

  void _back() {
    final router = GoRouter.of(context);
    if (router.canPop()) {
      router.pop();
    } else {
      router.goNamed('RecipesPage');
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
    final shown = _shown;

    Widget content;
    if (_loading) {
      content = Column(children: [
        for (var i = 0; i < 3; i++) ...[
          Container(
            height: 88,
            decoration: BoxDecoration(
                color: _sage, borderRadius: BorderRadius.circular(20)),
          ),
          const SizedBox(height: 12),
        ],
      ]);
    } else if (_offline) {
      content = _message(t, Icons.cloud_off_outlined, 'Can’t reach your recipes.',
          'No signal, or the connection dropped. Try again when you are back online.');
    } else if (_recipes.isEmpty) {
      content = _message(t, Icons.menu_book_outlined, 'No recipes yet.',
          'Keep ideas you like on Recipes, or add a recipe of your own.');
    } else if (shown.isEmpty) {
      content = _message(t, Icons.filter_alt_off_outlined, 'Nothing here.',
          _filter == 'ready'
              ? 'No recipe has everything in your kitchen right now.'
              : 'Try another filter.');
    } else {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final r in shown) ...[
            _card(t, r),
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
            Text('Your recipes.',
                style: t.headlineMedium.copyWith(
                    fontSize: 32, fontWeight: FontWeight.w800, color: _ink)),
            const SizedBox(height: 4),
            Text('Kept ideas and your own, shared with your household.',
                style: t.bodyLarge.copyWith(color: _muted, fontSize: 16)),
            const SizedBox(height: 16),
            SizedBox(
              height: 52,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: _forest,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () => _edit(t, null),
                icon: const Icon(Icons.add, size: 20),
                label: Text('Add your own recipe',
                    style: t.bodyLarge.copyWith(
                        color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                children: [
                  for (final e in _filters.entries) ...[
                    _choice(t, e.value, _filter == e.key,
                        () => setState(() => _filter = e.key)),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            content,
          ],
        ),
      ),
    );
  }

  Widget _card(FlutterFlowTheme t, Map r) {
    final (have, all) = _have(r);
    final minutes = _data(r)['minutes'] is num
        ? (_data(r)['minutes'] as num).round()
        : 0;
    final fav = r['is_favourite'] == true;
    return Semantics(
      button: true,
      label: '${r['title']}',
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _open(t, r),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 6, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${r['title']}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: t.bodyLarge.copyWith(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: _ink)),
                    const SizedBox(height: 4),
                    Wrap(spacing: 6, runSpacing: 4, children: [
                      if (all > 0)
                        _pill(
                            t,
                            have == all
                                ? 'Everything in your kitchen'
                                : 'You have $have of $all',
                            have == all ? _forest : _muted,
                            have == all ? const Color(0xFFDDF0E2) : _sage),
                      if (minutes > 0) _pill(t, '$minutes min', _muted, _sage),
                      if (r['source'] == 'own') _pill(t, 'Your own', _muted, _sage),
                    ]),
                  ],
                ),
              ),
              IconButton(
                tooltip: fav ? 'Take out of favourites' : 'Add to favourites',
                onPressed: () => _favourite(r),
                icon: Icon(fav ? Icons.star : Icons.star_border,
                    color: fav ? _gold : _muted),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _favourite(Map r) async {
    try {
      await SupaFlow.client
          .from('saved_recipes')
          .update({'is_favourite': r['is_favourite'] != true}).eq(
              'id', '${r['id']}');
      await _load(_for, quiet: true);
    } catch (error) {
      if (mounted) _say(_why(error));
    }
  }

  Future<void> _open(FlutterFlowTheme t, Map r) async {
    final all = _ingredients(r);
    final missing = [
      for (final i in all)
        if (!_inKitchen(i)) i
    ];
    final d = _data(r);
    final steps = _words(d['steps']);
    final notes = TextEditingController(text: '${r['notes'] ?? ''}');
    final action = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _cream,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheet) => StatefulBuilder(
        builder: (sheet, redraw) => Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(sheet).viewInsets.bottom),
          child: ConstrainedBox(
            constraints: BoxConstraints(
                maxHeight: MediaQuery.of(sheet).size.height * 0.9),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('${r['title']}',
                        style: t.headlineSmall.copyWith(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: _ink,
                            height: 1.15)),
                    const SizedBox(height: 16),
                    _label(t, 'Ingredients'),
                    for (final i in all)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Icon(
                                _inKitchen(i)
                                    ? Icons.check_circle
                                    : Icons.radio_button_unchecked,
                                color: _inKitchen(i) ? _forest : _muted,
                                size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(i,
                                  style: t.bodyLarge
                                      .copyWith(fontSize: 16, color: _ink)),
                            ),
                            Text(_inKitchen(i) ? 'In your kitchen' : '',
                                style: t.bodySmall
                                    .copyWith(color: _muted, fontSize: 12)),
                          ],
                        ),
                      ),
                    if (missing.isNotEmpty)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          style: TextButton.styleFrom(
                              minimumSize: const Size(48, 48),
                              foregroundColor: _forest),
                          onPressed: _listed.contains('${r['id']}')
                              ? null
                              : () async {
                                  for (final m in missing) {
                                    final said = await addNameToShoppingList(m);
                                    if (said.isNotEmpty) {
                                      if (mounted) _say(said);
                                      return;
                                    }
                                  }
                                  _listed.add('${r['id']}');
                                  try {
                                    redraw(() {});
                                  } catch (_) {}
                                  if (mounted) {
                                    _say(missing.length == 1
                                        ? '1 thing added to your shopping list.'
                                        : '${missing.length} things added to your shopping list.');
                                  }
                                },
                          icon: Icon(
                              _listed.contains('${r['id']}')
                                  ? Icons.check
                                  : Icons.add_shopping_cart,
                              size: 18),
                          label: Text(
                              _listed.contains('${r['id']}')
                                  ? 'On your shopping list'
                                  : 'Add ${missing.length} missing to the shopping list',
                              style: t.bodyLarge.copyWith(
                                  color: _listed.contains('${r['id']}')
                                      ? _muted
                                      : _forest,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ),
                    if (steps.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _label(t, 'Steps'),
                      for (var i = 0; i < steps.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text('${i + 1}. ${steps[i]}',
                              style: t.bodyLarge.copyWith(
                                  fontSize: 16, color: _ink, height: 1.4)),
                        ),
                    ],
                    if (r.containsKey('notes')) ...[
                      const SizedBox(height: 12),
                      _label(t, 'Notes'),
                      TextField(
                        controller: notes,
                        maxLines: 3,
                        minLines: 1,
                        decoration: InputDecoration(
                          hintText: 'e.g. Kids like it with extra cheese',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: _border),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 52,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: _forest,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () => Navigator.of(sheet).pop('week'),
                        icon: const Icon(Icons.calendar_month_outlined,
                            size: 20),
                        label: Text('Add to my week',
                            style: t.bodyLarge.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700)),
                      ),
                    ),
                    if (r['source'] == 'own')
                      TextButton.icon(
                        style: TextButton.styleFrom(
                            minimumSize: const Size(48, 48),
                            foregroundColor: _forest),
                        onPressed: () => Navigator.of(sheet).pop('edit'),
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: Text('Edit this recipe',
                            style: t.bodyLarge.copyWith(
                                color: _forest, fontWeight: FontWeight.w700)),
                      ),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                          minimumSize: const Size(48, 48),
                          foregroundColor: _red),
                      onPressed: () => Navigator.of(sheet).pop('delete'),
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: Text(
                          r['source'] == 'own'
                              ? 'Delete this recipe'
                              : 'Remove from your recipes',
                          style: t.bodyLarge.copyWith(
                              color: _red, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    final note = notes.text.trim();
    notes.dispose();
    if (!mounted) return;
    if (r.containsKey('notes') && note != '${r['notes'] ?? ''}'.trim()) {
      try {
        await SupaFlow.client
            .from('saved_recipes')
            .update({'notes': note.isEmpty ? null : note}).eq('id', '${r['id']}');
        await _load(_for, quiet: true);
      } catch (error) {
        if (mounted) _say(_why(error));
      }
    }
    if (!mounted) return;
    switch (action) {
      case 'week':
        await _toWeek(t, r);
        break;
      case 'edit':
        await _edit(t, r);
        break;
      case 'delete':
        final sure = await showDialog<bool>(
          context: context,
          builder: (dlg) => AlertDialog(
            title: Text(r['source'] == 'own'
                ? 'Delete this recipe?'
                : 'Remove this recipe?'),
            content: const Text(
                'It goes for everyone in your household. Meals already planned keep their steps.'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(dlg).pop(false),
                  child: const Text('Keep it')),
              TextButton(
                  onPressed: () => Navigator.of(dlg).pop(true),
                  child: const Text('Delete', style: TextStyle(color: _red))),
            ],
          ),
        );
        if (sure != true) return;
        try {
          await SupaFlow.client
              .from('saved_recipes')
              .delete()
              .eq('id', '${r['id']}');
          await _load(_for, quiet: true);
          if (mounted) _say('Removed from your recipes.');
        } catch (error) {
          if (mounted) _say(_why(error));
        }
    }
  }

  Future<void> _toWeek(FlutterFlowTheme t, Map r) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    String name(int i) {
      if (i == 0) return 'Today';
      if (i == 1) return 'Tomorrow';
      final d = today.add(Duration(days: i));
      return '${_days[d.weekday - 1]} ${d.day} ${_months[d.month - 1]}';
    }

    var day = 0;
    var meal = 'dinner';
    final go = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: _cream,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheet) => StatefulBuilder(
        builder: (sheet, redraw) => SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Add to my week',
                    style: t.headlineSmall.copyWith(
                        fontSize: 24, fontWeight: FontWeight.w800, color: _ink)),
                const SizedBox(height: 16),
                _label(t, 'Day'),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (var i = 0; i < 7; i++)
                    _choice(t, name(i), day == i, () => redraw(() => day = i)),
                ]),
                const SizedBox(height: 16),
                _label(t, 'Meal'),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final m in const ['breakfast', 'lunch', 'dinner', 'snack'])
                    _choice(t, m[0].toUpperCase() + m.substring(1), meal == m,
                        () => redraw(() => meal = m)),
                ]),
                const SizedBox(height: 20),
                SizedBox(
                  height: 52,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: _forest,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () => Navigator.of(sheet).pop(true),
                    child: Text('Add',
                        style: t.bodyLarge.copyWith(
                            color: Colors.white, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (go != true || !mounted) return;
    final d = today.add(Duration(days: day));
    final all = _ingredients(r);
    final data = _data(r);
    try {
      await SupaFlow.client.from('meal_plan_entries').insert({
        'household_id': _for,
        'plan_date':
            '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}',
        'meal': meal,
        'title': '${r['title']}',
        // What is in the kitchen now, and what the week's shopping needs.
        'recipe_data': {
          'uses': [
            for (final i in all)
              if (_inKitchen(i)) i
          ],
          'extras': [
            for (final i in all)
              if (!_inKitchen(i)) i
          ],
          'steps': _words(data['steps']),
          'minutes': data['minutes'] is num ? data['minutes'] : 0,
          if (data['calories'] is num) 'calories': data['calories'],
          if (data['protein'] is num) 'protein': data['protein'],
        },
        'servings': r['servings'] is num
            ? r['servings']
            : (data['servings'] is num && (data['servings'] as num) > 0
                ? data['servings']
                : 2),
        'created_by': SupaFlow.client.auth.currentUser?.id,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            'Planned for ${day < 2 ? name(day).toLowerCase() : name(day)}.'),
        action: SnackBarAction(
          label: 'See the week',
          textColor: const Color(0xFFB9E08F),
          onPressed: () => context.pushNamed('PlanWeekPage'),
        ),
      ));
    } catch (error) {
      if (mounted) _say(_why(error));
    }
  }

  /// Add (r == null) or edit one of your own recipes.
  Future<void> _edit(FlutterFlowTheme t, Map? r) async {
    final d = r == null ? const {} : _data(r);
    final title = TextEditingController(text: r == null ? '' : '${r['title']}');
    final ingredients =
        TextEditingController(text: _words(d['ingredients']).join('\n'));
    final steps = TextEditingController(text: _words(d['steps']).join('\n'));
    var servings = r?['servings'] is num ? (r!['servings'] as num).round() : 2;
    var minutes = d['minutes'] is num ? (d['minutes'] as num).round() : 30;
    InputDecoration look(String label, String hint) => InputDecoration(
          labelText: label,
          hintText: hint,
          alignLabelWithHint: true,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _border),
          ),
        );
    final save = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _cream,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheet) => StatefulBuilder(
        builder: (sheet, redraw) => Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(sheet).viewInsets.bottom),
          child: ConstrainedBox(
            constraints: BoxConstraints(
                maxHeight: MediaQuery.of(sheet).size.height * 0.92),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(r == null ? 'Your own recipe' : 'Edit recipe',
                        style: t.headlineSmall.copyWith(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: _ink)),
                    const SizedBox(height: 16),
                    TextField(
                        controller: title,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: look('Name', 'e.g. Nan’s lentil soup')),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _label(t, 'Serves')),
                        _stepper(Icons.remove, servings > 1,
                            () => redraw(() => servings--)),
                        SizedBox(
                            width: 40,
                            child: Text('$servings',
                                textAlign: TextAlign.center,
                                style: t.titleMedium.copyWith(color: _ink))),
                        _stepper(Icons.add, servings < 12,
                            () => redraw(() => servings++)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: _label(t, 'Minutes')),
                        _stepper(Icons.remove, minutes > 5,
                            () => redraw(() => minutes -= 5)),
                        SizedBox(
                            width: 40,
                            child: Text('$minutes',
                                textAlign: TextAlign.center,
                                style: t.titleMedium.copyWith(color: _ink))),
                        _stepper(Icons.add, minutes < 240,
                            () => redraw(() => minutes += 5)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                        controller: ingredients,
                        minLines: 4,
                        maxLines: 10,
                        decoration: look('Ingredients, one per line',
                            'Red lentils\nOnion\nCarrots')),
                    const SizedBox(height: 12),
                    TextField(
                        controller: steps,
                        minLines: 4,
                        maxLines: 12,
                        decoration: look('Steps, one per line',
                            'Soften the onion\nAdd lentils and water')),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 52,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: _forest,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () {
                          if (title.text.trim().isEmpty) return;
                          Navigator.of(sheet).pop(true);
                        },
                        child: Text('Save recipe',
                            style: t.bodyLarge.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    List<String> lines(TextEditingController c) => [
          for (final l in c.text.split('\n'))
            if (l.trim().isNotEmpty) l.trim()
        ];
    final row = {
      'title': title.text.trim(),
      'source': 'own',
      'servings': servings,
      'recipe_data': {
        'ingredients': lines(ingredients),
        'steps': lines(steps),
        'minutes': minutes,
        'servings': servings,
      },
    };
    title.dispose();
    ingredients.dispose();
    steps.dispose();
    if (save != true || !mounted) return;
    try {
      if (r == null) {
        await SupaFlow.client.from('saved_recipes').insert({
          ...row,
          'household_id': _for,
          'profile_id': SupaFlow.client.auth.currentUser?.id,
        });
      } else {
        await SupaFlow.client
            .from('saved_recipes')
            .update(row)
            .eq('id', '${r['id']}');
      }
      await _load(_for, quiet: true);
      if (mounted) _say(r == null ? 'Recipe saved.' : 'Recipe updated.');
    } catch (error) {
      if (mounted) _say(_why(error));
    }
  }

  Widget _pill(FlutterFlowTheme t, String text, Color fg, Color bg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
        decoration: BoxDecoration(
            color: bg, borderRadius: BorderRadius.circular(999)),
        child: Text(text,
            style: t.bodySmall.copyWith(
                color: fg, fontWeight: FontWeight.w700, fontSize: 12)),
      );

  Widget _label(FlutterFlowTheme t, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: t.bodyMedium.copyWith(
                color: _muted, fontWeight: FontWeight.w700, fontSize: 14)),
      );

  Widget _choice(
          FlutterFlowTheme t, String label, bool on, VoidCallback onTap) =>
      Semantics(
        button: true,
        selected: on,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 44),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: on ? _forest : Colors.white,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: on ? _forest : _border),
            ),
            child: Text(label,
                style: t.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: on ? Colors.white : _ink)),
          ),
        ),
      );

  Widget _stepper(IconData icon, bool enabled, VoidCallback onTap) => Opacity(
        opacity: enabled ? 1 : 0.4,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: enabled ? onTap : null,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: _border),
            ),
            child: Icon(icon, color: _forest, size: 20),
          ),
        ),
      );

  Widget _message(FlutterFlowTheme t, IconData icon, String title, String text) {
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
        ],
      ),
    );
  }
}
''';

const _recipesHome = r'''
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Recipes below the title "What looks good?", as design guide v4 lays out.
///
/// Controls first and compact: Quick meals and Use my food toggle real
/// filters; Filters opens the rest in a sheet. Then an invitation, or the
/// ideas as cards that open to their details. Kept ideas last.
///
/// "Fits my goals" (a Plus feature, owner 14 Sep) is optional and off until
/// turned on: calories and protein per serving on each idea, and only ideas
/// in the chosen calorie range or high in protein. The numbers are estimates
/// and always say so.
class RecipesHome extends StatefulWidget {
  const RecipesHome({super.key, this.width, this.height});

  final double? width;
  final double? height;

  @override
  State<RecipesHome> createState() => _RecipesHomeState();
}

class _Kept {
  const _Kept(this.id, this.idea);
  final String id;
  final MealIdeaStruct idea;
}

class _RecipesHomeState extends State<RecipesHome> {
  static const _forest = Color(0xFF07533A);
  static const _leaf = Color(0xFF83BD43);
  static const _ink = Color(0xFF202C24);
  static const _muted = Color(0xFF59665D);
  static const _sage = Color(0xFFEDF2E8);
  static const _border = Color(0xFFDCE3D7);
  static const _cream = Color(0xFFF7F7F0);

  static const _food =
      'https://cdn.jsdelivr.net/gh/ashelashiry/UseItFresh@b50424f12bd372d81c9cd44d895b62c25d1329e7/design/v3/food';

  static const _meals = <String, String>{
    'any': 'Any',
    'breakfast': 'Breakfast',
    'lunch': 'Lunch',
    'dinner': 'Dinner',
    'snack': 'Snack',
  };
  static const _calorieRanges = <String, String>{
    '': 'Any',
    'under400': 'Under 400',
    '400to600': '400–600',
    '600to800': '600–800',
  };
  static const _times = <int, String>{
    0: 'Any',
    15: '15 min',
    30: '30 min',
    60: '1 hour',
  };

  String _for = '';
  bool? _hasFood;
  List<_Kept> _kept = const [];
  final Set<String> _listed = {};
  bool _keeping = false;

  static String _same(String s) => s.trim().toLowerCase();

  // ---- data ----------------------------------------------------------------

  Future<void> _load(String household) async {
    try {
      final any = await SupaFlow.client
          .from('food_items_status')
          .select('id')
          .eq('household_id', household)
          .limit(1);
      final rows = await SupaFlow.client
          .from('saved_recipes')
          .select('id, title, recipe_data')
          .eq('household_id', household)
          .order('created_at', ascending: false)
          .limit(20);
      final kept = <_Kept>[];
      for (final r in rows as List) {
        final m = r as Map;
        final d = m['recipe_data'] is Map ? m['recipe_data'] as Map : const {};
        List<String> words(Object? v) => v is List
            ? [
                for (final w in v)
                  if ('$w'.trim().isNotEmpty) '$w'.trim()
              ]
            : <String>[];
        kept.add(_Kept(
          m['id'].toString(),
          MealIdeaStruct(
            title: (m['title'] ?? '').toString(),
            // Your own recipes list ingredients rather than uses.
            uses: words(d['uses']).isEmpty
                ? words(d['ingredients'])
                : words(d['uses']),
            extras: words(d['extras']),
            steps: words(d['steps']),
            minutes: d['minutes'] is num ? (d['minutes'] as num).round() : 0,
            servings: d['servings'] is num ? (d['servings'] as num).round() : 0,
            calories: d['calories'] is num ? (d['calories'] as num).round() : 0,
            protein: d['protein'] is num ? (d['protein'] as num).round() : 0,
          ),
        ));
      }
      if (!mounted || household != _for) return;
      setState(() {
        _hasFood = (any as List).isNotEmpty;
        _kept = kept;
      });
    } catch (_) {
      // No signal: the invitation still shows; asking will say why not.
    }
  }

  bool _isKept(MealIdeaStruct idea) =>
      _kept.any((k) => _same(k.idea.title) == _same(idea.title));

  Future<void> _ask() async {
    final said = await getMealIdeas();
    if (!mounted) return;
    if (said.isNotEmpty) _say(said);
  }

  void _say(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> _keep(MealIdeaStruct idea) async {
    final household = FFAppState().currentHouseholdId;
    if (household.isEmpty || _keeping || _isKept(idea)) return;
    setState(() => _keeping = true);
    try {
      await SupaFlow.client.from('saved_recipes').insert({
        'household_id': household,
        'profile_id': SupaFlow.client.auth.currentUser?.id,
        'title': idea.title,
        'recipe_data': {
          'uses': idea.uses,
          'extras': idea.extras,
          'steps': idea.steps,
          'minutes': idea.minutes,
          'servings': idea.servings,
          if (idea.calories > 0) 'calories': idea.calories,
          if (idea.protein > 0) 'protein': idea.protein,
        },
      });
      await _load(household);
      if (mounted) _say('Kept for your household.');
    } on PostgrestException catch (error) {
      if (mounted) {
        _say(error.code == '42501'
            ? 'Your account is not allowed to keep ideas in this household.'
            : error.message);
      }
    } catch (_) {
      if (mounted) _say('Could not keep it. Check your signal and try again.');
    } finally {
      if (mounted) setState(() => _keeping = false);
    }
  }

  Future<void> _remove(_Kept kept) async {
    try {
      await SupaFlow.client.from('saved_recipes').delete().eq('id', kept.id);
      await _load(_for);
    } catch (_) {
      if (mounted)
        _say('Could not remove it. Check your signal and try again.');
    }
  }

  Future<String> _addExtras(MealIdeaStruct idea) async {
    for (final name in idea.extras) {
      final said = await addNameToShoppingList(name);
      if (said.isNotEmpty) return said;
    }
    return '';
  }

  /// A photo of an ingredient the idea really uses, when there is one.
  static ({String url, String cue})? _ingredientPhoto(MealIdeaStruct idea) {
    const exact = {
      'spinach': 'spinach',
      'mushroom': 'mushrooms',
      'tomato': 'tomatoes',
      'egg': 'eggs',
      'yogurt': 'yogurt',
      'yoghurt': 'yogurt',
      'pasta': 'pasta',
    };
    for (final use in idea.uses) {
      final n = use.toLowerCase();
      for (final e in exact.entries) {
        if (n.contains(e.key)) {
          return (
            url: '$_food/${e.value}.webp',
            cue: 'Uses your ${use.toLowerCase()}'
          );
        }
      }
    }
    return null;
  }

  static String _cue(MealIdeaStruct idea) {
    final photo = _ingredientPhoto(idea);
    if (photo != null) return photo.cue;
    if (idea.uses.isNotEmpty)
      return 'Uses your ${idea.uses.first.toLowerCase()}';
    return '';
  }

  static bool get _goalsOn => FFAppState().ideasGoals;

  /// "520 kcal · 32 g protein", per serving, or '' when there is no estimate.
  static String _nutrition(MealIdeaStruct idea) => [
        if (idea.calories > 0) '${idea.calories} kcal',
        if (idea.protein > 0) '${idea.protein} g protein',
      ].join(' · ');

  int get _activeFilters {
    var n = 0;
    final s = FFAppState();
    if (s.ideasMeal.isNotEmpty && s.ideasMeal != 'any') n++;
    if (s.ideasMinutes != 0) n++;
    if (s.ideasServings != 2 && s.ideasServings != 0) n++;
    if (s.ideasLeaveOut.trim().isNotEmpty) n++;
    return n;
  }

  // ---- page ----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();
    final t = FlutterFlowTheme.of(context);
    final household = FFAppState().currentHouseholdId;
    if (household.isNotEmpty && household != _for) {
      _for = household;
      WidgetsBinding.instance.addPostFrameCallback((_) => _load(household));
    }
    final ideas = FFAppState().mealIdeas;
    final loading = FFAppState().ideasLoading;
    final still = MediaQuery.of(context).disableAnimations;

    Widget body;
    if (loading) {
      body = _thinking(t);
    } else if (ideas.isEmpty) {
      body = _invitation(t);
    } else {
      body = _results(t, ideas);
    }

    return SizedBox(
      width: widget.width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _weekLink(t),
          const SizedBox(height: 8),
          _collectionLink(t),
          const SizedBox(height: 12),
          _controls(t),
          const SizedBox(height: 16),
          AnimatedSwitcher(
            duration: still ? Duration.zero : const Duration(milliseconds: 220),
            child: KeyedSubtree(
              key: ValueKey(loading
                  ? 'loading'
                  : (ideas.isEmpty
                      ? 'invite'
                      : 'ideas${ideas.length}${ideas.first.title}')),
              child: body,
            ),
          ),
          if (_kept.isNotEmpty) ...[
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Text('Kept ideas',
                      style: t.titleLarge.copyWith(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: _ink)),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                      minimumSize: const Size(48, 44),
                      foregroundColor: _forest),
                  onPressed: () => context.pushNamed('RecipeCollectionPage'),
                  child: Text('See all',
                      style: t.bodyMedium.copyWith(
                          color: _forest, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 128,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                itemCount: _kept.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, i) =>
                    _smallCard(t, _kept[i].idea, kept: _kept[i], width: 200),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ---- controls ------------------------------------------------------------

  Widget _controls(FlutterFlowTheme t) {
    final s = FFAppState();
    final quick = s.ideasMinutes == 15 || s.ideasMinutes == 30;
    final active = _activeFilters;
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        children: [
          _chip(t, 'Quick meals', quick, Icons.bolt_outlined, () {
            FFAppState()
                .update(() => FFAppState().ideasMinutes = quick ? 0 : 30);
          }),
          const SizedBox(width: 8),
          _chip(t, 'Use my food', s.ideasKitchenOnly, Icons.kitchen_outlined,
              () {
            FFAppState().update(() =>
                FFAppState().ideasKitchenOnly = !FFAppState().ideasKitchenOnly);
          }),
          const SizedBox(width: 8),
          _chip(t, 'Fits my goals', s.ideasGoals, Icons.track_changes, () {
            final turningOn = !FFAppState().ideasGoals;
            FFAppState().update(() => FFAppState().ideasGoals = turningOn);
            // First time on, with nothing chosen yet: show where goals are set.
            if (turningOn &&
                FFAppState().ideasCalories.isEmpty &&
                !FFAppState().ideasHighProtein) {
              _openFilters(t);
            }
          }),
          const SizedBox(width: 8),
          _chip(t, active > 0 ? 'Filters · $active' : 'Filters', active > 0,
              Icons.tune, () => _openFilters(t)),
        ],
      ),
    );
  }

  Widget _collectionLink(FlutterFlowTheme t) => Semantics(
        button: true,
        label: 'Your recipes',
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => context.pushNamed('RecipeCollectionPage'),
          child: Container(
            constraints: const BoxConstraints(minHeight: 60),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _border),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      color: _sage, borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.menu_book_outlined,
                      color: _forest, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Your recipes',
                          style: t.bodyLarge.copyWith(
                              fontWeight: FontWeight.w800, color: _ink)),
                      Text('Kept ideas and your own, with what you have',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: t.bodySmall
                              .copyWith(color: _muted, fontSize: 13)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: _forest),
              ],
            ),
          ),
        ),
      );

  Widget _weekLink(FlutterFlowTheme t) => Semantics(
        button: true,
        label: 'Plan my week',
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => context.pushNamed('PlanWeekPage'),
          child: Container(
            constraints: const BoxConstraints(minHeight: 60),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _sage,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.calendar_month_outlined,
                      color: _forest, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Plan my week',
                          style: t.bodyLarge.copyWith(
                              fontWeight: FontWeight.w800, color: _ink)),
                      Text('Meals for the next 7 days, and one shopping list',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: t.bodySmall
                              .copyWith(color: _muted, fontSize: 13)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: _forest),
              ],
            ),
          ),
        ),
      );

  /// Puts an idea on a day of the household's week.
  Future<void> _addToWeek(FlutterFlowTheme t, MealIdeaStruct idea) async {
    final household = FFAppState().currentHouseholdId;
    if (household.isEmpty) return;
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
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
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    String name(int i) {
      if (i == 0) return 'Today';
      if (i == 1) return 'Tomorrow';
      final d = today.add(Duration(days: i));
      return '${days[d.weekday - 1]} ${d.day} ${months[d.month - 1]}';
    }

    var day = 0;
    var meal = _meals.containsKey(FFAppState().ideasMeal) &&
            FFAppState().ideasMeal != 'any'
        ? FFAppState().ideasMeal
        : 'dinner';
    final go = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _cream,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheet) => StatefulBuilder(
        builder: (sheet, redraw) => SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Add to my week',
                    style: t.headlineSmall.copyWith(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: _ink)),
                const SizedBox(height: 4),
                Text(idea.title,
                    style: t.bodyLarge.copyWith(color: _muted, fontSize: 16)),
                const SizedBox(height: 20),
                _sheetLabel(t, 'Day'),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (var i = 0; i < 7; i++)
                    _choice(t, name(i), day == i, () => redraw(() => day = i)),
                ]),
                const SizedBox(height: 20),
                _sheetLabel(t, 'Meal'),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final e in _meals.entries)
                    if (e.key != 'any')
                      _choice(t, e.value, meal == e.key,
                          () => redraw(() => meal = e.key)),
                ]),
                const SizedBox(height: 20),
                SizedBox(
                  height: 52,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: _forest,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () => Navigator.of(sheet).pop(true),
                    child: Text(
                        'Add to ${name(day) == 'Today' || name(day) == 'Tomorrow' ? name(day).toLowerCase() : name(day)}',
                        style: t.bodyLarge.copyWith(
                            color: Colors.white, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (go != true || !mounted) return;
    final d = today.add(Duration(days: day));
    final iso =
        '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    try {
      await SupaFlow.client.from('meal_plan_entries').insert({
        'household_id': household,
        'plan_date': iso,
        'meal': meal,
        'title': idea.title,
        'recipe_data': {
          'uses': idea.uses,
          'extras': idea.extras,
          'steps': idea.steps,
          'minutes': idea.minutes,
          if (idea.calories > 0) 'calories': idea.calories,
          if (idea.protein > 0) 'protein': idea.protein,
        },
        'servings': idea.servings > 0 ? idea.servings : 2,
        'created_by': SupaFlow.client.auth.currentUser?.id,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            'Planned for ${name(day) == 'Today' || name(day) == 'Tomorrow' ? name(day).toLowerCase() : name(day)}.'),
        action: SnackBarAction(
          label: 'See the week',
          textColor: const Color(0xFFB9E08F),
          onPressed: () => context.pushNamed('PlanWeekPage'),
        ),
      ));
    } on PostgrestException catch (error) {
      if (!mounted) return;
      _say(error.code == '42P01' || error.code == 'PGRST205'
          ? 'Plan my week is almost ready. Try again soon.'
          : (error.code == '42501'
              ? 'Your account is not allowed to plan meals in this household.'
              : error.message));
    } catch (_) {
      if (mounted) _say('Could not add it. Check your signal and try again.');
    }
  }

  Widget _chip(FlutterFlowTheme t, String label, bool on, IconData icon,
          VoidCallback onTap) =>
      Semantics(
        button: true,
        selected: on,
        label: label,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            constraints: const BoxConstraints(minHeight: 44),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: on ? _forest : Colors.white,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: on ? _forest : _border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: on ? Colors.white : _forest),
                const SizedBox(width: 6),
                Text(label,
                    style: t.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: on ? Colors.white : _ink)),
              ],
            ),
          ),
        ),
      );

  void _openFilters(FlutterFlowTheme t) {
    final leaveOut = TextEditingController(text: FFAppState().ideasLeaveOut);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _cream,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheet) {
        return StatefulBuilder(builder: (sheet, redraw) {
          final s = FFAppState();
          final meal = _meals.containsKey(s.ideasMeal) ? s.ideasMeal : 'any';
          final minutes =
              _times.containsKey(s.ideasMinutes) ? s.ideasMinutes : 0;
          final people = s.ideasServings < 1
              ? 2
              : (s.ideasServings > 8 ? 8 : s.ideasServings);
          final avoid = s.ideasAvoid.trim();
          void set(void Function() change) {
            FFAppState().update(change);
            redraw(() {});
          }

          return Padding(
            padding:
                EdgeInsets.only(bottom: MediaQuery.of(sheet).viewInsets.bottom),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                            color: _border,
                            borderRadius: BorderRadius.circular(999)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Filters',
                        style: t.headlineSmall.copyWith(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: _ink)),
                    const SizedBox(height: 20),
                    _sheetLabel(t, 'Meal'),
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      for (final e in _meals.entries)
                        _choice(t, e.value, meal == e.key,
                            () => set(() => FFAppState().ideasMeal = e.key)),
                    ]),
                    const SizedBox(height: 20),
                    _sheetLabel(t, 'Time'),
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      for (final e in _times.entries)
                        _choice(t, e.value, minutes == e.key,
                            () => set(() => FFAppState().ideasMinutes = e.key)),
                    ]),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(child: _sheetLabel(t, 'Servings')),
                        _stepper(
                            Icons.remove,
                            people > 1,
                            () => set(
                                () => FFAppState().ideasServings = people - 1)),
                        SizedBox(
                          width: 84,
                          child: Text(
                              people == 1 ? '1 person' : '$people people',
                              textAlign: TextAlign.center,
                              style: t.titleSmall.copyWith(color: _ink)),
                        ),
                        _stepper(
                            Icons.add,
                            people < 8,
                            () => set(
                                () => FFAppState().ideasServings = people + 1)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _goals(t, set),
                    const SizedBox(height: 20),
                    _sheetLabel(t, 'Leave out'),
                    TextField(
                      controller: leaveOut,
                      style: t.bodyLarge.copyWith(fontSize: 16, color: _ink),
                      decoration: InputDecoration(
                        hintText: 'e.g. mushrooms, nuts',
                        filled: true,
                        fillColor: Colors.white,
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
                      ),
                      onChanged: (v) => FFAppState()
                          .update(() => FFAppState().ideasLeaveOut = v),
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {
                        Navigator.of(sheet).pop();
                        context.pushNamed('FoodPreferencesPage');
                      },
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 56),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: _border),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.no_food_outlined,
                                color: _forest, size: 22),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Diet & allergies',
                                      style: t.bodyLarge.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: _ink)),
                                  Text(
                                    avoid.isEmpty
                                        ? 'None saved'
                                        : 'Always left out: $avoid',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: t.bodySmall
                                        .copyWith(color: _muted, fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right, color: _muted),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 52,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: _forest,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () {
                          Navigator.of(sheet).pop();
                          _ask();
                        },
                        child: Text('Show ideas',
                            style: t.bodyLarge.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        });
      },
    ).whenComplete(leaveOut.dispose);
  }

  // Off by default: people who only want to waste less never see calories.
  Widget _goals(FlutterFlowTheme t, void Function(void Function()) set) {
    final s = FFAppState();
    final range =
        _calorieRanges.containsKey(s.ideasCalories) ? s.ideasCalories : '';
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 10, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: s.ideasGoals ? _forest : _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.track_changes, color: _forest, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Fits my goals',
                        style: t.bodyLarge.copyWith(
                            fontWeight: FontWeight.w700, color: _ink)),
                    Text('Calories and protein on each idea, estimated',
                        style:
                            t.bodySmall.copyWith(color: _muted, fontSize: 14)),
                  ],
                ),
              ),
              Switch(
                value: s.ideasGoals,
                activeTrackColor: _forest,
                onChanged: (v) => set(() => FFAppState().ideasGoals = v),
              ),
            ],
          ),
          if (s.ideasGoals) ...[
            const SizedBox(height: 14),
            _sheetLabel(t, 'Calories per serving'),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final e in _calorieRanges.entries)
                _choice(t, e.value, range == e.key,
                    () => set(() => FFAppState().ideasCalories = e.key)),
            ]),
            const SizedBox(height: 14),
            Row(
              children: [
                _choice(
                    t,
                    'High protein',
                    s.ideasHighProtein,
                    () => set(() => FFAppState().ideasHighProtein =
                        !FFAppState().ideasHighProtein)),
              ],
            ),
            const SizedBox(height: 6),
            Text('At least 25 g a serving; 15 g for breakfasts and snacks.',
                style: t.bodySmall.copyWith(color: _muted, fontSize: 13)),
          ],
        ],
      ),
    );
  }

  // Small, quiet badges: the photo stays first.
  Widget _badges(FlutterFlowTheme t, MealIdeaStruct idea) {
    Widget badge(String text) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xE6FFFFFF),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(text,
              style: t.bodySmall.copyWith(
                  color: _forest, fontWeight: FontWeight.w800, fontSize: 12)),
        );
    return Wrap(spacing: 6, runSpacing: 6, children: [
      if (idea.calories > 0) badge('${idea.calories} kcal'),
      if (idea.protein > 0) badge('${idea.protein} g protein'),
    ]);
  }

  Widget _sheetLabel(FlutterFlowTheme t, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: t.bodyMedium.copyWith(
                color: _muted, fontWeight: FontWeight.w700, fontSize: 14)),
      );

  Widget _choice(
          FlutterFlowTheme t, String label, bool on, VoidCallback onTap) =>
      Semantics(
        button: true,
        selected: on,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 44),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: on ? _forest : Colors.white,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: on ? _forest : _border),
            ),
            child: Text(label,
                style: t.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: on ? Colors.white : _ink)),
          ),
        ),
      );

  Widget _stepper(IconData icon, bool enabled, VoidCallback onTap) => Opacity(
        opacity: enabled ? 1 : 0.4,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: enabled ? onTap : null,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: _border),
            ),
            child: Icon(icon, color: _forest, size: 20),
          ),
        ),
      );

  // ---- states --------------------------------------------------------------

  Widget _invitation(FlutterFlowTheme t) {
    final empty = _hasFood == false;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: 250,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Illustrative ingredients, not a recipe result.
            Image.network(
              '$_food/spinach.webp',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: _sage),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x00000000), Color(0xC0000000)],
                  stops: [0.3, 1],
                ),
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    empty
                        ? 'Ideas come from your food'
                        : 'Ideas from your food',
                    style: t.headlineSmall.copyWith(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        height: 1.15),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 48,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: _forest,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: empty
                          ? () async {
                              await clearShelfScan();
                              if (mounted) context.pushNamed('MapReviewPage');
                            }
                          : _ask,
                      icon: Icon(
                          empty ? Icons.add : Icons.auto_awesome_outlined,
                          size: 20),
                      label: Text(empty ? 'Add food' : 'Find ideas',
                          style: t.bodyLarge.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _thinking(FlutterFlowTheme t) {
    Widget block(double h) => Container(
          height: h,
          decoration: BoxDecoration(
              color: _sage, borderRadius: BorderRadius.circular(20)),
        );
    return Semantics(
      label: 'Finding ideas from your kitchen',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          block(220),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: block(128)),
            const SizedBox(width: 12),
            Expanded(child: block(128)),
          ]),
          const SizedBox(height: 12),
          Text('Looking through your kitchen…',
              style: t.bodyMedium.copyWith(color: _muted, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _results(FlutterFlowTheme t, List<MealIdeaStruct> ideas) {
    final lead = ideas.first;
    final rest = ideas.skip(1).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _leadCard(t, lead),
        if (rest.isNotEmpty) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 128,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              itemCount: rest.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) => _smallCard(t, rest[i], width: 220),
            ),
          ),
        ],
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _ask,
            style: TextButton.styleFrom(
                minimumSize: const Size(48, 48), foregroundColor: _forest),
            icon: const Icon(Icons.refresh, size: 18),
            label: Text('New ideas',
                style: t.bodyLarge
                    .copyWith(color: _forest, fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }

  Widget _leadCard(FlutterFlowTheme t, MealIdeaStruct idea) {
    final photo = _ingredientPhoto(idea);
    final meta = [
      if (idea.minutes > 0) '${idea.minutes} min',
      if (_cue(idea).isNotEmpty) _cue(idea),
    ].join(' · ');
    final text = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(idea.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: t.headlineSmall.copyWith(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w800,
                height: 1.15)),
        if (meta.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(meta,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: t.bodyMedium.copyWith(
                  color: Colors.white.withOpacity(0.9), fontSize: 14)),
        ],
        if (_goalsOn && _nutrition(idea).isNotEmpty) ...[
          const SizedBox(height: 8),
          _badges(t, idea),
        ],
      ],
    );
    return _tap(
      label: idea.title,
      onTap: () => _openIdea(t, idea),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          height: 220,
          child: photo == null
              ? Container(
                  color: _forest,
                  padding: const EdgeInsets.all(20),
                  alignment: Alignment.bottomLeft,
                  child: text,
                )
              : Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(photo.url,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            Container(color: _forest)),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0x00000000), Color(0xC8000000)],
                          stops: [0.25, 1],
                        ),
                      ),
                    ),
                    Positioned(left: 20, right: 20, bottom: 20, child: text),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _smallCard(FlutterFlowTheme t, MealIdeaStruct idea,
      {_Kept? kept, required double width}) {
    final meta = [
      if (idea.minutes > 0) '${idea.minutes} min',
      if (_goalsOn && _nutrition(idea).isNotEmpty)
        _nutrition(idea)
      else if (kept == null && _cue(idea).isNotEmpty)
        _cue(idea),
    ].join(' · ');
    return _tap(
      label: idea.title,
      onTap: () => _openIdea(t, idea, kept: kept),
      child: Container(
        width: width,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kept == null ? Colors.white : _sage,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: kept == null ? _border : _sage),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(idea.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: t.titleMedium.copyWith(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: _ink,
                    height: 1.2)),
            const Spacer(),
            if (meta.isNotEmpty)
              Text(meta,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.bodySmall.copyWith(color: _muted, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _tap(
          {required String label,
          required VoidCallback onTap,
          required Widget child}) =>
      Semantics(
        button: true,
        label: label,
        child: GestureDetector(onTap: onTap, child: child),
      );

  // ---- one idea, in full -----------------------------------------------------

  void _openIdea(FlutterFlowTheme t, MealIdeaStruct idea, {_Kept? kept}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _cream,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheet) {
        return StatefulBuilder(builder: (sheet, redraw) {
          final avoid = [FFAppState().ideasAvoid, FFAppState().ideasLeaveOut]
              .map((w) => w.trim())
              .where((w) => w.isNotEmpty)
              .join(', ');
          final meta = [
            if (idea.minutes > 0) '${idea.minutes} min',
            if (idea.servings > 0) 'Serves ${idea.servings}',
          ].join(' · ');
          final listed = _listed.contains(_same(idea.title));
          return ConstrainedBox(
            constraints: BoxConstraints(
                maxHeight: MediaQuery.of(sheet).size.height * 0.88),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                            color: _border,
                            borderRadius: BorderRadius.circular(999)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(idea.title,
                        style: t.headlineSmall.copyWith(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: _ink,
                            height: 1.15)),
                    if (meta.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(meta,
                          style: t.bodyMedium
                              .copyWith(color: _muted, fontSize: 14)),
                    ],
                    if (_goalsOn && idea.calories > 0) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _sage,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                for (final n in [
                                  ('${idea.calories}', 'kcal a serving'),
                                  if (idea.protein > 0)
                                    ('${idea.protein} g', 'protein a serving'),
                                ])
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(n.$1,
                                            style: t.headlineSmall.copyWith(
                                                fontSize: 24,
                                                fontWeight: FontWeight.w800,
                                                color: _forest)),
                                        Text(n.$2,
                                            style: t.bodySmall.copyWith(
                                                color: _muted, fontSize: 13)),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Estimated from typical amounts of these ingredients, not measured. A guide only, not diet or medical advice.',
                              style: t.bodySmall.copyWith(
                                  color: _ink, fontSize: 13, height: 1.35),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    _section(t, kept == null ? 'From your kitchen' : 'Uses'),
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      for (final u in idea.uses) _pill(t, u, _sage, _forest),
                    ]),
                    if (kept == null) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Only food that is not past its use-by or best-before date.',
                        style:
                            t.bodySmall.copyWith(color: _muted, fontSize: 13),
                      ),
                    ],
                    if (idea.extras.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _section(t, 'You would also need'),
                      Wrap(spacing: 8, runSpacing: 8, children: [
                        for (final e in idea.extras)
                          _pill(t, e, Colors.white, _ink),
                      ]),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          style: TextButton.styleFrom(
                              minimumSize: const Size(48, 48),
                              foregroundColor: _forest),
                          onPressed: listed
                              ? null
                              : () async {
                                  final said = await _addExtras(idea);
                                  if (!mounted) return;
                                  if (said.isEmpty) {
                                    _listed.add(_same(idea.title));
                                    redraw(() {});
                                    _say('Added to your shopping list.');
                                  } else {
                                    _say(said);
                                  }
                                },
                          icon: Icon(
                              listed ? Icons.check : Icons.add_shopping_cart,
                              size: 18),
                          label: Text(
                              listed
                                  ? 'On your shopping list'
                                  : 'Add to shopping list',
                              style: t.bodyLarge.copyWith(
                                  color: listed ? _muted : _forest,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
                    if (idea.steps.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _section(t, 'Steps'),
                      for (var i = 0; i < idea.steps.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                alignment: Alignment.center,
                                decoration: const BoxDecoration(
                                    color: _forest, shape: BoxShape.circle),
                                child: Text('${i + 1}',
                                    style: t.bodySmall.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(idea.steps[i],
                                    style: t.bodyLarge.copyWith(
                                        fontSize: 16,
                                        color: _ink,
                                        height: 1.45)),
                              ),
                            ],
                          ),
                        ),
                    ],
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _border),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline,
                              color: _forest, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              avoid.isEmpty
                                  ? 'Not checked for allergies or diets. Read the label on anything you cook with.'
                                  : 'Left out for you: $avoid. Not a medical check: read the label on anything you cook with.',
                              style: t.bodyMedium.copyWith(
                                  color: _ink, fontSize: 14, height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
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
                        onPressed: () {
                          Navigator.of(sheet).pop();
                          _addToWeek(t, idea);
                        },
                        icon:
                            const Icon(Icons.calendar_month_outlined, size: 20),
                        label: Text('Add to my week',
                            style: t.bodyLarge.copyWith(
                                color: _forest, fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 52,
                      child: kept != null
                          ? OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _forest,
                                side: const BorderSide(color: _border),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                              ),
                              onPressed: () {
                                Navigator.of(sheet).pop();
                                _remove(kept);
                              },
                              icon: const Icon(Icons.close, size: 18),
                              label: Text('Remove from kept ideas',
                                  style: t.bodyLarge.copyWith(
                                      color: _forest,
                                      fontWeight: FontWeight.w700)),
                            )
                          : FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: _forest,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: _leaf.withOpacity(0.5),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                              ),
                              onPressed: _isKept(idea)
                                  ? null
                                  : () async {
                                      await _keep(idea);
                                      redraw(() {});
                                    },
                              icon: Icon(
                                  _isKept(idea)
                                      ? Icons.bookmark
                                      : Icons.bookmark_border,
                                  size: 20),
                              label: Text(
                                  _isKept(idea) ? 'Kept' : 'Keep this idea',
                                  style: t.bodyLarge.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700)),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          );
        });
      },
    );
  }

  Widget _section(FlutterFlowTheme t, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(text,
            style: t.titleMedium.copyWith(
                fontSize: 18, fontWeight: FontWeight.w800, color: _ink)),
      );

  Widget _pill(FlutterFlowTheme t, String text, Color bg, Color fg) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: bg == Colors.white ? _border : bg),
        ),
        child: Text(text,
            style: t.bodyMedium.copyWith(
                color: fg, fontWeight: FontWeight.w600, fontSize: 14)),
      );
}
''';
