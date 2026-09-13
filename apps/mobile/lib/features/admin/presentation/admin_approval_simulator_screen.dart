import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/services/supabase_service.dart';

class AdminApprovalSimulatorScreen extends StatefulWidget {
  final VoidCallback onBack;

  const AdminApprovalSimulatorScreen({
    super.key,
    required this.onBack,
  });

  @override
  State<AdminApprovalSimulatorScreen> createState() => _AdminApprovalSimulatorScreenState();
}

class _AdminApprovalSimulatorScreenState extends State<AdminApprovalSimulatorScreen> {
  bool _isLoading = true;
  String _selectedFilter = 'all'; // 'all', 'pending', 'approved', 'rejected'
  List<Map<String, dynamic>> _applications = [];

  // Demo Fallback Applications
  final List<Map<String, dynamic>> _demoApplications = [
    {
      'id': 'prov_demo_001',
      'provider_name': 'Ahmet Yılmaz (Özel Şef)',
      'provider_email': 'ahmet.chef@gastrohost.com',
      'provider_phone': '05551234567',
      'provider_type': 'chef',
      'city_region': 'Balıkesir / Ayvalık',
      'bio': '10 yıllık Fine Dining ve Ege Mutfağı deneyimine sahip şef.',
      'iban': 'TR90 0006 2000 0000 1234 5678 90',
      'status': 'pending_approval',
      'rejection_reason': null,
      'documents_count': 2,
      'created_at': '2026-08-25T14:30:00Z',
    },
    {
      'id': 'prov_demo_002',
      'provider_name': 'Zeynep Miksolojist',
      'provider_email': 'zeynep.bar@gastrohost.com',
      'provider_phone': '05329876543',
      'provider_type': 'bartender',
      'city_region': 'İstanbul / Kadıköy',
      'bio': 'Signature kokteyller ve taşınabilir bar konsepti uzmanı.',
      'iban': 'TR12 0001 5000 0000 9876 5432 10',
      'status': 'approved',
      'rejection_reason': null,
      'documents_count': 1,
      'created_at': '2026-08-24T10:15:00Z',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadApplications();
  }

  Future<void> _loadApplications() async {
    setState(() => _isLoading = true);
    try {
      final supabase = SupabaseService();
      final apps = await supabase.getAllProviderApplications();
      if (apps.isNotEmpty) {
        setState(() {
          _applications = apps.map((app) {
            final profile = (app['profiles'] is Map) ? app['profiles'] as Map<String, dynamic> : null;
            final logistics = app['logistics'] as Map<String, dynamic>? ?? {};
            final payout = app['payout_info'] as Map<String, dynamic>? ?? {};
            final docs = app['provider_documents'] as List<dynamic>? ?? [];

            final firstName = profile?['first_name'] ?? '';
            final lastName = profile?['last_name'] ?? '';
            final fullName = '$firstName $lastName'.trim();
            final accountHolder = payout['account_holder'] as String? ?? '';
            final email = profile?['email'] as String? ?? '';
            final emailPrefix = email.contains('@') ? email.split('@').first : '';

            final displayName = fullName.isNotEmpty
                ? fullName
                : accountHolder.isNotEmpty
                    ? accountHolder
                    : emailPrefix.isNotEmpty
                        ? 'Şef / Barmen ($emailPrefix)'
                        : 'Şef / Barmen Başvurusu';

            final status = app['onboarding_status'] ?? 'pending_approval';

            return {
              'id': app['id'],
              'user_id': app['user_id'],
              'provider_name': displayName,
              'provider_email': profile?['email'] ?? 'onboarding@gastrohost.com',
              'provider_phone': profile?['phone'] ?? 'Belirtilmedi',
              'provider_type': app['provider_type'] ?? 'chef',
              'city_region': logistics['city_region'] ?? 'Belirtilmedi',
              'bio': app['bio'] ?? 'Biyografi henüz girilmedi.',
              'iban': payout['iban'] ?? 'IBAN girilmedi',
              'status': status,
              'rejection_reason': app['rejection_reason'],
              'documents_count': docs.length,
              'documents': docs,
              'created_at': app['created_at'] ?? DateTime.now().toIso8601String(),
            };
          }).toList();
        });
      } else {
        setState(() => _applications = _demoApplications);
      }
    } catch (e) {
      debugPrint('Error loading provider applications: $e');
      setState(() => _applications = _demoApplications);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateApplicationStatus(String providerId, String newStatus, {String? reason}) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final supabase = SupabaseService();
      await supabase.updateProviderApplicationStatus(
        providerId: providerId,
        newStatus: newStatus,
        rejectionReason: reason,
      );

      setState(() {
        final idx = _applications.indexWhere((a) => a['id'] == providerId);
        if (idx != -1) {
          _applications[idx]['status'] = newStatus;
          _applications[idx]['rejection_reason'] = newStatus == 'rejected' ? reason : null;
        }
      });

      if (mounted) {
        final statusLabel = newStatus == 'approved'
            ? 'Onaylandı (Onaylı Şef/Barmen Aktif!)'
            : newStatus == 'rejected'
                ? 'Reddedildi'
                : 'İnceleme Durumuna Alındı';
        messenger.showSnackBar(
          SnackBar(
            content: Text('Şef başvuru durumu güncellendi: $statusLabel', style: GoogleFonts.manrope(fontSize: 13, color: Colors.white)),
            backgroundColor: newStatus == 'approved'
                ? const Color(0xFF10B981)
                : newStatus == 'rejected'
                    ? const Color(0xFFEF4444)
                    : const Color(0xFFF59E0B),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error updating application status: $e');
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Güncelleme hatası: $e', style: GoogleFonts.manrope(fontSize: 13, color: Colors.white)),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showRejectDialog(String providerId, String providerName) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Başvuruyu Reddet',
          style: GoogleFonts.libreCaslonText(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$providerName kişisine ait başvuru reddedilecek.',
              style: GoogleFonts.manrope(fontSize: 13, color: const Color(0xFF747878)),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: reasonController,
              maxLines: 3,
              style: GoogleFonts.manrope(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Ret gerekçesini girin (Örn: Biyografi yetersiz, evraklar eksik...)',
                hintStyle: GoogleFonts.manrope(fontSize: 12, color: const Color(0xFFA0A0A0)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Vazgeç', style: GoogleFonts.manrope(fontSize: 13, color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              final reason = reasonController.text.trim();
              Navigator.pop(ctx);
              _updateApplicationStatus(providerId, 'rejected', reason: reason.isEmpty ? 'Başvuru şartları yetersiz.' : reason);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Reddet', style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  String _getRoleLabel(String type) {
    switch (type) {
      case 'chef':
        return 'Özel Şef / Aşçı';
      case 'bartender':
        return 'Barmen / Miksolojist';
      case 'both':
        return 'Hem Şef Hem Barmen (Mutfak & Bar)';
      default:
        return 'Hizmet Sağlayıcı';
    }
  }

  @override
  Widget build(BuildContext context) {
    final pendingCount = _applications.where((a) => a['status'] == 'pending_approval' || a['status'] == 'draft' || a['status'] == 'pending').length;
    final approvedCount = _applications.where((a) => a['status'] == 'approved').length;
    final rejectedCount = _applications.where((a) => a['status'] == 'rejected').length;

    final filteredApps = _applications.where((a) {
      final status = a['status'];
      if (_selectedFilter == 'pending') return status == 'pending_approval' || status == 'draft' || status == 'pending';
      if (_selectedFilter == 'approved') return status == 'approved';
      if (_selectedFilter == 'rejected') return status == 'rejected';
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B1C1C),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: widget.onBack,
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Admin Şef & Barmen Onay Paneli', style: GoogleFonts.libreCaslonText(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
            Text('Gerçek Başvurular & Onay Yönetimi', style: GoogleFonts.manrope(fontSize: 11, color: const Color(0xFFD4AF37))),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _loadApplications,
            tooltip: 'Yenile',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)))
          : Column(
              children: [
                // Top Summary Stats Bar
                Container(
                  color: const Color(0xFF1B1C1C),
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Row(
                    children: [
                      _buildStatBadge('Bekleyen Başvuru', '$pendingCount', const Color(0xFFF59E0B)),
                      const SizedBox(width: 8),
                      _buildStatBadge('Onaylı Şef', '$approvedCount', const Color(0xFF10B981)),
                      const SizedBox(width: 8),
                      _buildStatBadge('Reddedilen', '$rejectedCount', const Color(0xFFEF4444)),
                    ],
                  ),
                ),

                // Filter Chips Row
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  color: Colors.white,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('Tüm Başvurular (${_applications.length})', 'all'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Onay Bekleyenler ($pendingCount)', 'pending'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Onaylananlar ($approvedCount)', 'approved'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Reddedilenler ($rejectedCount)', 'rejected'),
                      ],
                    ),
                  ),
                ),

                const Divider(height: 1, color: Color(0xFFE4E2E2)),

                // Applications List
                Expanded(
                  child: filteredApps.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.folder_off_outlined, size: 48, color: Colors.grey),
                              const SizedBox(height: 12),
                              Text('Bu filtreye uygun başvuru bulunamadı.', style: GoogleFonts.manrope(fontSize: 14, color: Colors.grey)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredApps.length,
                          itemBuilder: (context, index) {
                            final app = filteredApps[index];
                            final status = app['status'] ?? 'pending_approval';
                            final roleType = app['provider_type'] ?? 'chef';

                            return Card(
                              margin: const EdgeInsets.only(bottom: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: const BorderSide(color: Color(0xFFE4E2E2)),
                              ),
                              elevation: 0,
                              color: Colors.white,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Header: Provider Info & Status Badge
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        CircleAvatar(
                                          backgroundColor: const Color(0xFF1B1C1C),
                                          radius: 22,
                                          child: Icon(
                                            roleType == 'bartender'
                                                ? Icons.local_bar_outlined
                                                : Icons.restaurant_outlined,
                                            color: const Color(0xFFD4AF37),
                                            size: 22,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                app['provider_name'] ?? 'Başvuran Şef',
                                                style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1B1C1C)),
                                              ),
                                              Text(
                                                '${app['provider_email']} • ${app['provider_phone']}',
                                                style: GoogleFonts.manrope(fontSize: 12, color: const Color(0xFF747878)),
                                              ),
                                            ],
                                          ),
                                        ),
                                        _buildStatusBadge(status),
                                      ],
                                    ),
                                    const SizedBox(height: 14),

                                    // Role & Logistics Banner
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFBF9F8),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: const Color(0xFFE4E2E2)),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              const Icon(Icons.star_border_rounded, size: 16, color: Color(0xFF7B5800)),
                                              const SizedBox(width: 6),
                                              Text('Rol: ', style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF7B5800))),
                                              Text(_getRoleLabel(roleType), style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w600)),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              const Icon(Icons.location_on_outlined, size: 16, color: Color(0xFF747878)),
                                              const SizedBox(width: 6),
                                              Text('Hizmet Bölgesi: ', style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.bold)),
                                              Text('${app['city_region']}', style: GoogleFonts.manrope(fontSize: 13)),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              const Icon(Icons.account_balance_outlined, size: 16, color: Color(0xFF747878)),
                                              const SizedBox(width: 6),
                                              Text('IBAN: ', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.bold)),
                                              Expanded(child: Text('${app['iban']}', style: GoogleFonts.manrope(fontSize: 12), overflow: TextOverflow.ellipsis)),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Bio snippet
                                    if (app['bio'] != null && app['bio'].toString().isNotEmpty) ...[
                                      const SizedBox(height: 10),
                                      Text(
                                        'Biyografi: "${app['bio']}"',
                                        style: GoogleFonts.manrope(fontSize: 12, fontStyle: FontStyle.italic, color: const Color(0xFF555555)),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],

                                    // Rejection reason (if rejected)
                                    if (status == 'rejected' && app['rejection_reason'] != null) ...[
                                      const SizedBox(height: 10),
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFEF2F2),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: const Color(0xFFFCA5A5)),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFFDC2626)),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                'Ret Nedeni: ${app['rejection_reason']}',
                                                style: GoogleFonts.manrope(fontSize: 12, color: const Color(0xFFB91C1C)),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],

                                    const SizedBox(height: 16),

                                    // Action Buttons
                                    Row(
                                      children: [
                                        // Approve Button
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            onPressed: status == 'approved' ? null : () => _updateApplicationStatus(app['id'], 'approved'),
                                            icon: const Icon(Icons.check_circle_rounded, size: 16),
                                            label: Text('Onayla', style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.bold)),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFF10B981),
                                              foregroundColor: Colors.white,
                                              disabledBackgroundColor: Colors.grey.shade200,
                                              disabledForegroundColor: Colors.grey,
                                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),

                                        // Reject Button
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            onPressed: status == 'rejected' ? null : () => _showRejectDialog(app['id'], app['provider_name']),
                                            icon: const Icon(Icons.cancel_outlined, size: 18),
                                            label: Text('Reddet', style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.bold)),
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: const Color(0xFFEF4444),
                                              side: BorderSide(color: status == 'rejected' ? Colors.grey.shade300 : const Color(0xFFEF4444)),
                                              padding: const EdgeInsets.symmetric(vertical: 12),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),

                                        // Reset Button
                                        IconButton(
                                          onPressed: () => _updateApplicationStatus(app['id'], 'pending_approval'),
                                          icon: const Icon(Icons.restart_alt_rounded, size: 22, color: Colors.grey),
                                          tooltip: 'İnceleme Durumuna Al',
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatBadge(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Column(
          children: [
            Text(value, style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: GoogleFonts.manrope(fontSize: 11, color: Colors.white70)),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String key) {
    final isSelected = _selectedFilter == key;
    return ChoiceChip(
      label: Text(label, style: GoogleFonts.manrope(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedFilter = key),
      selectedColor: const Color(0xFF1B1C1C),
      backgroundColor: const Color(0xFFFBF9F8),
      labelStyle: TextStyle(color: isSelected ? Colors.white : const Color(0xFF1B1C1C)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isSelected ? const Color(0xFF1B1C1C) : const Color(0xFFE4E2E2))),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color fg;
    String text;

    switch (status) {
      case 'approved':
        bg = const Color(0xFFD1FAE5);
        fg = const Color(0xFF065F46);
        text = 'Onaylı Şef';
        break;
      case 'rejected':
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFF991B1B);
        text = 'Reddedildi';
        break;
      default:
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFF92400E);
        text = 'Onay Bekliyor';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(text, style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.bold, color: fg)),
    );
  }
}
