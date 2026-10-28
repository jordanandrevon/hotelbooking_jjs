-- =====================================================================
-- PROJET : HOTEL BOOKING JJS
-- =====================================================================
--
-- RESPONSABLE : Josephine
-- OUTIL       : Google BigQuery
-- LANGAGE     : SQL - GoogleSQL
-- ETAPE       : A3.4 - ANALYSE METIER
--
-- FICHIER     : sql/04_requête.sql
--
-- QUESTION METIER N°4 :
-- Comment le délai entre la réservation et la date d'arrivée
-- (lead_time) influence-t-il les annulations ?
--
-- SOURCE :
-- Projet BigQuery : hotel-booking-jjs
-- Dataset         : hotel_booking
-- Table           : reservations
--
-- TABLE COMPLETE :
-- `hotel-booking-jjs.hotel_booking.reservations`
--
-- VOLUME DE DONNEES :
-- 119208 réservations
--
-- OBJECTIFS :
--
-- 1. Comprendre la variable lead_time.
-- 2. Regrouper les réservations par tranche de délai.
-- 3. Calculer le taux d'annulation pour chaque tranche.
-- 4. Comparer City Hotel et Resort Hotel.
-- 5. Identifier les tendances et les risques métier.
-- 6. Proposer des recommandations pour les hôtels.
--
-- =====================================================================



-- =====================================================================
-- PARTIE 1 : COMPRENDRE LES VARIABLES UTILISEES
-- =====================================================================

-- VARIABLE 1 : lead_time
--
-- Définition :
-- Nombre de jours entre la date de réservation
-- et la date d'arrivée prévue du client.
--
-- Exemples :
--
-- lead_time = 0
-- Le client réserve pour une arrivée le jour même.
--
-- lead_time = 7
-- Le client réserve 7 jours avant son arrivée.
--
-- lead_time = 90
-- Le client réserve 90 jours avant son arrivée.
--
-- lead_time = 200
-- Le client réserve 200 jours avant son arrivée.
--
-- Type BigQuery : INTEGER


-- VARIABLE 2 : is_canceled
--
-- Définition :
-- Indique si une réservation a été annulée.
--
-- 0 = réservation non annulée
-- 1 = réservation annulée
--
-- Type BigQuery : INTEGER


-- VARIABLE 3 : hotel
--
-- Définition :
-- Type d'établissement hôtelier.
--
-- City Hotel   = hôtel urbain
-- Resort Hotel = hôtel de vacances
--
-- Type BigQuery : STRING



-- =====================================================================
-- PARTIE 2 : CONTROLE EXPLORATOIRE DU LEAD_TIME
-- =====================================================================
--
-- OBJECTIF :
-- Comprendre les valeurs présentes dans lead_time.
--
-- Nous allons calculer :
--
-- - Le nombre total de réservations.
-- - Le délai minimum.
-- - Le délai maximum.
-- - Le délai moyen.
--
-- FONCTIONS UTILISEES :
--
-- COUNT(*) : compte toutes les lignes.
-- MIN()    : recherche la valeur minimale.
-- MAX()    : recherche la valeur maximale.
-- AVG()    : calcule la moyenne.
-- ROUND()  : arrondit un résultat numérique.
--
-- =====================================================================


SELECT

    COUNT(*) AS total_reservations,

    MIN(lead_time) AS delai_minimum,

    MAX(lead_time) AS delai_maximum,

    ROUND(AVG(lead_time), 2) AS delai_moyen

FROM `hotel-booking-jjs.hotel_booking.reservations`;


-- INTERPRETATION :
--
-- Cette requête permet de comprendre l'étendue
-- des délais de réservation présents dans les données.
--
-- Elle permet également de détecter d'éventuelles
-- valeurs incohérentes, par exemple un délai négatif.
--
-- Le résultat doit être vérifié dans BigQuery
-- avant d'être documenté définitivement.



-- =====================================================================
-- PARTIE 3 : CREATION DES TRANCHES DE LEAD_TIME
-- =====================================================================
--
-- OBJECTIF :
--
-- Transformer une variable numérique continue
-- en catégories faciles à analyser.
--
-- Nous allons créer cinq groupes :
--
-- 1. Dernière minute : 0 à 7 jours
-- 2. Court terme     : 8 à 30 jours
-- 3. Moyen terme     : 31 à 90 jours
-- 4. Long terme      : 91 à 180 jours
-- 5. Très long terme : plus de 180 jours
--
-- METHODE :
--
-- Utilisation de CASE WHEN.
--
-- CASE WHEN fonctionne comme une série de conditions.
--
-- Exemple :
--
-- Si lead_time <= 7
-- Alors catégorie = Dernière minute.
--
-- Sinon, si lead_time <= 30
-- Alors catégorie = Court terme.
--
-- Et ainsi de suite.
--
-- =====================================================================


SELECT

    lead_time,

    CASE

        WHEN lead_time BETWEEN 0 AND 7
            THEN '1. Dernière minute (0-7 jours)'

        WHEN lead_time BETWEEN 8 AND 30
            THEN '2. Court terme (8-30 jours)'

        WHEN lead_time BETWEEN 31 AND 90
            THEN '3. Moyen terme (31-90 jours)'

        WHEN lead_time BETWEEN 91 AND 180
            THEN '4. Long terme (91-180 jours)'

        WHEN lead_time > 180
            THEN '5. Très long terme (>180 jours)'

        ELSE 'Non renseigné ou invalide'

    END AS tranche_lead_time,

    is_canceled

FROM `hotel-booking-jjs.hotel_booking.reservations`

LIMIT 20;


-- RESULTAT :
--
-- Cette requête affiche un échantillon de 20 réservations.
--
-- Pour chaque réservation, nous obtenons :
--
-- lead_time
-- tranche_lead_time
-- is_canceled
--
-- EXEMPLE :
--
-- lead_time = 7
-- tranche = Dernière minute
--
-- lead_time = 23
-- tranche = Court terme
--
-- lead_time = 85
-- tranche = Moyen terme
--
-- lead_time = 342
-- tranche = Très long terme
--
-- ATTENTION :
--
-- LIMIT 20 affiche uniquement 20 lignes.
-- Ce n'est pas une analyse statistique complète.
--
-- Cette requête sert à vérifier que les catégories
-- sont correctement attribuées.



-- =====================================================================
-- PARTIE 4 : ANALYSE GLOBALE DU TAUX D'ANNULATION
-- =====================================================================
--
-- QUESTION :
--
-- Comment le délai de réservation influence-t-il
-- le taux d'annulation ?
--
-- OBJECTIF :
--
-- Calculer pour chaque tranche :
--
-- 1. Le nombre total de réservations.
-- 2. Le nombre de réservations annulées.
-- 3. Le taux d'annulation en pourcentage.
--
-- FORMULE :
--
-- Taux d'annulation =
--
-- (Nombre de réservations annulées /
--  Nombre total de réservations) * 100
--
-- EXEMPLE :
--
-- 100 réservations
-- 30 annulations
--
-- Taux = (30 / 100) * 100 = 30 %
--
-- =====================================================================


-- ETAPE 1 :
-- Création d'une CTE pour classer les réservations.
--
-- Une CTE (Common Table Expression) est une
-- table temporaire logique définie avec WITH.
--
-- Elle permet d'organiser une requête complexe
-- en plusieurs étapes plus faciles à comprendre.


WITH reservations_classees AS (

    SELECT

        lead_time,

        is_canceled,

        CASE

            WHEN lead_time BETWEEN 0 AND 7
                THEN '1. Dernière minute (0-7 jours)'

            WHEN lead_time BETWEEN 8 AND 30
                THEN '2. Court terme (8-30 jours)'

            WHEN lead_time BETWEEN 31 AND 90
                THEN '3. Moyen terme (31-90 jours)'

            WHEN lead_time BETWEEN 91 AND 180
                THEN '4. Long terme (91-180 jours)'

            WHEN lead_time > 180
                THEN '5. Très long terme (>180 jours)'

            ELSE 'Non renseigné ou invalide'

        END AS tranche_lead_time

    FROM `hotel-booking-jjs.hotel_booking.reservations`

)


-- ETAPE 2 :
-- Calcul des indicateurs pour chaque tranche.


SELECT

    tranche_lead_time,

    -- Nombre total de réservations
    COUNT(*) AS total_reservations,

    -- Nombre de réservations annulées
    COUNTIF(is_canceled = 1) AS reservations_annulees,

    -- Calcul du taux d'annulation
    ROUND(

        SAFE_DIVIDE(

            COUNTIF(is_canceled = 1),

            COUNT(*)

        ) * 100,

        2

    ) AS taux_annulation_pct


FROM reservations_classees


-- Regrouper les réservations par tranche
GROUP BY tranche_lead_time


-- Afficher les catégories dans l'ordre chronologique
ORDER BY tranche_lead_time;



-- =====================================================================
-- RESULTATS OBTENUS DANS BIGQUERY
-- =====================================================================
--
-- TRANCHE                    RESERVATIONS  ANNULEES   TAUX
--
-- 0-7 jours                      19635       1885      9.60 %
--
-- 8-30 jours                     18945       5283     27.89 %
--
-- 31-90 jours                    29528      11140     37.73 %
--
-- 91-180 jours                   26420      11819     44.74 %
--
-- Plus de 180 jours              24680      14071     57.01 %
--
-- TOTAL                         119208      44198
--
-- =====================================================================



-- =====================================================================
-- INTERPRETATION METIER : ANALYSE GLOBALE
-- =====================================================================
--
-- CONSTAT 1 :
--
-- Le taux d'annulation augmente avec le délai
-- de réservation.
--
-- Les réservations effectuées entre 0 et 7 jours
-- avant l'arrivée présentent un taux d'annulation
-- de 9.60 %.
--
-- Les réservations effectuées plus de 180 jours
-- avant l'arrivée présentent un taux de 57.01 %.
--
--
-- CONSTAT 2 :
--
-- Les réservations très anticipées présentent
-- les taux d'annulation les plus élevés.
--
-- ECART :
--
-- 57.01 - 9.60 = 47.41 points de pourcentage.
--
--
-- CONCLUSION :
--
-- Il existe une association positive entre
-- le délai de réservation et le taux d'annulation.
--
-- Plus les réservations sont effectuées tôt,
-- plus leur taux d'annulation observé est élevé.
--
-- ATTENTION :
--
-- Cette analyse descriptive ne démontre pas
-- une relation de causalité.
--
-- =====================================================================



-- =====================================================================
-- PARTIE 5 : COMPARAISON CITY HOTEL VS RESORT HOTEL
-- =====================================================================
--
-- QUESTION :
--
-- L'influence du lead_time est-elle identique
-- pour les deux établissements ?
--
-- OBJECTIF :
--
-- Comparer les taux d'annulation par tranche
-- de lead_time pour :
--
-- - City Hotel
-- - Resort Hotel
--
-- Nous allons ajouter la variable hotel
-- à notre analyse précédente.
--
-- =====================================================================


WITH reservations_classees AS (

    SELECT

        hotel,

        lead_time,

        is_canceled,

        CASE

            WHEN lead_time BETWEEN 0 AND 7
                THEN '1. Dernière minute (0-7 jours)'

            WHEN lead_time BETWEEN 8 AND 30
                THEN '2. Court terme (8-30 jours)'

            WHEN lead_time BETWEEN 31 AND 90
                THEN '3. Moyen terme (31-90 jours)'

            WHEN lead_time BETWEEN 91 AND 180
                THEN '4. Long terme (91-180 jours)'

            WHEN lead_time > 180
                THEN '5. Très long terme (>180 jours)'

            ELSE 'Non renseigné ou invalide'

        END AS tranche_lead_time

    FROM `hotel-booking-jjs.hotel_booking.reservations`

)


SELECT

    -- Type d'établissement
    hotel,

    -- Catégorie du délai de réservation
    tranche_lead_time,

    -- Nombre total de réservations
    COUNT(*) AS total_reservations,

    -- Nombre d'annulations
    COUNTIF(is_canceled = 1) AS reservations_annulees,

    -- Taux d'annulation en pourcentage
    ROUND(

        SAFE_DIVIDE(

            COUNTIF(is_canceled = 1),

            COUNT(*)

        ) * 100,

        2

    ) AS taux_annulation_pct


FROM reservations_classees


-- Regrouper par hôtel et tranche
GROUP BY

    hotel,

    tranche_lead_time


-- Trier les résultats par hôtel puis par tranche
ORDER BY

    hotel,

    tranche_lead_time;



-- =====================================================================
-- RESULTATS OBTENUS : CITY HOTEL
-- =====================================================================
--
-- TRANCHE               RESERVATIONS  ANNULEES   TAUX
--
-- 0-7 jours                 10703        1304     12.18 %
--
-- 8-30 jours                12541        3880     30.94 %
--
-- 31-90 jours               20775        8299     39.95 %
--
-- 91-180 jours              18206        8744     48.03 %
--
-- Plus de 180 jours         16937       10851     64.07 %
--
-- TOTAL                     79162       33078
--
-- =====================================================================



-- =====================================================================
-- RESULTATS OBTENUS : RESORT HOTEL
-- =====================================================================
--
-- TRANCHE               RESERVATIONS  ANNULEES   TAUX
--
-- 0-7 jours                  8932         581      6.50 %
--
-- 8-30 jours                 6404        1403     21.91 %
--
-- 31-90 jours                8753        2841     32.46 %
--
-- 91-180 jours               8214        3075     37.44 %
--
-- Plus de 180 jours          7743        3220     41.59 %
--
-- TOTAL                     40046       11120
--
-- =====================================================================



-- =====================================================================
-- PARTIE 6 : CONTROLE DE COHERENCE DES RESULTATS
-- =====================================================================
--
-- OBJECTIF :
--
-- Vérifier que le total des réservations
-- et des annulations correspond aux résultats
-- obtenus lors des questions précédentes.
--
-- RESULTATS ATTENDUS :
--
-- Total réservations = 119208
-- Total annulations  = 44198
--
-- =====================================================================


SELECT

    COUNT(*) AS total_reservations,

    COUNTIF(is_canceled = 1) AS total_annulations,

    ROUND(

        SAFE_DIVIDE(

            COUNTIF(is_canceled = 1),

            COUNT(*)

        ) * 100,

        2

    ) AS taux_global_annulation_pct

FROM `hotel-booking-jjs.hotel_booking.reservations`;


-- RESULTATS ATTENDUS :
--
-- total_reservations          = 119208
--
-- total_annulations           = 44198
--
-- taux_global_annulation_pct  = 37.08
--
-- STATUT : COHERENT AVEC LA QUESTION METIER N°1



-- =====================================================================
-- PARTIE 7 : SYNTHESE DES RESULTATS METIER
-- =====================================================================
--
-- QUESTION :
--
-- Comment le délai entre la réservation et l'arrivée
-- influence-t-il les annulations ?
--
--
-- RESULTAT GLOBAL :
--
-- Le taux d'annulation augmente progressivement
-- avec le délai de réservation.
--
-- Il passe de 9.60 % pour les réservations
-- de dernière minute à 57.01 % pour celles
-- effectuées plus de 180 jours à l'avance.
--
--
-- COMPARAISON DES HOTELS :
--
-- City Hotel présente systématiquement
-- des taux d'annulation plus élevés
-- que Resort Hotel.
--
--
-- RESERVATIONS DE DERNIERE MINUTE :
--
-- City Hotel   : 12.18 %
-- Resort Hotel :  6.50 %
--
-- Ecart : 5.68 points de pourcentage.
--
--
-- RESERVATIONS TRES ANTICIPEES :
--
-- City Hotel   : 64.07 %
-- Resort Hotel : 41.59 %
--
-- Ecart : 22.48 points de pourcentage.
--
--
-- PRINCIPAL ENSEIGNEMENT :
--
-- Le délai de réservation constitue
-- une variable pertinente pour identifier
-- les réservations associées à un risque
-- d'annulation plus élevé.
--
--
-- RECOMMANDATIONS METIER :
--
-- 1. Surveiller les réservations effectuées
--    plusieurs mois avant l'arrivée.
--
-- 2. Intégrer le lead_time dans les analyses
--    de prévision des annulations.
--
-- 3. Adapter les stratégies de gestion
--    des réservations selon le type d'hôtel.
--
-- 4. Etudier également le type d'acompte,
--    le segment de marché et les antécédents
--    d'annulation.
--
-- 5. Tester des actions de confirmation
--    anticipée pour les réservations
--    présentant un risque élevé.
--
--
-- LIMITES DE L'ANALYSE :
--
-- Les résultats montrent une association
-- statistique, mais ne prouvent pas que
-- le délai de réservation cause l'annulation.
--
-- D'autres variables peuvent intervenir.
--
-- Les résultats décrivent les réservations
-- présentes dans le jeu de données étudié.
--
--
-- =====================================================================
-- FIN DE LA QUESTION METIER N°4
-- =====================================================================
--
-- RESPONSABLE : Josephine
--
-- STATUT : ANALYSE TERMINEE
--
-- LIVRABLE :
-- sql/04_requête.sql
--
-- PROCHAINE ETAPE :
--
-- QUESTION METIER N°5
--
-- Quels segments de marché (market_segment)
-- présentent les taux d'annulation les plus élevés ?
--
-- =====================================================================