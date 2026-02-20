import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/user_model.dart';
import '../../services/profile_service.dart';

class PublicProfileScreen extends StatelessWidget {
  final String uid;

  const PublicProfileScreen({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserModel?>(
      future: ProfileService().getUser(uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || snapshot.data == null) {
          return Scaffold(
            appBar: AppBar(leading: const BackButton(color: Colors.black)),
            body: const Center(child: Text("Không tìm thấy người dùng")),
          );
        }

        final user = snapshot.data!;

        return Scaffold(
          backgroundColor: const Color(0xFFFAFAFA),
          body: SingleChildScrollView(
            child: Column(
              children: [
                // Header
                Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.bottomLeft,
                  children: [
                    // Cover
                    Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.purple[100],
                        image:
                            user.coverUrl != null
                                ? DecorationImage(
                                  image: NetworkImage(user.coverUrl!),
                                  fit: BoxFit.cover,
                                )
                                : null,
                      ),
                    ),
                    // Back Button
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 10,
                      left: 10,
                      child: CircleAvatar(
                        backgroundColor: Colors.black26,
                        child: const BackButton(color: Colors.white),
                      ),
                    ),
                    // Avatar
                    Positioned(
                      bottom: -40,
                      left: 20,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                        ),
                        child: CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.grey[200],
                          backgroundImage:
                              user.photoUrl != null
                                  ? NetworkImage(user.photoUrl!)
                                  : null,
                          child:
                              user.photoUrl == null
                                  ? const Icon(
                                    Icons.person,
                                    size: 40,
                                    color: Colors.grey,
                                  )
                                  : null,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 50),

                // Info
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (user.username != null)
                        Text(
                          "@${user.username}",
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                      const SizedBox(height: 16),
                      if (user.bio != null && user.bio!.isNotEmpty)
                        Text(
                          user.bio!,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color: Colors.black87,
                          ),
                        ),

                      const SizedBox(height: 24),
                      Divider(color: Colors.grey[200]),
                      const SizedBox(height: 24),

                      // Join Date
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Tham gia ${DateFormat('MM/yyyy').format(user.createdAt)}",
                            style: GoogleFonts.inter(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
