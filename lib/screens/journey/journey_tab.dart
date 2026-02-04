import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class JourneyTab extends StatefulWidget {
  const JourneyTab({super.key});

  @override
  State<JourneyTab> createState() => _JourneyTabState();
}

class _JourneyTabState extends State<JourneyTab> {
  // Calendar State
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final Map<DateTime, List<String>> _events = {}; // Mock events

  // Journal State
  final TextEditingController _journalController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    // Seed some mock mood data
    _events[DateTime.now().subtract(const Duration(days: 1))] = ['happy'];
    _events[DateTime.now().subtract(const Duration(days: 2))] = ['neutral'];
    _events[DateTime.now().subtract(const Duration(days: 4))] = ['sad'];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: Text(
          'Hành trình của tôi',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Personal Summary Stats
            _buildPersonalSummary(),

            const SizedBox(height: 32),

            // 2. Trend Analysis (Charts)
            _buildTrendAnalysis(),

            const SizedBox(height: 32),

            // 3. Emotional History (Calendar)
            _buildEmotionalHistory(),

            const SizedBox(height: 32),

            // 4. Personal Journal
            _buildJournalSection(),
            
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
           _buildStatItem('7 Ngày', 'Check-in', Icons.calendar_today, Colors.blue),
           _buildStatItem('12', 'Mục tiêu', Icons.check_circle_outline, Colors.green),
           _buildStatItem('5', 'Bài học', Icons.lightbulb_outline, Colors.orange),
        ],
      ),
    ).animate().fadeIn().moveY(begin: 20, end: 0);
  }

  Widget _buildStatItem(String value, String label, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.montserrat(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }

  Widget _buildTrendAnalysis() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Xu hướng cảm xúc',
          style: GoogleFonts.montserrat(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          height: 250,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
             border: Border.all(color: Colors.grey.withOpacity(0.1)),
          ),
          child: Column(
            children: [
               Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Tuần này bạn có xu hướng tích cực hơn tuần trước 🌱",
                  style: GoogleFonts.inter(
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                    fontSize: 13
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: false),
                    titlesData: FlTitlesData(
                      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            switch (value.toInt()) {
                              case 0: return const Text('T2');
                              case 1: return const Text('T3');
                              case 2: return const Text('T4');
                              case 3: return const Text('T5');
                              case 4: return const Text('T6');
                              case 5: return const Text('T7');
                              case 6: return const Text('CN');
                            }
                            return const Text('');
                          },
                          interval: 1,
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: const [
                          FlSpot(0, 3), // Mon
                          FlSpot(1, 2), // Tue
                          FlSpot(2, 4), // Wed
                          FlSpot(3, 3), // Thu
                          FlSpot(4, 5), // Fri
                          FlSpot(5, 4), // Sat
                          FlSpot(6, 5), // Sun
                        ],
                        isCurved: true,
                        color: const Color(0xFFFF4081),
                        barWidth: 3,
                        dotData: const FlDotData(show: true),
                        belowBarData: BarAreaData(
                          show: true,
                          color: const Color(0xFFFF4081).withOpacity(0.1),
                        ),
                      ),
                    ],
                    minY: 0,
                    maxY: 6,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildEmotionalHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Lịch sử cảm xúc',
          style: GoogleFonts.montserrat(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.withOpacity(0.1)),
          ),
          child: TableCalendar(
            locale: 'en_US', // Can be switched to 'vi_VN' if initializeDateFormatting is called
            firstDay: DateTime.utc(2020, 10, 16),
            lastDay: DateTime.utc(2030, 3, 14),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            calendarFormat: CalendarFormat.month,
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
            calendarStyle: const CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Color(0xFFF48FB1),
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Color(0xFFFF4081),
                shape: BoxShape.circle,
              ),
            ),
            // Custom Builders to show Markers for moods
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                 // Check if there's an event (mood) on this day
                 // This is a naive check. In real app, check _events map.
                 if (_events.containsKey(DateTime(date.year, date.month, date.day))) {
                   return Positioned(
                     bottom: 1,
                     child: Container(
                       width: 6,
                       height: 6,
                       decoration: const BoxDecoration(
                         color: Colors.blueAccent,
                         shape: BoxShape.circle,
                       ),
                     ),
                   );
                 }
                 return null;
              },
            ),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 400.ms);
  }

  Widget _buildJournalSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nhật ký hôm nay',
          style: GoogleFonts.montserrat(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3E0), // Warm notebook color
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('EEEE, d MMMM').format(DateTime.now()),
                style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.orange[800]),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _journalController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'Bạn đang nghĩ gì? Viết tự do vào đây nhé...',
                  hintStyle: GoogleFonts.inter(color: Colors.orange[300]),
                  border: InputBorder.none,
                ),
                style: GoogleFonts.inter(color: Colors.black87),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Save Logic
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã lưu nhật ký riêng tư 🔒')),
                    );
                    FocusScope.of(context).unfocus();
                  },
                  icon: const Icon(Icons.lock_outline, size: 16),
                  label: const Text('Lưu nhật ký'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[400],
                    foregroundColor: Colors.white,
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ).animate().fadeIn(delay: 600.ms);
  }
}
