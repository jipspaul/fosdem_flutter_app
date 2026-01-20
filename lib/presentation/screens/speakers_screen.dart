import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/person.dart';
import '../../presentation/bloc/speaker/speaker_bloc.dart';

class SpeakersScreen extends StatefulWidget {
  const SpeakersScreen({super.key});

  @override
  State<SpeakersScreen> createState() => _SpeakersScreenState();
}

class _SpeakersScreenState extends State<SpeakersScreen> {
  final ScrollController _scrollController = ScrollController();
  static const int _pageSize = 20;
  int _currentPage = 0;
  List<Person> _allSpeakers = [];
  List<Person> _displayedSpeakers = [];
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    context.read<SpeakerBloc>().add(const LoadSpeakersEvent());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isLoadingMore) return;
    
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreSpeakers();
    }
  }

  void _loadMoreSpeakers() {
    if (_displayedSpeakers.length >= _allSpeakers.length) return;
    
    setState(() {
      _isLoadingMore = true;
      final startIndex = _currentPage * _pageSize;
      final endIndex = (startIndex + _pageSize).clamp(0, _allSpeakers.length);
      _displayedSpeakers.addAll(_allSpeakers.sublist(startIndex, endIndex));
      _currentPage++;
      _isLoadingMore = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Speakers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _currentPage = 0;
                _displayedSpeakers.clear();
              });
              context.read<SpeakerBloc>().add(const LoadSpeakersEvent());
            },
          ),
        ],
      ),
      body: BlocConsumer<SpeakerBloc, SpeakerState>(
        listener: (context, state) {
          if (state is SpeakerLoadedState) {
            setState(() {
              _allSpeakers = state.speakers;
              _currentPage = 0;
              _displayedSpeakers.clear();
              _loadMoreSpeakers();
            });
          }
        },
        builder: (context, state) {
          if (state is SpeakerLoadingState && _displayedSpeakers.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is SpeakerErrorState && _displayedSpeakers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(state.message),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<SpeakerBloc>().add(const LoadSpeakersEvent());
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (_displayedSpeakers.isEmpty) {
            return const Center(child: Text('No speakers available'));
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _currentPage = 0;
                _displayedSpeakers.clear();
              });
              context.read<SpeakerBloc>().add(const LoadSpeakersEvent());
            },
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _displayedSpeakers.length + 1,
              itemBuilder: (context, index) {
                if (index == _displayedSpeakers.length) {
                  return _displayedSpeakers.length < _allSpeakers.length
                      ? const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : const SizedBox.shrink();
                }

                final speaker = _displayedSpeakers[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text(speaker.name),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      // Navigate to speaker details
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
