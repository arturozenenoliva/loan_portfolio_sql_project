-- CONCLUSIONS DE L'ANALYSE A LA FIN DU SCRIPT

/* VUE GLOBALE DU PORTEFEUILLE */
select 
	COUNT(*) as nb_prets,
	SUM(original_amount) as montant_total_initial,
	SUM(current_balance) as solde_total_actuel,
	AVG(interest_rate) as taux_interet_moyen
from loans;

/*
 * VOLUME INITIAL TOTAL ET MOYEN PAR TYPE DE PRET
 * BUT: VOIR QUELS PRODUITS DOMINENT LE PORTEFEUILLE
*/
select 
	loan_type,
	COUNT(*) as nb_prets,
	SUM(original_amount) as montant_total_initial,
	AVG(original_amount) as montant_moyen_initial
from loans
group by loan_type
order by nb_prets desc;

/*
 * REPARTITION DES PRETS PAR STATUT
 * BUT: SAVOIR COMBIEN DE PRETS SONT ACTIFS, FERMES OU PROBLEMATIQUES
*/
select 
    status,
    COUNT(*) as nb_prets,
    SUM(current_balance) as solde_total_actuel
from loans
group by status
order by nb_prets desc;

/*
 * PRETS LES PLUS IMPORTANTS PAR SOLDE RESTANT
 * BUT: REPERER LES EXPOSITIONS LES PLUS IMPORTANTES
*/
select 
    loan_id,
    customer_id,
    loan_type,
    original_amount,
    current_balance,
    interest_rate
from loans 
order by current_balance desc
limit 10;

/*
 * VALEUR TOTALE EMPRUNTEE PAR CLIENT
 * BUT: IDENTIFIER LES CLIENTS A FORTE VALEUR
*/
select
    c.customer_id,
    c.first_name,
    c.last_name,
    COUNT(l.loan_id) as nb_prets,
    SUM(l.original_amount) as montant_total_emprunte,
    SUM(l.current_balance) as solde_total_actuel
from customers c
join loans l on c.customer_id = l.customer_id
group by c.customer_id, c.first_name, c.last_name
order by montant_total_emprunte desc;

/*
 * PAIEMENTS TOTAUX PAR PRET
 * BUT: SUIVRE L’EXECUTION DES REMBOURSEMENTS
*/
select
    l.loan_id,
    l.loan_type,
    l.original_amount,
    SUM(p.payment_amount) as total_paye,
    SUM(p.principal_amount) as principal_total,
    SUM(p.interest_amount) as interet_total
from loans l
left join payments p on l.loan_id = p.loan_id
group by l.loan_id, l.loan_type, l.original_amount
order by total_paye desc;

/*
 * TAUX DE REMBOURSEMENT PAR PRET
 * BUT: MESURER L’AVANCEMENT DU REMBOURSEMENT
*/
select
    l.loan_id,
    l.original_amount,
    l.current_balance,
    COALESCE(SUM(p.payment_amount), 0) as total_paye,
    ROUND(
        COALESCE(SUM(p.payment_amount), 0) / NULLIF(l.original_amount, 0) * 100,
        2
    ) as pct_rembourse
from loans l
left join payments p on l.loan_id = p.loan_id
group by l.loan_id, l.original_amount, l.current_balance
order by pct_rembourse desc;

/*
 * CLIENTS AVEC PLUSIEURS PRETS
 * BUT: SEGMENTATION CLIENTS, CROSS-SELL, CONCENTRATION DU RISQUE
*/
select
    c.customer_id,
    c.first_name,
    c.last_name,
    COUNT(l.loan_id) as nb_prets
from customers c
join loans l on c.customer_id = l.customer_id
group by c.customer_id, c.first_name, c.last_name
having COUNT(l.loan_id) > 1
order by nb_prets desc;

/*
 * EVOLUTION DES TAUX DE REFERENCE DANS LE TEMPS
 * BUT: SUIVRE LE CONTEXTE DE MARCHE
*/
select
    rate_month,
    benchmark_rate
from interest_rates
order by rate_month;

/*
 * COMPARATION DES TAUX DES PRETS AU TAUX DE REFERENCE
 * BUT: VOIR QUELS PRETS SONT AU-DESSUS OU EN DESSOUS DU MARCHE
*/
select
    l.loan_id,
    l.loan_type,
    l.interest_rate,
    ir.benchmark_rate,
    ROUND(l.interest_rate - ir.benchmark_rate, 2) as ecart_au_marche
from loans l
join interest_rates ir
    on DATE_TRUNC('month', l.start_date) = DATE_TRUNC('month', ir.rate_month)
order by ecart_au_marche desc;

/*
 * CLASSIFICATION DU RISQUE PAR PRET
*/
SELECT
    loan_id,
    original_amount,
    current_balance,
    interest_rate,
    CASE
        WHEN current_balance = 0 THEN 'closed'
        WHEN interest_rate >= 10 THEN 'high risk'
        WHEN interest_rate >= 6 THEN 'medium risk'
        ELSE 'low risk'
    END AS risk_category
FROM loans;

/*
 * TAUX DE REMBOURSEMENT
*/
SELECT
    l.loan_id,
    l.original_amount,
    l.current_balance,
    COALESCE(p.total_paye, 0) AS total_paye,
    ROUND(COALESCE(p.total_paye, 0) / NULLIF(l.original_amount, 0) * 100, 2) AS pct_rembourse
FROM loans l
LEFT JOIN (
    SELECT
        loan_id,
        SUM(payment_amount) AS total_paye
    FROM payments
    GROUP BY loan_id
) p ON l.loan_id = p.loan_id
ORDER BY pct_rembourse DESC;

/*
 * RATIO INTERET / PRINCIPAL PAR PRET
*/
SELECT
    loan_id,
    SUM(interest_amount) AS total_interet,
    SUM(principal_amount) AS total_principal,
    ROUND(
        SUM(interest_amount) / NULLIF(SUM(principal_amount), 0),
        2
    ) AS ratio_interet_principal
FROM payments
GROUP BY loan_id
ORDER BY ratio_interet_principal DESC;

/*
 * VUE CTE POUR RESUMER LES PRETS
*/
WITH loan_summary AS (
    SELECT
        l.loan_id,
        l.customer_id,
        l.loan_type,
        l.original_amount,
        l.current_balance,
        COALESCE(SUM(p.payment_amount), 0) AS total_paye
    FROM loans l
    LEFT JOIN payments p ON l.loan_id = p.loan_id
    GROUP BY l.loan_id, l.customer_id, l.loan_type, l.original_amount, l.current_balance
)
SELECT
    loan_id,
    customer_id,
    loan_type,
    original_amount,
    current_balance,
    total_paye,
    ROUND(total_paye / NULLIF(original_amount, 0) * 100, 2) AS pct_rembourse
FROM loan_summary
ORDER BY pct_rembourse DESC;

/*
 * KPIs
*/
CREATE OR REPLACE VIEW vw_portfolio_kpis AS
WITH payment_summary AS (
    SELECT
        loan_id,
        SUM(payment_amount) AS total_paid,
        SUM(principal_amount) AS total_principal_paid,
        SUM(interest_amount) AS total_interest_paid
    FROM payments
    GROUP BY loan_id
)
SELECT
    COUNT(DISTINCT c.customer_id) AS nb_clients,
    COUNT(DISTINCT l.loan_id) AS nb_prets,
    SUM(l.original_amount) AS montant_total_initial,
    SUM(l.current_balance) AS solde_total_actuel,
    AVG(l.interest_rate) AS taux_interet_moyen,
    COUNT(*) FILTER (WHERE l.status = 'active') AS nb_prets_actifs,
    COUNT(*) FILTER (WHERE l.status = 'closed') AS nb_prets_fermes,
    COALESCE(SUM(ps.total_paid), 0) AS total_paiements,
    COALESCE(SUM(ps.total_principal_paid), 0) AS total_principal_rembourse,
    COALESCE(SUM(ps.total_interest_paid), 0) AS total_interet_percu,
    ROUND(
        COALESCE(SUM(ps.total_principal_paid), 0) / NULLIF(SUM(l.original_amount), 0) * 100,
        2
    ) AS pct_principal_rembourse
FROM customers c
JOIN loans l ON c.customer_id = l.customer_id
LEFT JOIN payment_summary ps ON l.loan_id = ps.loan_id;

SELECT 
	nb_clients, 
	nb_prets, 
	montant_total_initial,
	solde_total_actuel,
	taux_interet_moyen,
	pct_principal_rembourse
FROM vw_portfolio_kpis;


/*
 * SEGMENTS DE RISQUE 
*/
CREATE OR REPLACE VIEW vw_loan_risk_segments AS
SELECT
    loan_id,
    customer_id,
    loan_type,
    original_amount,
    current_balance,
    interest_rate,
    ROUND(current_balance / NULLIF(original_amount, 0), 2) AS balance_ratio,
    CASE
        WHEN status = 'closed' THEN 'closed'
        WHEN interest_rate >= 10 OR current_balance / NULLIF(original_amount, 0) >= 0.85 THEN 'high risk'
        WHEN interest_rate >= 7 OR current_balance / NULLIF(original_amount, 0) >= 0.65 THEN 'medium risk'
        ELSE 'low risk'
    END AS risk_segment
FROM loans;

SELECT 
	loan_id, 
	loan_type, 
	risk_segment, 
	current_balance 
FROM vw_loan_risk_segments
ORDER BY risk_segment DESC, current_balance DESC;


/*
 * SEGMENTS DE CLIENTS 
*/
CREATE OR REPLACE VIEW vw_customer_segments AS
WITH customer_summary AS (
    SELECT
        c.customer_id,
        c.first_name,
        c.last_name,
        COUNT(l.loan_id) AS nb_prets,
        SUM(l.original_amount) AS montant_total_emprunte,
        SUM(l.current_balance) AS solde_total_actuel
    FROM customers c
    LEFT JOIN loans l ON c.customer_id = l.customer_id
    GROUP BY c.customer_id, c.first_name, c.last_name
)
SELECT
    *,
    CASE
        WHEN solde_total_actuel >= 200000 THEN 'large exposure'
        WHEN solde_total_actuel >= 50000 THEN 'medium exposure'
        ELSE 'small exposure'
    END AS customer_segment
FROM customer_summary;

SELECT * FROM vw_customer_segments;

