/*
 1
 */
--a
SELECT projet.ajouter_artiste('Madonna', NULL);
--b
SELECT projet.ajouter_salle('Palais 13', 'Bruxelles', 5);
--c
SELECT projet.ajouter_festival('IPL');
--d
SELECT projet.ajouter_even('ev1', '2020/05/12', 1, 10::REAL, 2);
--e
SELECT projet.ajouter_even('ev2', '2020/05/12', 2, 15::REAL, NULL);
--f
SELECT projet.ajouter_even('ev3', '2020/05/13', 2, 20::REAL, 2);
--/g ⛔️
SELECT projet.ajouter_even('ev4', '2020/05/12', 1, 20::REAL, 2);
--h
SELECT projet.ajouter_concert(1, 1, '20:00');
--/i ⛔️
SELECT projet.ajouter_concert(1, 1, '15:00');
--/j ⛔️
SELECT projet.ajouter_concert(3, 1, '20:00');
--/k ⛔️
SELECT projet.ajouter_concert(1, 2, '21:00');
--l
SELECT projet.ajouter_concert(3, 2, '20:00');

/*
 2
 */
--a
SELECT * FROM projet.visualiser_evenements_futurs_de_la_salle(1) t(id INT, nom VARCHAR, date DATE, salle VARCHAR, artistes VARCHAR, prix REAL, estComplet BOOLEAN);
--/b
SELECT * FROM projet.reserver_tickets(1, 1, 4);
--c
SELECT * FROM projet.reserver_tickets(1, 1, 2);
--d
SELECT * FROM projet.visualiser_evenements_futurs_de_la_salle(2) t(id INT, nom VARCHAR, date DATE, salle VARCHAR, artistes VARCHAR, prix REAL, estComplet BOOLEAN);
--/e ⛔️
SELECT * FROM projet.reserver_tickets(1, 2, 1);
--/f ⛔️
SELECT * FROM projet.reserver_tickets(1, 3, 2);

/*
 3
 */
--a
SELECT projet.ajouter_concert(2, 1, '22:00');
--b
SELECT projet.ajouter_concert(2, 3, '22:00');
--c
SELECT * FROM projet.visualiser_artistes_tries() t(id_artiste INT, nom VARCHAR, nationalite VARCHAR, nb_tickets INT);
--d
SELECT * FROM projet.visualiser_evenements('2020/05/10', '2020/05/15') t(id INT, nom VARCHAR, date DATE, salle VARCHAR, artistes VARCHAR, prix REAL, estComplet BOOLEAN);

/*
 4
 */
--a
SELECT * FROM projet.visualiser_festivals_futurs() t(id INT, nom VARCHAR, date_debut DATE, date_fin DATE, prix_total REAL);
--b & c ⛔️
SELECT projet.reserver_tickets_festival(1,2,2);
--d
SELECT projet.reserver_tickets_festival(1,2,1);
--e
SELECT projet.visualiser_evenements_futurs_de_l_artiste(2);
--f
SELECT projet.reserver_tickets(1,3,3);
--g ⛔️
SELECT projet.reserver_tickets(1,3,1);
--h
SELECT projet.visualiser_reservations();
