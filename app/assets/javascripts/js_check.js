"use strict";

document.body.className +=
  " js-enabled" + ("noModule" in HTMLScriptElement.prototype ? " govuk-frontend-supported" : "");
