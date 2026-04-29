## Name & DOB & TRN & NINO

No `include` API param needed

### Old

```json
{
  "dob": "1994-10-31T00:00:00",
  "trn": "2187999",
  "name": "Some name",
  "ni_number": null
}
```

Current mapping:

- date_of_birth -> `{"dob": ...}`
- first_name -> `{"name": ...}` SPLIT
- surname -> `{"name": ...}` SPLIT
- national_insurance_number -> `{"ni_number": ...}`
- teacher_reference_number -> `{"trn": ...}`

### New

```json
{
  "trn": "3013047",
  "firstName": "Kenneth",
  "middleName": "",
  "lastName": "Decerqueira",
  "dateOfBirth": "1965-08-07",
  "nationalInsuranceNumber": "AB400011A",
}
```

New mapping:

- date_of_birth -> `{"dateOfBirth": ...}`
- first_name -> `{"firstName": ...}`
- surname -> `{"lastName": ...}`
- national_insurance_number -> `{"nationalInsuranceNumber": ...}`
- teacher_reference_number -> `{"trn": ...}`

## Induction

`include: induction`

### Old

```json
{
  "induction": {
    "state": "Active",
    "status": "In Progress",
    "start_date": "2023-09-01T00:00:00Z",
    "state_name": "Active",
    "completion_date": null
  }
}
```

Current mapping:

- induction_start_date ->  `{"induction": {"start_date": ...}}`
- induction_completion_date ->  `{"induction": {"completion_date": ...}}`
- induction_status -> `{"induction": {"status": ...}}`

### New

```json
{
  "induction": {
    "status": "Passed",
    "startDate": "2024-09-01",
    "completedDate": null,
    "exemptionReasons": []
  }
}
```

New mapping:

- induction_start_date ->  `{"induction": {"startDate": ...}}`
- induction_completion_date ->  `{"induction": {"completedDate": ...}}`
- induction_status -> `{"induction": {"status": ...}}`

## ITT

`include: routesToProfessionalStatuses`

### Old

```json
{
  "initial_teacher_training": {
  "state": "Active",
  "result": "Pass",
  "subject1": "mathematics",
  "subject2": null,
  "subject3": null,
  "state_code": "Active",
  "qualification": null,
  "subject1_code": "100403",
  "subject2_code": null,
  "subject3_code": null,
  "programme_type": "Provider-led (postgrad)",
  "programme_end_date": "2023-06-30T00:00:00Z",
  "programme_start_date": "2022-09-05T00:00:00Z"
  }
}
```

Current mapping:

- itt_subject_codes -> {"initial_teacher_training": {"subject1_code": ..., "subject2_code": ..., "subject3_code": ...}}
- itt_subjects -> {"initial_teacher_training": {"subject1": ..., "subject2": ..., "subject3": ...}}
- qualification_name -> {"initial_teacher_training": {"qualification": ...}}
- itt_start_date -> {"initial_teacher_training": {"programme_start_date": ...}}

### New

```json
{
  "routesToProfessionalStatuses": [
    {
      "routeToProfessionalStatusId": "e47d7e18-c563-4763-bd00-dc35fcf72c74",
      "routeToProfessionalStatusType": {
        "routeToProfessionalStatusTypeId": "57b86cef-98e2-4962-a74a-d47c7a34b838",
        "name": "Assessment Only",
        "professionalStatusType": "QualifiedTeacherStatus"
      },
      "status": "Holds",
      "holdsFrom": "2022-09-01",
      "trainingStartDate": "2024-09-01",
      "trainingEndDate": null,
      "trainingSubjects": [
        {
          "reference": "100358",
          "name": "applied computing"
        }
      ],
      "trainingAgeSpecialism": null,
      "trainingCountry": null,
      "trainingProvider": null,
      "degreeType": null,
      "inductionExemption": {
        "isExempt": false,
        "exemptionReasons": []
      }
    }
  ]
}
```

New mapping:

Iterate over `routesToProfessionalStatuses` array

- itt_subject_codes -> Iterate over `trainingSubjects` then `{"reference": ...}`
- itt_subjects -> Iterate over `trainingSubjects` then `"name": ...`
- qualification_name -> `{"routeToProfessionalStatusType": {"name": ...}}`
- itt_start_date -> `{"trainingStartDate": ...}`

Questions:

- Is is possible to have more than one `routesToProfessionalStatuses`?
- Previously this was flat with just ONE `programme_start_date`.
- So in this has if there was previously a `subject1` AND `subject2` would that map:
  - 2x `routesToProfessionalStatuses`
  - or 1x `routesToProfessionalStatuses` which contains 2x `trainingSubjects`?

## QTS

No `include` API param needed

### Old

```json
{
  "qualified_teacher_status": {
    "name": "Qualified teacher (trained)",
    "state": "Active",
    "qts_date": "2023-06-30T00:00:00Z",
    "state_name": "Active"
  }
}
```

Current mapping:

- qts_award_date -> {"qualified_teacher_status": "qts_date": ...}

### New

```json
{
  "qts": {
    "holdsFrom": "2022-09-01",
    "routes": [
      {
        "routeToProfessionalStatusType": {
          "routeToProfessionalStatusTypeId": "57b86cef-98e2-4962-a74a-d47c7a34b838",
          "name": "Assessment Only",
          "professionalStatusType": "QualifiedTeacherStatus"
        }
      }
    ]
  }
}
```

New mapping:

- qts_award_date -> {"qts": "holdsFrom": ...}

Questions:

- `holdsFrom` does that map to the old `qts_date`?

## Alerts

### Old

```json
{
  "active_alert": false,
}
```

Current mapping:

- active_alert? -> {"active_alert": ...}

### New

```json
{
  "alerts": [
    {
      "alertId": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
      "alertType": {
        "alertTypeId": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
        "alertCategory": {
          "alertCategoryId": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
          "name": "string"
        },
        "name": "string"
      },
      "details": "string",
      "startDate": "2026-01-27",
      "endDate": "2026-01-27"
    }
  ]
}
```

New mapping:

Current mapping:

- active_alert? -> Iterate through and if any of the have started and not ended?
