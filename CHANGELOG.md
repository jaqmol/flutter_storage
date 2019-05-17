## [0.9.4] - 2019/03/10

* Due to apparent changes in object serialization between isolates in the Dart VM and/or the native runtime, backend was renamed to directly expose it's API without being encapsulated by an isolate.
* Thus this version is not concurrent anymore.

## [0.9.3] - 2019/03/10

* Asserting list type for `Storage.addEntries(…)`.

## [0.9.2] - 2019/02/07

* Making `Serializer.collection(…)` accept `Iterables`.

## [0.9.1] - 2019/01/15

* Making `closeAndOpen(…)` returning `this` on conclude.

## [0.9.0] - 2019/01/14

* Making `flushState(…)` conditional, so that in case no change occurred, nothing will be written to disk.

## [0.8.9] - 2019/01/14

* Adding `closeAndOpen(…)` method, allowing for:
  * Reuse of storage and isolate.
  * Minimizing respawn-time if requirement is: 1 open storage at a time.

## [0.8.8] - 2019/01/11

* Discovering compaction error, extending test amd fixing error.

## [0.8.7] - 2019/01/08

* Renaming `Storage.create(…)` to `Storage.open(…)`
* Renaming `Storage.flushStateAndClose()` to `Storage.close()`
* Changing isolate kill priority to `beforeNextEvent(…)`

## [0.8.6] - 2018/12/13

* Adding `Serializer.model(…)` for chaining calls on a serializer.

## [0.8.4] - 2018/12/09

* Changing example lokation

## [0.8.3] - 2018/12/09

* Example added showcasing adding, retrieving and iterating values.
* Exporting storag entities

## [0.8.2] - 2018/12/08

* First release with comprehensible documentation.
