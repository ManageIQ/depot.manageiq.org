$(function() {
  /*
   * Adds a disabled class when the user clicks a follow or unfollow button
   * so they know a request is in progress and they don't click follow or unfollow
   * twice.
   */
  $('a[rel~="follow"], a[rel~="unfollow"]').on('click', function() {
    $(this).addClass('disabled');
  });

  /*
   * Binds an ajax:success event to the extension partial follow button and replaces
   * the partial in question with server side rendered HTML.
   */
  $('body').delegate('.listing .follow', 'ajax:success', function(e, data, status, xhr) {
    var followCountId = '#' + $(this).data('extension') + '-follow-count';
    var followButtonId = '#' + $(this).data('extension') + '-follow-button';

    $(followCountId).replaceWith($(data).filter(followCountId));
    $(followButtonId).replaceWith($(data).filter(followButtonId));
  });

  /*
   * Binds an ajax:success event to the extension show follow button and replaces
   * the followbutton which includes the follow count with server side rendred HTML.
   */
  $('body').delegate('.extension_show .follow', 'ajax:success', function(e, data, status, xhr) {
    $('.followbutton').replaceWith(data);
  });
});
