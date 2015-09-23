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

  _retrytimeout = null
  _inprogress = no
  _currentbackoff = backoff
  _ondrain = []

  _retry = ->
    _currentbackoff *= 2
    all = retrying.all()
    inflight.enqueue item for item in all
    retrying = Queue()
    _retrytimeout = null
    _drain() if !_inprogress

  _drain = ->
    _inprogress = yes
    if inflight.length() is 0
      if retrying.length() is 0
        _currentbackoff = backoff
        ondrain = _ondrain
        _ondrain = []
        cb() for cb in ondrain
      else if _retrytimeout is null
        console.log "Retrying #{retrying.length()} messages in #{_currentbackoff}ms"
        _retrytimeout = setTimeout _retry, _currentbackoff
      if inflight.length() is 0
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
    retrying.compact
  drain: (cb) ->
    return cb() if !_inprogress and _retrytimeout is null
    _ondrain.push cb
  destroy: ->
    if _retrytimeout
      clearTimeout _retrytimeout
      _retrytimeout = null
