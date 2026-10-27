-- ============================================================
-- PROJET : HOTEL BOOKING JJS
-- ============================================================
-- Responsable : Josephine
-- Outil : Google BigQuery
-- Étape : A3.2 - Contrôle des données importées
--
-- Source :
-- dataset/processed/hotel_bookings_clean.csv
--
-- Table BigQuery :
-- hotel-booking-jjs.hotel_booking.reservations
--
-- Objectif :
-- Vérifier la conformité des données importées dans BigQuery
-- avec le fichier préparé par Suz.
-- ============================================================


-- ============================================================
-- CONTROLE 1 : NOMBRE TOTAL DE RESERVATIONS
-- ============================================================

SELECT
    COUNT(*) AS total_reservations

FROM `hotel-booking-jjs.hotel_booking.reservations`;

-- RESULTAT ATTENDU : 119208 réservations
-- RESULTAT OBTENU  : 119208 réservations
-- STATUT : VALIDE


-- ============================================================
-- CONTROLE 2 : NOMBRE DE COLONNES
-- ============================================================

SELECT
    COUNT(*) AS nombre_colonnes

FROM `hotel-booking-jjs.hotel_booking.INFORMATION_SCHEMA.COLUMNS`

WHERE table_name = 'reservations';

-- RESULTAT ATTENDU : 36 colonnes
-- RESULTAT OBTENU  : 36 colonnes
-- STATUT : VALIDE


-- ============================================================
-- CONTROLE 3 : VERIFICATION DES TYPES DE DONNEES
-- ============================================================

SELECT
    ordinal_position,
    column_name,
    data_type

FROM `hotel-booking-jjs.hotel_booking.INFORMATION_SCHEMA.COLUMNS`

WHERE table_name = 'reservations'

ORDER BY ordinal_position;

-- OBJECTIF :
-- Vérifier que les colonnes possèdent des types cohérents.
--
-- Exemples :
-- hotel       : STRING
-- is_canceled : INTEGER
-- lead_time   : INTEGER
--
-- RESULTAT :
-- 36 colonnes identifiées et types vérifiés.
-- STATUT : VALIDE


-- ============================================================
-- CONTROLE 4 : VALEURS MANQUANTES
-- ============================================================

SELECT
    COUNT(*) AS total_reservations,

    COUNTIF(country IS NULL) AS country_null,

    COUNTIF(children IS NULL) AS children_null,

    COUNTIF(agent IS NULL) AS agent_null,

    COUNTIF(company IS NULL) AS company_null

FROM `hotel-booking-jjs.hotel_booking.reservations`;

-- OBJECTIF :
-- Vérifier les colonnes qui présentaient des valeurs
-- manquantes avant le nettoyage effectué par Suz.


-- ============================================================
-- CONTROLE 5 : VALEURS DE REMPLACEMENT
-- ============================================================

SELECT
    COUNTIF(country = 'Unknown') AS pays_inconnus,

    COUNTIF(agent = 0) AS sans_agence,

    COUNTIF(company = 0) AS sans_entreprise

FROM `hotel-booking-jjs.hotel_booking.reservations`;

-- OBJECTIF :
-- Vérifier la présence des valeurs utilisées lors
-- du nettoyage des données.
--
-- Attention :
-- Une valeur égale à 0 n'est pas une valeur NULL.


-- ============================================================
-- CONTROLE 6 : VERIFICATION GLOBALE DES VALEURS NULL
-- ============================================================

DECLARE requete STRING;

SET requete = (
    SELECT
        'SELECT ' ||

        STRING_AGG(
            FORMAT(
                'COUNTIF(`%s` IS NULL)',
                column_name
            ),
            ' + '
            ORDER BY ordinal_position
        )

        || ' AS total_valeurs_null ' ||
        'FROM `hotel-booking-jjs.hotel_booking.reservations`'

    FROM `hotel-booking-jjs.hotel_booking.INFORMATION_SCHEMA.COLUMNS`

    WHERE table_name = 'reservations'
);

EXECUTE IMMEDIATE requete;

-- RESULTAT ATTENDU : 0
-- RESULTAT OBTENU  : 0
-- STATUT : VALIDE


-- ============================================================
-- CONCLUSION DES CONTROLES
-- ============================================================

-- Nombre de réservations : 119208
-- Nombre de colonnes     : 36
-- Valeurs NULL           : 0
--
-- Les contrôles réalisés confirment la cohérence du volume,
-- du schéma et l'absence de valeurs NULL.
--
-- Les données sont prêtes pour les analyses métier SQL.
--
-- Les choix de nettoyage, notamment la conservation
-- des doublons, sont documentés dans le travail de Suz.
-- ============================================================