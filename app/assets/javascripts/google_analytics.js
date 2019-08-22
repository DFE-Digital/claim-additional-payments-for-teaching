"use strict";

(function() {
  window.TeacherPayments = window.TeacherPayments || {};
  window.TeacherPayments.cookies = window.TeacherPayments.cookies || {};
  window.TeacherPayments.cookies.postNonEssentialCookieAcceptanceFunctions =
    window.TeacherPayments.cookies.postNonEssentialCookieAcceptanceFunctions || [];

  var currentScript = document.currentScript;

  function enableGoogleAnalytics() {
    window.dataLayer = window.dataLayer || [];

    function gtag() {
      window.dataLayer.push(arguments);
    }

    gtag("js", new Date());
    gtag("config", currentScript.getAttribute("data-ga-id"), { anonymize_ip: true });
  }

  document.addEventListener("DOMContentLoaded", function() {
    if (window.TeacherPayments.cookies.checkNonEssentialCookiesAccepted()) {
      enableGoogleAnalytics();
    } else {
      window.TeacherPayments.cookies.postNonEssentialCookieAcceptanceFunctions.push(enableGoogleAnalytics);
    }
  });
})();
