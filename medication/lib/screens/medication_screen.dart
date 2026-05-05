import 'package:flutter/material.dart';
import 'package:medication/services/database_helper.dart';
import 'add_medication_screen.dart';

class MedicationScreen extends StatefulWidget {
  const MedicationScreen({super.key});

  @override
  State<MedicationScreen> createState() => _MedicationScreenState();
}

class _MedicationScreenState extends State<MedicationScreen> {
  List<Map<String, dynamic>> _medications = [];
  Map<int, List<Map<String, dynamic>>> _doseHistory = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final db = DatabaseHelper();
    final meds = await db.db.then((dbClient) => dbClient.query('medications', orderBy: 'id DESC'));
    final Map<int, List<Map<String, dynamic>>> history = {};
    for (final med in meds) {
      final hist = await db.db.then((dbClient) => dbClient.query('dose_history', 
          where: 'medication_id = ?', 
          whereArgs: [med['id']], 
          orderBy: 'timestamp DESC',
          limit: 5 // Only show last 5 for performance and UI
      ));
      history[med['id'] as int] = hist;
    }
    if (mounted) {
      setState(() {
        _medications = meds;
        _doseHistory = history;
        _loading = false;
      });
    }
  }

  void _openAddMedication() async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => AddMedicationScreen(onSaved: _loadData),
    ));
  }

  Future<void> _markDose(int medId, bool taken) async {
    final db = DatabaseHelper();
    await db.db.then((dbClient) => dbClient.insert('dose_history', {
      'medication_id': medId,
      'taken': taken ? 1 : 0,
      'timestamp': DateTime.now().toIso8601String(),
    }));
    _loadData();
  }

  Future<void> _deleteMedication(int medId) async {
    final db = DatabaseHelper();
    await db.deleteMedication(medId);
    _loadData();
  }

  String _formatRelativeTime(String isoString) {
    try {
      final dateTime = DateTime.parse(isoString);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inDays > 0) return '${difference.inDays}d ago';
      if (difference.inHours > 0) return '${difference.inHours}h ago';
      if (difference.inMinutes > 0) return '${difference.inMinutes}m ago';
      return 'Just now';
    } catch (_) {
      return 'Unknown';
    }
  }

  bool _isDoseComplete(Map<String, dynamic> med) {
    final durationDays = med['duration_days'] as int? ?? 0;
    if (durationDays <= 0) return false;

    try {
      final startDate = DateTime.parse(med['start_date'] as String? ?? '');
      final endDate = startDate.add(Duration(days: durationDays));
      return DateTime.now().isAfter(endDate);
    } catch (_) {
      return false;
    }
  }

  int _getRemainingDays(Map<String, dynamic> med) {
    final durationDays = med['duration_days'] as int? ?? 0;
    if (durationDays <= 0) return 0;

    try {
      final startDate = DateTime.parse(med['start_date'] as String? ?? '');
      final endDate = startDate.add(Duration(days: durationDays));
      final remaining = endDate.difference(DateTime.now()).inDays;
      return remaining < 0 ? 0 : remaining;
    } catch (_) {
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3FF),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF7C3AED)))
          : CustomScrollView(
              slivers: [
                // ── Modern Header ──
                SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.only(bottom: 24),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
                    ),
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Medications',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Manage your daily prescriptions',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Medication List ──
                _medications.isEmpty
                    ? SliverFillRemaining(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.04),
                                      blurRadius: 20,
                                    )
                                  ],
                                ),
                                child: Icon(Icons.medication_rounded, color: Colors.grey.shade300, size: 64),
                              ),
                              const SizedBox(height: 24),
                              const Text(
                                'No medications yet',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E)),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tap the + button to add your first one',
                                style: TextStyle(color: Colors.grey.shade500),
                              ),
                            ],
                          ),
                        ),
                      )
                    : SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, i) {
                              final med = _medications[i];
                              final history = _doseHistory[med['id']] ?? [];
                              final isComplete = _isDoseComplete(med);
                              final remainingDays = _getRemainingDays(med);
                              return _MedicationCard(
                                med: med,
                                history: history,
                                onMarkTaken: () => _markDose(med['id'], true),
                                onMarkNotTaken: () => _markDose(med['id'], false),
                                formatTime: _formatRelativeTime,
                                isComplete: isComplete,
                                remainingDays: remainingDays,
                                onDelete: () => _deleteMedication(med['id']),
                              );
                            },
                            childCount: _medications.length,
                          ),
                        ),
                      ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddMedication,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add New', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: const Color(0xFF7C3AED),
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  HELPER WIDGETS
// ─────────────────────────────────────────────

class _MedicationCard extends StatefulWidget {
  final Map<String, dynamic> med;
  final List<Map<String, dynamic>> history;
  final VoidCallback onMarkTaken;
  final VoidCallback onMarkNotTaken;
  final String Function(String) formatTime;
  final bool isComplete;
  final int remainingDays;
  final VoidCallback onDelete;

  const _MedicationCard({
    required this.med,
    required this.history,
    required this.onMarkTaken,
    required this.onMarkNotTaken,
    required this.formatTime,
    required this.isComplete,
    required this.remainingDays,
    required this.onDelete,
  });

  @override
  State<_MedicationCard> createState() => _MedicationCardState();
}

class _MedicationCardState extends State<_MedicationCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)]),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.medication_rounded, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.med['name'] ?? '',
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.med['dosage'] ?? 'No dosage info',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                      if (widget.med['duration_days'] != null && widget.med['duration_days'] as int > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: widget.isComplete
                              ? const Text(
                                  'Dose Complete',
                                  style: TextStyle(
                                    color: Color(0xFF10B981),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                )
                              : Text(
                                  '${widget.remainingDays} day${widget.remainingDays == 1 ? '' : 's'} left',
                                  style: const TextStyle(
                                    color: Color(0xFF7C3AED),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() => _isExpanded = !_isExpanded),
                  icon: Icon(
                    _isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    color: Colors.grey.shade400,
                  ),
                ),
                PopupMenuButton(
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      child: const Row(
                        children: [
                          Icon(Icons.delete_outline_rounded, size: 20, color: Colors.redAccent),
                          SizedBox(width: 12),
                          Text('Delete', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Delete Medication'),
                            content: const Text('Are you sure you want to delete this medication?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  widget.onDelete();
                                },
                                child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                  icon: const Icon(Icons.more_vert_rounded, size: 20),
                  color: Colors.grey.shade600,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: widget.isComplete
                ? Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
                    ),
                    child: const Center(
                      child: Text(
                        'Dose Complete',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF10B981),
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  )
                : Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7C3AED),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: widget.onMarkTaken,
                          child: const Text('Mark Taken', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.grey.shade700,
                            side: BorderSide(color: Colors.grey.shade200),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: widget.onMarkNotTaken,
                          child: const Text('Mark Missed', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        ),
                      ),
                    ],
                  ),
          ),
          if (_isExpanded) ...[
            const Divider(height: 1),
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Recent History',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF374151)),
                  ),
                  const SizedBox(height: 12),
                  if (widget.history.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text('No doses recorded yet.', style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
                    )
                  else
                    ...widget.history.map((h) => Padding(
                          padding: const EdgeInsets.only(bottom: 10.0),
                          child: Row(
                            children: [
                              Icon(
                                h['taken'] == 1 ? Icons.check_circle_rounded : Icons.cancel_rounded,
                                color: h['taken'] == 1 ? const Color(0xFF10B981) : Colors.redAccent,
                                size: 18,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                h['taken'] == 1 ? 'Taken' : 'Missed',
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF1A1A2E)),
                              ),
                              const Spacer(),
                              Text(
                                widget.formatTime(h['timestamp'] ?? ''),
                                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                              ),
                            ],
                          ),
                        )),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
