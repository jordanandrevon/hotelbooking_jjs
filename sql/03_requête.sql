-- =====================================================
-- PROJET : HOTEL BOOKING JJS
-- RESPONSABLE : JOSEPHINE
-- OUTIL : GOOGLE BIGQUERY
-- ETAPE : A3.4 - ANALYSE METIER
--
-- QUESTION METIER 3 :
-- Quels mois d'arrivée présentent les taux
-- d'annulation les plus élevés ?
-- =====================================================


-- =====================================================
-- ANALYSE 1 : TAUX D'ANNULATION PAR MOIS
-- =====================================================

-- Coller ici ta première requête SQL
-- Résultat : 12 mois classés par taux décroissant


-- =====================================================
-- ANALYSE 2 : TAUX D'ANNULATION PAR ANNEE ET MOIS
-- =====================================================

-- Coller ici ta deuxième requête SQL
-- Résultat : 26 combinaisons année-mois


-- =====================================================
-- INTERPRETATION METIER
-- =====================================================

-- 1. Juin présente le taux global le plus élevé :
--    41,49 %.

-- 2. Le taux de juin augmente entre 2016 et 2017 :
--    39,62 % → 43,23 %.

-- 3. Avril et mai présentent également une
--    augmentation entre 2016 et 2017.

-- 4. Les données ne permettent pas de conclure
--    à une saisonnalité durable.


-- =====================================================
-- RECOMMANDATION METIER
-- =====================================================

-- Approfondir l'analyse du lead_time,
-- des segments de clientèle et des acomptes
-- pour identifier les facteurs associés
-- aux annulations.