--CREATE TABLE Statements for staging schema

--account_history
CREATE TABLE IF NOT EXISTS stg.account_history (
    client_id TEXT,
    account_id TEXT,
    as_of_date TEXT,
    value TEXT
);

--businesses
CREATE TABLE IF NOT EXISTS stg.businesses (
    client_id TEXT,
    fact_id TEXT,
    fact_type_name TEXT,
    sub_type TEXT,
    name TEXT,
    amount TEXT,
    amount_as_of TEXT,
    cost_basis TEXT
);

--charities
CREATE TABLE IF NOT EXISTS stg.charities (
    client_id TEXT,
    fact_id TEXT,
    name TEXT
);

--clients
CREATE TABLE IF NOT EXISTS stg.clients (
    client_id TEXT,
    client_name TEXT,
    first_name TEXT,
    last_name TEXT,
    hh_date_of_birth TEXT,
    gender TEXT,
    marital_status TEXT,
    citizenship TEXT,
    spouse_first_name TEXT,
    spouse_last_name TEXT,
    spouse_dob TEXT,
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
    emp_years_employed TEXT
);

--disability_ltc_insurance_accounts
CREATE TABLE IF NOT EXISTS stg.disability_ltc_insurance_accounts (
    client_id TEXT,
    account_id TEXT,
    account_name TEXT,
    account_number TEXT,
    total_value TEXT,
    amount_as_of TEXT,
    institution_name TEXT,
    benefit_amount TEXT,
    fact_type_name TEXT,
    sub_type TEXT,
    connected TEXT,
    purchase_date TEXT,
    premium_term_in_years TEXT,
    annual_premium TEXT,
    elimination_period TEXT,
    elimination_period_in_days TEXT,
    benefit_type TEXT,
    benefit_frequency TEXT,
    benefit_period TEXT,
    benefit_period_in_days TEXT,
    own_occupation TEXT,
    is_benefit_taxable TEXT,
    business_entity_id TEXT
);

--entity_interests
CREATE TABLE IF NOT EXISTS stg.entity_interests (
    client_id TEXT,
    account_id TEXT,
    interest_id TEXT,
    interest_owner_type TEXT,
    interest_type TEXT,
    interest_percent TEXT
);

--expenses
CREATE TABLE IF NOT EXISTS stg.expenses (
    client_id TEXT,
    expense_item TEXT,
    individual_full_name TEXT,
    annual_amount TEXT,
    end_actual_date TEXT,
    end_projection_date TEXT,
    end_type TEXT,
    institution_name TEXT,
    is_goal TEXT,
    start_actual_date TEXT,
    start_indexing_at TEXT,
    start_type TEXT,
    sub_type TEXT,
    type TEXT
);

--facts
CREATE TABLE IF NOT EXISTS stg.facts (
    client_id TEXT,
    fact_id TEXT,
    fact_type_name TEXT,
    sub_type TEXT,
    name TEXT,
    amount TEXT,
    amount_as_of TEXT
);

--flows
CREATE TABLE IF NOT EXISTS stg.flows (
    client_id TEXT,
    account_id TEXT,
    account_name TEXT,
    amount TEXT,
    retirement_amount TEXT,
    amount_as_of TEXT,
    institution_name TEXT,
    fact_type_name TEXT,
    sub_type TEXT
);

--holdings
CREATE TABLE IF NOT EXISTS stg.holdings (
    client_id TEXT,
    account_id TEXT,
    holdings_id TEXT,
    ticker TEXT,
    description TEXT,
    units TEXT,
    market_price TEXT,
    as_of TEXT,
    value TEXT,
    cost_basis TEXT,
    asset_class TEXT,
    holding_type TEXT
);

--incomes
CREATE TABLE IF NOT EXISTS stg.incomes (
    client_id TEXT,
    household_household_business_name TEXT,
    income_id TEXT,
    annual_amount TEXT,
    created_date TEXT,
    current_year_amount TEXT,
    deleted TEXT,
    end_type TEXT,
    end_value TEXT,
    income_frequency TEXT,
    income_name TEXT,
    income_type TEXT,
    is_self_employed TEXT,
    owner_type TEXT,
    start_actual_date TEXT,
    start_value TEXT
);

--investment_deposit_accounts
CREATE TABLE IF NOT EXISTS stg.investment_deposit_accounts (
    client_id TEXT,
    account_id TEXT,
    account_name TEXT,
    total_value TEXT,
    amount_as_of TEXT,
    institution_name TEXT,
    holdings_value TEXT,
    cash_balance TEXT,
    cost_basis TEXT,
    fact_type_name TEXT,
    sub_type TEXT,
    under_our_management TEXT
);

--liability_note_accounts
CREATE TABLE IF NOT EXISTS stg.liability_note_accounts (
    client_id TEXT,
    account_id TEXT,
    account_name TEXT,
    total_value TEXT,
    amount_as_of TEXT,
    institution_name TEXT,
    cash_balance TEXT,
    fact_type_name TEXT,
    sub_type TEXT,
    connected TEXT,
    under_our_management TEXT,
    repayment_type TEXT,
    original_loan_amount TEXT,
    loan_term_in_years TEXT,
    is_interest_deductible TEXT,
    interest_rate TEXT,
    loan_date TEXT,
    payment_frequency TEXT,
    number_of_payments TEXT,
    real_estate_id TEXT
);

--life_insurance_annuity_accounts
CREATE TABLE IF NOT EXISTS stg.life_insurance_annuity_accounts (
    client_id TEXT,
    account_id TEXT,
    account_name TEXT,
    account_number TEXT,
    total_value TEXT,
    amount_as_of TEXT,
    institution_name TEXT,
    holdings_value TEXT,
    cash_balance TEXT,
    margin_balance TEXT,
    cost_basis TEXT,
    death_benefit TEXT,
    fact_type_name TEXT,
    sub_type TEXT,
    under_our_management TEXT,
    purchase_date TEXT,
    premium_term_in_years TEXT,
    term_in_years TEXT,
    annual_premium TEXT
);

--medical_insurance_accounts
CREATE TABLE IF NOT EXISTS stg.medical_insurance_accounts (
    client_id TEXT,
    account_id TEXT,
    account_name TEXT,
    amount_as_of TEXT,
    institution_name TEXT,
    fact_type_name TEXT,
    sub_type TEXT,
    purchase_date TEXT,
    annual_premium TEXT,
    deductible TEXT
);

--personal_property_accounts
CREATE TABLE IF NOT EXISTS stg.personal_property_accounts (
    client_id TEXT,
    account_id TEXT,
    account_name TEXT,
    total_value TEXT,
    amount_as_of TEXT,
    cost_basis TEXT,
    fact_type_name TEXT
);

--property_casualty_insurance_accounts
CREATE TABLE IF NOT EXISTS stg.property_casualty_insurance_accounts (
    client_id TEXT,
    account_id TEXT,
    account_name TEXT,
    amount_as_of TEXT,
    institution_name TEXT,
    sub_type TEXT,
    connected TEXT,
    purchase_date TEXT,
    annual_premium TEXT,
    premium_term_in_years TEXT,
    replacement_value TEXT,
    renewal_date TEXT,
    maximum_annual_benefit TEXT
);

--real_estate_assets
CREATE TABLE IF NOT EXISTS stg.real_estate_assets (
    client_id TEXT,
    account_id TEXT,
    account_name TEXT,
    total_value TEXT,
    amount_as_of TEXT,
    cost_basis TEXT,
    sub_type TEXT,
    address1 TEXT,
    address2 TEXT,
    city TEXT,
    state TEXT,
    postal_code TEXT,
    purchase_year TEXT,
    purchase_amount TEXT
);

--savings
CREATE TABLE IF NOT EXISTS stg.savings (
    client_id TEXT, -- Loaded as text from CSV
    name TEXT,
    destination TEXT,
    account_id TEXT,
    starts TEXT,
    ends TEXT,
    amount TEXT,
    indexed_at TEXT -- Loaded as text from CSV (e.g., "0%")
);

--values
CREATE TABLE IF NOT EXISTS stg.values (
    client_id TEXT,
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
