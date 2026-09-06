library;

import 'dart:io';

import 'package:flutterflow_ai/flutterflow_ai.dart';

Future<void> main(List<String> args) async {
  final options = _parseCliOptions(args);
  try {
    await flutterFlowAI(
      buildUseItFreshCreateFlow,
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
Run the starter FlutterFlow AI create flow.

Usage:
  dart run dsl/create.dart [options]

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

/// Use It Fresh — Phase 1 (Foundation), per spec §19 + addendum 01.
/// Supabase auth + profile, household create/join, canonical 5-tab nav,
/// and the §16 design system. Later phases add inventory, AI capture,
/// assessments, recipes, and insights.
void buildUseItFreshCreateFlow(App app) {
  // ---------------------------------------------------------------------
  // Design system (spec §16): fresh green, warm cream surfaces, charcoal
  // text, amber/orange urgency, red reserved for safety, cool blue frozen.
  // ---------------------------------------------------------------------
  app.themeColor('primary', 0xFF2F8A57, dark: 0xFF5FB57F);
  app.themeColor('secondary', 0xFF1F5C3D, dark: 0xFF3E7A5A);
  app.themeColor('tertiary', 0xFFE8853D, dark: 0xFFE8944F);
  app.themeColor('alternate', 0xFFE7E4D8, dark: 0xFF33402F);
  app.themeColor('primaryBackground', 0xFFFAF8F1, dark: 0xFF141A14);
  app.themeColor('secondaryBackground', 0xFFFFFFFF, dark: 0xFF1C241C);
  app.themeColor('primaryText', 0xFF22301F, dark: 0xFFE6EDE3);
  app.themeColor('secondaryText', 0xFF5C6A58, dark: 0xFF9FAF9B);
  app.themeColor('accent1', 0x4C2F8A57);
  app.themeColor('accent2', 0x4D1F5C3D);
  app.themeColor('accent3', 0x4DE8853D);
  app.themeColor('accent4', 0xCCFFFFFF, dark: 0xB2141A14);
  app.themeColor('success', 0xFF2E7D4F, dark: 0xFF5FB57F);
  app.themeColor('warning', 0xFFE0A72E, dark: 0xFFD9A54A);
  app.themeColor('error', 0xFFC44536, dark: 0xFFE08A79);
  app.themeColor('info', 0xFF3B78B5, dark: 0xFF86AED6);
  app.primaryFont('Figtree');
  app.darkMode(enabled: true);

  // ---------------------------------------------------------------------
  // Supabase backend (project "UseItFresh"). Anon key is the public
  // client key; schema + RLS live in supabase/migrations/.
  // ---------------------------------------------------------------------
  app.supabase(
    url: 'https://ltdvxdizjrkgwldbmbbf.supabase.co',
    anonKey: 'sb_publishable_DsPbhjNRn6D0RONf9XvOWw_T0YjTNUr',
    connectedProjectId: 'ltdvxdizjrkgwldbmbbf',
    connectedProjectName: 'UseItFresh',
  );

  // ------------------------------------------------------------------
  // Postgres tables Phase 1 touches (subset of the full §11 schema).
  // ------------------------------------------------------------------
  final profiles = app.table(
    'profiles',
    fields: {
      'id': const PostgresTableField(
        string,
        postgresType: 'uuid',
        isPrimaryKey: true,
      ),
      'display_name': const PostgresTableField(string, postgresType: 'text'),
      'avatar_url': const PostgresTableField(string, postgresType: 'text'),
      'country_code': const PostgresTableField(string, postgresType: 'text'),
      'locale': const PostgresTableField(string, postgresType: 'text'),
      'unit_system': const PostgresTableField(
        string,
        postgresType: 'text',
        hasDefault: true,
      ),
    },
    description: 'One row per signed-in user; auto-created on signup.',
  );

  final households = app.table(
    'households',
    fields: {
      'id': const PostgresTableField(
        string,
        postgresType: 'uuid',
        isPrimaryKey: true,
        hasDefault: true,
      ),
      'name': const PostgresTableField(
        string,
        postgresType: 'text',
        isRequired: true,
      ),
      'owner_id': const PostgresTableField(
        string,
        postgresType: 'uuid',
        hasDefault: true,
      ),
      'invite_code': const PostgresTableField(
        string,
        postgresType: 'text',
        hasDefault: true,
      ),
    },
    description:
        'Shared inventory space. Creating one auto-adds the owner as a member '
        'plus default Fridge/Freezer/Pantry locations (DB trigger).',
  );

  app.table(
    'household_members',
    fields: {
      'household_id': const PostgresTableField(
        string,
        postgresType: 'uuid',
        isRequired: true,
      ),
      'profile_id': const PostgresTableField(
        string,
        postgresType: 'uuid',
        isRequired: true,
      ),
      'role': const PostgresTableField(
        string,
        postgresType: 'text',
        hasDefault: true,
      ),
    },
    description: 'Membership + role (owner/admin/member) per household.',
  );

  app.table(
    'storage_locations',
    fields: {
      'id': const PostgresTableField(
        string,
        postgresType: 'uuid',
        isPrimaryKey: true,
        hasDefault: true,
      ),
      'household_id': const PostgresTableField(
        string,
        postgresType: 'uuid',
        isRequired: true,
      ),
      'name': const PostgresTableField(
        string,
        postgresType: 'text',
        isRequired: true,
      ),
      'location_type': const PostgresTableField(
        string,
        postgresType: 'text',
        isRequired: true,
      ),
      'is_default': const PostgresTableField(
        bool_,
        postgresType: 'bool',
        hasDefault: true,
      ),
    },
    description: 'Fridge/freezer/pantry spots inside a household.',
  );

  // ------------------------------------------------------------------
  // Reusable components
  // ------------------------------------------------------------------
  final dynamic emptyState = app.component(
    'EmptyStateCard',
    params: {
      'title': string.withDefault('Nothing here yet'),
      'message': string.withDefault('This area fills in as you use the app.'),
    },
    description: 'Friendly empty state used by list screens before data exists.',
    body: Container(
      padding: 32,
      width: double.infinity,
      borderRadius: 12,
      color: Colors.secondaryBackground,
      child: Column(
        spacing: 10,
        children: [
          Icon('eco', size: 44, color: Colors.primary),
          Text(
            Param('title'),
            style: Styles.titleMedium,
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
          Text(
            Param('message'),
            style: Styles.bodyMedium,
            color: Colors.secondaryText,
            textAlign: TextAlign.center,
            maxLines: 3,
          ),
        ],
      ),
    ),
  );

  // ------------------------------------------------------------------
  // Auth pages (spec §8.1–8.2)
  // ------------------------------------------------------------------
  final resetPasswordPage = app.page(
    'ResetPasswordPage',
    route: '/reset-password',
    description: 'Sends a Supabase password-reset email.',
    state: {'email': string.withDefault('')},
    body: Scaffold(
      appBar: AppBar(title: 'Reset password'),
      body: Container(
        padding: 24,
        child: Column(
          spacing: 16,
          crossAxis: CrossAxis.start,
          children: [
            Text(
              'Enter your email and we will send you a reset link.',
              style: Styles.bodyMedium,
              color: Colors.secondaryText,
            ),
            TextField(
              name: 'ResetEmailField',
              label: 'Email',
              hint: 'you@example.com',
              keyboard: Keyboard.email,
              onChanged: SetState('email', const TextValue()),
            ),
            Button(
              'Send reset link',
              name: 'SendResetLinkButton',
              width: double.infinity,
              borderRadius: 12,
              onTap: [
                ResetPassword(State('email')),
                Snackbar('Reset email sent — check your inbox.'),
                const NavigateBack(),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  final signInPage = app.page(
    'SignInPage',
    route: '/sign-in',
    description: 'Email/password sign-in.',
    state: {'email': string.withDefault(''), 'password': string.withDefault('')},
    body: Scaffold(
      appBar: AppBar(title: 'Sign in'),
      body: Container(
        padding: 24,
        child: Column(
          spacing: 16,
          crossAxis: CrossAxis.start,
          scrollable: true,
          children: [
            TextField(
              name: 'SignInEmailField',
              label: 'Email',
              hint: 'you@example.com',
              keyboard: Keyboard.email,
              onChanged: SetState('email', const TextValue()),
            ),
            TextField(
              name: 'SignInPasswordField',
              label: 'Password',
              obscureText: true,
              onChanged: SetState('password', const TextValue()),
            ),
            Button(
              'Sign in',
              name: 'SignInButton',
              width: double.infinity,
              borderRadius: 12,
              onTap: [LoginEmailPassword(State('email'), State('password'))],
            ),
            Button(
              'Forgot password?',
              name: 'ForgotPasswordButton',
              variant: ButtonVariant.text,
              onTap: Navigate(resetPasswordPage),
            ),
          ],
        ),
      ),
    ),
  );

  final signUpPage = app.page(
    'SignUpPage',
    route: '/sign-up',
    description: 'Email/password account creation.',
    state: {
      'email': string.withDefault(''),
      'password': string.withDefault(''),
      'confirmPassword': string.withDefault(''),
    },
    body: Scaffold(
      appBar: AppBar(title: 'Create account'),
      body: Container(
        padding: 24,
        child: Column(
          spacing: 16,
          crossAxis: CrossAxis.start,
          scrollable: true,
          children: [
            TextField(
              name: 'SignUpEmailField',
              label: 'Email',
              hint: 'you@example.com',
              keyboard: Keyboard.email,
              onChanged: SetState('email', const TextValue()),
            ),
            TextField(
              name: 'SignUpPasswordField',
              label: 'Password',
              obscureText: true,
              onChanged: SetState('password', const TextValue()),
            ),
            TextField(
              name: 'SignUpConfirmField',
              label: 'Confirm password',
              obscureText: true,
              onChanged: SetState('confirmPassword', const TextValue()),
            ),
            Button(
              'Create account',
              name: 'CreateAccountButton',
              width: double.infinity,
              borderRadius: 12,
              onTap: [
                SignupEmailPassword(
                  State('email'),
                  State('password'),
                  confirmPassword: State('confirmPassword'),
                ),
              ],
            ),
            Text(
              'By continuing you agree to our terms and acknowledge that '
              'Use It Fresh gives general food-management guidance, not a '
              'guarantee of safety.',
              style: Styles.bodySmall,
              color: Colors.secondaryText,
              maxLines: 4,
            ),
          ],
        ),
      ),
    ),
  );

  final welcomePage = app.page(
    'WelcomePage',
    route: '/',
    isInitial: true,
    description: 'Brand welcome screen; routes to sign in / sign up.',
    body: Scaffold(
      body: Container(
        padding: 24,
        child: Column(
          spacing: 20,
          scrollable: true,
          children: [
            Container(
              width: 96,
              height: 96,
              borderRadius: 48,
              color: Colors.primary,
              alignment: Alignment.center,
              child: Icon('eco', size: 52, color: Colors.secondaryBackground),
            ),
            Text('Use It Fresh', style: Styles.headlineMedium),
            Text(
              'Know what you have, what to use next, and never waste good '
              'food again.',
              style: Styles.bodyLarge,
              color: Colors.secondaryText,
              textAlign: TextAlign.center,
              maxLines: 3,
            ),
            Button(
              'Get started',
              name: 'GetStartedButton',
              width: double.infinity,
              borderRadius: 12,
              onTap: Navigate(signUpPage),
            ),
            Button(
              'I already have an account',
              name: 'GoToSignInButton',
              variant: ButtonVariant.outlined,
              width: double.infinity,
              borderRadius: 12,
              onTap: Navigate(signInPage),
            ),
          ],
        ),
      ),
    ),
  );

  // ------------------------------------------------------------------
  // Onboarding + household setup (spec §8.3, §7)
  // ------------------------------------------------------------------
  final householdSetupPage = app.page(
    'HouseholdSetupPage',
    route: '/household-setup',
    description: 'Create a household or join one with an invite code.',
    state: {
      'householdName': string.withDefault(''),
      'inviteCode': string.withDefault(''),
    },
    body: Scaffold(
      appBar: AppBar(title: 'Your household'),
      body: Container(
        padding: 24,
        child: Column(
          spacing: 20,
          crossAxis: CrossAxis.start,
          scrollable: true,
          children: [
            Text(
              'A household is the shared space where your fridge, freezer, '
              'and pantry live. Create one, or join your family’s.',
              style: Styles.bodyMedium,
              color: Colors.secondaryText,
              maxLines: 3,
            ),
            Container(
              padding: 20,
              width: double.infinity,
              borderRadius: 12,
              color: Colors.secondaryBackground,
              child: Column(
                spacing: 12,
                crossAxis: CrossAxis.start,
                children: [
                  Text('Create a household', style: Styles.titleMedium),
                  TextField(
                    name: 'HouseholdNameField',
                    label: 'Household name',
                    hint: 'e.g. The Elashirys',
                    onChanged: SetState('householdName', const TextValue()),
                  ),
                  Button(
                    'Create household',
                    name: 'CreateHouseholdButton',
                    width: double.infinity,
                    borderRadius: 12,
                    onTap: [
                      PostgresCreate(
                        households,
                        fields: {'name': State('householdName')},
                        outputAs: 'createdHousehold',
                      ),
                      Snackbar('Household created — welcome home!'),
                      Navigate('HomePage'),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: 20,
              width: double.infinity,
              borderRadius: 12,
              color: Colors.secondaryBackground,
              child: Column(
                spacing: 12,
                crossAxis: CrossAxis.start,
                children: [
                  Text('Join with an invite code', style: Styles.titleMedium),
                  TextField(
                    name: 'InviteCodeField',
                    label: 'Invite code',
                    hint: '8-letter code from a household member',
                    onChanged: SetState('inviteCode', const TextValue()),
                  ),
                  Button(
                    'Join household',
                    name: 'JoinHouseholdButton',
                    variant: ButtonVariant.outlined,
                    width: double.infinity,
                    borderRadius: 12,
                    onTap: [
                      Snackbar(
                        'Invite joining unlocks in the next update — '
                        'create your own household for now.',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );

  final onboardingPage = app.page(
    'OnboardingPage',
    route: '/onboarding',
    description: 'Collects display name and units, saved to the profile.',
    state: {
      'displayName': string.withDefault(''),
      'useImperial': bool_.withDefault(false),
    },
    body: Scaffold(
      appBar: AppBar(title: 'Set up your profile'),
      body: Container(
        padding: 24,
        child: Column(
          spacing: 16,
          crossAxis: CrossAxis.start,
          scrollable: true,
          children: [
            TextField(
              name: 'DisplayNameField',
              label: 'Your name',
              hint: 'What should we call you?',
              onChanged: SetState('displayName', const TextValue()),
            ),
            Checkbox(
              name: 'UseImperialCheckbox',
              label: 'Use imperial units (lb, oz, °F)',
              value: State('useImperial'),
              onChanged: SetState('useImperial', const WidgetValue()),
            ),
            Text(
              'Dietary preferences and allergies arrive with recipe '
              'features. Allergy filtering will never be a medical guarantee.',
              style: Styles.bodySmall,
              color: Colors.secondaryText,
              maxLines: 3,
            ),
            Button(
              'Save and continue',
              name: 'SaveProfileButton',
              width: double.infinity,
              borderRadius: 12,
              onTap: [
                PostgresUpdate(
                  profiles,
                  outputAs: 'updatedProfileName',
                  fields: {'display_name': State('displayName')},
                  query: PostgresQuerySpec(
                    filters: [
                      PostgresFilter(
                        'id',
                        relation: PostgresFilterRelation.equalTo,
                        value: const AuthUser(AuthUserField.userId),
                      ),
                    ],
                    isSingleRow: true,
                  ),
                ),
                If(
                  State('useImperial'),
                  then: [
                    PostgresUpdate(
                      profiles,
                      outputAs: 'unitsImperial',
                      fields: {'unit_system': 'imperial'},
                      query: PostgresQuerySpec(
                        filters: [
                          PostgresFilter(
                            'id',
                            relation: PostgresFilterRelation.equalTo,
                            value: const AuthUser(AuthUserField.userId),
                          ),
                        ],
                        isSingleRow: true,
                      ),
                    ),
                  ],
                  orElse: [
                    PostgresUpdate(
                      profiles,
                      outputAs: 'unitsMetric',
                      fields: {'unit_system': 'metric'},
                      query: PostgresQuerySpec(
                        filters: [
                          PostgresFilter(
                            'id',
                            relation: PostgresFilterRelation.equalTo,
                            value: const AuthUser(AuthUserField.userId),
                          ),
                        ],
                        isSingleRow: true,
                      ),
                    ),
                  ],
                ),
                Snackbar('Profile saved'),
                Navigate(householdSetupPage),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  // ------------------------------------------------------------------
  // Main shell pages (spec §8.4, §8.5, §8.6, §8.9, §8.14 — Phase 1 shells)
  // ------------------------------------------------------------------
  final homePage = app.page(
    'HomePage',
    route: '/home',
    description: 'Dashboard: greeting, setup prompts, use-first placeholder.',
    body: Scaffold(
      appBar: AppBar(title: 'Use It Fresh'),
      body: Container(
        padding: 20,
        child: Column(
          spacing: 16,
          crossAxis: CrossAxis.start,
          scrollable: true,
          children: [
            Text('Welcome back 👋', style: Styles.headlineSmall),
            Text(
              const AuthUser(AuthUserField.email),
              style: Styles.bodyMedium,
              color: Colors.secondaryText,
              maxLines: 1,
            ),
            Container(
              padding: 20,
              width: double.infinity,
              borderRadius: 12,
              color: Colors.secondaryBackground,
              child: Column(
                spacing: 12,
                crossAxis: CrossAxis.start,
                children: [
                  Text('Finish setting up', style: Styles.titleMedium),
                  Button(
                    'Complete your profile',
                    name: 'GoToOnboardingButton',
                    variant: ButtonVariant.outlined,
                    width: double.infinity,
                    borderRadius: 12,
                    icon: 'person',
                    onTap: Navigate(onboardingPage),
                  ),
                  Button(
                    'Create or join a household',
                    name: 'GoToHouseholdButton',
                    variant: ButtonVariant.outlined,
                    width: double.infinity,
                    borderRadius: 12,
                    icon: 'group',
                    onTap: Navigate(householdSetupPage),
                  ),
                ],
              ),
            ),
            Text('Use first', style: Styles.titleLarge),
            emptyState(
              title: 'Nothing to use up yet',
              message:
                  'Once your inventory is in, the items to use first show '
                  'up here.',
            ),
            Text('Quick add', style: Styles.titleLarge),
            Button(
              'Add food manually',
              name: 'QuickAddManualButton',
              width: double.infinity,
              borderRadius: 12,
              icon: 'add',
              onTap: Snackbar('Manual add arrives with Phase 2 (inventory).'),
            ),
            Button(
              'Scan an item with AI',
              name: 'QuickAddScanButton',
              variant: ButtonVariant.outlined,
              width: double.infinity,
              borderRadius: 12,
              icon: 'photo_camera',
              onTap: Snackbar('AI scanning arrives with Phase 3.'),
            ),
          ],
        ),
      ),
    ),
  );

  final inventoryPage = app.page(
    'InventoryPage',
    route: '/inventory',
    description: 'Inventory list shell; real lists land in Phase 2.',
    body: Scaffold(
      appBar: AppBar(title: 'Inventory'),
      body: Container(
        padding: 20,
        child: Column(
          spacing: 16,
          crossAxis: CrossAxis.start,
          children: [
            emptyState(
              title: 'Your inventory is empty',
              message:
                  'Fridge, freezer, and pantry views — with urgency sorting '
                  '— arrive in the next update.',
            ),
          ],
        ),
      ),
    ),
  );

  final scanAddPage = app.page(
    'ScanAddPage',
    route: '/scan',
    description: 'Capture hub: the five ways to add food (§8.6). Shell for now.',
    body: Scaffold(
      appBar: AppBar(title: 'Add food'),
      body: Container(
        padding: 20,
        child: Column(
          spacing: 12,
          crossAxis: CrossAxis.start,
          scrollable: true,
          children: [
            Text(
              'Five ways to add food. AI capture lands in Phase 3 — manual '
              'entry in Phase 2.',
              style: Styles.bodyMedium,
              color: Colors.secondaryText,
              maxLines: 3,
            ),
            Button(
              'Photograph one item',
              name: 'ScanItemButton',
              variant: ButtonVariant.outlined,
              width: double.infinity,
              borderRadius: 12,
              icon: 'photo_camera',
              onTap: Snackbar('Item photo scanning arrives in Phase 3.'),
            ),
            Button(
              'Scan a barcode',
              name: 'ScanBarcodeButton',
              variant: ButtonVariant.outlined,
              width: double.infinity,
              borderRadius: 12,
              icon: 'qr_code_scanner',
              onTap: Snackbar('Barcode scanning arrives in Phase 3.'),
            ),
            Button(
              'Scan a receipt',
              name: 'ScanReceiptButton',
              variant: ButtonVariant.outlined,
              width: double.infinity,
              borderRadius: 12,
              icon: 'receipt_long',
              onTap: Snackbar('Receipt scanning arrives in Phase 3.'),
            ),
            Button(
              'Scan your fridge',
              name: 'ScanFridgeButton',
              variant: ButtonVariant.outlined,
              width: double.infinity,
              borderRadius: 12,
              icon: 'kitchen',
              onTap: Snackbar('Fridge-scene scanning arrives in Phase 3.'),
            ),
            Button(
              'Add manually',
              name: 'AddManualButton',
              width: double.infinity,
              borderRadius: 12,
              icon: 'add',
              onTap: Snackbar('Manual add arrives with Phase 2 (inventory).'),
            ),
          ],
        ),
      ),
    ),
  );

  final recipesPage = app.page(
    'RecipesPage',
    route: '/recipes',
    description: 'Use-first recipe shell; generation lands in Phase 5.',
    body: Scaffold(
      appBar: AppBar(title: 'Recipes'),
      body: Container(
        padding: 20,
        child: Column(
          spacing: 16,
          crossAxis: CrossAxis.start,
          children: [
            emptyState(
              title: 'What can I make?',
              message:
                  'Recipes that use up your most urgent ingredients arrive '
                  'once your inventory is live.',
            ),
          ],
        ),
      ),
    ),
  );

  final profilePage = app.page(
    'ProfilePage',
    route: '/profile',
    description: 'Account overview, settings entry points, sign out.',
    body: Scaffold(
      appBar: AppBar(title: 'Profile'),
      body: Container(
        padding: 20,
        child: Column(
          spacing: 12,
          crossAxis: CrossAxis.start,
          scrollable: true,
          children: [
            Text(
              const AuthUser(AuthUserField.email),
              style: Styles.titleMedium,
              maxLines: 1,
            ),
            ListTile(
              title: 'Profile & units',
              subtitle: 'Name, metric or imperial',
              leadingIcon: 'person',
              trailingIcon: 'chevron_right',
            ),
            Button(
              'Edit profile',
              name: 'EditProfileButton',
              variant: ButtonVariant.outlined,
              width: double.infinity,
              borderRadius: 12,
              onTap: Navigate(onboardingPage),
            ),
            ListTile(
              title: 'Household',
              subtitle: 'Members, invites, shared inventory',
              leadingIcon: 'group',
              trailingIcon: 'chevron_right',
            ),
            Button(
              'Manage household',
              name: 'ManageHouseholdButton',
              variant: ButtonVariant.outlined,
              width: double.infinity,
              borderRadius: 12,
              onTap: Navigate(householdSetupPage),
            ),
            Text(
              'Use It Fresh provides general food-management guidance, not '
              'a guarantee of safety. When in doubt — especially with '
              'high-risk food — throw it out and follow local food-safety '
              'advice.',
              style: Styles.bodySmall,
              color: Colors.secondaryText,
              maxLines: 5,
            ),
            Button(
              'Sign out',
              name: 'SignOutButton',
              variant: ButtonVariant.text,
              width: double.infinity,
              onTap: const [Logout()],
            ),
          ],
        ),
      ),
    ),
  );

  // ------------------------------------------------------------------
  // Canonical bottom navigation (spec §9) + auth routing
  // ------------------------------------------------------------------
  app.bottomNav(
    items: [
      BottomNavItem(homePage, icon: 'home'),
      BottomNavItem(inventoryPage, icon: 'inventory_2'),
      BottomNavItem(scanAddPage, icon: 'add_circle'),
      BottomNavItem(recipesPage, icon: 'restaurant'),
      BottomNavItem(profilePage, icon: 'person'),
    ],
    backgroundColor: Colors.secondaryBackground,
    selectedColor: Colors.primary,
    unselectedColor: Colors.secondaryText,
  );

  app.supabaseAuth(
    providers: const [SupabaseAuthProvider.email],
    homePage: homePage,
    signInPage: welcomePage,
  );
}
