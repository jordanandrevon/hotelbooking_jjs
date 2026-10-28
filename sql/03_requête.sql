-- =====================================================================
-- PROJET : HOTEL BOOKING JJS
-- =====================================================================
--
-- RESPONSABLE : Josephine
-- OUTIL       : Google BigQuery
-- LANGAGE     : SQL - GoogleSQL
-- ETAPE       : A3.4 - ANALYSE METIER
--
-- FICHIER     : sql/03_requête.sql
--
-- QUESTION METIER N°3 :
--
-- Quels mois d'arrivée présentent les taux
-- d'annulation les plus élevés ?
--
-- SOURCE :
--
-- Projet BigQuery : hotel-booking-jjs
-- Dataset         : hotel_booking
-- Table           : reservations
--
-- TABLE COMPLETE :
-- `hotel-booking-jjs.hotel_booking.reservations`
--
-- VOLUME :
-- 119208 réservations
--
-- OBJECTIFS :
--
-- 1. Comprendre les variables temporelles.
-- 2. Vérifier les mois et les années disponibles.
-- 3. Calculer le taux d'annulation par mois d'arrivée.
-- 4. Identifier les mois présentant les taux les plus élevés.
-- 5. Analyser les annulations par année et par mois.
-- 6. Comparer les résultats dans le temps.
-- 7. Proposer des recommandations métier.
--
-- =====================================================================



-- =====================================================================
-- PARTIE 1 : COMPRENDRE LES VARIABLES
-- =====================================================================

-- VARIABLE 1 : arrival_date_year
--
-- Définition :
-- Année d'arrivée prévue du client.
--
-- Exemples :
-- 2015
-- 2016
-- 2017
--
-- Type BigQuery : INTEGER


-- VARIABLE 2 : arrival_date_month
--
-- Définition :
-- Mois d'arrivée prévu du client.
--
-- Exemples :
-- January
-- February
-- March
-- April
--
-- Type BigQuery : STRING


-- VARIABLE 3 : is_canceled
--
-- Définition :
-- Indique si la réservation a été annulée.
--
-- 0 = réservation non annulée
-- 1 = réservation annulée
--
-- Type BigQuery : INTEGER


-- VARIABLE 4 : arrival_date_day_of_month
--
-- Définition :
-- Jour du mois correspondant à l'arrivée prévue.
--
-- Exemples :
-- 1, 2, 15, 28, 31
--
-- Type BigQuery : INTEGER



-- =====================================================================
-- PARTIE 2 : CONTROLE EXPLORATOIRE DES ANNEES
-- =====================================================================
--
-- OBJECTIF :
--
-- Identifier les années présentes dans le dataset.
--
-- FONCTIONS :
--
-- DISTINCT : supprime les valeurs répétées.
-- ORDER BY : trie les résultats.
--
-- =====================================================================


SELECT DISTINCT

    arrival_date_year

FROM `hotel-booking-jjs.hotel_booking.reservations`

ORDER BY arrival_date_year;


-- RESULTATS ATTENDUS :
--
-- 2015
-- 2016
-- 2017
--
-- INTERPRETATION :
--
-- Le dataset couvre des réservations dont les
-- arrivées sont prévues entre 2015 et 2017.
--
-- La période disponible va de juillet 2015
-- à août 2017.
--
-- ATTENTION :
--
-- Les années 2015 et 2017 sont incomplètes.
--
-- Il faudra en tenir compte lors des comparaisons.



-- =====================================================================
-- PARTIE 3 : CONTROLE DES MOIS D'ARRIVEE
-- =====================================================================
--
-- OBJECTIF :
--
-- Identifier les mois présents dans les données.
--
-- PROBLEME :
--
-- arrival_date_month est une variable STRING.
--
-- Si nous utilisons uniquement ORDER BY,
-- BigQuery classe les mois alphabétiquement.
--
-- Exemple :
--
-- April
-- August
-- December
-- February
--
-- Ce n'est pas l'ordre chronologique.
--
-- SOLUTION :
--
-- Utiliser CASE WHEN pour attribuer
-- un numéro à chaque mois.
--
-- =====================================================================


SELECT DISTINCT

    arrival_date_month,

    CASE arrival_date_month

        WHEN 'January' THEN 1
        WHEN 'February' THEN 2
        WHEN 'March' THEN 3
        WHEN 'April' THEN 4
        WHEN 'May' THEN 5
        WHEN 'June' THEN 6
        WHEN 'July' THEN 7
        WHEN 'August' THEN 8
        WHEN 'September' THEN 9
        WHEN 'October' THEN 10
        WHEN 'November' THEN 11
        WHEN 'December' THEN 12

    END AS numero_mois

FROM `hotel-booking-jjs.hotel_booking.reservations`

ORDER BY numero_mois;


-- RESULTAT ATTENDU :
--
-- numero_mois | arrival_date_month
-- ---------------------------------
-- 1           | January
-- 2           | February
-- 3           | March
-- 4           | April
-- 5           | May
-- 6           | June
-- 7           | July
-- 8           | August
-- 9           | September
-- 10          | October
-- 11          | November
-- 12          | December
--
-- INTERPRETATION :
--
-- Les 12 mois de l'année sont présents
-- dans le dataset.
--
-- Cette transformation permet de classer
-- les résultats chronologiquement.



-- =====================================================================
-- PARTIE 4 : QUESTION METIER N°3
-- ANALYSE GLOBALE DES ANNULATIONS PAR MOIS
-- =====================================================================
--
-- QUESTION :
--
-- Quels mois d'arrivée présentent les taux
-- d'annulation les plus élevés ?
--
-- OBJECTIF :
--
-- Calculer pour chaque mois :
--
-- 1. Le nombre total de réservations.
-- 2. Le nombre de réservations annulées.
-- 3. Le taux d'annulation.
--
-- FORMULE :
--
-- Taux d'annulation =
--
-- (Nombre d'annulations / Nombre de réservations) * 100
--
-- METHODE :
--
-- Nous utilisons une CTE pour créer le numéro du mois.
--
-- Puis nous regroupons les réservations par mois.
--
-- =====================================================================


WITH reservations_par_mois AS (

    SELECT

        arrival_date_month,

        is_canceled,

        CASE arrival_date_month

            WHEN 'January' THEN 1
            WHEN 'February' THEN 2
            WHEN 'March' THEN 3
            WHEN 'April' THEN 4
            WHEN 'May' THEN 5
            WHEN 'June' THEN 6
            WHEN 'July' THEN 7
            WHEN 'August' THEN 8
            WHEN 'September' THEN 9
            WHEN 'October' THEN 10
            WHEN 'November' THEN 11
            WHEN 'December' THEN 12

        END AS numero_mois

    FROM `hotel-booking-jjs.hotel_booking.reservations`

)


SELECT

    numero_mois,

    arrival_date_month,

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


FROM reservations_par_mois


GROUP BY

    numero_mois,

    arrival_date_month


-- Classer les mois du taux le plus élevé au plus faible
ORDER BY taux_annulation_pct DESC;



-- =====================================================================
-- RESULTATS OBTENUS DANS BIGQUERY
-- =====================================================================
--
-- MOIS         RESERVATIONS   ANNULEES    TAUX
--
-- June             10929        4534      41.49 %
-- April            11078        4518      40.78 %
-- May              11780        4677      39.70 %
-- September        10500        4115      39.19 %
-- October          11147        4246      38.09 %
-- August           13861        5237      37.78 %
-- July             12644        4737      37.46 %
-- December          6759        2368      35.03 %
-- February          8052        2693      33.45 %
-- March             9766        3147      32.22 %
-- November          6771        2120      31.31 %
-- January           5921        1806      30.50 %
--
-- =====================================================================



-- =====================================================================
-- INTERPRETATION METIER : ANALYSE GLOBALE
-- =====================================================================
--
-- CONSTAT 1 :
--
-- Le mois de juin présente le taux
-- d'annulation le plus élevé.
--
-- June : 41.49 %
--
-- Il est suivi par :
--
-- April : 40.78 %
-- May   : 39.70 %
--
--
-- CONSTAT 2 :
--
-- Le mois de janvier présente le taux
-- d'annulation le plus faible.
--
-- January : 30.50 %
--
--
-- CONSTAT 3 :
--
-- Les taux d'annulation varient
-- selon les mois d'arrivée.
--
-- ECART ENTRE JUIN ET JANVIER :
--
-- 41.49 - 30.50 = 10.99 points de pourcentage.
--
--
-- CONCLUSION :
--
-- Les réservations dont l'arrivée est prévue
-- en juin présentent le taux d'annulation
-- le plus élevé dans cette analyse globale.
--
-- Cependant, cette analyse regroupe
-- plusieurs années.
--
-- Nous devons donc approfondir les résultats
-- en distinguant les années d'arrivée.
--
-- =====================================================================



-- =====================================================================
-- PARTIE 5 : ANALYSE COMPLEMENTAIRE PAR ANNEE ET MOIS
-- =====================================================================
--
-- OBJECTIF :
--
-- Etudier l'évolution des taux d'annulation
-- pour chaque mois de chaque année.
--
-- POURQUOI ?
--
-- L'analyse précédente regroupe les réservations
-- de plusieurs années.
--
-- Exemple :
--
-- January 2016
-- January 2017
--
-- Ces deux périodes sont regroupées
-- dans le résultat global de janvier.
--
-- Pour analyser l'évolution temporelle,
-- nous devons les distinguer.
--
-- =====================================================================


WITH reservations_par_periode AS (

    SELECT

        arrival_date_year AS annee,

        arrival_date_month AS mois,

        is_canceled,

        CASE arrival_date_month

            WHEN 'January' THEN 1
            WHEN 'February' THEN 2
            WHEN 'March' THEN 3
            WHEN 'April' THEN 4
            WHEN 'May' THEN 5
            WHEN 'June' THEN 6
            WHEN 'July' THEN 7
            WHEN 'August' THEN 8
            WHEN 'September' THEN 9
            WHEN 'October' THEN 10
            WHEN 'November' THEN 11
            WHEN 'December' THEN 12

        END AS numero_mois

    FROM `hotel-booking-jjs.hotel_booking.reservations`

)


SELECT

    annee,

    numero_mois,

    mois,

    -- Nombre total de réservations
    COUNT(*) AS total_reservations,

    -- Nombre de réservations annulées
    COUNTIF(is_canceled = 1) AS reservations_annulees,

    -- Taux d'annulation
    ROUND(

        SAFE_DIVIDE(

            COUNTIF(is_canceled = 1),

            COUNT(*)

        ) * 100,

        2

    ) AS taux_annulation_pct


FROM reservations_par_periode


GROUP BY

    annee,

    numero_mois,

    mois


-- Trier chronologiquement
ORDER BY

    annee,

    numero_mois;



-- =====================================================================
-- RESULTATS OBTENUS DANS BIGQUERY
-- =====================================================================
--
-- Nombre de périodes observées : 26
--
-- PERIODE :
--
-- Juillet 2015 à août 2017
--
--
-- EXEMPLES DE RESULTATS : 2015
--
-- ANNEE  MOIS         RESERVATIONS  ANNULEES  TAUX
--
-- 2015   July              2774       1259    45.39 %
-- 2015   August            3883       1598    41.15 %
-- 2015   September         5109       2093    40.97 %
-- 2015   October           4951       1732    34.98 %
-- 2015   November          2337        486    20.80 %
-- 2015   December          2913        973    33.40 %
--
--
-- EXEMPLES DE RESULTATS : 2016
--
-- ANNEE  MOIS         RESERVATIONS  ANNULEES  TAUX
--
-- 2016   January           2248        557    24.78 %
-- 2016   February          3884       1335    34.37 %
-- 2016   March             4818       1476    30.64 %
-- 2016   April             5425       2060    37.97 %
-- 2016   May               5475       1915    34.98 %
-- 2016   June              5290       2096    39.62 %
-- 2016   July              4560       1494    32.76 %
-- 2016   August            5055       1825    36.10 %
-- 2016   September         5391       2022    37.51 %
-- 2016   October           6196       2514    40.57 %
-- 2016   November          4434       1634    36.85 %
-- 2016   December          3846       1395    36.27 %
--
--
-- EXEMPLES DE RESULTATS : 2017
--
-- ANNEE  MOIS         RESERVATIONS  ANNULEES  TAUX
--
-- 2017   January           3673       1249    34.00 %
-- 2017   February          4168       1358    32.58 %
-- 2017   March             4948       1671    33.77 %
-- 2017   April             5653       2458    43.48 %
-- 2017   May               6305       2762    43.81 %
-- 2017   June              5639       2438    43.23 %
-- 2017   July              5310       1984    37.36 %
-- 2017   August            4923       1814    36.85 %
--
-- =====================================================================



-- =====================================================================
-- INTERPRETATION METIER : ANALYSE TEMPORELLE
-- =====================================================================
--
-- CONSTAT 1 :
--
-- Les taux d'annulation varient d'une année
-- à l'autre pour un même mois.
--
-- Exemple pour janvier :
--
-- January 2016 : 24.78 %
-- January 2017 : 34.00 %
--
-- ECART :
--
-- 34.00 - 24.78 = 9.22 points.
--
--
-- CONSTAT 2 :
--
-- Les taux d'annulation de certains mois
-- sont particulièrement élevés en 2017.
--
-- April 2017 : 43.48 %
-- May 2017   : 43.81 %
-- June 2017  : 43.23 %
--
--
-- CONSTAT 3 :
--
-- Le taux d'annulation peut évoluer
-- différemment selon les périodes.
--
-- Exemple :
--
-- October 2015 : 34.98 %
-- October 2016 : 40.57 %
--
--
-- CONCLUSION :
--
-- Le mois d'arrivée est associé à des variations
-- du taux d'annulation.
--
-- Cependant, le comportement des annulations
-- varie également selon l'année.
--
-- Il est donc pertinent de suivre
-- les taux d'annulation à une granularité
-- mensuelle et annuelle.
--
-- =====================================================================



-- =====================================================================
-- PARTIE 6 : CONTROLE DE COHERENCE
-- =====================================================================
--
-- OBJECTIF :
--
-- Vérifier que les résultats correspondent
-- au volume global de la table.
--
-- RESULTATS ATTENDUS :
--
-- Réservations : 119208
-- Annulations  : 44198
-- Taux global  : 37.08 %
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
-- total_reservations         = 119208
-- total_annulations          = 44198
-- taux_global_annulation_pct = 37.08
--
-- STATUT : COHERENT AVEC LA QUESTION METIER N°1



-- =====================================================================
-- PARTIE 7 : SYNTHESE DES RESULTATS METIER
-- =====================================================================
--
-- QUESTION :
--
-- Quels mois d'arrivée présentent les taux
-- d'annulation les plus élevés ?
--
--
-- RESULTATS GLOBAUX :
--
-- Les trois mois présentant les taux
-- d'annulation les plus élevés sont :
--
-- 1. June  : 41.49 %
-- 2. April : 40.78 %
-- 3. May   : 39.70 %
--
--
-- Le mois présentant le taux
-- le plus faible est :
--
-- January : 30.50 %
--
--
-- ANALYSE COMPLEMENTAIRE :
--
-- Les taux d'annulation varient
-- également selon les années.
--
-- Exemple :
--
-- May 2016 : 34.98 %
-- May 2017 : 43.81 %
--
-- Cela représente une augmentation
-- de 8.83 points de pourcentage.
--
--
-- PRINCIPAL ENSEIGNEMENT :
--
-- Le mois d'arrivée constitue
-- une variable pertinente pour analyser
-- les variations des annulations.
--
-- Les résultats montrent également
-- l'intérêt d'intégrer l'année d'arrivée
-- dans les analyses temporelles.
--
--
-- RECOMMANDATIONS METIER :
--
-- 1. Surveiller les taux d'annulation
--    des mois présentant les niveaux
--    les plus élevés.
--
-- 2. Mettre en place un suivi mensuel
--    des réservations et des annulations.
--
-- 3. Comparer les résultats d'une année
--    à l'autre lorsque les périodes
--    sont comparables.
--
-- 4. Intégrer le mois d'arrivée dans
--    les tableaux de bord de suivi.
--
-- 5. Etudier d'autres variables,
--    notamment le type d'hôtel,
--    le segment de marché et le lead_time.
--
--
-- LIMITES DE L'ANALYSE :
--
-- Les données couvrent juillet 2015
-- à août 2017.
--
-- Les années 2015 et 2017 sont incomplètes.
--
-- Les résultats ne permettent pas
-- de démontrer une causalité entre
-- le mois d'arrivée et les annulations.
--
-- Les différences peuvent aussi être liées
-- à la composition de la clientèle,
-- au type d'hôtel ou à d'autres facteurs.
--
--
-- =====================================================================
-- FIN DE LA QUESTION METIER N°3
-- =====================================================================
--
-- RESPONSABLE : Josephine
--
-- STATUT : ANALYSE DOCUMENTEE
--
-- LIVRABLE :
-- sql/03_requête.sql
--
-- PROCHAINE ETAPE :
--
-- QUESTION METIER N°4
--
-- Comment le délai de réservation (lead_time)
-- influence-t-il les annulations ?
--
-- =====================================================================