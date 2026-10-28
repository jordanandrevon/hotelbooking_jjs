-- =====================================================
-- PROJET : HOTEL BOOKING JJS
-- RESPONSABLE : JOSEPHINE
-- OUTIL : GOOGLE BIGQUERY
-- ETAPE : A3.4 - ANALYSE METIER
-- =====================================================

-- QUESTION METIER 1 :
-- Quel est le taux global d'annulation ?

-- OBJECTIF :
-- Mesurer la proportion de réservations annulées sur l'ensemble des réservations analysées.

SELECT
    COUNT(*) AS total_reservations,

    COUNTIF(is_canceled = 1) AS reservations_annulees,

    ROUND(
        SAFE_DIVIDE(
            COUNTIF(is_canceled = 1),
            COUNT(*)
        ) * 100,
        2
    ) AS taux_annulation_pct

FROM `hotel-booking-jjs.hotel_booking.reservations`;


-- =====================================================
-- RESULTATS OBTENUS
-- =====================================================

-- Total des réservations : 119208
-- Réservations annulées : 44198
-- Taux global d'annulation : 37.08 %

-- =====================================================
-- INTERPRETATION METIER
-- =====================================================

-- Sur 119208 réservations analysées, 44198 ont été
-- annulées, soit un taux global de 37.08 %.

-- Environ 37 réservations sur 100 sont donc annulées.

-- Ce niveau d'annulation peut compliquer la gestion des disponibilités, la planification des équipes et les prévisions de revenus.

-- RECOMMANDATION :
-- Identifier les segments de réservations présentant les taux d'annulation les plus élevés afin de  mieux cibler les actions de prévention.

-- LIMITE :
-- Ce taux global ne permet pas d'identifier les facteurs associés aux annulations.
-- Des analyses complémentaires sont nécessaires.