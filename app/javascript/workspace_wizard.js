//= require jquery
// This script handles the AJAX loading and submission of each wizard step in the modal
$(document).on('turbolinks:load', function() {
  function loadWizardStep(step, workspaceId) {
    var url;
    switch(step) {
      case 1:
        url = '/admin/workspaces/new'; break;
      case 2:
        url = '/admin/workspaces/' + workspaceId + '/step2'; break;
      case 3:
        url = '/admin/workspaces/' + workspaceId + '/step3'; break;
      case 4:
        url = '/admin/workspaces/' + workspaceId + '/step4'; break;
      default:
        url = '/admin/workspaces/new';
    }
    $.get(url, function(data) {
      $('#wizard-step-content').html($(data).find('#wizard-step-content').html() || data);
    });
  }

  // Open modal and load first step
  $('#open-wizard-modal-btn').on('click', function(e) {
    e.preventDefault();
    $('#workspace-wizard-modal').modal('show');
    loadWizardStep(1);
  });

  // Handle AJAX form submission for each step
  $(document).on('ajax:success', '#wizard-step1-form, #wizard-step2-form, #wizard-step3-form, #wizard-step4-form', function(event) {
    var [data, status, xhr] = event.detail;
    if (data.next_step) {
      loadWizardStep(data.next_step, data.workspace_id);
    } else if (data.redirect_url) {
      window.location.href = data.redirect_url;
    }
  });

  $(document).on('ajax:error', '#wizard-step1-form, #wizard-step2-form, #wizard-step3-form, #wizard-step4-form', function(event) {
    var [data, status, xhr] = event.detail;
    $('#wizard-step-content').html(data.responseText);
  });
}); 