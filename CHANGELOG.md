## 1.0.0 - Major Release

### 💥 Breaking Changes
* **Blocking Connection Behavior**: `connect()` method will block until connection is established or fails with permission errors
* **Permission Error Detection**: `connect()`, `sub()`, and `pub()` methods now throw exceptions immediately when permission errors are detected from server
* **Introduced new ConnectOption Parameters**: 
  - `subscriptionErrorTimeout`
  - `connectionErrorTimeout`

### 🚀 New Features  
* **Enhanced Error Handling**: Real-time detection of permission violations during connection, subscription, and publishing
* **Configurable Error Timeouts**: New timeout parameters allow fine-tuning how long to wait for server error responses in non-verbose mode
* **Automatic Reconnection**: Robust automatic reconnection when server closes established connections
* **Improved Connection Reliability**: Better connection state management and retry logic
* **🚀 JetStream Support**: Complete implementation of NATS JetStream for message persistence
  - Stream management (create, delete, configure streams)
  - Consumer management (durable and ephemeral consumers)  
  - Publishing with acknowledgments and delivery guarantees
  - Pull and push subscription patterns
  - Message acknowledgment handling (ack, nak, term, in-progress)
  - Exactly-once delivery with deduplication
  - Message replay from specific sequence or time
  - Work queue patterns with competing consumers
  - Comprehensive stream and consumer information APIs

### 🔮 JETSTREAM FEATURES
- ✅ Stream and Consumer Management
- ✅ Message Persistence with Acknowledgments
- ✅ Pull and Push Subscription Patterns  
- ✅ Exactly-Once Delivery Guarantees
- ✅ Message Replay and Time-Travel
- ✅ Work Queue Patterns
- 🔄 Key-Value Store (Planned)
- 🔄 Object Store (Planned)

### ⚠️ Migration Required
This is a major version with breaking changes to connection and subscription behavior. See migration guide in README.md.

## 0.6.5
* Issue resolved when app is in background. Thanks nileshsoni97 for contribution.

## 0.6.4

* Fix Uint8List and List<int> inconsistency. Thank myxzlpltk for contribution.

## 0.6.3

* fix Exposing Security Context#31.
* Fix missing headers in request response.


## 0.6.2

* fix a bug that does not correctly parse headers containing the ':' character. Thank https://github.com/CoryHagerman for contribution.

## 0.6.1

* fix nkeys decode issue

## 0.6.0

* Support verbos acknowledge
* Chang pub, pubString to async
* Header support (hpub and hmsg)

## 0.5.1

* Add retry

## 0.5.0

* Add nkeys publicKey privateKey functions
* Revamp rqeust
* Custom inbox prefix
* Inbound structure data

## 0.4.9

* fix #22 error when connect to nats://demo.nats.io

## 0.4.8

* fix #23 Unsupported operation: Platform._version with WebSocket

## 0.4.7

* add generic type to client.request()
* fix reconnect issue
* fix retry issue

## 0.4.6

* fix bug #16 Connect to invalid ws connection does not give error

## 0.4.5

* fix bug wss: connecting bug

## 0.4.4

* fix bug #20 larger MSG payloads not always working, check if full payload present in buffer

## 0.4.2

* TLS support

## 0.4.1

* fix wss://host:port

## 0.4.0

* client.connect() support with url schema example ws://host:port or nats://nost:port
* tls:// not support yet
* discontinue client.tcpConnect()
* add nkey authentication
* add jwt authentication

## 0.3.5

* Update readme

## 0.3.4

* Support TCP socket as 0.2.x by client.tcpConnect()

## 0.3.3

* Update package dependencies

## 0.3.2

* Fix flutter web Nuid() error

## 0.3.1

* Add statusStream
* Add request timeout

## 0.3.0

* Change transport from socket to WebSock
* Support Flutter Web

## 0.2.0

* Add user passwor authentication
* Add token authentication
* Convert to Null safety
* Dart SDK version 2.12.0 - 3.0.0
* fix inbox security

## 0.1.8

* fix request error on second request

## 0.1.7

* add async support for ping()
* add message.respondString

## 0.1.6+1

* Improve receive buffer handling

## 0.1.6

* async connect
* fix defect message delay when sub receive continuous message

## 0.1.5+1

* fix defect

## 0.1.5

* request/respond function
* change some wording from payload to data

## 0.1.4+1

* add inbox to generate unique inbox subject
* add nuid to generate unique id

## 0.1.3+4

* refactor code
* add commend

## 0.1.3+1

* add string api client.pubString and message.string
* fix defect: pub sub non ascii
* fix defect: message include \r or \n
* revamp message decoding

## 0.1.2

* change api from string to byte array

## 0.1.1

* publish can be buffered.

## 0.1.0+4

* Update sample code

## 0.1.0+3

* Update sample code

## 0.1.0+2

* Update readme

## 0.1.0+1

* Add readme

## 0.0.2+1

* Add change log

## 0.0.2

* Refactor code

## 0.0.1

* Initial experimental version
