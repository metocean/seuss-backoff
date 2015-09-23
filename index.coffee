Queue = require 'seuss-queue'
async = require 'odo-async'

module.exports = (options) ->
  onitem = options.onitem
  inflight = options.inflight
  inflight ?= Queue()
  retrying = options.retrying
  retrying ?= Queue()
  backoff = options.delay
  backoff ?= 500

  retrytimeout = null
  _inprogress = no
  _currentbackoff = backoff

  _retry = ->
    _currentbackoff *= 2
    all = retrying.all()
    inflight.enqueue item for item in all
    retrying = Queue()
    _drain() if !_inprogress

  _drain = ->
    _inprogress = yes
    if inflight.length() is 0
      if retrying.length() is 0
        _currentbackoff = backoff
      if retrytimeout is null
        console.log "Retrying #{retrying.length()} messages in #{_currentbackoff}ms"
        retrytimeout = setTimeout _retry, _currentbackoff
      _inprogress = no
      return

    item = inflight.peek()
    onitem item, (success) ->
      if !success
        retrying.enqueue item
      inflight.dequeue()
      async.delay _drain

  enqueue: (item, cb) ->
    inflight.enqueue item
    _drain() if !_inprogress
  inflight: -> inflight.all()
  retrying: -> retrying.all()
  all: ->
    []
      .concat(retrying.all())
      .concat(inflight.all())
  length: ->
    inflight.length() + retrying.length()
  compact: ->
    inflight.compact()
    retrying.compact()