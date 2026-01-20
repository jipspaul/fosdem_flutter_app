import 'package:flutter/material.dart';
import '../../../../domain/entities/event_domain.dart';
import 'package:intl/intl.dart';

class SwipeableEventCard extends StatefulWidget {
  final EventDomain event;
  final VoidCallback onSwipeLeft;
  final VoidCallback onSwipeRight;
  final VoidCallback onSkip;

  const SwipeableEventCard({
    super.key,
    required this.event,
    required this.onSwipeLeft,
    required this.onSwipeRight,
    required this.onSkip,
  });

  @override
  State<SwipeableEventCard> createState() => _SwipeableEventCardState();
}

class _SwipeableEventCardState extends State<SwipeableEventCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _animation;
  Offset _dragOffset = Offset.zero;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = Tween<Offset>(begin: Offset.zero, end: Offset.zero).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails details) {
    setState(() {
      _isDragging = true;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset += details.delta;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    final screenWidth = MediaQuery.of(context).size.width;
    final threshold = screenWidth * 0.3;

    if (_dragOffset.dx.abs() > threshold) {
      // Swipe detected
      final targetOffset = _dragOffset.dx > 0 
          ? Offset(screenWidth * 2, _dragOffset.dy)
          : Offset(-screenWidth * 2, _dragOffset.dy);

      _animation = Tween<Offset>(
        begin: _dragOffset,
        end: targetOffset,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

      _controller.forward(from: 0).then((_) {
        if (_dragOffset.dx > 0) {
          widget.onSwipeRight();
        } else {
          widget.onSwipeLeft();
        }
        _resetCard();
      });
    } else {
      // Return to center
      _animation = Tween<Offset>(
        begin: _dragOffset,
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

      _controller.forward(from: 0).then((_) {
        _resetCard();
      });
    }

    setState(() {
      _isDragging = false;
    });
  }

  void _resetCard() {
    setState(() {
      _dragOffset = Offset.zero;
      _controller.reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    final rotation = _dragOffset.dx / 1000;
    final opacity = 1.0 - (_dragOffset.dx.abs() / 300).clamp(0.0, 1.0);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final offset = _controller.isAnimating ? _animation.value : _dragOffset;

        return Transform.translate(
          offset: offset,
          child: Transform.rotate(
            angle: rotation,
            child: Opacity(
              opacity: opacity,
              child: child,
            ),
          ),
        );
      },
      child: GestureDetector(
        onPanStart: _onPanStart,
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        child: Stack(
          children: [
            _buildCard(),
            _buildSwipeIndicators(),
          ],
        ),
      ),
    );
  }

  Widget _buildCard() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: double.infinity,
        height: double.infinity,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Track badge
            if (widget.event.track?.isNotEmpty == true)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  widget.event.track!,
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            const SizedBox(height: 16),

            // Title
            Text(
              widget.event.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),

            // Time and duration
            Row(
              children: [
                Icon(Icons.access_time, size: 20, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  '${DateFormat('HH:mm').format(widget.event.startTime)} • ${widget.event.duration} min',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Room
            if (widget.event.room.isNotEmpty)
              Row(
                children: [
                  Icon(Icons.location_on, size: 20, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.event.room,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 16),

            // Abstract/Description
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  widget.event.abstract?.isNotEmpty == true 
                      ? widget.event.abstract! 
                      : widget.event.description ?? 'No description available',
                  style: const TextStyle(fontSize: 16, height: 1.5),
                ),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSwipeIndicators() {
    final showLeft = _dragOffset.dx < -50;
    final showRight = _dragOffset.dx > 50;

    return Positioned.fill(
      child: IgnorePointer(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Dislike indicator (left)
            AnimatedOpacity(
              opacity: showLeft ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 100),
              child: Container(
                margin: const EdgeInsets.all(32),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.5),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 48,
                ),
              ),
            ),

            // Like indicator (right)
            AnimatedOpacity(
              opacity: showRight ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 100),
              child: Container(
                margin: const EdgeInsets.all(32),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.5),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.favorite,
                  color: Colors.white,
                  size: 48,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
