# Hotel Booking — Prédire les annulations tardives

Projet de groupe réalisé dans le cadre de la formation Data Analyst.

**Équipe :** Suz · Josy · Jordan

## Contexte et problématique

Une direction hôtelière gère deux établissements, un **City Hotel** et un **Resort Hotel**. Les annulations perturbent la prévision de l'occupation, l'organisation des équipes et le pilotage commercial.

**Question posée :** peut-on identifier à l'avance les réservations les plus susceptibles d'être annulées, afin d'intervenir sur les 100 réservations les plus risquées sur 1 000 ?

**Notre cadrage :**
- **Moment de prédiction : J-7 avant l'arrivée.** C'est l'horizon où l'hôtel engage ses plannings et ses ressources, et où il reste le temps d'agir (confirmation, remise en vente).
- **Population :** les réservations encore actives à J-7 (62 427 réservations).
- **Cible :** les annulations tardives (annulations et no-shows dans les 7 derniers jours), soit 6,4 % de cette population.

87 % des annulations ont lieu avant J-7 : elles relèvent de la politique commerciale (acompte, conditions d'annulation) et sont traitées dans les recommandations.

## Structure du dépôt

```
hotelbooking_jjs/
├── dataset/
│   ├── raw/                  # hotel_bookings.csv (données brutes, non modifiées)
│   └── processed/            # hotel_bookings_clean.csv (données nettoyées)
├── notebook/
│   ├── [01_exploration.ipynb]
│   ├── [02_preparation.ipynb]
│   └── 03_classification.ipynb
├── sql/
│   ├── [00_create_table.sql]
│   └── q1_... à q6_...sql    # requêtes d'analyse
├── docs/                     # classement des variables, comparaison des modèles
├── reports/                  # synthèse métier, slides, figures
├── requirements.txt
└── README.md
```

## Données

- **Source :** dataset *Hotel Booking Demand* (Antonio, Almeida et Nunes, 2019), 119 390 réservations entre juillet 2015 et août 2017, 32 variables.
- **Nettoyage (119 208 lignes conservées) :**
  - valeurs manquantes traitées (`children`, `country`, `agent`, `company`) ;
  - suppression des réservations à 0 client et des prix aberrants ;
  - création de `arrival_date`, `arrival_month_num`, `total_nights` et `total_guests` ;
  - **doublons conservés** (31 980 lignes) : sans identifiant de réservation, ils correspondent vraisemblablement à plusieurs chambres réservées par un même groupe.

## Démarche

### 1. Exploration (Python)
[Résumer en 2-3 lignes les principaux constats de l'analyse descriptive et de la comparaison City Hotel / Resort Hotel.]

Taux d'annulation global : **37,1 %** (City Hotel : 41,8 % ; Resort Hotel : 27,8 %).

### 2. Analyse SQL (BigQuery)
Les données sont chargées dans BigQuery (`hotel-booking-jjs.hotel_booking.reservations`). Six requêtes répondent à des questions métier :

| Requête | Question | Technique |
|---|---|---|
| Q1 | Évolution mensuelle des réservations et des annulations par hôtel | `GROUP BY`, agrégations |
| Q2 | Taux d'annulation selon le délai de réservation | `CASE WHEN` |
| Q3 | Taux d'annulation selon le type de dépôt | `HAVING` |
| Q4 | Annulations par segment de marché et canal | fonction de fenêtrage `OVER ()` |
| Q5 | Impact de l'historique d'annulation du client | `CASE WHEN` |
| Q6 | Manque à gagner des annulations, cumul annuel | **CTE + fonctions de fenêtrage** |

Les interprétations détaillées figurent dans [chemin du fichier d'interprétation].

### 3. Classification (Python, scikit-learn)
- **Sélection des variables :** les variables inconnues à J-7 ont été retirées pour éviter les fuites de données (`reservation_status`, `assigned_room_type`, `booking_changes`, `total_of_special_requests`, `required_car_parking_spaces`, `country`…). Détail dans `docs/classement_variables_J7.xlsx`.
- **Split temporel :** entraînement sur les arrivées avant avril 2017, test sur avril-août 2017. Ce choix simule l'usage réel (prédire le futur à partir du passé) et évite qu'une même réservation de groupe se retrouve dans les deux jeux.
- **Préparation :** encodage one-hot (modalités rares regroupées), normalisation pour la régression logistique uniquement, le tout dans un `Pipeline` ajusté sur le jeu d'entraînement seul.
- **Modèles comparés :** régression logistique, Random Forest, Gradient Boosting, Random Forest optimisé par validation croisée temporelle (`TimeSeriesSplit`).
- **Métriques :** ROC-AUC, PR-AUC et précision du top 10 %. L'accuracy n'est pas utilisée : avec 3,8 % d'annulations au test, un modèle qui ne prédit jamais d'annulation obtiendrait 96 %.

## Résultats

| Modèle | ROC-AUC | PR-AUC | Précision top 10 % |
|---|---|---|---|
| Régression logistique | 0,659 | 0,141 | 10,5 % |
| **Random Forest (retenu)** | **0,681** | **0,185** | **11,2 %** |
| Gradient Boosting | 0,665 | 0,157 | 11,2 % |
| Random Forest optimisé | 0,674 | 0,179 | 11,9 % |

**Règle de priorisation :** chaque semaine, à J-7, contacter les 10 % de réservations au score de risque le plus élevé.

- 29 % des annulations tardives sont repérées en contactant 10 % des réservations ;
- sur 100 réservations contactées, **11 annulations contre 4 au hasard** (×2,9) ;
- le modèle bat le hasard dans **98 %** des 1 000 simulations de lots de 1 000 réservations.

**Facteurs les plus prédictifs :** le type de dépôt, l'historique d'annulation du client et le délai de réservation.

## Recommandations

1. Déployer la règle du top 10 % à J-7 (message de confirmation de séjour).
2. Agir sur les annulations précoces par une politique d'acompte ou une date limite d'annulation gratuite.
3. Suivre les clients ayant déjà annulé (57 % d'annulations tardives contre 6 %).
4. Concentrer l'effort sur le City Hotel et les réservations de dernière minute.
5. Clarifier l'anomalie des réservations non remboursables et réentraîner le modèle chaque trimestre.

## Limites

- 71 % des annulations tardives restent imprévisibles avec l'information disponible à J-7.
- Dérive des données : le taux d'annulation tardive passe de 7,2 % (entraînement) à 3,8 % (test).
- Le test ne couvre que d'avril à août 2017.
- Les réservations non remboursables présentent une anomalie (taux d'annulation très élevé) qui pèse dans le modèle.
- Le manque à gagner calculé en SQL est un maximum théorique : une partie des chambres annulées a pu être relouée.

## Exécution

### Python
```bash
git clone https://github.com/jordanandrevon/hotelbooking_jjs.git
cd hotelbooking_jjs
pip install -r requirements.txt
```
Ouvrir les notebooks du dossier `notebook/` dans l'ordre (01, 02, 03), puis exécuter toutes les cellules. Les chemins sont relatifs : les notebooks doivent être lancés depuis le dossier `notebook/`.

### SQL (BigQuery)
1. Créer un dataset `hotel_booking` dans un projet BigQuery.
2. Charger `dataset/processed/hotel_bookings_clean.csv` dans une table `reservations` (script : `sql/[00_create_table.sql]`).
3. Exécuter les requêtes du dossier `sql/` en remplaçant le nom du projet si besoin.

## Outils

Python (pandas, NumPy, scikit-learn) · BigQuery · GitHub · Trello