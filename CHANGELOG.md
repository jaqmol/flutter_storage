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
