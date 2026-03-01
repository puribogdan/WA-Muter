import 'package:flutter/material.dart';

import 'app_tokens.dart';

class ThemeDemoWidget extends StatefulWidget {
  const ThemeDemoWidget({super.key});

  @override
  State<ThemeDemoWidget> createState() => _ThemeDemoWidgetState();
}

class _ThemeDemoWidgetState extends State<ThemeDemoWidget> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Scaffold(
      appBar: AppBar(title: const Text('Theme Demo')),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: AppShadows.accentGlow(context.isDarkTheme),
        ),
        child: FloatingActionButton(
          onPressed: () {},
          child: const Icon(Icons.mic_none_rounded),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        children: [
          Text(
            'Primary Card',
            style: AppTypography.sectionTitle.copyWith(color: tokens.primary),
          ),
          const SizedBox(height: AppSpacing.gap12),
          Container(
            decoration: AppDecorations.card(context),
            padding: AppSpacing.cardPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Morning Work Block',
                  style: AppTypography.cardTitle.copyWith(color: tokens.primary),
                ),
                const SizedBox(height: AppSpacing.gap8),
                Text(
                  'Mon-Fri - 09:00-11:30 - 4 groups',
                  style: AppTypography.secondaryBody.copyWith(
                    color: tokens.secondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.section),
          Text(
            'Search Input',
            style: AppTypography.sectionTitle.copyWith(color: tokens.primary),
          ),
          const SizedBox(height: AppSpacing.gap12),
          DecoratedBox(
            decoration: AppDecorations.searchFieldContainer(context),
            child: TextField(
              decoration: AppInputStyles.search(
                context,
                hintText: 'Search groups or schedules',
                prefixIcon: const Icon(Icons.search),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.section),
          Text(
            'List Row',
            style: AppTypography.sectionTitle.copyWith(color: tokens.primary),
          ),
          const SizedBox(height: AppSpacing.gap12),
          DecoratedBox(
            decoration: AppDecorations.listRow(context),
            child: ListTile(
              leading: Container(
                width: 32,
                height: 32,
                decoration: AppDecorations.statusBubble(
                  context,
                  bg: context.isDarkTheme ? tokens.surface2 : tokens.chartGrid,
                ),
                child: Icon(
                  Icons.repeat_rounded,
                  size: 18,
                  color: tokens.secondary,
                ),
              ),
              title: Text(
                'Recurring mute',
                style: AppTypography.bodyStrong.copyWith(color: tokens.primary),
              ),
              subtitle: Text(
                'Repeats every weekday at 22:00',
                style: AppTypography.secondaryBody.copyWith(
                  color: tokens.secondary,
                ),
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: AppDecorations.pill(context),
                child: Text(
                  'ACTIVE',
                  style: AppTypography.micro.copyWith(color: tokens.muted),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(context).navigationBarTheme.backgroundColor,
            borderRadius: BorderRadius.circular(AppRadii.bottomNav),
            boxShadow: AppShadows.floating(context.isDarkTheme),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.bottomNav),
            child: NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: (value) => setState(() => _index = value),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.schedule),
                  label: 'Schedules',
                ),
                NavigationDestination(icon: Icon(Icons.group), label: 'Groups'),
                NavigationDestination(
                  icon: Icon(Icons.settings),
                  label: 'Settings',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
