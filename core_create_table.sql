--CREATE TABLE statements for core schema

--account_history
-- Create core table
CREATE TABLE IF NOT EXISTS core.account_history (
    client_id INTEGER,
    account_id TEXT,
    as_of_date DATE,
    value NUMERIC
);

--businesses
-- Create core table
CREATE TABLE IF NOT EXISTS core.businesses (
    client_id INTEGER,
    fact_id TEXT,
    fact_type_name TEXT,
    sub_type TEXT,
    name TEXT,
    amount NUMERIC,
    amount_as_of TIMESTAMP,
    cost_basis NUMERIC
);

--charities
-- Create core table
CREATE TABLE IF NOT EXISTS core.charities (
    client_id INTEGER,
    fact_id TEXT,
    name TEXT
);

--clients
-- Create core table
CREATE TABLE IF NOT EXISTS core.clients (
    client_id INTEGER,
    client_name TEXT,
    first_name TEXT,
    last_name TEXT,
    hh_date_of_birth DATE,
    gender TEXT,
    marital_status TEXT,
    citizenship TEXT,
    spouse_first_name TEXT,
    spouse_last_name TEXT,
    spouse_dob DATE,
    address1 TEXT,
    city TEXT,
    state_or_province TEXT,
    postal_code TEXT,
    home_phone TEXT,
    business_phone TEXT,
    cell_phone TEXT,
    spouse_cell_phone TEXT,
    emp_name TEXT,
    emp_job_title TEXT,
    emp_years_employed INTEGER
);

--disability_ltc_insurance_accounts
-- Create core table
CREATE TABLE IF NOT EXISTS core.disability_ltc_insurance_accounts (
    client_id INTEGER,
    account_id TEXT,
    account_name TEXT,
    account_number TEXT,
    total_value NUMERIC,
    amount_as_of TIMESTAMP,
    institution_name TEXT,
    benefit_amount NUMERIC,
    fact_type_name TEXT,
    sub_type TEXT,
    connected BOOLEAN,
    purchase_date DATE,
    premium_term_in_years NUMERIC,
    annual_premium NUMERIC,
    elimination_period TEXT,
    elimination_period_in_days INTEGER,
    benefit_type TEXT,
    benefit_frequency TEXT,
    benefit_period TEXT,
    benefit_period_in_days NUMERIC,
    own_occupation NUMERIC,
    is_benefit_taxable BOOLEAN,
    business_entity_id TEXT
);

--entity_interests
-- Create core table
CREATE TABLE IF NOT EXISTS core.entity_interests (
    client_id INTEGER,
    account_id TEXT,
    interest_id TEXT,
    interest_owner_type TEXT,
    interest_type TEXT,
    interest_percent NUMERIC
);

--expenses
-- Create core table
CREATE TABLE IF NOT EXISTS core.expenses (
    client_id INTEGER,
    expense_item TEXT,
    individual_full_name TEXT,
    annual_amount NUMERIC,
    end_actual_date DATE,
    end_projection_date DATE,
    end_type TEXT,
    institution_name TEXT,
    is_goal BOOLEAN,
    start_actual_date DATE,
    start_indexing_at TEXT,
    start_type TEXT,
    sub_type TEXT,
    type TEXT
);

--facts
-- Create core table
CREATE TABLE IF NOT EXISTS core.facts (
    client_id INTEGER,
    fact_id TEXT,
    fact_type_name TEXT,
    sub_type TEXT,
    name TEXT,
    amount NUMERIC,
    amount_as_of TIMESTAMP
);

--flows
-- Create core table
CREATE TABLE IF NOT EXISTS core.flows (
    client_id INTEGER,
    account_id TEXT,
    account_name TEXT,
    amount NUMERIC,
    retirement_amount NUMERIC,
    amount_as_of TIMESTAMP,
    institution_name TEXT,
    fact_type_name TEXT,
    sub_type TEXT
);

--holdings
-- Create core table
CREATE TABLE IF NOT EXISTS core.holdings (
    client_id INTEGER,
    account_id TEXT,
    holdings_id TEXT,
    ticker TEXT,
    description TEXT,
    units NUMERIC,
    market_price NUMERIC,
    as_of DATE,
    value NUMERIC,
    cost_basis NUMERIC,
    asset_class TEXT,
    holding_type TEXT
);

--incomes
-- Create core table
CREATE TABLE IF NOT EXISTS core.incomes (
    client_id INTEGER,
    household_household_business_name TEXT,
    income_id INTEGER,
    annual_amount NUMERIC,
    created_date TIMESTAMP,
    current_year_amount NUMERIC,
    deleted BOOLEAN,
    end_type TEXT,
    end_value NUMERIC,
    income_frequency TEXT,
    income_name TEXT,
    income_type TEXT,
    is_self_employed BOOLEAN,
    owner_type TEXT,
    start_actual_date DATE,
    start_value INTEGER
);

--investment_deposit_accounts
-- Create core table
CREATE TABLE IF NOT EXISTS core.investment_deposit_accounts (
    client_id INTEGER,
    account_id TEXT,
    account_name TEXT,
    total_value NUMERIC,
    amount_as_of TIMESTAMP,
    institution_name TEXT,
    holdings_value NUMERIC,
    cash_balance NUMERIC,
    cost_basis NUMERIC,
    fact_type_name TEXT,
    sub_type TEXT,
    under_our_management BOOLEAN
);

--liability_note_accounts
-- Create core table
CREATE TABLE IF NOT EXISTS core.liability_note_accounts (
    client_id INTEGER,
    account_id TEXT,
    account_name TEXT,
    total_value NUMERIC,
    amount_as_of TIMESTAMP,
    institution_name TEXT,
    cash_balance NUMERIC,
    fact_type_name TEXT,
    sub_type TEXT,
    connected BOOLEAN,
    under_our_management BOOLEAN,
    repayment_type TEXT,
    original_loan_amount NUMERIC,
    loan_term_in_years NUMERIC,
    is_interest_deductible BOOLEAN,
    interest_rate NUMERIC,
    loan_date DATE,
    payment_frequency TEXT,
    number_of_payments NUMERIC,
    real_estate_id TEXT
);

--life_insurance_annuity_accounts
-- Create core table
CREATE TABLE IF NOT EXISTS core.life_insurance_annuity_accounts (
    client_id INTEGER,
    account_id TEXT,
    account_name TEXT,
    account_number TEXT,
    total_value NUMERIC,
    amount_as_of TIMESTAMP,
    institution_name TEXT,
    holdings_value NUMERIC,
    cash_balance NUMERIC,
    margin_balance NUMERIC,
    cost_basis NUMERIC,
    death_benefit NUMERIC,
    fact_type_name TEXT,
    sub_type TEXT,
    under_our_management BOOLEAN,
    purchase_date DATE,
    premium_term_in_years NUMERIC,
    term_in_years NUMERIC,
    annual_premium NUMERIC
);

--medical_insurance_accounts
-- Create core table
CREATE TABLE IF NOT EXISTS core.medical_insurance_accounts (
    client_id INTEGER,
    account_id TEXT,
    account_name TEXT,
    amount_as_of TIMESTAMP,
    institution_name TEXT,
    fact_type_name TEXT,
    sub_type TEXT,
    purchase_date DATE,
    annual_premium NUMERIC,
    deductible NUMERIC
);

--personal_property_accounts
-- Create core table
CREATE TABLE IF NOT EXISTS core.personal_property_accounts (
    client_id INTEGER,
    account_id TEXT,
    account_name TEXT,
    total_value NUMERIC,
    amount_as_of TIMESTAMP,
    cost_basis NUMERIC,
    fact_type_name TEXT
);

--property_casualty_insurance_accounts
-- Create core table
CREATE TABLE IF NOT EXISTS core.property_casualty_insurance_accounts (
    client_id INTEGER,
    account_id TEXT,
    account_name TEXT,
    amount_as_of TIMESTAMP,
    institution_name TEXT,
    sub_type TEXT,
    connected BOOLEAN,
    purchase_date DATE,
    annual_premium NUMERIC,
    premium_term_in_years NUMERIC,
    replacement_value BOOLEAN,
    renewal_date DATE,
    maximum_annual_benefit NUMERIC
);

--real_estate_assets
-- Create core table
CREATE TABLE IF NOT EXISTS core.real_estate_assets (
    client_id INTEGER,
    account_id TEXT,
    account_name TEXT,
    total_value NUMERIC,
    amount_as_of TIMESTAMP,
    cost_basis NUMERIC,
    sub_type TEXT,
    address1 TEXT,
    address2 TEXT,
    city TEXT,
    state TEXT,
    postal_code TEXT,
    purchase_year NUMERIC,
    purchase_amount NUMERIC
);

--savings
-- Create core table
CREATE TABLE IF NOT EXISTS core.savings (
    savings_id SERIAL PRIMARY KEY,
    client_id INTEGER,
    name TEXT,
    destination TEXT,
    account_id TEXT,
    start_type TEXT,
    end_type TEXT,
    amount_type TEXT, -- 'numeric', 'currency_frequency', 'percentage_formula'
    amount_numeric NUMERIC(20,2), -- For absolute monetary values
    amount_frequency TEXT, -- 'per_year', 'annual', 'one_time', etc.
    amount_formula TEXT, -- Original formula text for percentage-based contributions
    amount_percentage_rate NUMERIC(5,4), -- Store the derived rate as a decimal (e.g., 4.0% -> 0.0400)
    indexed_at_percentage NUMERIC -- The 'Indexed At' value from the CSV, stored as a decimal (e.g., 0% -> 0.00)
);

--values
-- Create core table
CREATE TABLE IF NOT EXISTS core.values (
    client_id INTEGER,
    household_business_name TEXT,
    active TEXT,
    last_name TEXT,
    first_name TEXT,
    email TEXT,
    email_spouse TEXT,
    values1 TEXT,
    values2 TEXT,
    values3 TEXT,
    values4 TEXT,
    values5 TEXT,
    values6 TEXT,
    accomplishments1 TEXT,
    accomplishments2 TEXT,
    accomplishments3 TEXT,
    accomplishments4 TEXT,
    relationships1 TEXT,
    relationships2 TEXT,
    relationships3 TEXT,
    relationships4 TEXT,
    goals1 TEXT,
    goals2 TEXT,
    goals3 TEXT,
    goals4 TEXT,
    goals5 TEXT,
    risk1 TEXT,
    risk2 TEXT,
    risk3 TEXT,
    risk4 TEXT,
    foundation1 TEXT,
    foundation2 TEXT,
    foundation3 TEXT,
    foundation4 TEXT,
    next_and_next_steward1 TEXT,
    next_and_next_steward2 TEXT,
    next_and_next_steward4 TEXT,
    process1 TEXT,
    process2 TEXT,
    process3 TEXT,
    process4 TEXT
);