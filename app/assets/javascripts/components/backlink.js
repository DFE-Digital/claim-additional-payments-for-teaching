"use strict";

(function () {
  var backlink = document.getElementById("backlink");
  if (!backlink) return;

  // unhide backlink and add listener
  backlink.classList.remove("govuk-visually-hidden");
  backlink.addEventListener("click", () => {
    history.back();
  });
})();
