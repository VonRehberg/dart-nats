import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'client.dart';
import 'inbox.dart';
import 'jetstream.dart';
import 'message.dart';
import 'subscription.dart';

/// JetStream context for managing streams, consumers, and publishing
class JetStreamContext {
  final Client _client;
  final String _apiPrefix;
  final Duration _requestTimeout;

  JetStreamContext._(
    this._client, {
    String apiPrefix = '\$JS.API',
    Duration requestTimeout = const Duration(seconds: 5),
  })  : _apiPrefix = apiPrefix,
        _requestTimeout = requestTimeout;

  /// Create a JetStream context from a NATS client
  static JetStreamContext from(
    Client client, {
    String apiPrefix = '\$JS.API',
    Duration requestTimeout = const Duration(seconds: 5),
  }) {
    return JetStreamContext._(client,
        apiPrefix: apiPrefix, requestTimeout: requestTimeout);
  }

  /// Create or update a stream
  Future<StreamInfo> addStream(StreamConfig config) async {
    final subject = '$_apiPrefix.STREAM.CREATE.${config.name}';
    final payload = jsonEncode(config.toJson());

    final response =
        await _client.requestString(subject, payload, timeout: _requestTimeout);
    final responseData = jsonDecode(response.string);

    if (responseData['error'] != null) {
      throw JetStreamException(
        responseData['error']['description'],
        code: responseData['error']['code'],
      );
    }

    return StreamInfo.fromJson(responseData);
  }

  /// Get information about a stream
  Future<StreamInfo> getStreamInfo(String streamName) async {
    final subject = '$_apiPrefix.STREAM.INFO.$streamName';

    final response =
        await _client.requestString(subject, '', timeout: _requestTimeout);
    final responseData = jsonDecode(response.string);

    if (responseData['error'] != null) {
      throw JetStreamException(
        responseData['error']['description'],
        code: responseData['error']['code'],
      );
    }

    return StreamInfo.fromJson(responseData);
  }

  /// List all streams
  Future<List<String>> listStreams() async {
    final subject = '$_apiPrefix.STREAM.NAMES';

    final response =
        await _client.requestString(subject, '{}', timeout: _requestTimeout);
    final responseData = jsonDecode(response.string);

    if (responseData['error'] != null) {
      throw JetStreamException(
        responseData['error']['description'],
        code: responseData['error']['code'],
      );
    }

    return List<String>.from(responseData['streams'] ?? []);
  }

  /// Delete a stream
  Future<bool> deleteStream(String streamName) async {
    final subject = '$_apiPrefix.STREAM.DELETE.$streamName';

    final response =
        await _client.requestString(subject, '', timeout: _requestTimeout);
    final responseData = jsonDecode(response.string);

    if (responseData['error'] != null) {
      throw JetStreamException(
        responseData['error']['description'],
        code: responseData['error']['code'],
      );
    }

    return responseData['success'] == true;
  }

  /// Create or update a consumer
  Future<ConsumerInfo> addConsumer(
      String streamName, ConsumerConfig config) async {
    final durableName = config.durableName;

    // Choose correct API endpoint based on consumer type
    final String subject;
    if (durableName != null && durableName.isNotEmpty) {
      // Durable consumer - use DURABLE.CREATE endpoint
      subject = '$_apiPrefix.CONSUMER.DURABLE.CREATE.$streamName.$durableName';
    } else {
      // Ephemeral consumer - use regular CREATE endpoint
      subject = '$_apiPrefix.CONSUMER.CREATE.$streamName';
    }

    // Build payload with correct structure: stream_name + config wrapper
    final payload = jsonEncode({
      'stream_name': streamName,
      'config': config.toJson(),
    });

    final response =
        await _client.requestString(subject, payload, timeout: _requestTimeout);
    final responseData = jsonDecode(response.string);

    if (responseData['error'] != null) {
      throw JetStreamException(
        responseData['error']['description'],
        code: responseData['error']['code'],
      );
    }

    return ConsumerInfo.fromJson(responseData);
  }

  /// Get information about a consumer
  Future<ConsumerInfo> getConsumerInfo(
      String streamName, String consumerName) async {
    final subject = '$_apiPrefix.CONSUMER.INFO.$streamName.$consumerName';

    final response =
        await _client.requestString(subject, '', timeout: _requestTimeout);
    final responseData = jsonDecode(response.string);

    if (responseData['error'] != null) {
      throw JetStreamException(
        responseData['error']['description'],
        code: responseData['error']['code'],
      );
    }

    return ConsumerInfo.fromJson(responseData);
  }

  /// Delete a consumer
  Future<bool> deleteConsumer(String streamName, String consumerName) async {
    final subject = '$_apiPrefix.CONSUMER.DELETE.$streamName.$consumerName';

    final response =
        await _client.requestString(subject, '', timeout: _requestTimeout);
    final responseData = jsonDecode(response.string);

    if (responseData['error'] != null) {
      throw JetStreamException(
        responseData['error']['description'],
        code: responseData['error']['code'],
      );
    }

    return responseData['success'] == true;
  }

  /// Publish a message to JetStream and wait for acknowledgment
  Future<PubAck> publish(
    String subject,
    Uint8List data, {
    String? messageId,
    Duration? expectedLastMsgId,
    int? expectedLastSeq,
    String? expectedStream,
  }) async {
    // Create headers for JetStream publish options
    Header? header;
    if (messageId != null ||
        expectedLastMsgId != null ||
        expectedLastSeq != null ||
        expectedStream != null) {
      header = Header();
      if (messageId != null) header.add('Nats-Msg-Id', messageId);
      if (expectedLastMsgId != null)
        header.add('Nats-Expected-Last-Msg-Id', expectedLastMsgId.toString());
      if (expectedLastSeq != null)
        header.add('Nats-Expected-Last-Sequence', expectedLastSeq.toString());
      if (expectedStream != null)
        header.add('Nats-Expected-Stream', expectedStream);
    }

    // Create the acknowledgment subject and subscribe first
    final ackSubject = newInbox(inboxPrefix: _client.inboxPrefix);
    final ackSubscription = await _client.sub(ackSubject);

    // Small delay to ensure subscription is ready before publishing
    await Future.delayed(Duration(milliseconds: 10));

    // Now publish the message
    await _client.pub(subject, data, replyTo: ackSubject, header: header);

    try {
      final ackMsg =
          await ackSubscription.stream.first.timeout(_requestTimeout);
      final ackData = jsonDecode(ackMsg.string);

      if (ackData['error'] != null) {
        throw JetStreamException(
          ackData['error']['description'],
          code: ackData['error']['code'],
        );
      }

      return PubAck.fromJson(ackData);
    } finally {
      _client.unSub(ackSubscription);
    }
  }

  /// Publish a string message to JetStream
  Future<PubAck> publishString(
    String subject,
    String message, {
    String? messageId,
    Duration? expectedLastMsgId,
    int? expectedLastSeq,
    String? expectedStream,
  }) {
    return publish(
      subject,
      Uint8List.fromList(utf8.encode(message)),
      messageId: messageId,
      expectedLastMsgId: expectedLastMsgId,
      expectedLastSeq: expectedLastSeq,
      expectedStream: expectedStream,
    );
  }

  /// Subscribe to a JetStream consumer (pull-based)
  Future<JetStreamSubscription> pullSubscribe(
    String subject, {
    String? consumerName,
    String? durableName,
    ConsumerConfig? config,
  }) async {
    // If no consumer name provided, create one
    String? actualConsumerName = consumerName ?? durableName;

    if (actualConsumerName == null) {
      // Create ephemeral consumer
      final tempConfig = config ??
          ConsumerConfig(
            filterSubject: subject,
            deliverPolicy: DeliverPolicy.new_,
            ackPolicy: AckPolicy.explicit,
          );

      final streamName = await _findStreamForSubject(subject);
      final consumerInfo = await addConsumer(streamName, tempConfig);
      actualConsumerName = consumerInfo.name;
    }

    return JetStreamSubscription._pull(this, subject, actualConsumerName);
  }

  /// Subscribe to a JetStream consumer (push-based)
  Future<JetStreamSubscription> pushSubscribe(
    String subject, {
    String? consumerName,
    String? durableName,
    String? deliverSubject,
    ConsumerConfig? config,
  }) async {
    final actualDeliverSubject =
        deliverSubject ?? _client.inboxPrefix + '.' + _generateNuid();

    // Create consumer with deliver subject
    final consumerConfig = config ??
        ConsumerConfig(
          name: consumerName,
          durableName: durableName,
          deliverSubject: actualDeliverSubject,
          filterSubject: subject,
          ackPolicy: AckPolicy.explicit,
        );

    final streamName = await _findStreamForSubject(subject);
    final consumerInfo = await addConsumer(streamName, consumerConfig);

    return JetStreamSubscription._push(
        this, actualDeliverSubject, consumerInfo.name);
  }

  /// Find which stream handles a given subject
  Future<String> _findStreamForSubject(String subject) async {
    final streams = await listStreams();

    for (final streamName in streams) {
      final streamInfo = await getStreamInfo(streamName);
      for (final streamSubject in streamInfo.config.subjects) {
        if (_subjectMatches(subject, streamSubject)) {
          return streamName;
        }
      }
    }

    throw JetStreamException('No stream found for subject: $subject');
  }

  /// Check if a subject matches a stream subject pattern
  bool _subjectMatches(String subject, String pattern) {
    if (pattern == subject) return true;
    if (pattern.endsWith('>')) {
      final prefix = pattern.substring(0, pattern.length - 1);
      return subject.startsWith(prefix);
    }
    if (pattern.contains('*')) {
      final parts = pattern.split('.');
      final subjectParts = subject.split('.');
      if (parts.length != subjectParts.length) return false;

      for (int i = 0; i < parts.length; i++) {
        if (parts[i] != '*' && parts[i] != subjectParts[i]) {
          return false;
        }
      }
      return true;
    }
    return false;
  }

  /// Generate a NUID for unique identifiers
  String _generateNuid() {
    // Simple NUID implementation
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    var result = '';
    for (int i = 0; i < 22; i++) {
      result +=
          chars[(DateTime.now().millisecondsSinceEpoch + i) % chars.length];
    }
    return result;
  }
}

/// JetStream subscription wrapper
class JetStreamSubscription {
  final JetStreamContext _js;
  final String _subject;
  final String _consumerName;
  final bool _isPull;
  Subscription? _subscription;
  final StreamController<JetStreamMessage> _controller =
      StreamController<JetStreamMessage>();
  int _outstandingPulls = 0;
  String? _inboxSubject; // unique inbox per pull subscription

  JetStreamSubscription._pull(this._js, this._subject, this._consumerName)
      : _isPull = true;
  JetStreamSubscription._push(this._js, this._subject, this._consumerName)
      : _isPull = false;

  /// Stream of JetStream messages
  Stream<JetStreamMessage> get stream => _controller.stream;

  /// Start the subscription
  Future<void> start() async {
    if (_isPull) {
      // For pull subscriptions, we need to:
      // 1. Set up an inbox subscription to receive pulled messages
      // 2. Start the pull loop to request messages
      // Use a unique inbox per subscription to avoid collisions and follow JetStream expectations
      _inboxSubject = newInbox(inboxPrefix: _js._client.inboxPrefix);
      _subscription = await _js._client.sub(_inboxSubject!);
      _subscription!.stream.listen((msg) {
        // Parse JetStream message format for proper content extraction
        final jsMsg = _parseJetStreamMessage(msg);
        if (jsMsg != null) {
          _controller.add(jsMsg);
          // Decrement outstanding pulls when we receive a message
          if (_outstandingPulls > 0) _outstandingPulls--;
        }
      });

      // Start requesting messages
      _startPullLoop();
    } else {
      // For push subscriptions, subscribe to the deliver subject
      _subscription = await _js._client.sub(_subject);
      _subscription!.stream.listen((msg) {
        final jsMsg = JetStreamMessage.fromMessage(msg, this);
        _controller.add(jsMsg);
      });
    }
  }

  /// Parse JetStream message from NATS wire protocol
  JetStreamMessage? _parseJetStreamMessage(Message msg) {
    // If message is empty, it's likely an acknowledgment, not a real message
    if (msg.byte.isEmpty) {
      return null;
    }

    final content = msg.string;

    // JetStream messages follow NATS protocol: NATS/1.0 + headers + body
    if (content.contains('NATS/1.0')) {
      final parts = content.split('\r\n\r\n');
      if (parts.length >= 2) {
        final body = parts[1];

        // Create a new Message with the body content
        final bodyBytes = Uint8List.fromList(utf8.encode(body));
        final parsedMessage = Message(
          msg.subject,
          msg.sid,
          bodyBytes,
          _js._client,
          replyTo: msg.replyTo,
          header: msg.header,
        );

        return JetStreamMessage.fromMessage(parsedMessage, this);
      }
    }

    // Fallback: treat entire message as JetStream message
    return JetStreamMessage.fromMessage(msg, this);
  }

  /// Start the pull loop for pull subscriptions
  void _startPullLoop() {
    Timer.periodic(const Duration(milliseconds: 500), (timer) async {
      if (_controller.isClosed) {
        timer.cancel();
        return;
      }

      // Only pull if we don't have outstanding pull requests
      if (_outstandingPulls == 0) {
        try {
          await _pullMessages(1);
          _outstandingPulls++;
        } catch (e) {
          // Handle pull errors, but still reset counter
          if (_outstandingPulls > 0) _outstandingPulls--;
        }
      }
    });
  }

  /// Pull messages from the consumer
  Future<void> _pullMessages(int batch) async {
    final subject =
        '\$JS.API.CONSUMER.MSG.NEXT.${await _getStreamName()}.$_consumerName';
    // Ensure we have an inbox (should have been created in start())
    final replyInbox =
        _inboxSubject ?? newInbox(inboxPrefix: _js._client.inboxPrefix);
    // JetStream expects numeric expires in nanoseconds. Use 5s default.
    final expiresNanos = Duration(seconds: 5).inMicroseconds *
        1000; // microseconds -> nanoseconds
    final payload = jsonEncode({'batch': batch, 'expires': expiresNanos});

    try {
      // Make the pull request with inbox as reply-to - this will cause NATS
      // to deliver messages to our inbox subscription
      await _js._client.pub(subject, Uint8List.fromList(utf8.encode(payload)),
          replyTo: replyInbox);

      // Messages will be delivered to our inbox subscription automatically
    } catch (e) {
      // Handle pull errors
    }
  }

  /// Get the stream name for this consumer
  Future<String> _getStreamName() async {
    // Find stream name using the subject pattern
    return await _js._findStreamForSubject(_subject);
  }

  /// Close the subscription
  Future<void> close() async {
    if (_subscription != null) {
      _js._client.unSub(_subscription!);
    }
    await _controller.close();
  }
}

/// JetStream message with additional metadata
class JetStreamMessage {
  final Message _message;
  final JetStreamSubscription _subscription;

  JetStreamMessage.fromMessage(this._message, this._subscription);

  /// Get the underlying NATS message
  Message get message => _message;

  /// Get message data
  Uint8List get data => _message.byte;

  /// Get message as string
  String get string => _message.string;

  /// Get the subject
  String get subject => _message.subject ?? '';

  /// Get message metadata
  JetStreamMessageInfo? get info {
    // Parse JetStream metadata from headers
    if (_message.header != null) {
      // This would parse metadata like sequence, timestamp, etc.
      // from the message headers
    }
    return null;
  }

  /// Acknowledge the message
  Future<void> ack() async {
    if (_message.replyTo != null) {
      await _subscription._js._client.pubString(_message.replyTo!, '+ACK');
    }
  }

  /// Negative acknowledge the message (redelivery)
  Future<void> nak() async {
    if (_message.replyTo != null) {
      await _subscription._js._client.pubString(_message.replyTo!, '-NAK');
    }
  }

  /// Acknowledge and request termination
  Future<void> term() async {
    if (_message.replyTo != null) {
      await _subscription._js._client.pubString(_message.replyTo!, '+TERM');
    }
  }

  /// Working indicator (extend ack deadline)
  Future<void> inProgress() async {
    if (_message.replyTo != null) {
      await _subscription._js._client.pubString(_message.replyTo!, '+WPI');
    }
  }
}

/// JetStream message metadata
class JetStreamMessageInfo {
  final String stream;
  final int sequence;
  final DateTime timestamp;
  final int deliveryCount;
  final String? consumer;

  const JetStreamMessageInfo({
    required this.stream,
    required this.sequence,
    required this.timestamp,
    required this.deliveryCount,
    this.consumer,
  });
}
