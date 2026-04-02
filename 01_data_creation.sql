
/*Création de la base de données loan_portfolio_db*/
create database loan_portfolio_db;


CREATE TABLE customers (
    customer_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    province VARCHAR(50) NOT NULL,
    birth_date DATE,
    income NUMERIC(12,2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

/*
 * ON VEUT PAS DE DOUBLONS DANS LA TABLE "CUSTOMERS". L'IDENTITE UNIQUE DU CLIENT EST SONT PRENOM, NOM ET DATE DE NAISSANCE
*/
ALTER TABLE customers
ADD CONSTRAINT unique_customer_identity
UNIQUE (first_name, last_name, birth_date);

CREATE TABLE loans (
    loan_id SERIAL PRIMARY KEY,
    customer_id INT NOT NULL REFERENCES customers(customer_id),
    loan_type VARCHAR(30) NOT NULL,
    original_amount NUMERIC(12,2) NOT NULL,
    interest_rate NUMERIC(5,2) NOT NULL,
    term_months INT NOT NULL,
    start_date DATE NOT NULL,
    status VARCHAR(20) NOT NULL,
    current_balance NUMERIC(12,2) NOT NULL
);

CREATE TABLE payments (
    payment_id SERIAL PRIMARY KEY,
    loan_id INT NOT NULL REFERENCES loans(loan_id),
    payment_date DATE NOT NULL,
    payment_amount NUMERIC(12,2) NOT NULL,
    principal_amount NUMERIC(12,2) NOT NULL,
    interest_amount NUMERIC(12,2) NOT NULL
);

CREATE TABLE interest_rates (
    rate_id SERIAL PRIMARY KEY,
    rate_month DATE NOT NULL UNIQUE,
    benchmark_rate NUMERIC(5,2) NOT NULL
);


INSERT INTO customers (first_name, last_name, province, birth_date, income)
VALUES
('Marie', 'Gagnon', 'Quebec', '1994-05-12', 72000),
('Ali', 'Haddad', 'Quebec', '1988-11-03', 86000),
('Sofia', 'Martinez', 'Quebec', '2000-01-22', 54000),
('David', 'Tremblay', 'Quebec', '1991-07-19', 91000);

INSERT INTO customers (first_name, last_name, province, birth_date, income)
VALUES
('Julie', 'Roy', 'Quebec', '1998-04-14', 68000),
('Thomas', 'Nguyen', 'Quebec', '1995-09-02', 82000),
('Fatou', 'Diallo', 'Quebec', '1997-12-11', 59000),
('Marc', 'Pelletier', 'Quebec', '1989-03-27', 91000),
('Sarah', 'Johnson', 'Quebec', '1996-08-05', 76000),
('Karim', 'Benali', 'Quebec', '1993-01-18', 88000),
('Chloe', 'Martin', 'Quebec', '2001-06-23', 51000),
('Antoine', 'Gauthier', 'Quebec', '1990-10-09', 74000),
('Nadia', 'El Hadi', 'Quebec', '1987-02-14', 99000),
('Olivier', 'Tremblay', 'Quebec', '1994-11-30', 65000);

/*
 * ESSAYER D'INSERER UN CLIENT DEJA EXISTENT SANS SUCCES MAIS SANS SOULEVER D'ERREUR 
*/
INSERT INTO customers (first_name, last_name, province, birth_date, income)
VALUES ('Julie', 'Roy', 'Quebec', '1998-04-14', 70000)
ON CONFLICT (first_name, last_name, birth_date)
DO NOTHING;

INSERT INTO loans (customer_id, loan_type, original_amount, interest_rate, term_months, start_date, status, current_balance)
VALUES
(1, 'auto', 18000, 6.25, 60, '2023-06-01', 'active', 12400),
(2, 'mortgage', 320000, 5.10, 300, '2021-09-01', 'active', 287500),
(3, 'personal', 8000, 11.90, 36, '2024-02-15', 'active', 5600),
(4, 'auto', 25000, 5.75, 72, '2022-11-10', 'closed', 0);

INSERT INTO loans (customer_id, loan_type, original_amount, interest_rate, term_months, start_date, status, current_balance) 
VALUES
(5, 'auto', 24000, 6.15, 72, '2024-05-01', 'active', 21850),
(6, 'personal', 12000, 10.95, 48, '2023-11-15', 'active', 9350),
(7, 'mortgage', 365000, 5.05, 300, '2022-04-01', 'active', 342700),
(8, 'auto', 28000, 6.35, 60, '2024-02-01', 'active', 19950),
(9, 'student', 18000, 4.75, 84, '2021-09-01', 'active', 12400),
(10, 'line_of_credit', 15000, 8.90, 36, '2024-08-10', 'active', 11200),
(11, 'personal', 6000, 12.25, 24, '2025-01-20', 'active', 5600),
(12, 'auto', 32000, 5.85, 72, '2022-06-12', 'closed', 0),
(13, 'mortgage', 410000, 4.95, 300, '2021-12-01', 'active', 389500),
(14, 'personal', 9000, 11.40, 36, '2024-03-18', 'active', 7050);

INSERT INTO payments (loan_id, payment_date, payment_amount, principal_amount, interest_amount)
VALUES
(1, '2024-01-01', 420.00, 360.00, 60.00),
(1, '2024-02-01', 420.00, 362.00, 58.00),
(2, '2024-01-01', 1870.00, 1500.00, 370.00),
(3, '2024-03-15', 260.00, 170.00, 90.00),
(4, '2023-12-10', 0.00, 0.00, 0.00);

INSERT INTO payments (loan_id, payment_date, payment_amount, principal_amount, interest_amount) 
VALUES
(5, '2024-06-01', 420.00, 320.00, 100.00),
(5, '2024-07-01', 420.00, 322.00, 98.00),
(6, '2023-12-15', 360.00, 280.00, 80.00),
(7, '2024-05-01', 1950.00, 1600.00, 350.00),
(8, '2024-03-01', 510.00, 395.00, 115.00),
(9, '2024-01-15', 260.00, 190.00, 70.00),
(10, '2024-09-10', 340.00, 250.00, 90.00),
(11, '2025-02-20', 310.00, 250.00, 60.00),
(13, '2024-01-01', 2200.00, 1750.00, 450.00),
(14, '2024-04-18', 280.00, 210.00, 70.00);

INSERT INTO interest_rates (rate_month, benchmark_rate)
VALUES
('2023-06-01', 4.75),
('2023-07-01', 4.75),
('2023-08-01', 5.00),
('2023-09-01', 5.00),
('2023-10-01', 5.25);

INSERT INTO interest_rates (rate_month, benchmark_rate) 
VALUES
('2024-01-01', 5.00),
('2024-02-01', 5.00),
('2024-03-01', 5.00),
('2024-04-01', 5.00),
('2024-05-01', 5.00),
('2024-06-01', 4.75);
