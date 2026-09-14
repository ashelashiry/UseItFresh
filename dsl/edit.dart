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

/// Fixes from a full review of the new code before phone testing (14 Sep):
/// allergies typed for someone without the app are always saved; "Who's
/// eating" chips change at once; "I ate this" works for each person and
/// "Mark as still to cook" removes your log; whole-word food matching with
/// near matches unticked; leftovers do not use food twice and are planned
/// once; the photo picker never closes the wrong screen; sheets move above the
/// keyboard; titles and servings kept within the table's limits; calendar
/// days rather than 24-hour steps; a retry on Your recipes offline; the
/// receipt date picker opens on misread dates; receipt lengths and item count;
/// product_images rows removed with their picture; controllers disposed after
/// sheets finish closing.
void buildStarterEditFlow(App app) {
  app.raw((project) {
    updateCustomWidget(project, name: 'WeekPlan', code: _weekPlan);
    updateCustomWidget(project, name: 'RecipesHome', code: _recipesHome);
    updateCustomWidget(project, name: 'RecipeCollection', code: _recipeCollection);
    updateCustomWidget(project, name: 'ReceiptHeader', code: _receiptHeader);
    updateCustomWidget(project, name: 'ProductPhotoPicker', code: _productPhotoPicker);
    updateCustomAction(project, name: 'SaveScannedFoods', code: _saveScannedFoods);
    updateCustomAction(project, name: 'ChangeFoodPhoto', code: _changeFoodPhoto);
  });
}

const _weekPlan = r'''
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Plan my week (owner, 14 Sep; a Plus feature).
///
/// The next seven days, one card each. Meals come from ideas already on
/// Recipes or kept ideas, so every plan starts from the food in the kitchen.
/// A planned meal can be swapped, moved, cooked with extra portions for
/// another day, or removed. One button puts everything the week still needs
/// on the shopping list.
///
/// "I ate this" is where planned becomes eaten: portions are confirmed, the
/// meal is logged for this person only, and the foods it used up leave the
/// kitchen — each one can be unticked first, and all of it can be undone.
/// Planned and eaten are kept in separate tables and never mixed.
///
/// Household planning (a Plus feature): who eats at home — everyone in the
/// household, and people without the app such as children — each with a
/// portion size and their allergies. Each planned meal says who is eating, its
/// servings add up from their portions, and a meal that mentions something one
/// of them avoids says so. Ideas found here leave out everyone's allergies.
///
/// Budget (a Plus feature): a weekly amount for the household, what the
/// week's shopping should cost from the last prices paid (receipts, or typed),
/// what receipts say was spent in the last seven days, and a price on each
/// idea when adding a meal. Always "about", and honest about missing prices.
///
/// Your day (with "Fits my goals" on): today's estimated calories and
/// protein from the meals this person marked as eaten, against targets
/// they choose. Private to them, and never shown to anyone who has not
/// turned goals on.
class WeekPlan extends StatefulWidget {
  const WeekPlan({super.key, this.width, this.height});

  final double? width;
  final double? height;

  @override
  State<WeekPlan> createState() => _WeekPlanState();
}

class _Entry {
  _Entry(Map m)
      : id = m['id'].toString(),
        date = DateTime.parse(m['plan_date'].toString()),
        meal = (m['meal'] ?? 'dinner').toString(),
        title = (m['title'] ?? '').toString(),
        data = m['recipe_data'] is Map ? m['recipe_data'] as Map : const {},
        servings = m['servings'] is num ? (m['servings'] as num).round() : 2,
        extra = m['extra_portions'] is num
            ? (m['extra_portions'] as num).round()
            : 0,
        status = (m['status'] ?? 'planned').toString();

  final String id;
  final DateTime date;
  final String meal;
  final String title;
  final Map data;
  final int servings;
  final int extra;
  final String status;

  List<String> list(String key) => data[key] is List
      ? [
          for (final w in data[key] as List)
            if ('$w'.trim().isNotEmpty) '$w'.trim()
        ]
      : <String>[];
  int number(String key) => data[key] is num ? (data[key] as num).round() : 0;
}

class _WeekPlanState extends State<WeekPlan> {
  static const _forest = Color(0xFF07533A);
  static const _ink = Color(0xFF202C24);
  static const _muted = Color(0xFF59665D);
  static const _sage = Color(0xFFEDF2E8);
  static const _border = Color(0xFFDCE3D7);
  static const _cream = Color(0xFFF7F7F0);
  static const _red = Color(0xFFB42318);

  static const _meals = <String, String>{
    'breakfast': 'Breakfast',
    'lunch': 'Lunch',
    'dinner': 'Dinner',
    'snack': 'Snack',
  };
  static const _mealOrder = ['breakfast', 'lunch', 'dinner', 'snack'];
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
  bool _busy = false;
  List<_Entry> _entries = const [];
  List<MealIdeaStruct> _kept = const [];
  // Your day: what this person ate today, and their own targets.
  List<Map> _eaten = const [];
  int? _kcalTarget;
  int? _proteinTarget;
  bool _targetsReady = true;
  // Budget: the household's weekly amount, known prices, recent spending.
  double? _budget;
  String _currency = 'AUD';
  final Map<String, double> _prices = {};
  double _spent = 0;
  bool _budgetReady = true;
  // Household planning: who eats at home, and who eats each planned meal.
  List<Map> _diners = const [];
  final Map<String, Map<String, double>> _plates = {};
  bool _dinersReady = true;

  static DateTime get _today {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  static String _iso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// "today", "tomorrow" or "Wed 17 Sep", for the middle of a sentence.
  static String _onDay(DateTime d) {
    final name = _dayName(d);
    return name == 'Today' || name == 'Tomorrow' ? name.toLowerCase() : name;
  }

  static DateTime _dayAt(int i) =>
      DateTime(_today.year, _today.month, _today.day + i);

  /// Whole-word match either way ("egg" in "Free-range eggs"), so "egg" is
  /// never "eggplant" and "milk" never "coconut milk" alone.
  static bool _wordIn(String hay, String word) {
    final w = word.trim().toLowerCase();
    if (w.length < 2) return false;
    return RegExp('(^|[^a-z])${RegExp.escape(w)}(es|s)?([^a-z]|\$)')
        .hasMatch(hay.toLowerCase());
  }

  static String _dayName(DateTime d) {
    final diff = DateTime.utc(d.year, d.month, d.day)
        .difference(DateTime.utc(_today.year, _today.month, _today.day))
        .inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    return '${_days[d.weekday - 1]} ${d.day} ${_months[d.month - 1]}';
  }

  // ---- data ----------------------------------------------------------------

  Future<void> _load(String household, {bool quiet = false}) async {
    if (!quiet && mounted) {
      setState(() {
        _loading = true;
        _offline = false;
      });
    }
    try {
      final rows = await SupaFlow.client
          .from('meal_plan_entries')
          .select(
              'id, plan_date, meal, title, recipe_data, servings, extra_portions, status')
          .eq('household_id', household)
          .gte('plan_date', _iso(_today))
          .lte('plan_date', _iso(_dayAt(6)))
          .order('plan_date');
      final kept = await SupaFlow.client
          .from('saved_recipes')
          .select('title, recipe_data')
          .eq('household_id', household)
          .order('created_at', ascending: false)
          .limit(20);
      final entries = [for (final r in rows as List) _Entry(r as Map)]
        ..sort((a, b) {
          final byDay = a.date.compareTo(b.date);
          return byDay != 0
              ? byDay
              : _mealOrder
                  .indexOf(a.meal)
                  .compareTo(_mealOrder.indexOf(b.meal));
        });
      final ideas = <MealIdeaStruct>[];
      for (final r in kept as List) {
        final m = r as Map;
        final d = m['recipe_data'] is Map ? m['recipe_data'] as Map : const {};
        ideas.add(_idea((m['title'] ?? '').toString(), d));
      }
      if (!mounted || household != _for) return;
      setState(() {
        _entries = entries;
        _kept = ideas;
        _loading = false;
        _offline = false;
        _notReady = false;
      });
      _loadDay();
      _loadBudget();
      _loadDiners(seed: true);
    } on PostgrestException catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        // The table is created by a one-off database step.
        _notReady = error.code == '42P01' || error.code == 'PGRST205';
        _offline = !_notReady;
      });
    } catch (_) {
      if (!mounted) return;
      if (quiet && _entries.isNotEmpty) return;
      setState(() {
        _loading = false;
        _offline = true;
      });
    }
  }

  Future<void> _loadDay() async {
    final uid = SupaFlow.client.auth.currentUser?.id;
    if (uid == null) return;
    try {
      final log = await SupaFlow.client
          .from('meal_log_entries')
          .select(
              'id, meal, title, portions, calories_per_serving, protein_per_serving, plan_entry_id, household_id')
          .eq('profile_id', uid)
          .eq('eaten_on', _iso(DateTime.now()))
          .order('created_at');
      Map? settings;
      var ready = true;
      try {
        settings = await SupaFlow.client
            .from('user_settings')
            .select('daily_calorie_target, daily_protein_target')
            .eq('profile_id', uid)
            .maybeSingle();
      } on PostgrestException {
        ready = false;
      }
      if (!mounted) return;
      int? whole(Object? v) => v is num ? v.round() : null;
      setState(() {
        _eaten = [for (final r in log as List) r as Map];
        _kcalTarget = whole(settings?['daily_calorie_target']);
        _proteinTarget = whole(settings?['daily_protein_target']);
        _targetsReady = ready;
      });
    } catch (_) {
      // Your day is extra: the plan still shows without it.
    }
  }

  static double _portions(Map r) =>
      r['portions'] is num ? (r['portions'] as num).toDouble() : 1;

  int get _kcalToday => _eaten
      .fold<double>(
          0,
          (sum, r) =>
              sum +
              (r['calories_per_serving'] is num
                      ? (r['calories_per_serving'] as num).toDouble()
                      : 0) *
                  _portions(r))
      .round();

  int get _proteinToday => _eaten
      .fold<double>(
          0,
          (sum, r) =>
              sum +
              (r['protein_per_serving'] is num
                      ? (r['protein_per_serving'] as num).toDouble()
                      : 0) *
                  _portions(r))
      .round();

  Future<void> _unlog(Map r) async {
    try {
      await SupaFlow.client
          .from('meal_log_entries')
          .delete()
          .eq('id', r['id'].toString());
      await _loadDay();
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      final back = Map<String, dynamic>.from(r)..remove('id');
      messenger.showSnackBar(SnackBar(
        content: const Text('Taken off your day. Your kitchen is unchanged.'),
        action: SnackBarAction(
          label: 'Undo',
          textColor: const Color(0xFFB9E08F),
          onPressed: () async {
            try {
              await SupaFlow.client.from('meal_log_entries').insert({
                ...back,
                'profile_id': SupaFlow.client.auth.currentUser?.id,
                'eaten_on': _iso(DateTime.now()),
              });
              if (mounted) _loadDay();
            } catch (_) {
              messenger.showSnackBar(const SnackBar(
                  content: Text('Could not undo. Check your signal.')));
            }
          },
        ),
      ));
    } catch (_) {
      if (mounted) _say('Could not change your day. Check your signal.');
    }
  }

  Future<void> _openTargets(FlutterFlowTheme t) async {
    if (!_targetsReady) {
      _say('Daily targets are almost ready. Try again soon.');
      return;
    }
    var kcal = _kcalTarget ?? 2000;
    var protein = _proteinTarget ?? 60;
    final choice = await _sheet<String>((sheet, redraw) {
      Widget row(String label, String value, VoidCallback less,
              VoidCallback more, bool canLess, bool canMore) =>
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Expanded(child: _label(t, label)),
                _stepper(Icons.remove, canLess, less),
                SizedBox(
                  width: 96,
                  child: Text(value,
                      textAlign: TextAlign.center,
                      style: t.titleSmall.copyWith(color: _ink)),
                ),
                _stepper(Icons.add, canMore, more),
              ],
            ),
          );
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Your daily targets',
              style: t.headlineSmall.copyWith(
                  fontSize: 24, fontWeight: FontWeight.w800, color: _ink)),
          const SizedBox(height: 4),
          Text('Your own numbers, private to you.',
              style: t.bodyLarge.copyWith(color: _muted, fontSize: 16)),
          const SizedBox(height: 20),
          row('Calories', '$kcal kcal', () => redraw(() => kcal -= 50),
              () => redraw(() => kcal += 50), kcal > 1000, kcal < 4500),
          row('Protein', '$protein g', () => redraw(() => protein -= 5),
              () => redraw(() => protein += 5), protein > 0, protein < 300),
          Text(
              'Not medical or diet advice. A dietitian or doctor can suggest targets that suit you.',
              style: t.bodySmall.copyWith(color: _muted, fontSize: 13)),
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
              onPressed: () => Navigator.of(sheet).pop('save'),
              child: Text('Save targets',
                  style: t.bodyLarge.copyWith(
                      color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ),
          if (_kcalTarget != null || _proteinTarget != null)
            TextButton(
              style: TextButton.styleFrom(
                  minimumSize: const Size(48, 48), foregroundColor: _forest),
              onPressed: () => Navigator.of(sheet).pop('clear'),
              child: Text('No targets, just totals',
                  style: t.bodyLarge
                      .copyWith(color: _forest, fontWeight: FontWeight.w700)),
            ),
        ],
      );
    });
    if (choice == null || !mounted) return;
    final uid = SupaFlow.client.auth.currentUser?.id;
    try {
      await SupaFlow.client.from('user_settings').upsert({
        'profile_id': uid,
        'daily_calorie_target': choice == 'save' ? kcal : null,
        'daily_protein_target': choice == 'save' ? protein : null,
      });
      await _loadDay();
      if (mounted) {
        _say(choice == 'save' ? 'Targets saved.' : 'Targets cleared.');
      }
    } catch (_) {
      if (mounted) _say('Could not save your targets. Check your signal.');
    }
  }

  static String _thousands(int n) {
    final s = n.abs().toString();
    final b = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
      b.write(s[i]);
    }
    return n < 0 ? '-$b' : b.toString();
  }

  Widget _dayProgress(FlutterFlowTheme t) {
    final kcal = _kcalToday;
    final protein = _proteinToday;
    Widget bar(String text, int value, int? target, String unit) {
      final over = target != null && value > target;
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
                target == null
                    ? '${_thousands(value)} $unit so far'
                    : (over
                        ? '${_thousands(value)} $unit · ${_thousands(value - target)} over your $text target'
                        : '${_thousands(value)} of ${_thousands(target)} $unit'),
                style: t.bodyLarge.copyWith(
                    fontWeight: FontWeight.w700, color: _ink, fontSize: 16)),
            if (target != null && target > 0) ...[
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: (value / target).clamp(0.0, 1.0),
                  minHeight: 10,
                  backgroundColor: Colors.white,
                  valueColor: AlwaysStoppedAnimation(
                      over ? const Color(0xFFB54708) : _forest),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 14),
      decoration: BoxDecoration(
        color: _sage,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Your day',
                    style: t.titleMedium.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: _ink)),
              ),
              TextButton(
                style: TextButton.styleFrom(
                    minimumSize: const Size(48, 44), foregroundColor: _forest),
                onPressed: () => _openTargets(t),
                child: Text(
                    _kcalTarget == null && _proteinTarget == null
                        ? 'Set targets'
                        : 'Change targets',
                    style: t.bodyMedium
                        .copyWith(color: _forest, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                bar('calorie', kcal, _kcalTarget, 'kcal'),
                bar('protein', protein, _proteinTarget, 'g protein'),
                const SizedBox(height: 12),
                if (_eaten.isEmpty)
                  Text(
                      'Nothing logged today. Open a planned meal and tap «I ate this».',
                      style: t.bodyMedium.copyWith(color: _muted, fontSize: 14))
                else
                  for (final r in _eaten)
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                              '${r['title']} · ${_portions(r) == 1 ? '1 portion' : '${_portions(r) == _portions(r).roundToDouble() ? _portions(r).round() : _portions(r)} portions'}${r['calories_per_serving'] is num ? ' · ${((r['calories_per_serving'] as num) * _portions(r)).round()} kcal' : ''}',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: t.bodyMedium
                                  .copyWith(color: _ink, fontSize: 14)),
                        ),
                        IconButton(
                          tooltip: 'Take off your day',
                          onPressed: () => _unlog(r),
                          icon:
                              const Icon(Icons.close, color: _muted, size: 20),
                        ),
                      ],
                    ),
                const SizedBox(height: 4),
                Text(
                    'Estimated from the meals you marked as eaten. A guide only, not diet or medical advice.',
                    style: t.bodySmall.copyWith(color: _muted, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static MealIdeaStruct _idea(String title, Map d) {
    List<String> words(Object? v) => v is List
        ? [
            for (final w in v)
              if ('$w'.trim().isNotEmpty) '$w'.trim()
          ]
        : <String>[];
    int n(Object? v) => v is num ? v.round() : 0;
    return MealIdeaStruct(
      title: title,
      uses: words(d['uses']),
      extras: words(d['extras']),
      steps: words(d['steps']),
      minutes: n(d['minutes']),
      servings: n(d['servings']),
      calories: n(d['calories']),
      protein: n(d['protein']),
    );
  }

  static Map<String, dynamic> _data(MealIdeaStruct idea) => {
        'uses': idea.uses,
        'extras': idea.extras,
        'steps': idea.steps,
        'minutes': idea.minutes,
        if (idea.calories > 0) 'calories': idea.calories,
        if (idea.protein > 0) 'protein': idea.protein,
      };

  void _say(String text, {SnackBarAction? action}) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(text),
          action: action,
          duration: Duration(seconds: action == null ? 4 : 6)));

  String _why(Object error) {
    if (error is PostgrestException && error.code == '42501') {
      return 'Your account is not allowed to change this household’s plan.';
    }
    return 'Could not save that. Check your signal and try again.';
  }

  Future<bool> _write(Future<void> Function() change) async {
    if (_busy) return false;
    setState(() => _busy = true);
    try {
      await change();
      await _load(_for, quiet: true);
      return true;
    } catch (error) {
      if (mounted) _say(_why(error));
      return false;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _add(DateTime day, String meal, MealIdeaStruct idea) async {
    final people = FFAppState().ideasServings;
    final ok =
        await _write(() => SupaFlow.client.from('meal_plan_entries').insert({
              'household_id': _for,
              'plan_date': _iso(day),
              'meal': meal,
              'title': idea.title.length > 120
                  ? idea.title.substring(0, 120)
                  : idea.title,
              'recipe_data': _data(idea),
              'servings': idea.servings > 0
                  ? idea.servings.clamp(1, 12)
                  : (people < 1 ? 2 : (people > 12 ? 12 : people)),
              'created_by': SupaFlow.client.auth.currentUser?.id,
            }));
    if (ok && mounted) _say('${idea.title} planned for ${_onDay(day)}.');
  }

  Future<void> _swap(_Entry entry, MealIdeaStruct idea) async {
    final ok = await _write(() => SupaFlow.client
        .from('meal_plan_entries')
        .update({
          'title': idea.title.length > 120
              ? idea.title.substring(0, 120)
              : idea.title,
          'recipe_data': _data(idea)
        }).eq(
            'id', entry.id));
    if (ok && mounted) _say('Swapped for ${idea.title}.');
  }

  Future<void> _update(_Entry entry, Map<String, dynamic> change) =>
      _write(() => SupaFlow.client
          .from('meal_plan_entries')
          .update(change)
          .eq('id', entry.id));

  Future<void> _remove(_Entry entry) async {
    final ok = await _write(() =>
        SupaFlow.client.from('meal_plan_entries').delete().eq('id', entry.id));
    if (ok && mounted) _say('${entry.title} taken off the plan.');
  }

  /// Cook once, eat twice: the leftovers become a lunch the next day.
  Future<void> _planLeftovers(_Entry entry) async {
    final next = DateTime(entry.date.year, entry.date.month, entry.date.day + 1);
    final ok =
        await _write(() => SupaFlow.client.from('meal_plan_entries').insert({
              'household_id': _for,
              'plan_date': _iso(next),
              'meal': 'lunch',
              'title': 'Leftover ${entry.title}'.length > 120
                  ? entry.title
                  : 'Leftover ${entry.title}',
              'recipe_data': {
                ...entry.data,
                'uses': <String>[],
                'extras': <String>[],
                'leftoverOf': entry.id,
                'steps': [
                  'Reheat the extra portions from ${_dayName(entry.date)}.'
                ],
              },
              'servings': entry.extra.clamp(1, 12),
              'created_by': SupaFlow.client.auth.currentUser?.id,
            }));
    if (ok && mounted) _say('Leftovers planned for ${_onDay(next)}’s lunch.');
  }

  /// Everything the planned meals still need, once each.
  List<String> get _needed {
    final seen = <String>{};
    final out = <String>[];
    for (final e in _entries.where((e) => e.status == 'planned')) {
      for (final x in e.list('extras')) {
        if (seen.add(x.toLowerCase())) out.add(x);
      }
    }
    return out;
  }

  Future<void> _loadBudget() async {
    final household = _for;
    if (household.isEmpty) return;
    try {
      final budget = await SupaFlow.client
          .from('household_budgets')
          .select('weekly_amount, currency')
          .eq('household_id', household)
          .maybeSingle();
      final prices = await SupaFlow.client
          .from('known_prices')
          .select('name_key, price, currency')
          .eq('household_id', household)
          .limit(1000);
      final since = DateTime.now().subtract(const Duration(days: 7));
      final receipts = await SupaFlow.client
          .from('receipts')
          .select('total_amount, purchased_at, scanned_at')
          .eq('household_id', household)
          .gte('scanned_at', since.toUtc().toIso8601String());
      if (!mounted || household != _for) return;
      var spent = 0.0;
      for (final r in receipts as List) {
        final m = r as Map;
        if (m['total_amount'] is num)
          spent += (m['total_amount'] as num).toDouble();
      }
      setState(() {
        _budget = budget?['weekly_amount'] is num
            ? (budget!['weekly_amount'] as num).toDouble()
            : null;
        _currency = '${budget?['currency'] ?? 'AUD'}';
        _prices
          ..clear()
          ..addEntries([
            for (final p in prices as List)
              if ((p as Map)['price'] is num)
                MapEntry('${p['name_key']}', (p['price'] as num).toDouble()),
          ]);
        _spent = spent;
        _budgetReady = true;
      });
    } on PostgrestException {
      if (mounted) setState(() => _budgetReady = false);
    } catch (_) {}
  }

  /// The last price paid for something, matched on its name.
  double? _priceOf(String name) {
    final key = name.trim().toLowerCase();
    if (key.isEmpty) return null;
    final exact = _prices[key];
    if (exact != null) return exact;
    for (final e in _prices.entries) {
      if (e.key.length > 2 && (key.contains(e.key) || e.key.contains(key))) {
        return e.value;
      }
    }
    return null;
  }

  String _money(double amount) {
    const symbols = {
      'AUD': r'$',
      'NZD': r'$',
      'USD': r'$',
      'CAD': r'$',
      'GBP': '£',
      'EUR': '€'
    };
    final symbol = symbols[_currency] ?? '$_currency ';
    return amount >= 100
        ? '$symbol${amount.round()}'
        : '$symbol${amount.toStringAsFixed(2)}';
  }

  /// About what an idea's missing things cost, and how many have no price.
  (double, int) _costOf(List<String> extras) {
    var sum = 0.0;
    var unknown = 0;
    for (final x in extras) {
      final p = _priceOf(x);
      if (p == null) {
        unknown++;
      } else {
        sum += p;
      }
    }
    return (sum, unknown);
  }

  Future<void> _openBudget(FlutterFlowTheme t, List<String> needed) async {
    if (!_budgetReady) {
      _say('Budgets are almost ready. Try again soon.');
      return;
    }
    final amount = TextEditingController(
        text: _budget == null ? '' : _budget!.toStringAsFixed(0));
    final unpriced = [
      for (final n in needed)
        if (_priceOf(n) == null) n
    ];
    final typed = {for (final n in unpriced) n: TextEditingController()};
    InputDecoration look(String label) => InputDecoration(
          labelText: label,
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
      builder: (sheet) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(sheet).viewInsets.bottom),
        child: ConstrainedBox(
          constraints: BoxConstraints(
              maxHeight: MediaQuery.of(sheet).size.height * 0.88),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Weekly budget',
                      style: t.headlineSmall.copyWith(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: _ink)),
                  const SizedBox(height: 4),
                  Text('For the whole household’s food shopping.',
                      style: t.bodyLarge.copyWith(color: _muted, fontSize: 16)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: amount,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: look('Amount a week ($_currency)'),
                  ),
                  if (unpriced.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _label(t, 'Prices we don’t know yet'),
                    Text(
                        'Scanning receipts fills these in. Or type what you usually pay.',
                        style:
                            t.bodySmall.copyWith(color: _muted, fontSize: 13)),
                    const SizedBox(height: 8),
                    for (final n in unpriced)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: TextField(
                          controller: typed[n],
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: look(n),
                        ),
                      ),
                  ],
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
                      onPressed: () => Navigator.of(sheet).pop(true),
                      child: Text('Save',
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
    );
    double? number(String s) =>
        double.tryParse(s.replaceAll(RegExp(r'[^0-9.]'), ''));
    final weekly = number(amount.text);
    final newPrices = <Map<String, dynamic>>[
      for (final e in typed.entries)
        if ((number(e.value.text) ?? 0) > 0)
          {
            'household_id': _for,
            'name_key': e.key.trim().toLowerCase(),
            'display_name': e.key.trim(),
            'price': (number(e.value.text)! * 100).round() / 100,
            'currency': _currency,
            'source': 'typed',
            'seen_at': DateTime.now().toUtc().toIso8601String(),
          }
    ];
    Future.delayed(const Duration(milliseconds: 500), amount.dispose);
    Future.delayed(const Duration(milliseconds: 500), () {
      for (final c in typed.values) {
        c.dispose();
      }
    });
    if (save != true || !mounted) return;
    try {
      await SupaFlow.client.from('household_budgets').upsert({
        'household_id': _for,
        'weekly_amount': weekly,
        'currency': _currency,
        'updated_by': SupaFlow.client.auth.currentUser?.id,
      });
      if (newPrices.isNotEmpty) {
        await SupaFlow.client
            .from('known_prices')
            .upsert(newPrices, onConflict: 'household_id,name_key');
      }
      await _loadBudget();
      if (mounted) _say('Budget saved.');
    } catch (_) {
      if (mounted) _say('Could not save the budget. Check your signal.');
    }
  }

  Widget _budgetCard(FlutterFlowTheme t, List<String> needed) {
    final (cost, unknown) = _costOf(needed);
    final budget = _budget;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Budget',
                    style: t.titleMedium.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: _ink)),
              ),
              TextButton(
                style: TextButton.styleFrom(
                    minimumSize: const Size(48, 44), foregroundColor: _forest),
                onPressed: () => _openBudget(t, needed),
                child: Text(budget == null ? 'Set a weekly budget' : 'Change',
                    style: t.bodyMedium
                        .copyWith(color: _forest, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                    needed.isEmpty
                        ? 'The planned meals need nothing to buy.'
                        : 'About ${_money(cost)} to buy for the planned meals${budget == null ? '' : ', of ${_money(budget)} a week'}.',
                    style: t.bodyLarge.copyWith(
                        fontWeight: FontWeight.w700,
                        color: _ink,
                        fontSize: 16)),
                if (budget != null && budget > 0) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: ((cost + _spent) / budget).clamp(0.0, 1.0),
                      minHeight: 10,
                      backgroundColor: _sage,
                      valueColor: AlwaysStoppedAnimation(
                          (cost + _spent) > budget
                              ? const Color(0xFFB54708)
                              : _forest),
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                    [
                      if (_spent > 0)
                        '${_money(_spent)} spent in the last 7 days, from receipts.',
                      if (budget != null && (cost + _spent) > budget)
                        'That is about ${_money(cost + _spent - budget)} over the budget. Swapping a meal for one that uses only your food helps.',
                      if (unknown > 0)
                        '${unknown == 1 ? '1 thing has' : '$unknown things have'} no price yet, so it may cost more.',
                      'Estimated from the last prices you paid. Prices change.',
                    ].join(' '),
                    style: t.bodySmall.copyWith(color: _muted, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
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

  static double _portionOf(Object? v) => v is num ? v.toDouble() : 1;

  static String _portionName(double p) =>
      p <= 0.5 ? 'small' : (p >= 1.5 ? 'large' : 'regular');

  Future<void> _loadDiners({bool seed = false}) async {
    final household = _for;
    if (household.isEmpty) return;
    try {
      if (seed) await _seedMembers(household);
      final diners = await SupaFlow.client
          .from('household_diners')
          .select('id, profile_id, name, default_portion, allergens')
          .eq('household_id', household)
          .order('created_at');
      final ids = [for (final e in _entries) e.id];
      final plates = ids.isEmpty
          ? const []
          : await SupaFlow.client
              .from('meal_plan_diners')
              .select('plan_entry_id, diner_id, portions')
              .inFilter('plan_entry_id', ids);
      if (!mounted || household != _for) return;
      final list = [for (final d in diners as List) d as Map];
      setState(() {
        _diners = list;
        _plates.clear();
        for (final p in plates as List) {
          final m = p as Map;
          _plates.putIfAbsent(
                  '${m['plan_entry_id']}', () => {})['${m['diner_id']}'] =
              _portionOf(m['portions']);
        }
        _dinersReady = true;
      });
      // Ideas found for the household leave out everyone's allergies.
      final avoid = <String>{
        for (final d in list)
          ..._words(d['allergens']).map((a) => a.toLowerCase())
      }.join(', ');
      if (FFAppState().ideasHouseholdAvoid != avoid) {
        FFAppState().update(() => FFAppState().ideasHouseholdAvoid = avoid);
      }
    } on PostgrestException {
      if (mounted) setState(() => _dinersReady = false);
    } catch (_) {}
  }

  /// Everyone in the household with an account is someone who eats at home.
  /// Their name and allergies follow their own profile.
  Future<void> _seedMembers(String household) async {
    final members = await SupaFlow.client
        .from('household_members')
        .select('profile_id')
        .eq('household_id', household);
    final ids = [
      for (final m in members as List) '${(m as Map)['profile_id']}'
    ];
    if (ids.isEmpty) return;
    final profiles = await SupaFlow.client
        .from('profiles')
        .select('id, display_name, allergens, dietary_preferences')
        .inFilter('id', ids);
    final existing = await SupaFlow.client
        .from('household_diners')
        .select('id, profile_id, name, allergens')
        .eq('household_id', household)
        .not('profile_id', 'is', null);
    final byProfile = {
      for (final d in existing as List) '${(d as Map)['profile_id']}': d
    };
    for (final p in profiles as List) {
      final m = p as Map;
      final id = '${m['id']}';
      final name = '${m['display_name'] ?? ''}'.trim();
      final allergens = _words(m['allergens']);
      final had = byProfile[id];
      if (had == null) {
        await SupaFlow.client.from('household_diners').upsert({
          'household_id': household,
          'profile_id': id,
          'name': name.isEmpty ? 'Someone' : name,
          'allergens': allergens,
          'dietary_preferences': _words(m['dietary_preferences']),
          'created_by': SupaFlow.client.auth.currentUser?.id,
        }, onConflict: 'household_id,profile_id', ignoreDuplicates: true);
      } else if (_words(had['allergens']).join(',') != allergens.join(',') ||
          (name.isNotEmpty && '${had['name']}' != name)) {
        await SupaFlow.client.from('household_diners').update({
          if (name.isNotEmpty) 'name': name,
          'allergens': allergens,
        }).eq('id', '${had['id']}');
      }
    }
  }

  /// Who eats this meal, by name, or '' when nobody has been chosen.
  String _eaters(_Entry e) {
    final plate = _plates[e.id];
    if (plate == null || plate.isEmpty) return '';
    return [
      for (final d in _diners)
        if (plate.containsKey('${d['id']}'))
          '${d['name']}${plate['${d['id']}']! <= 0.5 ? ' (small)' : ''}'
    ].join(', ');
  }

  /// "Mia avoids eggs" for each eater whose allergy the meal mentions.
  List<String> _clashes(_Entry e) {
    final plate = _plates[e.id];
    final eaters = [
      for (final d in _diners)
        if (plate == null || plate.isEmpty || plate.containsKey('${d['id']}')) d
    ];
    final text = [e.title, ...e.list('uses'), ...e.list('extras')]
        .join('\n')
        .toLowerCase();
    return [
      for (final d in eaters)
        for (final a in _words(d['allergens']))
          if (_stem(a).length > 1 && text.contains(_stem(a)))
            '${d['name']} avoids ${a.toLowerCase()}'
    ];
  }

  Future<void> _setEater(_Entry e, Map d, bool eating) async {
    final dinerId = '${d['id']}';
    try {
      if (eating) {
        await SupaFlow.client.from('meal_plan_diners').upsert({
          'plan_entry_id': e.id,
          'diner_id': dinerId,
          'household_id': _for,
          'portions': _portionOf(d['default_portion']),
        });
      } else {
        await SupaFlow.client
            .from('meal_plan_diners')
            .delete()
            .eq('plan_entry_id', e.id)
            .eq('diner_id', dinerId);
      }
      final plate = Map<String, double>.of(_plates[e.id] ?? {});
      if (eating) {
        plate[dinerId] = _portionOf(d['default_portion']);
      } else {
        plate.remove(dinerId);
      }
      if (mounted) setState(() => _plates[e.id] = plate);
      if (plate.isNotEmpty) {
        final total = plate.values.fold<double>(0, (a, b) => a + b);
        await SupaFlow.client
            .from('meal_plan_entries')
            .update({'servings': total.ceil().clamp(1, 12)}).eq('id', e.id);
      }
      await _load(_for, quiet: true);
    } catch (_) {
      if (mounted) _say('Could not change who is eating. Check your signal.');
    }
  }

  Future<void> _openDiners(FlutterFlowTheme t) async {
    if (!_dinersReady) {
      _say('Household planning is almost ready. Try again soon.');
      return;
    }
    final name = TextEditingController();
    // Allergy text typed but not yet saved, by diner id.
    final edits = <String, String>{};
    List<String> allergyList(String v) => [
          for (final a in v.split(RegExp(r'[,;\n]')))
            if (a.trim().length > 1) a.trim()
        ];
    await _sheet<void>((sheet, redraw) {
      Future<void> change(Future<void> Function() write) async {
        try {
          await write();
          await _loadDiners();
        } catch (_) {
          if (mounted) _say('Could not save that. Check your signal.');
        }
        try {
          redraw(() {});
        } catch (_) {}
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Who eats at home',
              style: t.headlineSmall.copyWith(
                  fontSize: 24, fontWeight: FontWeight.w800, color: _ink)),
          const SizedBox(height: 4),
          Text(
              'Portions add up to a meal’s servings. Allergies are left out of ideas found for the household.',
              style: t.bodyMedium.copyWith(color: _muted, fontSize: 14)),
          const SizedBox(height: 16),
          for (final d in _diners)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text('${d['name']}',
                            style: t.bodyLarge.copyWith(
                                fontWeight: FontWeight.w700, color: _ink)),
                      ),
                      if (d['profile_id'] == null)
                        IconButton(
                          tooltip: 'Remove ${d['name']}',
                          icon: const Icon(Icons.close, color: _muted),
                          onPressed: () => change(() => SupaFlow.client
                              .from('household_diners')
                              .delete()
                              .eq('id', '${d['id']}')),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    for (final p in const [0.5, 1.0, 1.5])
                      _choice(
                          t,
                          p == 0.5
                              ? 'Small portion'
                              : (p == 1.0 ? 'Regular' : 'Large portion'),
                          _portionName(_portionOf(d['default_portion'])) ==
                              _portionName(p),
                          () => change(() => SupaFlow.client
                              .from('household_diners')
                              .update({'default_portion': p}).eq(
                                  'id', '${d['id']}'))),
                  ]),
                  const SizedBox(height: 6),
                  if (d['profile_id'] == null)
                    TextFormField(
                      key: ValueKey('allergy-${d['id']}'),
                      initialValue: _words(d['allergens']).join(', '),
                      onChanged: (v) => edits['${d['id']}'] = v,
                      decoration: const InputDecoration(
                          labelText: 'Allergies or foods to avoid',
                          hintText: 'e.g. peanuts, eggs'),
                      onFieldSubmitted: (v) {
                        edits.remove('${d['id']}');
                        change(() => SupaFlow.client
                            .from('household_diners')
                            .update({'allergens': allergyList(v)}).eq(
                                'id', '${d['id']}'));
                      },
                    )
                  else
                    Text(
                        _words(d['allergens']).isEmpty
                            ? 'No allergies saved in their profile'
                            : 'Avoids ${_words(d['allergens']).join(', ')} (from their profile)',
                        style:
                            t.bodySmall.copyWith(color: _muted, fontSize: 13)),
                ],
              ),
            ),
          const SizedBox(height: 8),
          _label(t, 'Add someone without the app'),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: name,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(hintText: 'Name, e.g. Mia'),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: _forest,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(64, 48),
                ),
                onPressed: () {
                  final n = name.text.trim();
                  if (n.isEmpty) return;
                  name.clear();
                  change(() => SupaFlow.client.from('household_diners').insert({
                        'household_id': _for,
                        'name': n,
                        'created_by': SupaFlow.client.auth.currentUser?.id,
                      }));
                },
                child: const Text('Add'),
              ),
            ],
          ),
        ],
      );
    });
    Future.delayed(const Duration(milliseconds: 500), name.dispose);
    if (edits.isNotEmpty) {
      try {
        for (final e in edits.entries) {
          await SupaFlow.client
              .from('household_diners')
              .update({'allergens': allergyList(e.value)}).eq('id', e.key);
        }
        await _loadDiners();
      } catch (_) {
        if (mounted) _say('Could not save the allergies. Check your signal.');
      }
    }
  }

  Widget _dinersCard(FlutterFlowTheme t) {
    final names = [
      for (final d in _diners)
        '${d['name']}${_portionOf(d['default_portion']) <= 0.5 ? ' (small)' : ''}'
    ];
    return Semantics(
      button: true,
      label: 'Who eats at home',
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openDiners(t),
        child: Container(
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _border),
          ),
          child: Row(
            children: [
              const Icon(Icons.groups_outlined, color: _forest, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Who eats at home',
                        style: t.bodyLarge.copyWith(
                            fontWeight: FontWeight.w700, color: _ink)),
                    Text(
                        names.isEmpty
                            ? 'Add the people you cook for'
                            : names.join(', '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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

  Future<void> _shop() async {
    final needed = _needed;
    if (needed.isEmpty || _busy) return;
    setState(() => _busy = true);
    var added = 0;
    try {
      for (final name in needed) {
        final said = await addNameToShoppingList(name);
        if (said.isNotEmpty) {
          if (mounted) _say(said);
          return;
        }
        added++;
      }
      if (mounted) {
        _say(added == 1
            ? '1 thing is on your shopping list.'
            : '$added things are on your shopping list.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ---- page ----------------------------------------------------------------

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

    Widget content;
    if (household.isEmpty) {
      content = _message(t, Icons.group_outlined, 'No household yet.',
          'Create or join a household first, then plan meals together.', null);
    } else if (_loading) {
      content = Column(children: [
        for (var i = 0; i < 4; i++) ...[
          Container(
            height: 96,
            decoration: BoxDecoration(
                color: _sage, borderRadius: BorderRadius.circular(20)),
          ),
          const SizedBox(height: 12),
        ],
      ]);
    } else if (_notReady) {
      content = _message(
          t,
          Icons.construction_outlined,
          'Plan my week is almost ready.',
          'It needs one more setup step on our side. Try again soon.',
          () => _load(_for));
    } else if (_offline) {
      content = _message(
          t,
          Icons.cloud_off_outlined,
          'Can’t reach your plan.',
          'No signal, or the connection dropped. Try again when you are back online.',
          () => _load(_for));
    } else {
      final needed = _needed;
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (FFAppState().ideasGoals) ...[
            _dayProgress(t),
            const SizedBox(height: 16),
          ],
          if (_dinersReady) ...[
            _dinersCard(t),
            const SizedBox(height: 12),
          ],
          for (var i = 0; i < 7; i++) ...[
            _dayCard(t, _dayAt(i)),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 8),
          _shoppingCard(t, needed),
          if (_budgetReady) ...[
            const SizedBox(height: 12),
            _budgetCard(t, needed),
          ],
        ],
      );
    }

    final planned = _entries.where((e) => e.status == 'planned').length;
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
            Text('Plan my week.',
                style: t.headlineMedium.copyWith(
                    fontSize: 32, fontWeight: FontWeight.w800, color: _ink)),
            const SizedBox(height: 4),
            Text(
                _loading || _offline || _notReady
                    ? 'The next seven days, shared with your household.'
                    : (planned == 0
                        ? 'Nothing planned yet. Add a meal to any day.'
                        : (planned == 1
                            ? '1 meal planned, shared with your household.'
                            : '$planned meals planned, shared with your household.')),
                style: t.bodyLarge.copyWith(color: _muted, fontSize: 16)),
            const SizedBox(height: 20),
            AnimatedSize(
              duration: MediaQuery.of(context).disableAnimations
                  ? Duration.zero
                  : const Duration(milliseconds: 200),
              alignment: Alignment.topCenter,
              child: content,
            ),
          ],
        ),
      ),
    );
  }

  Widget _dayCard(FlutterFlowTheme t, DateTime day) {
    final meals = _entries.where((e) => _sameDay(e.date, day)).toList();
    final isToday = _sameDay(day, _today);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isToday ? _forest : _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(_dayName(day),
                    style: t.titleMedium.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: _ink)),
              ),
              TextButton.icon(
                style: TextButton.styleFrom(
                    minimumSize: const Size(48, 44), foregroundColor: _forest),
                onPressed: _busy ? null : () => _openPicker(t, day: day),
                icon: const Icon(Icons.add, size: 18),
                label: Text('Add a meal',
                    style: t.bodyMedium
                        .copyWith(color: _forest, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          if (meals.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8, right: 8),
              child: Text('Nothing planned',
                  style: t.bodyMedium.copyWith(color: _muted, fontSize: 14)),
            ),
          for (final e in meals) _entryRow(t, e),
        ],
      ),
    );
  }

  Widget _entryRow(FlutterFlowTheme t, _Entry e) {
    final goals = FFAppState().ideasGoals;
    final minutes = e.number('minutes');
    final kcal = e.number('calories');
    final meta = [
      _meals[e.meal] ?? 'Dinner',
      if (minutes > 0) '$minutes min',
      'Serves ${e.servings}',
      if (e.extra > 0) '+${e.extra} extra',
      if (_eaters(e).isNotEmpty) 'for ${_eaters(e)}',
      if (_clashes(e).isNotEmpty) '⚠ check allergies',
      if (goals && kcal > 0) '$kcal kcal',
    ].join(' · ');
    final done = e.status != 'planned';
    return Semantics(
      button: true,
      label: e.title,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: _busy ? null : () => _openEntry(t, e),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 8, 8, 8),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    color: done ? _forest : _sage,
                    borderRadius: BorderRadius.circular(14)),
                child: Icon(
                    e.status == 'cooked'
                        ? Icons.check
                        : (e.status == 'skipped'
                            ? Icons.remove
                            : Icons.restaurant_outlined),
                    color: done ? Colors.white : _forest,
                    size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: t.bodyLarge.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: _ink,
                            decoration:
                                done ? TextDecoration.lineThrough : null)),
                    Text(
                        e.status == 'cooked'
                            ? 'Eaten · $meta'
                            : (e.status == 'skipped'
                                ? 'Skipped · $meta'
                                : meta),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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

  Widget _shoppingCard(FlutterFlowTheme t, List<String> needed) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _sage,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Shopping for the week',
              style: t.titleMedium.copyWith(
                  fontSize: 18, fontWeight: FontWeight.w800, color: _ink)),
          const SizedBox(height: 4),
          Text(
              needed.isEmpty
                  ? 'The planned meals need nothing beyond your kitchen.'
                  : needed.join(', '),
              style: t.bodyMedium.copyWith(color: _muted, fontSize: 14)),
          if (needed.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 52,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: _forest,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _busy ? null : _shop,
                icon: const Icon(Icons.add_shopping_cart, size: 20),
                label: Text(
                    needed.length == 1
                        ? 'Add 1 thing to the shopping list'
                        : 'Add ${needed.length} things to the shopping list',
                    style: t.bodyLarge.copyWith(
                        color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ---- sheets --------------------------------------------------------------

  Future<T?> _sheet<T>(Widget Function(BuildContext, StateSetter) build) =>
      showModalBottomSheet<T>(
        context: context,
        isScrollControlled: true,
        backgroundColor: _cream,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (sheet) => StatefulBuilder(
          builder: (sheet, redraw) => Padding(
           padding: EdgeInsets.only(
               bottom: MediaQuery.of(sheet).viewInsets.bottom),
           child: ConstrainedBox(
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
                    build(sheet, redraw),
                  ],
                ),
              ),
            ),
          ),
          ),
        ),
      );

  /// Add a meal to a day, or (with [swapFor]) pick what replaces one.
  Future<void> _openPicker(FlutterFlowTheme t,
      {required DateTime day, _Entry? swapFor}) async {
    var meal = swapFor?.meal ?? 'dinner';
    var finding = false;
    await _sheet<void>((sheet, redraw) {
      final now = FFAppState().mealIdeas;
      Widget ideaTile(MealIdeaStruct idea) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                Navigator.of(sheet).pop();
                if (swapFor != null) {
                  _swap(swapFor, idea);
                } else {
                  _add(day, meal, idea);
                }
              },
              child: Container(
                constraints: const BoxConstraints(minHeight: 56),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(idea.title,
                              style: t.bodyLarge.copyWith(
                                  fontWeight: FontWeight.w700, color: _ink)),
                          Text(
                              [
                                if (idea.minutes > 0) '${idea.minutes} min',
                                if (idea.extras.isEmpty)
                                  'Only your food'
                                else
                                  'Needs ${idea.extras.length} more',
                                if (idea.extras.isNotEmpty &&
                                    _costOf(idea.extras).$2 <
                                        idea.extras.length)
                                  'about ${_money(_costOf(idea.extras).$1)} to buy',
                                if (FFAppState().ideasGoals &&
                                    idea.calories > 0)
                                  '${idea.calories} kcal',
                              ].join(' · '),
                              style: t.bodySmall
                                  .copyWith(color: _muted, fontSize: 13)),
                        ],
                      ),
                    ),
                    const Icon(Icons.add_circle_outline, color: _forest),
                  ],
                ),
              ),
            ),
          );
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
              swapFor != null
                  ? 'Swap ${swapFor.title}'
                  : 'Add to ${_onDay(day)}',
              style: t.headlineSmall.copyWith(
                  fontSize: 24, fontWeight: FontWeight.w800, color: _ink)),
          if (swapFor == null) ...[
            const SizedBox(height: 16),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final e in _meals.entries)
                _choice(t, e.value, meal == e.key,
                    () => redraw(() => meal = e.key)),
            ]),
          ],
          const SizedBox(height: 20),
          if (now.isNotEmpty) ...[
            _label(t, 'Ideas from your food now'),
            for (final idea in now) ideaTile(idea),
            const SizedBox(height: 12),
          ],
          if (_kept.isNotEmpty) ...[
            _label(t, 'Kept ideas'),
            for (final idea in _kept) ideaTile(idea),
            const SizedBox(height: 12),
          ],
          if (now.isEmpty && _kept.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                  'No ideas yet. Find some from the food in your kitchen.',
                  style: t.bodyLarge.copyWith(color: _muted, fontSize: 16)),
            ),
          SizedBox(
            height: 52,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: _forest,
                backgroundColor: Colors.white,
                side: const BorderSide(color: _border),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: finding
                  ? null
                  : () async {
                      redraw(() => finding = true);
                      if (swapFor == null) {
                        FFAppState()
                            .update(() => FFAppState().ideasMeal = meal);
                      }
                      final said = await getMealIdeas();
                      if (!mounted) return;
                      if (said.isNotEmpty) _say(said);
                      try {
                        redraw(() => finding = false);
                      } catch (_) {}
                    },
              icon: finding
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: _forest))
                  : const Icon(Icons.auto_awesome_outlined, size: 20),
              label: Text(
                  finding ? 'Looking through your kitchen…' : 'Find new ideas',
                  style: t.bodyLarge
                      .copyWith(color: _forest, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      );
    });
  }

  Future<void> _openEntry(FlutterFlowTheme t, _Entry e) async {
    final uses = e.list('uses');
    final extras = e.list('extras');
    final steps = e.list('steps');
    await _sheet<void>((sheet, redraw) {
      void act(VoidCallback then) {
        Navigator.of(sheet).pop();
        then();
      }

      Widget action(IconData icon, String label, VoidCallback onTap,
              {Color colour = _forest}) =>
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
            minVerticalPadding: 12,
            leading: Icon(icon, color: colour),
            title: Text(label,
                style: t.bodyLarge.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: colour == _forest ? _ink : colour)),
            onTap: onTap,
          );

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(e.title,
              style: t.headlineSmall.copyWith(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: _ink,
                  height: 1.15)),
          const SizedBox(height: 4),
          Text(
              [
                '${_meals[e.meal] ?? 'Dinner'}, ${_onDay(e.date)}',
                if (e.number('minutes') > 0) '${e.number('minutes')} min',
                'Serves ${e.servings}',
              ].join(' · '),
              style: t.bodyMedium.copyWith(color: _muted, fontSize: 14)),
          if (_clashes(e).isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFDE3E0),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                  '${_clashes(e).join('. ')}. Check the ingredients before cooking; this is not a medical check.',
                  style: t.bodyMedium.copyWith(
                      color: const Color(0xFFB42318),
                      fontWeight: FontWeight.w600,
                      fontSize: 14)),
            ),
          ],
          if (_diners.isNotEmpty) ...[
            const SizedBox(height: 16),
            _label(t, 'Who’s eating'),
            StatefulBuilder(
              builder: (context, again) => Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final d in _diners)
                    _choice(t, '${d['name']}',
                        _plates[e.id]?.containsKey('${d['id']}') ?? false,
                        () async {
                      await _setEater(e, d,
                          !(_plates[e.id]?.containsKey('${d['id']}') ?? false));
                      try {
                        again(() {});
                      } catch (_) {}
                    }),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text('Servings follow who’s eating and their portions.',
                style: t.bodySmall.copyWith(color: _muted, fontSize: 13)),
          ],
          if (e.status == 'planned' || e.status == 'cooked') ...[
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
                onPressed: () => act(() => _openAte(t, e)),
                icon: const Icon(Icons.check, size: 20),
                label: Text('I ate this',
                    style: t.bodyLarge.copyWith(
                        color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
          const SizedBox(height: 16),
          // Cook once, eat twice.
          Container(
            padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Cook extra portions',
                              style: t.bodyLarge.copyWith(
                                  fontWeight: FontWeight.w700, color: _ink)),
                          Text('Cook once, eat twice',
                              style: t.bodySmall
                                  .copyWith(color: _muted, fontSize: 13)),
                        ],
                      ),
                    ),
                    _stepper(
                        Icons.remove,
                        e.extra > 0,
                        () => act(
                            () => _update(e, {'extra_portions': e.extra - 1}))),
                    SizedBox(
                      width: 36,
                      child: Text('${e.extra}',
                          textAlign: TextAlign.center,
                          style: t.titleMedium.copyWith(color: _ink)),
                    ),
                    _stepper(
                        Icons.add,
                        e.extra < 6,
                        () => act(
                            () => _update(e, {'extra_portions': e.extra + 1}))),
                  ],
                ),
                if (e.extra > 0 &&
                    e.data['leftoverOf'] == null &&
                    !_entries.any((x) => x.data['leftoverOf'] == e.id))
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      style: TextButton.styleFrom(
                          minimumSize: const Size(48, 44),
                          foregroundColor: _forest),
                      onPressed: () => act(() => _planLeftovers(e)),
                      icon: const Icon(Icons.event_repeat, size: 18),
                      label: Text(
                          'Plan the leftovers for ${_onDay(DateTime(e.date.year, e.date.month, e.date.day + 1))}’s lunch',
                          style: t.bodyMedium.copyWith(
                              color: _forest, fontWeight: FontWeight.w700)),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          if (e.status == 'planned')
            action(Icons.swap_horiz, 'Swap for another idea',
                () => act(() => _openPicker(t, day: e.date, swapFor: e))),
          action(Icons.event_outlined, 'Move to another day',
              () => act(() => _openMove(t, e))),
          if (e.status != 'planned')
            action(
                Icons.undo,
                'Mark as still to cook',
                () => act(() async {
                      // Your own log of this meal goes too; the kitchen
                      // is left as it is (Undo on the message restores food).
                      final uid = SupaFlow.client.auth.currentUser?.id;
                      if (uid != null) {
                        try {
                          await SupaFlow.client
                              .from('meal_log_entries')
                              .delete()
                              .eq('plan_entry_id', e.id)
                              .eq('profile_id', uid);
                        } catch (_) {}
                      }
                      await _update(
                          e, {'status': 'planned', 'cooked_at': null});
                    })),
          if (e.status == 'planned')
            action(Icons.remove_circle_outline, 'Skip it this time',
                () => act(() => _update(e, {'status': 'skipped'}))),
          action(Icons.delete_outline, 'Take off the plan',
              () => act(() => _remove(e)),
              colour: _red),
          if (uses.isNotEmpty) ...[
            const SizedBox(height: 12),
            _label(t, 'From your kitchen'),
            Text(uses.join(', '),
                style: t.bodyLarge.copyWith(color: _ink, fontSize: 16)),
          ],
          if (extras.isNotEmpty) ...[
            const SizedBox(height: 12),
            _label(t, 'You would also need'),
            Text(extras.join(', '),
                style: t.bodyLarge.copyWith(color: _ink, fontSize: 16)),
          ],
          if (steps.isNotEmpty) ...[
            const SizedBox(height: 12),
            _label(t, 'Steps'),
            for (var i = 0; i < steps.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text('${i + 1}. ${steps[i]}',
                    style: t.bodyLarge
                        .copyWith(color: _ink, fontSize: 16, height: 1.4)),
              ),
          ],
        ],
      );
    });
  }

  Future<void> _openMove(FlutterFlowTheme t, _Entry e) async {
    await _sheet<void>((sheet, redraw) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Move ${e.title}',
                style: t.headlineSmall.copyWith(
                    fontSize: 24, fontWeight: FontWeight.w800, color: _ink)),
            const SizedBox(height: 16),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (var i = 0; i < 7; i++)
                _choice(t, _dayName(_dayAt(i)),
                    _sameDay(e.date, _dayAt(i)), () {
                  Navigator.of(sheet).pop();
                  _update(
                      e, {'plan_date': _iso(_dayAt(i))});
                }),
            ]),
          ],
        ));
  }

  /// Pick a meal → cook it → confirm portions → "I ate this".
  Future<void> _openAte(FlutterFlowTheme t, _Entry e) async {
    // The kitchen foods this meal uses, ticked to leave the kitchen.
    var foods = <({String id, String name})>[];
    final exact = <String>{};
    try {
      final rows = await SupaFlow.client
          .from('food_items_status')
          .select('id, name, computed_status')
          .eq('household_id', _for)
          .limit(200);
      final uses = e.list('uses').map((u) => u.toLowerCase()).toList();
      for (final r in rows as List) {
        final m = r as Map;
        final status = (m['computed_status'] ?? '').toString();
        if (status == 'consumed' || status == 'discarded') continue;
        final name = (m['name'] ?? '').toString();
        final n = name.toLowerCase();
        if (n.isEmpty) continue;
        if (uses.any((u) => n == u || _wordIn(n, u) || _wordIn(u, n))) {
          foods.add((id: m['id'].toString(), name: name));
          if (uses.contains(n)) exact.add(m['id'].toString());
        }
      }
    } catch (_) {
      foods = [];
    }
    if (!mounted) return;
    // Exact names start ticked; near matches are offered unticked. When the
    // meal was already eaten by someone else, nothing is ticked: the food
    // most likely left the kitchen then.
    final ticked = e.status == 'cooked'
        ? <String>{}
        : {
            for (final f in foods)
              if (exact.contains(f.id) || foods.length <= 3) f.id
          };    var portions = 1.0;
    final kcal = e.number('calories');
    final protein = e.number('protein');
    final goals = FFAppState().ideasGoals;

    final confirmed = await _sheet<bool>((sheet, redraw) {
      String amount(double p) =>
          p == p.roundToDouble() ? p.round().toString() : p.toStringAsFixed(1);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('I ate this',
              style: t.headlineSmall.copyWith(
                  fontSize: 26, fontWeight: FontWeight.w800, color: _ink)),
          const SizedBox(height: 4),
          Text(e.title,
              style: t.bodyLarge.copyWith(color: _muted, fontSize: 16)),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _label(t, 'How much did you have?')),
              _stepper(Icons.remove, portions > 0.5,
                  () => redraw(() => portions -= 0.5)),
              SizedBox(
                width: 96,
                child: Text(
                    portions == 1
                        ? '1 portion'
                        : '${amount(portions)} portions',
                    textAlign: TextAlign.center,
                    style: t.titleSmall.copyWith(color: _ink)),
              ),
              _stepper(
                  Icons.add, portions < 4, () => redraw(() => portions += 0.5)),
            ],
          ),
          if (goals && kcal > 0) ...[
            const SizedBox(height: 8),
            Text(
                'About ${(kcal * portions).round()} kcal${protein > 0 ? ' · ${(protein * portions).round()} g protein' : ''}, estimated. A guide only.',
                style: t.bodyMedium.copyWith(color: _muted, fontSize: 14)),
          ],
          const SizedBox(height: 20),
          _label(t, 'Used up in cooking'),
          if (foods.isEmpty)
            Text('No matching foods in your kitchen, so nothing changes there.',
                style: t.bodyMedium.copyWith(color: _muted, fontSize: 14))
          else ...[
            for (final f in foods)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: _forest,
                value: ticked.contains(f.id),
                title: Text(f.name,
                    style: t.bodyLarge.copyWith(fontSize: 16, color: _ink)),
                onChanged: (v) => redraw(
                    () => v == true ? ticked.add(f.id) : ticked.remove(f.id)),
              ),
            Text('Untick anything with some left.',
                style: t.bodySmall.copyWith(color: _muted, fontSize: 13)),
          ],
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
              child: Text('Confirm',
                  style: t.bodyLarge.copyWith(
                      color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      );
    });
    if (confirmed != true || !mounted) return;
    await _ate(e, portions, ticked.toList());
  }

  Future<void> _ate(_Entry e, double portions, List<String> used) async {
    if (_busy) return;
    setState(() => _busy = true);
    final uid = SupaFlow.client.auth.currentUser?.id;
    String? logId;
    final settled = <String>[];
    try {
      final row = await SupaFlow.client
          .from('meal_log_entries')
          .insert({
            'profile_id': uid,
            'household_id': _for,
            'plan_entry_id': e.id,
            'eaten_on': _iso(DateTime.now()),
            'meal': e.meal,
            'title': e.title,
            'portions': portions,
            if (e.number('calories') > 0)
              'calories_per_serving': e.number('calories'),
            if (e.number('protein') > 0)
              'protein_per_serving': e.number('protein'),
          })
          .select('id')
          .single();
      logId = row['id'].toString();
      await SupaFlow.client.from('meal_plan_entries').update({
        'status': 'cooked',
        'cooked_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', e.id);
      for (final id in used) {
        final said = await settleFoodItem(id, 'consumed');
        if (said.isEmpty) settled.add(id);
      }
    } catch (error) {
      if (mounted) {
        setState(() => _busy = false);
        _say(logId == null
            ? _why(error)
            : 'Logged, but the kitchen could not be updated. Check your signal.');
      }
      if (logId == null) return;
    }
    if (!mounted) return;
    setState(() => _busy = false);
    await _load(_for, quiet: true);
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final id = logId!;
    _say(
        settled.isEmpty
            ? 'Logged. Enjoy.'
            : (settled.length == 1
                ? 'Logged, and 1 food has left your kitchen.'
                : 'Logged, and ${settled.length} foods have left your kitchen.'),
        action: SnackBarAction(
          label: 'Undo',
          textColor: const Color(0xFFB9E08F),
          onPressed: () async {
            try {
              await SupaFlow.client
                  .from('meal_log_entries')
                  .delete()
                  .eq('id', id);
              await SupaFlow.client.from('meal_plan_entries').update(
                  {'status': 'planned', 'cooked_at': null}).eq('id', e.id);
              for (final f in settled) {
                await unsettleFoodItem(f);
              }
              messenger.showSnackBar(
                  const SnackBar(content: Text('Undone. Nothing changed.')));
              if (mounted) _load(_for, quiet: true);
            } catch (_) {
              messenger.showSnackBar(const SnackBar(
                  content: Text('Could not undo. Check your signal.')));
            }
          },
        ));
  }

  // ---- pieces --------------------------------------------------------------

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

const _recipesHome = r'''
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
        'title': idea.title.length > 120
            ? idea.title.substring(0, 120)
            : idea.title,
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
      final d = DateTime(today.year, today.month, today.day + i);
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
    final d = DateTime(today.year, today.month, today.day + day);
    final iso =
        '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    try {
      await SupaFlow.client.from('meal_plan_entries').insert({
        'household_id': household,
        'plan_date': iso,
        'meal': meal,
        'title': idea.title.length > 120
            ? idea.title.substring(0, 120)
            : idea.title,
        'recipe_data': {
          'uses': idea.uses,
          'extras': idea.extras,
          'steps': idea.steps,
          'minutes': idea.minutes,
          if (idea.calories > 0) 'calories': idea.calories,
          if (idea.protein > 0) 'protein': idea.protein,
        },
        'servings': idea.servings > 0 ? idea.servings.clamp(1, 12) : 2,
        'created_by': SupaFlow.client.auth.currentUser?.id,
      });
      if (!mounted) return;
      final router = GoRouter.of(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            'Planned for ${name(day) == 'Today' || name(day) == 'Tomorrow' ? name(day).toLowerCase() : name(day)}.'),
        action: SnackBarAction(
          label: 'See the week',
          textColor: const Color(0xFFB9E08F),
          onPressed: () => router.pushNamed('PlanWeekPage'),
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
    ).whenComplete(() =>
        Future.delayed(const Duration(milliseconds: 500), leaveOut.dispose));
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

  /// Whole-word match either way ("egg" in "Free-range eggs"), so "egg" is
  /// never "eggplant" and "milk" never "coconut milk" alone.
  static bool _wordIn(String hay, String word) {
    final w = word.trim().toLowerCase();
    if (w.length < 2) return false;
    return RegExp('(^|[^a-z])${RegExp.escape(w)}(es|s)?([^a-z]|\$)')
        .hasMatch(hay.toLowerCase());
  }

  bool _inKitchen(String ingredient) {
    final i = ingredient.toLowerCase();
    final si = _stem(i);
    for (final k in _kitchen) {
      if (k.isEmpty) continue;
      final sk = _stem(k);
      if (k == i ||
          (sk.length > 2 && _wordIn(i, sk)) ||
          (si.length > 2 && _wordIn(k, si))) {
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
      content = _message(
          t,
          Icons.cloud_off_outlined,
          'Can’t reach your recipes.',
          'No signal, or the connection dropped. Try again when you are back online.',
          retry: () => _load(_for));
    } else if (_recipes.isEmpty) {
      content = _message(t, Icons.menu_book_outlined, 'No recipes yet.',
          'Keep ideas you like on Recipes, or add a recipe of your own.');
    } else if (shown.isEmpty) {
      content = _message(
          t,
          Icons.filter_alt_off_outlined,
          'Nothing here.',
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
    final minutes =
        _data(r)['minutes'] is num ? (_data(r)['minutes'] as num).round() : 0;
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
                      if (r['source'] == 'own')
                        _pill(t, 'Your own', _muted, _sage),
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
      await SupaFlow.client.from('saved_recipes').update(
          {'is_favourite': r['is_favourite'] != true}).eq('id', '${r['id']}');
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
                        icon:
                            const Icon(Icons.calendar_month_outlined, size: 20),
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
    Future.delayed(const Duration(milliseconds: 500), notes.dispose);
    if (!mounted) return;
    if (r.containsKey('notes') && note != '${r['notes'] ?? ''}'.trim()) {
      try {
        await SupaFlow.client.from('saved_recipes').update(
            {'notes': note.isEmpty ? null : note}).eq('id', '${r['id']}');
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
      final d = DateTime(today.year, today.month, today.day + i);
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
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: _ink)),
                const SizedBox(height: 16),
                _label(t, 'Day'),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (var i = 0; i < 7; i++)
                    _choice(t, name(i), day == i, () => redraw(() => day = i)),
                ]),
                const SizedBox(height: 16),
                _label(t, 'Meal'),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final m in const [
                    'breakfast',
                    'lunch',
                    'dinner',
                    'snack'
                  ])
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
    final d = DateTime(today.year, today.month, today.day + day);
    final all = _ingredients(r);
    final data = _data(r);
    try {
      await SupaFlow.client.from('meal_plan_entries').insert({
        'household_id': _for,
        'plan_date':
            '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}',
        'meal': meal,
        'title': '${r['title']}'.length > 120
            ? '${r['title']}'.substring(0, 120)
            : '${r['title']}',
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
            ? (r['servings'] as num).round().clamp(1, 12)
            : (data['servings'] is num && (data['servings'] as num) > 0
                ? data['servings']
                : 2),
        'created_by': SupaFlow.client.auth.currentUser?.id,
      });
      if (!mounted) return;
      final router = GoRouter.of(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            'Planned for ${day < 2 ? name(day).toLowerCase() : name(day)}.'),
        action: SnackBarAction(
          label: 'See the week',
          textColor: const Color(0xFFB9E08F),
          onPressed: () => router.pushNamed('PlanWeekPage'),
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
      'title': title.text.trim().length > 120
          ? title.text.trim().substring(0, 120)
          : title.text.trim(),
      'source': 'own',
      'servings': servings,
      'recipe_data': {
        'ingredients': lines(ingredients),
        'steps': lines(steps),
        'minutes': minutes,
        'servings': servings,
      },
    };
    Future.delayed(const Duration(milliseconds: 500), () {
      title.dispose();
      ingredients.dispose();
      steps.dispose();
    });
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

  Widget _pill(FlutterFlowTheme t, String text, Color fg, Color bg) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
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

  Widget _message(FlutterFlowTheme t, IconData icon, String title, String text,
      {VoidCallback? retry}) {
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
                child: const Text('Try again'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
''';

const _receiptHeader = r'''
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// The receipt at the top of the receipt review: shop, where, when, total.
///
/// What was read can be wrong, so "Fix" opens it for editing before the food
/// is added. Nothing shows for a shelf photo or typed food.
class ReceiptHeader extends StatefulWidget {
  const ReceiptHeader({super.key, this.width, this.height});

  final double? width;
  final double? height;

  @override
  State<ReceiptHeader> createState() => _ReceiptHeaderState();
}

class _ReceiptHeaderState extends State<ReceiptHeader> {
  static const _forest = Color(0xFF07533A);
  static const _ink = Color(0xFF202C24);
  static const _muted = Color(0xFF59665D);
  static const _sage = Color(0xFFEDF2E8);
  static const _border = Color(0xFFDCE3D7);
  static const _cream = Color(0xFFF7F7F0);

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

  static Map<String, dynamic> _info() {
    try {
      final v = jsonDecode(FFAppState().scanReceipt);
      return v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  static void _write(Map<String, dynamic> info) =>
      FFAppState().update(() => FFAppState().scanReceipt = jsonEncode(info));

  static String _when(String iso) {
    final d = DateTime.tryParse(iso);
    if (d == null) return '';
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final hasTime = iso.contains('T');
    return '${_days[d.weekday - 1]} ${d.day} ${_months[d.month - 1]}'
        '${hasTime ? ', $h:${d.minute.toString().padLeft(2, '0')} ${d.hour < 12 ? 'am' : 'pm'}' : ''}';
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
    return '${symbols[code] ?? (code.isEmpty ? r'$' : '$code ')}${amount.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();
    final t = FlutterFlowTheme.of(context);
    if (FFAppState().scannedFrom != 'receipt' ||
        FFAppState().scannedFoods.isEmpty) {
      return const SizedBox.shrink();
    }
    final info = _info();
    final shop = '${info['shop'] ?? ''}'.trim();
    final place = '${info['location'] ?? ''}'.trim();
    final when = _when('${info['purchasedAt'] ?? ''}');
    final total = _money(info['total'], info['currency']);
    return Container(
      width: widget.width,
      margin: const EdgeInsets.only(top: 4, bottom: 4),
      padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
      decoration: BoxDecoration(
        color: _sage,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.receipt_long_outlined, color: _forest, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(shop.isEmpty ? 'Shop not read' : shop,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.bodyLarge
                        .copyWith(fontWeight: FontWeight.w800, color: _ink)),
                Text(
                    [
                      if (place.isNotEmpty) place,
                      when.isEmpty ? 'time not read' : when,
                      if (total.isNotEmpty) total,
                    ].join(' · '),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: t.bodySmall.copyWith(color: _muted, fontSize: 13)),
              ],
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(
                minimumSize: const Size(48, 44), foregroundColor: _forest),
            onPressed: () => _fix(t, info),
            child: Text('Fix',
                style: t.bodyMedium
                    .copyWith(color: _forest, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Future<void> _fix(FlutterFlowTheme t, Map<String, dynamic> info) async {
    final shop = TextEditingController(text: '${info['shop'] ?? ''}');
    final place = TextEditingController(text: '${info['location'] ?? ''}');
    final total = TextEditingController(
        text: info['total'] is num && (info['total'] as num) > 0
            ? (info['total'] as num).toStringAsFixed(2)
            : '');
    var when = DateTime.tryParse('${info['purchasedAt'] ?? ''}');
    InputDecoration look(String label) => InputDecoration(
          labelText: label,
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
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('The receipt',
                      style: t.headlineSmall.copyWith(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: _ink)),
                  const SizedBox(height: 16),
                  TextField(
                      controller: shop,
                      textCapitalization: TextCapitalization.words,
                      decoration: look('Shop')),
                  const SizedBox(height: 12),
                  TextField(
                      controller: place,
                      textCapitalization: TextCapitalization.words,
                      decoration: look('Where (branch or suburb)')),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      alignment: Alignment.centerLeft,
                      minimumSize: const Size(0, 56),
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: _border),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () async {
                      final now = DateTime.now();
                      final first = now.subtract(const Duration(days: 365));
                      // A misread date may be outside the range: start inside.
                      var init = when ?? now;
                      if (init.isAfter(now)) init = now;
                      if (init.isBefore(first)) init = first;
                      final day = await showDatePicker(
                        context: sheet,
                        initialDate: init,
                        firstDate: now.subtract(const Duration(days: 365)),
                        lastDate: now,
                      );
                      if (day == null) return;
                      final time = await showTimePicker(
                        context: sheet,
                        initialTime: TimeOfDay.fromDateTime(when ?? now),
                      );
                      redraw(() => when = DateTime(day.year, day.month, day.day,
                          time?.hour ?? 12, time?.minute ?? 0));
                    },
                    icon: const Icon(Icons.event, color: _forest),
                    label: Text(
                        when == null
                            ? 'When was it bought?'
                            : 'Bought ${_when(when!.toIso8601String())}',
                        style: t.bodyLarge.copyWith(color: _ink)),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                      controller: total,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: look('Total paid')),
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
                      child: Text('Save',
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
    );
    if (save == true) {
      final amount =
          double.tryParse(total.text.replaceAll(RegExp(r'[^0-9.]'), ''));
      final d = when;
      _write({
        ...info,
        'shop': shop.text.trim(),
        'location': place.text.trim(),
        'purchasedAt': d == null
            ? ''
            : '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}T${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}',
        'total': amount == null ? 0 : (amount * 100).round() / 100,
      });
    }
    Future.delayed(const Duration(milliseconds: 500), () {
      shop.dispose();
      place.dispose();
      total.dispose();
    });
  }
}
''';

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
    if (!mounted) return;
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
          if (p is Map &&
              '${p['image_front_small_url'] ?? ''}'.startsWith('https://'))
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
      var res = await http
          .get(Uri.parse(larger))
          .timeout(const Duration(seconds: 12));
      if (res.statusCode != 200 && larger != small) {
        res = await http
            .get(Uri.parse(small))
            .timeout(const Duration(seconds: 12));
      }
      if (res.statusCode != 200 || res.bodyBytes.isEmpty) throw 'no image';
      path = '$household/product-${const Uuid().v4()}.jpg';
      await storage.uploadBinary(path, res.bodyBytes,
          fileOptions:
              const FileOptions(contentType: 'image/jpeg', upsert: false));
      final signed = await storage.createSignedUrl(path, 60 * 60 * 24 * 365);
      await client
          .from('food_items')
          .update({'image_url': signed}).eq('id', id);

      // The picture it replaced, if the app stored it.
      final old = _storagePath('${food['image_url'] ?? ''}');
      if (old != null) {
        try {
          await storage.remove([old]);
          await client.from('product_images').delete().eq('storage_path', old);
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
      if (mounted) navigator.pop(true);
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
          Text(
              'Pick the pack that matches yours. Packs differ from country to country.',
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
                    backgroundColor: _forest, minimumSize: const Size(52, 52)),
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
            Text(_note,
                style: t.bodyLarge.copyWith(color: _muted, fontSize: 16))
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

const _saveScannedFoods = r'''
import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Adds everything left on the review list, in one insert.
///
/// One insert, so it is all or nothing: a receipt never lands half-added.
/// The list is emptied before the write, so a second tap while the first is
/// still saving finds nothing to add twice; if the write fails, it comes back.
///
/// From a receipt, it is also recorded for Receipts (shop, where, when, how
/// many, total) with each line and what was paid, and the price of each food
/// is remembered for budget planning. That record is extra: if it cannot be
/// written, the food is still added.
Future<String> saveScannedFoods() async {
  final items = List<ScannedFoodStruct>.of(FFAppState().scannedFoods);
  if (items.isEmpty) return 'Nothing left to add.';

  final household = FFAppState().currentHouseholdId;
  if (household.isEmpty) {
    return 'No household yet. Create or join one before adding food.';
  }
  final fromReceipt = FFAppState().scannedFrom != 'shelf';
  final source = fromReceipt ? 'receipt' : 'fridge_scan';
  final client = SupaFlow.client;
  final uid = client.auth.currentUser?.id;

  Map info = const {};
  if (fromReceipt) {
    try {
      final v = jsonDecode(FFAppState().scanReceipt);
      if (v is Map) info = v;
    } catch (_) {}
  }
  final shopRead = '${info['shop'] ?? ''}'.trim();
  final shop = shopRead.length > 120 ? shopRead.substring(0, 120) : shopRead;
  final whereRead = '${info['location'] ?? ''}'.trim();
  final where =
      whereRead.length > 200 ? whereRead.substring(0, 200) : whereRead;
  final bought = DateTime.tryParse('${info['purchasedAt'] ?? ''}');
  final total = info['total'] is num ? (info['total'] as num).toDouble() : 0.0;
  final currency = RegExp(r'^[A-Z]{3}$').hasMatch('${info['currency'] ?? ''}')
      ? '${info['currency']}'
      : '';

  FFAppState().update(() => FFAppState().scannedFoods = []);

  // The receipt record first, so each food can point at it.
  String? receiptId;
  if (fromReceipt) {
    try {
      final row = await client
          .from('receipts')
          .insert({
            'household_id': household,
            'scanned_by': uid,
            if (shop.isNotEmpty) 'shop_name': shop,
            if (where.isNotEmpty) 'shop_location': where,
            if (bought != null)
              'purchased_at': bought.toUtc().toIso8601String(),
            'item_count': items
                .fold<int>(0, (n, f) => n + (f.quantity < 1 ? 1 : f.quantity))
                .clamp(0, 500),
            if (total > 0) 'total_amount': total,
            if (currency.isNotEmpty) 'currency': currency,
          })
          .select('id')
          .single();
      receiptId = row['id'].toString();
    } catch (_) {
      receiptId = null;
    }
  }

  List rows;
  try {
    rows = await client.from('food_items').insert([
      for (final f in items)
        {
          'household_id': household,
          if (f.place.isNotEmpty) 'storage_location_id': f.place,
          'created_by': uid,
          'name': f.name,
          if (f.category.isNotEmpty) 'category': f.category,
          'quantity': f.quantity < 1 ? 1 : f.quantity,
          'source_type': source,
          if (receiptId != null) 'receipt_id': receiptId,
          if (fromReceipt && bought != null)
            'purchase_date':
                '${bought.year.toString().padLeft(4, '0')}-${bought.month.toString().padLeft(2, '0')}-${bought.day.toString().padLeft(2, '0')}',
        },
    ]).select('id');
  } on PostgrestException catch (error) {
    FFAppState().update(() => FFAppState().scannedFoods = items);
    await _dropReceipt(receiptId);
    if (error.code == '42501') {
      return 'Your account is not allowed to add to this household.';
    }
    return error.message;
  } catch (error) {
    FFAppState().update(() => FFAppState().scannedFoods = items);
    await _dropReceipt(receiptId);
    return 'Could not add them. $error';
  }

  if (receiptId != null) {
    try {
      await client.from('receipt_items').insert([
        for (var i = 0; i < items.length; i++)
          {
            'receipt_id': receiptId,
            'household_id': household,
            'name': items[i].name,
            'quantity': items[i].quantity < 1 ? 1 : items[i].quantity,
            if (items[i].price > 0) 'line_total': items[i].price,
            if (items[i].price > 0)
              'unit_price': ((items[i].price /
                              (items[i].quantity < 1 ? 1 : items[i].quantity)) *
                          100)
                      .round() /
                  100,
            if (i < rows.length) 'food_item_id': (rows[i] as Map)['id'],
          },
      ]);
    } catch (_) {}
  }

  // Remember what each food cost, for planning a week on a budget.
  final priced = <String, Map<String, dynamic>>{};
  for (final f in items) {
    if (f.price <= 0) continue;
    final key = f.name.trim().toLowerCase();
    if (key.isEmpty) continue;
    final each = f.price / (f.quantity < 1 ? 1 : f.quantity);
    priced[key] = {
      'household_id': household,
      'name_key': key,
      'display_name': f.name.trim(),
      'price': (each * 100).round() / 100,
      if (currency.isNotEmpty) 'currency': currency,
      'source': 'receipt',
      'seen_at': (bought ?? DateTime.now()).toUtc().toIso8601String(),
    };
  }
  if (priced.isNotEmpty) {
    try {
      await client
          .from('known_prices')
          .upsert(priced.values.toList(), onConflict: 'household_id,name_key');
    } catch (_) {}
  }

  FFAppState().update(() => FFAppState().scanReceipt = '');
  return '';
}

Future<void> _dropReceipt(String? id) async {
  if (id == null) return;
  try {
    await SupaFlow.client.from('receipts').delete().eq('id', id);
  } catch (_) {}
}
''';

const _changeFoodPhoto = r'''
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

/// Sets or removes one food's picture.
///
/// "ok" when saved, "" when the person backed out of the camera or photos
/// (not an error, so nothing is said), otherwise a sentence to show.
Future<String> changeFoodPhoto(String itemId, String source) async {
  final id = itemId.trim();
  if (id.isEmpty) return 'This food could not be found.';
  final client = SupaFlow.client;
  final storage = client.storage.from('food-images');

  String household;
  String oldUrl;
  try {
    final row = await client
        .from('food_items')
        .select('household_id, image_url')
        .eq('id', id)
        .maybeSingle();
    if (row == null) return 'This food is no longer in your kitchen.';
    household = row['household_id'].toString();
    oldUrl = (row['image_url'] ?? '').toString();
  } catch (_) {
    return 'Can’t reach your kitchen. Check your signal and try again.';
  }

  String? newPath;
  String? newUrl;
  if (source != 'remove') {
    final XFile? shot;
    try {
      shot = await ImagePicker().pickImage(
        source: source == 'gallery' ? ImageSource.gallery : ImageSource.camera,
        // A card and the top of the food's screen, and quick to upload.
        maxWidth: 900,
        maxHeight: 900,
        imageQuality: 82,
      );
    } catch (_) {
      return source == 'gallery'
          ? 'Use It Fresh can’t open your photos. Allow it in Settings.'
          : 'Use It Fresh can’t use the camera. Allow it in Settings.';
    }
    if (shot == null) return '';
    try {
      final bytes = await shot.readAsBytes();
      newPath = '$household/item-${const Uuid().v4()}.jpg';
      await storage.uploadBinary(
        newPath,
        bytes,
        fileOptions:
            const FileOptions(contentType: 'image/jpeg', upsert: false),
      );
      // A year, the same as every other picture the app keeps.
      newUrl = await storage.createSignedUrl(newPath, 60 * 60 * 24 * 365);
    } catch (_) {
      if (newPath != null) await _removeQuietly(storage, [newPath]);
      return 'Could not save the photo. Check your signal and try again.';
    }
  }

  try {
    await client.from('food_items').update({'image_url': newUrl}).eq('id', id);
  } on PostgrestException catch (error) {
    if (newPath != null) await _removeQuietly(storage, [newPath]);
    if (error.code == '42501') {
      return 'Your account is not allowed to change this food.';
    }
    return error.message;
  } catch (_) {
    if (newPath != null) await _removeQuietly(storage, [newPath]);
    return 'Could not save the photo. Check your signal and try again.';
  }

  // The picture it replaced, if the app stored it.
  final oldPath = _storagePath(oldUrl);
  if (oldPath != null && oldPath != newPath) {
    await _removeQuietly(storage, [oldPath]);
    try {
      await client.from('product_images').delete().eq('storage_path', oldPath);
    } catch (_) {}
  }
  return 'ok';
}

Future<void> _removeQuietly(StorageFileApi storage, List<String> paths) async {
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

