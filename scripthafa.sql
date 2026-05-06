-- ============================================================
--  PROJET S4 - Application de régime alimentaire
--  Base de données MySQL
-- ============================================================

CREATE DATABASE IF NOT EXISTS projet_s4
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE projet_s4;

-- ------------------------------------------------------------
-- TABLE : utilisateurs
-- ------------------------------------------------------------
CREATE TABLE utilisateurs (
    id            INT AUTO_INCREMENT PRIMARY KEY,
    nom           VARCHAR(100)        NOT NULL,
    prenom        VARCHAR(100)        NOT NULL,
    email         VARCHAR(150)        NOT NULL UNIQUE,
    mot_de_passe  VARCHAR(255)        NOT NULL,   -- hash bcrypt
    genre         ENUM('homme','femme','autre') NOT NULL,
    date_naissance DATE,
    -- Informations de santé (page 2 de l'inscription)
    taille_cm     DECIMAL(5,2),                   -- en cm
    poids_kg      DECIMAL(5,2),                   -- en kg
    imc           DECIMAL(5,2)        GENERATED ALWAYS AS
                    (poids_kg / ((taille_cm/100) * (taille_cm/100))) STORED,
    -- Objectif
    objectif      ENUM('augmenter_poids','reduire_poids','imc_ideal') DEFAULT NULL,
    -- Portefeuille & option Gold
    solde         DECIMAL(10,2)       NOT NULL DEFAULT 0.00,
    est_gold      TINYINT(1)          NOT NULL DEFAULT 0,
    date_gold     DATETIME            DEFAULT NULL,
    -- Métadonnées
    est_actif     TINYINT(1)          NOT NULL DEFAULT 1,
    created_at    DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at    DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP
                    ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- TABLE : regimes
-- ------------------------------------------------------------
CREATE TABLE regimes (
    id              INT AUTO_INCREMENT PRIMARY KEY,
    nom             VARCHAR(150)    NOT NULL,
    description     TEXT,
    -- Composition en %
    pct_viande      DECIMAL(5,2)    NOT NULL DEFAULT 0.00,
    pct_poisson     DECIMAL(5,2)    NOT NULL DEFAULT 0.00,
    pct_volaille    DECIMAL(5,2)    NOT NULL DEFAULT 0.00,
    -- Variation de poids attendue
    variation_poids_kg DECIMAL(5,2) NOT NULL COMMENT 'Positif = prise, négatif = perte',
    -- Objectif ciblé par ce régime
    objectif_cible  ENUM('augmenter_poids','reduire_poids','imc_ideal') NOT NULL,
    est_actif       TINYINT(1)      NOT NULL DEFAULT 1,
    created_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP
                      ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT chk_pct CHECK (pct_viande + pct_poisson + pct_volaille <= 100)
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- TABLE : regime_prix  (prix selon la durée)
-- ------------------------------------------------------------
CREATE TABLE regime_prix (
    id          INT AUTO_INCREMENT PRIMARY KEY,
    regime_id   INT             NOT NULL,
    duree_jours INT             NOT NULL COMMENT 'Ex: 7, 14, 30, 60, 90',
    prix        DECIMAL(10,2)   NOT NULL,
    FOREIGN KEY (regime_id) REFERENCES regimes(id) ON DELETE CASCADE,
    UNIQUE KEY uq_regime_duree (regime_id, duree_jours)
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- TABLE : activites_sportives
-- ------------------------------------------------------------
CREATE TABLE activites_sportives (
    id                  INT AUTO_INCREMENT PRIMARY KEY,
    nom                 VARCHAR(150)    NOT NULL,
    description         TEXT,
    calories_par_heure  DECIMAL(7,2)    COMMENT 'Calories brûlées / heure',
    intensite           ENUM('faible','modérée','élevée') NOT NULL DEFAULT 'modérée',
    est_actif           TINYINT(1)      NOT NULL DEFAULT 1,
    created_at          DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP
                          ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- TABLE : codes_portefeuille
-- ------------------------------------------------------------
CREATE TABLE codes_portefeuille (
    id              INT AUTO_INCREMENT PRIMARY KEY,
    code            VARCHAR(50)     NOT NULL UNIQUE,
    montant         DECIMAL(10,2)   NOT NULL,
    est_utilise     TINYINT(1)      NOT NULL DEFAULT 0,
    utilise_par     INT             DEFAULT NULL,   -- FK utilisateurs
    utilise_le      DATETIME        DEFAULT NULL,
    created_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (utilise_par) REFERENCES utilisateurs(id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- TABLE : abonnements_regime  (souscription d'un utilisateur à un régime)
-- ------------------------------------------------------------
CREATE TABLE abonnements_regime (
    id              INT AUTO_INCREMENT PRIMARY KEY,
    utilisateur_id  INT             NOT NULL,
    regime_id       INT             NOT NULL,
    regime_prix_id  INT             NOT NULL,
    date_debut      DATE            NOT NULL,
    date_fin        DATE            NOT NULL,
    montant_paye    DECIMAL(10,2)   NOT NULL,
    remise_gold     DECIMAL(10,2)   NOT NULL DEFAULT 0.00,
    statut          ENUM('en_cours','termine','annule') NOT NULL DEFAULT 'en_cours',
    created_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (utilisateur_id) REFERENCES utilisateurs(id) ON DELETE CASCADE,
    FOREIGN KEY (regime_id)      REFERENCES regimes(id),
    FOREIGN KEY (regime_prix_id) REFERENCES regime_prix(id)
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- TABLE : abonnements_activite  (activité recommandée avec un abonnement)
-- ------------------------------------------------------------
CREATE TABLE abonnements_activite (
    id                  INT AUTO_INCREMENT PRIMARY KEY,
    abonnement_id       INT     NOT NULL,
    activite_id         INT     NOT NULL,
    seances_par_semaine TINYINT NOT NULL DEFAULT 3,
    duree_seance_min    INT     NOT NULL DEFAULT 45 COMMENT 'Durée en minutes',
    FOREIGN KEY (abonnement_id) REFERENCES abonnements_regime(id) ON DELETE CASCADE,
    FOREIGN KEY (activite_id)   REFERENCES activites_sportives(id)
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- TABLE : admins  (back-office)
-- ------------------------------------------------------------
CREATE TABLE admins (
    id           INT AUTO_INCREMENT PRIMARY KEY,
    nom          VARCHAR(100)  NOT NULL,
    prenom       VARCHAR(100)  NOT NULL,
    email        VARCHAR(150)  NOT NULL UNIQUE,
    mot_de_passe VARCHAR(255)  NOT NULL,
    role         ENUM('super_admin','admin') NOT NULL DEFAULT 'admin',
    est_actif    TINYINT(1)    NOT NULL DEFAULT 1,
    created_at   DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ============================================================
--  DONNÉES MINIMALES
-- ============================================================

-- --- 1 admin par défaut ---
INSERT INTO admins (nom, prenom, email, mot_de_passe, role) VALUES
('Admin', 'Super', 'admin@projet.mg', '$2y$10$exampleHashedPasswordHere', 'super_admin');

-- --- 5 utilisateurs ---
INSERT INTO utilisateurs (nom, prenom, email, mot_de_passe, genre, date_naissance, taille_cm, poids_kg, objectif, solde) VALUES
('Rakoto',   'Jean',    'jean.rakoto@mail.mg',   '$2y$10$hash1', 'homme', '1998-03-15', 175.0, 85.0,  'reduire_poids',   5000.00),
('Rasoa',    'Marie',   'marie.rasoa@mail.mg',   '$2y$10$hash2', 'femme', '2000-07-22', 162.0, 48.0,  'augmenter_poids', 3000.00),
('Andry',    'Lova',    'lova.andry@mail.mg',    '$2y$10$hash3', 'homme', '1995-11-05', 180.0, 95.0,  'imc_ideal',       8000.00),
('Ramiandrisoa','Soa',  'soa.rami@mail.mg',      '$2y$10$hash4', 'femme', '2001-02-28', 158.0, 55.0,  'imc_ideal',       2000.00),
('Razafy',   'Hery',   'hery.razafy@mail.mg',    '$2y$10$hash5', 'homme', '1993-09-10', 170.0, 70.0,  'reduire_poids',   0.00);

-- --- 5 régimes ---
INSERT INTO regimes (nom, description, pct_viande, pct_poisson, pct_volaille, variation_poids_kg, objectif_cible) VALUES
('Régime Équilibré',       'Apport équilibré pour atteindre l\'IMC idéal',           20.0, 25.0, 20.0,  -3.0,  'imc_ideal'),
('Régime Minceur',         'Réduction calorique pour perdre du poids efficacement',   15.0, 30.0, 20.0,  -6.0,  'reduire_poids'),
('Régime Prise de Masse',  'Riche en protéines pour augmenter la masse corporelle',   35.0, 15.0, 30.0,   5.0,  'augmenter_poids'),
('Régime Détox Poisson',   'Dominante poisson, faible en graisses saturées',           5.0, 50.0, 10.0,  -4.0,  'reduire_poids'),
('Régime Volaille & IMC',  'Volaille maigre pour affiner et stabiliser le poids',     10.0, 20.0, 40.0,  -2.0,  'imc_ideal');

-- --- Prix par durée pour chaque régime ---
INSERT INTO regime_prix (regime_id, duree_jours, prix) VALUES
-- Régime 1 : Équilibré
(1,  7,  15000), (1, 14,  25000), (1, 30,  45000), (1, 60,  80000), (1, 90, 110000),
-- Régime 2 : Minceur
(2,  7,  18000), (2, 14,  30000), (2, 30,  55000), (2, 60,  95000), (2, 90, 130000),
-- Régime 3 : Prise de Masse
(3,  7,  20000), (3, 14,  35000), (3, 30,  60000), (3, 60, 105000), (3, 90, 145000),
-- Régime 4 : Détox Poisson
(4,  7,  12000), (4, 14,  22000), (4, 30,  38000), (4, 60,  70000), (4, 90,  95000),
-- Régime 5 : Volaille & IMC
(5,  7,  14000), (5, 14,  24000), (5, 30,  42000), (5, 60,  75000), (5, 90, 100000);

-- --- 5 activités sportives ---
INSERT INTO activites_sportives (nom, description, calories_par_heure, intensite) VALUES
('Course à pied',   'Jogging ou course en extérieur / tapis',        600.0, 'élevée'),
('Natation',        'Nage libre ou aquagym',                         500.0, 'modérée'),
('Vélo',            'Vélo en extérieur ou vélo stationnaire',        450.0, 'modérée'),
('Musculation',     'Exercices avec charges pour tonifier les muscles', 400.0, 'élevée'),
('Yoga / Pilates',  'Étirements, respiration, renforcement doux',    250.0, 'faible');

-- --- 15 codes portefeuille ---
INSERT INTO codes_portefeuille (code, montant) VALUES
('PROMO-A1B2C3',  5000),
('PROMO-D4E5F6', 10000),
('PROMO-G7H8I9',  2000),
('PROMO-J1K2L3', 15000),
('PROMO-M4N5O6',  5000),
('PROMO-P7Q8R9',  8000),
('PROMO-S1T2U3', 20000),
('PROMO-V4W5X6',  3000),
('PROMO-Y7Z8A1', 12000),
('GOLD-B2C3D4',  25000),
('GOLD-E5F6G7',  25000),
('GOLD-H8I9J1',  10000),
('GIFT-K2L3M4',   7000),
('GIFT-N5O6P7',   4000),
('GIFT-Q8R9S1',   6000);

-- ============================================================
-- FIN DU SCRIPT
-- ============================================================