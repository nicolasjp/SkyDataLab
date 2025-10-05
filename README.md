# ✈ Sky Data Lab  

**Analyse et pipeline de données sur le trafic aérien pour extraire des KPI pertinents et visualiser les insights.**

---

## 🚀 Objectif du projet  
L’objectif de *Sky Data Lab* est de traiter et d’analyser un jeu de données sur les vols aériens, en construisant une **chaîne de traitement complète** – de la donnée brute jusqu’à la restitution des **indicateurs clés de performance (KPI)**.  

Le projet illustre les compétences essentielles d’un **Data Engineer / Data Analyst**, notamment dans la **préparation, transformation et visualisation** de données à grande échelle.

---

## 🧩 Architecture du projet  

Le projet repose sur **Azure Synapse Analytics** pour l’ingestion, le nettoyage et la transformation des données, puis sur **Power BI** pour la visualisation des résultats.

### Étapes principales :
1. **Mise en place de l’architecture**
   - Création d’un *Storage Account*, d’un *container* et d’un *Synapse Workspace* pour centraliser les données et traitements.  

2. **Ingestion des données**
   - Chargement des fichiers sources (CSV/JSON) dans le *container Azure*.  

3. **Phase de découverte**
   - Analyse exploratoire via requêtes SQL simples pour identifier anomalies et incohérences.  

4. **Nettoyage et transformation**
   - Création de vues intermédiaires dans Synapse pour nettoyer et harmoniser les données (espaces, formats, doublons…).  

5. **Construction de la table Gold**
   - Consolidation des vues nettoyées en une **table Gold** unique contenant les données prêtes à l’analyse.  
   - Calcul d’indicateurs dérivés : ponctualité, retards, typologie de vols, etc.  

6. **Visualisation Power BI**
   - Création d’un **rapport interactif** en quatre pages :  
     - **Page d’accueil** : résumé global des indicateurs.  
     - **KPI 1** : Taux de vols au départ à l’heure (annuel).  
     - **KPI 2** : Retard moyen à l’arrivée par type d’avion.  
     - **KPI 3** : Top 3 des causes de retard sur les vols nationaux.  

---

## 📊 Enseignements clés  

- En moyenne, **seulement 30 % des vols partent à l’heure**, révélant un fort potentiel d’amélioration.  
- Le **retard moyen à l’arrivée** est d’environ **15 minutes**, impactant la fluidité des opérations.  
- La catégorie **"UNKNOWN"** est la principale cause de retard recensée, signalant un besoin d’améliorer la qualité du suivi des motifs.  

---

## 🛠️ Technologies utilisées  

| Catégorie | Outils / Technologies |
|------------|------------------------|
| Cloud & Data | **Azure Synapse Analytics**, **Azure Storage Account** |
| Langage | **SQL** |
| Visualisation | **Power BI** |
| Versionning | **Git / GitHub** |

---

## 📁 Structure du projet  
SkyDataLab/
├── raw_data/ # Fichiers sources (CSV, JSON)
├── code_transformation/ # Requêtes SQL et scripts de transformation
├── results/ # Table Gold finale, export Power BI et captures d’écran
└── README.md

---

## 📈 Résultats  
Les visualisations permettent une compréhension rapide de la ponctualité des vols et de l’impact des causes de retard, offrant des pistes concrètes pour améliorer la performance opérationnelle et la qualité des données.  