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

  var attemptExtensionsLoad = function() {
    $.get("/users/accessible_repos", function(resp) {
      if (resp.repo_names) {
        $("#loading-extensions").remove();

        var select = $("<select></select>");
        select.attr("data-repos", JSON.stringify(resp.repo_names));
        select.attr("id", "extension-url-short-field");
        select.attr("name", "extension[github_url_short]");
        select.attr("required", "required");
        select.append($("<option value=''>Select a Repository</option>"));

        for (var i = 0; i < resp.repo_names.length; i++) {
          var item = resp.repo_names[i];
          select.append($("<option value='" + item.full_name + "'>" + item.full_name + "</option>"));
        }

        $("#extensions-selector").prepend(select);

        select.blur(function() {
          Foundation.libs.abide.parse_patterns($(this));
        });

        $("#extension-url-short-field").change(function(ev) {
          updateNameAndDescription();
        });
      } else {
        setTimeout(attemptExtensionsLoad, 1000);
      }

    })
  }

  if ($("#extension-url-short-field").size() > 0) {
    $("#extension-url-short-field").change(function(ev) {
      updateNameAndDescription();
    });

    updateNameAndDescription();
  } else if ($("#loading-extensions").size() > 0) {
    setTimeout(attemptExtensionsLoad, 1000);
  }
});
