/// Generic paginated list state management.
/// Works with any entity type — products, messages, users, etc.
///
/// Usage:
///   final cubit = PaginatedListCubit<Product>(
///     fetcher: (page, size) => productRepo.getProducts(page: page, limit: size),
///   );
///   cubit.loadInitial();

import 'package:flutter_bloc/flutter_bloc.dart';

class PaginatedListState<T> {
  final List<T> items;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasReachedEnd;
  final String? error;
  final int currentPage;

  const PaginatedListState({
    this.items = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasReachedEnd = false,
    this.error,
    this.currentPage = 1,
  });

  PaginatedListState<T> copyWith({
    List<T>? items,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasReachedEnd,
    String? error,
    int? currentPage,
  }) {
    return PaginatedListState<T>(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasReachedEnd: hasReachedEnd ?? this.hasReachedEnd,
      error: error,
      currentPage: currentPage ?? this.currentPage,
    );
  }
}

typedef PageFetcher<T> = Future<List<T>> Function(int page, int pageSize);

class PaginatedListCubit<T> extends Cubit<PaginatedListState<T>> {
  final PageFetcher<T> _fetcher;
  final int pageSize;

  PaginatedListCubit({
    required PageFetcher<T> fetcher,
    this.pageSize = 20,
  })  : _fetcher = fetcher,
        super(const PaginatedListState());

  Future<void> loadInitial() async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final items = await _fetcher(1, pageSize);
      emit(state.copyWith(
        items: items,
        isLoading: false,
        currentPage: 1,
        hasReachedEnd: items.length < pageSize,
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || state.hasReachedEnd) return;
    emit(state.copyWith(isLoadingMore: true));
    try {
      final nextPage = state.currentPage + 1;
      final items = await _fetcher(nextPage, pageSize);
      emit(state.copyWith(
        items: [...state.items, ...items],
        isLoadingMore: false,
        currentPage: nextPage,
        hasReachedEnd: items.length < pageSize,
      ));
    } catch (e) {
      emit(state.copyWith(isLoadingMore: false, error: e.toString()));
    }
  }

  Future<void> refresh() async {
    try {
      final items = await _fetcher(1, pageSize);
      emit(PaginatedListState<T>(
        items: items,
        currentPage: 1,
        hasReachedEnd: items.length < pageSize,
      ));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }
}
