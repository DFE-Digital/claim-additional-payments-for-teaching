"use strict";

document.addEventListener("DOMContentLoaded", function () {
  var formAcceptCookie = document.querySelector("#formAcceptCookie");
  var formRejectCookie = document.querySelector("#formRejectCookie");
  var formHideAcceptCookie = document.querySelector("#formHideAcceptCookie");
  var formHideRejectCookie = document.querySelector("#formHideRejectCookie");

  if (formAcceptCookie) {
    formAcceptCookie.addEventListener("ajax:success", function(e, data, status, xhr) {
      document.querySelector("#askCookieBanner").hidden = true;
      document.querySelector("#acceptedCookieBanner").hidden = false;
    });
  }

  if (formRejectCookie) {
    formRejectCookie.addEventListener("ajax:success", function(e, data, status, xhr) {
      document.querySelector("#askCookieBanner").hidden = true;
      document.querySelector("#rejectedCookieBanner").hidden = false;
    });
  }

  if (formHideAcceptCookie) {
    formHideAcceptCookie.addEventListener("ajax:success", function(e, data, status, xhr) {
      document.querySelector("#acceptedCookieBanner").hidden = true;
    });
  }

  if (formHideRejectCookie) {
    formHideRejectCookie.addEventListener("ajax:success", function(e, data, status, xhr) {
      document.querySelector("#rejectedCookieBanner").hidden = true;
    });
  }
});
