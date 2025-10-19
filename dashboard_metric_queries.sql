--Insurance Metrics

--Life Insurance (Sum of all life insurance)
SELECT 
       COALESCE(SUM(death_benefit),0) AS life_insurance_usd
FROM core.life_insurance_annuity_accounts
WHERE death_benefit IS NOT NULL
AND client_id = 1;

--Disability (Sum of all disability insurance)
SELECT COALESCE(SUM(benefit_amount), 0) AS disability_coverage_usd
FROM (
      -- individual / business / group-ST & LT policies
      SELECT benefit_amount
      FROM core.disability_ltc_insurance_accounts
      WHERE client_id = 6
        AND benefit_amount IS NOT NULL

      UNION ALL

      -- group LTD facts
      SELECT amount AS benefit_amount
      FROM core.facts
      WHERE client_id = 6
        AND fact_type_name = 'Disability Policy'
        AND amount > 0
) AS all_disability;

--LTC (Sum of all Long-term care insurance)
SELECT COALESCE(SUM(benefit_amount), 0) AS ltc_coverage_usd
FROM core.disability_ltc_insurance_accounts
WHERE client_id = 1
  AND benefit_amount IS NOT NULL
  AND (sub_type = 'PersonalLT'         -- standalone LTC
       OR fact_type_name ILIKE '%long-term care%'
       OR fact_type_name ILIKE '%ltc%');

-- Umbrella (Sum of all Umbrella insurance)
SELECT COALESCE(SUM(maximum_annual_benefit), 0) AS umbrella_coverage_usd
FROM core.property_casualty_insurance_accounts
WHERE client_id = 1
  AND sub_type = 'Umbrella'
  AND maximum_annual_benefit IS NOT NULL;

-- Business (Sum of all Business Insurance)
SELECT COALESCE(SUM(coverage_amount), 0) AS business_insurance_usd
FROM (
      /* 1. Commercial liability / property */
      SELECT maximum_annual_benefit AS coverage_amount
      FROM core.property_casualty_insurance_accounts
      WHERE client_id = 3
        AND sub_type = 'Commercial'

      UNION ALL

      /* 2. Business disability / LTC riders */
      SELECT benefit_amount
      FROM core.disability_ltc_insurance_accounts
      WHERE client_id = 3
        AND sub_type = 'BusinessReducingTerm'

      UNION ALL

      /* 3. Group life key-man or buy-sell */
      SELECT death_benefit
      FROM core.life_insurance_annuity_accounts
      WHERE client_id = 3
        AND sub_type = 'Group'
        AND account_name ILIKE '%business%'
) AS all_business;

-- Flood Insurance (Sum of all flood insurance)
SELECT COALESCE(SUM(maximum_annual_benefit), 0) AS flood_insurance_usd
FROM core.property_casualty_insurance_accounts
WHERE client_id = 1
  AND (sub_type ILIKE '%flood%'
       OR account_name ILIKE '%flood%');

-- At Risk (Sum of all taxable investmetns - umbrella insurance)
WITH taxable AS (
    SELECT COALESCE(SUM(total_value), 0) AS taxable_investments_usd
    FROM core.investment_deposit_accounts
    WHERE client_id = 1
      AND fact_type_name = 'Taxable Investment'   -- excludes IRA, 401k, 529 etc.
),
umbrella AS (
    SELECT COALESCE(SUM(maximum_annual_benefit), 0) AS umbrella_coverage_usd
    FROM core.property_casualty_insurance_accounts
    WHERE client_id = 1
      AND sub_type = 'Umbrella'
)
SELECT (taxable.taxable_investments_usd - umbrella.umbrella_coverage_usd) AS at_risk_usd
FROM taxable, umbrella;




