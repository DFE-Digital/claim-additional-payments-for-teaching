"use strict";

document.addEventListener("DOMContentLoaded", function() {
  var fieldset = document.querySelector("#tslr_claim_eligible_subjects");
  var el;
  var eligibleSubjectsSelector;
  var notTeachingSubjectsSelector;

  if (!fieldset) {
    return;
  }

  fieldset.addEventListener(
    "click",
    function(e) {
      el = e.target;

      if (!el) {
        return;
      }
      if (el.checked === false) {
        return;
      }

      eligibleSubjectsSelector = "tslr_claim[eligible_subjects][]";
      notTeachingSubjectsSelector = "tslr_claim[mostly_teaching_eligible_subjects]";

      if (el.name == eligibleSubjectsSelector) {
        var radioButton = document.querySelector("input[type='radio'][name='" + notTeachingSubjectsSelector + "']");
        radioButton.checked = false;
      } else if (el.name == notTeachingSubjectsSelector) {
        var checkboxes = document.querySelectorAll("input[name='" + eligibleSubjectsSelector + "']");
        checkboxes.forEach(function(item, index) {
          item.checked = false;
        });
      }
    },
    false
  );
});
