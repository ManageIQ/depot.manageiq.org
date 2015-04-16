$(document).on('opened', '[data-reveal]', function () {
  var settings =  {
    placeholder: 'Search for a collaborator',
    minimumInputLength: 3,
    width: '100%',
    ajax: {
      url: function () {
        return $(this).data('url');
      },
      dataType: 'json',
      quietMillis: 200,
      data: function (term, page) {
        return { q: term };
      },
      results: function (data, page) {
        return {results: data.collaborators};
      }
    },
    formatSelection: function(collaborator, container) {
      return collaborator.username;
    },
    formatResult: function(collaborator, container) {
      if(collaborator.first_name && collaborator.last_name) {
        return collaborator.first_name + ' ' + collaborator.last_name + ' (' + collaborator.username + ')';
      } else {
        return collaborator.username;
      }
    }
  }

  $('.collaborators').select2(settings);
  $('.collaborators.multiple').select2($.extend(settings, {multiple: true}));
});

$(function() {
  $('a[rel~="remove_collaboration"]').on('ajax:success', function(e, data, status, xhr) {
    $(this).closest('tr').remove();
  });
});
