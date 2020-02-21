pragma solidity 0.5.16;
pragma experimental ABIEncoderV2;


contract UserManagement {

    struct User {
        string name;
        address _address;
        uint reputation;
    }
    User[] utilisateurs;
    
    mapping(address => User) admins; // Il peut y avoir plusieurs administrateurs qui sont des utilisateurs qui ont des droits "étendus"
    mapping(address => User) users;  //stocke un élément de structure ' User' pour  chaque utilisateur
    mapping(address => bool) usersBannis; // La liste des utilisateurs bannis
    
    address[] addresses; // les adresses des users pour les administrer

    modifier isAdmin{
        require(admins[msg.sender]._address == msg.sender,"Il faut être adminstrateur.");
        _;
    }
    modifier userNotBannis(){
        require(!usersBannis[msg.sender],"Vous avez été bannis du site.");
        _;
    }
    modifier userExist(address add) {
        require(users[add]._address == add,"Cet utilisateur n'existe pas.");
        _;
    }
    modifier userNotExist() {
        require(users[msg.sender]._address != msg.sender,"Cet utilisateur existe déjà.");
        _;
    }

    /**
     * Celui qui déploi le contract est un administrateur.
     * Cet admin est un User car cela permettra de gérer
     *  sa connexion à la plateforme web comme les autres utilisateurs.
     *  Il est du coup ajouté à la liste des utilisateurs.
     */
    constructor () public {
        User memory admin = User("Administrateur",msg.sender,1);
        admins[msg.sender] = admin;
        users[msg.sender] = admin;
        addresses.push(msg.sender);
    }

    /**
    * L'inscription est réalisé par l'utilisateur.
    *  => L'utilisateur ne doit pas être bannis.
    *  => L'utilistateur ne doit pas s'inscrire plusieurs
    *     fois sinon il voit sa réputation réinitialisée à 1
    */
    function inscription(string memory name) public userNotBannis() userNotExist() {
         User memory u = User(name,msg.sender,1);
         users[msg.sender] = u;
         addresses.push(msg.sender);
    }
   
    /**
     * Pour bannir :
    *   => Seul un admin peut le faire.
    *   => Il faut que l'utilisateur banni soit inscrit.
    *  N.B. L'admin peut bannir un autre admin en tant qu'utilisateur (N.B aucune raison de l'interdire), l'admin bannis reste admin.
    */
    function bannir(address add) public isAdmin userExist(add){
         users[add].reputation = 0;
         usersBannis[add] = true;
     }
    /**
    * Promotion d'un utilisateur au status d'Administrateur
    * voir : https://forum.alyra.fr/t/defi-2-place-de-marche-d-illustrateurs-independants/148/4
    *   Si vous ajoutez les Administrateurs, à vous de choisir la procédure d’ajoute d’admin ( à la construction, par vote,… ).
    *
    * Choix : A la construction, et aussi à la promotion par un autre Administrateur.
    *  => Seul un Administrateur peut promouvoir un user.
    *  => Le User promu doit être inscrit.
    *  => Il est possible de promovoir un user bannis (N.B aucune raison de l'interdire)
    *  N.B. La promotion d'un user déjà admin ne servant à rien elle pourrait être interdite, mais ça complique beaucoup la lecture pour pas grand chose.
    */
    function promotion(address add) public isAdmin userExist(add) {
         admins[add] = users[add];
    }

    function getUser(address add) public view returns (User memory) {
        return users[add];
    }
    function getCurrentUser() public view returns (User memory) {
        return users[msg.sender];
    }
    /**
     * L'utilisateur courant est-il Administrateur?
     */
    function currentUserIsAdmin() public view returns (bool) {
        return admins[msg.sender]._address==msg.sender;
    }
    /**
     * Verifier si l'utilisateur est bannis
     */
    function currentUserIsBanned() public view returns (bool) {
        return usersBannis[msg.sender];
    }
    /**
     * Pour changer le nom de l'utilisateur
     **/
    function changeName(string memory newName) public userExist(msg.sender) {
         users[msg.sender].name = newName;
    }
    /**
    * La liste des adresses des utilisateurs pour les Admin puissent les administrer
    */
    function getAllUserAddress() public view returns (address[] memory){
        return addresses;
    }
    
     //On vérifie que l'utilisateur est bien inscrit 
    function dejaInscris(address utilisateur) public view returns (bool){
        if(users[utilisateur].reputation > 0){
            return true;
        }else {
            return false;
        }
    }
     enum etatDemande{
            Ouverte,
            Encours,
            Fermee
        }
        
    //Liste des demandes d'une entreprise
    struct Demandes{
        address demandeur; // adresse de celui qui formule la demande
        uint remuneration ; // mettre la remuneration en wei
        uint delaiAcceptation; //mettre le delai en seconde
        string descriptionTache;
        etatDemande etats; // etat de la demande
        uint reputationMinimum;
        uint debutDate; // date de début à partir du moment où le demandeur est accepté par l'entreprise
        string lien; // Lien vers le travail de l'illustrateur
    }
  
    //Création tableau des demandes
     Demandes[] public demandes;
     
     //Création de la liste des candidats qui ont postulés 
     struct ListeCandidats{
         address candidatsPostules;
         uint indice;
     }
     
     //Création du tableau des candidats qui ont postulés
     ListeCandidats [] candidats;
     
     //Créer une fonction ajouterDemande() qui permet à une entreprise de formuler une demande. 
     //L’adresse du demandeur doit être inscrite sur la plateforme.  //OK 
     //L’entreprise doit
     //en même temps déposer l’argent sur la plateforme correspondant à la rémunération + 2% de frais pour la plateforme.
     
     //// Il est important de fournir également le
    // mot-clé `payable`, sinon la fonction
    // rejettera automatiquement tous les Ethers qui lui sont envoyés
     function ajouterDemande(uint remuneration, uint delaiAcceptation, string memory description, uint reputationMinimum) 
     public payable {
         
         //Pour chaque demande tu dois vérifier que la rémunération est validée (ne pas oublier les 2% de frais)
         // Tu dois vérifier que l'entreprise est bien inscrite sur la plateforme
   
        require(dejaInscris(msg.sender));
        require(remuneration > 0);
        require(delaiAcceptation > 0);
        require(msg.value >= (remuneration * (100 + 2))/100);
       
       // On remplit alors notre liste de demandes
       // Le lien tu mets string vide, la date de début tu la mets à zéro
       Demandes memory d = Demandes(msg.sender, remuneration, delaiAcceptation, description, etatDemande.Ouverte, reputationMinimum,0,"");
       demandes.push(d);
        }
     
     //Créer une fonction postuler() qui permet à un indépendant de proposer ses services.
     //Il est alors ajouté à la liste des candidats
     function postuler(uint indice) public {
         // Tu dois vérifier qu'il est inscrit sur la plateforme 
         require(dejaInscris(msg.sender));
         //Ne pas oublier : tu dois respecter la réputation minimum  de l'entreprise pour pouvoir postuler 
    require(users[msg.sender].reputation >= demandes[indice].reputationMinimum );
         
         //Il est alors ajouté à la liste des candidats
         ListeCandidats memory c = ListeCandidats(msg.sender, indice);
         candidats.push(c);
     }
     
     //Créer une fonction accepterOffre() qui permet à l’entreprise d’accepter un illustrateur. 
     //La demande est alors ENCOURS jusqu’à sa remise
     
    function accepterOffre(uint indice, address demandeur) public {
        //On vérifie que l'entreprise est bien l'initiatrice de la demande
        require(demandes[indice].demandeur == msg.sender);
        
        // Tu mets à jour ta liste Demandes avec ce nouveau demandeur
        demandes[indice].demandeur=demandeur;
        demandes[indice].etats = etatDemande.Encours;
        demandes[indice].debutDate = now; // il s'agit du délai à partir du moment où le demandeur est accepté
        
    }
    
     //Créer une fonction à part pour le hachage du lien
     function hachageLien (string memory url) public pure returns (bytes32){
         return sha256(abi.encodePacked(url));
     }
     
    // Ecrire une fonction livraison() qui permet à l’illustrateur de remettre le hash du lien
    //où se trouve son travail. Les fonds sont alors automatiquement débloqués et 
    //peuvent être retirés par l’illustrateur. 
    //L’illustrateur gagne aussi un point de réputation
    
    function livraison(uint indice) public{
        // On vérifie que la demande est bien en cours de traitement
        require(demandes[indice].etats == etatDemande.Encours);
        // L'illustrateur remet le hash du lien 
         hachageLien(demandes[indice].lien);
        // On met la demande en Fermée 
        demandes[indice].etats = etatDemande.Fermee;
        // L'illustrateur est payé
        remuneration(msg.sender,demandes[indice].remuneration);
        // L'illustrateur gagne un point de reputation (incrémente)
        users[msg.sender].reputation ++;
    }
    
    // Ajout d'une fonction pour rémunéré l'illustrateur
    function remuneration(address payable illustrateur, uint montant) public{
        illustrateur.transfer(montant); 
        //call.value(montant)(“”)
    }
    
}