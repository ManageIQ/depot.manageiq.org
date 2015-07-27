jQuery(function() {
  var updateNameAndDescription = function() {
    var urlField = $("#extension-url-short-field");
    var repos = urlField.data("repos");
    var current = urlField.val();

    var repo = null;

    for (var i = 0; i < repos.length; i++) {
      if (repos[i].full_name == current) {
        repo = repos[i];
        break;
      }
    }

    if (repo) {
      $("#extension-url-field").val(repo.full_name);
      $("#extension-name-field").val(repo.name);
      $("#extension-desc-field").val(repo.description);
    }
  }

  $("#extension-url-short-field").change(function(ev) {
    updateNameAndDescription();
  });

  updateNameAndDescription();
});
