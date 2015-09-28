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
  factor = options.factor
  factor ?= 1.5
  limit = options.limit
  limit ?= 1000 * 60
  notify = options.notify
  notify ?= 1000 * 30

  _retrytimeout = null
  _inprogress = no
  _currentbackoff = backoff
  _ondrain = []

  _retry = ->
    _currentbackoff *= factor
    _currentbackoff = Math.max _currentbackoff, limit
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
        if _currentbackoff >= notify
          console.error "Retrying #{retrying.length()} messages in #{_currentbackoff / 1000}s"
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

  _drain() if !_inprogress

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
