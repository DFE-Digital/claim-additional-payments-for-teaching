# Google BigQuery Integration

## Introduction

Integration with Google BigQuery is done through the [DfE Analytics gem](https://github.com/DFE-Digital/dfe-analytics).

The Data Insights Team have read capability to then be able to create dashboards and reports from the exported data.

## Sensitive data

All data to be exported by the Analytics gem must be explicitly whitelisted. The manifest for this can be found in `config/analytics.yml`. Should any data not wish to be exported these can be specified in:

- `config/analytics_blocklist.yml`
- `config/analytics_hidden_pii.yml`
- `config/analytics_pii.yml`

Please see [Dfe Analytics README](https://github.com/DFE-Digital/dfe-analytics/blob/main/README.md) for further information on how to use these.
