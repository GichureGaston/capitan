import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../app_bloc.dart';
import '../data/species_repository.dart';
import '../models/sea_location.dart';
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
    final location =
        context.select<AppBloc, SeaLocation?>((bloc) => bloc.state.location);

    final regionTags = location == null
        ? const <String>[]
        : SpeciesRepository.regionsForLocation(location.latitude, location.longitude);
    final visibleRegionTags = regionTags.where((t) => t != 'global').toList();

    final entries = SpeciesRepository.filter(
      _entries,
      query: _query,
      regionTags: _myRegionOnly && visibleRegionTags.isNotEmpty ? regionTags : null,
    );

    final title = switch (widget.type) {
      SpeciesType.fish => 'Fish around you',
      SpeciesType.coral => 'Corals & reef life',
    };

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
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
                      _myRegionOnly
                          ? (visibleRegionTags.isEmpty
                              ? 'All waters'
                              : SpeciesRepository.regionLabel(visibleRegionTags.first))
                          : 'All waters',
                      style: const TextStyle(fontSize: 12),
                    ),
                    onSelected: (selected) => setState(() => _myRegionOnly = selected),
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
                _myRegionOnly && visibleRegionTags.isEmpty
                    ? 'No region detected — showing the full guide.'
                    : _myRegionOnly
                        ? 'Common around ${location.name}'
                        : 'Full guide (${_entries.length} species)',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
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
              hintText: switch (widget.type) {
                SpeciesType.fish => 'Search fish…',
                SpeciesType.coral => 'Search corals…',
              },
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
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onChanged: (value) => setState(() => _query = value),
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
              : entries.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          _query.isEmpty
                              ? 'No species tagged for your region yet — '
                                  'tap the region chip to see the whole guide.'
                              : 'Nothing matched "$_query".',
                          textAlign: TextAlign.center,
                          style:
                              TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(top: 4, bottom: 16),
                      itemCount: entries.length,
                      itemBuilder: (context, index) => SpeciesTile(
                        entry: entries[index],
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => SpeciesDetailScreen(
                              entry: entries[index],
                              type: widget.type,
                            ),
                          ),
                        ),
                      ),
                    ),
        ),
      ],
    );
  }
}
