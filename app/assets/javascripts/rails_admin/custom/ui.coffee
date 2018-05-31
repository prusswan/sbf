$(document).off('click').on 'click', '.pjax', (event) ->
  if event.which > 1 || event.metaKey || event.ctrlKey
    return
  else if $.support.pjax
    event.preventDefault()
    $.pjax
      container: $(this).data('pjax-container') || '[data-pjax-container]'
      url: $(this).data('href') || $(this).attr('href')
      timeout: 10000
  else if $(this).data('href') # not a native #href, need some help
    window.location = $(this).data('href')

$(document).off('submit').on 'submit', '.pjax-form', (event) ->
  if $.support.pjax
    event.preventDefault()
    $.pjax
      container: $(this).data('pjax-container') || '[data-pjax-container]'
      url: this.action + (if (this.action.indexOf('?') != -1) then '&' else '?') + $(this).serialize()
      timeout: 10000
