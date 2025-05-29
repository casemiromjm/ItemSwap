First, if you don't have google chome installed, install it.<p>
![install google chrome](https://www.google.com/intl/pt-PT/chrome/)

<p>
Then, open two terminals and write this two commands.
<p>

Separate terminal:<p>
```
chromedriver --port=4444
```

app terminal:<p>
```
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/account_flow_test.dart -d chrome
```

<p>
Finally, wait until all tests are made.
<p>

<p>
Or run in an android emulator:
<p>

To see allemulators:<p>
```
flutter emulators
```

Start one by its id/name:<p>
```
flutter emulators --launch [id/name]
```

run:<p>
```
flutter test integration_test/account_flow_test.dart --device-id emulator-5554
```