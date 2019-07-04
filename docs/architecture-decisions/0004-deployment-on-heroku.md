# 4. Deployment on Heroku

Date: 2019-04-03

## Status

Accepted

## Context

Department for Education have a Cloud Infrastructure Program based on Azure that
they would like digital services to use. Access to Azure is heavily restricted
for production, and slightly restricted for lower environments.

We need to be able to work quickly, particularly in the early stages of this
project.

We need to be able to deploy prototypes and experimental features and versions
of the service for user research.

## Decision

We will use Heroku to deploy the application.

We will use Heroku's pipeline feature to run CI and deploy the application.

## Consequences

The team will have full access and control of the infrastructure the service is
deployed to, and the ability to grant that access to new team members as
required.

We will need to work with DfE to get access to Azure and make a plan to deploy
the service to it later in the beta.
