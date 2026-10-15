import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers/location_provider.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../shared/widgets/location_search_delegate.dart';
import '../providers/historical_provider.dart';
import 'widgets/climatology_chart.dart';
import 'widgets/historical_day_list.dart';

class HistoricalScreen extends ConsumerStatefulWidget {
  const HistoricalScreen({super.key});

  @override
  ConsumerState<HistoricalScreen> createState() => _HistoricalScreenState();
}

class _HistoricalScreenState extends ConsumerState<HistoricalScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now().subtract(const Duration(days: 1));
  int _selectedMonth = DateTime.now().month;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final location  = ref.watch(locationProvider).activeLocation;
    final settings  = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(location?.name ?? 'Historical Weather'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search location',
            onPressed: () => showSearch(
              context: context,
              delegate: LocationSearchDelegate(ref),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Date Range'),
            Tab(text: 'Climatology'),
          ],
        ),
      ),
      body: location == null
          ? const Center(child: Text('Choose a location first.'))
          : TabBarView(
              controller: _tabController,
              children: [
                _DateRangeTab(
                  location: location,
                  settings: settings,
                  startDate: _startDate,
                  endDate: _endDate,
                  onDatesChanged: (start, end) =>
                      setState(() {
                        _startDate = start;
                        _endDate = end;
                      }),
                ),
                _ClimatologyTab(
                  location: location,
                  settings: settings,
                  selectedMonth: _selectedMonth,
                  onMonthChanged: (m) => setState(() => _selectedMonth = m),
                ),
              ],
            ),
    );
  }
}

// ── Date range tab ────────────────────────────────────────────────────────────

class _DateRangeTab extends ConsumerWidget {
  const _DateRangeTab({
    required this.location,
    required this.settings,
    required this.startDate,
    required this.endDate,
    required this.onDatesChanged,
  });

  final dynamic location;
  final AppSettings settings;
  final DateTime startDate;
  final DateTime endDate;
  final void Function(DateTime, DateTime) onDatesChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = HistoricalQuery(
      latitude: location.latitude,
      longitude: location.longitude,
      startDate: startDate,
      endDate: endDate,
    );
    final historicalAsync = ref.watch(historicalDataProvider(query));
    final dateFormat = DateFormat('d MMM yyyy');

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: Text(dateFormat.format(startDate)),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: startDate,
                      firstDate: DateTime(1940),
                      lastDate: DateTime.now().subtract(const Duration(days: 1)),
                    );
                    if (picked != null) {
                      onDatesChanged(picked, endDate.isBefore(picked) ? picked : endDate);
                    }
                  },
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('→'),
              ),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: Text(dateFormat.format(endDate)),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: endDate,
                      firstDate: startDate,
                      lastDate: DateTime.now().subtract(const Duration(days: 1)),
                    );
                    if (picked != null) onDatesChanged(startDate, picked);
                  },
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: historicalAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text(e.toString())),
            data: (data) => HistoricalDayList(data: data, settings: settings),
          ),
        ),
      ],
    );
  }
}

// ── Climatology tab ───────────────────────────────────────────────────────────

class _ClimatologyTab extends ConsumerWidget {
  const _ClimatologyTab({
    required this.location,
    required this.settings,
    required this.selectedMonth,
    required this.onMonthChanged,
  });

  final dynamic location;
  final AppSettings settings;
  final int selectedMonth;
  final ValueChanged<int> onMonthChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final climatologyAsync = ref.watch(climatologyProvider(selectedMonth));
    final monthNames = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec',
    ];

    return Column(
      children: [
        // Month picker
        SizedBox(
          height: 48,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            itemCount: 12,
            itemBuilder: (context, i) {
              final month = i + 1;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(
                  label: Text(monthNames[i]),
                  selected: selectedMonth == month,
                  onSelected: (_) => onMonthChanged(month),
                ),
              );
            },
          ),
        ),
        Expanded(
          child: climatologyAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text(e.toString())),
            data: (datasets) {
              final summaries = buildClimatology(datasets);
              return ClimatologyChart(
                summaries: summaries,
                settings: settings,
                monthName: monthNames[selectedMonth - 1],
              );
            },
          ),
        ),
      ],
    );
  }
}
