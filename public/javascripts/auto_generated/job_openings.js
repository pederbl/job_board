/* job_openings */
$(function() {
  if ($(".ji").length == 1) {
    var dirty_url = false;
  
    function live_search() {
      live_search_idx += 1;
      $(".matches").addClass("dimmed");
      $.get($("#query_form").attr("action") + ".js", $("#query_form").serialize() + "&live_search_idx=" + live_search_idx, null, "script");
      dirty_url = true;
    }
  
    $("#q_keywords,#q_employer").observe_field(0.2, live_search);
    
    $(".matches .items a").live("click", function() {
      if (dirty_url) {
        history.replaceState(null, "", "/j?" + $("#query_form").serialize());
      }
    });

    $(".matches .more_button input").live("click", function() {
      var data = $("#query_form").serialize() + "&q[max_id]=" + (next_max_id);
      $.get("/j/more.js", data, null, "script");
    });

    $(".job_categories_picker_link a").overlay({
      mask: '#fff', 
      effect: 'apple',
      fixed: false,
      load: false
    });
    $(".job_categories_tree").dynatree({
      checkbox: true, 
      selectMode: 2,
      children: job_categories_tree_data,
      onLazyRead: function(node) {
        node.appendAjax({
          url: "/j/job_categories_picker_node_children",
          data: $("#query_form").serialize() + "&key=" + node.data.key
        });
      },
      onSelect: function(flag, node) {
        var selectedNodes = node.tree.getSelectedNodes();
        var selectedKeys = $.map(selectedNodes, function(node) { return node.data.key; }).join(";");
        var selectedTitles = $.map(selectedNodes, function(node) { return node.data.title; });
        if (selectedTitles.length > 0) {
          selectedTitles = selectedTitles.join("; ");
        } else {
          selectedTitles = I18n["all"];
        }
        $("#q_job_categories").attr("value", selectedKeys);
        $('.job_categories .selected_list').html(selectedTitles);
        live_search();
      }
    });

    $(".locations_picker_link a").overlay({
      mask: '#fff', 
      effect: 'apple',
      fixed: false,
      load: false
    });

    $(".locations_tree").dynatree({
      checkbox: true, 
      selectMode: 2,
      children: locations_tree_data,
      onLazyRead: function(node) {
        node.appendAjax({
          url: "/j/locations_picker_node_children",
          data: $("#query_form").serialize() + "&key=" + node.data.key
        });
      },
      onSelect: function(flag, node) {
        var selectedNodes = node.tree.getSelectedNodes();
        var selectedKeys = $.map(selectedNodes, function(node) { return node.data.key; }).join(";");
        var selectedTitles = $.map(selectedNodes, function(node) { return node.data.title; });
        if (selectedTitles.length > 0) {
          selectedTitles = selectedTitles.join("; ");
        } else {
          selectedTitles = I18n["all"];
        }
        $("#q_locations").attr("value", selectedKeys);
        $('.locations .selected_list').html(selectedTitles);
        live_search();
      }
    });
  }

});
