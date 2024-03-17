//Syed Nofel Talha (20K-0151),
//Arhum Hashmi (20K-1892),
//Maarib Ul Haq Siddiqui (20K-0202)

import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

Future<void> createFile(var favorites) async {
  final directory = await getApplicationDocumentsDirectory();
  final file = File('${directory.path}/favorites.json');
  await file.writeAsString(jsonEncode(favorites));
}

Future<List<String>> readFile() async {
  final directory = await getApplicationDocumentsDirectory();
  final file = File('${directory.path}/favorites.json');
  if (await file.exists()) {
    var json = jsonDecode(await file.readAsString());
    var pairs = <String>[];
    for (var x in json) {
      pairs.add(x);
    }
    return pairs;
  }
  return <String>[];
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        title: 'Namer App',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.cyan),
        ),
        home: const MyHomePage(),
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {
  var current = WordPair.random();
  var favourites = <String>[];

  void getNext() {
    current = WordPair.random();
    notifyListeners();
  }

  void toggleFavourite() async {
    final currentString = current.toString();
    if (favourites.contains(currentString)) {
      favourites.remove(currentString);
    } else {
      favourites.add(currentString);
    }
    await createFile(favourites);
    notifyListeners();
  }

  void clearFavourites(int index) {
    favourites.removeAt(index);
    notifyListeners();
  }

  void read() async {
    favourites = await readFile();
    notifyListeners();
  }

  void clearAll() {
    favourites = [];
    notifyListeners();
  }
}

// ...

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    Provider.of<MyAppState>(context, listen: false).read();
  }

  @override
  Widget build(BuildContext context) {
    Widget page;
    switch (selectedIndex) {
      case 0:
        page = const GeneratorPage();
        break;
      case 1:
        page = const FavoritesPage();
        break;
      default:
        throw UnimplementedError('no widget for $selectedIndex');
    }

    return LayoutBuilder(builder: (context, constraints) {
      return Scaffold(
        body: Row(
          children: [
            SafeArea(
              child: NavigationRail(
                extended: constraints.maxWidth >= 1000,
                destinations: const [
                  NavigationRailDestination(
                    icon: Icon(Icons.home),
                    label: Text('Home'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.favorite),
                    label: Text('Favorites'),
                  ),
                ],
                selectedIndex: selectedIndex,
                onDestinationSelected: (value) {
                  setState(() {
                    selectedIndex = value;
                  });
                },
              ),
            ),
            Expanded(
              child: Container(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: page,
              ),
            ),
          ],
        ),
      );
    });
  }
}

class GeneratorPage extends StatelessWidget {
  const GeneratorPage({super.key});
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var pair = appState.current;

    IconData icon;
    if (appState.favourites.contains(pair.toString())) {
      icon = Icons.favorite;
    } else {
      icon = Icons.favorite_border;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          BigCard(pair: pair),
          const SizedBox(height: 10),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  appState.toggleFavourite();
                },
                icon: Icon(icon),
                label: const Text('Like'),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () {
                  appState.getNext();
                },
                child: const Text('Next'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ...

class BigCard extends StatelessWidget {
  const BigCard({
    super.key,
    required this.pair,
  });

  final WordPair pair;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.displayMedium!.copyWith(
      color: theme.colorScheme.onPrimary,
      shadows: const [
        Shadow(
          color: Colors.black,
          offset: Offset(2, 2),
          blurRadius: 4,
        ),
      ],
      backgroundColor: const Color.fromARGB(255, 1, 84, 99),
    );

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      color: theme.colorScheme.primary,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          pair.asLowerCase,
          style: style,
          textScaler: const TextScaler.linear(0.5),
          semanticsLabel: "${pair.first} ${pair.second}",
        ),
      ),
    );
  }
}

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();

    if (appState.favourites.isEmpty) {
      return const Center(
        child: Text('No favorites yet.'),
      );
    }

    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Text('You have '
              '${appState.favourites.length} favorites:'),
        ),
        for (var pair in appState.favourites)
          ListTile(
            leading: const Icon(Icons.favorite),
            title: Text(pair.toLowerCase()),
          ),
        for (var pair in appState.favourites)
          ElevatedButton(
            onPressed: () {
              appState.clearFavourites(
                appState.favourites.indexOf(pair),
              );
            },
            child: const Text('Clear'),
          ),
        ElevatedButton(
          onPressed: () {
            appState.clearAll();
          },
          child: Text('Clear All'),
        )
      ],
    );
  }
}
