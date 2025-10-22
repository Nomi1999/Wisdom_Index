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


-- Total Expenses per client (sum of all categories)
WITH params AS (
    SELECT 2::INT AS client_id,
           DATE_TRUNC('year', CURRENT_DATE) AS current_year_start
),
-- Giving
projected_giving_cte AS (
    SELECT p.client_id,
           COALESCE(SUM(e.annual_amount),0) AS projected_giving
    FROM params p
    LEFT JOIN core.expenses e ON e.client_id = p.client_id
    WHERE (LOWER(e.type) LIKE '%giving%' OR LOWER(e.sub_type) LIKE '%giving%' OR LOWER(e.sub_type) LIKE '%charity%')
      AND e.start_actual_date <= p.current_year_start + INTERVAL '1 year' - INTERVAL '1 day'
      AND (e.end_projection_date >= p.current_year_start OR e.end_projection_date IS NULL)
    GROUP BY p.client_id
),
actual_giving_cte AS (
    SELECT p.client_id,
           COALESCE(SUM(f.amount),0) AS actual_giving
    FROM params p
    LEFT JOIN core.flows f ON f.client_id = p.client_id
    WHERE (LOWER(f.fact_type_name) IN ('other expense','gift') AND (LOWER(f.sub_type) LIKE '%giving%' OR LOWER(f.sub_type) LIKE '%gift%'))
      AND f.amount_as_of >= p.current_year_start
      AND f.amount_as_of < p.current_year_start + INTERVAL '1 year'
    GROUP BY p.client_id
),
-- Living Expenses
projected_living_cte AS (
    SELECT p.client_id,
           COALESCE(SUM(e.annual_amount),0) AS projected_living
    FROM params p
    LEFT JOIN core.expenses e ON e.client_id = p.client_id
    WHERE (LOWER(e.type) IN ('living','spending') AND LOWER(e.sub_type) NOT LIKE '%giving%')
      AND e.start_actual_date <= p.current_year_start + INTERVAL '1 year' - INTERVAL '1 day'
      AND (e.end_projection_date >= p.current_year_start OR e.end_projection_date IS NULL)
    GROUP BY p.client_id
),
actual_living_cte AS (
    SELECT p.client_id,
           COALESCE(SUM(f.amount),0) AS actual_living
    FROM params p
    LEFT JOIN core.flows f ON f.client_id = p.client_id
    WHERE LOWER(f.fact_type_name) IN ('living expense','education expense','other expense')
      AND LOWER(f.sub_type) NOT LIKE '%giving%' AND LOWER(f.sub_type) NOT LIKE '%philanthropy%'
      AND f.amount_as_of >= p.current_year_start
      AND f.amount_as_of < p.current_year_start + INTERVAL '1 year'
    GROUP BY p.client_id
),
-- Taxes
projected_taxes_cte AS (
    SELECT p.client_id,
           COALESCE(SUM(e.annual_amount),0) AS projected_taxes
    FROM params p
    LEFT JOIN core.expenses e ON e.client_id = p.client_id
    WHERE LOWER(e.type) LIKE '%tax%' OR LOWER(e.sub_type) LIKE '%tax%'
      AND e.start_actual_date <= p.current_year_start + INTERVAL '1 year' - INTERVAL '1 day'
      AND (e.end_projection_date >= p.current_year_start OR e.end_projection_date IS NULL)
    GROUP BY p.client_id
),
actual_taxes_cte AS (
    SELECT p.client_id,
           COALESCE(SUM(f.amount),0) AS actual_taxes
    FROM params p
    LEFT JOIN core.flows f ON f.client_id = p.client_id
    WHERE LOWER(f.fact_type_name) LIKE '%tax%'
      AND f.amount_as_of >= p.current_year_start
      AND f.amount_as_of < p.current_year_start + INTERVAL '1 year'
    GROUP BY p.client_id
),
-- Savings
projected_savings_expenses_cte AS (
    SELECT p.client_id,
           COALESCE(SUM(e.annual_amount),0) AS projected_savings_expenses
    FROM params p
    LEFT JOIN core.expenses e ON e.client_id = p.client_id
    WHERE LOWER(e.type) LIKE '%savings%' OR LOWER(e.sub_type) LIKE '%savings%'
      AND e.start_actual_date <= p.current_year_start + INTERVAL '1 year' - INTERVAL '1 day'
      AND (e.end_projection_date >= p.current_year_start OR e.end_projection_date IS NULL)
    GROUP BY p.client_id
),
projected_savings_table_cte AS (
    SELECT
        p.client_id,
        COALESCE(SUM(s.amount_numeric), 0)  AS total_savings
    FROM
        params p
    LEFT JOIN core.savings s ON s.client_id = p.client_id
    WHERE
        s.start_type ='Active'
    GROUP BY p.client_id

),
actual_savings_cte AS (
    SELECT p.client_id,
           COALESCE(SUM(f.amount),0) AS actual_savings
    FROM params p
    LEFT JOIN core.flows f ON f.client_id = p.client_id
    WHERE LOWER(f.fact_type_name) LIKE '%savings%'
      AND f.amount_as_of >= p.current_year_start
      AND f.amount_as_of < p.current_year_start + INTERVAL '1 year'
    GROUP BY p.client_id
),
-- Debts
projected_debt_cte AS (
    SELECT p.client_id,
           COALESCE(SUM(e.annual_amount),0) AS projected_debt
    FROM params p
    LEFT JOIN core.expenses e ON e.client_id = p.client_id
    WHERE LOWER(e.type) LIKE '%loan%' OR LOWER(e.type) LIKE '%debt%' OR LOWER(e.type) LIKE '%mortgage%'
       OR LOWER(e.type) LIKE '%credit%' OR LOWER(e.sub_type) LIKE '%loan%' OR LOWER(e.sub_type) LIKE '%debt%'
       OR LOWER(e.sub_type) LIKE '%mortgage%' OR LOWER(e.sub_type) LIKE '%credit%'
      AND e.start_actual_date <= p.current_year_start + INTERVAL '1 year' - INTERVAL '1 day'
      AND (e.end_projection_date >= p.current_year_start OR e.end_projection_date IS NULL)
    GROUP BY p.client_id
),
actual_debt_cte AS (
    SELECT p.client_id,
           COALESCE(SUM(f.amount),0) AS actual_debt
    FROM params p
    LEFT JOIN core.flows f ON f.client_id = p.client_id
    WHERE LOWER(f.fact_type_name) LIKE '%loan%' OR LOWER(f.fact_type_name) LIKE '%mortgage%' OR LOWER(f.fact_type_name) LIKE '%credit%'
      AND f.amount_as_of >= p.current_year_start
      AND f.amount_as_of < p.current_year_start + INTERVAL '1 year'
    GROUP BY p.client_id
),
liability_cte AS (
    SELECT p.client_id,
           COALESCE(SUM(l.total_value),0) AS outstanding_debt,
           COALESCE(SUM(
                CASE
                    WHEN l.interest_rate IS NOT NULL AND l.interest_rate>0 THEN
                        l.total_value * (l.interest_rate/12) * POWER(1 + l.interest_rate/12, l.loan_term_in_years*12) /
                        (POWER(1 + l.interest_rate/12, l.loan_term_in_years*12)-1)*12
                    ELSE
                        l.total_value / NULLIF(l.loan_term_in_years,0)
                END
           ),0) AS annual_debt_payment
    FROM params p
    LEFT JOIN core.liability_note_accounts l ON l.client_id = p.client_id
    GROUP BY p.client_id
)
-- Final selection
SELECT
    p.client_id,
    -- Projected Expenses
    COALESCE(pg.projected_giving,0) +
    COALESCE(pl.projected_living,0) +
    COALESCE(pt.projected_taxes,0) +
    COALESCE(ps_exp.projected_savings_expenses,0) +
    COALESCE(ps_table.total_savings,0) +
    COALESCE(pd.projected_debt,0) AS projected_expenses,
    -- Actual Expenses
    COALESCE(ag.actual_giving,0) +
    COALESCE(al.actual_living,0) +
    COALESCE(at.actual_taxes,0) +
    COALESCE(asv.actual_savings,0) +
    COALESCE(ad.actual_debt,0) AS actual_expenses,
    -- Outstanding / future liabilities
    COALESCE(lia.outstanding_debt,0) AS outstanding_debt,
    COALESCE(lia.annual_debt_payment,0) AS annual_debt_payment
FROM params p
LEFT JOIN projected_giving_cte pg ON p.client_id = pg.client_id
LEFT JOIN actual_giving_cte ag ON p.client_id = ag.client_id
LEFT JOIN projected_living_cte pl ON p.client_id = pl.client_id
LEFT JOIN actual_living_cte al ON p.client_id = al.client_id
LEFT JOIN projected_taxes_cte pt ON p.client_id = pt.client_id
LEFT JOIN actual_taxes_cte at ON p.client_id = at.client_id
LEFT JOIN projected_savings_expenses_cte ps_exp ON p.client_id = ps_exp.client_id
LEFT JOIN projected_savings_table_cte ps_table ON p.client_id = ps_table.client_id
LEFT JOIN actual_savings_cte asv ON p.client_id = asv.client_id
LEFT JOIN projected_debt_cte pd ON p.client_id = pd.client_id
LEFT JOIN actual_debt_cte ad ON p.client_id = ad.client_id
LEFT JOIN liability_cte lia ON p.client_id = lia.client_id;

--Giving expenses
WITH params AS (
    -- Set client_id once
    SELECT 2::INT AS client_id,
           DATE_TRUNC('year', CURRENT_DATE) AS current_year_start
),
annual_giving_cte AS (
    -- Projected / Planned Giving from expenses
    SELECT
        p.client_id,
        COALESCE(SUM(e.annual_amount), 0) AS annual_giving
    FROM
        params p
    LEFT JOIN core.expenses e ON e.client_id = p.client_id
    WHERE
        (LOWER(e.type) LIKE '%giving%'
         OR LOWER(e.sub_type) LIKE '%giving%'
         OR LOWER(e.sub_type) LIKE '%charity%')
        AND e.start_actual_date <= p.current_year_start + INTERVAL '1 year' - INTERVAL '1 day'
        AND (e.end_projection_date >= p.current_year_start OR e.end_projection_date IS NULL)
    GROUP BY
        p.client_id
),
actual_giving_cte AS (
    -- Actual Giving from flows
    SELECT
        p.client_id,
        COALESCE(SUM(f.amount), 0) AS actual_giving
    FROM
        params p
    LEFT JOIN core.flows f ON f.client_id = p.client_id
    WHERE
        (LOWER(f.fact_type_name) = 'other expense' OR LOWER(f.fact_type_name) = 'gift')
        AND (LOWER(f.sub_type) LIKE '%giving%' OR LOWER(f.sub_type) LIKE '%gift%')
        AND f.amount_as_of >= p.current_year_start
        AND f.amount_as_of < p.current_year_start + INTERVAL '1 year'
    GROUP BY
        p.client_id
)
-- Final selection
SELECT
    p.client_id,
    COALESCE(pg.annual_giving, 0) AS annual_giving,
    COALESCE(ag.actual_giving, 0) AS actual_giving
FROM
    params p
LEFT JOIN annual_giving_cte pg ON p.client_id = pg.client_id
LEFT JOIN actual_giving_cte ag ON p.client_id = ag.client_id;

-- Savings per client
WITH params AS (
    SELECT 2::INT AS client_id,
           DATE_TRUNC('year', CURRENT_DATE) AS current_year_start
),
annual_savings_expenses_cte AS (
    -- Projected / Planned Savings from expenses table
    SELECT
        p.client_id,
        COALESCE(SUM(e.annual_amount), 0) AS annual_savings
    FROM
        params p
    LEFT JOIN core.expenses e ON e.client_id = p.client_id
    WHERE
        LOWER(e.type) LIKE '%savings%'
        OR LOWER(e.sub_type) LIKE '%savings%'
        AND e.start_actual_date <= p.current_year_start + INTERVAL '1 year' - INTERVAL '1 day'
        AND (e.end_projection_date >= p.current_year_start OR e.end_projection_date IS NULL)
    GROUP BY p.client_id
),
projected_savings_table_cte AS (
    -- Planned Savings from savings table
    SELECT
        p.client_id,
        COALESCE(SUM(s.fixed_amount_usd), 0)  AS total_savings
    FROM
        params p
    LEFT JOIN core.savings s ON s.client_id = p.client_id
    WHERE
        s.start_type ='Active'
    GROUP BY p.client_id
),
actual_savings_flows_cte AS (
    -- Actual Savings Contributions from flows table
    SELECT
        p.client_id,
        COALESCE(SUM(f.amount), 0) AS actual_savings
    FROM
        params p
    LEFT JOIN core.flows f ON f.client_id = p.client_id
    WHERE
        LOWER(f.fact_type_name) LIKE '%savings%'
        AND f.amount_as_of >= p.current_year_start
        AND f.amount_as_of < p.current_year_start + INTERVAL '1 year'
    GROUP BY p.client_id
)
SELECT
    p.client_id,
    COALESCE(ps_exp.annual_savings,0)AS annual_savings,
	COALESCE(ps_table.total_savings,0) AS total_savings,
    COALESCE(asv.actual_savings, 0) AS actual_savings
FROM
    params p
LEFT JOIN annual_savings_expenses_cte ps_exp ON p.client_id = ps_exp.client_id
LEFT JOIN projected_savings_table_cte ps_table ON p.client_id = ps_table.client_id
LEFT JOIN actual_savings_flows_cte asv ON p.client_id = asv.client_id;

-- Debt payments for a single client (Minimal Version)

SELECT
    2 AS client_id, -- Directly specify the ID
    COALESCE(SUM(l.total_value), 0) AS outstanding_debt,
    COALESCE(SUM(
        CASE
            -- Annuity formula for Annual Payment
            WHEN l.interest_rate IS NOT NULL AND l.interest_rate > 0 THEN
                l.total_value * (l.interest_rate/12) * POWER(1 + l.interest_rate/12, l.loan_term_in_years*12) /
                NULLIF(POWER(1 + l.interest_rate/12, l.loan_term_in_years*12) - 1, 0) * 12
            -- Simple amortization (principal only)
            ELSE
                l.total_value / NULLIF(l.loan_term_in_years, 0)
        END
    ), 0) AS annual_debt_payment
FROM
    core.liability_note_accounts l
WHERE
    l.client_id = 2;

--Taxes Metric
WITH params AS (
    -- Set client_id and current year start
    SELECT 2::INT AS client_id,
           DATE_TRUNC('year', CURRENT_DATE) AS current_year_start
),
annual_taxes_cte AS (
    -- Projected / Planned Taxes from expenses
    SELECT
        p.client_id,
        COALESCE(SUM(e.annual_amount), 0) AS annual_taxes
    FROM
        params p
    LEFT JOIN core.expenses e ON e.client_id = p.client_id
    WHERE
        (LOWER(e.type) LIKE '%tax%' OR LOWER(e.sub_type) LIKE '%tax%')
        AND e.start_actual_date <= p.current_year_start + INTERVAL '1 year' - INTERVAL '1 day'
        AND (e.end_projection_date >= p.current_year_start OR e.end_projection_date IS NULL)
    GROUP BY
        p.client_id
),
actual_taxes_cte AS (
    -- Actual Taxes Paid from flows
    SELECT
        p.client_id,
        COALESCE(SUM(f.amount), 0) AS actual_taxes
    FROM
        params p
    LEFT JOIN core.flows f ON f.client_id = p.client_id
    WHERE
        LOWER(f.fact_type_name) LIKE '%tax%'
        AND f.amount_as_of >= p.current_year_start
        AND f.amount_as_of < p.current_year_start + INTERVAL '1 year'
    GROUP BY
        p.client_id
)
-- Final selection
SELECT
    p.client_id,
    COALESCE(pt.annual_taxes, 0) AS annual_taxes,
    COALESCE(at.actual_taxes, 0) AS actual_taxes
FROM
    params p
LEFT JOIN annual_taxes_cte pt ON p.client_id = pt.client_id
LEFT JOIN actual_taxes_cte at ON p.client_id = at.client_id;

--Living Metric
WITH params AS (
    -- Set client_id and current year start
    SELECT 2::INT AS client_id,
           DATE_TRUNC('year', CURRENT_DATE) AS current_year_start
),
annual_living_cte AS (
    -- Projected / Planned Living Expenses from expenses
    SELECT
        p.client_id,
        COALESCE(SUM(e.annual_amount), 0) AS annual_living_expenses
    FROM
        params p
    LEFT JOIN core.expenses e ON e.client_id = p.client_id
    WHERE
        (LOWER(e.type) = 'living' OR LOWER(e.type) = 'spending')
        AND LOWER(e.sub_type) NOT LIKE '%giving%'  -- exclude giving/philanthropy
        AND e.start_actual_date <= p.current_year_start + INTERVAL '1 year' - INTERVAL '1 day'
        AND (e.end_projection_date >= p.current_year_start OR e.end_projection_date IS NULL)
    GROUP BY
        p.client_id
),
actual_living_cte AS (
    -- Actual Living Expenses from flows
    SELECT
        p.client_id,
        COALESCE(SUM(f.amount), 0) AS actual_living_expenses
    FROM
        params p
    LEFT JOIN core.flows f ON f.client_id = p.client_id
    WHERE
        LOWER(f.fact_type_name) IN ('living expense', 'education expense', 'other expense')
        AND LOWER(f.sub_type) NOT LIKE '%giving%'
        AND LOWER(f.sub_type) NOT LIKE '%philanthropy%'
        AND f.amount_as_of >= p.current_year_start
        AND f.amount_as_of < p.current_year_start + INTERVAL '1 year'
    GROUP BY
        p.client_id
)
-- Final selection
SELECT
    p.client_id,
    COALESCE(pl.annual_living_expenses, 0) AS annual_living_expenses,
    COALESCE(al.actual_living_expenses, 0) AS actual_living_expenses
FROM
    params p
LEFT JOIN annual_living_cte pl ON p.client_id = pl.client_id
LEFT JOIN actual_living_cte al ON p.client_id = al.client_id;

-- Margin Metric
--We can calculate this by using : Total Income - Total Expenses. (We already have queries for -----total income and Total expenses).


CREATE OR REPLACE VIEW core.vw_expense_summary AS
WITH params AS (
    SELECT DISTINCT client_id,
           DATE_TRUNC('year', CURRENT_DATE) AS current_year_start
    FROM core.expenses
    UNION
    SELECT DISTINCT client_id, DATE_TRUNC('year', CURRENT_DATE) FROM core.flows
    UNION
    SELECT DISTINCT client_id, DATE_TRUNC('year', CURRENT_DATE) FROM core.savings
    UNION
    SELECT DISTINCT client_id, DATE_TRUNC('year', CURRENT_DATE) FROM core.liability_note_accounts
),

-- Giving
annual_giving AS (
    SELECT p.client_id, COALESCE(SUM(e.annual_amount),0) AS annual_giving
    FROM params p
    LEFT JOIN core.expenses e ON e.client_id = p.client_id
    WHERE (LOWER(e.type) LIKE '%giving%' OR LOWER(e.sub_type) LIKE '%giving%' OR LOWER(e.sub_type) LIKE '%charity%')
      AND e.start_actual_date <= p.current_year_start + INTERVAL '1 year' - INTERVAL '1 day'
      AND (e.end_projection_date >= p.current_year_start OR e.end_projection_date IS NULL)
    GROUP BY p.client_id
),
actual_giving AS (
    SELECT p.client_id, COALESCE(SUM(f.amount),0) AS actual_giving
    FROM params p
    LEFT JOIN core.flows f ON f.client_id = p.client_id
    WHERE (LOWER(f.fact_type_name) IN ('other expense','gift') AND (LOWER(f.sub_type) LIKE '%giving%' OR LOWER(f.sub_type) LIKE '%gift%'))
      AND f.amount_as_of >= p.current_year_start
      AND f.amount_as_of < p.current_year_start + INTERVAL '1 year'
    GROUP BY p.client_id
),

-- Living
annual_living AS (
    SELECT p.client_id, COALESCE(SUM(e.annual_amount),0) AS annual_living
    FROM params p
    LEFT JOIN core.expenses e ON e.client_id = p.client_id
    WHERE (LOWER(e.type) IN ('living','spending') AND LOWER(e.sub_type) NOT LIKE '%giving%')
      AND e.start_actual_date <= p.current_year_start + INTERVAL '1 year' - INTERVAL '1 day'
      AND (e.end_projection_date >= p.current_year_start OR e.end_projection_date IS NULL)
    GROUP BY p.client_id
),
actual_living AS (
    SELECT p.client_id, COALESCE(SUM(f.amount),0) AS actual_living
    FROM params p
    LEFT JOIN core.flows f ON f.client_id = p.client_id
    WHERE LOWER(f.fact_type_name) IN ('living expense','education expense','other expense')
      AND LOWER(f.sub_type) NOT LIKE '%giving%' AND LOWER(f.sub_type) NOT LIKE '%philanthropy%'
      AND f.amount_as_of >= p.current_year_start
      AND f.amount_as_of < p.current_year_start + INTERVAL '1 year'
    GROUP BY p.client_id
),

-- Taxes
annual_taxes AS (
    SELECT p.client_id, COALESCE(SUM(e.annual_amount),0) AS annual_taxes
    FROM params p
    LEFT JOIN core.expenses e ON e.client_id = p.client_id
    WHERE (LOWER(e.type) LIKE '%tax%' OR LOWER(e.sub_type) LIKE '%tax%')
      AND e.start_actual_date <= p.current_year_start + INTERVAL '1 year' - INTERVAL '1 day'
      AND (e.end_projection_date >= p.current_year_start OR e.end_projection_date IS NULL)
    GROUP BY p.client_id
),
actual_taxes AS (
    SELECT p.client_id, COALESCE(SUM(f.amount),0) AS actual_taxes
    FROM params p
    LEFT JOIN core.flows f ON f.client_id = p.client_id
    WHERE LOWER(f.fact_type_name) LIKE '%tax%'
      AND f.amount_as_of >= p.current_year_start
      AND f.amount_as_of < p.current_year_start + INTERVAL '1 year'
    GROUP BY p.client_id
),

-- Savings
annual_savings AS (
    SELECT p.client_id, COALESCE(SUM(e.annual_amount),0) AS annual_savings
    FROM params p
    LEFT JOIN core.expenses e ON e.client_id = p.client_id
    WHERE (LOWER(e.type) LIKE '%savings%' OR LOWER(e.sub_type) LIKE '%savings%')
      AND e.start_actual_date <= p.current_year_start + INTERVAL '1 year' - INTERVAL '1 day'
      AND (e.end_projection_date >= p.current_year_start OR e.end_projection_date IS NULL)
    GROUP BY p.client_id
),
annual_savings_savingstable AS (
    SELECT p.client_id, COALESCE(SUM(s.fixed_amount_usd),0) AS annual_savings_savingstable
    FROM params p
    LEFT JOIN core.savings s ON s.client_id = p.client_id
    WHERE s.start_type = 'Active'
    GROUP BY p.client_id
),
actual_savings AS (
    SELECT p.client_id, COALESCE(SUM(f.amount),0) AS actual_savings
    FROM params p
    LEFT JOIN core.flows f ON f.client_id = p.client_id
    WHERE LOWER(f.fact_type_name) LIKE '%savings%'
      AND f.amount_as_of >= p.current_year_start
      AND f.amount_as_of < p.current_year_start + INTERVAL '1 year'
    GROUP BY p.client_id
),

-- Debt
annual_debt AS (
    SELECT p.client_id, COALESCE(SUM(e.annual_amount),0) AS annual_debt
    FROM params p
    LEFT JOIN core.expenses e ON e.client_id = p.client_id
    WHERE (
            LOWER(e.type) LIKE ANY (ARRAY['%loan%','%debt%','%mortgage%','%credit%'])
         OR LOWER(e.sub_type) LIKE ANY (ARRAY['%loan%','%debt%','%mortgage%','%credit%'])
          )
      AND e.start_actual_date <= p.current_year_start + INTERVAL '1 year' - INTERVAL '1 day'
      AND (e.end_projection_date >= p.current_year_start OR e.end_projection_date IS NULL)
    GROUP BY p.client_id
),
actual_debt AS (
    SELECT p.client_id, COALESCE(SUM(f.amount),0) AS actual_debt
    FROM params p
    LEFT JOIN core.flows f ON f.client_id = p.client_id
    WHERE LOWER(f.fact_type_name) LIKE ANY (ARRAY['%loan%','%mortgage%','%credit%'])
      AND f.amount_as_of >= p.current_year_start
      AND f.amount_as_of < p.current_year_start + INTERVAL '1 year'
    GROUP BY p.client_id
),
liability AS (
    SELECT p.client_id,
           ABS(COALESCE(SUM(l.total_value),0)) AS outstanding_debt,
           abs(COALESCE(SUM(
            CASE
                WHEN l.interest_rate IS NOT NULL AND l.interest_rate > 0 THEN
                    l.total_value * (l.interest_rate / 12) 
                    * POWER(1 + l.interest_rate / 12, l.loan_term_in_years * 12) /
                      (POWER(1 + l.interest_rate / 12, l.loan_term_in_years * 12) - 1) * 12
                WHEN l.loan_term_in_years IS NOT NULL AND l.loan_term_in_years > 0 THEN
                    l.total_value / l.loan_term_in_years
                ELSE 0
            END
        ), 0))::NUMERIC(18,2) AS annual_debt_payment
    FROM params p
    LEFT JOIN core.liability_note_accounts l ON l.client_id = p.client_id
    GROUP BY p.client_id
)

-- Final consolidated output
SELECT
    p.client_id,
    -- Giving
    COALESCE(pg.annual_giving,0) AS annual_giving,
    COALESCE(ag.actual_giving,0) AS actual_giving,

-- Living
    COALESCE(pl.annual_living,0) AS annual_living,
    COALESCE(al.actual_living,0) AS actual_living,

    -- Taxes
    COALESCE(pt.annual_taxes,0) AS annual_taxes,
    COALESCE(at.actual_taxes,0) AS actual_taxes,

    -- Savings
    COALESCE(ps.annual_savings,0) AS annual_savings,
	COALESCE(ps_tab.annual_savings_savingstable,0) AS annual_savings_savingstable,
    COALESCE(asv.actual_savings,0) AS actual_savings,

    -- Debt
    COALESCE(pd.annual_debt,0) AS annual_debt,
    COALESCE(ad.actual_debt,0) AS actual_debt,
    COALESCE(lia.outstanding_debt,0) AS outstanding_debt,
    COALESCE(lia.annual_debt_payment,0) AS annual_debt_payment,

    -- Totals
    (COALESCE(pg.annual_giving,0) + COALESCE(pl.annual_living,0) + COALESCE(pt.annual_taxes,0) +
     COALESCE(ps_tab.annual_savings_savingstable,0) + ABS(COALESCE(lia.annual_debt_payment,0))) AS projected_total_expenses,

    (COALESCE(ag.actual_giving,0) + COALESCE(al.actual_living,0) + COALESCE(at.actual_taxes,0) +
     COALESCE(asv.actual_savings,0) + ABS(COALESCE(ad.actual_debt,0))) AS actual_total_expenses

FROM params p
LEFT JOIN annual_giving pg ON p.client_id = pg.client_id
LEFT JOIN actual_giving ag ON p.client_id = ag.client_id
LEFT JOIN annual_living pl ON p.client_id = pl.client_id
LEFT JOIN actual_living al ON p.client_id = al.client_id
LEFT JOIN annual_taxes pt ON p.client_id = pt.client_id
LEFT JOIN actual_taxes at ON p.client_id = at.client_id
LEFT JOIN annual_savings ps ON p.client_id = ps.client_id
LEFT JOIN annual_savings_savingstable ps_tab ON p.client_id = ps_tab.client_id
LEFT JOIN actual_savings asv ON p.client_id = asv.client_id
LEFT JOIN annual_debt pd ON p.client_id = pd.client_id
LEFT JOIN actual_debt ad ON p.client_id = ad.client_id
LEFT JOIN liability lia ON p.client_id = lia.client_id;
