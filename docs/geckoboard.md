# Geckoboard

The service uses [Geckoboard](https://www.geckoboard.com/) to present summary
information on the current state and overall performance of the service. As part
of this, the application sends updates on the state of claims to a
[dataset](https://support.geckoboard.com/hc/en-us/articles/223190488-Guide-to-using-datasets).
The data are then sliced and aggregated in Geckoboard for reporting purposes.

## API key

The API key for Geckoboard can be found in the
[Geckoboard account details](https://app.geckoboard.com/account/details). It
should be placed in the `GECKOBOARD_API_KEY` environment variable.

## The data

Geckoboard limits datasets to ten columns. We send the following ten datapoints
for each claim, updated for all claims when a claim moves between states, and
for all unchecked claims
[each morning](../app/jobs/geckoboard/update_unchecked_claims_job.rb). These
datasets are defined in code in
[`models/claim/geckoboard_dataset.rb`](../app/models/claim/geckoboard_dataset.rb)

### 1. Claim reference

The human-readable reference for the claim. This is the unique key for the
dataset, any updates sent to the dataset with the same reference as an existing
datapoint will be merged.

### 2. Policy name

A string of the policy which the claim was submitted under.

### 3. Submitted at

The date and time the claim was submitted.

### 4. SLA Status

A string representing the state of the claim relative to its SLA deadline. This
can be one of three values:

- `ok` - The claim is not approaching its check deadline
- `warning` - The claim is within the warning period of its check deadline
- `passed` - The claim has passed its check deadline

### 5. Check status

A string representing the current status of a claim with regard to checking. It
can be one of three values:

- `unchecked` - The claim has not yet been checked
- `approved` - The claim has been approved
- `rejected` - The claim has been rejected

From these it is possible to infer if a claim has been checked or not, as well
as the outcome of that check.

### 6. Checked at

If a claim has been checked, the date and time a check decision about the claim
was made.

If a claim has not been checked this will be the result of the
`placeholder_date_for_nil_value` function in the model. Geckoboard does not
allow `null` values for datetimes - setting this to an early date avoids it
interfering with visualisations using this date, which are usually filtered on
the `Check` column.

### 7. Number of days to check

If a claim has been checked, the whole number of calendar days between the claim
being submitted and the claim being checked.

If the claim has not been checked this value will be `null`.

### 8. Paid

A string representation of a boolean indicating if a claim is believed to have
been paid out or not.

### 9. Paid at

If a claim is believed to have been paid, the estimated date on which the payout
would have happened.

If a claim is not believed to have been paid this will be the result of the
`placeholder_date_for_nil_value` function in the model. Geckoboard does not
allow `null` values for datetimes - setting this to an early date avoids it
interfering with visualisations using this date, which are usually filtered on
the `Paid` column.

### 10. Award amount

The award amount of the claim, in _whole pence_. Conversion to pounds and pence,
rounding and formatting is handled by Geckoboard.

## Performing a hard reset

You will need to perform a hard reset of the Geckoboard dataset if you change
the dataset definition in
[`models/claim/geckoboard_dataset.rb`](../app/models/claim/geckoboard_dataset.rb).
You may also want to perform this if something has become horribly out of sync.

To reset the dataset run `rake geckoboard:reset`. This will delete and rebuild
the dataset, then restore the data for all claims.
