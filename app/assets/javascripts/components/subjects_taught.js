"use strict";

document.addEventListener("DOMContentLoaded", function() {
  var fieldset = document.querySelector("#tslr_claim_eligible_subjects");

  if (!fieldset) {
    return;
  }

  function toggleSubjectValues(event) {
    var el = event.target;
    var eligibleSubjectsName = "tslr_claim[eligible_subjects][]";
    var notTeachingSubjectsName = "tslr_claim[mostly_teaching_eligible_subjects]";

    if (!el) {
      return;
    }
    if (el.checked === false) {
      return;
    }

    if (el.name == eligibleSubjectsName) {
      var radioButton = document.querySelector("input[type='radio'][name='" + notTeachingSubjectsName + "']");
      radioButton.checked = false;
    } else if (el.name == notTeachingSubjectsName) {
      var checkboxes = document.querySelectorAll("input[name='" + eligibleSubjectsName + "']");
      checkboxes.forEach(function(item, index) {
        item.checked = false;
      });
    }
  }

  fieldset.addEventListener("click", toggleSubjectValues, false);
});
