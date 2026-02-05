
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';
import '../../models/mood_model.dart';
import '../../services/mood_service.dart';

class MoodCheckInWidget extends StatefulWidget {
  const MoodCheckInWidget({super.key});

  @override
  State<MoodCheckInWidget> createState() => _MoodCheckInWidgetState();
}

class _MoodCheckInWidgetState extends State<MoodCheckInWidget> {
  final MoodService _moodService = MoodService();
  MoodType? _selectedMood;
  bool _isLoading = false;
  String? _blockReason;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _submitMood() async {
    if (_selectedMood == null) return;

    setState(() => _isLoading = true);
    try {
      // Logic checked on server/transaction side anyway. 
      // But we can double check async if we want, or just try.
      await _moodService.logMood(_selectedMood!);
      
      if (mounted) {
        setState(() {
          _selectedMood = null; // Reset selection on success
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã ghi nhận cảm xúc của bạn!')),
          );
        });
      }
    } catch (e) {
      String errorMessage = e.toString().replaceAll("Exception:", "").trim();
      if (errorMessage.contains("converted Future") || errorMessage.contains("transaction")) {
         errorMessage = "Không thể lưu lúc này. Vui lòng thử lại.";
      }

      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)), 
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DailyMoodSummary>(
      stream: _moodService.getDailySummaryStream(),
      builder: (context, snapshot) {
        final summary = snapshot.data;
        final currentMood = summary?.currentMood;
        
        // Instant check using stream data
        final status = _moodService.checkEligibilityLocal(summary);
        final isBlocked = status['allowed'] == false;
        final blockReason = status['reason'] as String?;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Cảm xúc của bạn',
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (currentMood != null)
                     Container(
                       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                       decoration: BoxDecoration(
                         color: MoodEntry.getColor(currentMood).withOpacity(0.2),
                         borderRadius: BorderRadius.circular(12),
                       ),
                       child: Text(
                         MoodEntry.getLabel(currentMood),
                         style: GoogleFonts.inter(
                           fontSize: 12, 
                           fontWeight: FontWeight.bold,
                           color: MoodEntry.getColor(currentMood)
                         ),
                       ),
                     ).animate().fadeIn(),
                ],
              ),
              const SizedBox(height: 16),
              
              if (isBlocked) 
                Container(
                   width: double.infinity,
                   padding: const EdgeInsets.all(12),
                   decoration: BoxDecoration(
                     color: Colors.grey[100],
                     borderRadius: BorderRadius.circular(12),
                     border: Border.all(color: Colors.grey[300]!)
                   ),
                   child: Row(
                     children: [
                       const Icon(Icons.info_outline, color: Colors.grey),
                       const SizedBox(width: 8),
                       Expanded(
                         child: Text(
                           blockReason ?? '',
                           style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[700]),
                         ),
                       ),
                     ],
                   ),
                )
              else 
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: MoodType.values.map((type) {
                    final isSelected = _selectedMood == type;
                    // Determine Size
                    final double size = isSelected ? 56 : 40;
                    
                    return GestureDetector(
                      onTap: isBlocked ? null : () {
                         setState(() {
                           _selectedMood = type;
                         });
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 3D Animated Icon
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.elasticOut,
                            width: size + 16,
                            height: size + 16,
                            padding: EdgeInsets.all(isSelected ? 4 : 0),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected 
                                  ? MoodEntry.getColor(type).withOpacity(0.15) 
                                  : Colors.transparent,
                               boxShadow: isSelected ? [
                                BoxShadow(
                                  color: MoodEntry.getColor(type).withOpacity(0.4),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                )
                              ] : null,
                            ),
                            child: ColorFiltered(
                              // Gray out if blocked or not selected
                              colorFilter: isBlocked 
                                  ? const ColorFilter.mode(Colors.grey, BlendMode.saturation) 
                                  : const ColorFilter.mode(Colors.transparent, BlendMode.multiply),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // 1. Fallback/Placeholder Icon (Always visible initially)
                                  Icon(
                                    MoodEntry.getIcon(type), 
                                    size: size, 
                                    color: MoodEntry.getColor(type).withOpacity(0.5)
                                  ),
                                  // 2. Lottie Animation
                                  Lottie.network(
                                    MoodEntry.getLottieUrl(type),
                                    fit: BoxFit.contain,
                                    animate: isSelected, // Animate only when selected
                                    // Remove enableMergePaths for stability
                                    errorBuilder: (context, error, stack) => const SizedBox(), // If error, show nothing (Icon below shows)
                                    frameBuilder: (context, child, composition) {
                                      if (composition == null) {
                                        return const SizedBox(); // Loading... show Icon below
                                      }
                                      return child; // Loaded!
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Label underneath
                          AnimatedOpacity(
                            duration: 200.ms,
                            opacity: isSelected ? 1.0 : 0.6,
                            child: Text(
                              MoodEntry.getLabel(type),
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected ? MoodEntry.getColor(type) : Colors.grey[600],
                              ),
                            ),
                          )
                        ],
                      ),
                    );
                  }).toList(),
                ),

              if (_selectedMood != null && !isBlocked)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitMood,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: MoodEntry.getColor(_selectedMood!).withOpacity(0.2),
                        elevation: 0,
                        foregroundColor: MoodEntry.getColor(_selectedMood!),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isLoading 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
                          : const Text("Check-in ngay"),
                    ),
                  ),
                ).animate().slideY(begin: 0.5, end: 0),
            ],
          ),
        ).animate().fadeIn(delay: 200.ms).moveY(begin: 20, end: 0);
      }
    );
  }
}
