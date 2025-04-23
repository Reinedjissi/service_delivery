class Categorie {
  final String id;
  final String nom;

  Categorie({required this.id, required this.nom});

  factory Categorie.fromFirestore(String id, Map<String, dynamic> data) {
    return Categorie(
      id: id,
      nom: data['nom'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {'nom': nom};
}
