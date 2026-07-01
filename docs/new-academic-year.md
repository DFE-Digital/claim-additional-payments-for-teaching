# Opening the service for a new academic year

The audience for this document is a service operator opening the service at the start of a new academic year (typically September).

Upload data first, then open the service — to avoid a window where the service is open but data is missing.

## 1. CSV uploads

### Annual uploads

These are needed at the start of each claim year. Upload them via the relevant journey configuration page in the admin UI.

#### STRI — Claim a targeted retention incentive payment for school teachers

- **TRI school awards** — CSV with headers `school_urn,award_amount`. Select the new academic year before uploading. Previous year data is not carried over automatically.
- **School Workforce Census data** — upload at `/admin/school_workforce_census_data_uploads/new`. This **wipes all previously uploaded census data**, so do not upload another file until you receive the success or failure email. Used by the automated census subjects taught check.

#### FETRI — Claim a targeted retention incentive payment for further education teachers

- **Eligible FE providers** — CSV of providers eligible to verify claims. Select the new academic year before uploading.
- **Flagged FE providers** — CSV of providers flagged for additional review. No academic year selector; replaces the previous file entirely.

#### EY — Early years financial incentive payment service

- **Eligible EY providers** — Upload via the Provider authenticated journey configuration page. No academic year selector; latest upload takes effect.

#### EYTRP — Claim an early years teacher recognition payment

- **Eligible EYTRP providers** — Select the new academic year before uploading.

### Recurring operational uploads

These are uploaded throughout the year as needed, not specifically at year open:

- **TPS data** — upload at `/admin/tps_data_uploads/new`. Teachers Pension Service employment data used by automated employment checks. (STRI, FETRI, TSLR)
- **Fraud risk CSV** — upload at `/admin/fraud_risk_csv_uploads/new`. Flags claims matching risk indicators. (STRI, FETRI, IRP)
- **Claimant flags CSV** — upload at `/admin/claimant_flags_csv_uploads/new`. Flags individual claimants for additional admin review. (FETRI)

## 2. Manage services (Open a journey)

Once data uploads are confirmed, go to `/admin/journey_configurations`. For each active journey:

1. Click the journey name.
2. Set **"Accepting claims for academic year"** to the new year (e.g. `2026/2027`).
3. Set **"Service status"** to **Open**.
4. Click **Save**.

If a journey is being retired this year, set its status to **Closed** and add an availability message explaining when or whether it will reopen.

## 3. Verification

1. On each journey's admin config page, confirm the **"Service open"** status panel shows the correct academic year.
2. For Targeted Retention Incentive Payments, confirm the awards panel shows today's date as the last upload date for the new year.
3. Check the **Upload history** section on each journey page to confirm the CSV uploads are listed.
4. Visit each journey's public claim URL and confirm the journey is accessible rather than showing a service closed page.
