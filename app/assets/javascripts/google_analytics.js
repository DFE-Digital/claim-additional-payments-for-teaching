"use strict";

(function() {
  window.TeacherPayments = window.TeacherPayments || {};
  window.TeacherPayments.cookies = window.TeacherPayments.cookies || {};
  window.TeacherPayments.cookies.postNonEssentialCookieAcceptanceFunctions =
    window.TeacherPayments.cookies.postNonEssentialCookieAcceptanceFunctions || [];

  var currentScript = document.currentScript;

  function trackPageView() {
    ga("create", currentScript.getAttribute("data-ga-id"), "auto");
    ga("send", "pageview", { anonymizeIp: true });
  }

  document.addEventListener("DOMContentLoaded", function() {
    if (window.TeacherPayments.cookies.checkNonEssentialCookiesAccepted()) {
      trackPageView();
    } else {
      window.TeacherPayments.cookies.postNonEssentialCookieAcceptanceFunctions.push(trackPageView);
    }
  });
})();
