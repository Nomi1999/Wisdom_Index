--Insurance Metrics

--Life Insurance (Sum of all life insurance)
SELECT 
    COALESCE(SUM(death_benefit), 0) as life_insurance_metric
FROM core.life_insurance_annuity_accounts 
WHERE fact_type_name = 'Life Insurance' 
AND client_id = 1;


--Disability (Sum of all disability insurance)
SELECT COALESCE(SUM(benefit_amount), 0) as disability_metric
FROM core.disability_ltc_insurance_accounts 
WHERE fact_type_name IN ('Disability Policy', 'Business Disability Policy')
AND client_id = 2;


--LTC (Sum of all Long-term care insurance)
SELECT 
    COALESCE(SUM(benefit_amount),0) as ltc_metric
FROM core.disability_ltc_insurance_accounts 
WHERE sub_type = 'PersonalLT' 
AND client_id = 2;


-- Umbrella (Sum of all Umbrella insurance)
SELECT 
    COALESCE(SUM(maximum_annual_benefit),0) as umbrella_metric
FROM core.property_casualty_insurance_accounts 
WHERE sub_type = 'Umbrella' 
AND client_id = 1;


-- Business (Sum of all Business Insurance)
SELECT 
    COALESCE(SUM(benefit_amount), 0) AS business_insurance
FROM core.disability_ltc_insurance_accounts 
WHERE sub_type = 'BusinessReducingTerm'
AND client_id = 2;


-- Flood Insurance (Sum of all flood insurance)
SELECT 
    COALESCE(SUM(maximum_annual_benefit), 0) as flood_insurance_metric
FROM core.property_casualty_insurance_accounts 
WHERE sub_type = 'Flood'
AND client_id = 1;


-- At Risk (Sum of all taxable investmetns - umbrella insurance)
WITH taxable AS (
    SELECT COALESCE(SUM(total_value), 0) AS taxable_investments_usd
    FROM core.investment_deposit_accounts
    WHERE client_id = 4
      AND fact_type_name = 'Taxable Investment'   -- excludes IRA, 401k, 529 etc.
),
umbrella AS (
    SELECT COALESCE(SUM(maximum_annual_benefit), 0) AS umbrella_coverage_usd
    FROM core.property_casualty_insurance_accounts
    WHERE client_id = 4
      AND sub_type = 'Umbrella'
)
SELECT (taxable.taxable_investments_usd - umbrella.umbrella_coverage_usd) AS at_risk_usd
FROM taxable, umbrella;




