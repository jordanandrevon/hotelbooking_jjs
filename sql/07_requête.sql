-- ============================================================================
-- HOTEL BOOKING JJS | A3.4 | QUESTION METIER N°7
-- Responsable : Josephine | Moteur : Google BigQuery (GoogleSQL)
-- Table : `hotel-booking-jjs.hotel_booking.reservations`
-- Question : Le type d'acompte (deposit_type) est-il associe aux annulations ?
-- Perimetre observe : 119 208 reservations (table utilisee pour l'analyse).
-- Mode d'emploi : executer chaque requete SELECT separement dans BigQuery.
-- IMPORTANT : resultats descriptifs ; aucune causalite n'est demontree.
-- ============================================================================

-- ==========================================================================
-- REQUETE 1 / 5 - Repartition des reservations par type d'acompte
-- ==========================================================================
-- GROUP BY rassemble les lignes partageant le meme deposit_type.
-- COUNT(*) compte les reservations dans chaque groupe.
-- Resultats observes :
-- No Deposit : 104460 ; Non Refund : 14586 ; Refundable : 162.
-- Controle : 104460 + 14586 + 162 = 119208.
SELECT
  deposit_type,
  COUNT(*) AS total_reservations,
  ROUND(100 * SAFE_DIVIDE(COUNT(*), SUM(COUNT(*)) OVER ()), 2)
    AS part_reservations_pct
FROM `hotel-booking-jjs.hotel_booking.reservations`
GROUP BY deposit_type
ORDER BY total_reservations DESC;

-- ==========================================================================
-- REQUETE 2 / 5 - Taux d'annulation par type d'acompte
-- ==========================================================================
-- COUNTIF(condition) compte les lignes qui respectent la condition.
-- SAFE_DIVIDE protege contre une division par zero ; ROUND arrondit a 2 chiffres.
-- Resultats observes (reservations / annulations / taux) :
-- Non Refund : 14586 / 14493 / 99.36 %
-- No Deposit : 104460 / 29669 / 28.40 %
-- Refundable : 162 / 36 / 22.22 %
-- Controle : 14493 + 29669 + 36 = 44198 annulations.
SELECT
  deposit_type,
  COUNT(*) AS total_reservations,
  COUNTIF(is_canceled = 1) AS reservations_annulees,
  COUNTIF(is_canceled = 0) AS reservations_non_annulees,
  ROUND(100 * SAFE_DIVIDE(COUNTIF(is_canceled = 1), COUNT(*)), 2)
    AS taux_annulation_pct
FROM `hotel-booking-jjs.hotel_booking.reservations`
GROUP BY deposit_type
ORDER BY taux_annulation_pct DESC;

-- ==========================================================================
-- REQUETE 3 / 5 - Comparaison par hotel ET type d'acompte
-- ==========================================================================
-- GROUP BY sur deux colonnes cree un groupe pour chaque combinaison.
-- Resultats observes (reservations / annulations / taux) :
-- City Hotel   | Non Refund : 12867 / 12843 / 99.81 %
-- City Hotel   | Refundable :     20 /    14 / 70.00 % (faible effectif)
-- City Hotel   | No Deposit : 66275 / 20221 / 30.51 %
-- Resort Hotel | Non Refund :  1719 /  1650 / 95.99 %
-- Resort Hotel | No Deposit : 38185 /  9448 / 24.74 %
-- Resort Hotel | Refundable :   142 /    22 / 15.49 %
SELECT
  hotel,
  deposit_type,
  COUNT(*) AS total_reservations,
  COUNTIF(is_canceled = 1) AS reservations_annulees,
  COUNTIF(is_canceled = 0) AS reservations_non_annulees,
  ROUND(100 * SAFE_DIVIDE(COUNTIF(is_canceled = 1), COUNT(*)), 2)
    AS taux_annulation_pct
FROM `hotel-booking-jjs.hotel_booking.reservations`
GROUP BY hotel, deposit_type
ORDER BY hotel, taux_annulation_pct DESC;

-- ==========================================================================
-- REQUETE 4 / 5 - Segments de marche des reservations Non Refund
-- ==========================================================================
-- WHERE filtre les lignes AVANT le regroupement.
-- Les segments Groups et Offline TA/TO regroupent ensemble 14177
-- reservations Non Refund sur 14586, soit environ 97.19 %.
-- Resultats principaux :
-- City Hotel / Groups : 7660 / 7656 / 99.95 %
-- City Hotel / Offline TA/TO : 4854 / 4853 / 99.98 %
-- Resort Hotel / Groups : 1512 / 1454 / 96.16 %
-- Resort Hotel / Offline TA/TO : 151 / 149 / 98.68 %
SELECT
  hotel,
  market_segment,
  COUNT(*) AS total_reservations,
  COUNTIF(is_canceled = 1) AS reservations_annulees,
  COUNTIF(is_canceled = 0) AS reservations_non_annulees,
  ROUND(100 * SAFE_DIVIDE(COUNTIF(is_canceled = 1), COUNT(*)), 2)
    AS taux_annulation_pct
FROM `hotel-booking-jjs.hotel_booking.reservations`
WHERE deposit_type = 'Non Refund'
GROUP BY hotel, market_segment
ORDER BY total_reservations DESC;

-- ==========================================================================
-- REQUETE 5 / 5 - Comparaison des acomptes a segment et hotel identiques
-- ==========================================================================
-- IN conserve seulement les deux segments predominants parmi Non Refund.
-- Cette analyse limite certaines differences de composition des groupes,
-- mais ne controle pas tous les facteurs (lead_time, saison, contrats...).
-- Resultats observes :
-- City / Groups : No Deposit 6298 / 1964 / 31.18 % ;
--                 Non Refund 7660 / 7656 / 99.95 %.
-- Resort / Groups : No Deposit 4190 / 1007 / 24.03 % ;
--                   Non Refund 1512 / 1454 / 96.16 %.
-- City / Offline TA/TO : No Deposit 11855 / 2312 / 19.50 % ;
--                        Non Refund 4854 / 4853 / 99.98 %.
-- Resort / Offline TA/TO : No Deposit 7317 / 985 / 13.46 % ;
--                          Non Refund 151 / 149 / 98.68 %.
-- Les cellules Refundable ont souvent de tres petits effectifs : prudence.
SELECT
  hotel,
  market_segment,
  deposit_type,
  COUNT(*) AS total_reservations,
  COUNTIF(is_canceled = 1) AS reservations_annulees,
  ROUND(100 * SAFE_DIVIDE(COUNTIF(is_canceled = 1), COUNT(*)), 2)
    AS taux_annulation_pct
FROM `hotel-booking-jjs.hotel_booking.reservations`
WHERE market_segment IN ('Groups', 'Offline TA/TO')
GROUP BY hotel, market_segment, deposit_type
ORDER BY hotel, market_segment, deposit_type;

-- ==========================================================================
-- CONTROLES DE COHERENCE (requete complementaire facultative)
-- ==========================================================================
-- A executer separement : confirme le perimetre et les valeurs de is_canceled.
-- Attendu d'apres les requetes : 119208 lignes ; 44198 annulees ;
-- 75010 non annulees ; 0 statut invalide ou NULL.
-- Si un resultat differe, verifier le chargement et les filtres de la table.
SELECT
  COUNT(*) AS total_reservations,
  COUNTIF(is_canceled = 1) AS reservations_annulees,
  COUNTIF(is_canceled = 0) AS reservations_non_annulees,
  COUNTIF(is_canceled IS NULL OR is_canceled NOT IN (0, 1))
    AS statuts_invalides,
  COUNTIF(deposit_type IS NULL) AS types_acompte_manquants,
  ROUND(100 * SAFE_DIVIDE(COUNTIF(is_canceled = 1), COUNT(*)), 2)
    AS taux_annulation_global_pct
FROM `hotel-booking-jjs.hotel_booking.reservations`;

-- ==========================================================================
-- SYNTHESE METIER ET RECOMMANDATIONS
-- ==========================================================================
-- Sur les 119208 reservations analysees, les taux d'annulation observes sont :
-- Non Refund 99.36 %, No Deposit 28.40 %, Refundable 22.22 %.
-- Le taux Non Refund est tres eleve dans les deux etablissements :
-- City Hotel 99.81 %, Resort Hotel 95.99 %.
-- 97.19 % des reservations Non Refund appartiennent aux segments
-- Groups et Offline TA/TO. L'ecart reste important lorsqu'on compare
-- les types d'acompte au sein d'un meme hotel et d'un meme segment.
-- ATTENTION : association statistique != causalite.
-- La categorie Refundable a seulement 162 reservations au total :
-- prudence sur ses taux, particulierement dans les petites cellules.
-- RECOMMANDATIONS :
-- 1) Auditer les regles contractuelles et le codage de deposit_type.
-- 2) Examiner les segments Groups et Offline TA/TO avec les equipes metier.
-- 3) Croiser avec lead_time et les periodes d'arrivee.
-- 4) Verifier les montants reellement encaisses avant d'evaluer les pertes.
-- LIMITES : l'ecart de 182 lignes avec le fichier brut de 119390
-- reservations doit etre documente dans le suivi de nettoyage.
