import 'package:flutter/material.dart';
import 'package:tournament_bracket_kit/tournament_bracket_kit.dart';

void main() => runApp(const BracketExampleApp());

class BracketExampleApp extends StatelessWidget {
  const BracketExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tournament Bracket Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2D7A5A),
          brightness: Brightness.light,
        ),
      ),
      home: const BracketDemoPage(),
    );
  }
}

class BracketDemoPage extends StatefulWidget {
  const BracketDemoPage({super.key});

  @override
  State<BracketDemoPage> createState() => _BracketDemoPageState();
}

class _BracketDemoPageState extends State<BracketDemoPage> {
  BracketVariant _variant = BracketVariant.linear;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('tournament_bracket_kit'),
        actions: [
          PopupMenuButton<BracketVariant>(
            initialValue: _variant,
            tooltip: 'Bracket layout',
            icon: const Icon(Icons.account_tree_outlined),
            onSelected: (value) => setState(() => _variant = value),
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: BracketVariant.linear,
                child: Text('Linear (left to right)'),
              ),
              PopupMenuItem(
                value: BracketVariant.mirrored,
                child: Text('Mirrored (final in center)'),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: TournamentBracket(
          rounds: dummyBracketRounds(),
          variant: _variant,
          onMatchTap: (match) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '${match.home?.name ?? 'TBD'} vs ${match.away?.name ?? 'TBD'}',
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
