--Data loading queries for core schema

--account_history
-- Insert cleaned data from stg
INSERT INTO core.account_history (client_id, account_id, as_of_date, value)
SELECT
    NULLIF(TRIM(client_id), '')::INTEGER AS client_id,
    NULLIF(TRIM(account_id), '') AS account_id,
    NULLIF(TRIM(as_of_date), '')::DATE AS as_of_date,
    NULLIF(TRIM(value), '')::NUMERIC AS value
FROM stg.account_history;

--businesses
-- Insert cleaned data from stg
INSERT INTO core.businesses (
    client_id,
    fact_id,
    fact_type_name,
    sub_type,
    name,
    amount,
    amount_as_of,
    cost_basis
)
SELECT
    NULLIF(TRIM(client_id), '')::INTEGER AS client_id,
    NULLIF(TRIM(fact_id), '') AS fact_id,
    NULLIF(TRIM(fact_type_name), '') AS fact_type_name,
    NULLIF(TRIM(sub_type), '') AS sub_type,
    NULLIF(TRIM(name), '') AS name,
    NULLIF(TRIM(amount), '')::NUMERIC AS amount,
    NULLIF(TRIM(amount_as_of), '')::TIMESTAMP AS amount_as_of,
    NULLIF(TRIM(cost_basis), '')::NUMERIC AS cost_basis
FROM stg.businesses;

--charities
-- Insert cleaned data from stg
INSERT INTO core.charities (client_id, fact_id, name)
SELECT
    NULLIF(TRIM(client_id), '')::INTEGER AS client_id,
    NULLIF(TRIM(fact_id), '') AS fact_id,
    NULLIF(TRIM(name), '') AS name
FROM stg.charities;

--clients
-- Insert cleaned data from stg
INSERT INTO core.clients (
    client_id,
    client_name,
    first_name,
    last_name,
    hh_date_of_birth,
    gender,
    marital_status,
    citizenship,
    spouse_first_name,
    spouse_last_name,
    spouse_dob,
    address1,
    city,
    state_or_province,
    postal_code,
    home_phone,
    business_phone,
    cell_phone,
    spouse_cell_phone,
    emp_name,
    emp_job_title,
    emp_years_employed
)
SELECT
    NULLIF(TRIM(client_id), '')::INTEGER AS client_id,
    NULLIF(TRIM(client_name), '') AS client_name,
    NULLIF(TRIM(first_name), '') AS first_name,
    NULLIF(TRIM(last_name), '') AS last_name,
    TO_DATE(NULLIF(TRIM(hh_date_of_birth), ''), 'MM/DD/YYYY') AS hh_date_of_birth,
    NULLIF(TRIM(gender), '') AS gender,
    NULLIF(TRIM(marital_status), '') AS marital_status,
    NULLIF(TRIM(citizenship), '') AS citizenship,
    NULLIF(TRIM(spouse_first_name), '') AS spouse_first_name,
    NULLIF(TRIM(spouse_last_name), '') AS spouse_last_name,
    TO_DATE(NULLIF(TRIM(SPLIT_PART(spouse_dob, ' ', 1)), ''), 'MM/DD/YYYY') AS spouse_dob,
    NULLIF(TRIM(address1), '') AS address1,
    NULLIF(TRIM(city), '') AS city,
    NULLIF(TRIM(state_or_province), '') AS state_or_province,
    NULLIF(TRIM(postal_code), '') AS postal_code,
    NULLIF(TRIM(home_phone), '') AS home_phone,
    NULLIF(TRIM(business_phone), '') AS business_phone,
    NULLIF(TRIM(cell_phone), '') AS cell_phone,
    NULLIF(TRIM(spouse_cell_phone), '') AS spouse_cell_phone,
    NULLIF(TRIM(emp_name), '') AS emp_name,
    NULLIF(TRIM(emp_job_title), '') AS emp_job_title,
    NULLIF(TRIM(emp_years_employed), '')::INTEGER AS emp_years_employed
FROM stg.clients;

--disability_ltc_insurance_accounts
-- Insert cleaned data from stg
INSERT INTO core.disability_ltc_insurance_accounts (
    client_id,
    account_id,
    account_name,
    account_number,
    total_value,
    amount_as_of,
    institution_name,
    benefit_amount,
    fact_type_name,
    sub_type,
    connected,
    purchase_date,
    premium_term_in_years,
    annual_premium,
    elimination_period,
    elimination_period_in_days,
    benefit_type,
    benefit_frequency,
    benefit_period,
    benefit_period_in_days,
    own_occupation,
    is_benefit_taxable,
    business_entity_id
)
SELECT
    NULLIF(TRIM(client_id), '')::INTEGER AS client_id,
    NULLIF(TRIM(account_id), '') AS account_id,
    NULLIF(TRIM(account_name), '') AS account_name,
    NULLIF(TRIM(account_number), '') AS account_number,
    NULLIF(TRIM(total_value), '')::NUMERIC AS total_value,
    NULLIF(TRIM(amount_as_of), '')::TIMESTAMP AS amount_as_of,
    NULLIF(TRIM(institution_name), '') AS institution_name,
    NULLIF(TRIM(benefit_amount), '')::NUMERIC AS benefit_amount,
    NULLIF(TRIM(fact_type_name), '') AS fact_type_name,
    NULLIF(TRIM(sub_type), '') AS sub_type,
    CASE 
        WHEN TRIM(connected) = '' THEN NULL
        WHEN LOWER(TRIM(connected)) = 'true' THEN TRUE
        WHEN LOWER(TRIM(connected)) = 'false' THEN FALSE
        ELSE NULL
    END AS connected,
    NULLIF(TRIM(purchase_date), '')::DATE AS purchase_date,
    NULLIF(TRIM(premium_term_in_years), '')::NUMERIC AS premium_term_in_years,
    NULLIF(TRIM(annual_premium), '')::NUMERIC AS annual_premium,
    NULLIF(TRIM(elimination_period), '') AS elimination_period,
    NULLIF(TRIM(elimination_period_in_days), '')::INTEGER AS elimination_period_in_days,
    NULLIF(TRIM(benefit_type), '') AS benefit_type,
    NULLIF(TRIM(benefit_frequency), '') AS benefit_frequency,
    NULLIF(TRIM(benefit_period), '') AS benefit_period,
    NULLIF(TRIM(benefit_period_in_days), '')::NUMERIC AS benefit_period_in_days,
    NULLIF(TRIM(own_occupation), '')::NUMERIC AS own_occupation,
    CASE 
        WHEN TRIM(is_benefit_taxable) = '' THEN NULL
        WHEN LOWER(TRIM(is_benefit_taxable)) = 'true' THEN TRUE
        WHEN LOWER(TRIM(is_benefit_taxable)) = 'false' THEN FALSE
        ELSE NULL
    END AS is_benefit_taxable,
    NULLIF(TRIM(business_entity_id), '') AS business_entity_id
FROM stg.disability_ltc_insurance_accounts;

--entity_interests
-- Insert cleaned data from stg
INSERT INTO core.entity_interests (
    client_id,
    account_id,
    interest_id,
    interest_owner_type,
    interest_type,
    interest_percent
)
SELECT
    NULLIF(TRIM(client_id), '')::INTEGER AS client_id,
    NULLIF(TRIM(account_id), '') AS account_id,
    NULLIF(TRIM(interest_id), '') AS interest_id,
    NULLIF(TRIM(interest_owner_type), '') AS interest_owner_type,
    NULLIF(TRIM(interest_type), '') AS interest_type,
    NULLIF(TRIM(interest_percent), '')::NUMERIC AS interest_percent
FROM stg.entity_interests;

--expenses
-- Insert cleaned data from stg
INSERT INTO core.expenses (
    client_id,
    expense_item,
    individual_full_name,
    annual_amount,
    end_actual_date,
    end_projection_date,
    end_type,
    institution_name,
    is_goal,
    start_actual_date,
    start_indexing_at,
    start_type,
    sub_type,
    type
)
SELECT
    NULLIF(TRIM(client_id), '')::INTEGER AS client_id,
    NULLIF(TRIM(expense_item), '') AS expense_item,
    NULLIF(TRIM(individual_full_name), '') AS individual_full_name,
    NULLIF(TRIM(annual_amount), '')::NUMERIC AS annual_amount,
    NULLIF(TRIM(end_actual_date), '')::DATE AS end_actual_date,
    NULLIF(TRIM(end_projection_date), '')::DATE AS end_projection_date,
    NULLIF(TRIM(end_type), '') AS end_type,
    NULLIF(TRIM(institution_name), '') AS institution_name,
    CASE 
        WHEN TRIM(is_goal) = '' THEN NULL
        WHEN LOWER(TRIM(is_goal)) = 'true' THEN TRUE
        WHEN LOWER(TRIM(is_goal)) = 'false' THEN FALSE
        ELSE NULL
    END AS is_goal,
    NULLIF(TRIM(start_actual_date), '')::DATE AS start_actual_date,
    NULLIF(TRIM(start_indexing_at), '') AS start_indexing_at,
    NULLIF(TRIM(start_type), '') AS start_type,
    NULLIF(TRIM(sub_type), '') AS sub_type,
    NULLIF(TRIM(type), '') AS type
FROM stg.expenses;

--facts
-- Insert cleaned data from stg
INSERT INTO core.facts (
    client_id,
    fact_id,
    fact_type_name,
    sub_type,
    name,
    amount,
    amount_as_of
)
SELECT
    NULLIF(TRIM(client_id), '')::INTEGER AS client_id,
    NULLIF(TRIM(fact_id), '') AS fact_id,
    NULLIF(TRIM(fact_type_name), '') AS fact_type_name,
    NULLIF(TRIM(sub_type), '') AS sub_type,
    NULLIF(TRIM(name), '') AS name,
    CASE 
        WHEN TRIM(amount) = '' OR TRIM(amount) = 'NULL' THEN NULL
        ELSE TRIM(amount)::NUMERIC
    END AS amount,
    CASE 
        WHEN TRIM(amount_as_of) IN ('', 'NULL', '01/01/0001 12:00:00 AM') THEN NULL
        WHEN amount_as_of ~ '^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$' THEN 
            TRIM(amount_as_of)::TIMESTAMP
        ELSE 
            TO_TIMESTAMP(TRIM(amount_as_of), 'MM/DD/YYYY HH12:MI:SS AM')
    END AS amount_as_of
FROM stg.facts;

--flows
-- Insert cleaned data from stg
INSERT INTO core.flows (
    client_id,
    account_id,
    account_name,
    amount,
    retirement_amount,
    amount_as_of,
    institution_name,
    fact_type_name,
    sub_type
)
SELECT
    NULLIF(TRIM(client_id), '')::INTEGER AS client_id,
    NULLIF(TRIM(account_id), '') AS account_id,
    NULLIF(TRIM(account_name), '') AS account_name,
    CASE 
        WHEN TRIM(amount) = '' OR TRIM(amount) = 'NULL' THEN NULL
        ELSE TRIM(amount)::NUMERIC
    END AS amount,
    CASE 
        WHEN TRIM(retirement_amount) = '' OR TRIM(retirement_amount) = 'NULL' THEN NULL
        ELSE TRIM(retirement_amount)::NUMERIC
    END AS retirement_amount,
    CASE 
        WHEN TRIM(amount_as_of) IN ('', 'NULL', '01/01/0001 12:00:00 AM') THEN NULL
        WHEN amount_as_of ~ '^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$' THEN 
            TRIM(amount_as_of)::TIMESTAMP
        ELSE 
            TO_TIMESTAMP(TRIM(amount_as_of), 'MM/DD/YYYY HH12:MI:SS AM')
    END AS amount_as_of,
    NULLIF(TRIM(institution_name), '') AS institution_name,
    NULLIF(TRIM(fact_type_name), '') AS fact_type_name,
    NULLIF(TRIM(sub_type), '') AS sub_type
FROM stg.flows;

--holdings
-- Insert cleaned data from stg
INSERT INTO core.holdings (
    client_id,
    account_id,
    holdings_id,
    ticker,
    description,
    units,
    market_price,
    as_of,
    value,
    cost_basis,
    asset_class,
    holding_type
)
SELECT
    NULLIF(TRIM(client_id), '')::INTEGER AS client_id,
    NULLIF(TRIM(account_id), '') AS account_id,
    NULLIF(TRIM(holdings_id), '') AS holdings_id,
    NULLIF(TRIM(ticker), '') AS ticker,
    NULLIF(TRIM(description), '') AS description,
    NULLIF(TRIM(units), '')::NUMERIC AS units,
    NULLIF(TRIM(market_price), '')::NUMERIC AS market_price,
    NULLIF(TRIM(as_of), '')::DATE AS as_of,
    NULLIF(TRIM(value), '')::NUMERIC AS value,
    NULLIF(TRIM(cost_basis), '')::NUMERIC AS cost_basis,
    NULLIF(TRIM(asset_class), '') AS asset_class,
    NULLIF(TRIM(holding_type), '') AS holding_type
FROM stg.holdings;

--incomes
-- Insert cleaned data from stg
INSERT INTO core.incomes (
    client_id,
    household_household_business_name,
    income_id,
    annual_amount,
    created_date,
    current_year_amount,
    deleted,
    end_type,
    end_value,
    income_frequency,
    income_name,
    income_type,
    is_self_employed,
    owner_type,
    start_actual_date,
    start_value
)
SELECT
    NULLIF(TRIM(client_id), '')::INTEGER AS client_id,
    NULLIF(TRIM(household_household_business_name), '') AS household_household_business_name,
    NULLIF(TRIM(income_id), '')::INTEGER AS income_id,
    NULLIF(TRIM(annual_amount), '')::NUMERIC AS annual_amount,
    NULLIF(TRIM(created_date), '')::TIMESTAMP AS created_date,
    NULLIF(TRIM(current_year_amount), '')::NUMERIC AS current_year_amount,
    CASE 
        WHEN TRIM(deleted) = '' THEN NULL
        WHEN LOWER(TRIM(deleted)) = 'true' THEN TRUE
        WHEN LOWER(TRIM(deleted)) = 'false' THEN FALSE
        ELSE NULL
    END AS deleted,
    NULLIF(TRIM(end_type), '') AS end_type,
    NULLIF(TRIM(end_value), '')::NUMERIC AS end_value,
    NULLIF(TRIM(income_frequency), '') AS income_frequency,
    NULLIF(TRIM(income_name), '') AS income_name,
    NULLIF(TRIM(income_type), '') AS income_type,
    CASE 
        WHEN TRIM(is_self_employed) = '' THEN NULL
        WHEN LOWER(TRIM(is_self_employed)) = 'true' THEN TRUE
        WHEN LOWER(TRIM(is_self_employed)) = 'false' THEN FALSE
        ELSE NULL
    END AS is_self_employed,
    NULLIF(TRIM(owner_type), '') AS owner_type,
    NULLIF(TRIM(start_actual_date), '')::DATE AS start_actual_date,
    NULLIF(TRIM(start_value), '')::INTEGER AS start_value
FROM stg.incomes;

--investment_deposit_accounts
-- Insert cleaned data from stg
INSERT INTO core.investment_deposit_accounts (
    client_id,
    account_id,
    account_name,
    total_value,
    amount_as_of,
    institution_name,
    holdings_value,
    cash_balance,
    cost_basis,
    fact_type_name,
    sub_type,
    under_our_management
)
SELECT
    NULLIF(TRIM(client_id), '')::INTEGER AS client_id,
    NULLIF(TRIM(account_id), '') AS account_id,
    NULLIF(TRIM(account_name), '') AS account_name,
    NULLIF(TRIM(total_value), '')::NUMERIC AS total_value,
    NULLIF(TRIM(amount_as_of), '')::TIMESTAMP AS amount_as_of,
    NULLIF(TRIM(institution_name), '') AS institution_name,
    NULLIF(TRIM(holdings_value), '')::NUMERIC AS holdings_value,
    NULLIF(TRIM(cash_balance), '')::NUMERIC AS cash_balance,
    NULLIF(TRIM(cost_basis), '')::NUMERIC AS cost_basis,
    NULLIF(TRIM(fact_type_name), '') AS fact_type_name,
    NULLIF(TRIM(sub_type), '') AS sub_type,
    CASE 
        WHEN TRIM(under_our_management) = '' OR TRIM(under_our_management) = 'NULL' THEN NULL
        WHEN TRIM(under_our_management) = '0.0' THEN FALSE
        WHEN TRIM(under_our_management) = '1.0' THEN TRUE
        ELSE NULL
    END AS under_our_management
FROM stg.investment_deposit_accounts;

--liability_note_accounts
-- Insert cleaned data from stg
INSERT INTO core.liability_note_accounts (
    client_id,
    account_id,
    account_name,
    total_value,
    amount_as_of,
    institution_name,
    cash_balance,
    fact_type_name,
    sub_type,
    connected,
    under_our_management,
    repayment_type,
    original_loan_amount,
    loan_term_in_years,
    is_interest_deductible,
    interest_rate,
    loan_date,
    payment_frequency,
    number_of_payments,
    real_estate_id
)
SELECT
    NULLIF(TRIM(client_id), '')::INTEGER AS client_id,
    NULLIF(TRIM(account_id), '') AS account_id,
    NULLIF(TRIM(account_name), '') AS account_name,
    NULLIF(TRIM(total_value), '')::NUMERIC AS total_value,
    NULLIF(TRIM(amount_as_of), '')::TIMESTAMP AS amount_as_of,
    NULLIF(TRIM(institution_name), '') AS institution_name,
    NULLIF(TRIM(cash_balance), '')::NUMERIC AS cash_balance,
    NULLIF(TRIM(fact_type_name), '') AS fact_type_name,
    NULLIF(TRIM(sub_type), '') AS sub_type,
    CASE 
        WHEN TRIM(connected) = '' THEN NULL
        WHEN LOWER(TRIM(connected)) = 'true' THEN TRUE
        WHEN LOWER(TRIM(connected)) = 'false' THEN FALSE
        ELSE NULL
    END AS connected,
    CASE 
        WHEN TRIM(under_our_management) = '' OR TRIM(under_our_management) = 'NULL' THEN NULL
        WHEN TRIM(under_our_management) = '0.0' THEN FALSE
        WHEN TRIM(under_our_management) = '1.0' THEN TRUE
        WHEN LOWER(TRIM(under_our_management)) = 'true' THEN TRUE
        WHEN LOWER(TRIM(under_our_management)) = 'false' THEN FALSE
        ELSE NULL
    END AS under_our_management,
    NULLIF(TRIM(repayment_type), '') AS repayment_type,
    NULLIF(TRIM(original_loan_amount), '')::NUMERIC AS original_loan_amount,
    NULLIF(TRIM(loan_term_in_years), '')::NUMERIC AS loan_term_in_years,
    CASE 
        WHEN TRIM(is_interest_deductible) = '' THEN NULL
        WHEN LOWER(TRIM(is_interest_deductible)) = 'true' THEN TRUE
        WHEN LOWER(TRIM(is_interest_deductible)) = 'false' THEN FALSE
        ELSE NULL
    END AS is_interest_deductible,
    NULLIF(TRIM(interest_rate), '')::NUMERIC AS interest_rate,
    NULLIF(TRIM(loan_date), '')::DATE AS loan_date,
    NULLIF(TRIM(payment_frequency), '') AS payment_frequency,
    NULLIF(TRIM(number_of_payments), '')::NUMERIC AS number_of_payments,
    NULLIF(TRIM(real_estate_id), '') AS real_estate_id
FROM stg.liability_note_accounts;

--life_insurance_annuity_accounts
-- Insert cleaned data from stg
INSERT INTO core.life_insurance_annuity_accounts (
    client_id,
    account_id,
    account_name,
    account_number,
    total_value,
    amount_as_of,
    institution_name,
    holdings_value,
    cash_balance,
    margin_balance,
    cost_basis,
    death_benefit,
    fact_type_name,
    sub_type,
    under_our_management,
    purchase_date,
    premium_term_in_years,
    term_in_years,
    annual_premium
)
SELECT
    NULLIF(TRIM(client_id), '')::INTEGER AS client_id,
    NULLIF(TRIM(account_id), '') AS account_id,
    NULLIF(TRIM(account_name), '') AS account_name,
    NULLIF(TRIM(account_number), '') AS account_number,
    NULLIF(TRIM(total_value), '')::NUMERIC AS total_value,
    NULLIF(TRIM(amount_as_of), '')::TIMESTAMP AS amount_as_of,
    NULLIF(TRIM(institution_name), '') AS institution_name,
    NULLIF(TRIM(holdings_value), '')::NUMERIC AS holdings_value,
    NULLIF(TRIM(cash_balance), '')::NUMERIC AS cash_balance,
    NULLIF(TRIM(margin_balance), '')::NUMERIC AS margin_balance,
    NULLIF(TRIM(cost_basis), '')::NUMERIC AS cost_basis,
    NULLIF(TRIM(death_benefit), '')::NUMERIC AS death_benefit,
    NULLIF(TRIM(fact_type_name), '') AS fact_type_name,
    NULLIF(TRIM(sub_type), '') AS sub_type,
    CASE 
        WHEN TRIM(under_our_management) = '' OR TRIM(under_our_management) = 'NULL' THEN NULL
        WHEN TRIM(under_our_management) = '0.0' THEN FALSE
        WHEN TRIM(under_our_management) = '1.0' THEN TRUE
        ELSE NULL
    END AS under_our_management,
    NULLIF(TRIM(purchase_date), '')::DATE AS purchase_date,
    NULLIF(TRIM(premium_term_in_years), '')::NUMERIC AS premium_term_in_years,
    NULLIF(TRIM(term_in_years), '')::NUMERIC AS term_in_years,
    NULLIF(TRIM(annual_premium), '')::NUMERIC AS annual_premium
FROM stg.life_insurance_annuity_accounts;

--medical_insurance_accounts
-- Insert cleaned data from stg
INSERT INTO core.medical_insurance_accounts (
    client_id,
    account_id,
    account_name,
    amount_as_of,
    institution_name,
    fact_type_name,
    sub_type,
    purchase_date,
    annual_premium,
    deductible
)
SELECT
    NULLIF(TRIM(client_id), '')::INTEGER AS client_id,
    NULLIF(TRIM(account_id), '') AS account_id,
    NULLIF(TRIM(account_name), '') AS account_name,
    NULLIF(TRIM(amount_as_of), '')::TIMESTAMP AS amount_as_of,
    NULLIF(TRIM(institution_name), '') AS institution_name,
    NULLIF(TRIM(fact_type_name), '') AS fact_type_name,
    NULLIF(TRIM(sub_type), '') AS sub_type,
    NULLIF(TRIM(purchase_date), '')::DATE AS purchase_date,
    NULLIF(TRIM(annual_premium), '')::NUMERIC AS annual_premium,
    NULLIF(TRIM(deductible), '')::NUMERIC AS deductible
FROM stg.medical_insurance_accounts;

--personal_property_accounts
-- Insert cleaned data from stg
INSERT INTO core.personal_property_accounts (
    client_id,
    account_id,
    account_name,
    total_value,
    amount_as_of,
    cost_basis,
    fact_type_name
)
SELECT
    NULLIF(TRIM(client_id), '')::INTEGER AS client_id,
    NULLIF(TRIM(account_id), '') AS account_id,
    NULLIF(TRIM(account_name), '') AS account_name,
    NULLIF(TRIM(total_value), '')::NUMERIC AS total_value,
    NULLIF(TRIM(amount_as_of), '')::TIMESTAMP AS amount_as_of,
    NULLIF(TRIM(cost_basis), '')::NUMERIC AS cost_basis,
    NULLIF(TRIM(fact_type_name), '') AS fact_type_name
FROM stg.personal_property_accounts;

--property_casualty_insurance_accounts
-- Insert cleaned data from stg
INSERT INTO core.property_casualty_insurance_accounts (
    client_id,
    account_id,
    account_name,
    amount_as_of,
    institution_name,
    sub_type,
    connected,
    purchase_date,
    annual_premium,
    premium_term_in_years,
    replacement_value,
    renewal_date,
    maximum_annual_benefit
)
SELECT
    NULLIF(TRIM(client_id), '')::INTEGER AS client_id,
    NULLIF(TRIM(account_id), '') AS account_id,
    NULLIF(TRIM(account_name), '') AS account_name,
    NULLIF(TRIM(amount_as_of), '')::TIMESTAMP AS amount_as_of,
    NULLIF(TRIM(institution_name), '') AS institution_name,
    NULLIF(TRIM(sub_type), '') AS sub_type,
    CASE 
        WHEN TRIM(connected) = '' THEN NULL
        WHEN LOWER(TRIM(connected)) = 'true' THEN TRUE
        WHEN LOWER(TRIM(connected)) = 'false' THEN FALSE
        ELSE NULL
    END AS connected,
    NULLIF(TRIM(purchase_date), '')::DATE AS purchase_date,
    NULLIF(TRIM(annual_premium), '')::NUMERIC AS annual_premium,
    NULLIF(TRIM(premium_term_in_years), '')::NUMERIC AS premium_term_in_years,
    CASE 
        WHEN TRIM(replacement_value) = '' THEN NULL
        WHEN LOWER(TRIM(replacement_value)) = 'true' THEN TRUE
        WHEN LOWER(TRIM(replacement_value)) = 'false' THEN FALSE
        ELSE NULL
    END AS replacement_value,
    NULLIF(TRIM(renewal_date), '')::DATE AS renewal_date,
    NULLIF(TRIM(maximum_annual_benefit), '')::NUMERIC AS maximum_annual_benefit
FROM stg.property_casualty_insurance_accounts;

--real_estate_assets
-- Insert cleaned data from stg
INSERT INTO core.real_estate_assets (
    client_id,
    account_id,
    account_name,
    total_value,
    amount_as_of,
    cost_basis,
    sub_type,
    address1,
    address2,
    city,
    state,
    postal_code,
    purchase_year,
    purchase_amount
)
SELECT
    NULLIF(TRIM(client_id), '')::INTEGER AS client_id,
    NULLIF(TRIM(account_id), '') AS account_id,
    NULLIF(TRIM(account_name), '') AS account_name,
    NULLIF(TRIM(total_value), '')::NUMERIC AS total_value,
    NULLIF(TRIM(amount_as_of), '')::TIMESTAMP AS amount_as_of,
    NULLIF(TRIM(cost_basis), '')::NUMERIC AS cost_basis,
    NULLIF(TRIM(sub_type), '') AS sub_type,
    NULLIF(TRIM(address1), '') AS address1,
    NULLIF(TRIM(address2), '') AS address2,
    NULLIF(TRIM(city), '') AS city,
    NULLIF(TRIM(state), '') AS state,
    NULLIF(TRIM(postal_code), '') AS postal_code,
    NULLIF(TRIM(purchase_year), '')::NUMERIC AS purchase_year,
    NULLIF(TRIM(purchase_amount), '')::NUMERIC AS purchase_amount
FROM stg.real_estate_assets;

--savings
-- Insert cleaned data from stg
INSERT INTO core.savings (
    client_id,
    name,
    destination,
    account_id,
    start_type,
    end_type,
    amount_type,
    fixed_amount_usd,
    match_rate_percent,
    income_cap_percent,
    calculated_annual_amount_usd,
    indexed_at_percent
)
SELECT
    c.client_id::INTEGER,
    c.name,
    c.destination,
    c.account_id,
    c.starts,
    c.ends,

    CASE WHEN c.amount LIKE '%100% of the first % of employee%'
         THEN 'percentage_formula'
         ELSE 'fixed_usd'
    END AS amount_type,

    CASE WHEN c.amount LIKE '%100% of the first % of employee%'
         THEN NULL
         ELSE REPLACE(REGEXP_REPLACE(c.amount, '\$|,(?=[0-9])| per year', '', 'g'), ' ', '')::NUMERIC
    END AS fixed_amount_usd,

    CASE WHEN c.amount LIKE '%100% of the first % of employee%'
         THEN 1.0000
         ELSE NULL
    END AS match_rate_percent,

    CASE WHEN c.amount LIKE '%100% of the first % of employee%'
         THEN (substring(c.amount FROM 'first ([0-9.]+)%'))::NUMERIC / 100.0
         ELSE NULL
    END AS income_cap_percent,

    CASE WHEN c.amount LIKE '%100% of the first % of employee%'
         THEN (SELECT i.annual_amount
               FROM core.incomes i
               WHERE i.client_id = c.client_id::INTEGER
                 AND i.income_type = 'Salary'
               ORDER BY
                   (i.income_name ILIKE '%primary%') DESC,
                   i.income_id ASC                  -- deterministic tie-breaker
               LIMIT 1)
              * 1.0000
              * (substring(c.amount FROM 'first ([0-9.]+)%'))::NUMERIC / 100.0
         ELSE REPLACE(REGEXP_REPLACE(c.amount, '\$|,(?=[0-9])| per year', '', 'g'), ' ', '')::NUMERIC
    END AS calculated_annual_amount_usd,

    CASE WHEN c.indexed_at ~ '[0-9.]+%'
         THEN REPLACE(c.indexed_at, '%', '')::NUMERIC
         ELSE NULL
    END AS indexed_at_percent
FROM stg.savings c;


--values
-- Insert cleaned data from stg
INSERT INTO core.values (
    client_id,
    household_business_name,
    active,
    last_name,
    first_name,
    email,
    email_spouse,
    values1,
    values2,
    values3,
    values4,
    values5,
    values6,
    accomplishments1,
    accomplishments2,
    accomplishments3,
    accomplishments4,
    relationships1,
    relationships2,
    relationships3,
    relationships4,
    goals1,
    goals2,
    goals3,
    goals4,
    goals5,
    risk1,
    risk2,
    risk3,
    risk4,
    foundation1,
    foundation2,
    foundation3,
    foundation4,
    next_and_next_steward1,
    next_and_next_steward2,
    next_and_next_steward4,
    process1,
    process2,
    process3,
    process4
)
SELECT
    NULLIF(TRIM(client_id), '')::INTEGER AS client_id,
    NULLIF(TRIM(household_business_name), '') AS household_business_name,
    NULLIF(TRIM(active), '') AS active,
    NULLIF(TRIM(last_name), '') AS last_name,
    NULLIF(TRIM(first_name), '') AS first_name,
    NULLIF(TRIM(email), '') AS email,
    NULLIF(TRIM(email_spouse), '') AS email_spouse,
    NULLIF(TRIM(values1), '') AS values1,
    NULLIF(TRIM(values2), '') AS values2,
    NULLIF(TRIM(values3), '') AS values3,
    NULLIF(TRIM(values4), '') AS values4,
    NULLIF(TRIM(values5), '') AS values5,
    NULLIF(TRIM(values6), '') AS values6,
    NULLIF(TRIM(accomplishments1), '') AS accomplishments1,
    NULLIF(TRIM(accomplishments2), '') AS accomplishments2,
    NULLIF(TRIM(accomplishments3), '') AS accomplishments3,
    NULLIF(TRIM(accomplishments4), '') AS accomplishments4,
    NULLIF(TRIM(relationships1), '') AS relationships1,
    NULLIF(TRIM(relationships2), '') AS relationships2,
    NULLIF(TRIM(relationships3), '') AS relationships3,
    NULLIF(TRIM(relationships4), '') AS relationships4,
    NULLIF(TRIM(goals1), '') AS goals1,
    NULLIF(TRIM(goals2), '') AS goals2,
    NULLIF(TRIM(goals3), '') AS goals3,
    NULLIF(TRIM(goals4), '') AS goals4,
    NULLIF(TRIM(goals5), '') AS goals5,
    NULLIF(TRIM(risk1), '') AS risk1,
    NULLIF(TRIM(risk2), '') AS risk2,
    NULLIF(TRIM(risk3), '') AS risk3,
    NULLIF(TRIM(risk4), '') AS risk4,
    NULLIF(TRIM(foundation1), '') AS foundation1,
    NULLIF(TRIM(foundation2), '') AS foundation2,
    NULLIF(TRIM(foundation3), '') AS foundation3,
    NULLIF(TRIM(foundation4), '') AS foundation4,
    NULLIF(TRIM(next_and_next_steward1), '') AS next_and_next_steward1,
    NULLIF(TRIM(next_and_next_steward2), '') AS next_and_next_steward2,
    NULLIF(TRIM(next_and_next_steward4), '') AS next_and_next_steward4,
    NULLIF(TRIM(process1), '') AS process1,
    NULLIF(TRIM(process2), '') AS process2,
    NULLIF(TRIM(process3), '') AS process3,
    NULLIF(TRIM(process4), '') AS process4
FROM stg.values;