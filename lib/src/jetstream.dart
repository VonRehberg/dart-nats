import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'client.dart';
import 'common.dart';
import 'message.dart';

/// JetStream delivery policies
enum DeliverPolicy {
  /// Deliver all messages from the stream
  all('all'),

  /// Deliver only the last message for each subject
  last('last'),

  /// Deliver messages newer than a specific sequence
  byStartSequence('by_start_sequence'),

  /// Deliver messages newer than a specific time
  byStartTime('by_start_time'),

  /// Deliver only new messages (from when consumer is created)
  new_('new');

  const DeliverPolicy(this.value);
  final String value;
}

/// JetStream acknowledgment policies
enum AckPolicy {
  /// No acknowledgment required
  none('none'),

  /// Acknowledge each message individually
  explicit('explicit'),

  /// Acknowledge all messages up to and including this one
  all('all');

  const AckPolicy(this.value);
  final String value;
}

/// JetStream replay policies
enum ReplayPolicy {
  /// Replay messages as fast as possible
  instant('instant'),

  /// Replay messages at original speed
  original('original');

  const ReplayPolicy(this.value);
  final String value;
}

/// JetStream retention policies for streams
enum RetentionPolicy {
  /// Retain messages based on limits (count, size, age)
  limits('limits'),

  /// Retain messages based on interest (consumers)
  interest('interest'),

  /// Retain messages based on work queue pattern
  workQueue('workqueue');

  const RetentionPolicy(this.value);
  final String value;
}

/// JetStream storage types
enum StorageType {
  /// Store messages in memory
  memory('memory'),

  /// Store messages on disk
  file('file');

  const StorageType(this.value);
  final String value;
}

/// JetStream discard policies
enum DiscardPolicy {
  /// Discard oldest messages when limits are hit
  old('old'),

  /// Discard newest messages when limits are hit
  new_('new');

  const DiscardPolicy(this.value);
  final String value;
}

/// JetStream stream configuration
class StreamConfig {
  /// Stream name
  final String name;

  /// List of subjects this stream listens to
  final List<String> subjects;

  /// Retention policy
  final RetentionPolicy retention;

  /// Maximum number of messages
  final int? maxMsgs;

  /// Maximum bytes the stream can contain
  final int? maxBytes;

  /// Maximum age of messages (in nanoseconds)
  final Duration? maxAge;

  /// Maximum message size
  final int? maxMsgSize;

  /// Storage type
  final StorageType storage;

  /// Number of replicas
  final int replicas;

  /// Discard policy when limits are hit
  final DiscardPolicy discard;

  /// Duplicate detection window
  final Duration? duplicateWindow;

  /// Stream description
  final String? description;

  const StreamConfig({
    required this.name,
    required this.subjects,
    this.retention = RetentionPolicy.limits,
    this.maxMsgs,
    this.maxBytes,
    this.maxAge,
    this.maxMsgSize,
    this.storage = StorageType.file,
    this.replicas = 1,
    this.discard = DiscardPolicy.old,
    this.duplicateWindow,
    this.description,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'name': name,
      'subjects': subjects,
      'retention': retention.value,
      'storage': storage.value,
      'num_replicas': replicas,
      'discard': discard.value,
    };

    if (maxMsgs != null) json['max_msgs'] = maxMsgs;
    if (maxBytes != null) json['max_bytes'] = maxBytes;
    if (maxAge != null) json['max_age'] = maxAge!.inMicroseconds * 1000;
    if (maxMsgSize != null) json['max_msg_size'] = maxMsgSize;
    if (duplicateWindow != null)
      json['duplicate_window'] = duplicateWindow!.inMicroseconds * 1000;
    if (description != null) json['description'] = description;

    return json;
  }
}

/// JetStream consumer configuration
class ConsumerConfig {
  /// Consumer name (optional, will be auto-generated if not provided)
  final String? name;

  /// Durable consumer name
  final String? durableName;

  /// Delivery subject for push consumers
  final String? deliverSubject;

  /// Delivery policy
  final DeliverPolicy deliverPolicy;

  /// Acknowledgment policy
  final AckPolicy ackPolicy;

  /// Replay policy
  final ReplayPolicy replayPolicy;

  /// Starting sequence for DeliverPolicy.byStartSequence
  final int? optStartSeq;

  /// Starting time for DeliverPolicy.byStartTime
  final DateTime? optStartTime;

  /// Acknowledgment wait time
  final Duration? ackWait;

  /// Maximum number of delivery attempts
  final int? maxDeliver;

  /// Filter subject (subset of stream subjects)
  final String? filterSubject;

  /// Idle heartbeat interval for push consumers
  final Duration? idleHeartbeat;

  /// Flow control for push consumers
  final bool? flowControl;

  /// Rate limit (messages per second)
  final int? rateLimit;

  /// Maximum number of pending acknowledgments
  final int? maxAckPending;

  /// Consumer description
  final String? description;

  const ConsumerConfig({
    this.name,
    this.durableName,
    this.deliverSubject,
    this.deliverPolicy = DeliverPolicy.all,
    this.ackPolicy = AckPolicy.explicit,
    this.replayPolicy = ReplayPolicy.instant,
    this.optStartSeq,
    this.optStartTime,
    this.ackWait,
    this.maxDeliver,
    this.filterSubject,
    this.idleHeartbeat,
    this.flowControl,
    this.rateLimit,
    this.maxAckPending,
    this.description,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};

    // NATS JetStream consumer configuration fields
    // All consumer config must be wrapped in a 'config' object
    if (name != null) json['name'] = name;
    if (durableName != null) json['durable_name'] = durableName;
    if (deliverSubject != null) json['deliver_subject'] = deliverSubject;
    if (optStartSeq != null) json['opt_start_seq'] = optStartSeq;
    if (optStartTime != null)
      json['opt_start_time'] = optStartTime!.toUtc().toIso8601String();
    if (ackWait != null) json['ack_wait'] = ackWait!.inMicroseconds * 1000;
    if (maxDeliver != null) json['max_deliver'] = maxDeliver;
    if (filterSubject != null) json['filter_subject'] = filterSubject;
    if (idleHeartbeat != null)
      json['idle_heartbeat'] = idleHeartbeat!.inMicroseconds * 1000;
    if (flowControl != null) json['flow_control'] = flowControl;
    if (rateLimit != null) json['rate_limit_bps'] = rateLimit;
    if (maxAckPending != null) json['max_ack_pending'] = maxAckPending;
    if (description != null) json['description'] = description;

    // Add enum values correctly
    if (ackPolicy != null) {
      json['ack_policy'] = ackPolicy.value;
    }
    if (deliverPolicy != null) {
      json['deliver_policy'] = deliverPolicy.value;
    }

    return json;
  }

  factory ConsumerConfig.fromJson(Map<String, dynamic> json) {
    return ConsumerConfig(
      name: json['name'],
      durableName: json['durable_name'],
      deliverSubject: json['deliver_subject'],
      optStartSeq: json['opt_start_seq'],
      optStartTime: json['opt_start_time'] != null
          ? DateTime.parse(json['opt_start_time'])
          : null,
      ackWait: json['ack_wait'] != null
          ? Duration(microseconds: json['ack_wait'] ~/ 1000)
          : null,
      maxDeliver: json['max_deliver'],
      filterSubject: json['filter_subject'],
      idleHeartbeat: json['idle_heartbeat'] != null
          ? Duration(microseconds: json['idle_heartbeat'] ~/ 1000)
          : null,
      flowControl: json['flow_control'],
      rateLimit: json['rate_limit_bps'],
      maxAckPending: json['max_ack_pending'],
      description: json['description'],
      ackPolicy: json['ack_policy'] != null
          ? AckPolicy.values.firstWhere(
              (e) => e.value == json['ack_policy'],
              orElse: () => AckPolicy.explicit,
            )
          : AckPolicy.explicit,
      deliverPolicy: json['deliver_policy'] != null
          ? DeliverPolicy.values.firstWhere(
              (e) => e.value == json['deliver_policy'],
              orElse: () => DeliverPolicy.all,
            )
          : DeliverPolicy.all,
    );
  }
}

/// JetStream stream information
class StreamInfo {
  final StreamConfig config;
  final DateTime created;
  final StreamState state;
  final ClusterInfo? cluster;

  const StreamInfo({
    required this.config,
    required this.created,
    required this.state,
    this.cluster,
  });

  factory StreamInfo.fromJson(Map<String, dynamic> json) {
    return StreamInfo(
      config: StreamConfig(
        name: json['config']['name'],
        subjects: List<String>.from(json['config']['subjects']),
        retention: RetentionPolicy.values.firstWhere(
          (e) => e.value == json['config']['retention'],
          orElse: () => RetentionPolicy.limits,
        ),
        storage: StorageType.values.firstWhere(
          (e) => e.value == json['config']['storage'],
          orElse: () => StorageType.file,
        ),
        replicas: json['config']['num_replicas'] ?? 1,
        discard: DiscardPolicy.values.firstWhere(
          (e) => e.value == json['config']['discard'],
          orElse: () => DiscardPolicy.old,
        ),
        maxMsgs: json['config']['max_msgs'],
        maxBytes: json['config']['max_bytes'],
        maxAge: json['config']['max_age'] != null
            ? Duration(microseconds: json['config']['max_age'] ~/ 1000)
            : null,
        maxMsgSize: json['config']['max_msg_size'],
        duplicateWindow: json['config']['duplicate_window'] != null
            ? Duration(microseconds: json['config']['duplicate_window'] ~/ 1000)
            : null,
        description: json['config']['description'],
      ),
      created: DateTime.parse(json['created']),
      state: StreamState.fromJson(json['state']),
      cluster: json['cluster'] != null
          ? ClusterInfo.fromJson(json['cluster'])
          : null,
    );
  }
}

/// JetStream stream state information
class StreamState {
  final int messages;
  final int bytes;
  final int firstSeq;
  final DateTime? firstTs;
  final int lastSeq;
  final DateTime? lastTs;
  final int consumers;

  const StreamState({
    required this.messages,
    required this.bytes,
    required this.firstSeq,
    this.firstTs,
    required this.lastSeq,
    this.lastTs,
    required this.consumers,
  });

  factory StreamState.fromJson(Map<String, dynamic> json) {
    return StreamState(
      messages: json['messages'] ?? 0,
      bytes: json['bytes'] ?? 0,
      firstSeq: json['first_seq'] ?? 0,
      firstTs:
          json['first_ts'] != null ? DateTime.parse(json['first_ts']) : null,
      lastSeq: json['last_seq'] ?? 0,
      lastTs: json['last_ts'] != null ? DateTime.parse(json['last_ts']) : null,
      consumers: json['consumer_count'] ?? 0,
    );
  }
}

/// JetStream cluster information
class ClusterInfo {
  final String? name;
  final String? leader;
  final List<String>? replicas;

  const ClusterInfo({
    this.name,
    this.leader,
    this.replicas,
  });

  factory ClusterInfo.fromJson(Map<String, dynamic> json) {
    return ClusterInfo(
      name: json['name'],
      leader: json['leader'],
      replicas:
          json['replicas'] != null ? List<String>.from(json['replicas']) : null,
    );
  }
}

/// JetStream consumer information
class ConsumerInfo {
  final String name;
  final String streamName;
  final ConsumerConfig config;
  final DateTime created;
  final ConsumerState delivered;
  final ConsumerState ackFloor;
  final int numPending;
  final int numWaiting;
  final int numRedelivered;
  final ClusterInfo? cluster;

  const ConsumerInfo({
    required this.name,
    required this.streamName,
    required this.config,
    required this.created,
    required this.delivered,
    required this.ackFloor,
    required this.numPending,
    required this.numWaiting,
    required this.numRedelivered,
    this.cluster,
  });

  factory ConsumerInfo.fromJson(Map<String, dynamic> json) {
    return ConsumerInfo(
      name: json['name'],
      streamName: json['stream_name'],
      config: ConsumerConfig.fromJson(json['config'] ?? {}),
      created: DateTime.parse(json['created']),
      delivered: ConsumerState.fromJson(json['delivered']),
      ackFloor: ConsumerState.fromJson(json['ack_floor']),
      numPending: json['num_pending'] ?? 0,
      numWaiting: json['num_waiting'] ?? 0,
      numRedelivered: json['num_redelivered'] ?? 0,
      cluster: json['cluster'] != null
          ? ClusterInfo.fromJson(json['cluster'])
          : null,
    );
  }
}

/// JetStream consumer state
class ConsumerState {
  final int consumerSeq;
  final int streamSeq;
  final DateTime? lastActive;

  const ConsumerState({
    required this.consumerSeq,
    required this.streamSeq,
    this.lastActive,
  });

  factory ConsumerState.fromJson(Map<String, dynamic> json) {
    return ConsumerState(
      consumerSeq: json['consumer_seq'] ?? 0,
      streamSeq: json['stream_seq'] ?? 0,
      lastActive: json['last_active'] != null
          ? DateTime.parse(json['last_active'])
          : null,
    );
  }
}

/// JetStream publish acknowledgment
class PubAck {
  final String stream;
  final int seq;
  final String? domain;
  final bool duplicate;

  const PubAck({
    required this.stream,
    required this.seq,
    this.domain,
    required this.duplicate,
  });

  factory PubAck.fromJson(Map<String, dynamic> json) {
    return PubAck(
      stream: json['stream'],
      seq: json['seq'],
      domain: json['domain'],
      duplicate: json['duplicate'] ?? false,
    );
  }
}

/// JetStream errors
class JetStreamException extends NatsException {
  final int? code;
  final String? description;

  JetStreamException(String? message, {this.code, this.description})
      : super(message);

  @override
  String toString() {
    var result = 'JetStreamException';
    if (message != null) result = '$result: $message';
    if (code != null) result = '$result (code: $code)';
    if (description != null) result = '$result - $description';
    return result;
  }
}
