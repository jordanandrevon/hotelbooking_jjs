-- ============================================================================
-- HOTEL BOOKING JJS | A3.4 | QUESTION METIER N°6
-- Comment evolue le taux d'annulation chaque mois pour City Hotel et Resort Hotel ?
-- Dialecte : GoogleSQL (BigQuery Standard SQL)
-- Source : export BigQuery de 52 lignes, juillet 2015 - aout 2017
-- ============================================================================
-- AVANT EXECUTION : remplacer `VOTRE_PROJET.VOTRE_DATASET.VOTRE_TABLE`
-- par l'identifiant reel de la table BigQuery utilisee dans les requetes 03-05.
-- Colonnes source supposees : hotel, arrival_date_year,
-- arrival_date_month, is_canceled (0 ou 1).
-- Executer chaque SELECT separement dans BigQuery pour visualiser son resultat.
-- Les chiffres commentes proviennent de l'export CSV partage ; ils ne sont pas
-- des resultats verifies sur une nouvelle execution de la table source.
-- ============================================================================

-- 01. TAUX D'ANNULATION PAR MOIS ET PAR HOTEL
-- COUNT(*) : toutes les reservations ; COUNTIF : uniquement les annulees.
-- FORMAT_DATE + PARSE_DATE convertissent le nom anglais du mois en numero.
-- SAFE_DIVIDE evite la division par zero.
SELECT
  hotel,
  arrival_date_year AS annee,
  arrival_date_month AS mois,
  EXTRACT(MONTH FROM PARSE_DATE('%B', arrival_date_month)) AS numero_mois,
  COUNT(*) AS total_reservations,
  COUNTIF(is_canceled = 1) AS reservations_annulees,
  ROUND(100 * SAFE_DIVIDE(COUNTIF(is_canceled = 1), COUNT(*)), 2)
    AS taux_annulation_pct
FROM `hotel-booking-jjs.hotel_booking.reservations`
GROUP BY hotel, annee, mois, numero_mois
ORDER BY hotel, annee, numero_mois;

-- 02. ANALYSE TEMPORELLE AVEC CTE ET LAG()
-- CTE = Common Table Expression : resultat intermediaire nomme avec WITH.
-- LAG() lit le taux de la ligne precedente dans le meme hotel.
-- PARTITION BY hotel interdit de comparer City Hotel a Resort Hotel.
-- ORDER BY annee, numero_mois garantit l'ordre chronologique.
-- NULL pour juillet 2015 : aucun mois anterieur n'est disponible.
WITH mensuel AS (
  SELECT
    hotel,
    arrival_date_year AS annee,
    arrival_date_month AS mois,
    EXTRACT(MONTH FROM PARSE_DATE('%B', arrival_date_month)) AS numero_mois,
    COUNT(*) AS total_reservations,
    COUNTIF(is_canceled = 1) AS reservations_annulees,
    100 * SAFE_DIVIDE(COUNTIF(is_canceled = 1), COUNT(*)) AS taux_exact
  FROM `hotel-booking-jjs.hotel_booking.reservations`
  GROUP BY hotel, annee, mois, numero_mois
),
avec_precedent AS (
  SELECT
    *,
    LAG(taux_exact) OVER (
      PARTITION BY hotel
      ORDER BY annee, numero_mois
    ) AS taux_precedent_exact
  FROM mensuel
)
SELECT
  hotel, annee, mois, numero_mois,
  total_reservations, reservations_annulees,
  ROUND(taux_exact, 2) AS taux_annulation_pct,
  ROUND(taux_precedent_exact, 2) AS taux_mois_precedent,
  ROUND(taux_exact - taux_precedent_exact, 2) AS evolution_points
FROM avec_precedent
ORDER BY hotel, annee, numero_mois;

-- 03. TAUX GLOBAL PAR HOTEL (PONDERE PAR LE VOLUME)
-- Ne pas calculer AVG(taux_mensuel) : les mois n'ont pas le meme volume.
SELECT
  hotel,
  COUNT(*) AS total_reservations,
  COUNTIF(is_canceled = 1) AS reservations_annulees,
  ROUND(100 * SAFE_DIVIDE(COUNTIF(is_canceled = 1), COUNT(*)), 2)
    AS taux_global_pct
FROM `hotel-booking-jjs.hotel_booking.reservations`
GROUP BY hotel
ORDER BY taux_global_pct DESC;
-- Export observe : City Hotel 79162 / 33078 / 41.79 % ;
-- Resort Hotel 40046 / 11120 / 27.77 %.

-- 04. COMPARAISON MOIS PAR MOIS : CITY VS RESORT
-- La jointure logique est ici realisee par agregation conditionnelle.
WITH mensuel AS (
  SELECT
    arrival_date_year AS annee,
    EXTRACT(MONTH FROM PARSE_DATE('%B', arrival_date_month)) AS numero_mois,
    hotel,
    100 * SAFE_DIVIDE(COUNTIF(is_canceled = 1), COUNT(*)) AS taux_exact
  FROM `hotel-booking-jjs.hotel_booking.reservations`
  GROUP BY annee, numero_mois, hotel
), comparaison AS (
  SELECT
    annee, numero_mois,
    MAX(IF(hotel = 'City Hotel', taux_exact, NULL)) AS city_taux,
    MAX(IF(hotel = 'Resort Hotel', taux_exact, NULL)) AS resort_taux
  FROM mensuel
  GROUP BY annee, numero_mois
)
SELECT
  annee, numero_mois,
  ROUND(city_taux, 2) AS city_taux_pct,
  ROUND(resort_taux, 2) AS resort_taux_pct,
  ROUND(city_taux - resort_taux, 2) AS ecart_points,
  CASE
    WHEN city_taux > resort_taux THEN 'City Hotel'
    WHEN resort_taux > city_taux THEN 'Resort Hotel'
    ELSE 'Egalite'
  END AS taux_plus_eleve
FROM comparaison
WHERE city_taux IS NOT NULL AND resort_taux IS NOT NULL
ORDER BY annee, numero_mois;
-- Export observe : City > Resort pendant 24 mois sur 26.
-- Exceptions : juillet et aout 2017 (Resort > City).

-- 05. MOIS CRITIQUES : MAXIMUM ET MINIMUM DE TAUX
-- ROW_NUMBER attribue un rang au sein de chaque hotel.
WITH mensuel AS (
  SELECT
    hotel, arrival_date_year AS annee, arrival_date_month AS mois,
    EXTRACT(MONTH FROM PARSE_DATE('%B', arrival_date_month)) AS numero_mois,
    100 * SAFE_DIVIDE(COUNTIF(is_canceled = 1), COUNT(*)) AS taux_exact
  FROM `hotel-booking-jjs.hotel_booking.reservations`
  GROUP BY hotel, annee, mois, numero_mois
), classement AS (
  SELECT *,
    ROW_NUMBER() OVER (PARTITION BY hotel ORDER BY taux_exact DESC, annee, numero_mois) AS rang_max,
    ROW_NUMBER() OVER (PARTITION BY hotel ORDER BY taux_exact ASC, annee, numero_mois) AS rang_min
  FROM mensuel
)
SELECT
  hotel, annee, mois, ROUND(taux_exact, 2) AS taux_annulation_pct,
  CASE WHEN rang_max = 1 THEN 'Maximum' ELSE 'Minimum' END AS type_extreme
FROM classement
WHERE rang_max = 1 OR rang_min = 1
ORDER BY hotel, type_extreme;
-- Export : City max juillet 2015 67.26 %, min novembre 2015 24.41 %.
-- Export : Resort max aout 2017 38.50 %, min janvier 2016 13.46 %.

-- 06. PLUS FORTES HAUSSES ET BAISSES MENSUELLES
WITH mensuel AS (
  SELECT
    hotel, arrival_date_year AS annee, arrival_date_month AS mois,
    EXTRACT(MONTH FROM PARSE_DATE('%B', arrival_date_month)) AS numero_mois,
    100 * SAFE_DIVIDE(COUNTIF(is_canceled = 1), COUNT(*)) AS taux_exact
  FROM `hotel-booking-jjs.hotel_booking.reservations`
  GROUP BY hotel, annee, mois, numero_mois
), evolutions AS (
  SELECT *,
    taux_exact - LAG(taux_exact) OVER (
      PARTITION BY hotel ORDER BY annee, numero_mois
    ) AS evolution_exacte
  FROM mensuel
), rangs AS (
  SELECT *,
    ROW_NUMBER() OVER (PARTITION BY hotel ORDER BY evolution_exacte DESC) AS rang_hausse,
    ROW_NUMBER() OVER (PARTITION BY hotel ORDER BY evolution_exacte ASC) AS rang_baisse
  FROM evolutions
  WHERE evolution_exacte IS NOT NULL
)
SELECT
  hotel, annee, mois,
  ROUND(evolution_exacte, 2) AS evolution_points,
  CASE WHEN rang_hausse = 1 THEN 'Plus forte hausse' ELSE 'Plus forte baisse' END AS type_variation
FROM rangs
WHERE rang_hausse = 1 OR rang_baisse = 1
ORDER BY hotel, type_variation;
-- Export : City +16.10 points decembre 2015, -17.46 points aout 2015.
-- Export : Resort +13.27 points fevrier 2016, -10.67 points janvier 2016.

-- 07. CONTROLES DE COHERENCE DE LA SOURCE
-- Les controles permettent de verifier le perimetre de l'analyse.
SELECT
  COUNT(*) AS nombre_lignes,
  COUNTIF(hotel IS NULL OR arrival_date_year IS NULL
          OR arrival_date_month IS NULL OR is_canceled IS NULL)
    AS lignes_avec_champ_essentiel_manquant,
  COUNTIF(is_canceled NOT IN (0, 1)) AS statuts_annulation_invalides,
  COUNTIF(SAFE.PARSE_DATE('%B', arrival_date_month) IS NULL)
    AS mois_non_reconnus,
  COUNT(DISTINCT FORMAT('%s-%d-%s', hotel, arrival_date_year, arrival_date_month))
    AS groupes_hotel_mois
FROM `hotel-booking-jjs.hotel_booking.reservations`;
-- Attendu sur le perimetre exporte : 119208 lignes et 52 groupes hotel-mois.
-- Dataset initial du projet : 119390 lignes ; difference = 182.
-- Documenter les exclusions / transformations avant de conclure.

-- ============================================================================
-- ANALYSE METIER : INTERPRETATION DES RESULTATS EXPORTES
-- ============================================================================
-- Periode : juillet 2015 - aout 2017, soit 26 mois par hotel.
-- City Hotel : 79162 reservations, 33078 annulations, taux global 41.79 %.
-- Resort Hotel : 40046 reservations, 11120 annulations, taux global 27.77 %.
-- Ecart global : environ 14.02 points de pourcentage.
-- City Hotel a un taux plus eleve pendant 24 des 26 mois observes.
-- Les exceptions sont juillet et aout 2017.
-- Les taux evoluent fortement selon les mois, mais les chiffres seuls ne
-- permettent pas de conclure a une cause ou a une saisonnalite recurrente.
-- RECOMMANDATIONS :
-- 1. Suivre les taux ET les volumes d'annulations chaque mois par hotel.
-- 2. Examiner lead_time, market_segment et deposit_type pour les mois critiques.
-- 3. Documenter le perimetre et les controles qualite avant le dashboard.
-- 4. Visualiser deux courbes mensuelles dans Looker Studio.
-- ATTENTION : ces statistiques concernent le mois d'arrivee prevu, et non
-- necessairement le mois pendant lequel l'annulation a ete effectuee.
-- ============================================================================
