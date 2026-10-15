import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/location.dart';
import '../../core/providers/geocoding_provider.dart';
import '../../core/providers/location_provider.dart';
import '../../shared/widgets/error_view.dart';

/// A [SearchDelegate] that geocodes a city/place name via the Open-Meteo
/// geocoding API and lets the user add the result to their saved locations.
///
/// Open the delegate with:
/// ```dart
/// showSearch(
///   context: context,
///   delegate: LocationSearchDelegate(ref),
/// );
/// ```
class LocationSearchDelegate extends SearchDelegate<WeatherLocation?> {
  LocationSearchDelegate(this._ref);

  final WidgetRef _ref;

  @override
  String get searchFieldLabel => 'Search for a city or place…';

  @override
  List<Widget> buildActions(BuildContext context) => [
        if (query.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.clear),
            tooltip: 'Clear',
            onPressed: () => query = '',
          ),
      ];

  @override
  Widget buildLeading(BuildContext context) => IconButton(
        icon: const Icon(Icons.arrow_back),
        tooltip: 'Back',
        onPressed: () => close(context, null),
      );

  @override
  Widget buildResults(BuildContext context) => _ResultsView(
        query: query.trim(),
        onSelect: _handleSelect,
      );

  @override
  Widget buildSuggestions(BuildContext context) => buildResults(context);

  void _handleSelect(BuildContext context, WeatherLocation loc) {
    _ref.read(locationProvider.notifier)
      ..addLocation(loc)
      ..setActiveLocation(loc);
    close(context, loc);
  }
}

// ── Private results widget ──────────────────────────────────────────────────

class _ResultsView extends ConsumerWidget {
  const _ResultsView({required this.query, required this.onSelect});

  final String query;
  final void Function(BuildContext, WeatherLocation) onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (query.isEmpty) {
      return const Center(
        child: _HintText('Type a city or place name to search.'),
      );
    }

    final asyncValue = ref.watch(geocodingProvider(query));

    return asyncValue.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => ErrorView(
        message: 'Search failed. Check your connection and try again.',
        onRetry: () => ref.invalidate(geocodingProvider(query)),
      ),
      data: (results) {
        if (results.isEmpty) {
          return Center(
            child: _HintText('No results for "$query". Try a different spelling.'),
          );
        }
        return ListView.separated(
          itemCount: results.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (ctx, i) {
            final loc = results[i];
            return _LocationTile(
              location: loc,
              onTap: () => onSelect(ctx, loc),
            );
          },
        );
      },
    );
  }
}

class _LocationTile extends StatelessWidget {
  const _LocationTile({required this.location, required this.onTap});

  final WeatherLocation location;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitle = [location.region, location.country]
        .whereType<String>()
        .join(', ');

    return ListTile(
      leading: const Icon(Icons.location_on_outlined),
      title: Text(location.name),
      subtitle: subtitle.isNotEmpty
          ? Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          : null,
      trailing: const Icon(Icons.add_location_alt_outlined, size: 20),
      onTap: onTap,
    );
  }
}

class _HintText extends StatelessWidget {
  const _HintText(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      );
}
