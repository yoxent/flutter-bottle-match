/// Where a match is in its lifecycle.
///
/// [paused] keeps the previous phase in [MatchSnapshot.resumePhase] so resume
/// restores that exact phase and does not reshuffle the round.
enum MatchPhase {
  setup,
  roundIntroduction,
  playerHandoff,
  activeTurn,
  physicalResultConfirmation,
  roundResult,
  paused,
  championship,
  unfinishedMatch,
}
