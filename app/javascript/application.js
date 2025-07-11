// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"
import "bootstrap"
import "bootstrap-select"
import "jquery"
import "cocoon"


// Initialize selectpicker after every Turbo page load
// Note: bootstrap-select is loaded via CDN in admin layout
document.addEventListener("turbo:load", () => {
  if (window.$ && typeof $('.selectpicker').selectpicker === 'function') {
    $('.selectpicker').selectpicker('render');
    $('.selectpicker').selectpicker('refresh');
  }
});
