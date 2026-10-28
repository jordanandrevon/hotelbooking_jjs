-- ============================================================
-- PROJET : HOTEL BOOKING JJS
-- ============================================================
--
-- FICHIER       : 00_create_table.sql
-- ACTIVITE      : A3.1 - Creation de la structure SQL
-- RESPONSABLE   : Josephine
-- ENVIRONNEMENT : Google BigQuery
--
-- OBJECTIF :
-- Documenter et permettre de recreer la structure
-- de la table reservations utilisee dans le projet
-- de prediction des annulations hotelieres.
--
-- SOURCE :
-- Donnees Hotel Booking nettoyees par l'equipe.
--
-- PROJET BIGQUERY : hotel-booking-jjs
-- DATASET         : hotel_booking
-- TABLE           : reservations
--
-- REMARQUES IMPORTANTES :
-- 1. La table existe deja dans BigQuery.
-- 2. IF NOT EXISTS evite de remplacer la table existante.
-- 3. Ce script ne charge pas les donnees CSV.
-- 4. La table actuelle possede une date d'expiration.
-- 5. L'expiration doit etre geree separement dans BigQuery.
--
-- ============================================================


-- ============================================================
-- ETAPE 1 : CREATION DU DATASET SI NECESSAIRE
-- ============================================================

-- Cree le dataset uniquement s'il n'existe pas.
-- Le dataset est situe dans la zone geographique EU.

CREATE SCHEMA IF NOT EXISTS
  `hotel-booking-jjs.hotel_booking`
OPTIONS (
  location = 'EU'
);


-- ============================================================
-- ETAPE 2 : CREATION DE LA TABLE RESERVATIONS
-- ============================================================

-- Cree la table uniquement si elle n'existe pas.
-- Les colonnes et leurs types correspondent au DDL
-- recupere depuis INFORMATION_SCHEMA.TABLES.

CREATE TABLE IF NOT EXISTS
  `hotel-booking-jjs.hotel_booking.reservations`
(

  -- ----------------------------------------------------------
  -- 2.1 IDENTIFICATION DE L'HOTEL ET ANNULATION
  -- ----------------------------------------------------------

  hotel STRING,
  is_canceled INT64,


  -- ----------------------------------------------------------
  -- 2.2 INFORMATIONS TEMPORELLES
  -- ----------------------------------------------------------

  lead_time INT64,
  arrival_date_year INT64,
  arrival_date_month STRING,
  arrival_date_week_number INT64,
  arrival_date_day_of_month INT64,


  -- ----------------------------------------------------------
  -- 2.3 DUREE DU SEJOUR
  -- ----------------------------------------------------------

  stays_in_weekend_nights INT64,
  stays_in_week_nights INT64,


  -- ----------------------------------------------------------
  -- 2.4 COMPOSITION DE LA RESERVATION
  -- ----------------------------------------------------------

  adults INT64,
  children INT64,
  babies INT64,


  -- ----------------------------------------------------------
  -- 2.5 INFORMATIONS COMMERCIALES
  -- ----------------------------------------------------------

  meal STRING,
  country STRING,
  market_segment STRING,
  distribution_channel STRING,


  -- ----------------------------------------------------------
  -- 2.6 HISTORIQUE DES RESERVATIONS
  -- ----------------------------------------------------------

  is_repeated_guest INT64,
  previous_cancellations INT64,
  previous_bookings_not_canceled INT64,


  -- ----------------------------------------------------------
  -- 2.7 INFORMATIONS SUR LES CHAMBRES
  -- ----------------------------------------------------------

  reserved_room_type STRING,
  assigned_room_type STRING,
  booking_changes INT64,


  -- ----------------------------------------------------------
  -- 2.8 CONDITIONS DE RESERVATION
  -- ----------------------------------------------------------

  deposit_type STRING,
  agent INT64,
  company INT64,
  days_in_waiting_list INT64,
  customer_type STRING,


  -- ----------------------------------------------------------
  -- 2.9 PRIX ET SERVICES
  -- ----------------------------------------------------------

  adr FLOAT64,
  required_car_parking_spaces INT64,
  total_of_special_requests INT64,


  -- ----------------------------------------------------------
  -- 2.10 STATUT FINAL DE LA RESERVATION
  -- ----------------------------------------------------------

  reservation_status STRING,
  reservation_status_date DATE,


  -- ----------------------------------------------------------
  -- 2.11 VARIABLES CREEES LORS DU NETTOYAGE
  -- ----------------------------------------------------------

  arrival_month_num INT64,
  arrival_date DATE,
  total_nights INT64,
  total_guests INT64

);


-- ============================================================
-- ETAPE 3 : VERIFICATION DE LA STRUCTURE
-- ============================================================

-- Objectif :
-- Verifier que la table contient les colonnes attendues
-- et identifier leurs types de donnees.

SELECT
  column_name,
  data_type,
  is_nullable

FROM
  `hotel-booking-jjs.hotel_booking.INFORMATION_SCHEMA.COLUMNS`

WHERE
  table_name = 'reservations'

ORDER BY
  ordinal_position;


-- ============================================================
-- ETAPE 4 : VERIFICATION DU VOLUME DE DONNEES
-- ============================================================

-- Objectif :
-- Verifier le nombre de reservations dans la table.

SELECT
  COUNT(*) AS total_reservations

FROM
  `hotel-booking-jjs.hotel_booking.reservations`;


-- ============================================================
-- RESULTAT ATTENDU SUR LA TABLE EXISTANTE
-- ============================================================
--
-- Nombre de reservations : 119208
-- Nombre de colonnes     : 36
--
-- ATTENTION :
-- Une table nouvellement creee sera vide tant que
-- les donnees nettoyees n'auront pas ete importees.
--
-- ============================================================
-- FIN DU SCRIPT
-- ============================================================