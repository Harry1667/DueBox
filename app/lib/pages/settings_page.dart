import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:app/l10n/generated/app_localizations.dart';
import '../main.dart'; // Import main to access BillManagerApp
import '../services/notification_service.dart';


class SettingsPage extends StatefulWidget {
  final bool initialNotificationState;
  final ValueChanged<bool> onNotificationChanged;

  const SettingsPage({
    super.key,
    required this.initialNotificationState,
    required this.onNotificationChanged,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late bool _notificationsEnabled;
  final TextEditingController _daysController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  int _reminderDays = 1;
  TimeOfDay _notificationTime = const TimeOfDay(hour: 9, minute: 0);

  @override
  void initState() {
    super.initState();
    _notificationsEnabled = widget.initialNotificationState;
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final loc = AppLocalizations.of(context)!;
    setState(() {
      _reminderDays = prefs.getInt('reminder_days') ?? 1;
      _daysController.text = _reminderDays.toString();
      _titleController.text = prefs.getString('page_title') ?? loc.dashboardTitle;
      final hour = prefs.getInt('notification_hour') ?? 9;
      final minute = prefs.getInt('notification_minute') ?? 0;
      _notificationTime = TimeOfDay(hour: hour, minute: minute);
    });
  }

  Future<void> _saveReminderDays(String value) async {
    final days = int.tryParse(value);
    if (days != null && days > 0) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('reminder_days', days);
      setState(() => _reminderDays = days);
    }
  }

  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _notificationTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF60A5FA),
              onPrimary: Colors.white,
              surface: Color(0xFF27272A),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _notificationTime) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('notification_hour', picked.hour);
      await prefs.setInt('notification_minute', picked.minute);
      setState(() => _notificationTime = picked);
    }
  }

    Future<void> _saveTitle(String value) async {
      if (value.trim().isEmpty) return;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('page_title', value);
    }

    // Removed _showLanguagePicker

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFF18181B), // Darker background
      appBar: AppBar(
        title: Text(loc.settingsTitle, style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF18181B),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader(loc.generalSettings),
          _buildContainer([
            ListTile(
              leading: const Icon(LucideIcons.layout, color: Colors.white),
              title: Text(loc.homeTitle, style: const TextStyle(color: Colors.white)),
              trailing: SizedBox(
                width: 120,
                child: TextField(
                  controller: _titleController,
                  textAlign: TextAlign.end,
                  style: const TextStyle(color: Colors.grey),
                  decoration: InputDecoration(border: InputBorder.none, hintText: loc.dashboardTitle),
                  onChanged: _saveTitle,
                ),
              ),
            ),
             const Divider(color: Color(0xFF3F3F46), height: 1),
             // Removed Language tile
          ]),

          const SizedBox(height: 24),
          _buildSectionHeader(loc.notificationsReminders),
          _buildContainer([
            // Switch
            ListTile(
              leading: const Icon(LucideIcons.bell, color: Colors.white),
              title: Text(loc.enableNotifications, style: const TextStyle(color: Colors.white)),
              trailing: Switch(
                value: _notificationsEnabled,
                activeColor: const Color(0xFF60A5FA),
                onChanged: (value) {
                  if (value) {
                     widget.onNotificationChanged(true);
                     setState(() => _notificationsEnabled = true);
                  } else {
                     // Normally handled by callback, but for UI:
                     // widget.onNotificationChanged(false); // If we want to allow disable
                  }
                },
              ),
            ),
            if (_notificationsEnabled) ...[
              const Divider(color: Color(0xFF3F3F46), height: 1),
              // Time Picker
              ListTile(
                leading: const Icon(LucideIcons.clock, color: Colors.white),
                title: Text(loc.reminderTime, style: const TextStyle(color: Colors.white)),
                subtitle: Text(loc.reminderTimeDesc, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: const Color(0xFF3F3F46), borderRadius: BorderRadius.circular(8)),
                  child: Text(
                    _notificationTime.format(context),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                onTap: _pickTime,
              ),
              const Divider(color: Color(0xFF3F3F46), height: 1),
              // Days Before
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    const Icon(LucideIcons.calendarClock, color: Colors.white),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(loc.advanceReminder, style: const TextStyle(color: Colors.white, fontSize: 16)),
                          const SizedBox(height: 4),
                          Text(loc.advanceReminderDesc, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      )
                    ),
                    Row(
                      children: [
                        Text("${loc.daysBefore} ", style: const TextStyle(color: Colors.white)),
                        SizedBox(
                          width: 40,
                          child: TextField(
                            controller: _daysController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Color(0xFF60A5FA), fontWeight: FontWeight.bold),
                            decoration: const InputDecoration(
                              isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 4),
                              border: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF60A5FA))),
                            ),
                            onChanged: _saveReminderDays,
                          ),
                        ),
                        Text(" ${loc.days}", style: const TextStyle(color: Colors.white)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ]),




          const SizedBox(height: 24),
          _buildSectionHeader(loc.about),
          _buildContainer([
            ListTile(
              leading: const Icon(LucideIcons.info, color: Colors.white),
              title: Text(loc.version, style: const TextStyle(color: Colors.white)),
              trailing: const Text('1.0.0 (Beta)', style: TextStyle(color: Colors.grey)),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(title, style: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 13, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildContainer(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF27272A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF3F3F46)),
      ),
      child: Column(children: children),
    );
  }
}
