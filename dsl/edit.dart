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

/// Owner's review (15 Sep), My details: "too plain". A MyDetails widget -
/// profile photo, name, units as two cards, Save changes - replaces the plain
/// name field, imperial checkbox and button (kept, hidden). Saving no longer
/// sends someone who already has a household to household setup.
void buildStarterEditFlow(App app) {
  final dynamic myDetails = app.customWidget(
    'MyDetails',
    parameters: {},
    description: 'My details: profile photo, name, units as two cards and Save changes.',
    code: _wMyDetails,
  );
  app.editPage(ff.Pages.onboardingPage, (page) {
    for (final i in [0, 1, 2]) {
      page.update(
          ff.Pages.onboardingPage.widgets
              .byPath('OnboardingPage.body[0].children[0].children[$i]')
              .single,
          (patch) => patch.visible(false));
    }
    page.ensureInsertedInto(
      ff.Pages.onboardingPage.widgets.byPath('OnboardingPage.body[0].children[0]').single,
      myDetails(name: 'MyDetailsForm'),
      index: 0,
    );
  });
}

const _wMyDetails = r'''
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

/// My details (owner, 15 Sep: "too plain"): a profile photo, the name, units
/// as two cards (Metric / Imperial) and one Save changes button.
///
/// The photo is a large round picture - or their initial - with a camera
/// badge; tapping it offers Take a photo, Choose a photo and Remove photo.
///
/// Photos go to the public `avatars` bucket under the person's own folder
/// (the only folder the storage policy lets them write) and the address is
/// kept in `profiles.avatar_url`. The previous file is removed after the new
/// one is saved.
class MyDetails extends StatefulWidget {
  const MyDetails({super.key, this.width, this.height});

  final double? width;
  final double? height;

  @override
  State<MyDetails> createState() => _MyDetailsState();
}

class _MyDetailsState extends State<MyDetails> {
  String _url = '';
  String _name = '';
  bool _busy = false;
  bool _loaded = false;
  bool _saving = false;
  String _units = 'metric';
  final _nameField = TextEditingController();

  @override
  void dispose() {
    _nameField.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  String? get _uid => SupaFlow.client.auth.currentUser?.id;

  Future<void> _load() async {
    final uid = _uid;
    if (uid == null) return;
    try {
      final row = await SupaFlow.client
          .from('profiles')
          .select('display_name, avatar_url, unit_system')
          .eq('id', uid)
          .maybeSingle();
      if (!mounted || row == null) return;
      setState(() {
        _url = (row['avatar_url'] ?? '').toString();
        _name = (row['display_name'] ?? '').toString();
        _nameField.text = _name;
        _units = row['unit_system'] == 'imperial' ? 'imperial' : 'metric';
        _loaded = true;
      });
    } catch (_) {
      // Offline: the initial still shows.
    }
  }

  void _say(String text) {
    if (!mounted || text.isEmpty) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  static String? _pathOf(String url) {
    const marker = '/storage/v1/object/public/avatars/';
    final i = url.indexOf(marker);
    if (i < 0) return null;
    return Uri.decodeComponent(url.substring(i + marker.length).split('?').first);
  }

  Future<void> _change(String source) async {
    final uid = _uid;
    if (uid == null || _busy) return;
    final storage = SupaFlow.client.storage.from('avatars');
    final old = _pathOf(_url);
    String? path;
    String url = '';
    if (source != 'remove') {
      final XFile? shot;
      try {
        shot = await ImagePicker().pickImage(
          source: source == 'gallery' ? ImageSource.gallery : ImageSource.camera,
          maxWidth: 600,
          maxHeight: 600,
          imageQuality: 85,
          preferredCameraDevice: CameraDevice.front,
        );
      } catch (_) {
        _say(source == 'gallery'
            ? 'Use It Fresh can’t open your photos. Allow it in Settings.'
            : 'Use It Fresh can’t use the camera. Allow it in Settings.');
        return;
      }
      if (shot == null) return;
      setState(() => _busy = true);
      try {
        final bytes = await shot.readAsBytes();
        path = '$uid/avatar-${const Uuid().v4()}.jpg';
        await storage.uploadBinary(path, bytes,
            fileOptions:
                const FileOptions(contentType: 'image/jpeg', upsert: false));
        url = storage.getPublicUrl(path);
      } catch (_) {
        if (mounted) setState(() => _busy = false);
        _say('Could not save the photo. Check your signal and try again.');
        return;
      }
    } else {
      setState(() => _busy = true);
    }
    try {
      await SupaFlow.client
          .from('profiles')
          .update({'avatar_url': url.isEmpty ? null : url}).eq('id', uid);
    } catch (_) {
      if (path != null) {
        try {
          await storage.remove([path]);
        } catch (_) {}
      }
      if (mounted) setState(() => _busy = false);
      _say('Could not change your photo. Check your signal and try again.');
      return;
    }
    if (old != null) {
      try {
        await storage.remove([old]);
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() {
      _url = url;
      _busy = false;
    });
    _say(source == 'remove' ? 'Photo removed.' : 'Photo saved.');
  }

  Future<void> _choose() async {
    final t = FlutterFlowTheme.of(context);
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: _uCream,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheet) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Your photo',
                  style: t.headlineSmall.copyWith(
                      fontSize: 22, fontWeight: FontWeight.w800, color: _uInk)),
              const SizedBox(height: 14),
              _UButton('Take a photo',
                  icon: Icons.photo_camera_outlined,
                  onTap: () => Navigator.of(sheet).pop('camera')),
              const SizedBox(height: 10),
              _UButton('Choose a photo',
                  icon: Icons.photo_library_outlined,
                  kind: 'secondary',
                  onTap: () => Navigator.of(sheet).pop('gallery')),
              if (_url.isNotEmpty) ...[
                const SizedBox(height: 10),
                _UButton('Remove photo',
                    icon: Icons.delete_outline,
                    kind: 'danger',
                    onTap: () => Navigator.of(sheet).pop('remove')),
              ],
            ],
          ),
        ),
      ),
    );
    if (picked != null) await _change(picked);
  }

  Widget _photo(BuildContext context) {
    final t = FlutterFlowTheme.of(context);
    final initial = _name.trim().isEmpty
        ? (SupaFlow.client.auth.currentUser?.email ?? '?').substring(0, 1).toUpperCase()
        : _name.trim().substring(0, 1).toUpperCase();
    final circle = Container(
      width: 104,
      height: 104,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFE9F0E1), Color(0xFFCFDDC5)]),
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: const [
          BoxShadow(color: Color(0x26203A2B), blurRadius: 14, offset: Offset(0, 6)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: _busy
          ? const Center(
              child: SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: _uForest)))
          : (_url.isEmpty
              ? Center(
                  child: Text(initial,
                      style: t.headlineLarge.copyWith(
                          fontSize: 40, fontWeight: FontWeight.w800, color: _uForest)))
              : Image.network(_url,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Center(
                      child: Text(initial,
                          style: t.headlineLarge.copyWith(
                              fontSize: 40,
                              fontWeight: FontWeight.w800,
                              color: _uForest))))),
    );
    return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              button: true,
              label: _url.isEmpty ? 'Add a profile photo' : 'Change your profile photo',
              child: GestureDetector(
                onTap: _busy ? null : _choose,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    circle,
                    Positioned(
                      right: -2,
                      bottom: 2,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [_uForestTop, _uForest]),
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.photo_camera_outlined,
                            size: 18, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _busy ? null : _choose,
              style: TextButton.styleFrom(
                  foregroundColor: _uForest, minimumSize: const Size(48, 40)),
              child: Text(_url.isEmpty ? 'Add a photo' : 'Change photo',
                  style: t.bodyMedium
                      .copyWith(color: _uForest, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
    );
  }

  Future<void> _save() async {
    final uid = _uid;
    if (uid == null || _saving) return;
    final name = _nameField.text.trim();
    setState(() => _saving = true);
    try {
      await SupaFlow.client.from('profiles').update({
        'display_name': name.isEmpty ? null : name,
        'unit_system': _units,
      }).eq('id', uid);
    } catch (_) {
      if (mounted) setState(() => _saving = false);
      _say('Could not save. Check your signal and try again.');
      return;
    }
    if (!mounted) return;
    setState(() {
      _saving = false;
      _name = name;
    });
    _say('Saved.');
    // New here: set up the household next. Otherwise back to Profile.
    if (FFAppState().currentHouseholdId.isEmpty) {
      context.pushNamed('HouseholdSetupPage');
    } else if (Navigator.of(context).canPop()) {
      context.pop();
    }
  }

  Widget _unitCard(FlutterFlowTheme t, String value, String title, String sub,
      IconData icon) {
    final on = _units == value;
    return Semantics(
      button: true,
      selected: on,
      label: '$title, $sub',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _units = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: on
                  ? const [Color(0xFFF1F7EC), Color(0xFFDDEAD2)]
                  : const [Color(0xFFFFFEFA), Color(0xFFF1F3EA)],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
                color: on ? _uForest : const Color(0xFFCCD7C2),
                width: on ? 2 : 1),
            boxShadow: const [
              BoxShadow(color: Color(0xFFD6DFCC), offset: Offset(0, 2))
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: _uForest, size: 24),
                  const Spacer(),
                  Icon(on ? Icons.check_circle : Icons.radio_button_unchecked,
                      color: on ? _uForest : const Color(0xFFB9C4AF), size: 22),
                ],
              ),
              const SizedBox(height: 10),
              Text(title,
                  style: t.bodyLarge.copyWith(
                      fontWeight: FontWeight.w800, color: _uInk, fontSize: 16)),
              const SizedBox(height: 2),
              Text(sub, style: t.bodySmall.copyWith(color: _uMuted, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);
    final email = SupaFlow.client.auth.currentUser?.email;
    OutlineInputBorder line(Color c, [double w = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: c, width: w));
    return SizedBox(
      width: widget.width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(child: _photo(context)),
          _USurface(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Your name',
                    style: t.bodyMedium
                        .copyWith(color: _uMuted, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                TextField(
                  controller: _nameField,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.done,
                  style: t.bodyLarge.copyWith(color: _uInk, fontSize: 17),
                  decoration: InputDecoration(
                    hintText: 'What should we call you?',
                    filled: true,
                    fillColor: const Color(0xFFFFFDF7),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    border: line(const Color(0xFFCCD7C2)),
                    enabledBorder: line(const Color(0xFFCCD7C2)),
                    focusedBorder: line(_uForest, 2),
                  ),
                ),
                if (email != null) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.mail_outline, size: 18, color: _uMuted),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(email,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: t.bodyMedium.copyWith(color: _uMuted)),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text('Units',
              style: t.titleMedium.copyWith(
                  fontWeight: FontWeight.w800, color: _uInk, fontSize: 18)),
          const SizedBox(height: 4),
          Text('How amounts and temperatures are shown.',
              style: t.bodyMedium.copyWith(color: _uMuted)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                  child: _unitCard(
                      t, 'metric', 'Metric', 'g, kg, ml, °C', Icons.straighten)),
              const SizedBox(width: 12),
              Expanded(
                  child: _unitCard(t, 'imperial', 'Imperial',
                      'oz, lb, fl oz, °F', Icons.scale_outlined)),
            ],
          ),
          const SizedBox(height: 24),
          _UButton('Save changes',
              busy: _saving, onTap: _loaded ? _save : null),
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
