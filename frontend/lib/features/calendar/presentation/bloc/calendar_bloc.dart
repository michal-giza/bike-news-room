import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/race.dart';
import '../../domain/usecases/get_upcoming_races.dart';

part 'calendar_event.dart';
part 'calendar_state.dart';

class CalendarBloc extends Bloc<CalendarEvent, CalendarState> {
  final GetUpcomingRaces getUpcoming;

  CalendarBloc({required this.getUpcoming}) : super(const CalendarState()) {
    on<CalendarRequested>(_onRequested);
    on<CalendarDisciplineChanged>(_onDisciplineChanged);
  }

  Future<void> _onRequested(
    CalendarRequested event,
    Emitter<CalendarState> emit,
  ) async {
    emit(state.copyWith(status: CalendarStatus.loading, errorMessage: null));
    final result = await getUpcoming(
      UpcomingRacesParams(discipline: state.discipline, limit: 60),
    );
    result.fold(
      (f) => emit(state.copyWith(
        status: CalendarStatus.error,
        errorMessage: f.message,
      )),
      (races) => emit(state.copyWith(
        status: CalendarStatus.loaded,
        races: races,
      )),
    );
  }

  Future<void> _onDisciplineChanged(
    CalendarDisciplineChanged event,
    Emitter<CalendarState> emit,
  ) async {
    emit(state.copyWith(discipline: event.discipline, clearDiscipline: event.discipline == null));
    add(const CalendarRequested());
  }
}
