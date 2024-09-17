"use strict";

(function () {
  var currentScript = document.currentScript;

  function trackPageView() {
    ga("create", currentScript.getAttribute("data-ga-id"), "auto");
    ga("send", "pageview", { anonymizeIp: true });
  }

  document.addEventListener("DOMContentLoaded", function () {
    trackPageView();
  });
})();
