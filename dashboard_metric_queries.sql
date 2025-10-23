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




