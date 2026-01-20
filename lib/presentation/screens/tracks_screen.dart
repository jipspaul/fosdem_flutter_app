import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/track.dart';
import '../../presentation/bloc/track/track_bloc.dart';

class TracksScreen extends StatefulWidget {
  const TracksScreen({super.key});

  @override
  State<TracksScreen> createState() => _TracksScreenState();
}

class _TracksScreenState extends State<TracksScreen> {
  final ScrollController _scrollController = ScrollController();
  static const int _pageSize = 15;
  int _currentPage = 0;
  List<Track> _allTracks = [];
  List<Track> _displayedTracks = [];
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    context.read<TrackBloc>().add(const LoadTracksEvent());
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
      _loadMoreTracks();
    }
  }

  void _loadMoreTracks() {
    if (_displayedTracks.length >= _allTracks.length) return;
    
    setState(() {
      _isLoadingMore = true;
      final startIndex = _currentPage * _pageSize;
      final endIndex = (startIndex + _pageSize).clamp(0, _allTracks.length);
      _displayedTracks.addAll(_allTracks.sublist(startIndex, endIndex));
      _currentPage++;
      _isLoadingMore = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tracks'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _currentPage = 0;
                _displayedTracks.clear();
              });
              context.read<TrackBloc>().add(const LoadTracksEvent());
            },
          ),
        ],
      ),
      body: BlocConsumer<TrackBloc, TrackState>(
        listener: (context, state) {
          if (state is TrackLoadedState) {
            setState(() {
              _allTracks = state.tracks;
              _currentPage = 0;
              _displayedTracks.clear();
              _loadMoreTracks();
            });
          }
        },
        builder: (context, state) {
          if (state is TrackLoadingState && _displayedTracks.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is TrackErrorState && _displayedTracks.isEmpty) {
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
                      context.read<TrackBloc>().add(const LoadTracksEvent());
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (_displayedTracks.isEmpty) {
            return const Center(child: Text('No tracks available'));
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _currentPage = 0;
                _displayedTracks.clear();
              });
              context.read<TrackBloc>().add(const LoadTracksEvent());
            },
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _displayedTracks.length + 1,
              itemBuilder: (context, index) {
                if (index == _displayedTracks.length) {
                  return _displayedTracks.length < _allTracks.length
                      ? const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : const SizedBox.shrink();
                }

                final track = _displayedTracks[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text(track.name),
                    subtitle: track.description.isNotEmpty 
                        ? Text(
                            track.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          )
                        : null,
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      // Navigate to track details
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
