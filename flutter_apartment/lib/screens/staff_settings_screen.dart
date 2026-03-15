import 'package:flutter/material.dart';

import '../core/app_i18n.dart';
import '../models/app_models.dart';
import '../services/download_service.dart';
import '../widgets/common_widgets.dart';

class StaffSettingsScreen extends StatefulWidget {
  const StaffSettingsScreen({super.key});

  @override
  State<StaffSettingsScreen> createState() => _StaffSettingsScreenState();
}

class _StaffSettingsScreenState extends State<StaffSettingsScreen> {
  int tab = 0;
  bool lateFee = true;
  bool visitorRegistration = false;
  bool amenityBooking = true;
  late List<_UnitTier> _tiers;

  @override
  void initState() {
    super.initState();
    _tiers = [
      const _UnitTier(name: 'Studio Apartment', summary: 'Tier A Management', monthlyRate: 1200, icon: Icons.apartment_rounded),
      const _UnitTier(name: '1 Bedroom (1BR)', summary: 'Tier B Management', monthlyRate: 1800, icon: Icons.meeting_room_rounded),
      const _UnitTier(name: '2 Bedroom (2BR)', summary: 'Tier C Management', monthlyRate: 2500, icon: Icons.king_bed_rounded),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'System Configuration',
      role: UserRole.staff,
      currentIndex: 3,
      leadingIcon: Icons.arrow_back_ios_new_rounded,
      actions: [
        ShellAction(icon: Icons.check_circle_rounded, onPressed: _saveConfiguration),
      ],
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          SegmentedButton<int>(
            segments: const [
              ButtonSegment<int>(value: 0, label: Text('Rules')),
              ButtonSegment<int>(value: 1, label: Text('Unit Types')),
              ButtonSegment<int>(value: 2, label: Text('Pricing')),
            ],
            selected: {tab},
            onSelectionChanged: (value) => setState(() => tab = value.first),
          ),
          const SizedBox(height: 16),
          ResponsiveButtonBar(
            children: [
              FilledButton.tonalIcon(
                onPressed: _importPreset,
                icon: const Icon(Icons.upload_rounded),
                label: Text(context.tr('Import')),
              ),
              OutlinedButton.icon(
                onPressed: _exportConfiguration,
                icon: const Icon(Icons.download_rounded),
                label: Text(context.tr('Export')),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            onPressed: _validateConfiguration,
            icon: const Icon(Icons.fact_check_rounded),
            label: Text(context.tr('Validate Data Consistency')),
          ),
          const SizedBox(height: 20),
          Text(context.tr('BUILDING RULES'), style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 12),
          _toggleRow(context, 'Late Fee Automation', 'Apply fees after the 5th of each month', lateFee, (value) => setState(() => lateFee = value)),
          _toggleRow(context, 'Visitor Registration', 'Require digital ID for all guest entries', visitorRegistration, (value) => setState(() => visitorRegistration = value)),
          _toggleRow(context, 'Amenity Booking', 'Enable digital scheduling for gym and pool', amenityBooking, (value) => setState(() => amenityBooking = value)),
          const SizedBox(height: 20),
          SectionTitle('Unit Types & Tiers', actionLabel: 'Edit All', onAction: _editAllTiers),
          const SizedBox(height: 12),
          ..._tiers.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InfoCard(
                child: Row(
                  children: [
                    SoftIcon(icon: item.icon, color: const Color(0xFF137FEC)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.name, style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF172033))),
                          const SizedBox(height: 4),
                          Text('${item.summary} - \$${item.monthlyRate}/mo base', style: const TextStyle(color: Color(0xFF8B97AA), fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => _editTier(item),
                      icon: const Icon(Icons.edit_rounded, color: Color(0xFF8B97AA)),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          InfoCard(
            color: const Color(0xFFEFF6FF),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pricing Insight', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: const Color(0xFF137FEC))),
                const SizedBox(height: 8),
                Text(
                  'Current blended monthly base rate: \$${_averageRate.toStringAsFixed(0)}. Adjusting these values will be reflected in the exported pricing configuration.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  double get _averageRate {
    if (_tiers.isEmpty) {
      return 0;
    }
    final total = _tiers.fold<double>(0, (sum, tier) => sum + tier.monthlyRate);
    return total / _tiers.length;
  }

  void _saveConfiguration() {
    showAppSnack(context, 'Configuration saved');
  }

  Future<void> _importPreset() async {
    setState(() {
      lateFee = true;
      visitorRegistration = true;
      amenityBooking = true;
      _tiers = [
        const _UnitTier(name: 'Studio Apartment', summary: 'Tier A Premium', monthlyRate: 1300, icon: Icons.apartment_rounded),
        const _UnitTier(name: '1 Bedroom (1BR)', summary: 'Tier B Premium', monthlyRate: 1900, icon: Icons.meeting_room_rounded),
        const _UnitTier(name: '2 Bedroom (2BR)', summary: 'Tier C Premium', monthlyRate: 2600, icon: Icons.king_bed_rounded),
      ];
    });
    showAppSnack(context, 'Preset configuration imported');
  }

  Future<void> _exportConfiguration() async {
    final content = StringBuffer('setting,value\n');
    content.writeln('late_fee,$lateFee');
    content.writeln('visitor_registration,$visitorRegistration');
    content.writeln('amenity_booking,$amenityBooking');
    for (final tier in _tiers) {
      content.writeln('${tier.name},${tier.summary} - \$${tier.monthlyRate}');
    }

    await DownloadService.saveCsvFile(filename: 'staff_configuration', content: content.toString());
    if (mounted) {
      showAppSnack(context, 'Configuration exported');
    }
  }

  Future<void> _validateConfiguration() async {
    final warnings = <String>[];
    if (!_tiers.every((tier) => tier.monthlyRate > 0)) {
      warnings.add('One or more unit tiers have an invalid monthly rate.');
    }
    if (!lateFee && !visitorRegistration && !amenityBooking) {
      warnings.add('All building rules are disabled.');
    }

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Validation Result'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tiers checked: ${_tiers.length}'),
            Text('Average rate: \$${_averageRate.toStringAsFixed(0)}'),
            const SizedBox(height: 12),
            if (warnings.isEmpty)
              const Text('Configuration looks consistent.')
            else
              ...warnings.map((warning) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text('- $warning'),
                  )),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Close')),
        ],
      ),
    );
  }

  Future<void> _editAllTiers() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: ListView(
            shrinkWrap: true,
            children: [
              Text('Edit Unit Tiers', style: Theme.of(sheetContext).textTheme.titleLarge),
              const SizedBox(height: 12),
              ..._tiers.map(
                (tier) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InfoCard(
                    child: Row(
                      children: [
                        SoftIcon(icon: tier.icon, color: const Color(0xFF137FEC), size: 40),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(tier.name, style: Theme.of(sheetContext).textTheme.labelLarge),
                              const SizedBox(height: 4),
                              Text('${tier.summary} - \$${tier.monthlyRate}/mo', style: Theme.of(sheetContext).textTheme.bodyMedium),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            Navigator.pop(sheetContext);
                            _editTier(tier);
                          },
                          icon: const Icon(Icons.edit_rounded),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _editTier(_UnitTier tier) async {
    final nameController = TextEditingController(text: tier.name);
    final summaryController = TextEditingController(text: tier.summary);
    final rateController = TextEditingController(text: tier.monthlyRate.toStringAsFixed(0));

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Tier'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
              const SizedBox(height: 12),
              TextField(controller: summaryController, decoration: const InputDecoration(labelText: 'Summary')),
              const SizedBox(height: 12),
              TextField(controller: rateController, decoration: const InputDecoration(labelText: 'Monthly Rate')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              setState(() {
                final index = _tiers.indexOf(tier);
                _tiers[index] = tier.copyWith(
                  name: nameController.text.trim(),
                  summary: summaryController.text.trim(),
                  monthlyRate: double.tryParse(rateController.text.trim()) ?? tier.monthlyRate,
                );
              });
              Navigator.pop(dialogContext);
              showAppSnack(context, 'Tier updated');
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _toggleRow(BuildContext context, String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InfoCard(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: const Color(0xFF172033))),
                  const SizedBox(height: 4),
                  Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
            Switch(value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}

class _UnitTier {
  final String name;
  final String summary;
  final double monthlyRate;
  final IconData icon;

  const _UnitTier({
    required this.name,
    required this.summary,
    required this.monthlyRate,
    required this.icon,
  });

  _UnitTier copyWith({
    String? name,
    String? summary,
    double? monthlyRate,
    IconData? icon,
  }) {
    return _UnitTier(
      name: name ?? this.name,
      summary: summary ?? this.summary,
      monthlyRate: monthlyRate ?? this.monthlyRate,
      icon: icon ?? this.icon,
    );
  }
}
