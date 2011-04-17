/* job_openings */
$(function() {
  if ($(".ji").length == 1) {
    var dirty_url = false;
  
    $("#_keywords,#_employer,#_location").observe_field(0.2, function( ) {
      $(".matches").addClass("dimmed");
      $.get($("#query_form").attr("action") + ".js", $("#query_form").serialize(), null, "script");
      dirty_url = true;
    });
  
    $(".matches .items a").live("click", function() {
      if (dirty_url) {
        history.replaceState(null, "", "/jobb?" + $("#query_form").serialize());
      }
    });

    $(".matches .more_button input").live("click", function() {
      var data = $("#query_form").serialize() + "&from_id=" + from_id;
      $.get("/jobb/more.js", data, null, "script");
    });
  }

});
