import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/detected_groups_provider.dart';
import '../providers/schedules_provider.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    return Consumer2<DetectedGroupsProvider, SchedulesProvider>(
      builder: (context, groupsProvider, schedulesProvider, _) {
        final filtered = groupsProvider.groups
            .where((g) => g.toLowerCase().contains(_query.toLowerCase()))
            .toList();

        return Scaffold(
          appBar: AppBar(title: const Text('Groups')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(
                decoration: const InputDecoration(
                  hintText: 'Search',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
              const SizedBox(height: 12),
              ...filtered.map((group) {
                final usage = schedulesProvider.schedules
                    .where((s) => s.groups.contains(group))
                    .length;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(group),
                  subtitle: Text('Used in $usage schedule${usage == 1 ? '' : 's'}'),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
