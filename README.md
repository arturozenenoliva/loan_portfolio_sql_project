# Projet SQL - Portefeuille de Prêts 

Construit avec PostgreSQL.  
L’objectif est d’analyser un petit portefeuille de prêts à l’aide de tables relationnelles, de jointures, d’agrégations, de CTE et de fonctions de fenêtre.

## Objectifs

- Structurer une base de données relationnelle simple mais réaliste.
- Analyser un portefeuille de prêts.
- Calculer des KPI financiers.
- Segmenter les prêts par niveau de risque.
- Produire des requêtes proches d’un usage en entreprise.

## Technologies

- PostgreSQL
- SQL
- DBeaver

## Schéma de la base

- `customers` : informations sur les clients
- `loans` : caractéristiques des prêts
- `payments` : historique des paiements
- `interest_rates` : taux de référence mensuels

## Structure du projet

```text
loan_portfolio_sql_project/
├── data_creation.sql
├── analysis_queries.sql
├── conclusions.md
└── screenshots/
