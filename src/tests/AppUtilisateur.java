package tests;

import jbcrypt.BCrypt;

import java.sql.*;
import java.util.Scanner;

public class AppUtilisateur {


    /***** Connection DB *****/

    private Connection conn = null;
    private static final Scanner sc = new Scanner(System.in).useDelimiter("\n|\r\n");
    private String url = "jdbc:postgresql://localhost/projet?user=saiyajin&password=1234";
    //private String url = "jdbc:postgresql://172.24.2.6:5432/dbalexismichiels?user=oussamaelbouenani&password=Mecv363!";
    private static int idUtilisateur = 0;
    private static AppUtilisateur app;

    /***** Preparation des query *****/

    private PreparedStatement connecterUtil;
    private PreparedStatement inscrireUtil;
    private PreparedStatement voirFestFuturs;
    private PreparedStatement voirEvenFutursArtiste;
    private PreparedStatement voirEvenFutursSalle;
    private PreparedStatement reserverTickets;
    private PreparedStatement reserverTicketsFestival;
    private PreparedStatement afficherSalles;
    private PreparedStatement afficherArtistes;
    private PreparedStatement voirReservations;

    public AppUtilisateur(){

        try {
            Class.forName("org.postgresql.Driver");
        } catch (ClassNotFoundException e) {
            System.out.println("Driver PostgreSQL manquant !");
            System.exit(1);
        }
        try {
            conn = DriverManager.getConnection(url);
        } catch (SQLException e) {
            System.out.println("Impossible de joindre le server !");
            System.exit(1);
        }
        try {

            /*Definition de mes query*/
            connecterUtil = conn.prepareStatement           ("SELECT id_util, mdp FROM projet.utilisateurs WHERE nom_util = ?");
            inscrireUtil = conn.prepareStatement            ("SELECT projet.ajouter_utilisateur(?,?,?)");
            voirFestFuturs = conn.prepareStatement          ("SELECT * FROM projet.visualiser_festivals_futurs() t(id_fest INTEGER, nom_fest VARCHAR, date_debut DATE, date_fin DATE, prixTotal REAL)");
            voirEvenFutursSalle = conn.prepareStatement     ("SELECT * FROM projet.visualiser_evenements_futurs_de_la_salle(?) t(id_even INTEGER, nom VARCHAR, date DATE, nom_salle VARCHAR, artistes VARCHAR, prix REAL, complet BOOLEAN)");
            voirEvenFutursArtiste = conn.prepareStatement   ("SELECT * FROM projet.visualiser_evenements_futurs_de_l_artiste(?) t(id_even INTEGER, nom VARCHAR, date DATE, nom_salle VARCHAR, artistes VARCHAR, prix REAL, complet BOOLEAN)");
            reserverTickets = conn.prepareStatement         ("SELECT projet.reserver_tickets(?,?,?)");
            reserverTicketsFestival = conn.prepareStatement ("SELECT projet.reserver_tickets_festival(?,?,?)");
            afficherSalles = conn.prepareStatement          ("SELECT * FROM projet.visualiser_salles() t(id_salle INTEGER, nom VARCHAR, ville VARCHAR, capacite INTEGER)");	//fonctionne
            afficherArtistes = conn.prepareStatement		("SELECT * FROM projet.visualiser_artistes_tries() t(id_artiste INTEGER, nom VARCHAR, nationalite VARCHAR, nb_tickets INTEGER)"); //fonctionne
            voirReservations = conn.prepareStatement		("SELECT * FROM projet.visualiser_reservations(?) t(nom VARCHAR, date DATE, nb_tickets INT, montant_total DOUBLE PRECISION)");

        } catch (SQLException e) {
            System.out.println("Erreur avec les requêtes SQL !");
            System.exit(1);
        }
    }

    public void close() {
        try {
            conn.close();
        } catch (SQLException e) {
            e.printStackTrace();
        }
    }

    /***** Main *****/

    public static void main(String[] args){

        app = new AppUtilisateur();

        System.out.println("BIENVENUE DANS L'APPLICATION UTILISATEUR\n");

        String [] tableChoix = {
                "1.     Se connecter",
                "2.     S'inscrire",
                "3.     Quitter "
        };

        int choix;

        do {

            for (String s: tableChoix
            ) {
                System.out.println(s);
            }
            System.out.println(" ");

            String pseudo, motDePasse, motDePasse2, email;

            choix = Integer.valueOf(sc.nextLine());

            switch (choix) {
                case 1 :
                    System.out.println("Pour vous connecter,");
                    System.out.print("Entrez votre nom d'utilisateur : ");
                    pseudo = sc.nextLine();

                    System.out.print("Entrez votre mot de passe : ");
                    motDePasse = sc.nextLine();
                    String mdpCrypt = "";
                    try{
                        app.connecterUtil.setString(1,pseudo);
                        try(ResultSet rs = app.connecterUtil.executeQuery()){
                            rs.next();
                            idUtilisateur = rs.getInt(1);
                            mdpCrypt = rs.getString(2);
                        }

                    } catch (SQLException e){
                        e.getMessage();
                    }

                    if (idUtilisateur == 0
                            || !BCrypt.checkpw(motDePasse, mdpCrypt)){
                        System.out.println("Pseudo ou mdp incorrect");
                        break;
                    }

                    System.out.println("Votre ID = "+idUtilisateur);

                    menuUtilisateur();
                    System.out.println("\n");
                    break;

                case 2 :

                    System.out.println("Pour vous inscrire,");

                    System.out.print("Entrez votre adresse mail : ");
                    email = sc.nextLine();

                    System.out.print("Entrez votre nom d'utilisateur : ");
                    pseudo = sc.nextLine();

                    do {
                        System.out.print("Entrez votre mot de passe : ");
                        motDePasse = sc.nextLine();

                        System.out.print("Confirmez votre mot de passe : ");
                        motDePasse2 = sc.nextLine();

                    } while(!motDePasse.equals(motDePasse2));

                    app.inscrireUtil(email, pseudo, motDePasse);

                    System.out.println("\n");
                    break;

                default:
                    System.out.println("\n");
                    break;

            }

        }while(choix >= 1 && choix <= tableChoix.length-1);

        app.close();

    }

    private void inscrireUtil(String email, String pseudo, String motDePasse) {

        try{
            inscrireUtil.setString(1, email);
            inscrireUtil.setString(2, pseudo);
            inscrireUtil.setString(3, BCrypt.hashpw(motDePasse, BCrypt.gensalt(12)));

            try(ResultSet rs = inscrireUtil.executeQuery()){
                while(rs.next()){
                    System.out.println("Bienvenue "+pseudo+", vous pouvez désormais vous connecter 😊");
                }
            }

        } catch(SQLException e){
            e.getMessage();
        }
    }

    private static void menuUtilisateur() {

        int choix2;

        String[] tabChoix = {
                "1.     Voir les événements futurs",
                "2.     Voir les festivals futurs",
                "3.     Voir ses reservations",
                "4.     Se Déconnecter"
        };
        System.out.println(" ");

        do {
            for (String s: tabChoix
            ) {
                System.out.println(s);
            }

            choix2 = Integer.valueOf(sc.nextLine());

            switch (choix2){
                case 1:
                    app.voirEvenFuturs();
                    System.out.println("\n");
                    break;
                case 2:
                    app.voirFestFuturs();
                    System.out.println("\n");
                    System.out.println("\nReserver ticket ? [o][n]\n");
                    char res = sc.nextLine().charAt(0);

                    if (res == 'o')
                        app.reservationTicketsFestivals();
                    System.out.println("\n");
                    break;

                case 3:
                    System.out.println("Voici vos reservations : ");
                    app.voirReservations();
                    System.out.println("\n");
                    break;

                default:
                    System.out.println("\n");
                    break;
            }

        }while (choix2 >= 1 && choix2 <= tabChoix.length-1);


    }

    private void voirReservations() {
        try{
            voirReservations.setInt(1, idUtilisateur);
            System.out.println("Even      Date          NbTickets   MontantTotal");
            try(ResultSet rs = voirReservations.executeQuery()){
                while(rs.next())
                    System.out.printf("%-10s%-14s%-12d%-5.2f€\n", rs.getString(1), rs.getDate(2), rs.getInt(3),rs.getFloat(4));
            }
        }catch (SQLException e){
            System.out.println(e.getMessage());
        }
    }

    private void voirEvenFuturs() {

        String tabChoix [] = {
                "1.     Voir les événements d’une salle particulière triés par date",
                "2.     Voir les événements auxquels participe un artiste particulier triés par date",
                "3.     Retour"
        };

        int choix;
        char res;

        do {
            for (String s: tabChoix
            ) {
                System.out.println(s);
            }

            choix = Integer.valueOf(sc.nextLine());

            switch (choix){
                case 1:
                    afficherSalles();
                    System.out.print("\nChoisissez une salle : ");
                    int salle = Integer.valueOf(sc.nextLine());

                    System.out.println("\nVoici les evenements relatifs à cette salle :\n");
                    afficherEvenementsSalle(salle);
                    System.out.println("\nReserver ticket ? [o][n]\n");
                    res = sc.nextLine().charAt(0);

                    if (res == 'o')
                        app.reservationTickets();

                    System.out.println("\n");
                    break;

                case 2:
                    System.out.println("\n");
                    app.afficherArtistes();
                    System.out.print("\nchoisissez le numero d'un artiste : ");
                    int artiste = Integer.valueOf(sc.nextLine());

                    System.out.println("\nVoici les evenements relatifs à cet(te) artiste :\n");
                    app.afficherEvenementsArtiste(artiste);
                    System.out.println("\nReserver ticket ? [o][n]\n");
                    res = sc.nextLine().charAt(0);

                    if (res == 'o')
                        app.reservationTickets();
                    System.out.println("\n");
                    break;


                default:
                    System.out.println("\n");
                    break;
            }


        }while (choix >=1 && choix <=tabChoix.length-1);

    }

    private void afficherEvenementsArtiste(int artiste) {
        try{
            voirEvenFutursArtiste.setInt(1, artiste);
            System.out.println("ID  Nom       DateDebut   Salle     Artiste(s)          Prix    Complet");
            try(ResultSet rs = voirEvenFutursArtiste.executeQuery()){
                while(rs.next()){
                    System.out.printf("%-4d%-10s%-12s%-10s%-20s%-8.2f%-10b\n",rs.getInt(1),rs.getString(2),rs.getDate(3),rs.getString(4),rs.getString(5),rs.getFloat(6),rs.getBoolean(7));
                }
            }
        } catch(SQLException e){
            System.out.println(e.getMessage());
        }
    }

    private void afficherEvenementsSalle(int salle) {
        System.out.println("ID  Nom       DateDebut   Salle     Artiste(s)          Prix    Complet");

        try{
            voirEvenFutursSalle.setInt(1, salle);
            try(ResultSet rs = voirEvenFutursSalle.executeQuery()){
                while(rs.next()){
                    System.out.printf("%-4d%-10s%-12s%-10s%-20s%-8.2f%-10b\n",rs.getInt(1),rs.getString(2),rs.getDate(3),rs.getString(4),rs.getString(5),rs.getFloat(6),rs.getBoolean(7));
                }
            }
        } catch(SQLException e){
            System.out.println(e.getMessage());
        }
    }

    private void afficherSalles() {
        try{
            System.out.println("ID  Nom       Ville     Capacite");
            try (ResultSet rs = afficherSalles.executeQuery()){
                while (rs.next()){
                    System.out.printf("%-4d%-10s%-10s%4d\n",rs.getInt(1),rs.getString(2),rs.getString(3),rs.getInt(4));
                }
            }
        } catch (SQLException e){
            System.out.println(e.getMessage());
        }
    }

    private void afficherArtistes() {
        try{
            System.out.println("ID  Nom       Origine     TicketsVendus");
            try (ResultSet rs = afficherArtistes.executeQuery()){
                while (rs.next()){
                    System.out.printf("%-4d%-10s%-15s%4d\n",rs.getInt(1),rs.getString(2),rs.getString(3),rs.getInt(4));
                }
            }
        }catch (SQLException e){
            System.out.println(e.getMessage());
        }
    }

    private void voirFestFuturs() {
        try{

            System.out.println("ID  Nom    DateDébut    DateFin      Prix total");
            try(ResultSet rs = app.voirFestFuturs.executeQuery()){
                while(rs.next()){
                    System.out.printf("%-4d%-7s%-13s%-13s%-7.2f€\n", rs.getInt(1), rs.getString(2), rs.getDate(3), rs.getDate(4), rs.getFloat(5));
                }
            }
        } catch(SQLException e){
            System.out.println(e.getMessage());
        }
    }

    private void reservationTickets(){
        System.out.println("Entrez le numero d'evenement :");
        int idEvent = Integer.valueOf(sc.nextLine());

        System.out.println("\nNombre de tickets desirés : ");
        int nbTickets = Integer.valueOf(sc.nextLine());

        try{
            reserverTickets.setInt(1, idUtilisateur);
            reserverTickets.setInt(2, idEvent);
            reserverTickets.setInt(3, nbTickets);
            try (ResultSet rs = reserverTickets.executeQuery()){
                while(rs.next()) {
                   System.out.println("Réservation n°" + rs.getInt(1) + " pour l'évènement " + idEvent + " a bien été enregistrée ✅");
                }
            }
        }catch (SQLException e){
            System.out.println(e.getMessage());
        }
    }

    private void reservationTicketsFestivals(){
        System.out.print("Choisissez un festival : ");
        int idFest = Integer.valueOf(sc.nextLine());

        System.out.print("Nombre de reservation désirées : ");
        int nbTickets = Integer.valueOf(sc.nextLine());
        System.out.println(nbTickets);

        try{
            reserverTicketsFestival.setInt(1, idUtilisateur);
            reserverTicketsFestival.setInt(2, idFest);
            reserverTicketsFestival.setInt(3, nbTickets);

            try(ResultSet rs = reserverTicketsFestival.executeQuery()){
                while (rs.next())
                    System.out.println("Reservation n°"+rs.getInt(1)+" pour le festival "+idFest+" a bien été enregistrée ✅");
            }

        }catch (SQLException e){
            System.out.println(e.getMessage());
        }

    }
}
