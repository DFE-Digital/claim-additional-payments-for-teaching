"use strict";

document.addEventListener("DOMContentLoaded", function () {
  var cookieBanner = document.querySelector("#global-cookie-message");
  var acceptButton = document.querySelector("#accept-cookies");

  if (!window.TeacherPayments.cookies.checkNonEssentialCookiesAccepted()) {
    cookieBanner.classList.add("govuk-cookie-banner--visible");
  }

  acceptButton.onclick = function () {
    window.TeacherPayments.cookies.acceptNonEssentialCookies();
    cookieBanner.classList.remove("govuk-cookie-banner--visible");
  };
});
