import '../models/bracket_match.dart';
import '../models/bracket_round.dart';
import '../models/bracket_score.dart';
import '../models/bracket_team.dart';

/// FIFA-style 16-team knockout demo bracket.
///
/// Round of 16 → Quarter Finals → Semi Finals → Final.
List<BracketRound> dummyBracketRounds() {
  const morocco = BracketTeam(id: '1', name: 'Morocco');
  const canada = BracketTeam(id: '2', name: 'Canada');

  const france = BracketTeam(id: '3', name: 'France');
  const paraguay = BracketTeam(id: '4', name: 'Paraguay');

  const norway = BracketTeam(id: '5', name: 'Norway');
  const brazil = BracketTeam(id: '6', name: 'Brazil');

  const england = BracketTeam(id: '7', name: 'England');
  const mexico = BracketTeam(id: '8', name: 'Mexico');

  const spain = BracketTeam(id: '9', name: 'Spain');
  const portugal = BracketTeam(id: '10', name: 'Portugal');

  const belgium = BracketTeam(id: '11', name: 'Belgium');
  const usa = BracketTeam(id: '12', name: 'United States');

  const argentina = BracketTeam(id: '13', name: 'Argentina');
  const egypt = BracketTeam(id: '14', name: 'Egypt');

  const switzerland = BracketTeam(id: '15', name: 'Switzerland');
  const colombia = BracketTeam(id: '16', name: 'Colombia');

  return const [
    BracketRound(
      title: 'Round of 16',
      matches: [
        BracketMatch(
          id: 'r16_1',
          home: morocco,
          away: canada,
          isCompleted: true,
          score: BracketScore(
            homeScore: 3,
            awayScore: 0,
            winnerId: '1',
          ),
        ),
        BracketMatch(
          id: 'r16_2',
          home: france,
          away: paraguay,
          isCompleted: true,
          score: BracketScore(
            homeScore: 1,
            awayScore: 0,
            winnerId: '3',
          ),
        ),
        BracketMatch(
          id: 'r16_3',
          home: norway,
          away: brazil,
          isCompleted: true,
          score: BracketScore(
            homeScore: 2,
            awayScore: 1,
            winnerId: '5',
          ),
        ),
        BracketMatch(
          id: 'r16_4',
          home: england,
          away: mexico,
          isCompleted: true,
          score: BracketScore(
            homeScore: 3,
            awayScore: 2,
            winnerId: '7',
          ),
        ),
        BracketMatch(
          id: 'r16_5',
          home: spain,
          away: portugal,
          isCompleted: true,
          score: BracketScore(
            homeScore: 1,
            awayScore: 0,
            winnerId: '9',
          ),
        ),
        BracketMatch(
          id: 'r16_6',
          home: belgium,
          away: usa,
          isCompleted: true,
          score: BracketScore(
            homeScore: 4,
            awayScore: 1,
            winnerId: '11',
          ),
        ),
        BracketMatch(
          id: 'r16_7',
          home: argentina,
          away: egypt,
          isCompleted: true,
          score: BracketScore(
            homeScore: 3,
            awayScore: 2,
            winnerId: '13',
          ),
        ),
        BracketMatch(
          id: 'r16_8',
          home: switzerland,
          away: colombia,
          isCompleted: true,
          score: BracketScore(
            homeScore: 0,
            awayScore: 0,
            winnerId: '15', // Switzerland won 4-3 on penalties.
          ),
        ),
      ],
    ),
    BracketRound(
      title: 'Quarter Finals',
      matches: [
        BracketMatch(
          id: 'qf_1',
          home: france,
          away: morocco,
          isCompleted: true,
          score: BracketScore(
            homeScore: 2,
            awayScore: 0,
            winnerId: '3',
          ),
        ),
        BracketMatch(
          id: 'qf_2',
          home: spain,
          away: belgium,
          isCompleted: true,
          score: BracketScore(
            homeScore: 2,
            awayScore: 1,
            winnerId: '9',
          ),
        ),
        BracketMatch(
          id: 'qf_3',
          home: england,
          away: norway,
          isCompleted: true,
          score: BracketScore(
            homeScore: 2,
            awayScore: 1,
            winnerId: '7',
          ),
        ),
        BracketMatch(
          id: 'qf_4',
          home: argentina,
          away: switzerland,
          isCompleted: true,
          score: BracketScore(
            homeScore: 3,
            awayScore: 1,
            winnerId: '13',
          ),
        ),
      ],
    ),
    BracketRound(
      title: 'Semi Finals',
      matches: [
        BracketMatch(
          id: 'sf_1',
          home: france,
          away: spain,
        ),
        BracketMatch(
          id: 'sf_2',
          home: england,
          away: argentina,
        ),
      ],
    ),
    BracketRound(
      title: 'Final',
      matches: [
        BracketMatch(
          id: 'final',
        ),
      ],
    ),
  ];
}
