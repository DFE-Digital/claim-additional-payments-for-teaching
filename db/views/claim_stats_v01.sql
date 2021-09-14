SELECT
  c.id AS claim_id,
  CASE c.eligibility_type
    WHEN 'EarlyCareerPayments::Eligibility' THEN 'early career payments'
    WHEN 'StudentLoans::Eligibility' THEN 'student loans'
    WHEN 'MathsAndPhysics::Eligibility' THEN 'maths and physics'
  END AS policy,
  c.created_at AS claim_started_at,
  c.submitted_at AS claim_submitted_at,
  d.created_at AS decision_made_at,
  CASE d.result
    WHEN 0 THEN 'accepted'
    WHEN 1 THEN 'rejected'
  END AS result,
  CASE c.submitted_at
    WHEN null THEN null
    ELSE extract(epoch from c.submitted_at - c.created_at)
  END AS submission_length,
  CASE d.created_at
    WHEN null THEN null
    ELSE extract(epoch from d.created_at - c.submitted_at)
  END AS decision_length
FROM decisions d
RIGHT JOIN claims c ON c.id = d.claim_id
