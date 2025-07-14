// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"
import "bootstrap"
import "cocoon"
import "select2"

// Initialize Select2 after every Turbo page load
document.addEventListener("turbo:load", function() {
  if (window.$ && typeof $().select2 === 'function') {
    $('.select2-select').each(function() {
      const placeholder = $(this).data('placeholder') || 'Select an option';
      $(this).select2({
        theme: 'default',
        width: '100%',
        placeholder: placeholder,
        allowClear: true
      });
    });
  }
});

document.addEventListener("DOMContentLoaded", function() {
  if (window.$ && typeof $().select2 === 'function') {
    $('.select2-select').each(function() {
      const placeholder = $(this).data('placeholder') || 'Select an option';
      $(this).select2({
        theme: 'default',
        width: '100%',
        placeholder: placeholder,
        allowClear: true
      });
    });
  }
});

$(document).on('cocoon:after-insert', function(e, insertedItem) {
  if (window.$ && typeof $().select2 === 'function') {
    insertedItem.find('.select2-select').each(function() {
      const placeholder = $(this).data('placeholder') || 'Select an option';
      $(this).select2({
        theme: 'default',
        width: '100%',
        placeholder: placeholder,
        allowClear: true
      });
    });
  }
});