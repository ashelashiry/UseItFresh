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

/// Hybrid design, food screen (brief 15 Sep): smaller photo, facts and actions first, Use some with quantities, Add to shopping list, More details, Throw out apart and confirmed.
void buildStarterEditFlow(App app) {
  app.raw((project) {
    updateCustomWidget(project, name: 'FoodDetail', code: _wFoodDetail);
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

  String? get _photo {
    if (_rows.isEmpty) return null;
    final r = _rows.first;
    final url = foodPhoto(r.name ?? '', r.imageUrl ?? '') ?? '';
    return url.isEmpty ? null : url;
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
              '${outcome == 'consumed' ? 'Used' : 'Thrown out'} ${quantityLabel(amount, unit)}. ${quantityLabel(left, unit)} left.'),
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
        final sure = await _confirmThrow(t, quantityLabel(q, unit) ?? '');
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
                Text(used ? 'How much did you use?' : 'How much are you throwing out?',
                    style: t.headlineSmall.copyWith(
                        fontSize: 22, fontWeight: FontWeight.w800, color: _uInk)),
                const SizedBox(height: 4),
                Text('You have ${quantityLabel(q, unit)}.',
                    style: t.bodyLarge.copyWith(color: _uMuted, fontSize: 16)),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _stepButton(Icons.remove, amount > step,
                        () => redraw(() => amount -= step)),
                    SizedBox(
                      width: 140,
                      child: Text(quantityLabel(amount, unit) ?? '',
                          textAlign: TextAlign.center,
                          style: t.titleLarge.copyWith(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: _uInk)),
                    ),
                    _stepButton(Icons.add, amount < q,
                        () => redraw(() => amount = (amount + step).clamp(step, q))),
                  ],
                ),
                const SizedBox(height: 20),
                _UButton(
                    amount >= q
                        ? (used ? 'Used all of it' : 'Throw all of it out')
                        : (used
                            ? 'Used ${quantityLabel(amount, unit)}'
                            : 'Throw out ${quantityLabel(amount, unit)}'),
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
      final sure = await _confirmThrow(t, quantityLabel(choice, unit) ?? '');
      if (sure != true) return;
    }
    await _settle(outcome, amount: choice);
  }

  Future<bool?> _confirmThrow(FlutterFlowTheme t, String what) => showDialog<bool>(
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
                        fontSize: 16, fontWeight: FontWeight.w700, color: _uInk)),
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
                              semanticLabel: illustrative
                                  ? 'Illustrative photo'
                                  : name,
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
                      _rows.first.printedDate == null ? 'Add date' : 'Edit date',
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
                              _moreOpen
                                  ? Icons.expand_less
                                  : Icons.expand_more,
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
Widget _uBack(BuildContext context, VoidCallback onTap) => _UPress(
      onTap: onTap,
      label: 'Back',
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFFFFFDF4),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFCDD6C4)),
          boxShadow: const [
            BoxShadow(color: Color(0xFFD6DFCC), offset: Offset(0, 2))
          ],
        ),
        child: const Icon(Icons.arrow_back, color: _uForest, size: 22),
      ),
    );

/// A food card for the two-column grids: picture, two-line name, amount and
/// the date badge.
Widget _uFoodCard(BuildContext context, Map item, {required VoidCallback onTap}) {
  final t = FlutterFlowTheme.of(context);
  final name = '${item['name'] ?? ''}';
  final photo = foodPhoto(name, '${item['image_url'] ?? ''}') ?? '';
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
''';

