import 'package:bloc/bloc.dart';
import 'package:diacritic/diacritic.dart';

import '../../models/prevision_model.dart';
import '../../models/service_num_model.dart';
import '../../services/api_service.dart';
import 'previsions_event.dart';
import 'previsions_state.dart';

class PrevisionsBloc extends Bloc<PrevisionsEvent, PrevisionsState> {
  final ApiService apiService;
  final bool useMockData;

  bool isPanelOpen = true;

  String? currentSortCriteria = 'qualiteDeServiceId';
  String? currentSortOrder = 'desc';
  List<String>? currentFilterCriteria;
  String? currentSearchQuery;

  late DateTime? lastUpdate = DateTime.now();

  List<String> currentFilters = [];
  Map<String, bool> expandedGroups = {}; // Pour conserver l'état d'expansion des groupes

  PrevisionsBloc({required this.apiService, this.useMockData = true}) : super(PrevisionsInitial()) {
    on<FetchPrevisionsEvent>(_onFetchPrevisions);
    on<FilterPrevisionsEvent>(_onFilterPrevisions);
    on<SortPrevisionsEvent>(_onSortPrevisions);
    on<SearchPrevisionsEvent>(_onSearchPrevisions);
    on<TogglePrevisionGroupEvent>(_onTogglePrevisionGroup);
    on<ToggleDayPrevisionGroupEvent>(_onToggleDayPrevisionGroup);
    on<OpenAllGroupsEvent>(_onOpenAllGroups);
    on<AddCategoryEvent>(_onAddCategoryEvent);
    on<RemoveCategoryEvent>(_onRemoveCategoryEvent);
  }

  Future<void> _onFetchPrevisions(FetchPrevisionsEvent event, Emitter<PrevisionsState> emit) async {
    if (event.showIndicator) {
      emit(PrevisionsLoading());
    }

    // todo rst : délai pour test
    await Future.delayed(const Duration(milliseconds: 250));

    try {
      final previsions = await _getPrevisions();
      final dayPrevisions = previsions.where((objet) {
        return estMemeJour(objet.dateDebut, DateTime.now().subtract(const Duration(days: 0)));
      }).toList();
      final groupedPrevisions = _groupPrevisionsByMonthAndYear(previsions);

      // Initialise tous les groupes comme étant ouverts
      final expandedGroups = {for (var k in groupedPrevisions.keys) k: true};

      emit(PrevisionsLoaded(
          isDayPanelOpen: isPanelOpen,
          previsionsGroupedByMonth: groupedPrevisions,
          expandedGroups: expandedGroups,
          dayPrevisions: dayPrevisions));
    } catch (e) {
      emit(PrevisionsError(message: e.toString()));
    }
  }

  Map<String, List<PrevisionA>> _groupPrevisionsByMonthAndYear(List<PrevisionA> previsions) {
    Map<String, List<PrevisionA>> grouped = {};
    for (var prevision in previsions) {
      DateTime date = prevision.dateDebut;
      String key = '${date.year}${date.month.toString().padLeft(2, '0')}'; // Format "YYYYMM"

      if (!grouped.containsKey(key)) {
        grouped[key] = [];
      }
      grouped[key]!.add(prevision);
    }
    return grouped;
  }

  void _onAddCategoryEvent(AddCategoryEvent event, Emitter<PrevisionsState> emit) {
    final currentState = state;
    if (currentState is PrevisionsLoaded) {
      final Map<String, bool> expandedGroups = Map.from(currentState.expandedGroups)
        ..updateAll((key, value) => true);

      emit(PrevisionsLoaded(
          previsionsGroupedByMonth: currentState.previsionsGroupedByMonth,
          expandedGroups: expandedGroups,
          isDayPanelOpen: currentState.isDayPanelOpen,
          dayPrevisions: currentState.dayPrevisions));
    }
  }

  void _onRemoveCategoryEvent(RemoveCategoryEvent event, Emitter<PrevisionsState> emit) {
    final currentState = state;
    if (currentState is PrevisionsLoaded) {
      final Map<String, bool> expandedGroups = Map.from(currentState.expandedGroups)
        ..updateAll((key, value) => true); // Mettre à jour tous les états d'expansion sur true

      emit(PrevisionsLoaded(
          previsionsGroupedByMonth: currentState.previsionsGroupedByMonth,
          expandedGroups: expandedGroups,
          isDayPanelOpen: currentState.isDayPanelOpen,
          dayPrevisions: currentState.dayPrevisions));
    }
  }

  void _onOpenAllGroups(OpenAllGroupsEvent event, Emitter<PrevisionsState> emit) {
    final currentState = state;
    if (currentState is PrevisionsLoaded) {
      final Map<String, bool> expandedGroups = Map.from(currentState.expandedGroups)
        ..updateAll((key, value) => true);

      emit(PrevisionsLoaded(
          previsionsGroupedByMonth: currentState.previsionsGroupedByMonth,
          expandedGroups: expandedGroups,
          isDayPanelOpen: currentState.isDayPanelOpen,
          dayPrevisions: currentState.dayPrevisions));
    }
  }

  void _onTogglePrevisionGroup(TogglePrevisionGroupEvent event, Emitter<PrevisionsState> emit) {
    final currentState = state;
    if (currentState is PrevisionsLoaded) {
      String yearMonthKey = event.year + event.month.padLeft(2, '0');

      // Clone l'état actuel des groupes expandus
      final Map<String, bool> expandedGroups = Map<String, bool>.from(currentState.expandedGroups);

      // Bascule l'état d'expansion pour le groupe spécifié
      expandedGroups[yearMonthKey] = !(expandedGroups[yearMonthKey] ?? false);

      emit(PrevisionsLoaded(
          previsionsGroupedByMonth: currentState.previsionsGroupedByMonth,
          expandedGroups: expandedGroups,
          isDayPanelOpen: currentState.isDayPanelOpen,
          dayPrevisions: currentState.dayPrevisions));
    }
  }

  void _onToggleDayPrevisionGroup(ToggleDayPrevisionGroupEvent event, Emitter<PrevisionsState> emit) async {
    final currentState = state;
    isPanelOpen = !isPanelOpen; // Basculez l'état de isPanelOpen
    if (currentState is PrevisionsLoaded) {
      emit(PrevisionsLoaded(
          previsionsGroupedByMonth: currentState.previsionsGroupedByMonth,
          expandedGroups: currentState.expandedGroups,
          isDayPanelOpen: isPanelOpen,
          dayPrevisions: currentState.dayPrevisions));
    }
  }

  void _onFilterPrevisions(FilterPrevisionsEvent event, Emitter<PrevisionsState> emit) async {
    if (event.filterBy == []) {
      resetCriteria();
      currentFilters = [];
    } else {
      currentFilterCriteria = event.filterBy;
      currentFilters = currentFilterCriteria!;
    }
    add(FetchPrevisionsEvent());
  }

  void _onSortPrevisions(SortPrevisionsEvent event, Emitter<PrevisionsState> emit) async {
    // resetCriteria();
    currentSortCriteria = event.sortBy;
    currentSortOrder = event.order;
    add(FetchPrevisionsEvent());
  }

  void _onSearchPrevisions(SearchPrevisionsEvent event, Emitter<PrevisionsState> emit) async {
    // resetCriteria();
    currentSearchQuery = event.query;
    add(FetchPrevisionsEvent());
  }

  void resetCriteria() {
    currentSortCriteria = null;
    currentFilterCriteria = [];
    currentSearchQuery = null;
    add(FetchPrevisionsEvent());
  }

  Future<List<PrevisionA>> _getPrevisions() async {
    List<PrevisionA> previsions;

    previsions = await apiService.fetchMockPrevisions();

    // Apply search filter
    if (currentSearchQuery != null && currentSearchQuery!.isNotEmpty) {
      previsions = previsions
          .where((prevision) =>
          removeDiacritics(prevision.libelle.toLowerCase())
              .contains(removeDiacritics(currentSearchQuery!.toLowerCase())))
          .toList();
    }

    // // Apply category filter
    // if (currentFilterCriteria != null && currentFilterCriteria!.isNotEmpty) {
    //
    //   List<Prevision> previsionupdate = [];
    //   currentFilterCriteria?.forEach((element) {
    //     previsionupdate.addAll(previsions
    //         .where((prevision) =>
    //             prevision.qualiteDeService.toLowerCase() == element)
    //         .toList());
    //   });
    //   previsions = previsionupdate;
    // }

    // // Apply sorting
    // if (currentSortCriteria != null) {
    //   if (currentSortCriteria == "qualiteDeServiceId") {
    //     if (currentSortOrder == 'asc') {
    //       previsions.sort((a, b) => a
    //           .getField(currentSortCriteria!)
    //           .compareTo(b.getField(currentSortCriteria!)));
    //     } else {
    //       previsions.sort((a, b) => b
    //           .getField(currentSortCriteria!)
    //           .compareTo(a.getField(currentSortCriteria!)));
    //     }
    //   } else {
    //     if (currentSortOrder == 'asc') {
    //       previsions.sort((a, b) => a
    //           .getField(currentSortCriteria!)
    //           .compareTo(b.getField(currentSortCriteria!)));
    //     } else {
    //       previsions.sort((a, b) => b
    //           .getField(currentSortCriteria!)
    //           .compareTo(a.getField(currentSortCriteria!)));
    //     }
    //   }
    // }

    return previsions ?? [];
  }

  bool estMemeJour(DateTime date1, DateTime date2) {
    return date1.year == date2.year && date1.month == date2.month && date1.day == date2.day;
  }
}
