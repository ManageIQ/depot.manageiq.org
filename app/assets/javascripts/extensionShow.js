//= require vendor/jquery-sparkline

$(function() {
  $(".show-extension-urls-manage, .cancel-submit-urls").click(function(event) {
    event.preventDefault();
    $(".manage-extension-urls").slideToggle();
    $(".show-extension-urls-manage").toggleClass('active');
    $(".extension-urls").fadeToggle();
  });

  $('a[rel~="remove-extension-collaborator"]').on('ajax:success', function(e, data, status, xhr) {
    $(this).parents('.gravatar-container').remove();
  });

  $("a.toggle-details-edit").click(function(event) {
    $(".toggle-details-edit").toggle();
    event.preventDefault();
  });

  $("a.toggle-platforms-edit").click(function(event) {
    $(".toggle-platforms-edit").toggle();
    event.preventDefault();
  });

  $("a.toggle-tags-edit").click(function(event) {
    $(".toggle-tags-edit").toggle();
    event.preventDefault();
  });

  $(".sparkline").sparkline("html", {
    width: "100%",
    height: "25px",
    spotColor: "",
    spotRadius: 0,
    disableInteraction: true
  }).addClass("loaded");
});
