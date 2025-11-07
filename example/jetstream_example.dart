import 'dart:async';
import 'dart:convert';
import 'package:dart_nats/dart_nats.dart';

/// Example demonstrating JetStream usage with the dart-nats client
///
/// This example shows:
/// 1. Creating streams with different configurations
/// 2. Publishing messages with acknowledgments
/// 3. Creating consumers with various delivery policies
/// 4. Subscribing to messages with pull and push patterns
/// 5. Message acknowledgment handling
void main() async {
  final client = Client();

  try {
    // Connect to NATS server (assumes JetStream enabled)
    await client.connect(Uri.parse('nats://localhost:4222'));
    print('Connected to NATS server');

    // Create JetStream context
    final js = client.jetStream();
    print('Created JetStream context');

    // === STREAM MANAGEMENT ===

    // Create a stream for user events
    final userStream = await js.addStream(StreamConfig(
      name: 'USER_EVENTS',
      subjects: ['users.>', 'events.user.>'],
      retention: RetentionPolicy.limits,
      storage: StorageType.file,
      maxAge: const Duration(hours: 24),
      maxBytes: 10 * 1024 * 1024, // 10MB
      maxMsgs: 10000,
      replicas: 1,
    ));
    print('Created stream: ${userStream.config.name}');

    // Create a stream for analytics (memory storage for speed)
    final analyticsStream = await js.addStream(StreamConfig(
      name: 'ANALYTICS',
      subjects: ['analytics.>'],
      retention: RetentionPolicy.workQueue,
      storage: StorageType.memory,
      maxAge: const Duration(minutes: 30),
      maxMsgs: 1000,
      replicas: 1,
    ));
    print('Created stream: ${analyticsStream.config.name}');

    // === PUBLISHING ===

    // Publish user events with acknowledgments
    for (int i = 1; i <= 5; i++) {
      final userData = {
        'id': i,
        'name': 'User $i',
        'email': 'user$i@example.com',
        'timestamp': DateTime.now().toIso8601String(),
      };

      final ack = await js.publishString(
        'users.created',
        jsonEncode(userData),
        messageId: 'user-$i-${DateTime.now().millisecondsSinceEpoch}',
      );

      print('Published user $i, stream: ${ack.stream}, seq: ${ack.seq}');
    }

    // Publish analytics events
    for (int i = 1; i <= 3; i++) {
      final analyticsData = {
        'event': 'page_view',
        'page': '/dashboard',
        'user_id': i,
        'timestamp': DateTime.now().toIso8601String(),
      };

      await js.publishString('analytics.page_view', jsonEncode(analyticsData));
      print('Published analytics event $i');
    }

    // === CONSUMER CREATION ===

    // Create a durable consumer for user events (deliver all)
    final userConsumer = await js.addConsumer(
        'USER_EVENTS',
        ConsumerConfig(
          name: 'user-processor',
          durableName: 'user-processor',
          deliverPolicy: DeliverPolicy.all,
          ackPolicy: AckPolicy.explicit,
          maxDeliver: 3,
          ackWait: const Duration(seconds: 30),
          filterSubject: 'users.>',
        ));
    print('Created consumer: ${userConsumer.name}');

    // Create an ephemeral consumer for analytics (deliver new only)
    final analyticsConsumer = await js.addConsumer(
        'ANALYTICS',
        ConsumerConfig(
          deliverPolicy: DeliverPolicy.new_,
          ackPolicy: AckPolicy.explicit,
          filterSubject: 'analytics.>',
          replayPolicy: ReplayPolicy.instant,
        ));
    print('Created consumer: ${analyticsConsumer.name}');

    // === PULL SUBSCRIPTION ===

    print('\n=== Pull Subscription Example ===');
    final pullSub =
        await js.pullSubscribe('users.>', consumerName: 'user-processor');
    await pullSub.start();

    // Process messages with pull subscription
    int processedCount = 0;
    final subscription = pullSub.stream.listen((msg) async {
      try {
        final data = jsonDecode(msg.string);
        print('Received user event: ${data['name']} (${data['email']})');

        // Simulate processing
        await Future.delayed(const Duration(milliseconds: 100));

        // Acknowledge the message
        await msg.ack();
        print('Acknowledged message');

        processedCount++;
      } catch (e) {
        print('Error processing message: $e');
        // Negative acknowledge for redelivery
        await msg.nak();
      }
    });

    // Wait for messages to be processed
    await Future.delayed(const Duration(seconds: 2));
    print('Processed $processedCount messages via pull subscription');

    await subscription.cancel();
    await pullSub.close();

    // === PUSH SUBSCRIPTION ===

    print('\n=== Push Subscription Example ===');
    final pushSub = await js.pushSubscribe(
      'analytics.>',
      consumerName: analyticsConsumer.name,
    );
    await pushSub.start();

    // Process analytics messages
    int analyticsProcessed = 0;
    final analyticsSubscription = pushSub.stream.listen((msg) async {
      final data = jsonDecode(msg.string);
      print('Received analytics: ${data['event']} for user ${data['user_id']}');

      await msg.ack();
      analyticsProcessed++;
    });

    await Future.delayed(const Duration(seconds: 1));
    print(
        'Processed $analyticsProcessed analytics messages via push subscription');

    await analyticsSubscription.cancel();
    await pushSub.close();

    // === STREAM INFORMATION ===

    print('\n=== Stream Information ===');
    final streams = await js.listStreams();
    print('Available streams: ${streams.join(", ")}');

    for (final streamName in streams) {
      final info = await js.getStreamInfo(streamName);
      print('Stream $streamName:');
      print('  Messages: ${info.state.messages}');
      print('  Bytes: ${info.state.bytes}');
      print('  Consumers: ${info.state.consumers}');
      print('  First Seq: ${info.state.firstSeq}');
      print('  Last Seq: ${info.state.lastSeq}');
    }

    // === CLEANUP ===

    print('\n=== Cleanup ===');

    // Delete consumers
    await js.deleteConsumer('USER_EVENTS', 'user-processor');
    print('Deleted user-processor consumer');

    // Delete streams
    await js.deleteStream('USER_EVENTS');
    await js.deleteStream('ANALYTICS');
    print('Deleted streams');
  } catch (e) {
    print('Error: $e');
  } finally {
    await client.close();
    print('Disconnected from NATS');
  }
}

/// Example of advanced JetStream patterns
void advancedPatterns() async {
  final client = Client();

  try {
    await client.connect(Uri.parse('nats://localhost:4222'));
    final js = client.jetStream();

    // === EXACTLY-ONCE DELIVERY ===

    // Create stream with deduplication
    await js.addStream(StreamConfig(
      name: 'ORDERS',
      subjects: ['orders.>'],
      storage: StorageType.file,
      retention: RetentionPolicy.limits,
      duplicateWindow: const Duration(minutes: 2),
      maxAge: const Duration(hours: 1),
    ));

    // Publish with message ID for deduplication
    final orderId = 'order-12345';

    // This will be stored once, even if called multiple times
    for (int i = 0; i < 3; i++) {
      final ack = await js.publishString(
        'orders.created',
        jsonEncode({'orderId': orderId, 'amount': 99.99}),
        messageId: orderId, // Same message ID = deduplication
      );

      print('Publish $i: duplicate=${ack.duplicate}');
    }

    // === WORK QUEUE PATTERN ===

    // Create work queue consumer
    await js.addConsumer(
        'ORDERS',
        ConsumerConfig(
          name: 'order-worker',
          ackPolicy: AckPolicy.explicit,
          deliverPolicy: DeliverPolicy.all,
          maxDeliver: 3,
          ackWait: const Duration(seconds: 10),
        ));

    final workSub =
        await js.pullSubscribe('orders.>', consumerName: 'order-worker');
    await workSub.start();

    workSub.stream.listen((msg) async {
      final order = jsonDecode(msg.string);
      print('Processing order: ${order['orderId']}');

      // Simulate work
      await Future.delayed(const Duration(milliseconds: 500));

      if (order['orderId'].contains('12345')) {
        await msg.ack(); // Success
      } else {
        await msg.nak(); // Retry
      }
    });

    await Future.delayed(const Duration(seconds: 2));

    // === REPLAY FROM SPECIFIC POINT ===

    // Consumer that starts from a specific sequence
    await js.addConsumer(
        'ORDERS',
        ConsumerConfig(
          name: 'audit-consumer',
          deliverPolicy: DeliverPolicy.byStartSequence,
          optStartSeq: 1, // Start from beginning
          ackPolicy: AckPolicy.none, // No ack needed for audit
        ));

    final auditSub =
        await js.pullSubscribe('orders.>', consumerName: 'audit-consumer');
    await auditSub.start();

    auditSub.stream.listen((msg) {
      final order = jsonDecode(msg.string);
      print('Audit: ${order['orderId']}');
    });

    await Future.delayed(const Duration(seconds: 1));

    // Cleanup
    await js.deleteStream('ORDERS');
  } finally {
    await client.close();
  }
}
