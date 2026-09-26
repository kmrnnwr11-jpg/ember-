import 'package:flutter_riverpod/flutter_riverpod.dart';

/// What the reviewers found for one project, and what has been sent back to
/// be fixed.
///
/// This lives outside the card because the card does not: it is only on screen
/// while the app is finished, so asking for a fix — which starts a build — took
/// the card off the tree and threw the whole list away. The user saw every
/// finding vanish the moment they acted on one, and had to run the review
/// again to get them back.
class ReviewState {
  const ReviewState({this.findings = const [], this.reports = const [], this.fixed = const {}, this.fixing = const {}});

  final List<Map<String, dynamic>> findings;
  final List<Map<String, dynamic>> reports;

  /// Titles already sent to be fixed, and the one being fixed now.
  final Set<String> fixed;
  final Set<String> fixing;

  int get remaining => findings.where((f) => !fixed.contains('${f['title']}')).length;
  bool get allFixed => findings.isNotEmpty && remaining == 0;

  ReviewState copyWith({
    List<Map<String, dynamic>>? findings,
    List<Map<String, dynamic>>? reports,
    Set<String>? fixed,
    Set<String>? fixing,
  }) =>
      ReviewState(
        findings: findings ?? this.findings,
        reports: reports ?? this.reports,
        fixed: fixed ?? this.fixed,
        fixing: fixing ?? this.fixing,
      );
}

/// One entry per project: two apps reviewed in the same session keep their
/// own lists.
class ReviewStates extends Notifier<Map<String, ReviewState>> {
  @override
  Map<String, ReviewState> build() {
    ref.keepAlive();
    return const {};
  }

  ReviewState of(String projectId) => state[projectId] ?? const ReviewState();

  void _set(String projectId, ReviewState s) => state = {...state, projectId: s};

  /// A fresh review replaces everything, including what was marked fixed.
  void found(String projectId, List<Map<String, dynamic>> findings, List<Map<String, dynamic>> reports) =>
      _set(projectId, ReviewState(findings: findings, reports: reports));

  void startFixing(String projectId, String title) {
    final s = of(projectId);
    _set(projectId, s.copyWith(fixing: {...s.fixing, title}));
  }

  void doneFixing(String projectId, String title) {
    final s = of(projectId);
    _set(projectId, s.copyWith(fixing: {...s.fixing}..remove(title), fixed: {...s.fixed, title}));
  }

  /// A fix that failed leaves the finding where it was, still to do.
  void failedFixing(String projectId, String title) {
    final s = of(projectId);
    _set(projectId, s.copyWith(fixing: {...s.fixing}..remove(title)));
  }
}

final reviewStatesProvider = NotifierProvider<ReviewStates, Map<String, ReviewState>>(ReviewStates.new);
