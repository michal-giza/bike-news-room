part of 'calendar_bloc.dart';

sealed class CalendarEvent extends Equatable {
  const CalendarEvent();
  @override
  List<Object?> get props => const [];
}

class CalendarRequested extends CalendarEvent {
  const CalendarRequested();
}

class CalendarDisciplineChanged extends CalendarEvent {
  final String? discipline;
  const CalendarDisciplineChanged(this.discipline);
  @override
  List<Object?> get props => [discipline];
}
