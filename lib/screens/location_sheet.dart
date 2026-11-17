import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../app_bloc.dart';
import '../models/sea_location.dart';
import '../services/open_meteo.dart';

Future<void> showLocationSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const _LocationSheet(),
  );
}

class _LocationSheet extends StatefulWidget {
  const _LocationSheet();

  @override
  State<_LocationSheet> createState() => _LocationSheetState();
}

class _LocationSheetState extends State<_LocationSheet> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  Timer? _debounce;
  List<SeaLocation> _results = const [];
  String? _error;
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged(String value, OpenMeteoApi api) {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 400),
      () => _runSearch(value, api),
    );
  }

  Future<void> _runSearch(String value, OpenMeteoApi api) async {
    final query = value.trim();
    if (query.length < 2) {
      setState(() {
        _results = const [];
        _error = null;
      });
      return;
    }
    setState(() => _searching = true);
    try {
      final results = await api.searchLocations(query);
      if (!mounted) return;
      setState(() {
        _results = results;
        if (results.isEmpty) {
          _error = 'No places matched "$query".';
        } else {
          _error = null;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _results = const [];
        _error = 'Search failed: $e';
      });
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final locating = context.watch<AppBloc>().state.locating;
    final scheme = Theme.of(context).colorScheme;
    final viewInsets = MediaQuery.of(context).viewInsets;

    Widget locatingIcon;
    if (locating) {
      locatingIcon = const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    } else {
      locatingIcon = const Icon(Icons.my_location, size: 18);
    }

    String locatingLabel;
    if (locating) {
      locatingLabel = 'Locating…';
    } else {
      locatingLabel = 'Use my current location';
    }

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Where are you diving today?',
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                'Tip: search a beach, town or bay name — e.g. "Bondi Beach".',
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _controller,
                focusNode: _focusNode,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search place name…',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (value) =>
                    _onChanged(value, context.read<OpenMeteoApi>()),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: locating
                      ? null
                      : () => context.read<AppBloc>().add(
                          const DeviceLocationRequested(),
                        ),
                  icon: locatingIcon,
                  label: Text(locatingLabel),
                ),
              ),
              if (locating) const SizedBox(height: 8),
              _buildResults(scheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResults(ColorScheme scheme) {
    if (_searching) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Text(_error!, style: TextStyle(color: scheme.onSurfaceVariant)),
      );
    }

    return Flexible(
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: _results.length,
        itemBuilder: (context, index) {
          final result = _results[index];
          final place = [
            result.admin,
            result.country,
          ].whereType<String>().join(', ');
          return ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.place, size: 20),
            title: Text(result.name),
            subtitle: Text(place, maxLines: 1, overflow: TextOverflow.ellipsis),
            onTap: () {
              Navigator.of(context).pop();
              context.read<AppBloc>().add(LocationSelected(result));
            },
          );
        },
      ),
    );
  }
}
