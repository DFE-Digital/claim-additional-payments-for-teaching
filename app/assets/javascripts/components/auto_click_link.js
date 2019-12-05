"use strict";

document.addEventListener("DOMContentLoaded", function() {
  var linkElement = document.querySelector("[data-auto-follow-link=true]");

  if (linkElement)
    window.setTimeout(function() {
      linkElement.click();
    }, 3 * 1000);
});
