# Deprecated



# Dart-NATS 
A Dart client for the [NATS](https://nats.io) messaging system. Design to use with Dart and flutter.

### Flutter Web Support by WebSocket 
```dart
client.connect(Uri.parse('ws://localhost:80'));
client.connect(Uri.parse('wss://localhost:443'));
```


### Flutter Other Platform Support both TCP Socket and WebSocket
```dart
client.connect(Uri.parse('nats://localhost:4222'));
client.connect(Uri.parse('tls://localhost:4222'));
client.connect(Uri.parse('ws://localhost:80'));
client.connect(Uri.parse('wss://localhost:443'));
```

### background retry 
```dart
  // unawait 
   client.connect(Uri.parse('nats://localhost:4222'), retry: true, retryCount: -1);
  
  // await for connect if need
   await client.wait4Connected();

   // listen to status stream
   client.statusStream.lesten((status){
    // 
    print(status);
   });
```

### Turn off retry and catch exception
```dart
try {
  await client.connect(Uri.parse('nats://localhost:1234'), retry: false);
} on NatsException {
  //Error handle
}
```

## Dart Examples:

Run the `example/main.dart`:

```
dart example/main.dart
```

```dart
import 'package:dart_nats/dart_nats.dart';

void main() async {
  var client = Client();
  client.connect(Uri.parse('nats://localhost'));
  var sub = client.sub('subject1');
  await client.pubString('subject1', 'message1');
  var msg = await sub.stream.first;

  print(msg.string);
  client.unSub(sub);
  client.close();
}
```

## Flutter Examples:

Import and Declare object
```dart
import 'package:dart_nats/dart_nats.dart' as nats;

nats.Client natsClient;
nats.Subscription fooSub, barSub;
```

Simply connect to server and subscribe to subject
```dart
void connect() {
  natsClient = nats.Client();
  natsClient.connect(Uri.parse('nats://hostname');
  fooSub = natsClient.sub('foo');
  barSub = natsClient.sub('bar');
}
```
Use as Stream in StreamBuilder
```dart
StreamBuilder(
  stream: fooSub.stream,
  builder: (context, AsyncSnapshot<nats.Message> snapshot) {
    return Text(snapshot.hasData ? '${snapshot.data.string}' : '');
  },
),
```

Publish Message
```dart
      await natsClient.pubString('subject','message string');
```

Request 
```dart
var client = Client();
client.inboxPrefix = '_INBOX.test_test';
await client.connect(Uri.parse('nats://localhost:4222'));
var receive = await client.request(
    'service', Uint8List.fromList('request'.codeUnits));
```

Structure Request 
```dart
var client = Client();
await client.connect(Uri.parse('nats://localhost:4222'));
client.registerJsonDecoder<Student>(json2Student);
var receive = await client.requestString<Student>('service', '');
var student = receive.data;


Student json2Student(String json) {
  return Student.fromJson(jsonDecode(json));
}
```

Dispose 
```dart
  void dispose() {
    natsClient.close();
    super.dispose();
  }
```

## Authentication

Token Authtication 
```dart
var client = Client();
client.connect(Uri.parse('nats://localhost'),
          connectOption: ConnectOption(authToken: 'mytoken'));
```

User/Password Authentication
```dart
var client = Client();
client.connect(Uri.parse('nats://localhost'),
          connectOption: ConnectOption(user: 'foo', pass: 'bar'));
```

NKEY Authentication
```dart
var client = Client();
client.seed =
    'SUACSSL3UAHUDXKFSNVUZRF5UHPMWZ6BFDTJ7M6USDXIEDNPPQYYYCU3VY';
client.connect(
  Uri.parse('nats://localhost'),
  connectOption: ConnectOption(
    nkey: 'UDXU4RCSJNZOIQHZNWXHXORDPRTGNJAHAHFRGZNEEJCPQTT2M7NLCNF4',
  ),
);
```

JWT Authentication
```dart
var client = Client();
client.seed =
    'SUAJGSBAKQHGYI7ZVKVR6WA7Z5U52URHKGGT6ZICUJXMG4LCTC2NTLQSF4';
client.connect(
  Uri.parse('nats://localhost'),
  connectOption: ConnectOption(
    jwt:
        '''eyJ0eXAiOiJKV1QiLCJhbGciOiJlZDI1NTE5LW5rZXkifQ.eyJqdGkiOiJBU1pFQVNGMzdKS0dPTFZLTFdKT1hOM0xZUkpHNURJUFczUEpVT0s0WUlDNFFENlAyVFlRIiwiaWF0IjoxNjY0NTI0OTU5LCJpc3MiOiJBQUdTSkVXUlFTWFRDRkUzRVE3RzVPQldSVUhaVVlDSFdSM0dRVERGRldaSlM1Q1JLTUhOTjY3SyIsIm5hbWUiOiJzaWdudXAiLCJzdWIiOiJVQzZCUVY1Tlo1V0pQRUVZTTU0UkZBNU1VMk5NM0tON09WR01DU1VaV1dORUdZQVBNWEM0V0xZUCIsIm5hdHMiOnsicHViIjp7fSwic3ViIjp7fSwic3VicyI6LTEsImRhdGEiOi0xLCJwYXlsb2FkIjotMSwidHlwZSI6InVzZXIiLCJ2ZXJzaW9uIjoyfX0.8Q0HiN0h2tBvgpF2cAaz2E3WLPReKEnSmUWT43NSlXFNRpsCWpmkikxGgFn86JskEN4yast1uSj306JdOhyJBA''',
  ),
);
```




Full Flutter sample code [example/flutter/main.dart](https://github.com/chartchuo/dart-nats/blob/master/example/flutter/main_dart)

## Migration Guide: Upgrading to 1.0.0

### ⚠️ Breaking Changes

#### 1. Blocking Connection with Permission Error Detection
The `connect()` method now blocks until the connection is fully established and will throw immediately if permission errors are detected.

**Before (0.x):**
```dart
// Connection was async but didn't detect permission errors reliably
var client = Client();
await client.connect(Uri.parse('nats://localhost:4222'));
// Permission errors might be missed
```

**After (1.0.0):**
```dart
// Connection blocks and throws on permission errors
var client = Client();
try {
  await client.connect(Uri.parse('nats://localhost:4222'));
  // Connection is now guaranteed to be established
} catch (NatsException e) {
  // Permission or authentication errors are caught here
  print('Connection failed: ${e.message}');
}
```

#### 2. Subscription Permission Error Detection
The `sub()` method now throws immediately when subscription permissions are denied.

**Before (0.x):**
```dart
// Subscription errors might go unnoticed
var sub = client.sub('restricted.subject');
// No immediate feedback on permission issues
```

**After (1.0.0):**
```dart
// Subscription throws on permission errors
try {
  var sub = await client.sub('restricted.subject');
  // Subscription is guaranteed to be established
} catch (NatsException e) {
  // Permission errors are caught immediately
  print('Subscription failed: ${e.message}');
}
```

#### 3. Publishing with Permission Validation
Publishing operations now detect and report permission errors immediately.

**Code stays the same, but errors are now properly detected:**
```dart
try {
  await client.pubString('restricted.subject', 'message');
} catch (NatsException e) {
  // Permission errors for publishing are now caught
  print('Publish failed: ${e.message}');
}
```

### 🔧 Non-Verbose Mode Configuration

The timeout parameters are only relevant for **non-verbose** connections. In verbose mode, the server sends explicit acknowledgments.

**Configuring timeouts for non-verbose mode:**
```dart
var client = Client();
await client.connect(
  Uri.parse('nats://localhost:4222'),
  connectOption: ConnectOption(
    verbose: false, // Non-verbose mode
    subscriptionErrorTimeout: Duration(seconds: 3), // Time to wait for subscription errors
    connectionErrorTimeout: Duration(seconds: 5),   // Time to wait for connection errors
  ),
);
```

**In verbose mode, these timeouts are not needed:**
```dart
var client = Client();
await client.connect(
  Uri.parse('nats://localhost:4222'),
  connectOption: ConnectOption(
    verbose: true, // Server sends explicit +OK/-ERR responses
  ),
);
```

### ✅ Benefits of Upgrading

1. **Immediate Error Feedback**: Know instantly if permissions are denied
2. **Reliable Connection State**: `connect()` blocking ensures connection is ready
3. **Better Error Handling**: Clear exceptions for permission violations  
4. **Automatic Reconnection**: Enhanced reconnection when connections drop
5. **Configurable Timeouts**: Fine-tune error detection for your use case

### 📋 Migration Checklist

- [ ] Update error handling around `connect()` calls
- [ ] Add try-catch blocks around `sub()` calls for permission errors
- [ ] Update `ConnectOption` timeout parameter names if used
- [ ] Test permission scenarios to verify error detection works
- [ ] Update to version 1.0.0: `dart_nats: ^1.0.0`

## Features
The following is a list of features currently supported: 

- [x] - Publish
- [x] - Subscribe, unsubscribe
- [x] - NUID, Inbox
- [x] - Reconnect to single server when connection lost and resume subscription
- [x] - Unsubscribe after N message
- [x] - Request, Respond
- [x] - Queue subscribe
- [x] - Request timeout
- [x] - Events/status 
- [x] - Buffering message during reconnect atempts
- [x] - All authentication models, including NATS 2.0 JWT and nkey
- [x] - NATS 2.x 
- [x] - TLS 

Planned:
- [ ] - Connect to list of servers
