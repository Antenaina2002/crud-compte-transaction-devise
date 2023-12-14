-- Suppression de la base de données existante si elle existe
DROP DATABASE IF EXISTS gestion_portefeuille;

-- Création d'une nouvelle base de données
CREATE DATABASE gestion_portefeuille;

-- Connexion à la nouvelle base de données
\c gestion_portefeuille

-- Table pour les types de devise (par exemple : Euro, Ariary)
CREATE TABLE IF NOT EXISTS devise (
    id SERIAL PRIMARY KEY,
    nom VARCHAR(50) UNIQUE,
    code VARCHAR(3) UNIQUE
);

-- Insertion des devises Euro et Ariary
INSERT INTO devise (nom, code) VALUES
    ('Euro', 'EUR'),
    ('Ariary', 'MGA')
ON CONFLICT (nom) DO NOTHING;

-- Table pour les comptes
CREATE TABLE IF NOT EXISTS compte (
    id SERIAL PRIMARY KEY,
    nom VARCHAR(50),
    solde_montant DECIMAL(15, 2),
    solde_date_maj TIMESTAMP,
    devise INT REFERENCES devise(nom),
    type VARCHAR(20) CHECK (type IN ('Banque', 'Espèce', 'Mobile Money'))
);

-- Table pour les transactions
CREATE TABLE IF NOT EXISTS transaction (
    id SERIAL PRIMARY KEY,
    label VARCHAR(50),
    montant DECIMAL(15, 2),
    date_transaction TIMESTAMP,
    type_transaction VARCHAR(10) CHECK (type_transaction IN ('Débit', 'Crédit')),
    compte_id INT REFERENCES compte(id)
);

-- Table pour les catégories de transactions
CREATE TABLE IF NOT EXISTS catégorie_transaction (
    id SERIAL PRIMARY KEY,
    référence VARCHAR(8) UNIQUE,
    catégorie VARCHAR(50) UNIQUE,
    type_transaction VARCHAR(10) CHECK (type_transaction IN ('Débit', 'Crédit'))
);

-- Insertion des catégories de transactions
INSERT INTO catégorie_transaction (référence, catégorie, type_transaction) VALUES
    (LPAD(FLOOR(RANDOM() * 100000000), 8, '0'), 'alimentation', 'Débit'),
    (LPAD(FLOOR(RANDOM() * 100000000), 8, '0'), 'transport', 'Débit'),
    (LPAD(FLOOR(RANDOM() * 100000000), 8, '0'), 'divertissement', 'Débit'),
    (LPAD(FLOOR(RANDOM() * 100000000), 8, '0'), 'salaire', 'Crédit'),
    (LPAD(FLOOR(RANDOM() * 100000000), 8, '0'), 'transfert_entrant', 'Crédit'),
    (LPAD(FLOOR(RANDOM() * 100000000), 8, '0'), 'pret_debit', 'Débit'),
    (LPAD(FLOOR(RANDOM() * 100000000), 8, '0'), 'pret_credit', 'Crédit')
ON CONFLICT (catégorie) DO NOTHING;

-- Fonction pour insérer une nouvelle transaction
CREATE OR REPLACE FUNCTION fonction_transaction(catégorie VARCHAR, montant DECIMAL)
RETURNS VOID AS $$
DECLARE
    référence_transaction VARCHAR(8);
BEGIN
    SELECT référence INTO référence_transaction
    FROM catégorie_transaction
    WHERE catégorie_transaction.catégorie = catégorie;

    IF référence_transaction IS NOT NULL THEN
        INSERT INTO transaction (label, montant, date_transaction, type_transaction, compte_id)
        VALUES (catégorie, montant, CURRENT_TIMESTAMP, (SELECT type_transaction FROM catégorie_transaction WHERE catégorie = catégorie LIMIT 1), 1); -- Modifier le compte_id selon vos besoins
    ELSE
        RAISE EXCEPTION 'Catégorie de transaction non trouvée.';
    END IF;
END;
$$ LANGUAGE plpgsql;