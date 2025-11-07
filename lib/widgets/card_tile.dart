import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/pokemon_card.dart';

class CardTile extends StatelessWidget {
  final PokemonCard card;
  final VoidCallback onTap;
  final Widget? trailing;

  const CardTile({
    super.key,
    required this.card,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CachedNetworkImage(
            imageUrl: card.imageUrl,
            width: 56,
            height: 56,
            fit: BoxFit.cover,
            placeholder: (c, _) => const SizedBox(
              width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2),
            ),
            errorWidget: (c, _, __) => const Icon(Icons.broken_image),
          ),
        ),
        title: Text(card.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(card.id),
        trailing: trailing,
      ),
    );
  }
}
