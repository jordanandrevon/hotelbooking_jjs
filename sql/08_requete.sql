-- ============================================================================
-- PROJET       : HOTEL BOOKING JJS
-- RESPONSABLE  : JOSEPHINE - SQL ET ANALYSE METIER
-- QUESTION N°8 : Quels sont les 10 pays generant le plus de reservations,
--                et quels sont leurs taux d'annulation ?
-- MOTEUR       : Google BigQuery (GoogleSQL)
-- TABLE SOURCE : `hotel-booking-jjs.hotel_booking.reservations`
-- PERIMETRE    : 119 208 reservations, selon les controles executes.

-- ============================================================================
-- REQUETE 1 - CONTROLE QUALITE DE COUNTRY
-- ============================================================================
-- COUNT(*) : compte toutes les reservations.
-- COUNT(DISTINCT country) : compte les codes pays differents non NULL.
-- COUNTIF(...) : compte les codes pays absents ou vides.
-- RESULTAT OBSERVE : 119 208 reservations ; 178 codes pays ; 0 manquant.
SELECT
    COUNT(*) AS total_reservations,
    COUNT(DISTINCT country) AS nombre_pays,
    COUNTIF(country IS NULL OR TRIM(country) = '') AS pays_manquants
FROM `hotel-booking-jjs.hotel_booking.reservations`;

-- ============================================================================
-- REQUETE 2 - TOP 10 SIMPLE, SANS FONCTION DE FENETRAGE
-- ============================================================================
-- GROUP BY country : une ligne par pays.
-- COUNTIF(is_canceled = 1) : nombre de reservations annulees.
-- SAFE_DIVIDE : evite une erreur si le denominateur est nul.
-- ORDER BY : trie par volume decroissant ; country departage les egalites.
-- LIMIT 10 : retourne exactement dix lignes si au moins dix pays existent.
SELECT
    country,
    COUNT(*) AS total_reservations,
    COUNTIF(is_canceled = 1) AS reservations_annulees,
    ROUND(100 * SAFE_DIVIDE(COUNTIF(is_canceled = 1), COUNT(*)), 2)
        AS taux_annulation_pct
FROM `hotel-booking-jjs.hotel_booking.reservations`
WHERE country IS NOT NULL AND TRIM(country) != ''
GROUP BY country
ORDER BY total_reservations DESC, country ASC
LIMIT 10;

-- ============================================================================
-- REQUETE 3 - TOP 10 AVEC WITH ET RANK()
-- ============================================================================
-- WITH : cree des CTE (resultats intermediaires nommes), reutilisables
--        uniquement pendant cette instruction SQL.
-- statistiques_pays : agrege les reservations par pays.
-- classement_pays : attribue un rang selon le nombre de reservations.
-- RANK() OVER (ORDER BY ... DESC) : meme rang en cas d'egalite ;
--        des rangs peuvent alors etre sautes.
-- WHERE rang <= 10 : inclut tous les ex aequo au dixieme rang ;
--        il peut donc y avoir plus de dix lignes en cas d'egalite.
WITH statistiques_pays AS (
    SELECT
        country,
        COUNT(*) AS total_reservations,
        COUNTIF(is_canceled = 1) AS reservations_annulees,
        ROUND(100 * SAFE_DIVIDE(COUNTIF(is_canceled = 1), COUNT(*)), 2)
            AS taux_annulation_pct
    FROM `hotel-booking-jjs.hotel_booking.reservations`
    WHERE country IS NOT NULL AND TRIM(country) != ''
    GROUP BY country
),
classement_pays AS (
    SELECT
        country,
        total_reservations,
        reservations_annulees,
        taux_annulation_pct,
        RANK() OVER (ORDER BY total_reservations DESC) AS rang
    FROM statistiques_pays
)
SELECT
    rang,
    country,
    total_reservations,
    reservations_annulees,
    taux_annulation_pct
FROM classement_pays
WHERE rang <= 10
ORDER BY rang, country;

-- ============================================================================
-- RESULTATS OBSERVES - REQUETE 3 
-- ============================================================================
-- Rang  Code  Reservations  Annulations  Taux (%)
--   1   PRT       48 482       27 505      56.73
--   2   GBR       12 119        2 452      20.23
--   3   FRA       10 401        1 933      18.58
--   4   ESP        8 560        2 177      25.43
--   5   DEU        7 285        1 218      16.72
--   6   ITA        3 761        1 333      35.44
--   7   IRL        3 374          832      24.66
--   8   BEL        2 342          474      20.24
--   9   BRA        2 222          830      37.35
--  10   NLD        2 103          387      18.40
-- Le classement repose sur le VOLUME, et non sur le taux d'annulation.

-- ============================================================================
-- REQUETE 4 - COMPARAISON DES MEMES PAYS ENTRE LES DEUX HOTELS
-- ============================================================================
-- CTE reservations_pays : nombre de reservations par pays (tous hotels).
-- CTE classement_pays : rang global avec RANK().
-- CTE statistiques_hotel : volume et taux par couple (hotel, pays).
-- INNER JOIN : relie les statistiques par hotel au classement global
--              a l'aide de la cle commune country.
-- Avantage : compare les MEMES pays dans City Hotel et Resort Hotel,
--            plutot que deux Top 10 independants.
WITH reservations_pays AS (
    SELECT
        country,
        COUNT(*) AS total_reservations
    FROM `hotel-booking-jjs.hotel_booking.reservations`
    WHERE country IS NOT NULL AND TRIM(country) != ''
    GROUP BY country
),
classement_pays AS (
    SELECT
        country,
        total_reservations,
        RANK() OVER (ORDER BY total_reservations DESC) AS rang
    FROM reservations_pays
),
statistiques_hotel AS (
    SELECT
        hotel,
        country,
        COUNT(*) AS total_reservations,
        COUNTIF(is_canceled = 1) AS reservations_annulees,
        ROUND(100 * SAFE_DIVIDE(COUNTIF(is_canceled = 1), COUNT(*)), 2)
            AS taux_annulation_pct
    FROM `hotel-booking-jjs.hotel_booking.reservations`
    WHERE country IS NOT NULL AND TRIM(country) != ''
    GROUP BY hotel, country
)
SELECT
    c.rang,
    s.country,
    s.hotel,
    s.total_reservations,
    s.reservations_annulees,
    s.taux_annulation_pct
FROM statistiques_hotel AS s
INNER JOIN classement_pays AS c
    ON s.country = c.country
WHERE c.rang <= 10
ORDER BY c.rang, s.hotel;

-- ============================================================================
-- RESULTATS OBSERVES - REQUETE 4 
-- ============================================================================
-- Pays    City: reservations / taux    Resort: reservations / taux
-- PRT       30 860 / 65.03 %             17 622 / 42.21 %
-- GBR        5 307 / 29.41 %              6 812 / 13.08 %
-- FRA        8 791 / 19.59 %              1 610 / 13.11 %
-- ESP        4 604 / 28.80 %              3 956 / 21.51 %
-- DEU        6 082 / 17.63 %              1 203 / 12.14 %
-- ITA        3 302 / 37.95 %                459 / 17.43 %
-- IRL        1 208 / 33.11 %              2 166 / 19.94 %
-- BEL        1 894 / 21.91 %                448 / 13.17 %
-- BRA        1 792 / 40.68 %                430 / 23.49 %
-- NLD        1 589 / 20.83 %                514 / 10.89 %
-- Dans chacun des dix pays, le taux City Hotel est superieur au taux Resort.

-- ============================================================================
-- REQUETE 5 - CONTROLES DE COHERENCE DU TOP 10
-- ============================================================================
-- Objectif : verifier le poids du Top 10 et la concordance avec les exports.
-- Les taux sont calcules sur les totaux bruts (moyennes ponderees),
-- et NON en faisant la moyenne simple des taux par pays.
WITH statistiques_pays AS (
    SELECT country, COUNT(*) AS total_reservations
    FROM `hotel-booking-jjs.hotel_booking.reservations`
    WHERE country IS NOT NULL AND TRIM(country) != ''
    GROUP BY country
),
classement_pays AS (
    SELECT
        country,
        RANK() OVER (ORDER BY total_reservations DESC) AS rang
    FROM statistiques_pays
),
reservations_top10 AS (
    SELECT r.hotel, r.is_canceled
    FROM `hotel-booking-jjs.hotel_booking.reservations` AS r
    INNER JOIN classement_pays AS c ON r.country = c.country
    WHERE c.rang <= 10
)
SELECT
    hotel,
    COUNT(*) AS reservations_top10,
    COUNTIF(is_canceled = 1) AS annulations_top10,
    ROUND(100 * SAFE_DIVIDE(COUNTIF(is_canceled = 1), COUNT(*)), 2)
        AS taux_annulation_top10_pct
FROM reservations_top10
GROUP BY hotel
UNION ALL
SELECT
    'TOTAL TOP 10' AS hotel,
    COUNT(*) AS reservations_top10,
    COUNTIF(is_canceled = 1) AS annulations_top10,
    ROUND(100 * SAFE_DIVIDE(COUNTIF(is_canceled = 1), COUNT(*)), 2)
        AS taux_annulation_top10_pct
FROM reservations_top10
ORDER BY hotel;

-- ============================================================================
-- CONCLUSION METIER - QUESTION N°8
-- ============================================================================
-- 1) Les dix principaux codes pays representent 84.43 % des reservations.
-- 2) Le Portugal (PRT) arrive en tete avec 48 482 reservations (40.67 %
--    de l'ensemble) et un taux d'annulation de 56.73 %.
-- 3) Pour chacun des dix principaux pays, City Hotel affiche un taux
--    d'annulation superieur a celui de Resort Hotel.
-- 4) Pour PRT : City Hotel = 65.03 % ; Resort Hotel = 42.21 % ;
--    difference = 22.82 points de pourcentage.
-- 5) Il s'agit d'associations descriptives, pas de preuves de causalite.
--    Le code pays ne doit pas servir seul a penaliser une clientele.
--
-- RECOMMANDATIONS :
-- - Suivre volumes ET taux d'annulation par pays et par hotel.
-- - Approfondir les differences par market_segment, lead_time et
--   deposit_type, avant toute decision operationnelle.
-- - Integrer un comparatif geographique dans Looker Studio.
-- - Verifier la validite des codes pays pour les cartes geographiques.
-- - Ne pas assimiler automatiquement annulation et perte de revenu.
-- ============================================================================
