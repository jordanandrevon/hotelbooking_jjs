-- =====================================================
-- PROJET : HOTEL BOOKING JJS
-- RESPONSABLE : JOSEPHINE
-- OUTIL : GOOGLE BIGQUERY
-- ETAPE : A3.4 - ANALYSE METIER
-- =====================================================

-- QUESTION METIER 2 :
-- Quel établissement présente le taux
-- d'annulation le plus élevé ?

-- OBJECTIF :
-- Comparer les réservations et les annulations
-- entre City Hotel et Resort Hotel.

SELECT
    hotel,

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

GROUP BY hotel

ORDER BY taux_annulation_pct DESC;


-- =====================================================
-- RESULTATS OBTENUS
-- =====================================================

-- CITY HOTEL :
-- Total réservations : 79162
-- Réservations annulées : 33078
-- Taux d'annulation : 41.79 %

-- RESORT HOTEL :
-- Total réservations : 40046
-- Réservations annulées : 11120
-- Taux d'annulation : 27.77 %

-- =====================================================
-- INTERPRETATION METIER
-- =====================================================

-- Le City Hotel présente un taux d'annulation de 41.79 %, contre 27.77 % pour le Resort Hotel.

-- L'écart est de 14.02 points de pourcentage.

-- Le City Hotel concentre environ 75 % des annulations du groupe hôtelier.

-- =====================================================
-- RECOMMANDATION METIER
-- =====================================================

-- Prioriser l'analyse des réservations du City Hotel.

-- Étudier les segments de marché, les délais de réservation et les politiques d'acompte afin d'identifier les facteurs associés aux annulations.

-- =====================================================
-- LIMITES
-- =====================================================

-- Cette analyse descriptive montre une différence
-- entre les établissements, mais ne démontre pas
-- les causes des annulations.