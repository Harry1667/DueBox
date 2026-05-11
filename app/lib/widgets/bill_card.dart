import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:app/l10n/generated/app_localizations.dart';
import '../types/bill.dart';

class BillCard extends StatelessWidget {
  final Bill bill;

  const BillCard({super.key, required this.bill});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    DateTime dueDate;
    try {
      dueDate = DateTime.parse(bill.dueDate);
    } catch (e) {
      dueDate = DateTime.now(); // Fallback for invalid dates
    }
    final diffDays = dueDate.difference(today).inDays;

    final loc = AppLocalizations.of(context)!;

    Color statusColor = const Color(0xFFA1A1AA); // zinc-400
    Color statusBg = const Color(0xFF27272A).withOpacity(0.5); // zinc-800/50
    IconData statusIcon = LucideIcons.calendar;
    String statusText = loc.statusRemaining(diffDays);

    if (bill.status == BillStatus.paid) {
      statusColor = const Color(0xFF4ADE80); // green-400
      statusBg = const Color(0xFF14532D).withOpacity(0.2); // green-900/20
      statusIcon = LucideIcons.checkCircle2;
      statusText = loc.statusPaid;
    } else if (diffDays < 0) {
      statusColor = const Color(0xFFF87171); // red-400
      statusBg = const Color(0xFF7F1D1D).withOpacity(0.2); // red-900/20
      statusIcon = LucideIcons.alertCircle;
      statusText = loc.statusOverdue(diffDays.abs());
    } else if (diffDays <= 3) {
      statusColor = const Color(0xFFFBBF24); // amber-400
      statusBg = const Color(0xFF78350F).withOpacity(0.2); // amber-900/20
      statusIcon = LucideIcons.alertCircle;
      statusText = loc.statusRemaining(diffDays);
    }

    final currencyFormat = NumberFormat("#,##0", "en_US");

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF18181B).withOpacity(0.8), // zinc-900/80
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF27272A)), // border-zinc-800
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF27272A), // zinc-800
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          bill.category ?? loc.generalBill,
                          style: const TextStyle(
                            color: Color(0xFFA1A1AA), // zinc-400
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        bill.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  child: Row(
                    children: [
                       // Recurrence Tag
                       if (bill.recurrence != Recurrence.none)
                         Container(
                           margin: const EdgeInsets.only(right: 8),
                           padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                           decoration: BoxDecoration(
                             color: Colors.green.withOpacity(0.2),
                             borderRadius: BorderRadius.circular(999),
                             border: Border.all(color: Colors.green.withOpacity(0.3)),
                           ),
                           child: Row(
                             children: [
                               const Icon(LucideIcons.repeat, size: 10, color: Color(0xFF86EFAC)), // green-300
                               const SizedBox(width: 4),
                               Text(
                                 bill.recurrence == Recurrence.monthly ? loc.monthly : loc.yearly,
                                 style: const TextStyle(color: Color(0xFF86EFAC), fontSize: 10),
                               ),
                             ],
                           ),
                         ),
                         
                      Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: statusBg,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          children: [
                            Icon(statusIcon, size: 14, color: statusColor),
                            const SizedBox(width: 4),
                            Text(
                              statusText,
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                     Text(
                      loc.dueDate,
                      style: const TextStyle(
                        color: Color(0xFF71717A), // zinc-500
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      bill.dueDate,
                      style: const TextStyle(
                        color: Color(0xFFD4D4D8), // zinc-300
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'RobotoMono', // simplified
                      ),
                    ),
                  ],
                ),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '${bill.currency} ',
                        style: const TextStyle(
                          color: Color(0xFF71717A), // zinc-500
                          fontSize: 18,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                      TextSpan(
                        text: currencyFormat.format(bill.amount),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (bill.note != null && bill.note!.isNotEmpty) ...[
              Container(
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.only(top: 16),
                decoration: const BoxDecoration(
                  border: Border(
                      top: BorderSide(color: Color(0x8027272A))), // zinc-800/50
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                     Text(
                      loc.note,
                      style: const TextStyle(
                        color: Color(0xFF71717A), // zinc-500
                        fontSize: 12,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        bill.note!,
                        textAlign: TextAlign.end,
                        style: const TextStyle(
                          color: Color(0xFFA1A1AA), // zinc-400
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
