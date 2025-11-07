# Pokémon Green Cards (Lab 4 – Mobile Application Development)

This project is a Flutter mobile application that fetches Grass-type Pokémon cards from the public *Pokémon TCG API* and displays them in a scrollable list.  
Users can **view cards**, **save cards locally**, and **open full-size card images** with zoom support.

Local saving is implemented using **Hive (NoSQL local database)**, and card images are efficiently loaded using **cached_network_image**.

## Features:

| Feature | Description |
|--------|-------------|
| Fetch Pokémon card data | Uses Pokémon TCG API to retrieve Grass-type Pokémon card list. |
| Save cards locally | Uses Hive to store selected cards for offline viewing. |
| Full Image View | Clicking a card opens a zoomable detailed view. |
| Offline Support | Saved cards remain even without internet. |
| Toggle UI | Switch between API cards and Saved cards. |

---

## Project Structure

lib/
├── main.dart # App entry point
├── models/
│ └── pokemon_card.dart # Card data model
├── services/
│ └── tcg_api.dart # API fetching logic
└── widgets/
└── card_tile.dart # UI card layout widget

yaml
Copy code

---

## Technologies Used
- **Flutter**
- **Dart**
- **Hive** (Local DB)
- **HTTP Package**
- **Pokémon TCG API**
- **cached_network_image**
- **Material Design 3 UI**

---

## API Used-

**Pokémon TCG API (v2)**  
https://pokemontcg.io/

## Example request:
GET https://api.pokemontcg.io/v2/cards?q=types:grass supertype:pokemon

## CODES THAT I FIX BY WHICH PROJECT RUN SUCCESFULLY:

- Example 1 — Fetching & displaying API cards

>> Incorrect (AI-looking, buggy & inefficient)
Problems: runs network in build(), no state management, no loading/error UI, no caching, and rebuilds refetch every frame.


>> class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Every build triggers a new network request → jank + rate limits
    http.get(Uri.parse("https://api.pokemontcg.io/v2/cards?q=types:grass"))
      .then((res) {
        final jsonMap = json.decode(res.body);
        // This doesn't trigger any UI update or store state safely.
        // Just an example of doing “work” inside build(): BAD.
        print("Got ${jsonMap['data']?.length ?? 0} cards");
      });

  // Shows static text forever; user never sees results.
    return const Scaffold(
      body: Center(child: Text("Fetching cards please wait maybe soon...")),
    );
  }
}


>> Correct Code (from my app: init in initState, FutureBuilder, long list with Save/Remove)

>> class _HomeScreenState extends State<HomeScreen> {
  late Future<List<PokemonCard>> _cards;
  bool showSaved = false;

  @override
  void initState() {
    super.initState();
    _cards = TcgApi.fetchGrassCards(); // fetch once
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
          ? const SizedBox() // (handled fully in Example 2)
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
                          isSaved
                              ? Icons.bookmark_remove_outlined
                              : Icons.bookmark_add,
                        ),
                        tooltip: isSaved ? 'Remove from DB' : 'Save to DB',
                        onPressed: () {
                          if (isSaved) {
                            box.delete(card.id);
                          } else {
                            box.put(card.id, card.toMap());
                          }
                          setState(() {}); // refresh the icon state
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

## Example 2 — Managing saved cards (Hive)

>> Incorrect (AI-looking, wrong persistence)
Problems: tries to put full objects into Hive without serialization, mutates lists inside setState, and re-queries DB inefficiently.


void saveAll(List<PokemonCard> cards) async {
  final box = await Hive.openBox('cardsBox');
  setState(() {
    // Doing heavy work inside setState; also invalid value type for Hive.
    for (final c in cards) {
      box.put(c.id, c); // ❌ Hive expects primitives/Maps unless using adapters
    }
    // Cloning entire list into state – memory heavy and unnecessary
    cachedSaved = List<PokemonCard>.from(cards);
  });
}

// WRONG: Rebuilding a giant Column instead of a builder; no listeners for DB changes.
Widget buildSaved() {
  final box = Hive.box('cardsBox');
  final values = box.values.toList(); // static snapshot; not reactive
  return SingleChildScrollView(
    child: Column(
      children: values.map((v) {
        final name = (v as Map)['name'] ?? 'Unknown';
        return ListTile(title: Text(name));
      }).toList(),
    ),
  );
}


>> Correct Code (from my app: ValueListenableBuilder, toMap()/fromMap(), efficient list builder)

>>
// Toggle branch for "Saved" view in build():
ValueListenableBuilder<Box<Map>>(
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

## Example 3 — Details screen & image loading

>> Incorrect (AI-looking, fragile UX)
Problems: uses Image.network without caching/placeholder/error handling, does zoom math manually, and creates routes inside build() causing rebuild side-effects.


>> class DetailsScreen extends StatelessWidget {
  final PokemonCard card;
  const DetailsScreen({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    // Pushing routes in build() is a side effect; this is just to look “busy”.
    if (card.name.isEmpty) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const Placeholder()));
    }

  double scale = 1.0; // not actually stateful; does nothing real
    return Scaffold(
      appBar: AppBar(title: Text(card.name)),
      body: Center(
        child: Transform.scale(
          scale: scale,
          child: Image.network( // ❌ no placeholder/error widget; no caching
            card.imageUrl,
            fit: BoxFit.fill,
          ),
        ),
      ),
    );
  }
}


>> Correct code (from my app: InteractiveViewer + CachedNetworkImage + graceful placeholders)

>> class DetailsScreen extends StatelessWidget {
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
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
            errorWidget: (ctx, _, __) =>
                const Icon(Icons.broken_image, size: 64),
          ),
        ),
      ),
    );
  }
}



## How to Run Locally
## bash
C:\Users\HP\OneDrive\Desktop\Semester 4\PokemonApp  // its the location where i did everything.
flutter run -d chrome --for Windows:

# sometimes after implementing command flutter run its not showing page, then reload again then its working good.


## GitHub Pages Deployment:
bash
Copy code
flutter build web --release --base-href "/lab4_mobapp/"

rmdir /S /Q docs 2> NUL
mkdir docs
xcopy build\web\* docs\ /E /I /H /Y
type NUL > docs\.nojekyll
copy /Y docs\index.html docs\404.html

git add docs
git commit -m "Update website"
git push

## Live Link:
https://saultjashan0001.github.io/lab4_mobapp/
