-- Eligibility for a claim comes from a seperate table based on the claim type.
-- This temporary table combines them into one eligibities table which is
-- referenced in the main select below. We can UNION like this as the IDs are
-- UUIDs so we can be sure there are no repeated IDs.
--
-- Unfortunately subject is recorded differently in each table so some finesing
-- is require around this.
WITH eligibilities AS
(
       SELECT id,
              current_school_id AS school_id,
              CASE eligible_itt_subject
                     WHEN 0 THEN 'chemistry'
                     WHEN 1 THEN 'foreign languages'
                     WHEN 2 THEN 'maths'
                     WHEN 3 THEN 'physics'
                     WHEN 4 THEN 'none'
              END AS subject
       FROM   early_career_payments_eligibilities
       UNION ALL
       SELECT id,
              current_school_id AS school_id,
              CASE initial_teacher_training_subject
                     WHEN 0 THEN 'maths'
                     WHEN 1 THEN 'physics'
                     WHEN 2 THEN 'science'
                     WHEN 3 THEN 'none'
              END AS subject
       FROM   maths_and_physics_eligibilities
       UNION ALL
       SELECT id,
              claim_school_id AS school_id,
              CASE
                     WHEN biology_taught IS true THEN 'biology'
                     WHEN chemistry_taught IS true THEN 'chemistry'
                     WHEN computing_taught IS true THEN 'computing'
                     WHEN languages_taught IS true THEN 'languages'
                     WHEN physics_taught IS true THEN 'physics'
                     ELSE 'none'
              END AS subject
       FROM   student_loans_eligibilities )
-- Build decsions table
SELECT c.id                       AS application_id,
       d.created_at               AS decision_date,
       c.teacher_reference_number AS trn,
       -- defined in models/decision.rb
       CASE d.result
              WHEN 0 THEN 'approved'
              WHEN 1 THEN 'rejected'
       END AS application_decision,
       -- derived from eligibility class names
       CASE c.eligibility_type
              WHEN 'EarlyCareerPayments::Eligibility' THEN 'early career payments'
              WHEN 'StudentLoans::Eligibility' THEN 'student loans'
              WHEN 'MathsAndPhysics::Eligibility' THEN 'maths and physics'
       END AS application_policy,
       e.subject,
       s.NAME                                              AS school_name,
       la.NAME                                             AS local_authorities_name,
       lad.NAME                                            AS local_authority_district_name,
       date_part('year', age(now(), c.date_of_birth))::int AS claimant_age,
       CASE c.payroll_gender
              WHEN 0 THEN 'don''t know'
              WHEN 1 THEN 'female'
              WHEN 2 THEN 'male'
       END             AS claimant_gender,
       c.academic_year AS claimant_year_qualified
FROM   decisions d,
       claims c,
       schools s,
       eligibilities e,
       local_authorities la,
       local_authority_districts lad
WHERE  d.claim_id = c.id
AND    c.eligibility_id = e.id
AND    e.school_id = s.id
AND    s.local_authority_id = la.id
AND    s.local_authority_district_id = lad.id;
