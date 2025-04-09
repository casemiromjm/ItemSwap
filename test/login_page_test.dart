void main() {
  // IMPORTANT: Set up the Firebase Core mocks at the very beginning.
  setupFirebaseAuthMocks();

  // Initialize Firebase before tests run.
  setUpAll(() async {
    await Firebase.initializeApp();
  });
