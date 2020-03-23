"use strict";

document.addEventListener("DOMContentLoaded", function () {
  var form = document.querySelector("form#verify_auth_request");

  if (!form) {
    return;
  }

  var submit_button = form.querySelector("#submit_verify_request");
  submit_button.style.display = "none";

  var heading = form.querySelector("#verify_heading");
  heading.innerText = "Continuing to next step…";

  var redirection_message = form.querySelector("#verify_redirection_message");
  redirection_message.innerText = "If your browser does not redirect in a few seconds, please try refreshing the page.";

  form.submit();
});
