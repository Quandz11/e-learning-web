import 'dart:async';
import 'package:e_learning_mobile/features/chat/data/chat_repository.dart';
import 'package:e_learning_mobile/features/chat/data/models/chat_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdminChatListState {
  const AdminChatListState({
    this.authenticatedConversations = const [],
    this.guestConversations = const [],
    this.activeTab = 'authenticated',
    this.searchQuery = '',
    this.isLoading = false,
    this.error,
  });

  final List<AdminConversationItem> authenticatedConversations;
  final List<AdminConversationItem> guestConversations;
  final String activeTab; // 'authenticated' | 'guest'
  final String searchQuery;
  final bool isLoading;
  final String? error;

  List<AdminConversationItem> get filteredConversations {
    final list = activeTab == 'guest' ? guestConversations : authenticatedConversations;
    if (searchQuery.trim().isEmpty) return list;
    final q = searchQuery.trim().toLowerCase();
    return list.where((item) {
      final name = item.userName.toLowerCase();
      final msg = (item.lastMessage ?? '').toLowerCase();
      return name.contains(q) || msg.contains(q);
    }).toList();
  }

  int get totalUnreadCount {
    var count = 0;
    for (final c in authenticatedConversations) {
      count += c.unreadCount;
    }
    for (final c in guestConversations) {
      count += c.unreadCount;
    }
    return count;
  }

  AdminChatListState copyWith({
    List<AdminConversationItem>? authenticatedConversations,
    List<AdminConversationItem>? guestConversations,
    String? activeTab,
    String? searchQuery,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return AdminChatListState(
      authenticatedConversations: authenticatedConversations ?? this.authenticatedConversations,
      guestConversations: guestConversations ?? this.guestConversations,
      activeTab: activeTab ?? this.activeTab,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

final adminChatListControllerProvider =
    StateNotifierProvider<AdminChatListController, AdminChatListState>((ref) {
  return AdminChatListController(ref.watch(chatRepositoryProvider));
});

class AdminChatListController extends StateNotifier<AdminChatListState> {
  AdminChatListController(this._repository)
      : super(const AdminChatListState(isLoading: true)) {
    load();
    _setupSignalR();
  }

  final ChatRepository _repository;
  StreamSubscription? _updateSubscription;

  @override
  void dispose() {
    _updateSubscription?.cancel();
    super.dispose();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final res = await _repository.getAdminConversations();
      state = state.copyWith(
        authenticatedConversations: res.authenticatedConversations,
        guestConversations: res.guestConversations,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void _setupSignalR() {
    final signalR = _repository.signalR;
    if (signalR == null) return;

    signalR.connect();

    _updateSubscription?.cancel();
    _updateSubscription = signalR.onConversationUpdated.listen((_) async {
      try {
        final res = await _repository.getAdminConversations();
        state = state.copyWith(
          authenticatedConversations: res.authenticatedConversations,
          guestConversations: res.guestConversations,
        );
      } catch (_) {}
    });
  }

  void setActiveTab(String tab) {
    state = state.copyWith(activeTab: tab);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }
}
