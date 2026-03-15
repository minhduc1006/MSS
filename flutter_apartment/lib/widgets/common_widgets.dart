import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/app_i18n.dart';
import '../models/app_models.dart';
import '../providers/app_state.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

List<NavItem> navItemsForRole(UserRole role) {
  switch (role) {
    case UserRole.admin:
      return const [
        NavItem(
            label: 'Overview',
            route: '/admin',
            index: 0,
            icon: Icons.dashboard_rounded),
        NavItem(
            label: 'Residents',
            route: '/admin/residents',
            index: 1,
            icon: Icons.groups_rounded),
        NavItem(
            label: 'Billing',
            route: '/admin/billing',
            index: 2,
            icon: Icons.receipt_long_rounded),
        NavItem(
            label: 'Facilities',
            route: '/admin/facilities',
            index: 3,
            icon: Icons.apartment_rounded),
        NavItem(
            label: 'Security',
            route: '/admin/security',
            index: 4,
            icon: Icons.shield_rounded),
      ];
    case UserRole.staff:
      return const [
        NavItem(
            label: 'Tasks',
            route: '/staff',
            index: 0,
            icon: Icons.grid_view_rounded),
        NavItem(
            label: 'Facilities',
            route: '/staff/facilities',
            index: 1,
            icon: Icons.corporate_fare_rounded),
        NavItem(
            label: 'Security',
            route: '/staff/security',
            index: 2,
            icon: Icons.shield_rounded),
        NavItem(
            label: 'Settings',
            route: '/staff/settings',
            index: 3,
            icon: Icons.settings_rounded),
      ];
    case UserRole.resident:
      return const [
        NavItem(
            label: 'Home',
            route: '/resident',
            index: 0,
            icon: Icons.home_rounded),
        NavItem(
            label: 'Bills',
            route: '/resident/bills',
            index: 1,
            icon: Icons.receipt_long_rounded),
        NavItem(
            label: 'Bookings',
            route: '/resident/bookings',
            index: 2,
            icon: Icons.book_online_rounded),
        NavItem(
            label: 'Security',
            route: '/resident/security',
            index: 3,
            icon: Icons.shield_rounded),
        NavItem(
            label: 'Account',
            route: '/resident/account',
            index: 4,
            icon: Icons.person_rounded),
      ];
  }
}

List<NavItem> drawerItemsForRole(UserRole role) {
  switch (role) {
    case UserRole.admin:
      return const [
        NavItem(
            label: 'Overview',
            route: '/admin',
            index: 0,
            icon: Icons.dashboard_rounded),
        NavItem(
            label: 'Residents',
            route: '/admin/residents',
            index: 1,
            icon: Icons.groups_rounded),
        NavItem(
            label: 'Staff Directory',
            route: '/admin/staff',
            index: 2,
            icon: Icons.badge_rounded),
        NavItem(
            label: 'Billing',
            route: '/admin/billing',
            index: 3,
            icon: Icons.receipt_long_rounded),
        NavItem(
            label: 'Facilities',
            route: '/admin/facilities',
            index: 4,
            icon: Icons.apartment_rounded),
        NavItem(
            label: 'Unit Map',
            route: '/admin/apartment',
            index: 5,
            icon: Icons.map_rounded),
        NavItem(
            label: 'Security',
            route: '/admin/security',
            index: 6,
            icon: Icons.shield_rounded),
      ];
    case UserRole.staff:
      return const [
        NavItem(
            label: 'Tasks',
            route: '/staff',
            index: 0,
            icon: Icons.grid_view_rounded),
        NavItem(
            label: 'Facilities',
            route: '/staff/facilities',
            index: 1,
            icon: Icons.corporate_fare_rounded),
        NavItem(
            label: 'Security',
            route: '/staff/security',
            index: 2,
            icon: Icons.shield_rounded),
        NavItem(
            label: 'Settings',
            route: '/staff/settings',
            index: 3,
            icon: Icons.settings_rounded),
      ];
    case UserRole.resident:
      return const [
        NavItem(
            label: 'Home',
            route: '/resident',
            index: 0,
            icon: Icons.home_rounded),
        NavItem(
            label: 'Bills',
            route: '/resident/bills',
            index: 1,
            icon: Icons.receipt_long_rounded),
        NavItem(
            label: 'Bookings',
            route: '/resident/bookings',
            index: 2,
            icon: Icons.book_online_rounded),
        NavItem(
            label: 'Security',
            route: '/resident/security',
            index: 3,
            icon: Icons.shield_rounded),
        NavItem(
            label: 'Account',
            route: '/resident/account',
            index: 4,
            icon: Icons.person_rounded),
      ];
  }
}

class ShellAction {
  final IconData icon;
  final VoidCallback onPressed;
  final bool alertDot;

  const ShellAction({
    required this.icon,
    required this.onPressed,
    this.alertDot = false,
  });
}

class AppShell extends StatelessWidget {
  final String title;
  final String? subtitle;
  final UserRole role;
  final int currentIndex;
  final Widget body;
  final IconData? leadingIcon;
  final VoidCallback? onLeadingTap;
  final List<ShellAction> actions;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final bool showBottomNav;
  final bool showNotifications;

  const AppShell({
    super.key,
    required this.title,
    required this.role,
    required this.currentIndex,
    required this.body,
    this.subtitle,
    this.leadingIcon,
    this.onLeadingTap,
    this.actions = const [],
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.showBottomNav = true,
    this.showNotifications = true,
  });

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final auth = context.watch<AuthProvider>();
    final sessionKey = '${role.name}:${auth.currentUser?.email ?? 'guest'}';
    if (appState.notificationSessionKey != sessionKey) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          context
              .read<AppState>()
              .ensureNotifications(role: role, user: auth.currentUser);
        }
      });
    }
    final navItems = navItemsForRole(role);

    return Scaffold(
      drawer: _AppDrawer(
          role: role, currentRoute: ModalRoute.of(context)?.settings.name),
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  if (leadingIcon != null) ...[
                    AppIconButton(
                        icon: leadingIcon!,
                        onPressed:
                            onLeadingTap ?? () => Navigator.maybePop(context)),
                    const SizedBox(width: 12),
                  ] else ...[
                    Builder(
                      builder: (buttonContext) => AppIconButton(
                        icon: Icons.menu_rounded,
                        onPressed: () =>
                            Scaffold.of(buttonContext).openDrawer(),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(context.tr(title),
                            style: Theme.of(context).textTheme.titleLarge),
                        if (subtitle != null)
                          Text(context.tr(subtitle!),
                              style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                  if (showNotifications)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: AppIconButton(
                        icon: Icons.notifications_rounded,
                        alertDot: appState.unreadNotificationCount > 0,
                        onPressed: () => _showNotificationsSheet(context),
                      ),
                    ),
                  ...actions.map(
                    (action) => Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: AppIconButton(
                        icon: action.icon,
                        alertDot: action.alertDot,
                        onPressed: action.onPressed,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: body),
          ],
        ),
      ),
      bottomNavigationBar: showBottomNav
          ? _BottomNav(role: role, currentIndex: currentIndex, items: navItems)
          : null,
    );
  }

  Future<void> _showNotificationsSheet(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => Consumer<AppState>(
        builder: (sheetContext, appState, _) {
          final items = appState.notifications;
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(sheetContext.tr('Notifications'),
                            style: Theme.of(sheetContext).textTheme.titleLarge),
                      ),
                      if (items.isNotEmpty)
                        TextButton(
                          onPressed: () => context
                              .read<AppState>()
                              .markAllNotificationsRead(),
                          child: Text(sheetContext.tr('Mark all read')),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (items.isEmpty)
                    InfoCard(
                      child: Text(
                          sheetContext.tr('No notifications right now.'),
                          style: Theme.of(sheetContext).textTheme.bodyMedium),
                    )
                  else
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (sheetContext, index) {
                          final item = items[index];
                          return InfoCard(
                            color: item.unread
                                ? item.color.withValues(alpha: 0.08)
                                : null,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SoftIcon(
                                    icon: item.icon,
                                    color: item.color,
                                    size: 44),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(14),
                                    onTap: () {
                                      context
                                          .read<AppState>()
                                          .markNotificationRead(item.id);
                                      Navigator.pop(sheetContext);
                                      if (item.route != null &&
                                          ModalRoute.of(context)
                                                  ?.settings
                                                  .name !=
                                              item.route) {
                                        Navigator.pushReplacementNamed(
                                            context, item.route!);
                                      }
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 2),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  item.title,
                                                  style: Theme.of(sheetContext)
                                                      .textTheme
                                                      .labelLarge
                                                      ?.copyWith(
                                                          color: AppTheme
                                                              .textPrimary),
                                                ),
                                              ),
                                              if (item.unread)
                                                Container(
                                                  width: 8,
                                                  height: 8,
                                                  decoration: BoxDecoration(
                                                      color: item.color,
                                                      shape: BoxShape.circle),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(item.message,
                                              style: Theme.of(sheetContext)
                                                  .textTheme
                                                  .bodyMedium),
                                          const SizedBox(height: 8),
                                          Text(item.timeLabel,
                                              style: Theme.of(sheetContext)
                                                  .textTheme
                                                  .bodySmall),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => context
                                      .read<AppState>()
                                      .dismissNotification(item.id),
                                  icon:
                                      const Icon(Icons.close_rounded, size: 18),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final UserRole role;
  final int currentIndex;
  final List<NavItem> items;

  const _BottomNav({
    required this.role,
    required this.currentIndex,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 22),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: items.map((item) {
          final selected = item.index == currentIndex;
          return InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () {
              if (ModalRoute.of(context)?.settings.name != item.route) {
                Navigator.pushReplacementNamed(context, item.route);
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(item.icon,
                      color: selected ? AppTheme.brand : AppTheme.textMuted,
                      size: 24),
                  const SizedBox(height: 4),
                  Text(
                    context.tr(item.label),
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: selected ? AppTheme.brand : AppTheme.textMuted,
                        ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _AppDrawer extends StatelessWidget {
  final UserRole role;
  final String? currentRoute;

  const _AppDrawer({
    required this.role,
    required this.currentRoute,
  });

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final appState = context.watch<AppState>();
    final user = auth.currentUser;
    final items = drawerItemsForRole(role);

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  AppAvatar(name: user?.fullName ?? role.name),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user?.fullName ?? 'Skyline Heights',
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 4),
                        Text(
                          '${role.name[0].toUpperCase()}${role.name.substring(1)}${user?.email != null ? ' • ${user!.email}' : ''}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 24),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                children: [
                  for (final item in items)
                    ListTile(
                      leading: Icon(item.icon),
                      title: Text(context.tr(item.label)),
                      selected: currentRoute == item.route,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      onTap: () {
                        Navigator.pop(context);
                        if (currentRoute != item.route) {
                          Navigator.pushReplacementNamed(context, item.route);
                        }
                      },
                    ),
                ],
              ),
            ),
            const Divider(height: 24),
            ListTile(
              leading: Icon(appState.isDarkMode
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded),
              title: Text(appState.isDarkMode
                  ? context.t('light_mode')
                  : context.t('dark_mode')),
              trailing: Switch(
                value: appState.isDarkMode,
                onChanged: (_) => context.read<AppState>().toggleTheme(),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.language_rounded),
              title: Text(context.t('language')),
              subtitle: Text(appState.language == AppLanguage.vi
                  ? context.t('vietnamese')
                  : context.t('english')),
              trailing: Switch(
                value: appState.language == AppLanguage.vi,
                onChanged: (value) => context
                    .read<AppState>()
                    .setLanguage(value ? AppLanguage.vi : AppLanguage.en),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.tonalIcon(
                  onPressed: () {
                    Navigator.pop(context);
                    context.read<AuthProvider>().logout(context);
                  },
                  icon: const Icon(Icons.logout_rounded),
                  label: Text(context.t('sign_out')),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AppIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final bool alertDot;

  const AppIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.alertDot = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Material(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onPressed,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Icon(icon, color: AppTheme.textPrimary),
            ),
          ),
        ),
        if (alertDot)
          const Positioned(
            right: 11,
            top: 11,
            child: DecoratedBox(
              decoration: BoxDecoration(
                  color: Color(0xFFEF4444), shape: BoxShape.circle),
              child: SizedBox(width: 8, height: 8),
            ),
          ),
      ],
    );
  }
}

class SoftIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color? background;
  final double size;

  const SoftIcon({
    super.key,
    required this.icon,
    required this.color,
    this.background,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background ?? color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: color, size: size * 0.5),
    );
  }
}

class AppNetworkImage extends StatelessWidget {
  final String url;
  final double height;
  final double? width;
  final BorderRadius borderRadius;
  final BoxFit fit;
  final Widget? overlay;

  const AppNetworkImage({
    super.key,
    required this.url,
    required this.height,
    this.width,
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
    this.fit = BoxFit.cover,
    this.overlay,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: SizedBox(
        height: height,
        width: width,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              url,
              fit: fit,
              errorBuilder: (_, __, ___) => Container(
                color: const Color(0xFFEAF3FF),
                child: const Icon(Icons.image_not_supported_rounded,
                    color: AppTheme.brand),
              ),
            ),
            if (overlay != null) overlay!,
          ],
        ),
      ),
    );
  }
}

class InfoCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;

  const InfoCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color,
      child: Container(
        width: double.infinity,
        padding: padding,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: child,
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionTitle(this.text, {super.key, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(context.tr(text),
              style: Theme.of(context).textTheme.titleMedium),
        ),
        if (actionLabel != null)
          TextButton(
            onPressed: onAction,
            child: Text(context.tr(actionLabel!),
                style: const TextStyle(fontWeight: FontWeight.w800)),
          ),
      ],
    );
  }
}

class MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String? note;
  final IconData icon;
  final Color iconColor;
  final Color? noteColor;

  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    this.note,
    this.noteColor,
  });

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      child: LayoutBuilder(
        builder: (context, constraints) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SoftIcon(icon: icon, color: iconColor, size: 36),
            const SizedBox(height: 8),
            Text(
              context.tr(label).toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: constraints.maxWidth,
                  child: FittedBox(
                    alignment: Alignment.centerLeft,
                    fit: BoxFit.scaleDown,
                    child: Text(value,
                        style: Theme.of(context).textTheme.headlineMedium),
                  ),
                ),
              ),
            ),
            if (note != null) ...[
              const SizedBox(height: 6),
              Text(
                context.tr(note!),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(color: noteColor ?? AppTheme.textMuted),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class ResponsiveButtonBar extends StatelessWidget {
  final List<Widget> children;
  final int maxColumns;
  final double spacing;
  final double runSpacing;

  const ResponsiveButtonBar({
    super.key,
    required this.children,
    this.maxColumns = 2,
    this.spacing = 12,
    this.runSpacing = 12,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int columns = 1;
        if (constraints.maxWidth >= 920) {
          columns = maxColumns;
        } else if (constraints.maxWidth >= 560) {
          columns = maxColumns > 1 ? 2 : 1;
        }

        final itemWidth =
            (constraints.maxWidth - (spacing * (columns - 1))) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          children: [
            for (final child in children)
              SizedBox(
                width: itemWidth,
                child: child,
              ),
          ],
        );
      },
    );
  }
}

class AppSearchField extends StatelessWidget {
  final String hint;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final FocusNode? focusNode;

  const AppSearchField({
    super.key,
    required this.hint,
    this.controller,
    this.onChanged,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      focusNode: focusNode,
      decoration: InputDecoration(
        hintText: context.tr(hint),
        prefixIcon: const Icon(Icons.search_rounded),
      ),
    );
  }
}

class ActionTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool primary;
  final double width;

  const ActionTile({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.primary = false,
    this.width = 104,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: primary ? AppTheme.brand : Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color:
                    primary ? AppTheme.brand : Theme.of(context).dividerColor),
            boxShadow: primary
                ? [
                    BoxShadow(
                      color: AppTheme.brand.withValues(alpha: 0.22),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  color: primary ? Colors.white : AppTheme.textPrimary,
                  size: 22),
              const SizedBox(height: 8),
              Text(
                context.tr(label),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontSize: 13,
                      height: 1.15,
                      color: primary ? Colors.white : AppTheme.textPrimary,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AppAvatar extends StatelessWidget {
  final String name;
  final double radius;

  const AppAvatar({
    super.key,
    required this.name,
    this.radius = 22,
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppTheme.brand.withValues(alpha: 0.15),
      child: Text(
        initialsFor(name),
        style: TextStyle(
          color: AppTheme.brand,
          fontWeight: FontWeight.w800,
          fontSize: radius * 0.72,
        ),
      ),
    );
  }
}

void showAppSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(context.tr(message))));
}

Widget asyncErrorView(
  BuildContext context, {
  String title = 'Unable to load data',
  String? message,
  VoidCallback? onRetry,
}) {
  return ListView(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
    children: [
      InfoCard(
        color: const Color(0xFFFEF2F2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr(title),
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: const Color(0xFFB91C1C)),
            ),
            const SizedBox(height: 8),
            Text(
              context.tr(message ??
                  'The app now loads backend data only. Check that the microservices are running and reachable.'),
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: const Color(0xFF7F1D1D)),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: onRetry,
                child: Text(context.tr('Retry')),
              ),
            ],
          ],
        ),
      ),
    ],
  );
}

Color statusColor(String status) {
  final value = status.toLowerCase();
  if (value.contains('deactivated') || value.contains('inactive')) {
    return const Color(0xFF6B7280);
  }
  if (value.contains('paid') ||
      value.contains('active') ||
      value.contains('open') ||
      value.contains('authorized') ||
      value.contains('success') ||
      value.contains('confirmed') ||
      value.contains('operational') ||
      value.contains('completed') ||
      value.contains('resolved') ||
      value.contains('available') ||
      value.contains('on duty')) {
    return const Color(0xFF22C55E);
  }
  if (value.contains('pending') ||
      value.contains('maintenance') ||
      value.contains('progress') ||
      value.contains('reserved') ||
      value.contains('due')) {
    return const Color(0xFFF59E0B);
  }
  return const Color(0xFFEF4444);
}

Widget statusChip(String status) {
  final color = statusColor(status);
  return Builder(
    builder: (context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        context.tr(status).toUpperCase(),
        style:
            TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 11),
      ),
    ),
  );
}

String formatMoney(num value, {int decimals = 0}) {
  final formatter = NumberFormat.decimalPattern('vi_VN');
  final normalized = decimals == 0 ? value.round() : value;
  final formatted = decimals == 0
      ? formatter.format(normalized)
      : NumberFormat.decimalPatternDigits(
              locale: 'vi_VN', decimalDigits: decimals)
          .format(normalized);
  return '$formatted VNĐ';
}

String initialsFor(String value) {
  final parts = value
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) {
    return '?';
  }
  if (parts.length == 1) {
    return parts.first.substring(0, 1).toUpperCase();
  }
  return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
}

IconData activityIcon(String kind) {
  switch (kind) {
    case 'billing':
      return Icons.receipt_long_rounded;
    case 'maintenance':
      return Icons.handyman_rounded;
    case 'onboarding':
      return Icons.person_add_alt_1_rounded;
    default:
      return Icons.info_outline_rounded;
  }
}

Color activityColor(String kind) {
  switch (kind) {
    case 'billing':
      return AppTheme.brand;
    case 'maintenance':
      return const Color(0xFFF97316);
    case 'onboarding':
      return const Color(0xFF22C55E);
    default:
      return AppTheme.textMuted;
  }
}
