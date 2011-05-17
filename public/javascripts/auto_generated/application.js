/* application */
$(function() {
  $(".locale_picker_link a").overlay({mask: '#fff', effect: 'apple'});
  $("[data-set-locale]").click(function() { 
    $.cookie("locale", $(this).attr("data-set-locale"), { path: '/' } );
    location.reload();
  });
});
