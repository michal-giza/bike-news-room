part of 'calendar_bloc.dart';

enum CalendarStatus { initial, loading, loaded, error }

class CalendarState extends Equatable {
  final CalendarStatus status;
  final List<Race> races;
  final String? discipline;
  final String? errorMessage;

  const CalendarState({
    this.status = CalendarStatus.initial,
    this.races = const [],
    this.discipline,
    this.errorMessage,
  });

  CalendarState copyWith({
    CalendarStatus? status,
    List<Race>? races,
    Object? discipline = _sentinel,
    bool clearDiscipline = false,
    Object? errorMessage = _sentinel,
  }) {
    return CalendarState(
      status: status ?? this.status,
      races: races ?? this.races,
      discipline: clearDiscipline
          ? null
          : (identical(discipline, _sentinel)
              ? this.discipline
              : discipline as String?),
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }

  static const _sentinel = Object();

  @override
  List<Object?> get props => [status, races, discipline, errorMessage];
}
