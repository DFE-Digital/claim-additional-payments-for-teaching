"use strict";

document.addEventListener("DOMContentLoaded", function() {
  var fieldset = document.querySelector("#claim_subjects_taught");

  if (!fieldset) {
    return;
  }

  function toggleSubjectValues(event) {
    var el = event.target;
    var eligibleSubjectsClass = "subject";
    var notTeachingSubjectsName = "claim[eligibility_attributes][mostly_teaching_eligible_subjects]";

    if (!el) {
      return;
    }
    if (el.checked === false) {
      return;
    }

    if (el.classList.contains(eligibleSubjectsClass)) {
      var radioButton = document.querySelector("input[type='radio'][name='" + notTeachingSubjectsName + "']");
      radioButton.checked = false;
    } else if (el.name == notTeachingSubjectsName) {
      var checkboxes = document.querySelectorAll("input." + eligibleSubjectsClass);
      checkboxes.forEach(function(item, index) {
        item.checked = false;
      });
    }
  }

  fieldset.addEventListener("click", toggleSubjectValues, false);
});
