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
- [x] - JetStream (message persistence, delivery guarantees)

Planned:
- [ ] - Connect to list of servers
- [ ] - Key-Value Store (JetStream KV)
- [ ] - Object Store (JetStream Object Store)

## JetStream Support

**JetStream** provides message persistence, delivery guarantees, and advanced messaging patterns beyond basic pub/sub. Perfect for reliable event sourcing, message replay, and at-least-once delivery guarantees.

### Quick Start with JetStream

```dart
import 'package:dart_nats/dart_nats.dart';

void main() async {
  var client = Client();
  await client.connect(Uri.parse('nats://localhost:4222'));
  
  // Create JetStream context
  var js = client.jetStream();
  
  // Create a stream for events
  await js.addStream(StreamConfig(
    name: 'EVENTS',
    subjects: ['events.>'],
    retention: RetentionPolicy.limits,
    storage: StorageType.file,
    maxAge: Duration(hours: 24),
  ));
  
  // Publish with acknowledgment guarantee
  var ack = await js.publishString('events.user.login', '{"userId": 123}');
  print('Message stored at sequence: ${ack.seq}');
  
  // Create consumer with delivery guarantees
  await js.addConsumer('EVENTS', ConsumerConfig(
    name: 'user-events-processor',
    deliverPolicy: DeliverPolicy.all,
    ackPolicy: AckPolicy.explicit,
  ));
  
  // Subscribe and process messages reliably
  var sub = await js.pullSubscribe('events.>', consumerName: 'user-events-processor');
  await sub.start();
  
  await for (var msg in sub.stream) {
    try {
      // Process message
      print('Processing: ${msg.string}');
      
      // Acknowledge successful processing
      await msg.ack();
    } catch (e) {
      // Negative acknowledge for redelivery
      await msg.nak();
    }
  }
}
```

### Core JetStream Features

#### 1. Stream Management
Create persistent streams that store messages:

```dart
// Basic stream
await js.addStream(StreamConfig(
  name: 'ORDERS', 
  subjects: ['orders.>'],
));

// Stream with retention and limits
await js.addStream(StreamConfig(
  name: 'USER_EVENTS',
  subjects: ['users.created', 'users.updated'],
  retention: RetentionPolicy.limits,
  storage: StorageType.file,
  maxAge: Duration(days: 7),
  maxBytes: 100 * 1024 * 1024, // 100MB
  maxMsgs: 10000,
  replicas: 1,
));

// Work queue (messages deleted after acknowledgment)
await js.addStream(StreamConfig(
  name: 'WORK_QUEUE',
  subjects: ['jobs.>'],
  retention: RetentionPolicy.workQueue,
  storage: StorageType.memory,
));
```

#### 2. Publishing with Guarantees
Publish messages with delivery confirmation:

```dart
// Simple publish with acknowledgment
var ack = await js.publishString('orders.created', jsonEncode(order));
print('Stored at sequence: ${ack.seq}, stream: ${ack.stream}');

// Publish with deduplication
var ack = await js.publishString(
  'orders.created',
  jsonEncode(order),
  messageId: 'order-${order.id}', // Prevents duplicates
);

// Publish with expected stream state
var ack = await js.publishString(
  'orders.updated',
  jsonEncode(order),
  expectedLastSeq: 41, // Only accept if last sequence is 41
);
```

#### 3. Consumer Patterns

**Durable Consumers** (survive restarts):
```dart
await js.addConsumer('EVENTS', ConsumerConfig(
  name: 'analytics-processor',
  durableName: 'analytics-processor',
  deliverPolicy: DeliverPolicy.all,
  ackPolicy: AckPolicy.explicit,
  filterSubject: 'events.analytics.>',
));
```

**Ephemeral Consumers** (temporary):
```dart
await js.addConsumer('EVENTS', ConsumerConfig(
  deliverPolicy: DeliverPolicy.new_, // Only new messages
  ackPolicy: AckPolicy.explicit,
  filterSubject: 'events.user.>',
));
```

**Work Queue Consumers** (competing consumers):
```dart
await js.addConsumer('WORK_QUEUE', ConsumerConfig(
  name: 'job-worker',
  ackPolicy: AckPolicy.explicit,
  maxDeliver: 3, // Retry failed jobs 3 times
  ackWait: Duration(seconds: 30), // 30s to process
));
```

#### 4. Subscription Patterns

**Pull-Based Subscriptions** (recommended):
```dart
var sub = await js.pullSubscribe('events.>', consumerName: 'my-consumer');
await sub.start();

await for (var msg in sub.stream) {
  // Process at your own pace
  await processEvent(msg.string);
  await msg.ack();
}
```

**Push-Based Subscriptions**:
```dart
var sub = await js.pushSubscribe(
  'events.user.>',
  deliverSubject: 'deliver.user.events', // Custom delivery subject
);
await sub.start();

sub.stream.listen((msg) async {
  await processUserEvent(msg.string);
  await msg.ack();
});
```

#### 5. Message Acknowledgment

```dart
await for (var msg in subscription.stream) {
  try {
    // Successful processing
    await processMessage(msg.string);
    await msg.ack(); // Acknowledge success
    
  } catch (RetryableError e) {
    // Temporary failure - retry later
    await msg.nak(); // Negative acknowledge for redelivery
    
  } catch (PermanentError e) {
    // Permanent failure - don't retry
    await msg.term(); // Terminate (won't redeliver)
    
  } catch (SlowProcessing e) {
    // Need more time
    await msg.inProgress(); // Extend ack deadline
  }
}
```

#### 6. Stream Information

```dart
// List all streams
var streams = await js.listStreams();
print('Available streams: ${streams.join(", ")}');

// Get stream details
var info = await js.getStreamInfo('EVENTS');
print('Messages in stream: ${info.state.messages}');
print('Stream size: ${info.state.bytes} bytes');
print('Active consumers: ${info.state.consumers}');

// Consumer information
var consumerInfo = await js.getConsumerInfo('EVENTS', 'my-consumer');
print('Pending messages: ${consumerInfo.numPending}');
print('Delivered count: ${consumerInfo.delivered.streamSeq}');
```

### Advanced Patterns

#### Message Replay from Specific Point
```dart
// Replay from sequence number
await js.addConsumer('EVENTS', ConsumerConfig(
  name: 'audit-replay',
  deliverPolicy: DeliverPolicy.byStartSequence,
  optStartSeq: 1000, // Start from message 1000
  ackPolicy: AckPolicy.none, // Read-only replay
));

// Replay from timestamp
await js.addConsumer('EVENTS', ConsumerConfig(
  name: 'time-replay',
  deliverPolicy: DeliverPolicy.byStartTime,
  optStartTime: DateTime.now().subtract(Duration(hours: 2)),
));
```

#### Exactly-Once Processing with Deduplication
```dart
// Stream with deduplication window
await js.addStream(StreamConfig(
  name: 'PAYMENTS',
  subjects: ['payments.>'],
  duplicateWindow: Duration(minutes: 5), // 5-minute dedup window
));

// Publish with unique message ID
for (var payment in payments) {
  var ack = await js.publishString(
    'payments.processed',
    jsonEncode(payment),
    messageId: 'payment-${payment.id}', // Deduplication key
  );
  
  if (ack.duplicate) {
    print('Payment ${payment.id} was already processed');
  } else {
    print('Payment ${payment.id} recorded at sequence ${ack.seq}');
  }
}
```

#### Stream Cleanup
```dart
// Delete consumer
await js.deleteConsumer('EVENTS', 'old-consumer');

// Delete stream (WARNING: removes all messages)
await js.deleteStream('TEMP_STREAM');
```

### JetStream Configuration Options

#### Stream Storage Types:
- **`StorageType.file`**: Persistent disk storage
- **`StorageType.memory`**: In-memory (faster, not persistent)

#### Retention Policies:
- **`RetentionPolicy.limits`**: Keep until limits exceeded
- **`RetentionPolicy.interest`**: Keep until all consumers acknowledge
- **`RetentionPolicy.workQueue`**: Delete after acknowledgment

#### Delivery Policies:
- **`DeliverPolicy.all`**: Deliver all messages in stream
- **`DeliverPolicy.last`**: Start with last message per subject
- **`DeliverPolicy.new_`**: Only new messages
- **`DeliverPolicy.byStartSequence`**: Start from specific sequence
- **`DeliverPolicy.byStartTime`**: Start from specific time

#### Acknowledgment Policies:
- **`AckPolicy.none`**: No acknowledgment required
- **`AckPolicy.all`**: Acknowledge processing of message
- **`AckPolicy.explicit`**: Must explicitly ack each message

### Error Handling

```dart
try {
  await js.addStream(config);
} on JetStreamException catch (e) {
  if (e.code == 10058) {
    print('Stream name already in use');
  } else {
    print('JetStream error: ${e.message}');
  }
}
```

For complete examples, see `example/jetstream_example.dart`.
