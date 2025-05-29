import 'package:integration_test/integration_test.dart';
import 'signup_screen_test.dart' as signup_test;
import 'login_screen_test.dart' as login_test;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  signup_test.main();
  login_test.main();
}
