#= require jquery
#= require jquery.ui.widget
#= require jquery.iframe-transport
#= require jquery.fileupload
#= require moment

#= require handlebars
#= require ember
#= require_self

#= require ./store
#= require_tree ./mixins
#= require_tree ./controllers
#= require_tree ./helpers
#= require_tree ./models
#= require_tree ./routes
#= require_tree ./templates
#= require_tree ./views
#= require ./router

window.console = { log: -> } unless window.console?

$.ajaxSetup
  beforeSend: (jqXHR) ->
    jqXHR.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content'))

if (navigator.userAgent.match(/IEMobile\/10\.0/))
  msViewportStyle = document.createElement('style')
  msViewportStyle.appendChild(
    document.createTextNode(
      '@-ms-viewport{width:auto!important}'
    )
  )
  document.querySelector('head').appendChild(msViewportStyle)

# These two functions are useful if we end up doing hashtag and username autocompletion
(($, undefined_) ->
  $.fn.getCursorPosition = ->
    el = $(this).get(0)
    pos = 0
    if "selectionStart" of el
      pos = el.selectionStart
    else if "selection" of document
      el.focus()
      Sel = document.selection.createRange()
      SelLength = document.selection.createRange().text.length
      Sel.moveStart "character", -el.value.length
      pos = Sel.text.length - SelLength
    pos) jQuery

# These two functions are useful if we end up doing hashtag and username autocompletion
(($, undefined_) ->
  $.fn.setCursorPosition = (pos) ->
    if @get(0).setSelectionRange
      @get(0).setSelectionRange pos, pos
    else if @get(0).createTextRange
      range = @get(0).createTextRange()
      range.collapse true
      range.moveEnd "character", pos
      range.moveStart "character", pos
      range.select()) jQuery

Ember.FEATURES['ember-routing-drop-deprecated-action-style'] = true
window.Twitarr = Ember.Application.create
#  LOG_TRANSITIONS: true
#  LOG_BINDINGS: true
  api_path: "/api/v2"
  ready: ->
    $("#app-loading").remove()
