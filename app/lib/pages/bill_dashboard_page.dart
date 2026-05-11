import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import 'dart:io';
import 'dart:math';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../types/bill.dart';
import '../types/bill_group.dart';
import '../widgets/bill_card.dart';
import '../services/gemini_service.dart';
import '../services/notification_service.dart';
import '../services/notification_service.dart';
import '../services/notification_service.dart';
import '../services/tutorial_service.dart';
import 'package:app/l10n/generated/app_localizations.dart';
import 'settings_page.dart';
import '../services/logger_service.dart';
import 'debug_console_page.dart';
import '../services/ad_service.dart';

class BillDashboardPage extends StatefulWidget {
  const BillDashboardPage({super.key});

  @override
  State<BillDashboardPage> createState() => _BillDashboardPageState();
}

class _BillDashboardPageState extends State<BillDashboardPage> {
  // Data
  final List<Bill> _bills = [];

  List<BillGroup> _groups = [];
  String _pageTitle = '';
  bool _isMenuOpen = false;
  bool _notifPermissionGranted = false;
  bool _isLoading = false;
  
  final GeminiService _geminiService = GeminiService();
  final NotificationService _notificationService = NotificationService();
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadTitle();
    _loadData(); // Load bills and groups
    
    // Initialize Notification Service
    _notificationService.init().then((_) {
      // Check permission status if possible, or just default to false until requested
      _notificationService.requestPermissions().then((granted) {
        setState(() {
          _notifPermissionGranted = granted;
        });
      });
    });
    // Confirm interface component positions (Post Frame)
    WidgetsBinding.instance.addPostFrameCallback((_) async {
       if (await TutorialService().shouldShowTutorial()) {
          if (mounted) {
             // Wait 5 seconds
             await Future.delayed(const Duration(seconds: 5));
             
             if (mounted) {
                // Force return to home page (root)
                Navigator.of(context).popUntil((route) => route.isFirst);
                
                // Explicitly confirm interface component positions
                await _ensureLayoutReady();
                _triggerTutorial(); 
             }
          }
       }
    });
  }

  Future<void> _ensureLayoutReady() async {
      int retries = 0;
      while (retries < 10) {
          if (TutorialService().billListKey.currentContext != null && 
              TutorialService().fabKey.currentContext != null) {
              return; // Positions confirmed
          }
          await Future.delayed(const Duration(milliseconds: 100));
          retries++;
      }
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load Bills
    final billsJson = prefs.getString('bills_data');
    if (billsJson != null) {
      final List<dynamic> decoded = jsonDecode(billsJson);
      _bills.clear();
      _bills.addAll(decoded.map((x) => Bill.fromJson(x)).toList());
    }

    // Load Groups
    final groupsJson = prefs.getString('groups_data');
    if (groupsJson != null) {
      final List<dynamic> decoded = jsonDecode(groupsJson);
      _groups = decoded.map((x) => BillGroup.fromJson(x)).toList();
    } else {
       if (_bills.isNotEmpty) {
           _initializeGroups(); // Fallback if old data format or first run
       }
    }
    setState(() {});
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Save Bills
    final billsJson = jsonEncode(_bills.map((b) => b.toJson()).toList());
    await prefs.setString('bills_data', billsJson);

    // Save Groups
    final groupsJson = jsonEncode(_groups.map((g) => g.toJson()).toList());
    await prefs.setString('groups_data', groupsJson);
  }

  void _initializeGroups() {
    final categories = _bills.map((b) => b.category ?? AppLocalizations.of(context)!.generalBill).toSet();
    for (var category in categories) {
      if (!_groups.any((g) => g.id == category)) {
        _groups.add(BillGroup(
          id: category,
          color: _generateRandomColor(),
        ));
      }
    }
    _sortGroups();
  }
  
  void _sortGroups() {
    setState(() {
      _groups.sort((a, b) {
        if (a.isPinned && !b.isPinned) return -1;
        if (!a.isPinned && b.isPinned) return 1;
        return a.orderIndex.compareTo(b.orderIndex);
      });
    });
  }

  Color _generateRandomColor() {
    final colors = [
      Colors.blue, Colors.green, Colors.orange, Colors.purple, Colors.teal, Colors.indigo, Colors.redAccent
    ];
     return colors[Random().nextInt(colors.length)];
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notifPermissionGranted = prefs.getBool('notifications_enabled') ?? false;
    });
  }

  Future<void> _loadTitle() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _pageTitle = prefs.getString('page_title') ?? (mounted ? AppLocalizations.of(context)!.dashboardTitle : '我的帳單');
    });
  }

  Future<void> _saveTitle(String newTitle) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('page_title', newTitle);
    setState(() {
      _pageTitle = newTitle;
    });
  }

  double get _totalAmount {
    return _bills
        .where((b) => b.status != BillStatus.paid)
        .fold(0, (sum, bill) => sum + bill.amount);
  }

  // --- Actions ---
  
  void _triggerTutorial() {
     TutorialService().startTutorial(
        context,
        onOpenMenu: () {
           if (!_isMenuOpen) _toggleMenu();
        },
     );
  }

  void _toggleMenu() => setState(() => _isMenuOpen = !_isMenuOpen);

  void _updateNotification(bool value) {
    if (value) {
      _notificationService.requestPermissions().then((granted) {
        setState(() => _notifPermissionGranted = granted);
        if (granted) {
          // Schedule for all existing bills
          for (var bill in _bills) {
            _notificationService.scheduleBillNotifications(bill);
          }
          
           if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.notificationScheduled)));
           // Test notification
           _notificationService.showTestNotification();
        }
      });
    } else {
      // Logic to disable? Usually system level.
      // We can cancel all.
      _notificationService.cancelAll();
      setState(() => _notifPermissionGranted = false);
    }
  }

  void _onSettingsTap() async {
    final result = await Navigator.push(context, MaterialPageRoute(
      builder: (context) => SettingsPage(
          initialNotificationState: _notifPermissionGranted,
          onNotificationChanged: _updateNotification),
    ));
    
    _loadTitle(); // Refresh title

    if (result == true) { // Trigger tutorial replay
       await TutorialService().resetTutorial();
       if (mounted) {
         TutorialService().startTutorial(
            context, 
            onOpenMenu: () {
              if (!_isMenuOpen) _toggleMenu();
            }
         );
       }
    }
  }

  Future<void> _editTitle() async {
    final titleController = TextEditingController(text: _pageTitle);
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF27272A),
        title: Text(AppLocalizations.of(context)!.editTitle, style: const TextStyle(color: Colors.white)),
        content: TextField(
          controller: titleController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(hintText: AppLocalizations.of(context)!.enterNewTitle, hintStyle: const TextStyle(color: Colors.grey)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(AppLocalizations.of(context)!.cancel)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            onPressed: () {
              if (titleController.text.isNotEmpty) _saveTitle(titleController.text);
              Navigator.pop(context);
            },
            child: Text(AppLocalizations.of(context)!.save, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- AI / Adding Bills ---

  Future<void> _addNewBill(Bill newBill) async {
    setState(() {
      _bills.add(newBill);
      final category = newBill.category ?? AppLocalizations.of(context)!.generalBill;
      final groupIndex = _groups.indexWhere((g) => g.id == category);
      if (groupIndex == -1) {
          _groups.add(BillGroup(id: category, color: _generateRandomColor()));
          _sortGroups();
      }
    });

    await _saveData();
    
    if (_notifPermissionGranted) {
      _notificationService.scheduleBillNotifications(newBill);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.addSuccess)));
    }

    // Step 8 Trigger: If Tutorial is Active OR it's the very first bill (for new users auto-flow)
    LoggerService().log("Checking if Step 8 should start. isTutorialActive: ${TutorialService().isTutorialActive}, bill count: ${_bills.length}");
    if (TutorialService().isTutorialActive || _bills.length == 1) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
             TutorialService().startStep8(
               context,
               onOpenEdit: () {
                  LoggerService().log("Step 8 onOpenEdit callback triggered. Current bill count: ${_bills.length}");
                  if (_bills.isNotEmpty) {
                      _showEditDialog(context, _bills.last);
                  } else {
                      LoggerService().log("WARNING: Bills list empty in onOpenEdit callback");
                  }
               }
             );
        });
    }
  }

  Future<void> _handleCameraInput() async {
    _toggleMenu();
    TutorialService().stopForInteraction();
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
      if (photo == null) return;
      
      setState(() => _isLoading = true);
      
      // Start AI in background
      final processingFuture = _geminiService.extractBillFromImage(File(photo.path));
      
      // Give native UI time to dismiss the picker
      await Future.delayed(const Duration(milliseconds: 800));
      
      // Show Ad and wait for it to close
      await AdService().showInterstitialAd();
      
      // Wait for AI result
      final bill = await processingFuture;
      
      if (bill != null) _addNewBill(bill);
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

   Future<void> _handleGalleryInput() async {
    _toggleMenu();
    TutorialService().stopForInteraction();
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.gallery);
      if (photo == null) return;
      
      setState(() => _isLoading = true);

      // Start AI in background
      final processingFuture = _geminiService.extractBillFromImage(File(photo.path));
      
      // Give native UI time to dismiss the picker
      await Future.delayed(const Duration(milliseconds: 800));
      
      // Show Ad and wait for it to close
      await AdService().showInterstitialAd();
      
      // Wait for AI result
      final bill = await processingFuture;
      
      if (bill != null) _addNewBill(bill);
    } catch (e) {
       _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleTextInput() async {
    _toggleMenu();
    TutorialService().stopForInteraction();
    final TextEditingController textController = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF27272A),
        title: Text(AppLocalizations.of(context)!.billInputTitle, style: const TextStyle(color: Colors.white)),
        content: TextField(
          controller:textController,
          maxLines: 5,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(hintText: AppLocalizations.of(context)!.billInputHint, hintStyle: const TextStyle(color: Colors.grey)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(AppLocalizations.of(context)!.cancel)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            onPressed: () async {
              Navigator.pop(context);
              if (textController.text.isNotEmpty) {
                 setState(() => _isLoading = true);
                 try {
                   // Start AI in background
                   final processingFuture = _geminiService.extractBillFromText(textController.text);
                   
                   // Short delay to allow dialog dismissal to settle
                   await Future.delayed(const Duration(milliseconds: 300));
                   
                   // Show Ad and wait
                   await AdService().showInterstitialAd();
                   
                   // Wait for AI
                   final bill = await processingFuture;
                   
                   if (bill != null) _addNewBill(bill);
                 } catch (e) {
                   _showError(e.toString());
                 } finally {
                   if (mounted) setState(() => _isLoading = false);
                 }
              }
            },
            child: Text(AppLocalizations.of(context)!.startAiAnalysis, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.addFail(message))));
    }
  }

  // --- Group & Bill Management ---

  void _deleteGroup(BillGroup group) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF27272A),
        title: Text(AppLocalizations.of(context)!.deleteGroupTitle(group.id), style: const TextStyle(color: Colors.white)),
        content: Text(AppLocalizations.of(context)!.deleteGroupContent, style: const TextStyle(color: Colors.grey)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(AppLocalizations.of(context)!.cancel)),
          TextButton(
            onPressed: () {
              // Cancel notifications for all bills in group
              final billsToDelete = _bills.where((b) => (b.category ?? AppLocalizations.of(context)!.generalBill) == group.id);
              for (var bill in billsToDelete) {
                if (_notifPermissionGranted) _notificationService.cancelBillNotifications(bill.id);
              }

              setState(() {
                _bills.removeWhere((b) => (b.category ?? AppLocalizations.of(context)!.generalBill) == group.id);
                _groups.remove(group);
                _saveData();
              });
              Navigator.pop(context);
            },
            child: Text(AppLocalizations.of(context)!.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _editGroupName(BillGroup group) {
    final controller = TextEditingController(text: group.id);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF27272A),
        title: Text(AppLocalizations.of(context)!.editGroupName, style: const TextStyle(color: Colors.white)),
        content: TextField(controller: controller, style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(AppLocalizations.of(context)!.cancel)),
          ElevatedButton(
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty && newName != group.id) {
                setState(() {
                  for (var i = 0; i < _bills.length; i++) {
                    if ((_bills[i].category ?? AppLocalizations.of(context)!.generalBill) == group.id) {
                       _bills[i] = Bill(
                         id: _bills[i].id,
                         title: _bills[i].title,
                         amount: _bills[i].amount,
                         currency: _bills[i].currency,
                         dueDate: _bills[i].dueDate,
                         status: _bills[i].status,
                         note: _bills[i].note,
                         category: newName,
                       );
                    }
                  }
                   group.id = newName;
                   _saveData();
                });
              }
              Navigator.pop(context);
            },
            child: Text(AppLocalizations.of(context)!.save),
          ),
        ],
      ),
    );
  }
  
  void _moveGroup(BillGroup group, int direction) {
    final index = _groups.indexOf(group);
    if (index < 0) return;
    final newIndex = index + direction;
    if (newIndex >= 0 && newIndex < _groups.length) {
      setState(() {
        final temp = _groups[newIndex];
        _groups[newIndex] = group;
        _groups[index] = temp;
        _saveData();
      });
    }
  }

  void _togglePinGroup(BillGroup group) {
    setState(() {
      group.isPinned = !group.isPinned;
      _sortGroups();
      _saveData();
    });
  }

  void _changeGroupColor(BillGroup group) {
    final colors = [Colors.blue, Colors.green, Colors.orange, Colors.purple, Colors.teal, Colors.red, Colors.pink, Colors.amber];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF27272A),
        title: Text(AppLocalizations.of(context)!.pickColor, style: const TextStyle(color: Colors.white)),
        content: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: colors.map((c) => GestureDetector(
            onTap: () {
              setState(() => group.color = c);
              _saveData();
              Navigator.pop(context);
            },
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: c, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
            ),
          )).toList(),
        ),
      ),
    );
  }

  // --- Drag & Drop ---

  List<dynamic> _buildFlattenedList() {
    final list = [];
    for (var group in _groups) {
      list.add(group); 
      final groupBills = _bills.where((b) => (b.category ?? AppLocalizations.of(context)!.generalBill) == group.id).toList();
      list.addAll(groupBills);
    }
    return list;
  }

  void _onReorder(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) newIndex -= 1;
    final flatList = _buildFlattenedList();
    final movedItem = flatList[oldIndex];

    if (movedItem is BillGroup) return; 

    if (movedItem is Bill) {
      final newPlacementItem = flatList[newIndex];
      BillGroup? targetGroup;
      for (int i = newIndex; i >= 0; i--) {
        if (i < flatList.length && flatList[i] is BillGroup) {
          targetGroup = flatList[i] as BillGroup;
          break;
        }
      }
      
      if (targetGroup != null) {
        setState(() {
          final billIndex = _bills.indexWhere((b) => b.id == movedItem.id);
          if (billIndex != -1) {
             final updatedBill = Bill(
               id: movedItem.id,
               title: movedItem.title,
               amount: movedItem.amount,
               currency: movedItem.currency,
               dueDate: movedItem.dueDate,
               status: movedItem.status,
               note: movedItem.note,
               category: targetGroup!.id,
             );
             _bills[billIndex] = updatedBill;
             _saveData();
          }
        });
      }
    }
  }
  
  // --- UI Components ---
  
  Widget _buildGroupHeader(BillGroup group) {
    final groupBills = _bills.where((b) => (b.category ?? AppLocalizations.of(context)!.generalBill) == group.id).toList();
    return Container(
      key: ValueKey(group.id),
      margin: const EdgeInsets.only(top: 24, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: group.color.withOpacity(0.7), 
        border: Border(left: BorderSide(color: group.color, width: 4)),
        borderRadius: const BorderRadius.only(topRight: Radius.circular(8), bottomRight: Radius.circular(8)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
               if (group.isPinned) const Padding(padding: EdgeInsets.only(right:6), child: Icon(LucideIcons.pin, size: 14, color: Colors.white)),
               Text(group.id, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          Text(
            AppLocalizations.of(context)!.items(groupBills.length),
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const Spacer(),
          // Menu
          PopupMenuButton<String>(
            icon: const Icon(LucideIcons.moreVertical, color: Colors.grey, size: 16),
            color: const Color(0xFF27272A),
            onSelected: (value) {
              if (value == 'color') _changeGroupColor(group);
              if (value == 'pin') {
                 setState(() {
                   group.isPinned = !group.isPinned;
                   _sortGroups();
                   _saveData();
                 });
              }
              if (value == 'up') _moveGroup(group, -1);
              if (value == 'down') _moveGroup(group, 1);
              if (value == 'delete') _deleteGroup(group);
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'color',
                child: Row(children: [const Icon(LucideIcons.palette, size: 16), const SizedBox(width: 8), Text(AppLocalizations.of(context)!.changeColor)]),
              ),
              PopupMenuItem(
                value: 'pin',
                child: Row(children: [Icon(group.isPinned ? LucideIcons.pinOff : LucideIcons.pin, size: 16), const SizedBox(width: 8), Text(AppLocalizations.of(context)!.pinUnpin)]),
              ),
              PopupMenuItem(
                value: 'up',
                enabled: _groups.indexOf(group) > 0,
                child: Row(children: [const Icon(LucideIcons.arrowUp, size: 16), const SizedBox(width: 8), Text(AppLocalizations.of(context)!.moveUp)]),
              ),
              PopupMenuItem(
                value: 'down',
                enabled: _groups.indexOf(group) < _groups.length - 1,
                child: Row(children: [const Icon(LucideIcons.arrowDown, size: 16), const SizedBox(width: 8), Text(AppLocalizations.of(context)!.moveDown)]),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'delete',
                child: Row(children: [const Icon(LucideIcons.trash2, size: 16, color: Colors.red), const SizedBox(width: 8), Text(AppLocalizations.of(context)!.deleteGroup, style: const TextStyle(color: Colors.red))]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat("#,##0", "en_US");
    final flatList = _buildFlattenedList();

    return Scaffold(
      backgroundColor: const Color(0xFF3C3C3C),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header (Editable)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: _editTitle,
                            child: Row(
                              key: TutorialService().titleKey,
                              children: [
                                Text(_pageTitle, style: GoogleFonts.inter(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                                const SizedBox(width: 8),
                                Icon(LucideIcons.edit2, size: 16, color: Colors.white.withOpacity(0.5))
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                           Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                ' ${AppLocalizations.of(context)!.totalPending} ',
                                style: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 12, fontWeight: FontWeight.w500),
                              ),
                              Text(
                                currencyFormat.format(_totalAmount),
                                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                       Row(
                        children: [

                           IconButton(
                            icon: const Icon(LucideIcons.settings, color: Colors.white),
                            onPressed: () {
                               Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SettingsPage(
                                    initialNotificationState: _notifPermissionGranted,
                                    onNotificationChanged: (value) async {
                                      final prefs = await SharedPreferences.getInstance();
                                      await prefs.setBool('notifications_enabled', value);
                                      setState(() {
                                        _notifPermissionGranted = value;
                                      });
                                    },
                                  ),
                                ),
                              ).then((_) {
                                  _loadSettings();
                                  _loadTitle(); // Reload title if changed
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // const SizedBox(height: 24), // Removed to decrease gap as requested
                
                Expanded(
                  child: Container(
                    key: TutorialService().billListKey,
                    // Ensure the key target fills the available space
                    alignment: Alignment.center, 
                    child: Container(
                      margin: const EdgeInsets.only(left: 20, right: 20, bottom: 150),
                      width: double.infinity,
                    child: _bills.isEmpty
                      ? Center(child: Padding(
                          padding: const EdgeInsets.only(top: 100),
                          child: Text(
                             AppLocalizations.of(context)!.addFirstBill, 
                             style: const TextStyle(color: Colors.grey)
                          ),
                        ))
                      : ReorderableListView(
                        padding: const EdgeInsets.only(bottom: 100),
                        onReorder: _onReorder,
                        proxyDecorator: (child, index, animation) {
                          return AnimatedBuilder(
                            animation: animation,
                            builder: (BuildContext context, Widget? child) {
                              final double animValue = Curves.easeInOut.transform(animation.value);
                              final double elevation = lerpDouble(0, 10, animValue)!;
                              final double scale = lerpDouble(1, 1.02, animValue)!;
                              return Transform.scale(
                                scale: scale,
                                child: Material(
                                  elevation: elevation,
                                  color: Colors.transparent,
                                  shadowColor: Colors.black.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(16),
                                  child: child,
                                ),
                              );
                            },
                            child: child,
                          );
                        },
                        children: flatList.asMap().entries.map((entry) {
                          int index = entry.key;
                          var item = entry.value;
                          
                          if (item is BillGroup) {
                            return Container(
                              key: ValueKey('group_${item.id}'),
                              child: _buildGroupHeader(item),
                            );
                          } else if (item is Bill) {
                            // Assign firstBillKey to the VERY FIRST bill in the list
                            final isFirstBill = _bills.isNotEmpty && _bills.first.id == item.id;
                            
                            return Container(
                              key: isFirstBill ? TutorialService().firstBillKey : ValueKey('bill_${item.id}'),
                              margin: const EdgeInsets.only(bottom: 12),
                              child: GestureDetector(
                                onTap: () {
                                   _showEditDialog(context, item);
                                },
                                child: BillCard(bill: item),
                              ),
                            );
                          }
                          return Container(key: UniqueKey());
                        }).toList(),
                      ),
                    ),
                  ),
                ),

              ],
            ),
          ),
          
          if (_isMenuOpen)
            GestureDetector(
              onTap: _toggleMenu,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                child: Container(color: Colors.black.withOpacity(0.6)),
              ),
            ),
          if (_isMenuOpen)
            Positioned(
              bottom: 100,
              right: 0, 
              left: 0,
              child: Row(
                key: TutorialService().menuKey,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildMenuButton(
                    key: TutorialService().textInputKey,
                    icon: LucideIcons.type, 
                    label: AppLocalizations.of(context)!.textInput, 
                    onTap: _handleTextInput
                  ),
                  const SizedBox(width: 24),
                  _buildMenuButton(
                    key: TutorialService().galleryInputKey,
                    icon: LucideIcons.image, 
                    label: AppLocalizations.of(context)!.galleryUpload, 
                    onTap: _handleGalleryInput
                  ),
                  const SizedBox(width: 24),
                  _buildMenuButton(
                    key: TutorialService().cameraInputKey,
                    icon: LucideIcons.camera, 
                    label: AppLocalizations.of(context)!.cameraScan, 
                    onTap: _handleCameraInput
                  ),
                ],
              ),
            ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            bottom: 32, left: 0, right: 0,
            child: Center(
              child: Container(
                key: TutorialService().fabKey,
                child: GestureDetector(
                  onTap: _toggleMenu,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 64, height: 64,
                    transform: Matrix4.rotationZ(_isMenuOpen ? 0.785398 : 0),
                    transformAlignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _isMenuOpen ? const Color(0xFF3F3F46).withOpacity(0.8) : const Color(0xFF2563EB).withOpacity(0.9),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: _isMenuOpen ? const Color(0xFF52525B) : const Color(0xFF60A5FA).withOpacity(0.3)),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 25, offset: const Offset(0, 10))],
                    ),
                    child: const Icon(LucideIcons.plus, color: Colors.white, size: 32),
                  ),
                ),
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: const Center(child: CircularProgressIndicator(color: Colors.blue)),
            ),
        ],
      ),
    );
  }
  
  void _showEditDialog(BuildContext context, Bill bill) {
     final titleController = TextEditingController(text: bill.title);
     
    final amountController = TextEditingController(text: bill.amount.toString());
    final categoryController = TextEditingController(text: bill.category ?? '');
    final noteController = TextEditingController(text: bill.note ?? '');
    DateTime selectedDate;
    try {
      selectedDate = DateTime.parse(bill.dueDate);
    } catch (e) {
      selectedDate = DateTime.now();
    }
    String selectedRecurrence = bill.recurrence.name;
    final TextEditingController dateController = TextEditingController(text: "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}");

    // Helper for Date Selection
    Future<void> selectDate(StateSetter setDialogState) async {
       final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: selectedDate,
        firstDate: DateTime(2000),
        lastDate: DateTime(2101),
        builder: (context, child) {
           return Theme(
            data: ThemeData.dark().copyWith(
              colorScheme: const ColorScheme.dark(
                primary: Color(0xFF60A5FA),
                onPrimary: Colors.white,
                surface: Color(0xFF27272A),
                onSurface: Colors.white,
              ),
              dialogBackgroundColor: const Color(0xFF27272A),
            ),
            child: child!,
          );
        },
      );
      if (picked != null && picked != selectedDate) {
          setDialogState(() {
             selectedDate = picked;
             dateController.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
          });
      }
    }

    showDialog(
      context: context,
      builder: (context) {
        // Trigger Step 9 when dialog opens ONLY if tutorial is active
        final isTutorial = TutorialService().isTutorialActive;
        LoggerService().log("Edit Dialog Builder called. isTutorialActive: $isTutorial");
        if (isTutorial) {
            // Using a slightly longer delay to ensure the Dialog animation is complete
            Future.delayed(const Duration(milliseconds: 700), () {
               if (mounted) {
                    TutorialService().startStep9(
                      context,
                      onNext: () {
                        LoggerService().log("Step 9 onNext triggered -> Showing Completion Step 10");
                        TutorialService().startStep10(context);
                      }
                    );
               }
            });
        }

        return StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: Colors.transparent, // Transparent for Dialog itself
          insetPadding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 24.0),
          child: Container(
             key: TutorialService().editDialogKey, // Key on the visible container
             decoration: BoxDecoration(
               color: const Color(0xFF27272A),
               borderRadius: BorderRadius.circular(28), // Matches Material 3 Dialog defaults roughly
             ),
             padding: const EdgeInsets.all(24), // Default padding for AlertDialog content
             child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppLocalizations.of(context)!.editBill, style: const TextStyle(color: Colors.white, fontSize: 24)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(labelText: AppLocalizations.of(context)!.title, labelStyle: const TextStyle(color: Colors.grey)),
                    style: const TextStyle(color: Colors.white)
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: amountController,
                    decoration: InputDecoration(labelText: AppLocalizations.of(context)!.amount, labelStyle: const TextStyle(color: Colors.grey)),
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white)
                  ),
                   const SizedBox(height: 16),
                   TextField(
                    controller: dateController,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.dueDate,
                      labelStyle: const TextStyle(color: Colors.grey),
                       suffixIcon: const Icon(Icons.calendar_today, color: Colors.white),
                    ),
                    style: const TextStyle(color: Colors.white),
                    onTap: () => selectDate(setDialogState),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: categoryController,
                    decoration: InputDecoration(labelText: AppLocalizations.of(context)!.categoryMoveGroup, labelStyle: const TextStyle(color: Colors.grey)),
                    style: const TextStyle(color: Colors.white)
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedRecurrence,
                    dropdownColor: const Color(0xFF27272A),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(labelText: AppLocalizations.of(context)!.recurrence, labelStyle: const TextStyle(color: Colors.grey)),
                    items: [
                      DropdownMenuItem(value: 'none', child: Text(AppLocalizations.of(context)!.none)),
                      DropdownMenuItem(value: 'daily', child: Text(AppLocalizations.of(context)!.daily)),
                      DropdownMenuItem(value: 'weekly', child: Text(AppLocalizations.of(context)!.weekly)),
                      DropdownMenuItem(value: 'monthly', child: Text(AppLocalizations.of(context)!.monthly)),
                      DropdownMenuItem(value: 'yearly', child: Text(AppLocalizations.of(context)!.yearly)),
                    ],
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedRecurrence = val);
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: noteController,
                    decoration: InputDecoration(labelText: AppLocalizations.of(context)!.note, labelStyle: const TextStyle(color: Colors.grey)),
                    style: const TextStyle(color: Colors.white)
                  ),
                  const SizedBox(height: 32),
                  Row(children: [
                     Expanded(child: TextButton(onPressed: () {
                       // Delete Bill
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: const Color(0xFF27272A),
                            title: Text(AppLocalizations.of(context)!.deleteBillConfirm, style: const TextStyle(color: Colors.white)),
                             actions: [
                              TextButton(onPressed: () => Navigator.pop(context), child: Text(AppLocalizations.of(context)!.cancel)),
                              TextButton(onPressed: () {
                                 // Cancel Notification first
                                 if (_notifPermissionGranted) _notificationService.cancelBillNotifications(bill.id);
                                 
                                 setState(() {
                                   _bills.removeWhere((b) => b.id == bill.id);
                                   // Check if group empty? Maybe keep empty group logic as is.
                                   _saveData();
                                 });
                                 Navigator.pop(context); // Close confirm
                                 Navigator.pop(context); // Close edit
                              }, child: const Text('確認刪除', style: TextStyle(color: Colors.red))),
                             ]
                          )
                        );
                     }, child: const Text("刪除", style: TextStyle(color: Colors.redAccent)))),
                     const SizedBox(width: 8),
                     Expanded(child: ElevatedButton(
                       onPressed: () {
                          // Save Changes
                          setState(() {
                             final index = _bills.indexWhere((b) => b.id == bill.id);
                             if (index != -1) {
                                final newCategory = categoryController.text.trim().isEmpty ? '未分類' : categoryController.text.trim();
                                
                                // Check if category changed, need to handle groups?
                                if (!_groups.any((g) => g.id == newCategory)) {
                                   _groups.add(BillGroup(id: newCategory, color: _generateRandomColor()));
                                   _sortGroups();
                                }
                                
                                final updatedBill = Bill(
                                  id: bill.id,
                                  title: titleController.text,
                                  amount: double.tryParse(amountController.text) ?? 0,
                                  currency: bill.currency,
                                  dueDate: dateController.text,
                                  status: bill.status,
                                  note: noteController.text,
                                  category: newCategory,
                                  recurrence: Recurrence.values.firstWhere((e) => e.name == selectedRecurrence, orElse: () => Recurrence.none),
                                );
                                
                              
                                _bills[index] = updatedBill;
                                _saveData();
                                
                                // Refresh notifications
                                if (_notifPermissionGranted) {
                                  _notificationService.cancelBillNotifications(bill.id);
                                  _notificationService.scheduleBillNotifications(updatedBill);
                                }
                             }
                          });
                          Navigator.pop(context); // Close dialog
                       },
                       child: const Text("儲存")
                     ))
                  ])
                ],
              ),
            ),
          ),
        ),
      );
     }
    );
  }

  Widget _buildMenuButton({Key? key, required IconData icon, required String label, required VoidCallback onTap}) {
     return Column(
      children: [
        GestureDetector(
          key: key,
          onTap: onTap,
          child: Container(
            width: 64, height: 64,
            decoration: BoxDecoration(color: const Color(0xFF3F3F46).withOpacity(0.8), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withOpacity(0.1))),
            child: Icon(icon, color: Colors.white, size: 26),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(color: Colors.black.withOpacity(0.4), borderRadius: BorderRadius.circular(999)),
          child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }

}
