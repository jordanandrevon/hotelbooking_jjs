-- ============================================================
-- PROJET : HOTEL BOOKING JJS
-- ============================================================
-- RESPONSABLE : JOSEPHINE
-- OUTIL : GOOGLE BIGQUERY
-- ETAPE : A3.4 - ANALYSE METIER
-- FICHIER : 05_requête.sql
--
-- QUESTION METIER N°5 :
-- Quels segments de marche (market_segment) presentent
-- les taux d'annulation les plus eleves ?
--
-- OBJECTIFS :
-- 1. Identifier les segments de marche.
-- 2. Calculer le nombre de reservations par segment.
-- 3. Calculer le nombre de reservations annulees.
-- 4. Calculer le taux d'annulation par segment.
-- 5. Comparer les resultats entre City Hotel et Resort Hotel.
-- 6. Formuler des conclusions et recommandations metier.
--
-- TABLE SOURCE :
-- `hotel-booking-jjs.hotel_booking.reservations`
--
-- VARIABLES UTILISEES :
-- market_segment : segment de marche
-- hotel          : type d'etablissement
-- is_canceled    : indicateur d'annulation (0 ou 1)
--
-- ============================================================


-- ============================================================
-- CONTROLE 1 : IDENTIFIER LES SEGMENTS DE MARCHE
-- ============================================================

-- OBJECTIF :
-- Identifier les differentes valeurs de market_segment.
--
-- EXPLICATION :
-- DISTINCT permet de supprimer les doublons dans le resultat.
-- ORDER BY permet de trier les segments alphabetiquement.

SELECT DISTINCT
    market_segment

FROM `hotel-booking-jjs.hotel_booking.reservations`

ORDER BY market_segment;


-- RESULTAT ATTENDU :
--
-- Aviation
-- Complementary
-- Corporate
-- Direct
-- Groups
-- Offline TA/TO
-- Online TA
-- Undefined
--
-- INTERPRETATION :
-- La base contient 8 segments de marche distincts.
--
-- POINT DE VIGILANCE :
-- Le segment Undefined correspond a une categorie
-- non definie. Il doit etre examine separement.


-- ============================================================
-- CONTROLE 2 : CALCULER LE VOLUME PAR SEGMENT
-- ============================================================

-- OBJECTIF :
-- Identifier les segments qui representent le plus
-- grand nombre de reservations.
--
-- EXPLICATION :
-- COUNT(*) compte les lignes de chaque segment.
-- GROUP BY regroupe les reservations par segment.
-- ORDER BY classe les segments par volume decroissant.

SELECT
    market_segment,

    COUNT(*) AS total_reservations

FROM `hotel-booking-jjs.hotel_booking.reservations`

GROUP BY market_segment

ORDER BY total_reservations DESC;


-- ============================================================
-- QUESTION METIER 5 : TAUX D'ANNULATION PAR SEGMENT
-- ============================================================

-- OBJECTIF :
-- Identifier les segments de marche qui presentent
-- les taux d'annulation les plus eleves.
--
-- INDICATEURS :
-- 1. Nombre total de reservations.
-- 2. Nombre de reservations annulees.
-- 3. Taux d'annulation en pourcentage.
--
-- FORMULE :
--
-- Taux d'annulation =
-- (Reservations annulees / Reservations totales) * 100
--
-- FONCTIONS SQL :
--
-- COUNT(*) :
-- Compte toutes les reservations du groupe.
--
-- COUNTIF(is_canceled = 1) :
-- Compte uniquement les reservations annulees.
--
-- SAFE_DIVIDE() :
-- Effectue une division securisee.
-- Retourne NULL si le denominateur est egal a zero.
--
-- ROUND(..., 2) :
-- Arrondit le resultat a deux decimales.
--
-- GROUP BY :
-- Regroupe les lignes par segment de marche.
--
-- ORDER BY DESC :
-- Classe les segments du taux le plus eleve au plus faible.

SELECT
    market_segment,

    COUNT(*) AS total_reservations,

    COUNTIF(is_canceled = 1) AS reservations_annulees,

    ROUND(
        SAFE_DIVIDE(
            COUNTIF(is_canceled = 1),
            COUNT(*)
        ) * 100,
        2
    ) AS taux_annulation_pct

FROM `hotel-booking-jjs.hotel_booking.reservations`

GROUP BY market_segment

ORDER BY taux_annulation_pct DESC;


-- ============================================================
-- RESULTATS OBTENUS DANS BIGQUERY
-- ============================================================

-- Segment          | Total | Annulees | Taux (%)
-- ------------------------------------------------
-- Undefined        |     2 |        2 | 100.00
-- Groups           | 19790 |    12094 |  61.11
-- Online TA        | 56408 |    20735 |  36.76
-- Offline TA/TO    | 24181 |     8301 |  34.33
-- Aviation         |   235 |       52 |  22.13
-- Corporate        |  5282 |      991 |  18.76
-- Direct           | 12582 |     1934 |  15.37
-- Complementary    |   728 |       89 |  12.23


-- ============================================================
-- ANALYSE METIER : RESULTATS GLOBAUX
-- ============================================================

-- OBSERVATION 1 :
-- Le segment Groups presente un taux d'annulation
-- de 61.11 %.
--
-- Il s'agit du taux le plus eleve parmi les segments
-- disposant d'un volume significatif de reservations.
--
-- OBSERVATION 2 :
-- Online TA represente 56 408 reservations,
-- dont 20 735 annulations.
--
-- Ce segment genere le plus grand nombre
-- d'annulations en valeur absolue.
--
-- OBSERVATION 3 :
-- Offline TA/TO presente un taux de 34.33 %.
--
-- OBSERVATION 4 :
-- Direct presente un taux de 15.37 %.
--
-- Les reservations directes sont associees
-- a un taux d'annulation relativement faible.
--
-- OBSERVATION 5 :
-- Undefined affiche 100 % d'annulations.
--
-- Cependant, ce segment ne contient que
-- deux reservations.
--
-- Ce resultat ne permet pas de tirer
-- une conclusion statistique solide.


-- ============================================================
-- ANALYSE COMPLEMENTAIRE :
-- COMPARAISON CITY HOTEL VS RESORT HOTEL
-- ============================================================

-- OBJECTIF :
-- Comparer les taux d'annulation des segments de marche
-- entre les deux etablissements.
--
-- POURQUOI ?
--
-- Un meme segment de marche peut presenter
-- des comportements differents selon l'hotel.
--
-- Cette analyse permet d'identifier les segments
-- les plus exposes dans chaque etablissement.
--
-- GROUP BY hotel, market_segment :
-- Cree un groupe pour chaque combinaison
-- hotel / segment de marche.

SELECT
    hotel,

    market_segment,

    COUNT(*) AS total_reservations,

    COUNTIF(is_canceled = 1) AS reservations_annulees,

    ROUND(
        SAFE_DIVIDE(
            COUNTIF(is_canceled = 1),
            COUNT(*)
        ) * 100,
        2
    ) AS taux_annulation_pct

FROM `hotel-booking-jjs.hotel_booking.reservations`

GROUP BY
    hotel,
    market_segment

ORDER BY
    market_segment,
    hotel;


-- ============================================================
-- RESULTATS COMPARATIFS BIGQUERY
-- ============================================================

-- SEGMENT : GROUPS
--
-- City Hotel   : 68.92 %
-- Resort Hotel : 42.43 %
--
-- Ecart : 26.49 points de pourcentage.
--
-- INTERPRETATION :
-- Les reservations de groupes presentent un taux
-- d'annulation plus eleve dans City Hotel.


-- SEGMENT : OFFLINE TA/TO
--
-- City Hotel   : 42.88 %
-- Resort Hotel : 15.21 %
--
-- Ecart : 27.67 points de pourcentage.
--
-- INTERPRETATION :
-- Les reservations via les agences traditionnelles
-- presentent une difference importante entre
-- les deux etablissements.


-- SEGMENT : ONLINE TA
--
-- City Hotel   : 37.45 %
-- Resort Hotel : 35.24 %
--
-- Ecart : 2.21 points de pourcentage.
--
-- INTERPRETATION :
-- Les taux d'annulation sont relativement proches
-- entre les deux etablissements.


-- SEGMENT : CORPORATE
--
-- City Hotel   : 21.50 %
-- Resort Hotel : 15.23 %
--
-- Ecart : 6.27 points de pourcentage.


-- SEGMENT : DIRECT
--
-- City Hotel   : 17.39 %
-- Resort Hotel : 13.49 %
--
-- Ecart : 3.90 points de pourcentage.
--
-- INTERPRETATION :
-- Les reservations directes presentent des taux
-- relativement faibles dans les deux etablissements.


-- SEGMENT : COMPLEMENTARY
--
-- City Hotel   : 10.63 %
-- Resort Hotel : 16.42 %
--
-- Ecart : -5.79 points de pourcentage.
--
-- INTERPRETATION :
-- Contrairement aux autres segments communs,
-- Resort Hotel presente ici le taux le plus eleve.


-- ============================================================
-- ANALYSE COMPLEMENTAIRE :
-- CALCUL AUTOMATIQUE DES ECARTS ENTRE HOTELS
-- ============================================================

-- OBJECTIF :
-- Comparer automatiquement les taux d'annulation
-- pour chaque segment present dans les deux hotels.
--
-- NOUVELLE NOTION : CTE
--
-- Une CTE (Common Table Expression) est un resultat
-- intermediaire nomme, defini avec WITH.
--
-- Elle permet de decomposer une requete complexe
-- en plusieurs etapes plus faciles a comprendre.
--
-- ETAPE 1 :
-- Calculer le taux d'annulation par hotel et segment.
--
-- ETAPE 2 :
-- Rassembler les taux des deux hotels
-- sur une seule ligne par segment.
--
-- ETAPE 3 :
-- Calculer la difference entre les taux.
--
-- NOTE :
-- Cette requete est une analyse complementaire
-- a executer et verifier dans BigQuery.

WITH taux_par_hotel AS (

    SELECT
        hotel,

        market_segment,

        ROUND(
            SAFE_DIVIDE(
                COUNTIF(is_canceled = 1),
                COUNT(*)
            ) * 100,
            2
        ) AS taux_annulation_pct

    FROM `hotel-booking-jjs.hotel_booking.reservations`

    GROUP BY
        hotel,
        market_segment

),

comparaison AS (

    SELECT
        market_segment,

        MAX(
            IF(
                hotel = 'City Hotel',
                taux_annulation_pct,
                NULL
            )
        ) AS taux_city_hotel,

        MAX(
            IF(
                hotel = 'Resort Hotel',
                taux_annulation_pct,
                NULL
            )
        ) AS taux_resort_hotel

    FROM taux_par_hotel

    GROUP BY market_segment

)

SELECT
    market_segment,

    taux_city_hotel,

    taux_resort_hotel,

    ROUND(
        taux_city_hotel - taux_resort_hotel,
        2
    ) AS ecart_points_pourcentage

FROM comparaison

ORDER BY ecart_points_pourcentage DESC;


-- ============================================================
-- CONCLUSION METIER GENERALE
-- ============================================================

-- L'analyse montre que les taux d'annulation varient
-- selon les segments de marche et les etablissements.
--
-- Le segment Groups presente un taux global
-- d'annulation eleve : 61.11 %.
--
-- Online TA represente le plus grand volume
-- d'annulations : 20 735 reservations.
--
-- City Hotel presente des taux particulierement
-- eleves pour Groups et Offline TA/TO.
--
-- Les reservations directes sont associees
-- a des taux d'annulation relativement faibles.
--
-- Ces resultats mettent en evidence l'interet
-- d'adapter les analyses et les actions commerciales
-- aux differents segments de clientele.


-- ============================================================
-- RECOMMANDATIONS METIER
-- ============================================================

-- RECOMMANDATION 1 :
-- Examiner les conditions d'annulation
-- des reservations de groupes.
--
-- RECOMMANDATION 2 :
-- Etudier les contrats avec les agences
-- de voyages traditionnelles.
--
-- RECOMMANDATION 3 :
-- Analyser les reservations Online TA,
-- car elles representent un volume important
-- d'annulations.
--
-- RECOMMANDATION 4 :
-- Explorer des strategies de fidelisation
-- et de reservation directe.
--
-- RECOMMANDATION 5 :
-- Approfondir l'analyse en croisant
-- market_segment avec :
--
-- lead_time
-- deposit_type
-- hotel
-- arrival_date_month
--
-- Ces variables pourraient aider a mieux comprendre
-- les facteurs associes aux annulations.
--
-- ATTENTION :
-- Les relations observees sont descriptives.
-- Elles ne prouvent pas un lien de causalite.


-- ============================================================
-- FIN DU FICHIER : 05_requête.sql
-- ============================================================