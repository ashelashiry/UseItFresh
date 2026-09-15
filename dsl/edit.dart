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

/// Build 17: "Find a meal that uses this" on a food's screen - Recipes opens
/// with a "Uses <food>" chip and asks for ideas that use it (function
/// 2026-09-15.1 honours useFood; older functions just ignore it).
void buildStarterEditFlow(App app) {
  app.state('ideasUseFood', string.withDefault(''));
  app.raw((project) {
    updateCustomWidget(project, name: 'FoodDetail', code: _wFoodDetail);
    updateCustomWidget(project, name: 'RecipesHome', code: _wRecipesHome);
    updateCustomAction(project, name: 'GetMealIdeas', code: _aGetMealIdeas);
  });
}

const _wFoodDetail = r'''
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Everything about one food (hybrid design, brief 15 Sep).
///
/// A smaller photo so the facts and actions sit in the first screen: the name
/// and a date badge that says its basis, quantity and place, a date note with
/// Edit date, "Use some" (choose how many) and Edit, "Add to shopping list" as
/// its own action, and More details. Throw out is separate, asks how many and
/// confirms, and every recorded change can be undone.
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
  bool _listed = false;
  bool _moreOpen = false;
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

  // Shows the other picture when both a fresh photo and your own exist.
  bool _otherPicture = false;

  String get _ownPicture =>
      _rows.isEmpty ? '' : (_rows.first.imageUrl ?? '').trim();

  String get _freshPicture =>
      _rows.isEmpty ? '' : _uFresh(_rows.first.name ?? '');

  bool get _bothPictures => _ownPicture.isNotEmpty && _freshPicture.isNotEmpty;

  String? get _photo {
    if (_rows.isEmpty) return null;
    final preferred = _uPicture(_rows.first.name ?? '', _ownPicture);
    if (_otherPicture && _bothPictures) {
      return preferred == _ownPicture ? _freshPicture : _ownPicture;
    }
    return preferred.isEmpty ? null : preferred;
  }

  String get _badge {
    if (_rows.isEmpty) return '';
    final r = _rows.first;
    return dateBadge(r.computedStatus ?? '', r.daysLeft, r.printedDate,
            r.printedDateType ?? '', r.statusBasis ?? '') ??
        '';
  }

  double get _quantity {
    final q = _rows.isEmpty ? null : _rows.first.quantity;
    return q == null || q <= 0 ? 1 : q;
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
              option(
                  c, Icons.travel_explore, 'Find the product photo', 'product'),
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
          constraints:
              BoxConstraints(maxHeight: MediaQuery.of(sheet).size.height * 0.9),
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

  /// Record that some or all of it was used or thrown out. Part of it only
  /// lowers the amount; all of it settles the food. Both can be undone.
  Future<void> _settle(String outcome, {double? amount}) async {
    if (_busy) return;
    setState(() => _busy = true);
    final router = GoRouter.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final id = _id;
    final name = _field('name');
    final before = _quantity;
    final unit = _rows.isEmpty ? '' : (_rows.first.unit ?? '');
    try {
      if (amount != null && amount < before) {
        final left = before - amount;
        await SupaFlow.client
            .from('food_items')
            .update({'quantity': left}).eq('id', id);
        try {
          await SupaFlow.client.from('food_item_events').insert({
            'food_item_id': id,
            'profile_id': SupaFlow.client.auth.currentUser?.id,
            'event_type': 'quantity_changed',
            'from_value': {'quantity': before},
            'to_value': {'quantity': left, 'reason': outcome},
          });
        } catch (_) {}
        await _load(quiet: true);
        messenger.showSnackBar(SnackBar(
          duration: const Duration(seconds: 6),
          content: Text(
              '${outcome == 'consumed' ? 'Used' : 'Thrown out'} ${_uAmount(amount, unit)}. ${_uAmount(left, unit)} left.'),
          action: SnackBarAction(
            label: 'Undo',
            textColor: const Color(0xFFB9E08F),
            onPressed: () async {
              try {
                await SupaFlow.client
                    .from('food_items')
                    .update({'quantity': before}).eq('id', id);
                if (mounted) _load(quiet: true);
              } catch (_) {
                messenger.showSnackBar(const SnackBar(
                    content: Text('Could not undo. Check your signal.')));
              }
            },
          ),
        ));
        return;
      }
      final said = await settleFoodItem(id, outcome);
      if (said.isNotEmpty) {
        messenger.showSnackBar(SnackBar(content: Text(said)));
        return;
      }
      messenger.showSnackBar(SnackBar(
        duration: const Duration(seconds: 6),
        content: Text(outcome == 'consumed'
            ? 'Marked as used.'
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
    } catch (_) {
      messenger.showSnackBar(const SnackBar(
          content: Text('Could not save that. Check your signal.')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// "Use some" or "Throw out": how much, then record it.
  Future<void> _howMuch(String outcome) async {
    final t = FlutterFlowTheme.of(context);
    final q = _quantity;
    final unit = _rows.isEmpty ? '' : (_rows.first.unit ?? '');
    final whole = q == q.roundToDouble();
    final step = whole ? 1.0 : q / 4;
    final used = outcome == 'consumed';
    // One item: nothing to choose.
    if (q <= 1) {
      if (!used) {
        final sure = await _confirmThrow(t, _uAmount(q, unit) ?? '');
        if (sure != true) return;
      }
      await _settle(outcome);
      return;
    }
    var amount = step;
    final choice = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _uCream,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheet) => StatefulBuilder(
        builder: (sheet, redraw) => SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                    used
                        ? 'How much did you use?'
                        : 'How much are you throwing out?',
                    style: t.headlineSmall.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: _uInk)),
                const SizedBox(height: 4),
                Text('You have ${_uAmount(q, unit)}.',
                    style: t.bodyLarge.copyWith(color: _uMuted, fontSize: 16)),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _stepButton(Icons.remove, amount > step,
                        () => redraw(() => amount -= step)),
                    SizedBox(
                      width: 140,
                      child: Text(_uAmount(amount, unit) ?? '',
                          textAlign: TextAlign.center,
                          style: t.titleLarge.copyWith(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: _uInk)),
                    ),
                    _stepButton(
                        Icons.add,
                        amount < q,
                        () => redraw(
                            () => amount = (amount + step).clamp(step, q))),
                  ],
                ),
                const SizedBox(height: 20),
                _UButton(
                    amount >= q
                        ? (used ? 'Used all of it' : 'Throw all of it out')
                        : (used
                            ? 'Used ${_uAmount(amount, unit)}'
                            : 'Throw out ${_uAmount(amount, unit)}'),
                    kind: used ? 'primary' : 'danger',
                    onTap: () => Navigator.of(sheet).pop(amount)),
                const SizedBox(height: 10),
                if (amount < q)
                  _UButton(used ? 'Used all of it' : 'Throw all of it out',
                      kind: 'secondary',
                      onTap: () => Navigator.of(sheet).pop(q)),
              ],
            ),
          ),
        ),
      ),
    );
    if (choice == null || !mounted) return;
    if (!used) {
      final sure = await _confirmThrow(t, _uAmount(choice, unit) ?? '');
      if (sure != true) return;
    }
    await _settle(outcome, amount: choice);
  }

  Future<bool?> _confirmThrow(FlutterFlowTheme t, String what) =>
      showDialog<bool>(
        context: context,
        builder: (d) => AlertDialog(
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Throw out $what?'),
          content: const Text(
              'It is recorded in What you used. You can undo straight after.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(d).pop(false),
                child: const Text('Keep it')),
            TextButton(
                onPressed: () => Navigator.of(d).pop(true),
                child: const Text('Throw out',
                    style: TextStyle(color: Color(0xFFB42318)))),
          ],
        ),
      );

  Widget _stepButton(IconData icon, bool enabled, VoidCallback onTap) =>
      _UPress(
        enabled: enabled,
        onTap: onTap,
        label: icon == Icons.add ? 'More' : 'Less',
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFFFFDF6),
            border: Border.all(color: const Color(0xFFCAD4BF)),
          ),
          child: Icon(icon, color: _uForest, size: 22),
        ),
      );

  Future<void> _addToList() async {
    if (_listed || _busy) return;
    final messenger = ScaffoldMessenger.of(context);
    final said = await addItemToShoppingList(_id);
    if (!mounted) return;
    if (said.isEmpty) {
      setState(() => _listed = true);
      messenger.showSnackBar(
          const SnackBar(content: Text('Added to your shopping list.')));
    } else {
      messenger.showSnackBar(SnackBar(content: Text(said)));
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

  Widget _backButton({bool onPhoto = true}) => _uBack(context, _back);

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
            color: const Color(0xF2FFFDF5),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFCDD6C4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.photo_camera_outlined,
                  color: _uForest, size: 21),
              if (!own) ...[
                const SizedBox(width: 6),
                Text('Add a photo',
                    style: t.bodyMedium.copyWith(
                        color: _uForest,
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
    final photo = _photo;
    final badge = _badge;
    final illustrative = photo != null && photo.contains('/design/v3/food/');
    final product = photo != null && photo.contains('/product-');
    final quantity = _field('quantity');
    final where = _field('where');
    final dateLine = _field('date');
    final source = _field('dateSource');
    final advice = _field('detail');
    final status = _field('status');
    final more = <(String, String)>[
      ('Category', _field('category')),
      ('How the date was worked out', _field('basis')),
      ('Added', _field('added').replaceFirst('Added ', '')),
      if (illustrative) ('Picture', 'An illustrative photo, not your food'),
      if (product) ('Picture', 'Photo: Open Food Facts'),
    ].where((r) => r.$2.trim().isNotEmpty).toList();

    Widget fact(String label, String value) => Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFBFCFB7))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: t.bodySmall.copyWith(color: _uMuted, fontSize: 13)),
                const SizedBox(height: 2),
                Text(value.isEmpty ? 'Not recorded' : value,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: t.bodyLarge.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _uInk)),
              ],
            ),
          ),
        );

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _backButton(onPhoto: false),
              const Spacer(),
              _photoButton(t),
            ],
          ),
          const SizedBox(height: 14),
          _USurface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: photo == null ? 96 : 195,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      photo == null
                          ? _uFallback(context, name, height: 96)
                          : Image.network(photo,
                              fit: BoxFit.cover,
                              cacheWidth: 900,
                              semanticLabel:
                                  illustrative ? 'Illustrative photo' : name,
                              errorBuilder: (_, __, ___) =>
                                  _uFallback(context, name, height: 195)),
                      if (_photoBusy)
                        const ColoredBox(
                          color: Color(0x66000000),
                          child: Center(
                            child: SizedBox(
                              width: 32,
                              height: 32,
                              child: CircularProgressIndicator(
                                  strokeWidth: 3, color: Colors.white),
                            ),
                          ),
                        ),
                      if (_bothPictures)
                        Positioned(
                          left: 10,
                          bottom: 10,
                          child: _UPress(
                            label: illustrative
                                ? 'Show my photo'
                                : 'Show a fresh photo',
                            onTap: () =>
                                setState(() => _otherPicture = !_otherPicture),
                            child: Container(
                              constraints: const BoxConstraints(minHeight: 32),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xE6FFFDF5),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                  illustrative
                                      ? 'Show my photo'
                                      : 'Show a fresh photo',
                                  style: t.bodySmall.copyWith(
                                      color: _uForest,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700)),
                            ),
                          ),
                        ),
                      if (illustrative || product)
                        Positioned(
                          right: 10,
                          bottom: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0x99000000),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                                product
                                    ? 'Photo: Open Food Facts'
                                    : 'Illustrative photo',
                                style: t.bodySmall.copyWith(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: t.headlineMedium.copyWith(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: _uForest,
                              height: 1.1)),
                      if (badge.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _uBadge(context, badge, size: 13),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              fact('Quantity', quantity),
              const SizedBox(width: 16),
              fact('Stored in', where),
            ],
          ),
          const SizedBox(height: 16),
          // The date, what it is based on, and a way to set it.
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
            decoration: BoxDecoration(
              color: const Color(0xF2F4F7EA),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFCAD7BF)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(dateLine,
                          style: t.bodyLarge.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: _uInk)),
                      const SizedBox(height: 2),
                      Text(source,
                          style: t.bodySmall
                              .copyWith(color: _uMuted, fontSize: 13)),
                      if ((status == 'past_use_by' ||
                              status == 'past_best_before') &&
                          advice.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(advice,
                            style: t.bodyMedium.copyWith(
                                color: _uInk,
                                fontSize: 14,
                                fontWeight: FontWeight.w600)),
                      ],
                    ],
                  ),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                      minimumSize: const Size(48, 44),
                      foregroundColor: _uForest),
                  onPressed: _busy ? null : _edit,
                  child: Text(
                      _rows.first.printedDate == null
                          ? 'Add date'
                          : 'Edit date',
                      style: t.bodyMedium.copyWith(
                          color: _uForest, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _UButton('Use some',
                    busy: _busy,
                    onTap: _busy ? null : () => _howMuch('consumed')),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _UButton('Edit',
                    kind: 'secondary',
                    icon: Icons.edit_outlined,
                    onTap: _busy ? null : _edit),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _UButton(_listed ? 'On your shopping list' : 'Add to shopping list',
              kind: 'secondary',
              icon: _listed ? Icons.check : Icons.add_shopping_cart,
              onTap: _listed || _busy ? null : _addToList),
          const SizedBox(height: 12),
          _UButton('Find a meal that uses this',
              kind: 'secondary',
              icon: Icons.restaurant_menu,
              onTap: _busy || _rows.isEmpty
                  ? null
                  : () {
                      final name = (_rows.first.name ?? '').trim();
                      if (name.isEmpty) return;
                      FFAppState().update(() {
                        FFAppState().ideasUseFood = name;
                        // Ideas that use one food: the other food filters stay.
                        FFAppState().mealIdeas = [];
                      });
                      context.pushNamed('RecipesPage');
                    }),
          const SizedBox(height: 14),
          if (more.isNotEmpty)
            _USurface(
              radius: 18,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _UPress(
                    label: _moreOpen ? 'Hide details' : 'More details',
                    onTap: () => setState(() => _moreOpen = !_moreOpen),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          Icon(
                              _moreOpen ? Icons.expand_less : Icons.expand_more,
                              color: _uForest),
                          const SizedBox(width: 8),
                          Text('More details',
                              style: t.bodyLarge.copyWith(
                                  color: _uForest,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
                  if (_moreOpen)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final r in more)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(r.$1,
                                      style: t.bodySmall.copyWith(
                                          color: _uMuted, fontSize: 13)),
                                  Text(r.$2,
                                      style: t.bodyLarge.copyWith(
                                          color: _uInk, fontSize: 15)),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 18),
          // Kept apart from everyday actions, and always asks first.
          Center(
            child: TextButton.icon(
              style: TextButton.styleFrom(
                  minimumSize: const Size(48, 48),
                  foregroundColor: const Color(0xFFB42318)),
              onPressed: _busy ? null : () => _howMuch('discarded'),
              icon: const Icon(Icons.delete_outline, size: 20),
              label: Text('Throw out',
                  style: t.bodyLarge.copyWith(
                      color: const Color(0xFFB42318),
                      fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
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
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                      alignment: Alignment.centerLeft,
                      child: _backButton(onPhoto: false)),
                  const SizedBox(height: 14),
                  block(290),
                  const SizedBox(height: 12),
                  block(92),
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
          _USurface(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
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
                _UButton(action, onTap: onAction),
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

const _wRecipesHome = r'''
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
/// Hybrid design (brief, 15 Sep): Plan my week and Saved recipes as compact
/// shortcuts, wrapping filter chips, a photographic lead idea with one clear
/// action, and more ideas as compact rows.
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

  // "Find a meal that uses this": ask once for each food chosen there.
  String _askedFor = '';

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
        'title':
            idea.title.length > 120 ? idea.title.substring(0, 120) : idea.title,
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
    for (final use in idea.uses) {
      final url = _uFresh(use, freshOnly: true);
      if (url.isNotEmpty) {
        return (url: url, cue: 'Uses your ${use.toLowerCase()}');
      }
    }
    // A pasta dish may show the illustrative pasta meal (never dry pasta).
    final title = idea.title.toLowerCase();
    if (title.contains('pasta') ||
        title.contains('spaghetti') ||
        title.contains('linguine') ||
        title.contains('penne')) {
      return (url: '$_food/pasta.webp', cue: '');
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
          Row(
            children: [
              Expanded(
                child: _UButton('Plan my week',
                    kind: 'secondary',
                    icon: _uPlus()
                        ? Icons.calendar_month_outlined
                        : Icons.lock_outline,
                    onTap: () => _uPlus()
                        ? context.pushNamed('PlanWeekPage')
                        : _uPlusSheet(context, 'Plan my week')),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _UButton('Saved recipes',
                    kind: 'secondary',
                    icon: _uPlus()
                        ? Icons.menu_book_outlined
                        : Icons.lock_outline,
                    onTap: () => _uPlus()
                        ? context.pushNamed('RecipeCollectionPage')
                        : _uPlusSheet(context, 'Your recipe collection')),
              ),
            ],
          ),
          const SizedBox(height: 14),
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
              height: 136,
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
    if (s.ideasUseFood.isNotEmpty && s.ideasUseFood != _askedFor) {
      _askedFor = s.ideasUseFood;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _ask();
      });
    }
    final quick = s.ideasMinutes == 15 || s.ideasMinutes == 30;
    final active = _activeFilters;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (s.ideasUseFood.isNotEmpty)
          _chip(t, 'Uses ${s.ideasUseFood}  ✕', true, Icons.restaurant_menu, () {
            _askedFor = '';
            FFAppState().update(() => FFAppState().ideasUseFood = '');
          }),
        _chip(t, 'Quick meals', quick, Icons.bolt_outlined, () {
          FFAppState().update(() => FFAppState().ideasMinutes = quick ? 0 : 30);
        }),
        _chip(t, 'Use my food', s.ideasKitchenOnly, Icons.kitchen_outlined, () {
          FFAppState().update(() =>
              FFAppState().ideasKitchenOnly = !FFAppState().ideasKitchenOnly);
        }),
        _chip(t, 'Fits my goals', s.ideasGoals && _uPlus(),
            _uPlus() ? Icons.track_changes : Icons.lock_outline, () {
          if (!_uPlus()) {
            _uPlusSheet(context, 'Fits my goals');
            return;
          }
          final turningOn = !FFAppState().ideasGoals;
          FFAppState().update(() => FFAppState().ideasGoals = turningOn);
          // First time on, with nothing chosen yet: show where goals are set.
          if (turningOn &&
              FFAppState().ideasCalories.isEmpty &&
              !FFAppState().ideasHighProtein) {
            _openFilters(t);
          }
        }),
        _chip(t, active > 0 ? 'Filters · $active' : 'Filters', active > 0,
            Icons.tune, () => _openFilters(t)),
      ],
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
    if (!_uPlus()) {
      await _uPlusSheet(context, 'Plan my week');
      return;
    }
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
        'title':
            idea.title.length > 120 ? idea.title.substring(0, 120) : idea.title,
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
      _UPress(
        label: label,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            gradient: on
                ? null
                : const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFFFFDF6), Color(0xFFF1F3E8)]),
            color: on ? _uForest : null,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: on ? _uForest : const Color(0xFFCAD4BF)),
            boxShadow: on
                ? const [
                    BoxShadow(color: Color(0xFF033C29), offset: Offset(0, 2))
                  ]
                : const [
                    BoxShadow(color: Color(0xFFD6DFCC), offset: Offset(0, 2))
                  ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 17, color: on ? Colors.white : _uForest),
              const SizedBox(width: 6),
              Text(label,
                  style: t.bodyMedium.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: on ? Colors.white : _uForest)),
            ],
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
    return _USurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 190,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Illustrative ingredients, not a recipe result.
                Image.network('$_food/spinach.webp',
                    fit: BoxFit.cover,
                    cacheWidth: 900,
                    semanticLabel: '',
                    errorBuilder: (_, __, ___) =>
                        Container(color: const Color(0xFFE4E9D9))),
                Positioned(
                  left: 14,
                  top: 14,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                        color: const Color(0xF0FFFFFF),
                        borderRadius: BorderRadius.circular(10)),
                    child: Text('IDEAS FROM YOUR FOOD',
                        style: t.bodySmall.copyWith(
                            color: _uForest,
                            fontSize: 11,
                            letterSpacing: 0.9,
                            fontWeight: FontWeight.w800)),
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
                Text(
                    empty
                        ? 'Ideas come from your food'
                        : 'What can you make tonight?',
                    style: t.headlineSmall.copyWith(
                        fontSize: 23,
                        fontWeight: FontWeight.w800,
                        color: _uInk,
                        height: 1.15)),
                const SizedBox(height: 6),
                Text(
                    empty
                        ? 'Add some food and ideas will use it first.'
                        : 'Meals built around what needs using first.',
                    style: t.bodyMedium.copyWith(color: _uMuted, fontSize: 14)),
                const SizedBox(height: 14),
                _UButton(empty ? 'Add food' : 'Find meals',
                    icon: empty ? Icons.add : Icons.arrow_forward,
                    trailing: !empty,
                    onTap: empty
                        ? () async {
                            await clearShelfScan();
                            if (mounted) context.pushNamed('MapReviewPage');
                          }
                        : _ask),
              ],
            ),
          ),
        ],
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
        const SizedBox(height: 22),
        Row(
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text('More possibilities',
                    style: t.titleLarge.copyWith(
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        color: _uInk)),
              ),
            ),
            TextButton.icon(
              onPressed: _ask,
              style: TextButton.styleFrom(
                  minimumSize: const Size(48, 44), foregroundColor: _uForest),
              icon: const Icon(Icons.refresh, size: 18),
              label: Text('New ideas',
                  style: t.bodyMedium
                      .copyWith(color: _uForest, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
        for (final idea in rest) ...[
          const SizedBox(height: 10),
          _row(t, idea),
        ],
      ],
    );
  }

  Widget _leadCard(FlutterFlowTheme t, MealIdeaStruct idea) {
    final photo = _ingredientPhoto(idea);
    final kept = _isKept(idea);
    final meta = [
      if (idea.minutes > 0) '${idea.minutes} min',
      if (idea.uses.isNotEmpty)
        idea.uses.length == 1
            ? 'Uses 1 food in your kitchen'
            : 'Uses ${idea.uses.length} foods in your kitchen',
    ].join(' · ');
    return _USurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: photo == null ? 64 : 210,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (photo == null)
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                          colors: [Color(0xFFE4E9D9), Color(0xFFD9E6D1)]),
                    ),
                  )
                else
                  Image.network(photo.url,
                      fit: BoxFit.cover,
                      cacheWidth: 900,
                      semanticLabel: '',
                      errorBuilder: (_, __, ___) =>
                          Container(color: const Color(0xFFE4E9D9))),
                Positioned(
                  left: 14,
                  top: 14,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                        color: const Color(0xF0FFFFFF),
                        borderRadius: BorderRadius.circular(10)),
                    child: Text('TONIGHT, SORTED',
                        style: t.bodySmall.copyWith(
                            color: _uForest,
                            fontSize: 11,
                            letterSpacing: 0.9,
                            fontWeight: FontWeight.w800)),
                  ),
                ),
                Positioned(
                  right: 14,
                  top: 10,
                  child: _UPress(
                    label: kept ? 'Saved' : 'Save this idea',
                    onTap: () => kept ? null : _keep(idea),
                    child: Container(
                      constraints:
                          const BoxConstraints(minHeight: 44, minWidth: 56),
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                          color: const Color(0xFFFFFDF5),
                          borderRadius: BorderRadius.circular(12)),
                      child: Text(kept ? 'Saved' : 'Save',
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
                Text(idea.title,
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
                if (_goalsOn && _nutrition(idea).isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(spacing: 6, runSpacing: 6, children: [
                    if (idea.calories > 0)
                      _uBadge(context, 'About ${idea.calories} kcal|calm'),
                    if (idea.protein > 0)
                      _uBadge(context, '${idea.protein} g protein|calm'),
                  ]),
                ],
                const SizedBox(height: 14),
                _UButton('Let’s cook',
                    icon: Icons.arrow_forward,
                    trailing: true,
                    onTap: () => _openIdea(t, idea)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// One more idea as a compact row: picture, name, time, Explore.
  Widget _row(FlutterFlowTheme t, MealIdeaStruct idea) {
    final photo = _ingredientPhoto(idea);
    final meta = [
      if (idea.minutes > 0) '${idea.minutes} min',
      if (_goalsOn && idea.calories > 0) 'about ${idea.calories} kcal',
      if (!_goalsOn && _cue(idea).isNotEmpty) _cue(idea),
    ].join(' · ');
    return _USurface(
      radius: 20,
      onTap: () => _openIdea(t, idea),
      label: idea.title,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              width: 84,
              height: 84,
              child: photo == null
                  ? Container(
                      color: const Color(0xFFE4E9D9),
                      alignment: Alignment.center,
                      child: const Icon(Icons.restaurant_menu,
                          color: _uForest, size: 28))
                  : Image.network(photo.url,
                      fit: BoxFit.cover,
                      cacheWidth: 260,
                      semanticLabel: '',
                      errorBuilder: (_, __, ___) =>
                          Container(color: const Color(0xFFE4E9D9))),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(idea.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: t.titleMedium.copyWith(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: _uInk,
                        height: 1.2)),
                if (meta.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(meta,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          t.bodySmall.copyWith(color: _uMuted, fontSize: 13)),
                ],
                const SizedBox(height: 6),
                Text('Explore →',
                    style: t.bodyMedium.copyWith(
                        color: _uForest, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _smallCard(FlutterFlowTheme t, MealIdeaStruct idea,
      {_Kept? kept, required double width}) {
    final meta = [
      if (idea.minutes > 0) '${idea.minutes} min',
      if (_goalsOn && _nutrition(idea).isNotEmpty) _nutrition(idea),
    ].join(' · ');
    return SizedBox(
      width: width,
      child: _USurface(
        radius: 20,
        onTap: () => _openIdea(t, idea, kept: kept),
        label: idea.title,
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 94,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(idea.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: t.titleMedium.copyWith(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: _uInk,
                      height: 1.2)),
              const Spacer(),
              if (meta.isNotEmpty)
                Text(meta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.bodySmall.copyWith(color: _uMuted, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }

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

const _aGetMealIdeas = r'''
import 'package:supabase_flutter/supabase_flutter.dart';

/// Asks for meal ideas built from the food in this kitchen, soonest-to-go
/// first and shaped by the Recipes filters, and keeps them in app state.
///
/// What to leave out is two things joined: what was typed into "Leave out",
/// and what the person's allergies and diet add. "Use my food" asks for ideas
/// that need nothing beyond the kitchen and the basics. "Fits my goals" sends
/// the calorie range and high protein, and every idea comes back with its
/// estimated calories and protein per serving.
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

  // Household allergies too (Plan my week → Who eats at home).
  final leaveOut = [
    FFAppState().ideasLeaveOut,
    FFAppState().ideasAvoid,
    FFAppState().ideasHouseholdAvoid
  ].map((w) => w.trim()).where((w) => w.isNotEmpty).join(', ');

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
        'useFood': FFAppState().ideasUseFood,
        'calories': FFAppState().ideasGoals ? FFAppState().ideasCalories : '',
        'highProtein': FFAppState().ideasGoals && FFAppState().ideasHighProtein,
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
        calories: r['calories'] is num ? (r['calories'] as num).round() : 0,
        protein: r['protein'] is num ? (r['protein'] as num).round() : 0,
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

