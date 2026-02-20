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
  late Stream<DailyMoodSummary?> _moodStream;

  @override
  void initState() {
    super.initState();
    _moodStream = _moodService.getDailySummaryStream();
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
      if (errorMessage.contains("converted Future") ||
          errorMessage.contains("transaction")) {
        errorMessage = "Không thể lưu lúc này. Vui lòng thử lại.";
      }

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorMessage)));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DailyMoodSummary?>(
      stream: _moodStream,
      builder: (context, snapshot) {
        final summary = snapshot.data;
        final currentMood = summary?.currentMood;

        // Instant check using stream data
        final status = _moodService.checkEligibilityLocal(summary);
        final isBlocked = status['allowed'] == false;
        final blockReason = status['reason'] as String?;

        final effectiveSelection =
            (isBlocked && currentMood != null) ? currentMood : _selectedMood;

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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: MoodEntry.getColor(currentMood).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        MoodEntry.getLabel(currentMood),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: MoodEntry.getColor(currentMood),
                        ),
                      ),
                    ).animate().fadeIn(),
                ],
              ),
              const SizedBox(height: 16),

              // Always show Icon Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children:
                    MoodType.values.map((type) {
                      // If blocked, show the saved mood as selected
                      final isSelected = effectiveSelection == type;
                      // Determine Size
                      final double size = isSelected ? 56 : 40;

                      return GestureDetector(
                        onTap: () {
                          if (isBlocked) {
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  blockReason ?? "Bạn đã hoàn thành check-in.",
                                ),
                                duration: const Duration(seconds: 3),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            );
                          } else {
                            setState(() {
                              _selectedMood = type;
                            });
                          }
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
                                color:
                                    isSelected
                                        ? MoodEntry.getColor(
                                          type,
                                        ).withOpacity(0.15)
                                        : Colors.transparent,
                                boxShadow:
                                    isSelected
                                        ? [
                                          BoxShadow(
                                            color: MoodEntry.getColor(
                                              type,
                                            ).withOpacity(0.4),
                                            blurRadius: 20,
                                            spreadRadius: 2,
                                          ),
                                        ]
                                        : null,
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // 1. Fallback/Placeholder Icon (Always visible initially)
                                  Icon(
                                    MoodEntry.getIcon(type),
                                    size: size,
                                    color: MoodEntry.getColor(type).withOpacity(
                                      0.3,
                                    ), // Lower opacity to avoid clash
                                  ),
                                  // 2. Lottie Animation
                                  Lottie.network(
                                    MoodEntry.getLottieUrl(type),
                                    fit: BoxFit.contain,
                                    // Always animate to show "live" UI, or just selected?
                                    // User wanted "Animation", let's animate all but maybe slowly or once?
                                    // Let's stick to animate all for maximum effect.
                                    animate: true,
                                    errorBuilder:
                                        (context, error, stack) =>
                                            const SizedBox(),
                                    frameBuilder: (
                                      context,
                                      child,
                                      composition,
                                    ) {
                                      // Fade in when loaded
                                      return AnimatedOpacity(
                                        opacity: composition != null ? 1 : 0,
                                        duration: const Duration(
                                          milliseconds: 300,
                                        ),
                                        child: child,
                                      );
                                    },
                                  ),
                                ],
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
                                  fontWeight:
                                      isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                  color:
                                      isSelected
                                          ? MoodEntry.getColor(type)
                                          : Colors.grey[600],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
              ),

              // Quote Section (Only if Blocked/Checked-In)
              // Quote Section (Only if Blocked/Checked-In)
              if (isBlocked && effectiveSelection != null)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 20),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: MoodEntry.getColor(
                      effectiveSelection,
                    ).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: MoodEntry.getColor(
                        effectiveSelection,
                      ).withOpacity(0.15),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        // Use stored quote if available, otherwise fallback to random
                        (summary?.quote ??
                                MoodEntry.getRandomQuote(effectiveSelection))
                            .replaceAll('"', '')
                            .replaceAll('“', '')
                            .replaceAll('”', ''),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          height: 1.5,
                          fontStyle: FontStyle.italic,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn().slideY(begin: 0.2, end: 0),

              if (_selectedMood != null && !isBlocked)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitMood,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: MoodEntry.getColor(
                          _selectedMood!,
                        ).withOpacity(0.2),
                        elevation: 0,
                        foregroundColor: MoodEntry.getColor(_selectedMood!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child:
                          _isLoading
                              ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : const Text(
                                "Check-in ngay",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                    ),
                  ),
                ).animate().slideY(begin: 0.5, end: 0),
            ],
          ),
        ).animate().fadeIn(delay: 200.ms).moveY(begin: 20, end: 0);
      },
    );
  }
}
