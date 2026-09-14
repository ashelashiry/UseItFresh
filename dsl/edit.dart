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

/// Credit Open Food Facts on a food whose picture came from a barcode lookup.
///
/// Their product photos are free to use with attribution. The copy the app
/// keeps is stored as "product-<id>.jpg", so the food's screen can tell it
/// apart from a photo the person took.
void buildStarterEditFlow(App app) {
  app.raw((project) {
    updateCustomWidget(project, name: 'FoodDetail', code: _foodDetail);
  });
}

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
              // Open Food Facts photos are free to use with credit. Our own
              // copies of them are stored as "product-…" in the household folder.
              if (photo != null && photo.contains('/product-'))
                Positioned(
                  right: 12,
                  top: 24,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0x99000000),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text('Photo: Open Food Facts',
                        style: t.bodySmall.copyWith(
                            color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
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
