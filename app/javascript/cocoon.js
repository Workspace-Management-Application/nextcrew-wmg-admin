// This is a simplified version compatible with importmap
$(document).on('click', '.add_fields', function(e) {
  e.preventDefault();

  const time = new Date().getTime();
  const template = $(this).attr('data-association-insertion-template');
  const regexp = new RegExp('new_' + $(this).attr('data-association'), 'g');
  const content = template.replace(regexp, time);

  const insertionNode = $(this).data('association-insertion-node');
  const insertionMethod = $(this).data('association-insertion-method') || 'before';

  if (insertionMethod === 'append') {
    $(insertionNode).append(content);
  } else if (insertionMethod === 'prepend') {
    $(insertionNode).prepend(content);
  } else {
    $(this).closest(insertionNode)[insertionMethod](content);
  }
});

$(document).on('click', '.remove_fields.dynamic', function(e) {
  $(this).closest(".nested-fields").remove();
  e.preventDefault();
});

$(document).on('click', '.remove_fields.existing', function(e) {
  $(this).prev("input[type=hidden]").val("1");
  $(this).closest(".nested-fields").hide();
  e.preventDefault();
});
