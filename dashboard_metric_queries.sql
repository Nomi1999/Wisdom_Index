-- 1. Net Worth metric
WITH assets AS (
    -- Calculate total assets from various sources
    SELECT 
        COALESCE(SUM(value), 0) AS total_value
    FROM core.holdings 
    WHERE client_id = {{client_id}}
    
    UNION ALL
    
    SELECT 
        COALESCE(SUM(total_value), 0)
    FROM core.real_estate_assets 
    WHERE client_id = {{client_id}}
    
    UNION ALL
    
    SELECT 
        COALESCE(SUM(amount), 0)
    FROM core.businesses 
    WHERE client_id = {{client_id}}
    
    UNION ALL
    
    SELECT 
        COALESCE(SUM(total_value), 0)
    FROM core.investment_deposit_accounts 
    WHERE client_id = {{client_id}}
    
    UNION ALL
    
    SELECT 
        COALESCE(SUM(total_value), 0)
    FROM core.personal_property_accounts 
    WHERE client_id = {{client_id}}
),
liabilities AS (
    -- Calculate total liabilities (using ABS for negative values)
    SELECT 
        COALESCE(SUM(ABS(total_value)), 0) AS total_liabilities
    FROM core.liability_note_accounts 
    WHERE client_id = {{client_id}}
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

--2. Portfolio metric
WITH portfolio_components AS (
    -- Holdings 
    SELECT COALESCE(SUM(value), 0) AS portfolio_value
    FROM core.holdings 
    WHERE client_id = {{client_id}}
    
    UNION ALL
    
    -- Investment deposit accounts 
    SELECT COALESCE(SUM(total_value), 0)
    FROM core.investment_deposit_accounts 
    WHERE client_id = {{client_id}}
)
SELECT SUM(portfolio_value) AS total_portfolio_value
FROM portfolio_components;

-- 3. REAL ESTATE meric
SELECT 
	COALESCE(SUM(total_value),0) as real_estate_value 
FROM core.real_estate_assets
WHERE client_id = {{client_id}}; 


-- 4. Debt metric
SELECT
ABS(COALESCE(SUM(total_value),0))
FROM core.liability_note_accounts
WHERE client_id = {{client_id}};

--5. Equity metric
WITH equity_holdings AS (
    SELECT 
        client_id,
        COALESCE(SUM(value),0) as equity_holdings_value
    FROM core.holdings 
    WHERE asset_class IN ('largecap', 'smallcap', 'largevalue', 'smallvalue', 'internat', 'emerging', 'ips') -- Filters for equity asset classes: largecap, smallcap, largevalue, smallvalue, internat, emerging, ips
        AND client_id = {{client_id}}
        AND value IS NOT NULL
    GROUP BY client_id
),
investment_equity AS (
    SELECT 
        client_id,
        COALESCE(SUM(holdings_value),0) as investment_equity_value
    FROM core.investment_deposit_accounts 
    WHERE fact_type_name IN ('Taxable Investment', 'Roth IRA', 'Qualified Retirement') -- Filters for investment account types: Taxable Investment, Roth IRA, Qualified Retirement
        AND client_id = {{client_id}}
        AND holdings_value IS NOT NULL
    GROUP BY client_id
)

SELECT 
    (COALESCE(eh.equity_holdings_value, 0) + COALESCE(ie.investment_equity_value, 0)) as total_equity
FROM equity_holdings eh
FULL OUTER JOIN investment_equity ie ON eh.client_id = ie.client_id;

-- 6. Fixed (Sum of fixed income values in the portfolio)
SELECT 
    COALESCE(SUM(value),0) as fixed_income_total
FROM core.holdings 
WHERE asset_class IN ('highyldbond', 'inttermmun', 'investbond', 'shortermbond', 'shortermmun')
    AND client_id = {{client_id}};

--7. Cash metric
WITH holdings_cash AS (
    SELECT 
        client_id,
        SUM(CASE WHEN asset_class = 'cash' THEN value ELSE 0 END) as cash_from_holdings
    FROM core.holdings 
    WHERE asset_class = 'cash' AND value IS NOT NULL
	AND client_id = {{client_id}}
    GROUP BY client_id
),
investment_cash AS (
    SELECT 
        client_id,
        SUM(COALESCE(cash_balance, 0)) as cash_from_investments
    FROM core.investment_deposit_accounts 
    WHERE fact_type_name = 'Cash Alternative' 
        AND cash_balance IS NOT NULL
		AND client_id = {{client_id}}
    GROUP BY client_id
)

SELECT 
    COALESCE(h.cash_from_holdings, 0) + COALESCE(i.cash_from_investments, 0) as total_cash
FROM holdings_cash h
FULL OUTER JOIN investment_cash i ON h.client_id = i.client_id;

--Income Metrics

--8. Earned Income
SELECT 
    COALESCE(SUM(current_year_amount),0) as earned_income
FROM core.incomes 
WHERE income_type IN ('Salary')
    AND client_id = {{client_id}};

--9. Social Security Income
SELECT 
    COALESCE(SUM(current_year_amount),0) as social_income
FROM core.incomes 
WHERE income_type IN ('SocialSecurity')
    AND client_id = {{client_id}};

--10. Pension Income
SELECT 
    COALESCE(SUM(current_year_amount),0) as pension_income
FROM core.incomes 
WHERE income_type IN ('Pension') -- No pension income_type currently in the data
    AND client_id = {{client_id}};

--11. Real Estate Income
SELECT 
    COALESCE(SUM(current_year_amount),0) as real_estate_income
FROM core.incomes 
WHERE income_type IN ('Real Estate') -- No Real Estate income_type currently in the data
    AND client_id = {{client_id}};

--12. Business Income
SELECT 
    COALESCE(SUM(current_year_amount),0) as business_income
FROM core.incomes 
WHERE income_type IN ('Business') -- No Business income_type currently in the data
    AND client_id = {{client_id}};

--13. Total Income (Sum of all income types) for a specific client
WITH income_breakdown AS (
    SELECT 
        client_id,
        -- Earned Income
        COALESCE(SUM(CASE WHEN income_type = 'Salary' THEN current_year_amount ELSE 0 END), 0) as earned_income,
        -- Social Income  
        COALESCE(SUM(CASE WHEN income_type = 'SocialSecurity' THEN current_year_amount ELSE 0 END), 0) as social_income,
        -- Pension Income (no data exists but included for completeness)
        COALESCE(SUM(CASE WHEN income_type = 'Pension' THEN current_year_amount ELSE 0 END), 0) as pension_income,
        -- Real Estate Income (no data exists but included for completeness)
        COALESCE(SUM(CASE WHEN income_type = 'Real Estate' THEN current_year_amount ELSE 0 END), 0) as real_estate_income,
        -- Business Income (no data exists but included for completeness)
        COALESCE(SUM(CASE WHEN income_type = 'Business' THEN current_year_amount ELSE 0 END), 0) as business_income,
        -- Other Income (exists as 'Other Income' in database)
        COALESCE(SUM(CASE WHEN income_type = 'Other' THEN current_year_amount ELSE 0 END), 0) as other_income,
        -- Total Income = Sum of all components
        COALESCE(SUM(current_year_amount), 0) as total_income
    FROM core.incomes 
    WHERE client_id = {{client_id}}  -- Filter for specific client
      AND current_year_amount IS NOT NULL
    GROUP BY client_id
)
SELECT 
    total_income
FROM income_breakdown;

--Expense Metrics

--14. Giving expense ("SUM of all Current Year Giving" by identifying giving expenses that are active during the current year.)
SELECT 
    COALESCE(SUM(annual_amount), 0) AS current_year_giving
FROM core.expenses 
WHERE client_id = {{client_id}}
    AND type = 'Spending' 
    AND sub_type = 'GivingAndPhilanthropy'
    AND annual_amount > 0
    -- Check if expense overlaps with current year
    AND EXTRACT(YEAR FROM start_actual_date) <= EXTRACT(YEAR FROM CURRENT_DATE)
    AND (end_actual_date IS NULL OR EXTRACT(YEAR FROM end_actual_date) >= EXTRACT(YEAR FROM CURRENT_DATE));

--15. Savings expense
SELECT 
    COALESCE(SUM(calculated_annual_amount_usd),0) as current_year_savings
FROM core.savings 
WHERE start_type = 'Active'  -- Only include currently active savings plans
  AND client_id = {{client_id}};  -- Filter for specific client (replace with actual client ID)

--16. Debt expense
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
    WHERE client_id = {{client_id}}  -- Filter for specific client
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

--17. Tax expense
SELECT 
    ROUND(COALESCE(SUM(current_year_amount), 0) * 0.15, 2) as current_year_taxes
FROM core.incomes 
WHERE client_id = {{client_id}}  -- Filter for specific client
  AND current_year_amount IS NOT NULL;

--18. Living Expense ( "SUM of all Current Year Living Expenses" by identifying living expenses that are active during the current year)
SELECT 
    COALESCE(SUM(annual_amount), 0) AS current_year_living_expenses
FROM core.expenses 
WHERE client_id = {{client_id}}
    AND type = 'Living' 
    AND annual_amount > 0
    -- Check if expense overlaps with current year
    AND EXTRACT(YEAR FROM start_actual_date) <= EXTRACT(YEAR FROM CURRENT_DATE)
    AND (end_actual_date IS NULL OR EXTRACT(YEAR FROM end_actual_date) >= EXTRACT(YEAR FROM CURRENT_DATE))
    -- Ensure logical date ranges
    AND (end_actual_date IS NULL OR end_actual_date >= start_actual_date);

-- 19. Total expenses (Sum of Giving, Savings, Debt, Taxes, Living) for a specific client
WITH 
-- Giving Expense
giving_expense AS (
    SELECT 
        COALESCE(SUM(annual_amount), 0) AS current_year_giving
    FROM core.expenses 
    WHERE client_id = {{client_id}}
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
      AND client_id = {{client_id}}
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
        WHERE client_id = {{client_id}}
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
    WHERE client_id = {{client_id}}
      AND current_year_amount IS NOT NULL
),

-- Living Expense
living_expense AS (
    SELECT 
        COALESCE(SUM(annual_amount), 0) AS current_year_living_expenses
    FROM core.expenses 
    WHERE client_id = {{client_id}}
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

--20. Margin Metric (Total Income - Total Expenses) for a specific client
WITH 
-- Total Income Calculation
income_breakdown AS (
    SELECT 
        client_id,
        COALESCE(SUM(current_year_amount), 0) as total_income
    FROM core.incomes 
    WHERE client_id = {{client_id}}  -- Filter for specific client
      AND current_year_amount IS NOT NULL
    GROUP BY client_id
),

-- Giving Expense
giving_expense AS (
    SELECT 
        COALESCE(SUM(annual_amount), 0) AS current_year_giving
    FROM core.expenses 
    WHERE client_id = {{client_id}}
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
      AND client_id = {{client_id}}
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
        WHERE client_id = {{client_id}}
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
    WHERE client_id = {{client_id}}
      AND current_year_amount IS NOT NULL
),

-- Living Expense
living_expense AS (
    SELECT 
        COALESCE(SUM(annual_amount), 0) AS current_year_living_expenses
    FROM core.expenses 
    WHERE client_id = {{client_id}}
        AND type = 'Living' 
        AND annual_amount > 0
        -- Check if expense overlaps with current year
        AND EXTRACT(YEAR FROM start_actual_date) <= EXTRACT(YEAR FROM CURRENT_DATE)
        AND (end_actual_date IS NULL OR EXTRACT(YEAR FROM end_actual_date) >= EXTRACT(YEAR FROM CURRENT_DATE))
        -- Ensure logical date ranges
        AND (end_actual_date IS NULL OR end_actual_date >= start_actual_date)
),

-- Total Expense Calculation
total_expense_calc AS (
    SELECT 
        ROUND((COALESCE(g.current_year_giving, 0) + 
               COALESCE(s.current_year_savings, 0) + 
               COALESCE(d.current_year_debt, 0) + 
               COALESCE(t.current_year_taxes, 0) + 
               COALESCE(l.current_year_living_expenses, 0)), 2) as total_expense
    FROM giving_expense g, savings_expense s, debt_expense d, tax_expense t, living_expense l
)

-- Final Margin Calculation (Total Income - Total Expenses)
SELECT 
    -- Margin = Total Income - Total Expenses, rounded to 2 decimal places
    ROUND((COALESCE(i.total_income, 0) - COALESCE(e.total_expense, 0)), 2) as margin
FROM income_breakdown i, total_expense_calc e;


--Insurance Metrics

--21. Life Insurance (Sum of all life insurance)
SELECT 
    COALESCE(SUM(death_benefit), 0) as life_insurance_metric
FROM core.life_insurance_annuity_accounts 
WHERE fact_type_name = 'Life Insurance' 
AND client_id = {{client_id}};


--22. Disability (Sum of all disability insurance)
SELECT COALESCE(SUM(benefit_amount), 0) as disability_metric
FROM core.disability_ltc_insurance_accounts 
WHERE fact_type_name IN ('Disability Policy', 'Business Disability Policy')
AND client_id = {{client_id}};


--23. LTC (Sum of all Long-term care insurance)
SELECT 
    COALESCE(SUM(benefit_amount),0) as ltc_metric
FROM core.disability_ltc_insurance_accounts 
WHERE sub_type = 'PersonalLT' 
AND client_id = {{client_id}};


--24. Umbrella (Sum of all Umbrella insurance)
SELECT 
    COALESCE(SUM(maximum_annual_benefit),0) as umbrella_metric
FROM core.property_casualty_insurance_accounts 
WHERE sub_type = 'Umbrella' 
AND client_id = {{client_id}};


-- 25. Business (Sum of all Business Insurance)
SELECT 
    COALESCE(SUM(benefit_amount), 0) AS business_insurance
FROM core.disability_ltc_insurance_accounts 
WHERE sub_type = 'BusinessReducingTerm'
AND client_id = {{client_id}};


-- 26. Flood Insurance (Sum of all flood insurance)
SELECT 
    COALESCE(SUM(maximum_annual_benefit), 0) as flood_insurance_metric
FROM core.property_casualty_insurance_accounts 
WHERE sub_type = 'Flood'
AND client_id = {{client_id}};


-- 27. At Risk (Sum of all taxable investmetns - umbrella insurance)
WITH taxable AS (
    SELECT COALESCE(SUM(total_value), 0) AS taxable_investments_usd
    FROM core.investment_deposit_accounts
    WHERE client_id = {{client_id}}
      AND fact_type_name = 'Taxable Investment'   -- excludes IRA, 401k, 529 etc.
),
umbrella AS (
    SELECT COALESCE(SUM(maximum_annual_benefit), 0) AS umbrella_coverage_usd
    FROM core.property_casualty_insurance_accounts
    WHERE client_id = {{client_id}}
      AND sub_type = 'Umbrella'
)
SELECT (taxable.taxable_investments_usd - umbrella.umbrella_coverage_usd) AS at_risk_usd
FROM taxable, umbrella;

--Future Planning Metric

-- Retirement Ratio (Corrected Version)
WITH 
-- Get client information and calculate current age
client_info AS (
    SELECT 
        c.client_id,
        EXTRACT(YEAR FROM AGE(CURRENT_DATE, c.hh_date_of_birth)) AS current_age,
        65 AS retirement_age
    FROM core.clients c
    WHERE c.client_id = {{client_id}}
),

-- Calculate present value of future income streams
future_income_pv AS (
    SELECT 
        i.client_id,
        SUM(
            CASE 
                -- Income that continues into retirement years
                WHEN (ci.retirement_age - ci.current_age) > 0 AND
                     (i.end_type IS NULL OR 
                      i.end_type != 'Age' OR
                      (i.end_type = 'Age' AND i.end_value > ci.retirement_age))
                THEN i.annual_amount * 
                     (1 - POWER(1.0/1.04, GREATEST(0, ci.retirement_age - ci.current_age))) / 0.04
                ELSE 0
            END
        ) AS pv_future_income
    FROM core.incomes i
    JOIN client_info ci ON i.client_id = ci.client_id
    WHERE i.deleted IS NULL OR i.deleted = false
    GROUP BY i.client_id
),

-- Calculate present value of future expenses
future_expenses_pv AS (
    SELECT 
        e.client_id,
        SUM(
            CASE 
                -- Expenses that continue into retirement years
                WHEN (ci.retirement_age - ci.current_age) > 0 AND
                     (e.end_type IS NULL OR 
                      e.end_type != 'Age' OR
                      (e.end_type = 'Age' AND 
                       EXTRACT(YEAR FROM AGE(e.end_actual_date, e.start_actual_date)) > (ci.retirement_age - ci.current_age)))
                THEN e.annual_amount * 
                     (1 - POWER(1.0/1.04, GREATEST(0, ci.retirement_age - ci.current_age))) / 0.04
                ELSE 0
            END
        ) AS pv_future_expenses
    FROM core.expenses e
    JOIN client_info ci ON e.client_id = ci.client_id
    GROUP BY e.client_id
),

-- Current assets (excluding retirement savings)
current_assets AS (
    SELECT 
        client_id,
        SUM(total_value) AS current_assets
    FROM (
        SELECT client_id, total_value FROM core.investment_deposit_accounts
        UNION ALL
        SELECT client_id, total_value FROM core.real_estate_assets  
        UNION ALL
        SELECT client_id, total_value FROM core.personal_property_accounts
    ) all_assets
    GROUP BY client_id
),

-- Retirement-specific savings
retirement_savings AS (
    SELECT 
        client_id,
        SUM(COALESCE(calculated_annual_amount_usd, fixed_amount_usd)) AS retirement_savings
    FROM core.savings
    WHERE destination ILIKE '%retirement%' OR 
          destination ILIKE '%401k%' OR 
          destination ILIKE '%ira%' OR
          account_id ILIKE '%retirement%' OR
          account_id ILIKE '%401k%' OR
          account_id ILIKE '%ira%'
    GROUP BY client_id
),

-- Current liabilities
current_liabilities AS (
    SELECT 
        client_id,
        SUM(total_value) AS current_liabilities
    FROM core.liability_note_accounts
    GROUP BY client_id
)

-- Final retirement ratio calculation
SELECT 
    ROUND(
        (
            COALESCE(fi.pv_future_income, 0) + 
            COALESCE(ca.current_assets, 0) + 
            COALESCE(rs.retirement_savings, 0)
        ) / 
        NULLIF(
            (COALESCE(fe.pv_future_expenses, 0) + COALESCE(cl.current_liabilities, 0)),
            0
        ),
        2
    ) AS retirement_ratio
FROM client_info ci
LEFT JOIN future_income_pv fi ON ci.client_id = fi.client_id
LEFT JOIN future_expenses_pv fe ON ci.client_id = fe.client_id
LEFT JOIN current_assets ca ON ci.client_id = ca.client_id
LEFT JOIN retirement_savings rs ON ci.client_id = rs.client_id
LEFT JOIN current_liabilities cl ON ci.client_id = cl.client_id
WHERE ci.current_age < ci.retirement_age;


-- Survivor Ratio (Corrected Version)
WITH 
-- Get client information and calculate current age
client_info AS (
    SELECT 
        c.client_id,
        EXTRACT(YEAR FROM AGE(CURRENT_DATE, c.hh_date_of_birth)) AS current_age
    FROM core.clients c
    WHERE c.client_id = {{client_id}}
),

-- Calculate present value of future income streams (post-death scenario)
future_income_pv AS (
    SELECT 
        i.client_id,
        SUM(
            CASE 
                -- Income that continues after death (spouse income, survivor benefits, etc.)
                WHEN (i.end_type = 'SpousesDeath' OR i.owner_type = 'Spouse') AND
                     (i.end_value IS NULL OR i.end_value > EXTRACT(YEAR FROM CURRENT_DATE))
                THEN i.annual_amount * 
                     (1 - POWER(1.0/1.04, 20)) / 0.04  -- 20-year planning horizon
                ELSE 0
            END
        ) AS pv_future_income
    FROM core.incomes i
    JOIN client_info ci ON i.client_id = ci.client_id
    WHERE (i.deleted IS NULL OR i.deleted = false)
    GROUP BY i.client_id
),

-- Calculate present value of future expenses (post-death scenario)
future_expenses_pv AS (
    SELECT 
        e.client_id,
        SUM(
            CASE 
                -- Expenses that continue after death (ongoing living expenses, etc.)
                WHEN e.end_type != 'AtSecondDeath' AND
                     (e.end_actual_date IS NULL OR e.end_actual_date > CURRENT_DATE)
                THEN e.annual_amount * 
                     (1 - POWER(1.0/1.04, 20)) / 0.04  -- 20-year planning horizon
                ELSE 0
            END
        ) AS pv_future_expenses
    FROM core.expenses e
    JOIN client_info ci ON e.client_id = ci.client_id
    GROUP BY e.client_id  -- Fixed: was i.client_id, now e.client_id
),

-- Current assets
current_assets AS (
    SELECT 
        client_id,
        SUM(total_value) AS current_assets
    FROM (
        SELECT client_id, total_value FROM core.investment_deposit_accounts
        UNION ALL
        SELECT client_id, total_value FROM core.real_estate_assets  
        UNION ALL
        SELECT client_id, total_value FROM core.personal_property_accounts
    ) all_assets
    GROUP BY client_id
),

-- Life insurance death benefits
life_insurance AS (
    SELECT 
        client_id,
        SUM(death_benefit) AS life_insurance_value
    FROM core.life_insurance_annuity_accounts
    WHERE death_benefit IS NOT NULL AND death_benefit > 0
    GROUP BY client_id
),

-- Current liabilities (note: these are negative values in the data)
current_liabilities AS (
    SELECT 
        client_id,
        ABS(SUM(total_value)) AS current_liabilities  -- Convert to positive for calculation
    FROM core.liability_note_accounts
    GROUP BY client_id
)

-- Final survivor ratio calculation
SELECT 
    ROUND(
        (
            COALESCE(li.life_insurance_value, 0) +
            COALESCE(fi.pv_future_income, 0) + 
            COALESCE(ca.current_assets, 0)
        ) / 
        NULLIF(
            (COALESCE(fe.pv_future_expenses, 0) + COALESCE(cl.current_liabilities, 0)),
            0
        ),
        2
    ) AS survivor_ratio
FROM client_info ci
LEFT JOIN future_income_pv fi ON ci.client_id = fi.client_id
LEFT JOIN future_expenses_pv fe ON ci.client_id = fe.client_id
LEFT JOIN current_assets ca ON ci.client_id = ca.client_id
LEFT JOIN life_insurance li ON ci.client_id = li.client_id
LEFT JOIN current_liabilities cl ON ci.client_id = cl.client_id;


-- Education Ratio (Corrected Version)
WITH 
-- Get client information
client_info AS (
    SELECT 
        c.client_id
    FROM core.clients c
    WHERE c.client_id = {{client_id}}
),

-- Calculate present value of education savings (annual contributions)
education_savings_pv AS (
    SELECT 
        s.client_id,
        SUM(
            CASE 
                WHEN s.destination ILIKE '%education%'
                THEN COALESCE(s.calculated_annual_amount_usd, s.fixed_amount_usd) * 
                     (1 - POWER(1.0/1.04, 10)) / 0.04  -- 10-year education planning horizon
                ELSE 0
            END
        ) AS pv_education_savings
    FROM core.savings s
    JOIN client_info ci ON s.client_id = ci.client_id
    GROUP BY s.client_id
),

-- Current education account balances
education_accounts AS (
    SELECT 
        client_id,
        SUM(total_value) AS education_account_balances
    FROM (
        -- Investment accounts with education subtype
        SELECT client_id, total_value 
        FROM core.investment_deposit_accounts
        WHERE sub_type ILIKE '%education%'
        
        UNION ALL
        
        -- Personal property accounts (all included as they may contain education assets)
        SELECT client_id, total_value 
        FROM core.personal_property_accounts
    ) edu_accounts
    GROUP BY client_id
),

-- Calculate present value of future education expenses
education_expenses_pv AS (
    SELECT 
        e.client_id,
        SUM(
            CASE 
                WHEN e.type ILIKE '%education%' OR 
                     e.sub_type ILIKE '%education%' OR 
                     e.expense_item ILIKE '%education%'
                THEN e.annual_amount * 
                     (1 - POWER(1.0/1.04, 10)) / 0.04  -- 10-year education planning horizon
                ELSE 0
            END
        ) AS pv_education_expenses
    FROM core.expenses e
    JOIN client_info ci ON e.client_id = ci.client_id
    GROUP BY e.client_id
)

-- Final education ratio calculation
SELECT 
    ROUND(
        (
            COALESCE(es.pv_education_savings, 0) +
            COALESCE(ea.education_account_balances, 0)
        ) / 
        NULLIF(COALESCE(ee.pv_education_expenses, 0), 0),
        2
    ) AS education_ratio
FROM client_info ci
LEFT JOIN education_savings_pv es ON ci.client_id = es.client_id
LEFT JOIN education_accounts ea ON ci.client_id = ea.client_id
LEFT JOIN education_expenses_pv ee ON ci.client_id = ee.client_id;


-- New Cars Ratio (Corrected Version)
WITH 
-- Get client information
client_info AS (
    SELECT 
        c.client_id
    FROM core.clients c
    WHERE c.client_id = {{client_id}}
),

-- Current taxable account balances (investment accounts flagged as taxable)
taxable_accounts AS (
    SELECT 
        client_id,
        SUM(total_value) AS taxable_account_value
    FROM core.investment_deposit_accounts
    WHERE sub_type ILIKE '%taxable%' 
       OR account_name ILIKE '%taxable%'
       OR account_name ILIKE '%brokerage%'
    GROUP BY client_id
),

-- Calculate present value of taxable savings (annual contributions to taxable accounts)
taxable_savings_pv AS (
    SELECT 
        s.client_id,
        SUM(
            CASE 
                WHEN NOT (s.destination ILIKE '%retirement%' OR s.destination ILIKE '%education%')
                THEN COALESCE(s.calculated_annual_amount_usd, s.fixed_amount_usd) * 
                     (1 - POWER(1.0/1.04, 5)) / 0.04  -- 5-year car planning horizon
                ELSE 0
            END
        ) AS pv_taxable_savings
    FROM core.savings s
    JOIN client_info ci ON s.client_id = ci.client_id
    GROUP BY s.client_id
),

-- Calculate present value of future car expenses
car_expenses_pv AS (
    SELECT 
        e.client_id,
        SUM(
            CASE 
                WHEN e.expense_item ILIKE '%car%' OR 
                     e.expense_item ILIKE '%vehicle%' OR 
                     e.expense_item ILIKE '%auto%' OR
                     e.type ILIKE '%car%' OR 
                     e.type ILIKE '%vehicle%' OR 
                     e.type ILIKE '%auto%' OR
                     e.sub_type ILIKE '%car%' OR 
                     e.sub_type ILIKE '%vehicle%' OR 
                     e.sub_type ILIKE '%auto%'
                THEN e.annual_amount * 
                     (1 - POWER(1.0/1.04, 5)) / 0.04  -- 5-year car planning horizon
                ELSE 0
            END
        ) AS pv_car_expenses
    FROM core.expenses e
    JOIN client_info ci ON e.client_id = ci.client_id
    GROUP BY e.client_id
)

-- Final new cars ratio calculation
SELECT 
    ROUND(
        (
            COALESCE(ta.taxable_account_value, 0) + 
            COALESCE(ts.pv_taxable_savings, 0)
        ) / 
        NULLIF(COALESCE(ce.pv_car_expenses, 0), 0),
        2
    ) AS new_cars_ratio
FROM client_info ci
LEFT JOIN taxable_accounts ta ON ci.client_id = ta.client_id
LEFT JOIN taxable_savings_pv ts ON ci.client_id = ts.client_id
LEFT JOIN car_expenses_pv ce ON ci.client_id = ce.client_id;


-- LTC Ratio (Corrected Version)
WITH 
-- Get client information
client_info AS (
    SELECT 
        c.client_id
    FROM core.clients c
    WHERE c.client_id = {{client_id}}
),

-- Calculate present value of all future income streams
future_income_pv AS (
    SELECT 
        i.client_id,
        SUM(
            CASE 
                WHEN (i.deleted IS NULL OR i.deleted = false)
                THEN i.annual_amount * 
                     (1 - POWER(1.0/1.04, 20)) / 0.04  -- 20-year planning horizon for LTC
                ELSE 0
            END
        ) AS pv_future_income
    FROM core.incomes i
    JOIN client_info ci ON i.client_id = ci.client_id
    GROUP BY i.client_id
),

-- Current assets (investment + real estate + personal property)
current_assets AS (
    SELECT 
        client_id,
        SUM(total_value) AS total_assets
    FROM (
        SELECT client_id, total_value FROM core.investment_deposit_accounts
        UNION ALL
        SELECT client_id, total_value FROM core.real_estate_assets  
        UNION ALL
        SELECT client_id, total_value FROM core.personal_property_accounts
    ) all_assets
    GROUP BY client_id
),

-- Calculate present value of future regular expenses (excluding LTC)
future_expenses_pv AS (
    SELECT 
        e.client_id,
        SUM(
            CASE 
                WHEN NOT (e.type ILIKE '%ltc%' OR e.expense_item ILIKE '%long term care%')
                THEN e.annual_amount * 
                     (1 - POWER(1.0/1.04, 20)) / 0.04  -- 20-year planning horizon
                ELSE 0
            END
        ) AS pv_future_expenses
    FROM core.expenses e
    JOIN client_info ci ON e.client_id = ci.client_id
    GROUP BY e.client_id
),

-- Calculate present value of future LTC expenses (premiums only)
ltc_expenses_pv AS (
    SELECT 
        l.client_id,
        SUM(
            CASE 
                WHEN l.sub_type ILIKE '%ltc%' OR l.fact_type_name ILIKE '%long term care%'
                THEN COALESCE(l.annual_premium, 0) * 
                     (1 - POWER(1.0/1.04, 20)) / 0.04  -- 20-year planning horizon
                ELSE 0
            END
        ) AS pv_ltc_expenses
    FROM core.disability_ltc_insurance_accounts l
    JOIN client_info ci ON l.client_id = ci.client_id
    GROUP BY l.client_id
)

-- Final LTC ratio calculation
SELECT 
    ROUND(
        (
            COALESCE(fi.pv_future_income, 0) + 
            COALESCE(ca.total_assets, 0)
        ) / 
        NULLIF(
            (COALESCE(fe.pv_future_expenses, 0) + COALESCE(le.pv_ltc_expenses, 0)),
            0
        ),
        2
    ) AS ltc_ratio
FROM client_info ci
LEFT JOIN future_income_pv fi ON ci.client_id = fi.client_id
LEFT JOIN current_assets ca ON ci.client_id = ca.client_id
LEFT JOIN future_expenses_pv fe ON ci.client_id = fe.client_id
LEFT JOIN ltc_expenses_pv le ON ci.client_id = le.client_id;


-- LTD Ratio (Corrected Version)
WITH 
-- Get client information
client_info AS (
    SELECT 
        c.client_id
    FROM core.clients c
    WHERE c.client_id = {{client_id}}
),

-- LTD value (current value/benefit amount of LTD policies)
ltd_value AS (
    SELECT 
        client_id,
        SUM(COALESCE(benefit_amount, 0)) AS ltd_value
    FROM core.disability_ltc_insurance_accounts
    WHERE fact_type_name ILIKE '%disability%'
    GROUP BY client_id
),

-- Current earned income (salary/wage income for current year)
earned_income AS (
    SELECT 
        client_id,
        SUM(COALESCE(current_year_amount, 0)) AS earned_income
    FROM core.incomes
    WHERE income_type = 'Salary' 
      AND (deleted IS NULL OR deleted = false)
    GROUP BY client_id
)

-- Final LTD ratio calculation
SELECT 
    ROUND(
        COALESCE(l.ltd_value, 0) / NULLIF(COALESCE(e.earned_income, 0), 0),
        2
    ) AS ltd_ratio
FROM client_info ci
LEFT JOIN ltd_value l ON ci.client_id = l.client_id
LEFT JOIN earned_income e ON ci.client_id = e.client_id;



