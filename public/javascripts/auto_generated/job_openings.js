/* job_openings */
$(function() {
  if ($(".ji").length == 1) {
    var dirty_url = false;
  
//    $("#_keywords,#_employer").observe_field(0.2, function( ) {
//      $(".matches").addClass("dimmed");
//      $.get($("#query_form").attr("action") + ".js", $("#query_form").serialize(), null, "script");
//      dirty_url = true;
//    });
  
    $(".matches .items a").live("click", function() {
      if (dirty_url) {
        history.replaceState(null, "", "/j?" + $("#query_form").serialize());
      }
    });

    $(".matches .more_button input").live("click", function() {
      var data = $("#query_form").serialize() + "&from_id=" + from_id;
      $.get("/j/more.js", data, null, "script");
    });

    $(".job_categories_picker_link a").overlay({mask: '#fff', effect: 'apple'});
    $(".locations_picker_link a").overlay({
      mask: '#fff', 
      effect: 'apple',
      fixed: false,
      load: true
    });

    $(".locations_tree").dynatree({
      checkbox: true, 
      selectMode: 2,
      children: locations_tree_data,
      onLazyRead: function(node) {
        node.appendAjax({
          url: "/j/location_picker_node_children",
          data: {"key": node.data.key }
        });
      },
      onSelect: function(flag, node) {
        if( ! flag ) alert("You deselected node with title " + node.data.title);
        console.log(node);
        var selectedNodes = node.tree.getSelectedNodes();
        var selectedKeys = $.map(selectedNodes, function(node){
          return node.data.key;
        });
        
        alert("Selected keys: " + selectedKeys.join(", "));
      }
    });
  }

});
