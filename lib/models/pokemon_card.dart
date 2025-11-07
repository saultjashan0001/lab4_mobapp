class PokemonCard {
  final String id;
  final String name;
  final String imageUrl;

  PokemonCard({
    required this.id,
    required this.name,
    required this.imageUrl,
  });

  factory PokemonCard.fromJson(Map<String, dynamic> json) {
    final images = (json['images'] ?? {}) as Map<String, dynamic>;
    return PokemonCard(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Unknown',
      imageUrl: images['large'] as String? ?? images['small'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'imageUrl': imageUrl,
      };

  factory PokemonCard.fromMap(Map<String, dynamic> map) => PokemonCard(
        id: map['id'] as String? ?? '',
        name: map['name'] as String? ?? 'Unknown',
        imageUrl: map['imageUrl'] as String? ?? '',
      );
}
