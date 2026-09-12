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

/// Design guide v4, section 4: Recipes.
///
/// "Show meals before presenting a form." The questionnaire, the introductory
/// paragraph, the busy banner, the card list and the blanket small print are
/// replaced by one body under the title "What looks good?":
///
///   * compact real controls — Quick meals, Use my food, Filters — where
///     Filters opens a sheet with the meal, the time, how many people, foods
///     to leave out, and a way to Diet & allergies;
///   * before asking: an image-led invitation with Find ideas (or, with an
///     empty kitchen, Add food — ideas come from food you have);
///   * after: the first idea as a large card and the rest in a scrolling row;
///     tapping any opens its ingredients, what else it needs, the steps, and
///     the diet and allergy notice in a sheet;
///   * kept ideas beneath.
///
/// Truthfulness: an idea's picture is a photo of an ingredient it really uses
/// from the kitchen, captioned "Uses your …" — never a photo passed off as the
/// dish. With no matching ingredient photo the card is typographic.
///
/// "Use my food" is a real filter: ideas that need nothing beyond the kitchen
/// and the basics. It needs the photo function (2026-09-13.1) to honour it.
void buildStarterEditFlow(App app) {
  app.state('ideasKitchenOnly', bool_.withDefault(false), persisted: true);

  app.raw((project) {
    updateCustomAction(project, name: 'GetMealIdeas', code: _getMealIdeas);
  });

  app.customWidget(
    'RecipesHome',
    parameters: {},
    description:
        'Recipes below the title: quick filters, an invitation or the ideas '
        'themselves as image-led cards, each opening to its details, and kept '
        'ideas.',
    code: _recipesHome,
  );

  final recipes = ff.Pages.recipesPage;
  app.editPage(recipes, (page) {
    for (final key in [
      'Text_gm5ki8ub', // small print (children[6])
      'Container_1acc9yvl', // idea cards (children[5])
      'Container_1cefa6e4', // busy banner (children[4])
      'Button_1yho9lai', // Get ideas (children[3])
      'Container_y4196gur', // the choices questionnaire (children[2])
      'Text_ewomh5xy', // introductory paragraph (children[1])
    ]) {
      page.ensureRemoved(recipes.widgets.byKey(key).single);
    }
    page.ensureInsertedAfter(
      recipes.widgets.byKey('Text_myeufboy').single, // the title
      CustomWidget(widgetName: 'RecipesHome', name: 'RecipesBody', arguments: {}),
    );
  });
}

const _getMealIdeas = r'''
import 'package:supabase_flutter/supabase_flutter.dart';

/// Asks for meal ideas built from the food in this kitchen, soonest-to-go
/// first and shaped by the Recipes filters, and keeps them in app state.
///
/// What to leave out is two things joined: what was typed into "Leave out",
/// and what the person's allergies and diet add. "Use my food" asks for ideas
/// that need nothing beyond the kitchen and the basics.
///
/// Returns '' when there are ideas to show, and otherwise a sentence saying
/// why not. It only runs on a tap: each ask is a Gemini call.
Future<String> getMealIdeas() async {
  const sorry = 'Could not come up with ideas just now. Try again in a minute.';
  final household = FFAppState().currentHouseholdId;
  if (household.isEmpty) {
    return 'No household yet. Create or join one first.';
  }
  // A second tap while the first ask is still thinking.
  if (FFAppState().ideasLoading) return '';

  final leaveOut = [FFAppState().ideasLeaveOut, FFAppState().ideasAvoid]
      .map((w) => w.trim())
      .where((w) => w.isNotEmpty)
      .join(', ');

  FFAppState().update(() => FFAppState().ideasLoading = true);
  try {
    final res = await SupaFlow.client.functions.invoke(
      'recognise-food',
      body: {
        'mode': 'ideas',
        'householdId': household,
        'meal': FFAppState().ideasMeal,
        'minutes': FFAppState().ideasMinutes,
        'servings': FFAppState().ideasServings,
        'leaveOut': leaveOut,
        'kitchenOnly': FFAppState().ideasKitchenOnly,
      },
    );
    final data = res.data;
    if (data is! Map) return sorry;
    if (data['error'] != null) return data['error'].toString();
    final raw = data['ideas'] is List ? data['ideas'] as List : const [];

    List<String> words(Object? v) => v is List
        ? [
            for (final w in v)
              if ('$w'.trim().isNotEmpty) '$w'.trim(),
          ]
        : <String>[];

    final ideas = <MealIdeaStruct>[];
    for (final r in raw) {
      if (r is! Map) continue;
      final title = (r['title'] ?? '').toString().trim();
      final uses = words(r['uses']);
      if (title.isEmpty || uses.isEmpty) continue;
      ideas.add(MealIdeaStruct(
        title: title,
        uses: uses,
        extras: words(r['extras']),
        steps: words(r['steps']),
        minutes: r['minutes'] is num ? (r['minutes'] as num).round() : 0,
        servings: r['servings'] is num ? (r['servings'] as num).round() : 0,
        soon: r['soon'] == true,
      ));
    }
    if (ideas.isEmpty) {
      final note = (data['note'] ?? '').toString();
      return note.isNotEmpty ? note : sorry;
    }
    FFAppState().update(() => FFAppState().mealIdeas = ideas);
    return '';
  } on FunctionException catch (error) {
    final details = error.details;
    if (details is Map && details['error'] != null) {
      return details['error'].toString();
    }
    return sorry;
  } catch (_) {
    return 'Could not reach your kitchen. Check your signal and try again.';
  } finally {
    FFAppState().update(() => FFAppState().ideasLoading = false);
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
            ? [for (final w in v) if ('$w'.trim().isNotEmpty) '$w'.trim()]
            : <String>[];
        kept.add(_Kept(
          m['id'].toString(),
          MealIdeaStruct(
            title: (m['title'] ?? '').toString(),
            uses: words(d['uses']),
            extras: words(d['extras']),
            steps: words(d['steps']),
            minutes: d['minutes'] is num ? (d['minutes'] as num).round() : 0,
            servings: d['servings'] is num ? (d['servings'] as num).round() : 0,
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

  void _say(String text) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(text)));

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
      if (mounted) _say('Could not remove it. Check your signal and try again.');
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
          return (url: '$_food/${e.value}.webp', cue: 'Uses your ${use.toLowerCase()}');
        }
      }
    }
    return null;
  }

  static String _cue(MealIdeaStruct idea) {
    final photo = _ingredientPhoto(idea);
    if (photo != null) return photo.cue;
    if (idea.uses.isNotEmpty) return 'Uses your ${idea.uses.first.toLowerCase()}';
    return '';
  }

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
          _controls(t),
          const SizedBox(height: 16),
          AnimatedSwitcher(
            duration: still ? Duration.zero : const Duration(milliseconds: 220),
            child: KeyedSubtree(
              key: ValueKey(loading ? 'loading' : (ideas.isEmpty ? 'invite' : 'ideas${ideas.length}${ideas.first.title}')),
              child: body,
            ),
          ),
          if (_kept.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text('Kept ideas',
                style: t.titleLarge.copyWith(
                    fontSize: 22, fontWeight: FontWeight.w800, color: _ink)),
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
            FFAppState().update(() => FFAppState().ideasMinutes = quick ? 0 : 30);
          }),
          const SizedBox(width: 8),
          _chip(t, 'Use my food', s.ideasKitchenOnly, Icons.kitchen_outlined, () {
            FFAppState().update(
                () => FFAppState().ideasKitchenOnly = !FFAppState().ideasKitchenOnly);
          }),
          const SizedBox(width: 8),
          _chip(t, active > 0 ? 'Filters · $active' : 'Filters', active > 0,
              Icons.tune, () => _openFilters(t)),
        ],
      ),
    );
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
          final minutes = _times.containsKey(s.ideasMinutes) ? s.ideasMinutes : 0;
          final people = s.ideasServings < 1 ? 2 : (s.ideasServings > 8 ? 8 : s.ideasServings);
          final avoid = s.ideasAvoid.trim();
          void set(void Function() change) {
            FFAppState().update(change);
            redraw(() {});
          }

          return Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(sheet).viewInsets.bottom),
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
                            fontSize: 24, fontWeight: FontWeight.w800, color: _ink)),
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
                        _stepper(Icons.remove, people > 1,
                            () => set(() => FFAppState().ideasServings = people - 1)),
                        SizedBox(
                          width: 84,
                          child: Text(
                              people == 1 ? '1 person' : '$people people',
                              textAlign: TextAlign.center,
                              style: t.titleSmall.copyWith(color: _ink)),
                        ),
                        _stepper(Icons.add, people < 8,
                            () => set(() => FFAppState().ideasServings = people + 1)),
                      ],
                    ),
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
                            const Icon(Icons.no_food_outlined, color: _forest, size: 22),
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
                                    style: t.bodySmall.copyWith(
                                        color: _muted, fontSize: 14),
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
                                color: Colors.white, fontWeight: FontWeight.w700)),
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

  Widget _sheetLabel(FlutterFlowTheme t, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: t.bodyMedium.copyWith(
                color: _muted, fontWeight: FontWeight.w700, fontSize: 14)),
      );

  Widget _choice(FlutterFlowTheme t, String label, bool on, VoidCallback onTap) =>
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
                    empty ? 'Ideas come from your food' : 'Ideas from your food',
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
                      icon: Icon(empty ? Icons.add : Icons.auto_awesome_outlined,
                          size: 20),
                      label: Text(empty ? 'Add food' : 'Find ideas',
                          style: t.bodyLarge.copyWith(
                              color: Colors.white, fontWeight: FontWeight.w700)),
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
              style: t.bodyMedium
                  .copyWith(color: Colors.white.withOpacity(0.9), fontSize: 14)),
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
                        errorBuilder: (_, __, ___) => Container(color: _forest)),
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
      if (kept == null && _cue(idea).isNotEmpty) _cue(idea),
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
                    fontSize: 17, fontWeight: FontWeight.w700, color: _ink, height: 1.2)),
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

  Widget _tap({required String label, required VoidCallback onTap, required Widget child}) =>
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
                            fontSize: 26, fontWeight: FontWeight.w800, color: _ink, height: 1.15)),
                    if (meta.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(meta,
                          style: t.bodyMedium.copyWith(color: _muted, fontSize: 14)),
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
                        style: t.bodySmall.copyWith(color: _muted, fontSize: 13),
                      ),
                    ],
                    if (idea.extras.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _section(t, 'You would also need'),
                      Wrap(spacing: 8, runSpacing: 8, children: [
                        for (final e in idea.extras) _pill(t, e, Colors.white, _ink),
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
                          icon: Icon(listed ? Icons.check : Icons.add_shopping_cart,
                              size: 18),
                          label: Text(
                              listed ? 'On your shopping list' : 'Add to shopping list',
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
                                        fontSize: 16, color: _ink, height: 1.45)),
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
                          const Icon(Icons.info_outline, color: _forest, size: 20),
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
                                      color: _forest, fontWeight: FontWeight.w700)),
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
                                  _isKept(idea) ? Icons.bookmark : Icons.bookmark_border,
                                  size: 20),
                              label: Text(_isKept(idea) ? 'Kept' : 'Keep this idea',
                                  style: t.bodyLarge.copyWith(
                                      color: Colors.white, fontWeight: FontWeight.w700)),
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

  Widget _pill(FlutterFlowTheme t, String text, Color bg, Color fg) => Container(
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
