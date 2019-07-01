"use strict";

document.addEventListener("DOMContentLoaded", function() {
  var form = document.querySelector("form#verify_auth_request");

  if (!form) {
    return;
  }

  form.submit();
});
