"use strict";

window.TeacherPayments = window.TeacherPayments || {};

window.TeacherPayments.cookies = {
  acceptCookieName: "accept_cookies",
  checkNonEssentialCookiesAccepted: function() {
    return this._get(this.acceptCookieName);
  },
  acceptNonEssentialCookies: function() {
    this._set(this.acceptCookieName, 1, 90);
  },
  _set: function(name, value, days) {
    var date = new Date();
    date.setTime(date.getTime() + 24 * 60 * 60 * 1000 * days);
    document.cookie = name + "=" + value + ";path=/;expires=" + date.toGMTString();
  },
  _get: function(name) {
    var v = document.cookie.match("(^|;) ?" + name + "=([^;]*)(;|$)");
    return v ? v[2] : null;
  }
};
