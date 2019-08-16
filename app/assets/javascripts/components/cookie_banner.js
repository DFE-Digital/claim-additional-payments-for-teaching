"use strict";

document.addEventListener("DOMContentLoaded", function() {
  var cookiePolicyName = "accept_cookie_policy";
  var acceptCookies = getCookie(cookiePolicyName);
  var cookieBanner = document.querySelector("#global-cookie-message");
  var acceptButton = document.querySelector("#accept-cookies");

  if (!acceptCookies) {
    cookieBanner.style.display = "block";
  }

  acceptButton.onclick = function() {
    setCookie(cookiePolicyName, 1, 365);
    cookieBanner.style.display = "none";
  };

  function getCookie(name) {
    var v = document.cookie.match("(^|;) ?" + name + "=([^;]*)(;|$)");
    return v ? v[2] : null;
  }

  function setCookie(name, value, days) {
    var date = new Date();
    date.setTime(date.getTime() + 24 * 60 * 60 * 1000 * days);
    document.cookie = name + "=" + value + ";path=/;expires=" + date.toGMTString();
  }
});
