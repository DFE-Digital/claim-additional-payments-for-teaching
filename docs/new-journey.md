# Journeys

`Journeys` are user flows through the app that collect data and typically determine eligibility. These are backed by a `Policies` which house configuration of a policy such as eligibility.

## SlugSequence

`SlugSequence` is used to determine which pages the user will see as they progress through their journey. Answers can be used to determine what pages the user will see next. The logic to determin this is housed in `SlugSequence`.

## Journeys::Session

`Journeys::Session` are used by each journey to hold information the collected from the user as they progress their journey. These are scoped to each journey.

## Locales

To try to keep things tidy ensure that each journey uses its own locale file to keep each journey segregated.

## Creating new journeys

When a policy is introduced we will typically be adding a new journey to the service the user can waltkthrough. See the [following example PR which introduces a new journey](https://github.com/DFE-Digital/claim-additional-payments-for-teaching/pull/4470).
