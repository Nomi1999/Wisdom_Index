-- Net Worth metric
WITH assets AS (
    -- Calculate total assets from various sources
    SELECT 
        COALESCE(SUM(value), 0) AS total_value
    FROM core.holdings 
    WHERE client_id = 1
    
    UNION ALL
    
    SELECT 
        COALESCE(SUM(total_value), 0)
    FROM core.real_estate_assets 
    WHERE client_id = 1
    
    UNION ALL
    
    SELECT 
        COALESCE(SUM(amount), 0)
    FROM core.businesses 
    WHERE client_id = 1
    
    UNION ALL
    
    SELECT 
        COALESCE(SUM(total_value), 0)
    FROM core.investment_deposit_accounts 
    WHERE client_id = 1
    
    UNION ALL
    
    SELECT 
        COALESCE(SUM(total_value), 0)
    FROM core.personal_property_accounts 
    WHERE client_id = 1
),
liabilities AS (
    -- Calculate total liabilities (using ABS for negative values)
    SELECT 
        COALESCE(SUM(ABS(total_value)), 0) AS total_liabilities
    FROM core.liability_note_accounts 
    WHERE client_id = 1
),
asset_summary AS (
    -- Sum all assets
    SELECT SUM(total_value) AS total_assets
    FROM assets
)
-- Final net worth calculation
SELECT 
    total_assets - total_liabilities AS net_worth
FROM asset_summary, liabilities;

--Portfolio metric
WITH portfolio_components AS (
    -- Holdings (stocks, bonds, ETFs, mutual funds)
    SELECT COALESCE(SUM(value), 0) AS portfolio_value
    FROM core.holdings 
    WHERE client_id = 1
    
    UNION ALL
    
    -- Investment deposit accounts (401k, Roth, taxable, checking)
    SELECT COALESCE(SUM(total_value), 0)
    FROM core.investment_deposit_accounts 
    WHERE client_id = 1
)
SELECT SUM(portfolio_value) AS total_portfolio_value
FROM portfolio_components;

-- REAL ESTATE meric
SELECT 
	COALESCE((SELECT SUM(COALESCE(total_value,0)) 
FROM core.real_estate_assets 
WHERE client_id = 1),0)::numeric AS metric_value;

-- Debt metric
SELECT
ABS(COALESCE((SELECT SUM(COALESCE(total_value, 0))
FROM core.liability_note_accounts
WHERE client_id = 1),0))::numeric AS metric_value;

--Equity metric
WITH equity_holdings AS (
    SELECT 
        client_id,
        COALESCE(SUM(value),0) as equity_holdings_value
    FROM core.holdings 
    WHERE asset_class IN ('largecap', 'smallcap', 'largevalue', 'smallvalue', 'internat', 'emerging', 'ips') -- Filters for equity asset classes: largecap, smallcap, largevalue, smallvalue, internat, emerging, ips
        AND client_id = 1
        AND value IS NOT NULL
    GROUP BY client_id
),
investment_equity AS (
    SELECT 
        client_id,
        COALESCE(SUM(holdings_value),0) as investment_equity_value
    FROM core.investment_deposit_accounts 
    WHERE fact_type_name IN ('Taxable Investment', 'Roth IRA', 'Qualified Retirement') -- Filters for investment account types: Taxable Investment, Roth IRA, Qualified Retirement
        AND client_id = 1
        AND holdings_value IS NOT NULL
    GROUP BY client_id
)

SELECT 
    (COALESCE(eh.equity_holdings_value, 0) + COALESCE(ie.investment_equity_value, 0)) as total_equity
FROM equity_holdings eh
FULL OUTER JOIN investment_equity ie ON eh.client_id = ie.client_id;

-- Fixed (Sum of fixed income values in the portfolio)
SELECT 
    COALESCE(SUM(value),0) as fixed_income_total
FROM core.holdings 
WHERE asset_class IN ('highyldbond', 'inttermmun', 'investbond', 'shortermbond', 'shortermmun')
    AND client_id = 1;

--Cash metric
WITH holdings_cash AS (
    SELECT 
        client_id,
        SUM(CASE WHEN asset_class = 'cash' THEN value ELSE 0 END) as cash_from_holdings
    FROM core.holdings 
    WHERE asset_class = 'cash' AND value IS NOT NULL
	AND client_id = 1
    GROUP BY client_id
),
investment_cash AS (
    SELECT 
        client_id,
        SUM(COALESCE(cash_balance, 0)) as cash_from_investments
    FROM core.investment_deposit_accounts 
    WHERE fact_type_name = 'Cash Alternative' 
        AND cash_balance IS NOT NULL
		AND client_id = 1
    GROUP BY client_id
)

SELECT 
    COALESCE(h.cash_from_holdings, 0) + COALESCE(i.cash_from_investments, 0) as total_cash
FROM holdings_cash h
FULL OUTER JOIN investment_cash i ON h.client_id = i.client_id;

--Income Metrics

--Earned Income
SELECT 
    COALESCE(SUM(current_year_amount),0) as earned_income
FROM core.incomes 
WHERE income_type IN ('Salary')
    AND client_id = 1;

--Social Security Income
SELECT 
    COALESCE(SUM(current_year_amount),0) as social_income
FROM core.incomes 
WHERE income_type IN ('SocialSecurity')
    AND client_id = 1;

--Pension Income
SELECT 
    COALESCE(SUM(current_year_amount),0) as pension_income
FROM core.incomes 
WHERE income_type IN ('Pension') -- No pension income_type currently in the data
    AND client_id = 1;

--Real Estate Income
SELECT 
    COALESCE(SUM(current_year_amount),0) as pension_income
FROM core.incomes 
WHERE income_type IN ('Real Estate') -- No Real Estate income_type currently in the data
    AND client_id = 1;

--Business Income
SELECT 
    COALESCE(SUM(current_year_amount),0) as business_income
FROM core.incomes 
WHERE income_type IN ('Business') -- No Business income_type currently in the data
    AND client_id = 1;

--Expense Metrics

--Giving expense ("SUM of all Current Year Giving" by identifying giving expenses that are active during the current year.)
SELECT 
    COALESCE(SUM(annual_amount), 0) AS current_year_giving
FROM core.expenses 
WHERE client_id = 1
    AND type = 'Spending' 
    AND sub_type = 'GivingAndPhilanthropy'
    AND annual_amount > 0
    -- Check if expense overlaps with current year
    AND EXTRACT(YEAR FROM start_actual_date) <= EXTRACT(YEAR FROM CURRENT_DATE)
    AND (end_actual_date IS NULL OR EXTRACT(YEAR FROM end_actual_date) >= EXTRACT(YEAR FROM CURRENT_DATE));

--Savings expense
SELECT 
    COALESCE(SUM(calculated_annual_amount_usd),0) as current_year_savings
FROM core.savings 
WHERE start_type = 'Active'  -- Only include currently active savings plans
  AND client_id = 1;  -- Filter for specific client (replace with actual client ID)

--Debt expense
WITH active_debts AS (
    -- Calculate annual debt payments for all active loans
    SELECT 
        client_id,
        account_name,
        total_value,
        interest_rate,
        loan_term_in_years,
        payment_frequency,
        loan_date,
        -- Calculate annual payment using amortization formula or simplified estimate
        CASE 
          WHEN interest_rate IS NOT NULL AND loan_term_in_years IS NOT NULL THEN
            -- Standard amortization: monthly payment * 12
            ABS(total_value) * (interest_rate / 12) / 
            (1 - POWER(1 + (interest_rate / 12), -loan_term_in_years * 12)) * 12
          ELSE
            -- For loans missing rate/term, assume 12-month repayment
            ABS(total_value) / 12
        END as annual_payment
    FROM core.liability_note_accounts 
    WHERE client_id = 1  -- Filter for specific client
      AND total_value < 0  -- Only include actual debt (negative values)
      AND repayment_type = 'PrincipalAndInterest'  -- Only active debt being serviced
      -- DYNAMIC CURRENT YEAR LOGIC:
      AND EXTRACT(YEAR FROM loan_date) <= EXTRACT(YEAR FROM CURRENT_DATE)  -- Loan originated before or in current year
      AND (loan_term_in_years IS NULL OR 
           EXTRACT(YEAR FROM loan_date) + loan_term_in_years >= EXTRACT(YEAR FROM CURRENT_DATE))  -- Still active in current year
)
SELECT 
    ROUND(SUM(annual_payment),2) as current_year_debt
FROM active_debts;

--Tax expense
SELECT 
    ROUND(COALESCE(SUM(current_year_amount), 0) * 0.15, 2) as current_year_taxes
FROM core.incomes 
WHERE client_id = 1  -- Filter for specific client
  AND current_year_amount IS NOT NULL;

--Living Expense ( "SUM of all Current Year Living Expenses" by identifying living expenses that are active during the current year)
SELECT 
    COALESCE(SUM(annual_amount), 0) AS current_year_living_expenses
FROM core.expenses 
WHERE client_id = 1
    AND type = 'Living' 
    AND annual_amount > 0
    -- Check if expense overlaps with current year
    AND EXTRACT(YEAR FROM start_actual_date) <= EXTRACT(YEAR FROM CURRENT_DATE)
    AND (end_actual_date IS NULL OR EXTRACT(YEAR FROM end_actual_date) >= EXTRACT(YEAR FROM CURRENT_DATE))
    -- Ensure logical date ranges
    AND (end_actual_date IS NULL OR end_actual_date >= start_actual_date);

-- Total expenses (Sum of Giving, Savings, Debt, Taxes, Living) for a specific client
WITH 
-- Giving Expense
giving_expense AS (
    SELECT 
        COALESCE(SUM(annual_amount), 0) AS current_year_giving
    FROM core.expenses 
    WHERE client_id = 1
        AND type = 'Spending' 
        AND sub_type = 'GivingAndPhilanthropy'
        AND annual_amount > 0
        -- Check if expense overlaps with current year
        AND EXTRACT(YEAR FROM start_actual_date) <= EXTRACT(YEAR FROM CURRENT_DATE)
        AND (end_actual_date IS NULL OR EXTRACT(YEAR FROM end_actual_date) >= EXTRACT(YEAR FROM CURRENT_DATE))
),

-- Savings Expense
savings_expense AS (
    SELECT 
        COALESCE(SUM(calculated_annual_amount_usd), 0) as current_year_savings
    FROM core.savings 
    WHERE start_type = 'Active'
      AND client_id = 1
),

-- Debt Expense
debt_expense AS (
    WITH active_debts AS (
        SELECT 
            client_id,
            CASE 
              WHEN interest_rate IS NOT NULL AND loan_term_in_years IS NOT NULL THEN
                ABS(total_value) * (interest_rate / 12) / 
                (1 - POWER(1 + (interest_rate / 12), -loan_term_in_years * 12)) * 12
              ELSE
                ABS(total_value) / 12
            END as annual_payment
        FROM core.liability_note_accounts 
        WHERE client_id = 1
          AND total_value < 0
          AND repayment_type = 'PrincipalAndInterest'
          AND EXTRACT(YEAR FROM loan_date) <= EXTRACT(YEAR FROM CURRENT_DATE)
          AND (loan_term_in_years IS NULL OR 
               EXTRACT(YEAR FROM loan_date) + loan_term_in_years >= EXTRACT(YEAR FROM CURRENT_DATE))
    )
    SELECT 
        COALESCE(SUM(annual_payment), 0) as current_year_debt
    FROM active_debts
),

-- Tax Expense
tax_expense AS (
    SELECT 
        ROUND(COALESCE(SUM(current_year_amount), 0) * 0.15, 2) as current_year_taxes
    FROM core.incomes 
    WHERE client_id = 1
      AND current_year_amount IS NOT NULL
),

-- Living Expense
living_expense AS (
    SELECT 
        COALESCE(SUM(annual_amount), 0) AS current_year_living_expenses
    FROM core.expenses 
    WHERE client_id = 1
        AND type = 'Living' 
        AND annual_amount > 0
        -- Check if expense overlaps with current year
        AND EXTRACT(YEAR FROM start_actual_date) <= EXTRACT(YEAR FROM CURRENT_DATE)
        AND (end_actual_date IS NULL OR EXTRACT(YEAR FROM end_actual_date) >= EXTRACT(YEAR FROM CURRENT_DATE))
        -- Ensure logical date ranges
        AND (end_actual_date IS NULL OR end_actual_date >= start_actual_date)
)

-- Final Total Expense Calculation
SELECT 
-- Total Expense = Sum of all components
    ROUND((COALESCE(g.current_year_giving, 0) + 
     COALESCE(s.current_year_savings, 0) + 
     COALESCE(d.current_year_debt, 0) + 
     COALESCE(t.current_year_taxes, 0) + 
     COALESCE(l.current_year_living_expenses, 0)),2) as total_expense
FROM giving_expense g, savings_expense s, debt_expense d, tax_expense t, living_expense l;

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
AND client_id = 1;


--LTC (Sum of all Long-term care insurance)
SELECT 
    COALESCE(SUM(benefit_amount),0) as ltc_metric
FROM core.disability_ltc_insurance_accounts 
WHERE sub_type = 'PersonalLT' 
AND client_id = 1;


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
AND client_id = 1;


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
