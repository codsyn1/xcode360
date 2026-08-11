import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'features/settings/presentation/bloc/settings_cubit.dart';
import 'features/settings/presentation/bloc/settings_state.dart';
import 'dart:io';
import 'sign_up_screen.dart' show SkillChipSelector;

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _customSkillController = TextEditingController();
  final List<String> _customSkills = [];
  final Set<String> _removedCustomSkills = <String>{};

  @override
  void dispose() {
    _customSkillController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final theme = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF1976D2),
        brightness: Brightness.dark,
        background: const Color(0xFF212121),
        surface: const Color(0xFF2C2C2C),
        primary: const Color(0xFF1976D2),
        onPrimary: Colors.white,
        onSurface: Colors.white,
      ),
      scaffoldBackgroundColor: const Color(0xFF232323),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: Colors.white),
        bodyLarge: TextStyle(color: Colors.white),
        labelLarge: TextStyle(color: Colors.white),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: Color(0xFF2C2C2C),
        labelStyle: TextStyle(color: Colors.white),
        hintStyle: TextStyle(color: Colors.white70),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
          borderSide: BorderSide(color: Colors.white24),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
          borderSide: BorderSide(color: Color(0xFF1976D2), width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
          borderSide: BorderSide(color: Colors.white24),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      useMaterial3: true,
    );

    return Theme(
      data: theme,
      child: BlocProvider(
        create: (_) => SettingsCubit()..init(),
        child: BlocListener<SettingsCubit, SettingsState>(
          listenWhen: (prev, curr) => prev.message != curr.message || prev.error != curr.error,
          listener: (context, state) {
            if (state.message != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message!)),
              );
            }
            if (state.error != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.error!), backgroundColor: Colors.redAccent),
              );
            }
          },
          child: BlocBuilder<SettingsCubit, SettingsState>(
            builder: (context, state) {
              // Compute safe values for dropdowns to avoid assertion when data mismatch
              final cats = state.categories.keys.toList();
              final safeCategory = cats.contains(state.category) ? state.category : null;
              final subs = safeCategory != null ? (state.categories[safeCategory] ?? const <String>[]) : const <String>[];
              final safeSubcategory = subs.contains(state.subcategory) ? state.subcategory : null;

              return Scaffold(
                appBar: AppBar(
                  title: const Text('Settings'),
                  actions: [
                    TextButton.icon(
                      onPressed: state.saving
                          ? null
                          : () {
                              if (formKey.currentState?.validate() ?? true) {
                                // Merge skills: keep known options (except 'Other') + (existing custom - removed) + newly added custom
                                final options = state.skillsOptions;
                                final base = state.skills.where((s) => s != 'Other' && options.contains(s)).toList();
                                final existingCustoms = state.skills.where((s) => s != 'Other' && !options.contains(s)).toList();
                                final keptExistingCustoms = existingCustoms.where((s) => !_removedCustomSkills.contains(s));
                                final mergedCustoms = {...keptExistingCustoms, ..._customSkills}.toList();
                                final effective = [...base, ...mergedCustoms];
                                context.read<SettingsCubit>().setSkills(effective);
                                context.read<SettingsCubit>().saveChanges();
                                // Reset removals after save
                                setState(() => _removedCustomSkills.clear());
                              }
                            },
                      icon: state.saving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save, color: Colors.white),
                      label: const Text('Save', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
                body: state.loading
                    ? const Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Form(
                          key: formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _SectionCard(
                                title: 'Profile Photos',
                                child: Column(
                                  children: [
                                    Center(
                                      child: Stack(
                                        children: [
                                          CircleAvatar(
                                            radius: 44,
                                            backgroundColor: const Color(0xFF3A3A3A),
                                            backgroundImage: state.localProfileImagePath != null
                                                ? Image.file(File(state.localProfileImagePath!)).image
                                                : (state.profileImageUrl.isNotEmpty
                                                    ? NetworkImage(state.profileImageUrl)
                                                    : null) as ImageProvider<Object>?,
                                            child: (state.localProfileImagePath == null && state.profileImageUrl.isEmpty)
                                                ? const Icon(Icons.person, size: 44, color: Colors.white70)
                                                : null,
                                          ),
                                          Positioned(
                                            bottom: 0,
                                            right: 0,
                                            child: InkWell(
                                              onTap: () => context.read<SettingsCubit>().pickProfileImage(),
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF1976D2),
                                                  shape: BoxShape.circle,
                                                  border: Border.all(color: Colors.white, width: 2),
                                                ),
                                                padding: const EdgeInsets.all(6),
                                                child: const Icon(Icons.edit, size: 18, color: Colors.white),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    GestureDetector(
                                      onTap: () => context.read<SettingsCubit>().pickCoverImage(),
                                      child: Container(
                                        height: 120,
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF3A3A3A),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: Colors.white24, width: 1.5),
                                          image: state.localCoverImagePath != null
                                              ? DecorationImage(image: FileImage(File(state.localCoverImagePath!)), fit: BoxFit.cover)
                                              : (state.coverImageUrl.isNotEmpty
                                                  ? DecorationImage(image: NetworkImage(state.coverImageUrl), fit: BoxFit.cover)
                                                  : null),
                                        ),
                                        child: (state.localCoverImagePath == null && state.coverImageUrl.isEmpty)
                                            ? Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: const [
                                                  Icon(Icons.photo, color: Colors.white54, size: 36),
                                                  SizedBox(height: 8),
                                                  Text('Tap to select cover photo', style: TextStyle(color: Colors.white54)),
                                                ],
                                              )
                                            : null,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 16),
                              _SectionCard(
                                title: 'Account (Read-only)',
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    _ReadOnlyTile(label: 'Full Name', value: state.fullName),
                                    const SizedBox(height: 12),
                                    _ReadOnlyTile(label: 'Country', value: state.country),
                                    const SizedBox(height: 12),
                                    _ReadOnlyTile(label: 'City', value: state.city),
                                    const SizedBox(height: 12),
                                    _ReadOnlyTile(label: 'Email', value: state.email),
                                    const SizedBox(height: 12),
                                    _ReadOnlyTile(label: 'Username', value: state.username),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 16),
                              _SectionCard(
                                title: 'Edit Profile',
                                child: Column(
                                  children: [
                                    // Profession (editable)
                                    TextFormField(
                                      initialValue: state.jobTitle,
                                      onChanged: (v) => context.read<SettingsCubit>().setJobTitle(v),
                                      style: const TextStyle(color: Colors.white),
                                      decoration: const InputDecoration(
                                        labelText: 'Profession',
                                        hintText: 'e.g. Flutter Developer',
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    TextFormField(
                                      initialValue: state.website,
                                      onChanged: (v) => context.read<SettingsCubit>().setWebsite(v),
                                      style: const TextStyle(color: Colors.white),
                                      decoration: const InputDecoration(
                                        labelText: 'Website (optional)',
                                        hintText: 'https://example.com',
                                      ),
                                      keyboardType: TextInputType.url,
                                    ),
                                    const SizedBox(height: 12),
                                    TextFormField(
                                      initialValue: state.bio,
                                      onChanged: (v) => context.read<SettingsCubit>().setBio(v),
                                      style: const TextStyle(color: Colors.white),
                                      decoration: const InputDecoration(
                                        labelText: 'About / Bio',
                                      ),
                                      maxLines: 4,
                                    ),
                                    const SizedBox(height: 12),
                                    // Skills chip selector
                                    SkillChipSelector(
                                      skills: state.skillsOptions,
                                      selectedSkills: state.skills,
                                      onChanged: (skills) => context.read<SettingsCubit>().setSkills(skills),
                                    ),
                                    // Custom skills input when 'Other' selected OR existing custom skills present
                                    if (state.skills.contains('Other') ||
                                        state.skills.any((s) => s != 'Other' && !state.skillsOptions.contains(s))) ...[
                                      const SizedBox(height: 10),
                                      const Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text('Add custom skills', style: TextStyle(color: Colors.white70)),
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: TextField(
                                              controller: _customSkillController,
                                              style: const TextStyle(color: Colors.white),
                                              decoration: const InputDecoration(hintText: 'Type a skill and press +'),
                                              onSubmitted: (_) {
                                                final text = _customSkillController.text.trim();
                                                if (text.isEmpty) return;
                                                if (!_customSkills.contains(text)) {
                                                  setState(() => _customSkills.add(text));
                                                }
                                                _customSkillController.clear();
                                              },
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          ElevatedButton(
                                            onPressed: () {
                                              final text = _customSkillController.text.trim();
                                              if (text.isEmpty) return;
                                              if (!_customSkills.contains(text)) {
                                                setState(() => _customSkills.add(text));
                                              }
                                              _customSkillController.clear();
                                            },
                                            child: const Text('+'),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Builder(builder: (context) {
                                        final options = state.skillsOptions;
                                        final existingCustoms = state.skills.where((s) => s != 'Other' && !options.contains(s)).toList();
                                        // Exclude removed customs from view
                                        final keptExisting = existingCustoms.where((s) => !_removedCustomSkills.contains(s));
                                        final mergedCustoms = {...keptExisting, ..._customSkills}.toList();
                                        return mergedCustoms.isEmpty
                                            ? const SizedBox.shrink()
                                            : Wrap(
                                                spacing: 6,
                                                runSpacing: 6,
                                                children: mergedCustoms
                                                    .map((s) => Chip(
                                                          label: Text(s, style: const TextStyle(color: Colors.white)),
                                                          backgroundColor: const Color(0xFF1976D2).withOpacity(0.3),
                                                          deleteIcon: const Icon(Icons.close, color: Colors.white70, size: 18),
                                                          onDeleted: () {
                                                            setState(() {
                                                              if (_customSkills.contains(s)) {
                                                                _customSkills.remove(s);
                                                              } else {
                                                                _removedCustomSkills.add(s);
                                                              }
                                                            });
                                                          },
                                                        ))
                                                    .toList(),
                                              );
                                      }),
                                    ],
                                    const SizedBox(height: 12),
                                    // Category
                                    DropdownButtonFormField<String>(
                                      value: safeCategory,
                                      items: state.categories.keys
                                          .map((cat) => DropdownMenuItem(
                                                value: cat,
                                                child: Text(cat, style: const TextStyle(color: Colors.white)),
                                              ))
                                          .toList(),
                                      onChanged: (val) => context.read<SettingsCubit>().setCategory(val),
                                      dropdownColor: const Color(0xFF2C2C2C),
                                      decoration: const InputDecoration(labelText: 'Category'),
                                    ),
                                    const SizedBox(height: 12),
                                    // Subcategory (dependent)
                                    if (safeCategory != null)
                                      DropdownButtonFormField<String>(
                                        value: safeSubcategory,
                                        items: subs
                                            .map((sub) => DropdownMenuItem(
                                                  value: sub,
                                                  child: Text(sub, style: const TextStyle(color: Colors.white)),
                                                ))
                                            .toList(),
                                        onChanged: (val) => context.read<SettingsCubit>().setSubcategory(val),
                                        dropdownColor: const Color(0xFF2C2C2C),
                                        decoration: const InputDecoration(labelText: 'Subcategory'),
                                      ),
                                    const SizedBox(height: 12),
                                    TextFormField(
                                      initialValue: '',
                                      onChanged: (v) => context.read<SettingsCubit>().setNewPassword(v),
                                      style: const TextStyle(color: Colors.white),
                                      decoration: const InputDecoration(
                                        labelText: 'New Password',
                                      ),
                                      obscureText: true,
                                      validator: (v) {
                                        if (v == null || v.isEmpty) return null; // optional
                                        if (v.length < 6) return 'Password must be at least 6 characters';
                                        return null;
                                      },
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 8),
                              const Text(
                                'Tip: Only photos, website, bio and password can be edited here.',
                                style: TextStyle(color: Colors.white70, fontSize: 12),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ReadOnlyTile extends StatelessWidget {
  final String label;
  final String value;
  const _ReadOnlyTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF2C2C2C),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white24),
          ),
          child: Text(value.isEmpty ? '-' : value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final WidgetBuilder? footerBuilder;
  const _SectionCard({required this.title, required this.child, this.footerBuilder});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF2C2C2C),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 6,
                  height: 18,
                  decoration: BoxDecoration(color: const Color(0xFF1976D2), borderRadius: BorderRadius.circular(3)),
                ),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            child,
            if (footerBuilder != null) ...[
              const SizedBox(height: 8),
              footerBuilder!(context),
            ]
          ],
        ),
      ),
    );
  }
}
