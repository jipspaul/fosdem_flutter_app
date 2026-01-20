import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../domain/models/journey_models.dart';
import '../bloc/journey_bloc.dart';
import '../bloc/journey_event.dart';

class WishlistWidget extends StatelessWidget {
  final List<JourneyItem> items;

  const WishlistWidget({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              child: Text('${item.priority}'),
            ),
            title: Text(item.eventTitle),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  DateFormat.yMMMd().add_Hm().format(item.startTime),
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.room} • ${item.track}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                final bloc = context.read<JourneyBloc>();
                switch (value) {
                  case 'add':
                    bloc.add(MoveToJourney(item.id));
                    break;
                  case 'remove':
                    bloc.add(RemoveFromJourney(item.id));
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'add',
                  child: Row(
                    children: [
                      Icon(Icons.add_circle),
                      SizedBox(width: 8),
                      Text('Add to journey'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'remove',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Remove', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
