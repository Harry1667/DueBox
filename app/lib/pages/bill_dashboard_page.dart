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
import '../services/ai_service.dart';
import '../services/notification_service.dart';
import '../services/tutorial_service.dart';
import 'package:app/l10n/generated/app_localizations.dart';
import 'settings_page.dart';
import '../services/logger_service.dart';
import '../services/ad_service.dart';
import '../services/analytics_service.dart';

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
  
  final AiService _aiService = AiService();
  final NotificationService _notificationService = NotificationService();
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadTitle();
    _loadData(); // Load bills and groups
    
    _notificationService.init().then((_) => _loadSettings());
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

  /// 還原通知的開關狀態。
  ///
  /// 必須尊重使用者存下來的選擇：如果他明確關過通知，這裡就不能再去要權限，
  /// 否則每次重開 App 都會把通知自動打開，等於關不掉。
  /// 尚未做過選擇（pref 不存在）時才詢問一次系統權限。
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getBool('notifications_enabled');

    if (saved == false) {
      if (mounted) setState(() => _notifPermissionGranted = false);
      return;
    }

    final granted = await _notificationService.requestPermissions();
    await prefs.setBool('notifications_enabled', granted);
    if (mounted) setState(() => _notifPermissionGranted = granted);
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

  /// 開啟或關閉通知。開啟時會替所有既有帳單補排程——否則使用者開啟通知後
  /// 只有之後新增的帳單才有提醒，先前的全都沒有。
  Future<void> _updateNotification(bool value) async {
    AnalyticsService().notificationToggled(value);
    final loc = AppLocalizations.of(context)!;

    if (!value) {
      await _notificationService.cancelAll();
      await _persistNotificationPref(false);
      if (mounted) setState(() => _notifPermissionGranted = false);
      return;
    }

    final granted = await _notificationService.requestPermissions();
    await _persistNotificationPref(granted);
    if (!mounted) return;
    setState(() => _notifPermissionGranted = granted);

    if (granted) {
      for (final bill in _bills) {
        await _notificationService.scheduleBillNotifications(bill, loc);
      }
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(loc.notificationScheduled)));
      }
    }
  }

  Future<void> _persistNotificationPref(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', enabled);
  }

  /// 提醒時間或提前天數改變後，把所有帳單的通知重排一次。
  /// 設定只寫進 SharedPreferences 是不夠的——已經排定的通知不會自己更新。
  Future<void> _rescheduleAllNotifications() async {
    if (!_notifPermissionGranted) return;
    final loc = AppLocalizations.of(context)!;
    for (final bill in _bills) {
      await _notificationService.scheduleBillNotifications(bill, loc);
    }
    LoggerService().log('設定變更：已重新排定 ${_bills.length} 張帳單的通知');
  }

  /// 進入設定頁。這是唯一的入口——先前有兩份重複實作，
  /// 畫面上實際走的那份沒有處理「重播教學」與「補排通知」。
  Future<void> _onSettingsTap() async {
    final result = await Navigator.push<bool>(context, MaterialPageRoute(
      builder: (context) => SettingsPage(
        initialNotificationState: _notifPermissionGranted,
        onNotificationChanged: _updateNotification,
        onReminderSettingsChanged: _rescheduleAllNotifications,
      ),
    ));

    await _loadTitle(); // 標題可能在設定頁被改過

    if (result == true && mounted) { // 使用者按了「重播教學」
      await TutorialService().resetTutorial();
      if (mounted) {
        TutorialService().startTutorial(
          context,
          onOpenMenu: () {
            if (!_isMenuOpen) _toggleMenu();
          },
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

    AnalyticsService().billAdded(
      category: newBill.category ?? 'uncategorized',
      recurring: newBill.recurrence != Recurrence.none,
    );

    if (_notifPermissionGranted && mounted) {
      await _notificationService.scheduleBillNotifications(
          newBill, AppLocalizations.of(context)!);
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

  Future<void> _handleCameraInput() => _handleImageInput(ImageSource.camera, 'camera');

  Future<void> _handleGalleryInput() => _handleImageInput(ImageSource.gallery, 'gallery');

  /// 拍照與相簿走同一條流程，差別只在 ImageSource 與統計標籤。
  Future<void> _handleImageInput(ImageSource source, String method) async {
    _toggleMenu();
    TutorialService().stopForInteraction();
    try {
      final XFile? photo = await _picker.pickImage(source: source);
      if (photo == null) return; // 使用者取消選圖，不算失敗

      AnalyticsService().billInputStarted(method);
      setState(() => _isLoading = true);

      // AI 先在背景跑，廣告同時播，兩件事重疊以縮短使用者等待時間
      final processingFuture =
          _aiService.extractBillFromImage(File(photo.path), method: method);

      // 給原生相機／相簿介面時間收起來，避免廣告蓋在上面
      await Future.delayed(const Duration(milliseconds: 800));

      await AdService().showInterstitialAd();
      AnalyticsService().adShown();

      final bill = await processingFuture;
      await _addNewBill(bill);
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
                 AnalyticsService().billInputStarted('text');
                 setState(() => _isLoading = true);
                 try {
                   // Start AI in background
                   final processingFuture = _aiService.extractBillFromText(textController.text);

                   // Short delay to allow dialog dismissal to settle
                   await Future.delayed(const Duration(milliseconds: 300));

                   // Show Ad and wait
                   await AdService().showInterstitialAd();
                   AnalyticsService().adShown();

                   // Wait for AI
                   final bill = await processingFuture;

                   await _addNewBill(bill);
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
                       // 用 copyWith，逐欄手動重建會漏掉 recurrence
                       _bills[i] = _bills[i].copyWith(category: newName);
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

    // 群組標題不支援拖曳排序，要調整順序請用群組選單的上移／下移
    if (movedItem is! Bill) return;

    // 往上找最近的群組標題，那就是這張帳單被放進去的群組
    BillGroup? targetGroup;
    for (int i = newIndex; i >= 0; i--) {
      if (i < flatList.length && flatList[i] is BillGroup) {
        targetGroup = flatList[i] as BillGroup;
        break;
      }
    }
    if (targetGroup == null) return;

    final billIndex = _bills.indexWhere((b) => b.id == movedItem.id);
    if (billIndex == -1) return;

    // copyWith 而非逐欄重建：先前這裡漏了 recurrence，
    // 使用者把月費帳單拖到別的群組，週期設定就被無聲清成「無」。
    final updatedBill = _bills[billIndex].copyWith(category: targetGroup.id);
    setState(() {
      _bills[billIndex] = updatedBill;
    });
    _saveData();

    // 分類變了不影響到期日，但通知內容帶著帳單資料，一併重排保持一致
    if (_notifPermissionGranted) {
      _notificationService.scheduleBillNotifications(
          updatedBill, AppLocalizations.of(context)!);
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
        color: group.color.withValues(alpha: 0.7), 
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
              if (value == 'rename') _editGroupName(group);
              if (value == 'color') _changeGroupColor(group);
              if (value == 'pin') _togglePinGroup(group);
              if (value == 'up') _moveGroup(group, -1);
              if (value == 'down') _moveGroup(group, 1);
              if (value == 'delete') _deleteGroup(group);
            },
            itemBuilder: (context) => [
              // 重新命名：_editGroupName 早就寫好了（連 l10n 字串都有），
              // 只是沒有任何選單項目叫得到它
              PopupMenuItem(
                value: 'rename',
                child: Row(children: [const Icon(LucideIcons.pencil, size: 16), const SizedBox(width: 8), Text(AppLocalizations.of(context)!.renameGroup)]),
              ),
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
                                Icon(LucideIcons.edit2, size: 16, color: Colors.white.withValues(alpha: 0.5))
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
                            onPressed: _onSettingsTap,
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
                                  shadowColor: Colors.black.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(16),
                                  child: child,
                                ),
                              );
                            },
                            child: child,
                          );
                        },
                        children: flatList.map((item) {
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
                child: Container(color: Colors.black.withValues(alpha: 0.6)),
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
                      color: _isMenuOpen ? const Color(0xFF3F3F46).withValues(alpha: 0.8) : const Color(0xFF2563EB).withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: _isMenuOpen ? const Color(0xFF52525B) : const Color(0xFF60A5FA).withValues(alpha: 0.3)),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 25, offset: const Offset(0, 10))],
                    ),
                    child: const Icon(LucideIcons.plus, color: Colors.white, size: 32),
                  ),
                ),
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.7),
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
    Recurrence selectedRecurrence = bill.recurrence;
    bool isPaid = bill.status == BillStatus.paid;
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
              // dialogBackgroundColor 已棄用，改用 DialogThemeData
              dialogTheme: const DialogThemeData(backgroundColor: Color(0xFF27272A)),
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
            final dialogContext = context;
            Future.delayed(const Duration(milliseconds: 700), () {
               // 等了 700ms，對話框可能已經被關掉，用 context.mounted 確認還在畫面上
               if (mounted && dialogContext.mounted) {
                    TutorialService().startStep9(
                      dialogContext,
                      onNext: () {
                        LoggerService().log("Step 9 onNext triggered -> Showing Completion Step 10");
                        AnalyticsService().tutorialCompleted();
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
                  // 選項直接綁 Recurrence 列舉，不再用字串比對。
                  // 先前多提供了「每日」「每週」兩個列舉裡沒有的選項，
                  // 使用者選了會被靜默改回「無」。
                  DropdownButtonFormField<Recurrence>(
                    initialValue: selectedRecurrence,
                    dropdownColor: const Color(0xFF27272A),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(labelText: AppLocalizations.of(context)!.recurrence, labelStyle: const TextStyle(color: Colors.grey)),
                    items: [
                      DropdownMenuItem(value: Recurrence.none, child: Text(AppLocalizations.of(context)!.none)),
                      DropdownMenuItem(value: Recurrence.monthly, child: Text(AppLocalizations.of(context)!.monthly)),
                      DropdownMenuItem(value: Recurrence.yearly, child: Text(AppLocalizations.of(context)!.yearly)),
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
                  const SizedBox(height: 8),
                  // 標記已繳費。先前 BillStatus.paid 只有被讀取、沒有任何地方
                  // 寫入，所以「已繳費」樣式、扣除待繳總額、停止提醒三個邏輯
                  // 全都是死的。
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: isPaid,
                    activeThumbColor: const Color(0xFF4ADE80),
                    title: Text(AppLocalizations.of(context)!.markAsPaid,
                        style: const TextStyle(color: Colors.white, fontSize: 15)),
                    subtitle: Text(AppLocalizations.of(context)!.markAsPaidDesc,
                        style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    onChanged: (v) => setDialogState(() => isPaid = v),
                  ),
                  const SizedBox(height: 24),
                  Row(children: [
                     Expanded(child: TextButton(
                       onPressed: () => _confirmDeleteBill(context, bill),
                       child: Text(AppLocalizations.of(context)!.delete,
                           style: const TextStyle(color: Colors.redAccent)))),
                     const SizedBox(width: 8),
                     Expanded(child: ElevatedButton(
                       onPressed: () {
                          // Save Changes
                          AnalyticsService().billEdited();
                          final loc = AppLocalizations.of(context)!;
                          final index = _bills.indexWhere((b) => b.id == bill.id);
                          if (index != -1) {
                             final newCategory = categoryController.text.trim().isEmpty
                                 ? loc.uncategorized
                                 : categoryController.text.trim();

                             if (!_groups.any((g) => g.id == newCategory)) {
                                _groups.add(BillGroup(id: newCategory, color: _generateRandomColor()));
                                _sortGroups();
                             }

                             final updatedBill = bill.copyWith(
                               title: titleController.text,
                               amount: double.tryParse(amountController.text) ?? 0,
                               dueDate: dateController.text,
                               status: isPaid ? BillStatus.paid : BillStatus.unpaid,
                               note: noteController.text,
                               category: newCategory,
                               recurrence: selectedRecurrence,
                             );

                             setState(() => _bills[index] = updatedBill);
                             _saveData();

                             // 重排通知。scheduleBillNotifications 內部會先取消舊的，
                             // 標記為已繳費時也會直接取消不再排新的。
                             if (_notifPermissionGranted) {
                               _notificationService.scheduleBillNotifications(updatedBill, loc);
                             }
                          }
                          Navigator.pop(context); // Close dialog
                       },
                       child: Text(AppLocalizations.of(context)!.save)
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

  /// 刪除帳單的確認流程。
  ///
  /// 先前是在確認框裡連續呼叫兩次 Navigator.pop(context)，第二次用的是已經
  /// 被彈掉的路由 context，屬於脆弱寫法。改成先 await 確認結果，拿到答案後
  /// 再各自用正確的 context 關閉，行為明確也不會誤彈到別的頁面。
  Future<void> _confirmDeleteBill(BuildContext editDialogContext, Bill bill) async {
    final loc = AppLocalizations.of(editDialogContext)!;
    final confirmed = await showDialog<bool>(
      context: editDialogContext,
      builder: (confirmContext) => AlertDialog(
        backgroundColor: const Color(0xFF27272A),
        title: Text(loc.deleteBillConfirm, style: const TextStyle(color: Colors.white)),
        content: Text(loc.deleteBillContent, style: const TextStyle(color: Colors.grey)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(confirmContext, false),
            child: Text(loc.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(confirmContext, true),
            child: Text(loc.confirmDelete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await _notificationService.cancelBillNotifications(bill.id);
    AnalyticsService().billDeleted();
    setState(() => _bills.removeWhere((b) => b.id == bill.id));
    await _saveData();

    // 關掉編輯對話框。用 editDialogContext 而不是主頁的 context，
    // 確保彈掉的是對話框而不是整個頁面。
    if (editDialogContext.mounted) Navigator.pop(editDialogContext);
  }

  Widget _buildMenuButton({Key? key, required IconData icon, required String label, required VoidCallback onTap}) {
     return Column(
      children: [
        GestureDetector(
          key: key,
          onTap: onTap,
          child: Container(
            width: 64, height: 64,
            decoration: BoxDecoration(color: const Color(0xFF3F3F46).withValues(alpha: 0.8), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withValues(alpha: 0.1))),
            child: Icon(icon, color: Colors.white, size: 26),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(999)),
          child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }

}
