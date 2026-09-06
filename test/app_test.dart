import 'package:flutterflow_ai/flutterflow_ai.dart';
import 'package:test/test.dart';

import '../dsl/edit.dart' as edit;

/// This is an EDIT flow: it references pages that only exist in the bound
/// project (`ResetPasswordPage`, `ProfilePage`) and uses `UpdatePassword`,
/// which the compiler gates on an active auth backend it can only see on the
/// real project. So `compileApp(...)` cannot run here with a null project —
/// full compilation is validated by `flutterflow ai run`, which loads the
/// remote project first. These tests cover the declaration layer instead.
void main() {
  late App app;
  late PageDeclaration updatePasswordPage;

  setUp(() {
    app = buildApp(edit.buildStarterEditFlow);
    updatePasswordPage =
        app.pages.singleWhere((p) => p.name == 'UpdatePasswordPage');
  });

  test('UpdatePasswordPage is declared idempotently', () {
    expect(app.ensurePageNames, contains('UpdatePasswordPage'));
  });

  test('UpdatePasswordPage lands on the recovery route', () {
    expect(updatePasswordPage.route, '/update-password');
    expect(updatePasswordPage.description, isNotNull);
  });

  test('UpdatePasswordPage declares both password state fields', () {
    expect(
      updatePasswordPage.state.keys,
      containsAll(<String>['password', 'confirmPassword']),
    );
  });
}
