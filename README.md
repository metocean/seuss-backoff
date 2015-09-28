# Seuss Backoff
Exponential backoff queue.

# Usage
```js
var Backoff = require('seuss-backoff');

// using sensible defaults
var queue = Backoff({
    onitem: function(item, cb) {
        // try and process item
        // cb(true) to succeed or cb(false) to fail and retry
        cb(false);
    }
});
```

# Options
Defaults shown. Seuss can either be the in-memory queue ([seuss-queue](https://github.com/metocean/seuss-queue)) or the file backed queue ([seuss](https://github.com/metocean/seuss)).
```js
var Seuss = require('seuss-queue');
var Backoff = require('seuss-backoff');
var queue = Backoff({
    inflight: Seuss(), // items to process
    retrying: Seuss(), // items awaiting retry
    backoff: 500, // initial retry timeout in ms
    factor: 1.5, // factor to increase each successive timeout
    limit: 1000 * 60, // maximum timeout in ms
    notify: 1000 * 30, // timeout in ms to start printing to stderr
    onitem: function(item, cb) {
        // try and process item
        // cb(true) to succeed or cb(false) to fail and retry
        cb(false);
    }
});
```