import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

Future<void> main() async {
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final firestore = FirebaseFirestore.instance;
  final papersCollection = firestore.collection('content').doc('papers').collection('items');

  // Sample Data
  final List<Map<String, dynamic>> samplePapers = [
    {
      'title': '5 Ngôn ngữ yêu thương là gì?',
      'summary': 'Khám phá cách thể hiện và đón nhận tình yêu hiệu quả nhất.',
      'content': '# 5 Ngôn ngữ yêu thương\n\n1. **Lời khẳng định**: Những lời khen, động viên.\n2. **Hành động giúp đỡ**: Làm giúp việc nhà, nấu ăn...\n3. **Quà tặng**: Món quà nhỏ nhưng ý nghĩa.\n4. **Thời gian chất lượng**: Dành trọn vẹn sự chú ý cho nhau.\n5. **Tiếp xúc vật lý**: Nắm tay, ôm, hôn.\n\nHiểu rõ ngôn ngữ của đối phương giúp mối quan hệ bền chặt hơn.',
      'imageUrl': 'https://images.unsplash.com/photo-1518199266791-5375a83190b7?auto=format&fit=crop&w=800&q=80',
      'category': 'Love',
      'status': 'published',
      'authorId': 'admin',
      'authorName': 'Admin Lovesense',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'viewCount': 120,
      'likeCount': 45,
      'commentCount': 0,
      'ratingAvg': 4.8,
      'ratingCount': 10,
    },
    {
      'title': 'Cách vượt qua nỗi buồn sau chia tay',
      'summary': 'Những lời khuyên tâm lý giúp bạn chữa lành trái tim.',
      'content': 'Chia tay không phải là chấm hết. Đó là cơ hội để bạn quay về yêu thương chính mình...',
      'imageUrl': 'https://images.unsplash.com/photo-1516585427167-9f4af9627e6c?auto=format&fit=crop&w=800&q=80',
      'category': 'Self-Growth',
      'status': 'published',
      'authorId': 'admin',
      'authorName': 'Dr. Pepper',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'viewCount': 340,
      'likeCount': 89,
      'commentCount': 5,
      'ratingAvg': 4.5,
      'ratingCount': 20,
    },
    {
      'title': 'Thiền chánh niệm cho người mới bắt đầu',
      'summary': 'Hướng dẫn đơn giản để tìm lại sự bình yên trong tâm hồn.',
      'content': 'Chỉ cần 5 phút mỗi ngày để tập trung vào hơi thở...',
      'imageUrl': 'https://images.unsplash.com/photo-1506126613408-eca07ce68773?auto=format&fit=crop&w=800&q=80',
      'category': 'Psychology',
      'status': 'published',
      'authorId': 'admin',
      'authorName': 'Zen Master',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'viewCount': 56,
      'likeCount': 12,
      'commentCount': 1,
      'ratingAvg': 5.0,
      'ratingCount': 5,
    },
     {
      'title': 'Review sách: Yêu mình trước đã, yêu đời để sau',
      'summary': 'Cuốn sách gối đầu giường cho những tâm hồn nhạy cảm.',
      'content': 'Một cuốn sách nhẹ nhàng, sâu lắng...',
      'imageUrl': 'https://images.unsplash.com/photo-1544947950-fa07a98d237f?auto=format&fit=crop&w=800&q=80',
      'category': 'Reviews',
      'status': 'published',
      'authorId': 'admin',
      'authorName': 'Bookworm',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'viewCount': 200,
      'likeCount': 67,
      'commentCount': 8,
      'ratingAvg': 4.7,
      'ratingCount': 15,
    },
  ];

  for (var paper in samplePapers) {
    await papersCollection.add(paper);
    print('Added paper: ${paper['title']}');
  }

  print('Seeding completed! You can now run the app.');
}
