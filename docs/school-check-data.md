# Generating School Check Data

**NB: This process involves accessing the production console. You will need an
approved PIM request, and a second developer to observe during this.**

As part of verifying a teacher's claims, service operators will send an email to
the relevant school to confirm their eligibility. Generating a list of claims
which need this email sending is a developer task, documented below.

## Process

1. Visit the
   [School Check Email - Sent Claims spreadsheet](https://docs.google.com/spreadsheets/d/1mxMND-SqOjK7yyYp0EaEJOOCUYFkqLJ1ZIwPLuSVKfM/edit#gid=1926551388)

2. On the second sheet, copy the contents of cell A1. This should be a
   comma-delimited list of all the claim references which have already been
   checked, for example `A1B2C345,D6E7F890,G1H2I345...`. Check to make sure
   there are no trailing commas

3. Have a second developer join you to observe, and connect to the production
   console using

   ```
   bin/azure-console production
   ```

4. Activate the Rails console in sandbox mode with

   ```
   bin/rails console --sandbox
   ```

5. Create a new instance of `Claim::SchoolCheckEmailDataExport` with

   ```
   exporter = Claim::SchoolCheckEmailDataExport.new("A1B2C345,D6E7F890,G1H2I345...")
   ```

   substituting the claim references for the string you copied from the
   spreadsheet in step 2.

6. Generate the CSV data of claims needing checking by running

   ```
   puts exporter.csv_string
   ```

   You may need to press the space bar to make your terminal render to the end
   of the output.

7. Copy the output and save as a CSV file with the name
   `school-check-batch_ddmmyyyy.csv`

8. Securely transfer the file to the relevant service operator to follow the
   rest of the school check process. The best way we’ve found to do this is to
   create a [new Google Sheets document](https://sheets.new/), private to
   yourself and shared only with the service operator.

9. From the CSV file, copy the claim references (and no other details) and
   append them to the first worksheet in the
   [School Check Email - Sent Claims spreadsheet](https://docs.google.com/spreadsheets/d/1mxMND-SqOjK7yyYp0EaEJOOCUYFkqLJ1ZIwPLuSVKfM/edit#gid=1926551388)
   so that they will be excluded the next time the process is run. Trim any
   remaining empty cells from the bottom of the column

10. After the service operator has sent the school check emails, delete the
    personal data from your machine and Google Sheets.
