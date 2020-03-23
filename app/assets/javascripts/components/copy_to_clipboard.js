"use strict";

document.addEventListener("DOMContentLoaded", function () {
  var fields = document.querySelectorAll("[data-copy-to-clipboard=true]");

  fields.forEach(function (field) {
    field.parentNode.appendChild(copyLinkBuilder(field));
  });

  function copyToClipboard(fieldToCopy) {
    fieldToCopy.select();
    document.execCommand("copy");
  }

  function copyLinkBuilder(fieldToCopy) {
    var copyButton = document.createElement("button");
    copyButton.innerHTML = "Copy to clipboard";
    copyButton.className = "govuk-button govuk-!-margin-top-2";
    copyButton.setAttribute("data-module", "govuk-button");
    copyButton.addEventListener("click", function () {
      copyToClipboard(fieldToCopy);
    });

    return copyButton;
  }
});
