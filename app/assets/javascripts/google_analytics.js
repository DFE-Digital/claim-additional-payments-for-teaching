"use strict";

var currentScript = document.currentScript;

document.addEventListener("DOMContentLoaded", function() {
  if (!window.TeacherPayments.cookies.checkNonEssentialCookiesAccepted()) {
    return;
  }

  window.dataLayer = window.dataLayer || [];

  function gtag() {
    window.dataLayer.push(arguments);
  }

  gtag("js", new Date());

  gtag("config", currentScript.getAttribute("data-ga-id"), { anonymize_ip: true });
});
