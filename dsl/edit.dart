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

/// Plus is shared by the household (owner, 15 Sep): when anyone in your
/// household has Plus, everyone in it does. Profile says "Plus, shared by
/// your household". Home refreshes the plan when the household loads.
void buildStarterEditFlow(App app) {
  app.raw((project) {
    updateCustomWidget(project, name: 'HomeKitchen', code: _wHomeKitchen);
    updateCustomWidget(project, name: 'ProfileMenu', code: _wProfileMenu);
  });
}

const _wHomeKitchen = r'''
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Home, in the hybrid design (brief, 15 Sep).
///
/// "Good food. Great possibilities." Then one photographic meal — what the
/// household planned for today, or an idea from its own food — with one
/// clear action; a small, calm note when foods need using soon; the next foods
/// to use as a two-column grid with honest date badges; and Shopping list and
/// Add food within reach.
///
/// Reads the household's food itself and stays silent when there is no
/// household or no signal: the page already has a card for each of those.
class HomeKitchen extends StatefulWidget {
  const HomeKitchen({super.key, this.width, this.height});

  final double? width;
  final double? height;

  @override
  State<HomeKitchen> createState() => _HomeKitchenState();
}

class _HomeKitchenState extends State<HomeKitchen> {
  String _for = '';
  bool _loading = true;
  bool _failed = false;
  bool _busy = false;
  List<Map<String, dynamic>> _items = const [];
  int _soon = 0;
  Map<String, dynamic>? _kept;
  Map<String, dynamic>? _planned;
  bool _saved = false;

  // The food picture library's index is checked once each time the app runs.
  static bool _libraryChecked = false;

  @override
  void initState() {
    super.initState();
    _refreshLibrary();
  }

  /// Downloads the food picture library's index and keeps it on the phone,
  /// so pictures added to the library show without a new build and still
  /// show offline.
  Future<void> _refreshLibrary() async {
    if (_libraryChecked) return;
    _libraryChecked = true;
    _uLoadProfile();
    try {
      final r = await http
          .get(Uri.parse(
              'https://cdn.jsdelivr.net/gh/ashelashiry/UseItFresh@main/design/library/index.json'))
          .timeout(const Duration(seconds: 20));
      if (r.statusCode != 200) return;
      final body = utf8.decode(r.bodyBytes);
      final j = jsonDecode(body);
      if (j is! Map || j['items'] is! List) return;
      if (body != FFAppState().foodLibrary) {
        FFAppState().update(() => FFAppState().foodLibrary = body);
      }
    } catch (_) {
      _libraryChecked = false;
    }
  }

  Future<void> _load(String household) async {
    _uLoadProfile();
    if (mounted) {
      setState(() {
        _loading = true;
        _failed = false;
      });
    }
    try {
      final client = SupaFlow.client;
      final rows = await client
          .from('food_items_status')
          .select(
              'id, name, quantity, unit, image_url, computed_status, days_left, printed_date, printed_date_type, status_basis, urgency_rank')
          .eq('household_id', household)
          .order('urgency_rank', ascending: true)
          .order('days_left', ascending: true)
          .limit(300);
      final all = [
        for (final r in rows as List)
          if (!const ['consumed', 'discarded']
              .contains('${(r as Map)['computed_status']}'))
            Map<String, dynamic>.from(r)
      ];
      Map<String, dynamic>? kept;
      try {
        final ideas = await client
            .from('saved_recipes')
            .select('title, recipe_data')
            .eq('household_id', household)
            .order('created_at', ascending: false)
            .limit(1);
        if ((ideas as List).isNotEmpty) {
          kept = Map<String, dynamic>.from(ideas.first as Map);
        }
      } catch (_) {}
      Map<String, dynamic>? planned;
      try {
        final n = DateTime.now();
        final today =
            '${n.year.toString().padLeft(4, '0')}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
        final meals = await client
            .from('meal_plan_entries')
            .select('id, meal, title, recipe_data, servings')
            .eq('household_id', household)
            .eq('plan_date', today)
            .eq('status', 'planned');
        const order = ['dinner', 'lunch', 'snack', 'breakfast'];
        final list = [
          for (final m in meals as List) Map<String, dynamic>.from(m as Map)
        ]..sort((a, b) => order
            .indexOf('${a['meal']}')
            .compareTo(order.indexOf('${b['meal']}')));
        if (list.isNotEmpty) planned = list.first;
      } catch (_) {}
      if (!mounted || household != _for) return;
      setState(() {
        _items = all;
        _soon = all.where(_uSoon).length;
        _kept = kept;
        _planned = planned;
        _loading = false;
      });
      // Keep the daily reminder notes in step with the kitchen.
      scheduleExpiryReminders();
    } catch (_) {
      if (!mounted) return;
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

  Future<void> _addFood() async {
    await clearShelfScan();
    if (!mounted) return;
    await context.pushNamed('CameraPage', queryParameters: {'mode': 'shelf'});
    if (mounted && _for.isNotEmpty) _load(_for);
  }

  Future<void> _open(String route, {Map<String, String>? query}) async {
    await context.pushNamed(route, queryParameters: query ?? const {});
    if (mounted && _for.isNotEmpty) _load(_for);
  }

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
    // No household: the page's own prompt says what to do.
    if (household.isEmpty) return const SizedBox.shrink();
    if (household != _for) {
      _for = household;
      WidgetsBinding.instance.addPostFrameCallback((_) => _load(household));
    }
    // No signal: the page's own card says so, with Try again.
    if (_failed) return const SizedBox.shrink();

    final t = FlutterFlowTheme.of(context);
    final title = t.headlineLarge.copyWith(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        color: _uForest,
        height: 1.08,
        letterSpacing: -0.8);

    return SizedBox(
      width: widget.width,
      child: _loading
          ? _skeleton()
          : AnimatedSwitcher(
              duration: _uStill(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 200),
              child: _items.isEmpty ? _empty(t, title) : _populated(t, title),
            ),
    );
  }

  Widget _skeleton() {
    Widget block(double h) => Container(
          height: h,
          decoration: BoxDecoration(
            color: const Color(0xAAE6EDDF),
            borderRadius: BorderRadius.circular(22),
          ),
        );
    return Semantics(
      label: 'Loading your kitchen',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(width: 260, child: block(70)),
          const SizedBox(height: 20),
          block(360),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: block(200)),
            const SizedBox(width: 12),
            Expanded(child: block(200)),
          ]),
        ],
      ),
    );
  }

  // ---- empty kitchen -------------------------------------------------------

  Widget _empty(FlutterFlowTheme t, TextStyle title) {
    const base =
        'https://cdn.jsdelivr.net/gh/ashelashiry/UseItFresh@b50424f12bd372d81c9cd44d895b62c25d1329e7/design/v3/food';
    return Column(
      key: const ValueKey('empty'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Fresh starts here.', style: title),
        const SizedBox(height: 20),
        _USurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 190,
                child: Image.network('$base/tomatoes.webp',
                    fit: BoxFit.cover,
                    semanticLabel: '',
                    errorBuilder: (_, __, ___) =>
                        Container(color: const Color(0xFFE4E9D9))),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Let’s stock your kitchen',
                        style: t.headlineSmall.copyWith(
                            fontSize: 23,
                            fontWeight: FontWeight.w800,
                            color: _uInk,
                            height: 1.15)),
                    const SizedBox(height: 6),
                    Text('Photograph a shelf, scan a receipt, or type it in.',
                        style: t.bodyMedium
                            .copyWith(color: _uMuted, fontSize: 14)),
                    const SizedBox(height: 14),
                    _UButton('Add food',
                        icon: Icons.add,
                        busy: _busy,
                        onTap: () => _run(_addFood)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _UButton('Scan a receipt',
                  kind: 'secondary',
                  icon: Icons.receipt_long_outlined,
                  onTap: _busy
                      ? null
                      : () => _open('CameraPage', query: {'mode': 'receipt'})),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _UButton('Shopping list',
                  kind: 'secondary',
                  icon: Icons.shopping_cart_outlined,
                  onTap: () => _open('ShoppingListPage')),
            ),
          ],
        ),
      ],
    );
  }

  // ---- food in the kitchen -------------------------------------------------

  Widget _populated(FlutterFlowTheme t, TextStyle title) {
    final next = _items.take(4).toList();
    return Column(
      key: const ValueKey('populated'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Good food.\nGreat possibilities.', style: title),
        const SizedBox(height: 20),
        _meal(t),
        if (_soon > 0) ...[
          const SizedBox(height: 14),
          _soonNote(t),
        ],
        const SizedBox(height: 22),
        Row(
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text('Use these next',
                    style: t.titleLarge.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: _uInk)),
              ),
            ),
            TextButton(
              onPressed: () => _open('InventoryPage'),
              style: TextButton.styleFrom(
                  minimumSize: const Size(48, 44), foregroundColor: _uForest),
              child: Text('View all ${_items.length}',
                  style: t.bodyMedium
                      .copyWith(color: _uForest, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LayoutBuilder(builder: (context, box) {
          final w = (box.maxWidth - 12) / 2;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final item in next)
                SizedBox(
                  width: w,
                  child: _uFoodCard(context, item,
                      onTap: () => _open('FoodItemPage',
                          query: {'itemId': '${item['id']}'})),
                ),
            ],
          );
        }),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _UButton('Shopping list',
                  kind: 'secondary',
                  icon: Icons.shopping_cart_outlined,
                  onTap: () => _open('ShoppingListPage')),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _UButton('Add food',
                  kind: 'secondary',
                  icon: Icons.add,
                  onTap: _busy ? null : () => _run(_addFood)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _soonNote(FlutterFlowTheme t) {
    final n = _soon;
    return _USurface(
      radius: 18,
      onTap: () => _open('UseSoonPage'),
      label:
          '$n ${n == 1 ? 'food needs' : 'foods need'} using soon. View foods.',
      tint: const [Color(0xFFFFF6EA), Color(0xFFFBEBD8)],
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      child: Row(
        children: [
          const Icon(Icons.schedule, color: Color(0xFF884311), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
                n == 1 ? '1 food needs using soon' : '$n foods need using soon',
                style: t.bodyMedium.copyWith(
                    color: const Color(0xFF5C2A04),
                    fontSize: 15,
                    fontWeight: FontWeight.w700)),
          ),
          Text('View foods',
              style: t.bodyMedium
                  .copyWith(color: _uForest, fontWeight: FontWeight.w700)),
          const Icon(Icons.chevron_right, color: _uForest, size: 20),
        ],
      ),
    );
  }

  /// The one meal Home leads with: today's plan, a fresh idea, or a kept one.
  Widget _meal(FlutterFlowTheme t) {
    String label;
    String name = '';
    String meta = '';
    List<String> uses = const [];
    String action;
    VoidCallback go;
    Map? keep;
    final plan = _planned;
    if (plan != null) {
      final d =
          plan['recipe_data'] is Map ? plan['recipe_data'] as Map : const {};
      final mins = d['minutes'] is num ? (d['minutes'] as num).round() : 0;
      final buy = d['extras'] is List ? (d['extras'] as List).length : 0;
      uses = d['uses'] is List
          ? [for (final u in d['uses'] as List) '$u']
          : const [];
      label = 'PLANNED FOR TODAY';
      name = '${plan['title']}';
      meta = [
        if (mins > 0) '$mins min',
        buy == 0
            ? 'Everything in your kitchen'
            : (buy == 1 ? '1 thing to buy' : '$buy things to buy'),
      ].join(' · ');
      action = 'Let’s cook';
      go = () => _open('PlanWeekPage');
    } else if (FFAppState().mealIdeas.isNotEmpty) {
      final idea = FFAppState().mealIdeas.first;
      label = 'TONIGHT, SORTED';
      name = idea.title;
      uses = idea.uses;
      meta = [
        if (idea.minutes > 0) '${idea.minutes} min',
        if (idea.uses.isNotEmpty)
          idea.uses.length == 1
              ? 'Uses 1 food in your kitchen'
              : 'Uses ${idea.uses.length} foods in your kitchen',
      ].join(' · ');
      action = 'Let’s cook';
      go = () => _open('RecipesPage');
      keep = {
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
      };
    } else if (_kept != null) {
      final d = _kept!['recipe_data'] is Map
          ? _kept!['recipe_data'] as Map
          : const {};
      final mins = d['minutes'] is num ? (d['minutes'] as num).round() : 0;
      uses = d['uses'] is List
          ? [for (final u in d['uses'] as List) '$u']
          : const [];
      label = 'ONE OF YOUR RECIPES';
      name = '${_kept!['title']}';
      meta = [if (mins > 0) '$mins min', 'Kept by your household'].join(' · ');
      action = 'Let’s cook';
      go = () => _open('RecipeCollectionPage');
    } else {
      label = 'TONIGHT';
      name = 'What can you make tonight?';
      meta = 'Ideas from the food you already have';
      action = 'Find meals';
      go = () => _open('RecipesPage');
    }

    // An illustrative photo of a real ingredient of this meal, when one fits.
    var photo = '';
    for (final u in uses) {
      photo = _uFresh(u, freshOnly: true);
      if (photo.isNotEmpty) break;
    }
    final lower = name.toLowerCase();
    if (photo.isEmpty &&
        (lower.contains('pasta') ||
            lower.contains('spaghetti') ||
            lower.contains('linguine'))) {
      photo =
          'https://cdn.jsdelivr.net/gh/ashelashiry/UseItFresh@b50424f12bd372d81c9cd44d895b62c25d1329e7/design/v3/food/pasta.webp';
    }

    Widget chip(String text) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
              color: const Color(0xF0FFFFFF),
              borderRadius: BorderRadius.circular(10)),
          child: Text(text,
              style: t.bodySmall.copyWith(
                  color: _uForest,
                  fontSize: 11,
                  letterSpacing: 0.9,
                  fontWeight: FontWeight.w800)),
        );

    return _USurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: photo.isEmpty ? 64 : 200,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (photo.isEmpty)
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFE4E9D9), Color(0xFFD9E6D1)],
                      ),
                    ),
                  )
                else
                  Image.network(photo,
                      fit: BoxFit.cover,
                      cacheWidth: 900,
                      semanticLabel: '',
                      errorBuilder: (_, __, ___) =>
                          Container(color: const Color(0xFFE4E9D9))),
                Positioned(left: 14, top: 14, child: chip(label)),
                if (keep != null)
                  Positioned(
                    right: 14,
                    top: 10,
                    child: _UPress(
                      label: _saved ? 'Saved' : 'Save this idea',
                      onTap: () async {
                        if (_saved) return;
                        try {
                          await SupaFlow.client.from('saved_recipes').insert({
                            ...keep!,
                            'household_id': _for,
                            'profile_id': SupaFlow.client.auth.currentUser?.id,
                          });
                          if (mounted) setState(() => _saved = true);
                        } catch (_) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Could not save it. Check your signal.')));
                          }
                        }
                      },
                      child: Container(
                        constraints:
                            const BoxConstraints(minHeight: 44, minWidth: 56),
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFDF5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(_saved ? 'Saved' : 'Save',
                            style: t.bodySmall.copyWith(
                                color: _uForest,
                                fontSize: 13,
                                fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(17),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(name,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: t.headlineSmall.copyWith(
                        fontSize: 23,
                        fontWeight: FontWeight.w800,
                        color: _uInk,
                        height: 1.15)),
                if (meta.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(meta,
                      style:
                          t.bodyMedium.copyWith(color: _uMuted, fontSize: 14)),
                ],
                const SizedBox(height: 14),
                _UButton(action,
                    icon: Icons.arrow_forward, trailing: true, onTap: go),
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

const _wProfileMenu = r'''
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';

/// Profile settings, grouped and compact.
class ProfileMenu extends StatelessWidget {
  const ProfileMenu({super.key, this.width, this.height});

  final double? width;
  final double? height;

  static const _forest = Color(0xFF07533A);
  static const _ink = Color(0xFF202C24);
  static const _muted = Color(0xFF59665D);
  static const _sage = Color(0xFFEDF2E8);
  static const _border = Color(0xFFDCE3D7);

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);
    context.watch<FFAppState>();
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const _ProfileHeader(),
          const SizedBox(height: 20),
          _group(context, t, 'You', [
            _Row('My details', Icons.badge_outlined, 'OnboardingPage'),
            _Row('Diet & allergies', Icons.no_food_outlined,
                'FoodPreferencesPage'),
            _Row('Security', Icons.lock_outline, 'UpdatePasswordPage'),
          ]),
          const SizedBox(height: 20),
          _group(context, t, 'Kitchen', [
            _Row('Household', Icons.group_outlined, 'HouseholdSetupPage'),
            _Row('Storage', Icons.kitchen_outlined, 'StorageLocationsPage'),
            _Row('Shopping list', Icons.shopping_cart_outlined,
                'ShoppingListPage'),
            _Row('Receipts', Icons.receipt_long_outlined, 'ReceiptsPage'),
            _Row('Reminders', Icons.notifications_none, 'RemindersPage'),
            _Row('What you used', Icons.insights_outlined, 'WasteHistoryPage'),
          ]),
          const SizedBox(height: 20),
          _group(context, t, 'App', [
            _Row(
                FFAppState().plan == 'plus'
                    ? 'Your plan: Plus'
                    : FFAppState().plan == 'household'
                    ? 'Your plan: Plus, shared by your household'
                    : (FFAppState().plan == 'free'
                        ? 'Your plan: Free'
                        : 'Your plan'),
                Icons.workspace_premium_outlined,
                _planRoute),
            _Row('Food pictures: ${_uPictureOrderLabel()}',
                Icons.image_outlined, _pictures),
          ]),
        ],
      ),
    );
  }

  static const _pictures = 'food-pictures';
  static const _planRoute = 'your-plan';

  /// Your plan (owner, 15 Sep): Plus says so; free shows what Plus adds.
  Future<void> _openPlan(BuildContext context, FlutterFlowTheme t) async {
    if (!_uPlus() || FFAppState().plan != 'plus') {
      if (FFAppState().plan == 'free') {
        await _uPlusSheet(context, 'Plan my week');
        return;
      }
    }
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: _uCream,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheet) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(children: [
                const Icon(Icons.workspace_premium_outlined,
                    color: _uForest, size: 28),
                const SizedBox(width: 10),
                _uPlusBadge(),
              ]),
              const SizedBox(height: 12),
              Text(
                  FFAppState().plan == 'plus'
                      ? 'You’re on Use It Fresh Plus'
                      : FFAppState().plan == 'household'
                      ? 'Your household has Use It Fresh Plus'
                      : 'Everything is open for now',
                  style: t.headlineSmall.copyWith(
                      fontSize: 22, fontWeight: FontWeight.w800, color: _uInk)),
              const SizedBox(height: 10),
              for (final perk in _uPlusPerks)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(children: [
                    Icon(perk.$1, size: 20, color: _uForest),
                    const SizedBox(width: 10),
                    Expanded(
                        child: Text(
                            perk.$2.replaceAll('«', '“').replaceAll('»', '”'),
                            style: t.bodyMedium.copyWith(color: _uInk))),
                    const Icon(Icons.check, size: 18, color: _uForest),
                  ]),
                ),
              const SizedBox(height: 10),
              _UButton('OK', onTap: () => Navigator.of(sheet).pop()),
            ],
          ),
        ),
      ),
    );
  }

  /// Owner, 15 Sep: which picture a food shows, as a ranked order of three
  /// sources - a fresh stock photo, the photo you took or scanned, and the
  /// product's photo from its barcode or the supermarket. Each food shows the
  /// highest-ranked picture it has.
  Future<void> _openPictures(BuildContext context, FlutterFlowTheme t) async {
    const about = <String, (String, String, IconData)>{
      'stock': (
        'Fresh stock photo',
        'A fresh, appetising photo of that food from our library.',
        Icons.photo_outlined
      ),
      'scan': (
        'My scan or photo',
        'The picture you took or cut from a shelf photo.',
        Icons.photo_camera_outlined
      ),
      'product': (
        'Product photo',
        'The pack from its barcode or the supermarket.',
        Icons.shopping_basket_outlined
      ),
    };
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: _uCream,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheet) => StatefulBuilder(builder: (sheet, redraw) {
        final order = _uPictureOrder();
        void move(int from, int to) {
          final next = [...order];
          final v = next.removeAt(from);
          next.insert(to, v);
          FFAppState()
              .update(() => FFAppState().photoPreference = next.join(','));
          redraw(() {});
        }

        Widget arrow(IconData icon, String label, VoidCallback? onTap) =>
            Semantics(
              button: true,
              label: label,
              child: IconButton(
                onPressed: onTap,
                icon: Icon(icon, size: 22),
                color: _uForest,
                disabledColor: const Color(0x3307533A),
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              ),
            );

        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Food pictures',
                    style: t.headlineSmall.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: _uInk)),
                const SizedBox(height: 4),
                Text(
                    'Put them in the order you like. Each food shows the first one it has.',
                    style: t.bodyMedium.copyWith(color: _uMuted, fontSize: 14)),
                const SizedBox(height: 14),
                for (var i = 0; i < order.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _USurface(
                      radius: 18,
                      label: '${i + 1}. ${about[order[i]]!.$1}',
                      padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
                      tint: i == 0
                          ? const [Color(0xFFF1F7EC), Color(0xFFE0ECD6)]
                          : null,
                      child: Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                                color: _uForest, shape: BoxShape.circle),
                            child: Text('${i + 1}',
                                style: t.bodyMedium.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800)),
                          ),
                          const SizedBox(width: 12),
                          Icon(about[order[i]]!.$3, color: _uForest, size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(about[order[i]]!.$1,
                                    style: t.bodyLarge.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: _uInk)),
                                Text(about[order[i]]!.$2,
                                    style: t.bodySmall.copyWith(
                                        color: _uMuted, fontSize: 12.5)),
                              ],
                            ),
                          ),
                          arrow(Icons.keyboard_arrow_up_rounded, 'Move up',
                              i == 0 ? null : () => move(i, i - 1)),
                          arrow(
                              Icons.keyboard_arrow_down_rounded,
                              'Move down',
                              i == order.length - 1
                                  ? null
                                  : () => move(i, i + 1)),
                        ],
                      ),
                    ),
                  ),
                Text(
                    'Stock photos are illustrations of the food, not your food. On a food’s screen you can switch to its other picture.',
                    style: t.bodySmall.copyWith(color: _uMuted, fontSize: 13)),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _group(BuildContext context, FlutterFlowTheme t, String heading,
      List<_Row> rows) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Semantics(
            header: true,
            child: Text(heading,
                style: t.bodyMedium.copyWith(
                    fontSize: 14, fontWeight: FontWeight.w700, color: _muted)),
          ),
        ),
        Container(
          decoration: _uCard(20),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < rows.length; i++) ...[
                if (i > 0)
                  const Divider(
                      height: 1, thickness: 1, indent: 64, color: _border),
                _tile(context, t, rows[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _tile(BuildContext context, FlutterFlowTheme t, _Row row) {
    return Semantics(
      button: true,
      label: row.title,
      excludeSemantics: true,
      child: InkWell(
        onTap: () => row.route == _pictures
            ? _openPictures(context, t)
            : (row.route == _planRoute
                ? _openPlan(context, t)
                : context.pushNamed(row.route)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      color: _sage, borderRadius: BorderRadius.circular(12)),
                  child: Icon(row.icon, color: _forest, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(row.title,
                      style: t.bodyLarge.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _ink)),
                ),
                const Icon(Icons.chevron_right, color: _muted, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Row {
  const _Row(this.title, this.icon, this.route);
  final String title;
  final IconData icon;
  final String route;
}

/// The top of Profile (owner, 15 Sep): your photo, name and email, opening
/// My details. Shows the app's remembered copy at once, then refreshes it.
class _ProfileHeader extends StatefulWidget {
  const _ProfileHeader();

  @override
  State<_ProfileHeader> createState() => _ProfileHeaderState();
}

class _ProfileHeaderState extends State<_ProfileHeader> {
  @override
  void initState() {
    super.initState();
    _uLoadProfile();
  }

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);
    final app = context.watch<FFAppState>();
    final email = SupaFlow.client.auth.currentUser?.email ?? '';
    final name = app.profileName.trim();
    final photo = app.profileAvatar.trim();
    final initial = (name.isNotEmpty ? name : (email.isNotEmpty ? email : '?'))
        .substring(0, 1)
        .toUpperCase();
    return _USurface(
      onTap: () => context.pushNamed('OnboardingPage'),
      label: 'My details',
      padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFE9F0E1), Color(0xFFCFDDC5)]),
              border: Border.all(color: Colors.white, width: 2),
            ),
            clipBehavior: Clip.antiAlias,
            child: photo.isEmpty
                ? Center(
                    child: Text(initial,
                        style: t.headlineSmall.copyWith(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: _uForest)))
                : Image.network(photo,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Center(
                        child: Text(initial,
                            style: t.headlineSmall.copyWith(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: _uForest)))),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name.isEmpty ? 'Add your name' : name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.titleMedium.copyWith(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: _uInk)),
                if (email.isNotEmpty)
                  Text(email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          t.bodyMedium.copyWith(color: _uMuted, fontSize: 14)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: _uMuted),
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

