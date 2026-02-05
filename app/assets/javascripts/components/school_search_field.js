"use strict";

/*
  School search field.

  Like the search for current schools, but only replaces a single field rather
  than taking over the whole form.

  Usage:
  Set up a div with the following data attributes:
  - data-school-search-container="true"
    the autocomplete attaches to the element with this attribute

  - data-school-search-path="<%= school_search_index_path %>"
    where to fetch the search results from

  - data-school-search-school-id-target="#some-id"
    the element the school id will be written to

  - data-school-search-search-box-target="#some-id"
    the text box we get the initial search term from, will be replaced by the
    autocomplete

  - data-school-search-min_length="3"
    minimum number of characters before we start searching

  Example:
  ```
    <div
        data-school-search-container="true"
        data-school-search-path="<%= school_search_index_path %>"
        data-school-search-school-id-target="#admin_claims_employment_form_school_id"
        data-school-search-search-box-target="#admin_claims_employment_form_school_search"
        data-school-search-min_length="3"
      >
      <%= f.hidden_field :school_id %>

      <%= errors_tag f.object, :school_search %>

      <%= f.text_field(
        :school_search,
        label: { text: "Previous workplace" },
        class: css_classes_for_input(f.object, :school_search),
      ) %>
    </div>
  ```
*/

document.addEventListener("DOMContentLoaded", function () {
  var searchContainer = document.querySelector("[data-school-search-container='true']");

  if (!searchContainer) { return }

  var schoolSearchPath = searchContainer.dataset.schoolSearchPath;

  if (!schoolSearchPath) { return }

  // field we write the school id to
  var schoolIdTarget = document.querySelector(searchContainer.dataset.schoolSearchSchoolIdTarget);

  if (!schoolIdTarget) { return }

  var searchBoxTarget = document.querySelector(searchContainer.dataset.schoolSearchSearchBoxTarget);

	console.log(searchContainer.dataset.schoolSearchSearchBoxTarget)

	console.log('school search box target:', searchBoxTarget);

  if (!searchBoxTarget) { return }

  // get current input from the search text field and remove it, it will be
  // replaced by the accessibleAutocomplete
  var searchBoxId = searchBoxTarget.id;
  var searchValue = searchBoxTarget.value;
  var searchBoxName = searchBoxTarget.name;

  searchBoxTarget.parentNode.removeChild(searchBoxTarget);

  var excludeClosedSchools = searchContainer.dataset.excludeClosed || false;

  var displayMenu = searchContainer.dataset.schoolSearchDisplayMenu || "overlay";

  var inputClasses = searchContainer.dataset.schoolSearchInputClasses || null;

  var schools = [];

  function resetField(e) {
    schoolIdTarget.value = "";
  }

  function getSchoolIds() {
    return schools.map(function (school) {
      return school.id;
    });
  }

  function findSchool(id) {
    for (var i = 0; i < schools.length; i++) {
      var school = schools[i];

      if (school.id === id) {
        return school;
      }
    }
  }

  accessibleAutocomplete({
    element: searchContainer,
    id: searchBoxId,
    name: searchBoxName,
    defaultValue: searchValue || "",
    displayMenu: displayMenu,
    inputClasses: inputClasses,
    source: function (query, populateResults) {
      function handleResponse(response) {
        schools = response.data || [];

        populateResults(getSchoolIds());
      }

      Rails.ajax({
        type: "post",
        url: schoolSearchPath,
        data: new URLSearchParams({
          query: query,
          exclude_closed: excludeClosedSchools
        }),
        success: handleResponse,
        error: handleResponse,
      });
    },
    minLength: parseInt(searchContainer.dataset.schoolSearchMinLength || 3),
    showNoOptionsFound: false,
    confirmOnBlur: false,
    templates: {
      inputValue: function (id) {
        var school = findSchool(id);

        if (school) return school.name;
      },
      suggestion: function (id) {
        var school = findSchool(id);

        if (!school) {
          return "<div></div>";
        }

        var suggestion =
          '<div class="school-search__suggestion">' +
            '<div class="school-search__suggestion-main-section">' +
              '<label class="govuk-label govuk-label--s">' +
              school.name +
              "</label>" +
              '<div class="govuk-hint">' +
              school.address +
              "</div>" +
            "</div>" +
          "</div>";

        if (school.closeDate) {
          suggestion +=
            '<div class="school-search__closed-status">' +
              '<div class="govuk-hint govuk-!-margin-bottom-1">' +
                "Closed on<br>" +
                school.closeDate +
              "</div>" +
            "</div>";
        }

        suggestion += "</div>";
        return suggestion;
      },
    },
    onConfirm: function (id) {
      var school = findSchool(id);

      if (school) {
        schoolIdTarget.value = school.id;
      } else {
        // NOOP
      }
    }
  })

  var accessibleAutocompleteSearchBox = document.getElementById(searchBoxId);
  accessibleAutocompleteSearchBox.addEventListener("input", resetField);
});

