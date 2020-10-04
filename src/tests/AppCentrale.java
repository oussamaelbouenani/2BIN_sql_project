package tests;

import java.sql.*;
import java.util.Scanner;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

public class AppCentrale {

	/********** Connexion à la DB **********/

	private Connection conn = null;
	private static final Scanner sc = new Scanner(System.in).useDelimiter("\n|\r\n");
	private String url = "jdbc:postgresql://localhost/projet?user=saiyajin&password=1234";
	//private String url = "jdbc:postgresql://172.24.2.6:5432/dbalexismichiels?user=alexismichiels&password=0BRN6XH75";

	/*Query preparées*/
	private PreparedStatement ajouterSalle;
	private PreparedStatement ajouterArtiste;
	private PreparedStatement ajouterEvenement;
	private PreparedStatement ajouterFestival;
	private PreparedStatement ajouterConcert;
	private PreparedStatement afficherArtistes;
	private PreparedStatement afficherEvenements;
	private PreparedStatement afficherEvenementsEntre;
	private PreparedStatement afficherSalles;
	private PreparedStatement afficherFestivals;

	public AppCentrale() {
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
			ajouterArtiste = conn.prepareStatement			("SELECT projet.ajouter_artiste (?,?)");
			ajouterConcert = conn.prepareStatement			("SELECT projet.ajouter_concert(?,?,?)");
			ajouterEvenement = conn.prepareStatement		("SELECT projet.ajouter_even(?,?,?,?,?)");
			ajouterFestival = conn.prepareStatement			("SELECT projet.ajouter_festival(?)");
			ajouterSalle = conn.prepareStatement			("SELECT projet.ajouter_salle(?,?,?)");
			afficherArtistes = conn.prepareStatement		("SELECT * FROM projet.visualiser_artistes_tries() t(id_artiste INTEGER, nom VARCHAR, nationalite VARCHAR, nb_tickets INTEGER)"); //fonctionne
			afficherEvenements = conn.prepareStatement		("SELECT * FROM projet.visualiser_evenements() t(id_even INTEGER, nom VARCHAR, date DATE, salle VARCHAR, artiste VARCHAR, prix REAL, complet BOOLEAN)"); 		//TODO demander s'il ne faut pas rajouter nom_fest VARCHAR
			afficherEvenementsEntre = conn.prepareStatement	("SELECT * FROM projet.visualiser_evenements(?,?) t(id_even INTEGER, nom VARCHAR, date DATE, salle VARCHAR, artiste VARCHAR, prix REAL, complet BOOLEAN)"); 	//TODO demander s'il ne faut pas rajouter nom_fest VARCHAR
			afficherSalles = conn.prepareStatement			("SELECT * FROM projet.visualiser_salles() t(id_salle INTEGER, nom VARCHAR, ville VARCHAR, capacite INTEGER)");	//fonctionne
			afficherFestivals = conn.prepareStatement		("SELECT * FROM projet.visualiser_festivals() t(id INT, nom VARCHAR, date_debut DATE, date_fin DATE, prix_total REAL);");

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

	/********** Main **********/

	public static void main(String[] args) {

		// TODO Auto-generated method stub

		AppCentrale app = new AppCentrale();

		System.out.println("BIENVENUE DANS L'APPLICATION CENTRALE\n");

		String [] tableChoix = {
			"1. Ajouter une salle",
			"2. Ajouter un artiste",
			"3. Ajouter un événement",
			"4. Ajouter un festival.",
			"5. Ajouter un concert à un événement",
			"6. Visualiser la liste des artistes triés par nombre de tickets réservés",
			"7. Afficher les événements entre deux dates données"
		};

		int choix;

		do {

			for (String s : tableChoix) {
				System.out.println(s);
			}
			System.out.print("Votre choix : ");
			choix = Integer.parseInt(sc.nextLine());

			String nomSalle, villeSalle, nomArtiste, nationaliteArtiste, nomEven, nomFestival;
			int idFest, idSalle, idEven, idArtiste,capaciteSalle;
			float prix;
			Date dateDebut, dateFin;

			switch (choix) {
			case 1:

				System.out.println("Pour introduire une salle entrez :");

				System.out.print("Son nom : ");
				nomSalle = sc.nextLine();

				System.out.print("Sa ville : ");
				villeSalle = sc.nextLine();

				System.out.print("Sa capacité : ");
				capaciteSalle = Integer.valueOf(sc.nextLine());

				app.ajouterSalle(nomSalle, villeSalle, capaciteSalle);

				break;
			case 2:

				System.out.println("Pour ajouter un artiste entrez :");

				System.out.print("Son nom : ");
				nomArtiste = sc.nextLine();

				System.out.print("Sa nationalite (Si non connue appuyez sur ENTER): ");
				nationaliteArtiste = sc.nextLine();

				app.ajouterArtiste(nomArtiste, nationaliteArtiste);

				break;

			case 3:

				System.out.println("Pour introduire un Evenement entrez :");

				System.out.print("Nom : ");
				nomEven = sc.nextLine();

				System.out.print("Entrez la date de l'evenement (Format YYYY-MM-DD): ");
				String d =sc.nextLine();

				Date d2 = Date.valueOf(d);

				System.out.print("Prix : ");
				prix = Float.valueOf(sc.nextLine());

				System.out.println("\nChoisissez une salle parmis celles presentes :");
				app.afficherSalles();
				System.out.println("\n");
				idSalle = Integer.valueOf(sc.nextLine());

				System.out.println("\nChoisissez un festival parmis ceux presents (Entrez 0 si aucun):");
				app.afficherFestivals();
				System.out.println("\n");
				idFest = Integer.valueOf(sc.nextLine());

				app.ajouterEvenement(nomEven, d2, idSalle, prix, idFest);
				System.out.println("\n");
				break;

			case 4:

				System.out.println("Pour ajouter un Festival entrez :");

				System.out.print("Son nom : ");
				nomFestival = sc.nextLine();
				System.out.println("\n");
				app.ajouterFestival(nomFestival);
				System.out.println("\n");
				break;

			case 5:

				System.out.println("Pour ajouter un concert à un evenement, " +
						"Selectionnez un evenement parmis ceux affichés :");
				System.out.println("\n");
				app.afficherEvenements();
				idEven = Integer.valueOf(sc.nextLine());
				System.out.println("\n");

				System.out.println("Ajoutez les info relatives au concert :\n" +
						"L'artiste :");
				app.afficherArtistes();
				idArtiste = Integer.valueOf(sc.nextLine());
				System.out.println("\n");

				System.out.print("L'heure de debut [format = HH:MM:SS]: ");
				Time heure = Time.valueOf(sc.nextLine());
				System.out.println("\n");

				app.ajouterConcert(idArtiste, idEven, heure);
				System.out.println("\n");

				break;

			case 6:

				System.out.println("\nVoici les artistes :\n");
				app.afficherArtistes();
				System.out.println("\n");

				break;

			case 7:

				System.out.println("Pour afficher un ou plusieurs evenements entrez une date de debut et une de fin :");

				System.out.print("La date de debut [format = YYYY:MM:DD]: ");
				dateDebut = Date.valueOf(sc.nextLine());

				System.out.print("La date de fin [format = YYYY:MM:DD]: ");
				dateFin = Date.valueOf(sc.nextLine());

				System.out.println("\nVoici les Evenements entre le "+dateDebut+" et le "+dateFin+" :\n");
				app.afficherEvenementsEntre(dateDebut, dateFin);
				System.out.println("\n");

				break;

			default:
				break;
			}

		} while(choix >= 1 && choix <= tableChoix.length);

		app.close();
	}


	/********** Methodes **********/

	//t(id_festival INTEGER , date_min DATE, date_max DATE, prix_total MONEY)
	private void afficherFestivals() {
		try{
			System.out.println("ID  Nom    DateDébut    DateFin      Prix total");
			try (ResultSet rs = afficherFestivals.executeQuery()){
				while (rs.next()){
					System.out.printf("%-4d%-7s%-13s%-13s%-7.2f€\n", rs.getInt(1), rs.getString(2), rs.getDate(3), rs.getDate(4), rs.getFloat(5));
				}
			}
		} catch (SQLException e){
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

	private void afficherEvenements(){
		try{
			System.out.println("ID  Nom       DateDebut   Salle     Artiste(s)          Prix    Complet");

			try (ResultSet rs = afficherEvenements.executeQuery()){
				while (rs.next()){
					System.out.printf("%-4d%-10s%-12s%-10s%-20s%-8.2f%-10b\n",rs.getInt(1),rs.getString(2),rs.getDate(3),rs.getString(4),rs.getString(5),rs.getFloat(6),rs.getBoolean(7));
				}
			}
		}catch (SQLException e){
			System.out.println(e.getMessage());
		}
	}

	private void afficherEvenementsEntre(Date dateDebut, Date dateFin){
		try{
			afficherEvenementsEntre.setDate(1, dateDebut);
			afficherEvenementsEntre.setDate(2, dateFin);
			System.out.println("ID  Nom       DateDebut   Salle     Artiste(s)          Prix    Complet");

			try (ResultSet rs = afficherEvenementsEntre.executeQuery()){
				while (rs.next()){
					System.out.printf("%-4d%-10s%-12s%-10s%-20s%-8.2f%-10b\n",rs.getInt(1),rs.getString(2),rs.getDate(3),rs.getString(4),rs.getString(5),rs.getFloat(6),rs.getBoolean(7));
				}
			}
		}catch (SQLException e){
			System.out.println(e.getMessage());
		}
	}

	private void ajouterFestival(String nomFestival) {
		try {
			ajouterFestival.setString(1, nomFestival);
			try (ResultSet rs = ajouterFestival.executeQuery()){
				while(rs.next()) {
					System.out.println("\tFestival n°"+ rs.getInt(1)  +" "+ nomFestival+ " ajouté ✅");
				}
			}
		}catch (SQLException e){
			System.out.println(e.getMessage());
		}
	}

	private void ajouterSalle(String nomSalle, String villeSalle, int capaciteSalle) {
		try{
			ajouterSalle.setString(1, nomSalle);
			ajouterSalle.setString(2, villeSalle);
			ajouterSalle.setInt(3, capaciteSalle);
			try (ResultSet rs = ajouterSalle.executeQuery()) {
				while(rs.next()){
					System.out.println("\tLa salle n°"+rs.getInt(1)+" "+nomSalle+", "+villeSalle+" | capacite = "+capaciteSalle+" ajoutée ✅");
				}
			}

		} catch (SQLException e){
			System.out.println(e.getMessage());
		}
	}


	private void ajouterArtiste(String nomArtiste, String nationalite) {
		try{
			ajouterArtiste.setString(1, nomArtiste);
			if (nationalite.equals(""))
				ajouterArtiste.setNull(2, Types.VARCHAR);
			else
				ajouterArtiste.setString(2, nationalite);
			try (ResultSet rs = ajouterArtiste.executeQuery()) {
				while(rs.next()) {
					System.out.println("\tL'artiste n°" + rs.getInt(1) + " " + nomArtiste + " ajouté ✅");
				}
			}

		} catch (SQLException e){
			System.out.println(e.getMessage());
		}
	}
	//nom_even VARCHAR, date_even DATE, id_salle_even INT, prix_even MONEY, id_fest_even INT
	private void ajouterEvenement(String nomEven, Date date, int idSalle, Float prix, int idFest) {
		try{
			ajouterEvenement.setString(1,nomEven);
			ajouterEvenement.setDate(2, date);
			ajouterEvenement.setInt(3, idSalle);
			ajouterEvenement.setFloat(4, prix);
			if(idFest == 0)
				ajouterEvenement.setNull(5, Types.INTEGER);
			else
				ajouterEvenement.setInt(5, idFest);

			try (ResultSet rs = ajouterEvenement.executeQuery()) {
				while (rs.next()) {
					System.out.println("\tEvenement n°" + rs.getInt(1) + " " + nomEven + " | salle : " + idSalle + " ajouté ✅");
				}
			}

		} catch (SQLException e){
			System.out.println(e.getMessage());
		}
	}

	private void ajouterConcert( int idArtiste, int idEven, Time heureDebut) {
		try{
			ajouterConcert.setInt(1, idArtiste);
			ajouterConcert.setInt(2, idEven);
			ajouterConcert.setTime(3, heureDebut);
			try (ResultSet rs = ajouterConcert.executeQuery()) {
				while(rs.next()) {
					System.out.println("\tConcert debutant à " + heureDebut + " ajouté ✅");
				}
			}

		} catch (SQLException e){
			System.out.println(e.getMessage());
		}
	}

}