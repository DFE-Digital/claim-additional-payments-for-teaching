# Payroll

## Deleting a payroll run

While testing the service it may be useful to delete a payroll run.

To do so, execute the following command in the relevant environment:

```bash
bin/rake delete_payroll_run\[<UUID of PayrollRun>\]
```

The UUID can be found in the URL of the payroll run on the admin site.

To delete the _last_ payroll run, you can simply run:

```bash
bin/rake delete_payroll_run
```

Of course, this command should probably not ever be run in the production
environment.
