import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'models/pokemon_card.dart';
import 'services/tcg_api.dart';
import 'widgets/card_tile.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox<Map>('cardsBox'); // store Map<String, dynamic>
  runApp(const PokemonApp());
}

class PokemonApp extends StatelessWidget {
  const PokemonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pokémon Green Cards',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF16a34a)),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<PokemonCard>> _cards;
  bool showSaved = false;

  @override
  void initState() {
    super.initState();
    _cards = TcgApi.fetchGrassCards();
  }

  @override
  Widget build(BuildContext context) {
    final Box<Map> box = Hive.box<Map>('cardsBox');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pokémon Green Cards'),
        actions: [
          IconButton(
            icon: Icon(showSaved ? Icons.cloud : Icons.bookmark),
            onPressed: () => setState(() => showSaved = !showSaved),
            tooltip: showSaved ? 'Show API results' : 'Show Saved (DB)',
          ),
        ],
      ),
      body: showSaved
          ? ValueListenableBuilder<Box<Map>>(
              valueListenable: box.listenable(),
              builder: (context, b, _) {
                final savedCards = b.values
                    .map((m) => PokemonCard.fromMap(Map<String, dynamic>.from(m)))
                    .toList();

                if (savedCards.isEmpty) {
                  return const Center(child: Text('No saved cards yet'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: savedCards.length,
                  itemBuilder: (context, i) => CardTile(
                    card: savedCards[i],
                    onTap: () => openDetails(savedCards[i]),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => b.delete(savedCards[i].id),
                      tooltip: 'Remove from DB',
                    ),
                  ),
                );
              },
            )
          : FutureBuilder<List<PokemonCard>>(
              future: _cards,
              builder: (context, AsyncSnapshot<List<PokemonCard>> snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(child: Text('Error: ${snap.error}'));
                }
                final cards = snap.data ?? const <PokemonCard>[];
                if (cards.isEmpty) {
                  return const Center(child: Text('No cards found.'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: cards.length,
                  itemBuilder: (context, i) {
                    final card = cards[i];
                    final isSaved = box.containsKey(card.id);
                    return CardTile(
                      card: card,
                      onTap: () => openDetails(card),
                      trailing: IconButton(
                        icon: Icon(
                          isSaved ? Icons.bookmark_remove_outlined : Icons.bookmark_add,
                        ),
                        tooltip: isSaved ? 'Remove from DB' : 'Save to DB',
                        onPressed: () {
                          if (isSaved) {
                            box.delete(card.id);
                          } else {
                            box.put(card.id, card.toMap());
                          }
                          setState(() {});
                        },
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  void openDetails(PokemonCard card) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DetailsScreen(card: card)),
    );
  }
}

class DetailsScreen extends StatelessWidget {
  final PokemonCard card;
  const DetailsScreen({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(card.name)),
      body: Center(
        child: InteractiveViewer(
          boundaryMargin: const EdgeInsets.all(24),
          minScale: 0.5,
          maxScale: 4.0,
          child: CachedNetworkImage(
            imageUrl: card.imageUrl,
            fit: BoxFit.contain,
            placeholder: (ctx, _) =>
                const Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()),
            errorWidget: (ctx, _, __) => const Icon(Icons.broken_image, size: 64),
          ),
        ),
      ),
    );
  }
}
