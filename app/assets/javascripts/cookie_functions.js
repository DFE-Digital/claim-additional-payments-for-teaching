"use strict";

(function() {
  window.TeacherPayments = window.TeacherPayments || {};
  window.TeacherPayments.cookies = window.TeacherPayments.cookies || {};
  window.TeacherPayments.cookies.postNonEssentialCookieAcceptanceFunctions =
    window.TeacherPayments.cookies.postNonEssentialCookieAcceptanceFunctions || [];

  var acceptCookieName = "accept_cookies";

  function setCookie(name, value, days) {
    var date = new Date();
    date.setTime(date.getTime() + 24 * 60 * 60 * 1000 * days);
    document.cookie = name + "=" + value + ";path=/;expires=" + date.toGMTString();
  }

  function getCookie(name) {
    var v = document.cookie.match("(^|;) ?" + name + "=([^;]*)(;|$)");
    return v ? v[2] : null;
  }

  window.TeacherPayments.cookies.checkNonEssentialCookiesAccepted = function checkNonEssentialCookiesAccepted() {
    return getCookie(acceptCookieName);
  };

  window.TeacherPayments.cookies.acceptNonEssentialCookies = function acceptNonEssentialCookies() {
    setCookie(acceptCookieName, 1, 90);

    for (var i = 0; i < this.postNonEssentialCookieAcceptanceFunctions.length; i++) {
      this.postNonEssentialCookieAcceptanceFunctions[i]();
    }

    this.postNonEssentialCookieAcceptanceFunctions = [];
  };
})();
