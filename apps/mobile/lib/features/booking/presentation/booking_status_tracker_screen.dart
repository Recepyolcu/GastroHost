import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BookingStatusTrackerScreen extends StatefulWidget {
  final String? bookingId;
  final VoidCallback onBackToHome;
  final VoidCallback onOpenChat;

  const BookingStatusTrackerScreen({
    super.key,
    this.bookingId,
    required this.onBackToHome,
    required this.onOpenChat,
  });

  @override
  State<BookingStatusTrackerScreen> createState() => _BookingStatusTrackerScreenState();
}

class _BookingStatusTrackerScreenState extends State<BookingStatusTrackerScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFBF9F8),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.black),
          onPressed: widget.onBackToHome,
        ),
        title: Text(
          "Tonight's Event",
          style: GoogleFonts.libreCaslonText(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Event Header
              Text(
                "Tonight's Event with Chef Marco",
                style: GoogleFonts.libreCaslonText(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1B1C1C),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Tuscan Truffle Experience • 7:30 PM",
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  color: const Color(0xFF747878),
                ),
              ),
              const SizedBox(height: 24),

              // Live Status Timeline Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE4E2E2)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Canlı Etkinlik Durumu',
                      style: GoogleFonts.libreCaslonText(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1B1C1C),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Step 1: Accepted
                    _buildTimelineStep(
                      title: 'Rezervasyon Onaylandı',
                      subtitle: 'Şef etkinliğinizi onayladı ve menüye alındınız.',
                      isDone: true,
                    ),
                    // Step 2: Shopping
                    _buildTimelineStep(
                      title: 'Malzeme Alışverişi & Tedarik',
                      subtitle: 'Taze malzemeler yerel gurme pazarlardan tedarik ediliyor.',
                      isDone: true,
                    ),
                    // Step 3: On The Way
                    _buildTimelineStep(
                      title: 'Şef Yolda',
                      subtitle: 'Şefiniz adresinize doğru yola çıktı.',
                      isCurrent: true,
                    ),
                    // Step 4: In Kitchen
                    _buildTimelineStep(
                      title: 'Mutfak Hazırlığı & Servis',
                      subtitle: 'Tabaklama ve canlı sunum gerçekleştiriliyor.',
                      isUpcoming: true,
                    ),
                    // Step 5: Completed
                    _buildTimelineStep(
                      title: 'Etkinlik Tamamlandı',
                      subtitle: 'Mutfak temizlendi ve hizmet başarıyla sonlandı.',
                      isUpcoming: true,
                      isLast: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Map & Chat Button
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  image: const DecorationImage(
                    image: NetworkImage(
                      'https://lh3.googleusercontent.com/aida-public/AB6AXuBVy2kw2xBFlyCArG9akCtDTiZHJUx0XGlWhoRI--ZD4OFS2nju_x0WMPCPdZ2H9LrmAVu1Lko9AIOOCwidSXvD00bUkTI9Z9vKQe2MRCTEPmp8i8-eZ7XvNb2wRTiH-_vErWBRcAGQTn7ruY3yfn78O1z0LEyW30e85gDWFYAD8AZ9SdITykQMlqloiJQt93KZsva5AXFOZjI5NSNZcc5zJhCnQgUSViTtxb5Oxel9lWz2qbZETfcW',
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      bottom: 12,
                      right: 12,
                      child: ElevatedButton.icon(
                        onPressed: widget.onOpenChat,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                        icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                        label: const Text('Chat with Chef'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Procurement Receipt Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE4E2E2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.receipt_long_rounded, color: Color(0xFF7B5800), size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Procurement Receipt',
                          style: GoogleFonts.libreCaslonText(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1B1C1C),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Sourced fresh this morning specifically for your menu.',
                      style: GoogleFonts.manrope(fontSize: 12, color: const Color(0xFF747878)),
                    ),
                    const SizedBox(height: 16),

                    _buildReceiptRow('Alba White Truffles', '2 oz'),
                    _buildReceiptRow('Hand-milled 00 Flour', '500g'),
                    _buildReceiptRow('Aged Parmigiano-Reggiano', '1 wedge'),
                    _buildReceiptRow('Chianina Beef Tenderloin', '32 oz'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineStep({
    required String title,
    required String subtitle,
    bool isDone = false,
    bool isCurrent = false,
    bool isUpcoming = false,
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDone
                    ? Colors.black
                    : (isCurrent ? const Color(0xFF7B5800) : const Color(0xFFEFEDED)),
              ),
              child: isDone
                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                  : (isCurrent
                      ? const Icon(Icons.directions_car_rounded, color: Colors.white, size: 13)
                      : null),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 36,
                color: const Color(0xFFE4E2E2),
              ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.manrope(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isUpcoming ? const Color(0xFF747878) : const Color(0xFF1B1C1C),
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  color: const Color(0xFF747878),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReceiptRow(String item, String qty) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(item, style: GoogleFonts.manrope(fontSize: 13, color: const Color(0xFF1B1C1C))),
          Text(qty, style: GoogleFonts.manrope(fontSize: 12, color: const Color(0xFF747878))),
        ],
      ),
    );
  }
}
