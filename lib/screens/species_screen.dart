import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../app_bloc.dart';
import '../data/species_repository.dart';
import '../models/species.dart';
import '../widgets/species_tile.dart';
import 'species_detail_screen.dart';

class SpeciesScreen extends StatefulWidget {
  const SpeciesScreen({super.key, required this.type});

  final SpeciesType type;

  @override
  State<SpeciesScreen> createState() => _SpeciesScreenState();
}

class _SpeciesScreenState extends State<SpeciesScreen> {
  final _searchController = TextEditingController();
  List<SpeciesEntry> _entries = const [];
  bool _loading = true;
  String _query = '';
  bool _myRegionOnly = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final entries = await SpeciesRepository.load(widget.type);
    if (!mounted) return;
    setState(() {
      _entries = entries;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final location = context.watch<AppBloc>().state.location;

    List<String> regionTags = const <String>[];
    if (location != null) {
      regionTags = SpeciesRepository.regionsForLocation(
        location.latitude,
        location.longitude,
      );
    }

    final visibleRegionTags = regionTags
        .where((tag) => tag != 'global')
        .toList();

    List<String>? filterTags;
    if (_myRegionOnly && visibleRegionTags.isNotEmpty) {
      filterTags = regionTags;
    }

    final entries = SpeciesRepository.filter(
      _entries,
      query: _query,
      regionTags: filterTags,
    );

    String title;
    if (widget.type == SpeciesType.fish) {
      title = 'Fish around you';
    } else {
      title = 'Corals & reef life';
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              if (location != null)
                Tooltip(
                  message: _myRegionOnly
                      ? 'Showing species typical for waters around ${location.name}'
                      : 'Showing all species in the guide',
                  child: FilterChip(
                    selected: _myRegionOnly,
                    label: Text(
                      _regionChipLabel(visibleRegionTags),
                      style: const TextStyle(fontSize: 12),
                    ),
                    onSelected: (selected) =>
                        setState(() => _myRegionOnly = selected),
                  ),
                ),
            ],
          ),
        ),
        if (location != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _regionHint(location.name, visibleRegionTags),
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              isDense: true,
              hintText: _searchHint(),
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _query = '');
                      },
                    ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (value) => setState(() => _query = value),
          ),
        ),
        Expanded(child: _buildList(context, entries)),
      ],
    );
  }

  Widget _buildList(BuildContext context, List<SpeciesEntry> entries) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    if (entries.isEmpty) {
      String message;
      if (_query.isEmpty) {
        message =
            'No species tagged for your region yet — '
            'tap the region chip to see the whole guide.';
      } else {
        message = 'Nothing matched "$_query".';
      }

      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 4, bottom: 16),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        return SpeciesTile(
          entry: entry,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) =>
                    SpeciesDetailScreen(entry: entry, type: widget.type),
              ),
            );
          },
        );
      },
    );
  }

  String _regionChipLabel(List<String> visibleRegionTags) {
    if (_myRegionOnly && visibleRegionTags.isNotEmpty) {
      return SpeciesRepository.regionLabel(visibleRegionTags.first);
    }
    return 'All waters';
  }

  String _regionHint(String locationName, List<String> visibleRegionTags) {
    if (_myRegionOnly) {
      if (visibleRegionTags.isEmpty) {
        return 'No region detected — showing the full guide.';
      }
      return 'Common around $locationName';
    }
    return 'Full guide (${_entries.length} species)';
  }

  String _searchHint() {
    if (widget.type == SpeciesType.fish) {
      return 'Search fish…';
    }
    return 'Search corals…';
  }
}
