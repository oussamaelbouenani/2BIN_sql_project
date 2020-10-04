    /*
     TABLES
     */
    DROP SCHEMA IF EXISTS projet CASCADE;
    CREATE SCHEMA projet;

    CREATE TABLE projet.festivals (
    id_fest SERIAL PRIMARY KEY,
    nom VARCHAR NOT NULL
        CHECK (nom <> '')
    );

    CREATE TABLE projet.utilisateurs (
        id_util SERIAL PRIMARY KEY,
        email VARCHAR UNIQUE NOT NULL
            CHECK (email ~ '^[A-Za-z0-9._%-]+@[A-Za-z0-9.-]+[.][A-Za-z]+$'),
        nom_util VARCHAR UNIQUE NOT NULL
            CHECK (nom_util SIMILAR TO '[A-Za-z0-9]{2,}'),
        mdp VARCHAR NOT NULL
            CHECK (mdp <> '')
    );

    CREATE TABLE projet.salles (
        id_salle SERIAL PRIMARY KEY,
        nom VARCHAR NOT NULL
           CHECK (nom SIMILAR TO '[A-Za-z0-9\ ]{2,}'),
        ville VARCHAR NOT NULL
           CHECK (ville SIMILAR TO '[\ A-Za-z-]{2,}'),
        capacite INT NOT NULL
           CHECK (capacite > 0),
        UNIQUE (nom, ville)
    );

    CREATE TABLE projet.artistes (
        id_artiste SERIAL PRIMARY KEY,
        nom VARCHAR NOT NULL UNIQUE
            CHECK (nom SIMILAR TO '[A-Za-z ]+'),
        nationalite VARCHAR NULL
            CHECK (nom SIMILAR TO '[A-Za-z]+'),
        nb_tickets INT NOT NULL
            CHECK (nb_tickets >= 0)
    );

    CREATE TABLE projet.evenements (
        id_even SERIAL PRIMARY KEY,
        nom VARCHAR NOT NULL
           CHECK (nom <> ''),
        date DATE NOT NULL,
        id_salle INT NOT NULL
           REFERENCES projet.salles (id_salle),
        prix REAL NOT NULL
           CHECK (prix > 0::REAL),
        id_fest INT NULL
           REFERENCES projet.festivals (id_fest),
        UNIQUE (date, id_salle)
    );

    CREATE TABLE projet.concerts (
         id_artiste INT NOT NULL
             REFERENCES projet.artistes (id_artiste),
         id_even INT NOT NULL
             REFERENCES projet.evenements (id_even),
         horaire TIME NOT NULL,
         CONSTRAINT pk_concert PRIMARY KEY (id_artiste, id_even),
         UNIQUE (horaire, id_even)
    );

    CREATE TABLE projet.reservations(
        num_res INT NOT NULL,
        id_even INT NOT NULL
            REFERENCES projet.evenements (id_even),
        nb_tickets INT NOT NULL
            CHECK (nb_tickets > 0 AND nb_tickets <= 4),
        id_util INT NOT NULL
            REFERENCES projet.utilisateurs (id_util),
        CONSTRAINT pk_res PRIMARY KEY (num_res, id_even)
    );

    /*
     PROCEDURES
     */

    /*
     Récupère les évènements entre la date debut et la date fin
     */
    CREATE OR REPLACE FUNCTION projet.evenements_entre (debut DATE, fin DATE)
        RETURNS SETOF RECORD AS $$
    DECLARE
    BEGIN
        RETURN QUERY (SELECT e.nom AS nom_even, e.date AS date_even, s.nom AS nom_salle, COALESCE(f.nom, 'Non répertorié') AS nom_fest
                      FROM projet.evenements e LEFT OUTER JOIN projet.festivals f
                                                               ON e.id_fest = f.id_fest,
                    projet.salles s
                      WHERE e.date BETWEEN debut AND fin);
    END;
    $$ LANGUAGE plpgsql;

    /*
     Permet d'ajouter une salle
     */
    CREATE OR REPLACE FUNCTION projet.ajouter_salle(nom_salle VARCHAR, ville_salle VARCHAR, capacite_salle INT)
        RETURNS INT AS $$
    DECLARE
        id_return INT;
    BEGIN
        IF nom_salle IS NULL OR nom_salle NOT SIMILAR TO '[a-zA-Z0-9\ ]{2,}' THEN RAISE 'Nom de salle invalide'; END IF;
        IF ville_salle IS NULL OR ville_salle NOT SIMILAR TO '[\ a-zA-Z-]{2,}' THEN RAISE 'Nom de ville invalide'; END IF;
        IF EXISTS(SELECT * FROM projet.salles WHERE nom = nom_salle AND ville = ville_salle) THEN RAISE 'Salle déjà ajoutée'; END IF;
        IF capacite_salle < 1 THEN RAISE 'Capacité invalide'; END IF;
        INSERT INTO projet.salles (nom, ville, capacite) VALUES (nom_salle, ville_salle, capacite_salle) returning id_salle INTO id_return;
        RETURN id_return;
    END;
    $$ LANGUAGE plpgsql;

    /*
     Permet d'ajouter un artiste
     */
    CREATE OR REPLACE FUNCTION projet.ajouter_artiste(nom_artiste VARCHAR, nationalite_artiste VARCHAR)
        RETURNS INT AS $$
    DECLARE
        id_return INT;
    BEGIN
        IF nom_artiste NOT SIMILAR TO '[A-Za-z ]+' THEN RAISE 'Nom d artiste invalide'; END IF;
        IF nationalite_artiste IS NOT NULL AND nationalite_artiste NOT SIMILAR TO '[A-Za-z]+' THEN RAISE 'Nationalité de l artiste invalide'; END IF;
        IF EXISTS(SELECT * FROM projet.artistes WHERE nom = nom_artiste) THEN RAISE 'Artiste déjà ajouté'; END IF;
        INSERT INTO projet.artistes (nom, nationalite, nb_tickets) VALUES (nom_artiste, nationalite_artiste, 0) returning id_artiste INTO id_return;
        RETURN id_return;
    END;
    $$ LANGUAGE plpgsql;

    /*
     Ajoute un évènement
     */
    CREATE OR REPLACE FUNCTION projet.ajouter_even(nom_even VARCHAR, date_even DATE, id_salle_even INT, prix_even REAL, id_fest_even INT)
        RETURNS INT AS $$
    DECLARE
        id_return INT;
    BEGIN
        IF nom_even IS NULL OR nom_even = ''
        THEN RAISE 'Nom d évènement invalide'; END IF;
        IF date_even IS NULL
        THEN RAISE 'Date d évènement vide'; END IF;
        IF date_even < DATE(NOW())
        THEN RAISE 'Date d évènement antérieure'; END IF;
        IF id_salle_even IS NULL
        THEN RAISE 'Salle d évènement invalide'; END IF;
        IF NOT EXISTS(SELECT * FROM projet.salles WHERE id_salle = id_salle_even)
        THEN RAISE 'Salle d évènement inexistante'; END IF;
        IF EXISTS(SELECT * FROM projet.evenements WHERE id_salle = id_salle_even AND date = date_even)
        THEN RAISE 'Salle déjà occupée à cette date'; END IF;
        IF prix_even <= 0::REAL
        THEN RAISE 'Prix d évènement invalide'; END IF;
        IF id_fest_even IS NOT NULL AND NOT EXISTS(SELECT * FROM projet.festivals WHERE id_fest = id_fest_even)
        THEN RAISE 'Festival d évènement inexistant'; END IF;
        INSERT INTO projet.evenements (nom, date, id_salle, prix, id_fest) VALUES (nom_even, date_even, id_salle_even, prix_even, id_fest_even) returning id_even INTO id_return;
        RETURN id_return;
    END;
    $$ LANGUAGE plpgsql;

    /*
     Ajout d'un festival
     */
    CREATE OR REPLACE FUNCTION projet.ajouter_festival(nom_fest VARCHAR)
        RETURNS INT AS $$
    DECLARE
        id_return INT;
    BEGIN
        IF nom_fest IS NULL OR nom_fest = ''
        THEN RAISE 'Nom de festival invalide'; END IF;
        INSERT INTO projet.festivals (nom) VALUES (nom_fest) returning id_fest INTO id_return;
        RETURN id_return;
    END;
    $$ LANGUAGE plpgsql;

    /*
     Ajout d'un concert
     */
    CREATE OR REPLACE FUNCTION projet.ajouter_concert(id_artiste_concert INT, id_even_concert INT, horaire_concert TIME)
        RETURNS INT AS $$
    DECLARE
    BEGIN
        IF NOT EXISTS(SELECT * FROM projet.artistes WHERE id_artiste = id_artiste_concert)
        THEN RAISE 'Artiste de concert inexistant'; END IF;
        IF NOT EXISTS(SELECT * FROM projet.evenements WHERE id_even = id_even_concert)
        THEN RAISE 'Évènement de concert inexistant'; END IF;
        IF EXISTS(SELECT * FROM projet.concerts WHERE horaire = horaire_concert AND id_even = id_even_concert)
        THEN RAISE 'Il y a déjà un concert pour cet even à ce moment là'; END IF;
        IF EXISTS
            (SELECT * FROM projet.concerts c, projet.evenements e, projet.evenements e2
             WHERE e2.id_even = id_even_concert
               AND c.id_artiste = id_artiste_concert
               AND c.id_even = e.id_even
               AND e.date = e2.date)
        THEN RAISE 'L artiste a déjà un évènement ce jour là';
        END IF;
        INSERT INTO projet.concerts (id_artiste, id_even, horaire) VALUES (id_artiste_concert, id_even_concert, horaire_concert);
        RETURN NULL;
    END;
    $$ LANGUAGE plpgsql;

    /*
     Visualiser artistes triés par nbr de tickets réservés
     */
    CREATE OR REPLACE FUNCTION projet.visualiser_artistes_tries()
        RETURNS SETOF RECORD AS $$
    DECLARE
    BEGIN
        RETURN QUERY (SELECT id_artiste, nom, COALESCE(nationalite, 'Non connu'), nb_tickets
                      FROM projet.artistes
                      ORDER BY nb_tickets DESC);
    END;
    $$ LANGUAGE plpgsql;

    /*
     Récupère tous les évènements
     */
    CREATE OR REPLACE FUNCTION projet.visualiser_evenements()
        RETURNS SETOF RECORD AS $$
    DECLARE
        ligne RECORD;
        artiste RECORD;
        artistes VARCHAR;
        sortie RECORD;
        sep VARCHAR;
        estComplet BOOLEAN;
    BEGIN
        FOR ligne IN (SELECT * FROM projet.evenements WHERE date >= DATE(NOW()))
            LOOP
                artistes := '';
                sep := '';
                FOR artiste IN (SELECT *
                                FROM projet.artistes a, projet.concerts c
                                WHERE c.id_artiste = a.id_artiste AND c.id_even = ligne.id_even)
                    LOOP
                        artistes := artistes || sep || artiste.nom;
                        sep := ' + ';
                    END LOOP;
                estComplet := (SELECT SUM(s.capacite) FROM projet.salles s WHERE s.id_salle = ligne.id_salle) = (SELECT COALESCE(SUM(r.nb_tickets), 0) FROM projet.reservations r WHERE r.id_even = ligne.id_even);
                SELECT ligne.id_even, ligne.nom, ligne.date, (SELECT nom FROM projet.salles WHERE id_salle = ligne.id_salle) AS salle, artistes, ligne.prix, estComplet INTO sortie;
                RETURN NEXT sortie;
            END LOOP;
        RETURN;
    END;
    $$ LANGUAGE plpgsql;

    /*
     Récupère tous les évènements d'un festival donné
     */
    CREATE OR REPLACE FUNCTION projet.visualiser_evenements_du_festival(id_fest_even INT)
        RETURNS SETOF RECORD AS $$
    DECLARE
        ligne RECORD;
        artiste RECORD;
        artistes VARCHAR;
        sortie RECORD;
        sep VARCHAR;
        estComplet BOOLEAN;
    BEGIN
        FOR ligne IN (SELECT * FROM projet.evenements WHERE id_fest = id_fest_even)
            LOOP
                artistes := '';
                sep := '';
                FOR artiste IN (SELECT *
                                FROM projet.artistes a, projet.concerts c
                                WHERE c.id_artiste = a.id_artiste AND c.id_even = ligne.id_even)
                    LOOP
                        artistes := artistes || sep || artiste.nom;
                        sep := ' + ';
                    END LOOP;
                estComplet := (SELECT SUM(s.capacite) FROM projet.salles s WHERE s.id_salle = ligne.id_salle) = (SELECT COALESCE(SUM(r.nb_tickets), 0) FROM projet.reservations r WHERE r.id_even = ligne.id_even);
                SELECT ligne.id_even, ligne.nom, ligne.date, (SELECT nom FROM projet.salles WHERE id_salle = ligne.id_salle) AS salle, artistes, ligne.prix, estComplet INTO sortie;
                RETURN NEXT sortie;
            END LOOP;
        RETURN;
    END;
    $$ LANGUAGE plpgsql;

    /*
     Récupère tous les évènements futurs d'une salle donnée
     */
    CREATE OR REPLACE FUNCTION projet.visualiser_evenements_futurs_de_la_salle(id_salle_even INT)
        RETURNS SETOF RECORD AS $$
    DECLARE
        ligne RECORD;
        artiste RECORD;
        artistes VARCHAR;
        sortie RECORD;
        sep VARCHAR;
        estComplet BOOLEAN;
    BEGIN
        FOR ligne IN (SELECT * FROM projet.evenements WHERE id_salle = id_salle_even AND date > DATE(NOW()))
            LOOP
                artistes := '';
                sep := '';
                FOR artiste IN (SELECT *
                                FROM projet.artistes a, projet.concerts c
                                WHERE c.id_artiste = a.id_artiste AND c.id_even = ligne.id_even)
                    LOOP
                        artistes := artistes || sep || artiste.nom;
                        sep := ' + ';
                    END LOOP;
                estComplet := (SELECT SUM(s.capacite) FROM projet.salles s WHERE s.id_salle = ligne.id_salle) = (SELECT COALESCE(SUM(r.nb_tickets), 0) FROM projet.reservations r WHERE r.id_even = ligne.id_even);
                SELECT ligne.id_even, ligne.nom, ligne.date, (SELECT nom FROM projet.salles WHERE id_salle = ligne.id_salle) AS salle, artistes, ligne.prix, estComplet INTO sortie;
                RETURN NEXT sortie;
            END LOOP;
        RETURN;
    END;
    $$ LANGUAGE plpgsql;

    /*
     Récupère tous les évènements futurs
     */
    CREATE OR REPLACE FUNCTION projet.visualiser_evenements_futurs()
        RETURNS SETOF RECORD AS $$
    DECLARE
        ligne RECORD;
        artiste RECORD;
        artistes VARCHAR;
        sortie RECORD;
        sep VARCHAR;
        estComplet BOOLEAN;
    BEGIN
        FOR ligne IN (SELECT * FROM projet.evenements WHERE date > DATE(NOW()))
            LOOP
                artistes := '';
                sep := '';
                FOR artiste IN (SELECT *
                                FROM projet.artistes a, projet.concerts c
                                WHERE c.id_artiste = a.id_artiste AND c.id_even = ligne.id_even)
                    LOOP
                        artistes := artistes || sep || artiste.nom;
                        sep := ' + ';
                    END LOOP;
                estComplet := (SELECT SUM(s.capacite) FROM projet.salles s WHERE s.id_salle = ligne.id_salle) = (SELECT COALESCE(SUM(r.nb_tickets), 0) FROM projet.reservations r WHERE r.id_even = ligne.id_even);
                SELECT ligne.id_even, ligne.nom, ligne.date, (SELECT nom FROM projet.salles WHERE id_salle = ligne.id_salle) AS salle, artistes, ligne.prix, estComplet INTO sortie;
                RETURN NEXT sortie;
            END LOOP;
        RETURN;
    END;
    $$ LANGUAGE plpgsql;


    /*
      Récupère tous les évènements futurs d'un artiste
     */
    CREATE OR REPLACE FUNCTION projet.visualiser_evenements_futurs_de_l_artiste(id_artiste_even INT)
        RETURNS SETOF RECORD AS $$
    DECLARE
        ligne RECORD;
        artiste RECORD;
        artistes VARCHAR;
        sortie RECORD;
        sep VARCHAR;
        estComplet BOOLEAN;
    BEGIN
        FOR ligne IN (SELECT e.* FROM projet.evenements e, projet.concerts c WHERE c.id_artiste = id_artiste_even AND c.id_even = e.id_even AND date > DATE(NOW()))
            LOOP
                artistes := '';
                sep := '';
                FOR artiste IN (SELECT *
                                FROM projet.artistes a, projet.concerts c
                                WHERE c.id_artiste = a.id_artiste AND c.id_even = ligne.id_even)
                    LOOP
                        artistes := artistes || sep || artiste.nom;
                        sep := ' + ';
                    END LOOP;
                estComplet := (SELECT SUM(s.capacite) FROM projet.salles s WHERE s.id_salle = ligne.id_salle) = (SELECT COALESCE(SUM(r.nb_tickets), 0) FROM projet.reservations r WHERE r.id_even = ligne.id_even);
                SELECT ligne.id_even, ligne.nom, ligne.date, (SELECT nom FROM projet.salles WHERE id_salle = ligne.id_salle) AS salle, artistes, ligne.prix, estComplet INTO sortie;
                RETURN NEXT sortie;
            END LOOP;
        RETURN;
    END;
    $$ LANGUAGE plpgsql;

    /*
     Visualiser les évènements entre deux dates
     */
    CREATE OR REPLACE FUNCTION projet.visualiser_evenements(date_debut DATE, date_fin DATE)
        RETURNS SETOF RECORD AS $$
    DECLARE
        ligne RECORD;
        artiste RECORD;
        artistes VARCHAR;
        sortie RECORD;
        sep VARCHAR;
        estComplet BOOLEAN;
    BEGIN
        IF date_fin < date_debut
        THEN RAISE 'La date de fin doit être ultérieure à celle de début'; END IF;
        FOR ligne IN (SELECT * FROM projet.evenements WHERE date >= date_debut AND date <= date_fin)
            LOOP
                artistes := '';
                sep := '';
                FOR artiste IN (SELECT *
                                FROM projet.artistes a, projet.concerts c
                                WHERE c.id_artiste = a.id_artiste AND c.id_even = ligne.id_even)
                    LOOP
                        artistes := artistes || sep || artiste.nom;
                        sep := ' + ';
                    END LOOP;
                estComplet := (SELECT SUM(s.capacite) FROM projet.salles s WHERE s.id_salle = ligne.id_salle) = (SELECT COALESCE(SUM(r.nb_tickets), 0) FROM projet.reservations r WHERE r.id_even = ligne.id_even);
                SELECT ligne.id_even, ligne.nom, ligne.date, (SELECT nom FROM projet.salles WHERE id_salle = ligne.id_salle) AS salle, artistes, ligne.prix, estComplet INTO sortie;
                RETURN NEXT sortie;
            END LOOP;
        RETURN;
    END;
    $$ LANGUAGE plpgsql;


    /*
        affiche les festivals même sans evenements ! //appCentrale !
    */
    CREATE OR REPLACE FUNCTION projet.visualiser_festivals()
        RETURNS SETOF RECORD AS $$
    DECLARE
    BEGIN
        RETURN QUERY (SELECT f.id_fest, f.nom, MIN(e.date) AS date_debut, MAX(e.date) AS date_fin, SUM(e.prix) AS prix_total
                      FROM projet.festivals f LEFT OUTER JOIN projet.evenements e ON e.id_fest = f.id_fest
                      GROUP BY f.id_fest
                      ORDER BY 3);
    END ;
    $$ LANGUAGE plpgsql;

    /*
     Afficher les festivals futurs
     */
    CREATE OR REPLACE FUNCTION projet.visualiser_festivals_futurs()
        RETURNS SETOF RECORD AS $$
    DECLARE
    BEGIN
        RETURN QUERY (SELECT f.id_fest, f.nom, MIN(e.date) AS date_debut, MAX(e.date) AS date_fin, SUM(e.prix) AS prix_total
                      FROM projet.festivals f, projet.evenements e
                      WHERE e.id_fest IS NOT NULL AND f.id_fest = e.id_fest
                      GROUP BY f.id_fest
                      ORDER BY 3);
    END;
    $$ LANGUAGE plpgsql;

    /*
     Ajouter un utilisateur
     */
    CREATE OR REPLACE FUNCTION projet.ajouter_utilisateur(email_util VARCHAR, nom VARCHAR, mdp_util VARCHAR)
        RETURNS INT AS $$
    DECLARE
        id_return INT;
    BEGIN
        IF email_util !~ '^[A-Za-z0-9._%-]+@[A-Za-z0-9.-]+[.][A-Za-z]+$'
        THEN RAISE 'Email invalide'; END IF;
        IF nom !~ '[A-Za-z0-9]{2,}'
        THEN RAISE 'Nom d utilisateur invalide'; END IF;
        IF mdp_util IS NULL OR mdp_util = ''
        THEN RAISE 'Mot de passe invalide'; END IF;
        IF EXISTS(SELECT * FROM projet.utilisateurs WHERE nom_util = nom)
        THEN RAISE 'Nom d utilisateur déjà utilisé'; END IF;
        IF EXISTS(SELECT * FROM projet.utilisateurs WHERE email = email_util)
        THEN RAISE 'Email déjà utilisée'; END IF;
        INSERT INTO projet.utilisateurs (email, nom_util, mdp) VALUES (email_util, nom, mdp_util) returning id_util INTO id_return;
        RETURN id_return;
    END;
    $$ LANGUAGE plpgsql;

    /*
    Réserver des tickets pour un évènement
     */
    CREATE OR REPLACE FUNCTION projet.reserver_tickets(id_util_res INT, id_even_res INT, nb_tickets_res INT)
        RETURNS INT AS $$
    DECLARE
        no_return INT;
        nb_tickets_deja_res_util INT;
        nb_tickets_deja_res_even INT;
        nb_tickets_max INT;
    BEGIN
        IF NOT EXISTS(SELECT * FROM projet.utilisateurs WHERE id_util = id_util_res)
        THEN RAISE 'Utilisateur inexistant'; END IF;
        IF NOT EXISTS(SELECT * FROM projet.evenements WHERE id_even = id_even_res)
        THEN RAISE 'Évènement inexistant'; END IF;
        IF (SELECT date FROM projet.evenements WHERE id_even = id_even_res) < DATE(now())
        THEN RAISE 'Évènement déjà passé'; END IF;
        IF (SELECT COALESCE(count(c), 0) FROM projet.concerts c, projet.evenements e WHERE c.id_even = e.id_even AND e.id_even = id_even_res) = 0
        THEN RAISE 'Évènement sans concert'; END IF;

        SELECT COALESCE(SUM(nb_tickets), 0) as somme FROM projet.reservations WHERE id_even = id_even_res INTO nb_tickets_deja_res_even;
        SELECT capacite FROM projet.salles s, projet.evenements e WHERE e.id_salle = s.id_salle AND e.id_even = id_even_res INTO nb_tickets_max;
        SELECT COALESCE(SUM(nb_tickets), 0) as somme FROM projet.reservations WHERE id_even = id_even_res AND id_util = id_util_res INTO nb_tickets_deja_res_util;
        IF (nb_tickets_res > 4 OR (nb_tickets_deja_res_util + nb_tickets_res) > 4 OR (nb_tickets_deja_res_even + nb_tickets_res) > nb_tickets_max)
        THEN RAISE 'Trop de tickets demandés'; END IF;
        IF EXISTS(
                SELECT * FROM projet.reservations r, projet.evenements e1, projet.evenements e2
            WHERE e1.id_even = id_even_res
            AND e2.id_even <> e1.id_even
            AND e2.date = e1.date
            AND e2.id_even = r.id_even
            AND r.id_util = id_util_res)
        THEN RAISE 'L utilisateur a déjà un évènement ce jour là'; END IF;
        SELECT COALESCE(MAX(num_res), 0) FROM projet.reservations WHERE id_even = id_even_res INTO no_return;
        no_return := no_return + 1;
        INSERT INTO projet.reservations (num_res, id_even, nb_tickets, id_util) VALUES (no_return, id_even_res, nb_tickets_res, id_util_res);
        RETURN no_return;
    END;
    $$ LANGUAGE plpgsql;

    /*
     Mettre à jour nb ickets artiste
     */
    CREATE OR REPLACE FUNCTION projet.update_nb_tickets_artiste()
        RETURNS TRIGGER AS $$
    DECLARE
        nb_tickets_new INT;
        id_even_new INT;
        ligne RECORD;
    BEGIN
        nb_tickets_new := NEW.nb_tickets;
        id_even_new := NEW.id_even;
        FOR ligne IN (SELECT a.* FROM projet.evenements e, projet.concerts c, projet.artistes a
                      WHERE e.id_even = id_even_new AND e.id_even = c.id_even AND c.id_artiste = a.id_artiste) LOOP
                UPDATE projet.artistes SET nb_tickets = (ligne.nb_tickets + nb_tickets_new) WHERE id_artiste = ligne.id_artiste;
            END LOOP;
        RETURN NEW;
    END;
    $$ LANGUAGE plpgsql;

    /*
     Mettre à jour nb tickets artiste
     */
    CREATE OR REPLACE FUNCTION projet.init_nb_tickets_artiste()
        RETURNS TRIGGER AS $$
    DECLARE
        id_even_new INT;
        nb_tickets_even INT;
    BEGIN
        id_even_new := NEW.id_even;
        SELECT COALESCE(SUM(nb_tickets), 0) FROM projet.reservations r WHERE r.id_even = NEW.id_even INTO nb_tickets_even;
        UPDATE projet.artistes SET nb_tickets = (nb_tickets + nb_tickets_even) WHERE id_artiste = NEW.id_artiste;
        RETURN NEW;
    END;
    $$ LANGUAGE plpgsql;

    /*
        Affiche toutes les salles
    */
    CREATE OR REPLACE FUNCTION projet.visualiser_salles()
        RETURNS SETOF RECORD AS $$
    DECLARE
    BEGIN
        RETURN QUERY (SELECT id_salle, nom, ville, capacite
                      FROM projet.salles);
    END;
    $$ LANGUAGE plpgsql;

    CREATE OR REPLACE FUNCTION projet.reserver_tickets_festival(id_util_res INT, id_fest_res INT, nb_tickets_res INT)
        RETURNS INT AS $$
    DECLARE
        ligne RECORD;
    BEGIN
        IF NOT EXISTS(SELECT * FROM projet.festivals WHERE id_fest = id_fest_res)
        THEN RAISE 'Festival inexistant'; END IF;
        IF (nb_tickets_res > 4)
        THEN RAISE 'Trop de tickets demandés'; END IF;
        FOR ligne IN (SELECT * FROM projet.evenements e WHERE e.id_fest = id_fest_res)
            LOOP
                PERFORM (SELECT * FROM projet.reserver_tickets(id_util_res, ligne.id_even, nb_tickets_res));
            END LOOP;
        RETURN id_fest_res;
    END;
    $$ LANGUAGE plpgsql;

    CREATE OR REPLACE FUNCTION projet.visualiser_salles()
        RETURNS SETOF RECORD AS $$
    DECLARE
    BEGIN
        RETURN QUERY (SELECT id_salle, nom, ville, capacite
                      FROM projet.salles);
    END;
    $$ LANGUAGE plpgsql;


    /*
        affiche les reservations de l'utilisateur
    */
    CREATE OR REPLACE FUNCTION projet.visualiser_reservations(id_util_res INTEGER)
        RETURNS SETOF RECORD AS $$
    DECLARE
    BEGIN
       RETURN QUERY(SELECT e.nom, e.date, r.nb_tickets, r.nb_tickets*e.prix as montant_total
                    FROM projet.utilisateurs u, projet.reservations r, projet.evenements e
                    WHERE e.id_even = r.id_even AND r.id_util = u.id_util
                    AND u.id_util = id_util_res
                    ORDER BY e.date DESC);

    END;
    $$ LANGUAGE plpgsql;


    /*
     TRIGGERS
     */
    CREATE TRIGGER trigger_update_nb_tickets_artiste AFTER INSERT ON projet.reservations FOR EACH ROW
    EXECUTE PROCEDURE projet.update_nb_tickets_artiste();

    CREATE TRIGGER trigger_init_nb_tickets_artiste AFTER INSERT ON projet.concerts FOR EACH ROW
    EXECUTE PROCEDURE projet.init_nb_tickets_artiste();

    /*
     DROITS
     */
     /*
    GRANT CONNECT ON DATABASE dbalexismichiels TO oussamaelbouenani;
    GRANT USAGE ON SCHEMA projet TO oussamaelbouenani;
    GRANT USAGE, SELECT ON SEQUENCE projet.utilisateurs_id_util_seq TO oussamaelbouenani;
    GRANT SELECT ON TABLE projet.utilisateurs, projet.festivals, projet.evenements, projet.salles, projet.concerts, projet.artistes, projet.reservations TO oussamaelbouenani;
    GRANT INSERT ON TABLE projet.utilisateurs, projet.festivals, projet.evenements, projet.salles, projet.concerts, projet.artistes, projet.reservations TO oussamaelbouenani;
    */
    /*
     PRE-DEMO
     */
    SELECT projet.ajouter_utilisateur('christophe.damas@vinci.be', 'Damas', '$2a$12$J.KUGJcQfehtFcEkDsZpCOQK8vPDNZC4N1lde1ACT3PvdVtJEYQA2');
    SELECT projet.ajouter_artiste('Eminem',  NULL);
    SELECT projet.ajouter_artiste('Beyonce', NULL);
    SELECT projet.ajouter_salle('Palais 12', 'Bruxelles', 3);
    SELECT projet.ajouter_festival('UCL');