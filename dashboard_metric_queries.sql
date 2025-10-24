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
--Retirement ratio:
SELECT 
 c.client_id,
 c.first_name,
 c.last_name,
 ROUND(
 (
 COALESCE(i.future_income, 0) + 
 COALESCE(a.current_assets, 0) + 
 COALESCE(s.retirement_savings, 0)
 ) / 
 NULLIF(
 (COALESCE(e.future_expenses, 0) + COALESCE(l.current_liabilities, 0)),
 0
 ),
 2
 ) AS retirement_ratio
FROM core.clients c
LEFT JOIN (
 SELECT client_id, SUM(annual_amount) AS future_income
 FROM core.incomes
 GROUP BY client_id
) i ON c.client_id = i.client_id
LEFT JOIN (
 SELECT client_id, SUM(total_value) AS current_assets
 FROM (
 SELECT client_id, total_value FROM core.investment_deposit_accounts
 UNION ALL
 SELECT client_id, total_value FROM core.real_estate_assets
 UNION ALL
 SELECT client_id, total_value FROM core.personal_property_accounts
 ) combined_assets
 GROUP BY client_id
) a ON c.client_id = a.client_id
LEFT JOIN (
 SELECT client_id, 
 SUM(COALESCE(calculated_annual_amount_usd, fixed_amount_usd)) AS 
retirement_savings
 FROM core.savings
 GROUP BY client_id
) s ON c.client_id = s.client_id
LEFT JOIN (
 SELECT client_id, SUM(annual_amount) AS future_expenses
 FROM core.expenses
 GROUP BY client_id
) e ON c.client_id = e.client_id
LEFT JOIN (
 SELECT client_id, SUM(total_value) AS current_liabilities
 FROM core.liability_note_accounts
 GROUP BY client_id
) l ON c.client_id = l.client_id

--Survivor ratio:
SELECT 
 c.client_id,
 c.first_name,
 c.last_name,
 ROUND(
 (
 COALESCE(life_ins.life_insurance_value, 0) +
 COALESCE(i.future_income, 0) + 
 COALESCE(a.current_assets, 0)
 ) /
 NULLIF(
 (COALESCE(e.future_expenses, 0) + COALESCE(li.current_liabilities, 0)),
 0
 ),
 2
 ) AS survivor_ratio
FROM core.clients c
-- Future Income
LEFT JOIN (
 SELECT client_id, SUM(annual_amount) AS future_income
 FROM core.incomes
 GROUP BY client_id
) i ON c.client_id = i.client_id
-- Current Assets (Investment + Real Estate + Personal Property)
LEFT JOIN (
 SELECT client_id, SUM(total_value) AS current_assets
 FROM (
 SELECT client_id, total_value FROM core.investment_deposit_accounts
 UNION ALL
 SELECT client_id, total_value FROM core.real_estate_assets
 UNION ALL
 SELECT client_id, total_value FROM core.personal_property_accounts
 ) combined_assets
 GROUP BY client_id
) a ON c.client_id = a.client_id
-- Life Insurance (Death Benefit)
LEFT JOIN (
 SELECT client_id, SUM(death_benefit) AS life_insurance_value
 FROM core.life_insurance_annuity_accounts
 GROUP BY client_id
) life_ins ON c.client_id = life_ins.client_id
-- Future Expenses
LEFT JOIN (
 SELECT client_id, SUM(annual_amount) AS future_expenses
 FROM core.expenses
 GROUP BY client_id
) e ON c.client_id = e.client_id
-- Current Liabilities
LEFT JOIN (
 SELECT client_id, SUM(total_value) AS current_liabilities
 FROM core.liability_note_accounts
 GROUP BY client_id
) li ON c.client_id = li.client_id;
SELECT 
 c.client_id,
 c.first_name,
 c.last_name,
 ROUND(
 (
 COALESCE(s.education_savings, 0) +
 COALESCE(a.education_accounts, 0)
 ) /
 NULLIF(COALESCE(e.education_expenses, 0), 0),
 2
 ) AS education_ratio
FROM core.clients c

-- Education Savings (savings accounts with education destination)
SELECT 
 c.client_id,
 c.first_name,
 c.last_name,
 ROUND(
 (
 COALESCE(s.education_savings, 0) +
 COALESCE(a.education_accounts, 0)
 ) /
 NULLIF(COALESCE(e.education_expenses, 0), 0),
 2
 ) AS education_ratio
FROM core.clients c
-- Education Savings
LEFT JOIN (
 SELECT 
 client_id,
 SUM(COALESCE(calculated_annual_amount_usd, fixed_amount_usd)) AS 
education_savings
 FROM core.savings
 WHERE LOWER(destination) LIKE '%education%'
 GROUP BY client_id
) s ON c.client_id = s.client_id
-- Current Education Accounts
LEFT JOIN (
 SELECT 
 client_id,
 SUM(total_value) AS education_accounts
 FROM (
 -- Investment accounts with subtype containing 'education'
 SELECT client_id, total_value 
 FROM core.investment_deposit_accounts
 WHERE LOWER(sub_type) LIKE '%education%'
 
 UNION ALL
 
 -- Personal property accounts (include all — no subtype field)
 SELECT client_id, total_value 
 FROM core.personal_property_accounts
 ) AS edu_accounts
 GROUP BY client_id
) a ON c.client_id = a.client_id
-- Future Education Expenses
LEFT JOIN (
 SELECT 
 client_id,
 SUM(annual_amount) AS education_expenses
 FROM core.expenses
 WHERE LOWER(type) LIKE '%education%'
 OR LOWER(sub_type) LIKE '%education%'
 OR LOWER(expense_item) LIKE '%education%'
 GROUP BY client_id
) e ON c.client_id = e.client_id;

--Cars
SELECT 
 c.client_id,
 c.first_name,
 c.last_name,
 ROUND(
 (
 COALESCE(t.taxable_account_value, 0) + 
 COALESCE(s.taxable_savings, 0)
 ) / 
 NULLIF(COALESCE(e.future_car_expenses, 0), 0),
 2
 ) AS new_cars_ratio
FROM core.clients c
-- taxable accounts (investment accounts flagged taxable + personal property accounts with car in name)
LEFT JOIN (
 SELECT client_id, SUM(total_value) AS taxable_account_value
 FROM (
 -- investment/deposit accounts that look taxable
 SELECT client_id, total_value
 FROM core.investment_deposit_accounts
 WHERE LOWER(COALESCE(sub_type, '')) LIKE '%taxable%'
 OR LOWER(COALESCE(account_name, '')) LIKE '%taxable%'
 UNION ALL
 -- personal property accounts where the account_name suggests a car
 SELECT client_id, total_value
 FROM core.personal_property_accounts
 WHERE LOWER(COALESCE(account_name, '')) LIKE '%car%'
 OR LOWER(COALESCE(account_name, '')) LIKE '%vehicle%'
 OR LOWER(COALESCE(account_name, '')) LIKE '%auto%'
 ) AS taxable_union
 GROUP BY client_id
) t ON c.client_id = t.client_id
-- taxable savings (fallback: any savings that are not explicitly retirement or education)
LEFT JOIN (
 SELECT client_id, 
 SUM(COALESCE(calculated_annual_amount_usd, fixed_amount_usd, 0)) AS 
taxable_savings
 FROM core.savings
 WHERE NOT (
 LOWER(COALESCE(destination, '')) LIKE '%retirement%'
 OR LOWER(COALESCE(destination, '')) LIKE '%education%'
 )
 GROUP BY client_id
) s ON c.client_id = s.client_id
-- future car expenses (look for car/vehicle/auto keywords in expense_item/type/sub_type)
LEFT JOIN (
 SELECT client_id, SUM(annual_amount) AS future_car_expenses
 FROM core.expenses
 WHERE LOWER(COALESCE(expense_item, '')) LIKE '%car%'
 OR LOWER(COALESCE(expense_item, '')) LIKE '%vehicle%'
 OR LOWER(COALESCE(expense_item, '')) LIKE '%auto%'
 OR LOWER(COALESCE(type, '')) LIKE '%car%'
 OR LOWER(COALESCE(type, '')) LIKE '%vehicle%'
 OR LOWER(COALESCE(type, '')) LIKE '%auto%'
 OR LOWER(COALESCE(sub_type, '')) LIKE '%car%'
 OR LOWER(COALESCE(sub_type, '')) LIKE '%vehicle%'
 OR LOWER(COALESCE(sub_type, '')) LIKE '%auto%'
 GROUP BY client_id
) e ON c.client_id = e.client_id;

--LTC
SELECT 
 c.client_id,
 c.first_name,
 c.last_name,
 ROUND(
 (
 COALESCE(i.future_income, 0) + 
 COALESCE(a.total_assets, 0)
 ) / 
 NULLIF(
 (COALESCE(e.future_expenses, 0) + COALESCE(l.ltc_expenses, 0)),
 0
 ),
 2
 ) AS ltc_ratio
FROM core.clients c
-- Income: Sum of all income streams
LEFT JOIN (
 SELECT client_id, SUM(annual_amount) AS future_income
 FROM core.incomes
 GROUP BY client_id
) i ON c.client_id = i.client_id
-- Assets: Combine investment, real estate, and personal property
LEFT JOIN (
 SELECT client_id, SUM(total_value) AS total_assets
 FROM (
 SELECT client_id, total_value FROM core.investment_deposit_accounts
 UNION ALL
 SELECT client_id, total_value FROM core.real_estate_assets
 UNION ALL
 SELECT client_id, total_value FROM core.personal_property_accounts
 ) assets
 GROUP BY client_id
) a ON c.client_id = a.client_id
-- Future Expenses: All regular (non-LTC) expenses
LEFT JOIN (
 SELECT client_id, SUM(annual_amount) AS future_expenses
 FROM core.expenses
 WHERE LOWER(COALESCE(type, '')) NOT LIKE '%ltc%'
 AND LOWER(COALESCE(expense_item, '')) NOT LIKE '%long term care%'
 GROUP BY client_id
) e ON c.client_id = e.client_id
-- LTC Expenses: Sum of premiums or benefit costs from LTC insurance
LEFT JOIN (
 SELECT client_id, 
 SUM(COALESCE(annual_premium, 0) + COALESCE(benefit_amount, 0)) AS ltc_expenses
 FROM core.disability_ltc_insurance_accounts
 WHERE LOWER(COALESCE(sub_type, '')) LIKE '%ltc%'
 OR LOWER(COALESCE(fact_type_name, '')) LIKE '%long term care%'
 GROUP BY client_id
) l ON c.client_id = l.client_id;

--LTD
SELECT 
 c.client_id,
 c.first_name,
 c.last_name,
 ROUND(
 COALESCE(l.ltd_value, 0) / NULLIF(COALESCE(i.earned_income, 0), 0),
 2
 ) AS ltd_ratio
FROM core.clients c
-- LTD value (current value of LTD accounts)
LEFT JOIN (
 SELECT client_id,
 SUM(total_value) AS ltd_value
 FROM core.disability_ltc_insurance_accounts
 WHERE LOWER(COALESCE(sub_type, '')) LIKE '%ltd%'
 OR LOWER(COALESCE(fact_type_name, '')) LIKE '%long term disability%'
 GROUP BY client_id
) l ON c.client_id = l.client_id
-- Current earned income (from income table)
LEFT JOIN (
 SELECT client_id,
 SUM(annual_amount) AS earned_income
 FROM core.incomes
 WHERE LOWER(COALESCE(income_type, '')) LIKE '%salary%'
 OR LOWER(COALESCE(income_type, '')) LIKE '%wage%'
 OR LOWER(COALESCE(income_type, '')) LIKE '%earned%'
 OR LOWER(COALESCE(income_name, '')) LIKE '%salary%'
 OR LOWER(COALESCE(income_name, '')) LIKE '%wage%'
 OR LOWER(COALESCE(income_name, '')) LIKE '%earned%'
 GROUP BY client_id
) i ON c.client_id = i.client_id;


