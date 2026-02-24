import 'package:flutter/material.dart';
import 'package:future_riverpod/features/auth/presentation/widgets/app_button.dart';
import 'package:future_riverpod/features/auth/presentation/widgets/app_text_field.dart';

import './theme/app_colors.dart';
import './theme/app_spacing.dart';

/// Design system showcase screen
/// This screen demonstrates all the design tokens and components
class DesignSystemShowcase extends StatefulWidget {
  const DesignSystemShowcase({super.key});

  @override
  State<DesignSystemShowcase> createState() => _DesignSystemShowcaseState();
}

class _DesignSystemShowcaseState extends State<DesignSystemShowcase> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Design System Showcase'),
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () {
              // Toggle theme (implement in your app)
            },
          ),
        ],
      ),
      body: ListView(
        padding: AppSpacing.paddingScreen,
        children: [
          const SizedBox(height: AppSpacing.lg),

          // Colors Section
          _buildSection(
            title: 'Colors',
            children: [
              _buildColorRow('Primary', theme.colorScheme.primary),
              _buildColorRow('Secondary', theme.colorScheme.secondary),
              _buildColorRow('Error', theme.colorScheme.error),
              _buildColorRow('Surface', theme.colorScheme.surface),
              _buildColorRow(
                'Green Primary',
                isDark
                    ? AppColors.darkGreenPrimary
                    : AppColors.lightGreenPrimary,
              ),
              _buildColorRow(
                'Green Secondary',
                isDark
                    ? AppColors.darkGreenSecondary
                    : AppColors.lightGreenSecondary,
              ),
              _buildColorRow(
                'Red Primary',
                isDark ? AppColors.darkRedPrimary : AppColors.lightRedPrimary,
              ),
              _buildColorRow(
                'Red Secondary',
                isDark
                    ? AppColors.darkRedSecondary
                    : AppColors.lightRedSecondary,
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.xl),

          // Typography Section
          _buildSection(
            title: 'Typography',
            children: [
              Text('Display Large', style: theme.textTheme.displayLarge),
              const SizedBox(height: AppSpacing.sm),
              Text('Display Medium', style: theme.textTheme.displayMedium),
              const SizedBox(height: AppSpacing.sm),
              Text('Display Small', style: theme.textTheme.displaySmall),
              const SizedBox(height: AppSpacing.md),
              Text('Headline Large', style: theme.textTheme.headlineLarge),
              const SizedBox(height: AppSpacing.sm),
              Text('Headline Medium', style: theme.textTheme.headlineMedium),
              const SizedBox(height: AppSpacing.sm),
              Text('Headline Small', style: theme.textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.md),
              Text('Title Large', style: theme.textTheme.titleLarge),
              const SizedBox(height: AppSpacing.sm),
              Text('Title Medium', style: theme.textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              Text('Title Small', style: theme.textTheme.titleSmall),
              const SizedBox(height: AppSpacing.md),
              Text('Body Large', style: theme.textTheme.bodyLarge),
              const SizedBox(height: AppSpacing.sm),
              Text('Body Medium', style: theme.textTheme.bodyMedium),
              const SizedBox(height: AppSpacing.sm),
              Text('Body Small', style: theme.textTheme.bodySmall),
              const SizedBox(height: AppSpacing.md),
              Text('Label Large', style: theme.textTheme.labelLarge),
              const SizedBox(height: AppSpacing.sm),
              Text('Label Medium', style: theme.textTheme.labelMedium),
              const SizedBox(height: AppSpacing.sm),
              Text('Label Small', style: theme.textTheme.labelSmall),
            ],
          ),

          const SizedBox(height: AppSpacing.xl),

          // Buttons Section
          _buildSection(
            title: 'Buttons',
            children: [
              AppButton.primary(
                label: 'Primary Button',
                onPressed: () {},
              ),
              const SizedBox(height: AppSpacing.md),
              AppButton.primary(
                label: 'Loading Button',
                isLoading: true,
                onPressed: () {},
              ),
              const SizedBox(height: AppSpacing.md),
              const AppButton.primary(
                label: 'Disabled Button',
                onPressed: null,
              ),
              const SizedBox(height: AppSpacing.md),
              AppButton.secondary(
                label: 'Secondary Button',
                onPressed: () {},
              ),
              const SizedBox(height: AppSpacing.md),
              AppButton.text(
                label: 'Text Button',
                onPressed: () {},
              ),
              const SizedBox(height: AppSpacing.md),
              AppButton.destructive(
                label: 'Delete Button',
                onPressed: () {},
              ),
              const SizedBox(height: AppSpacing.md),
              AppButton.primary(
                label: 'With Icon',
                icon: const Icon(Icons.login),
                onPressed: () {},
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: AppButton.primary(
                      label: 'Small',
                      size: ButtonSize.small,
                      onPressed: () {},
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: AppButton.primary(
                      label: 'Medium',
                      size: ButtonSize.medium,
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.xl),

          // Text Fields Section
          _buildSection(
            title: 'Text Fields',
            children: [
              AppTextField.email(
                controller: _emailController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField.password(
                controller: _passwordController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),
              const AppTextField.phone(),
              const SizedBox(height: AppSpacing.md),
              const AppTextField(
                hint: 'Enter something',
                prefixIcon: Icon(Icons.person_outline),
              ),
              const SizedBox(height: AppSpacing.md),
              const AppTextField(
                hint: 'Cannot edit',
                enabled: false,
              ),
              const SizedBox(height: AppSpacing.md),
              const AppTextField.text(
                hint: 'Enter multiple lines',
                maxLength: 200,
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.xl),

          // Cards Section
          _buildSection(
            title: 'Cards',
            children: [
              Card(
                child: Padding(
                  padding: AppSpacing.paddingCard,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Card Title',
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'This is a card with some content inside. Cards are useful for grouping related information.',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {},
                            child: const Text('Action'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.xl),

          // Chips Section
          _buildSection(
            title: 'Chips',
            children: [
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  Chip(
                    label: const Text('Chip 1'),
                    onDeleted: () {},
                  ),
                  const Chip(
                    label: Text('Chip 2'),
                    avatar: Icon(Icons.person, size: 18),
                  ),
                  ActionChip(
                    label: const Text('Action Chip'),
                    onPressed: () {},
                  ),
                  FilterChip(
                    label: const Text('Filter Chip'),
                    selected: true,
                    onSelected: (value) {},
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.xl),

          // Switches and Checkboxes Section
          _buildSection(
            title: 'Switches & Checkboxes',
            children: [
              SwitchListTile(
                title: const Text('Enable notifications'),
                value: true,
                onChanged: (value) {},
              ),
              CheckboxListTile(
                title: const Text('Accept terms and conditions'),
                value: true,
                onChanged: (value) {},
              ),
              const RadioListTile<int>(
                title: Text('Option 1'),
                value: 1,
              ),
              const RadioListTile<int>(
                title: Text('Option 2'),
                value: 2,
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.xl),

          // Progress Indicators Section
          _buildSection(
            title: 'Progress Indicators',
            children: [
              const LinearProgressIndicator(),
              const SizedBox(height: AppSpacing.md),
              const Center(
                child: CircularProgressIndicator(),
              ),
              const SizedBox(height: AppSpacing.md),
              LinearProgressIndicator(
                value: 0.7,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.xl),

          // Dividers Section
          _buildSection(
            title: 'Dividers',
            children: [
              const Text('Content above divider'),
              const Divider(),
              const Text('Content below divider'),
            ],
          ),

          const SizedBox(height: AppSpacing.xl),

          // Spacing Reference
          _buildSection(
            title: 'Spacing Reference',
            children: [
              _buildSpacingRow('XXS', AppSpacing.xxs),
              _buildSpacingRow('XS', AppSpacing.xs),
              _buildSpacingRow('SM', AppSpacing.sm),
              _buildSpacingRow('MD', AppSpacing.md),
              _buildSpacingRow('MLG', AppSpacing.mlg),
              _buildSpacingRow('LG', AppSpacing.lg),
              _buildSpacingRow('XL', AppSpacing.xl),
              _buildSpacingRow('XXL', AppSpacing.xxl),
            ],
          ),

          const SizedBox(height: AppSpacing.xl),

          // Border Radius Reference
          _buildSection(
            title: 'Border Radius',
            children: [
              _buildRadiusRow('XS', AppSpacing.radiusXS),
              _buildRadiusRow('SM', AppSpacing.radiusSM),
              _buildRadiusRow('MD', AppSpacing.radiusMD),
              _buildRadiusRow('LG', AppSpacing.radiusLG),
              _buildRadiusRow('XL', AppSpacing.radiusXL),
              _buildRadiusRow('XXL', AppSpacing.radiusXXL),
            ],
          ),

          const SizedBox(height: AppSpacing.xxxl),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: AppSpacing.md),
        ...children,
      ],
    );
  }

  Widget _buildColorRow(String name, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color,
              borderRadius: AppSpacing.borderRadiusSM,
              border: Border.all(
                color: Theme.of(context).dividerColor,
                width: 1,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: Theme.of(context).textTheme.bodyMedium),
                Text(
                  '#${color.value.toRadixString(16).substring(2).toUpperCase()}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpacingRow(String name, double size) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(name, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Text(
            '${size.toInt()}px',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(width: AppSpacing.md),
          Container(
            width: size,
            height: 24,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRadiusRow(String name, double radius) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(name, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Text(
            '${radius.toInt()}px',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(width: AppSpacing.md),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(radius),
            ),
          ),
        ],
      ),
    );
  }
}
