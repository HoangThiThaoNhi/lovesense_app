import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/course_model.dart';
import '../../models/lesson_model.dart';

class CourseSeeder {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> seedCourses() async {
    // 1. Individual Course: "Quản lý Cảm xúc Cá nhân"
    await _createCourse(
      CourseModel(
        id: 'course_individual_01',
        title: 'Quản lý Cảm xúc Cá nhân',
        description:
            'Học cách nhận diện và điều hòa cảm xúc của bản thân để sống tích cực hơn.',
        thumbnailUrl:
            'https://images.unsplash.com/photo-1517048676732-d65bc937f952?w=800',
        instructorId: 'admin_01',
        instructorName: 'Dr. Sarah Nguyen',
        lessonsCount: 3,
        rating: 4.8,
        isApproved: true,
        createdAt: DateTime.now(),
        level: 'Basic',
        targetAudience: 'Individual',
        tags: ['Self-care', 'Emotion', 'Healing'],
        duration: '45 mins',
      ),
      [
        LessonModel(
          id: 'lesson_ind_01',
          courseId: 'course_individual_01',
          title: 'Bài 1: Nhận diện Cảm xúc',
          description: 'Khám phá bánh xe cảm xúc.',
          type: LessonType.text,
          contentUrl: '',
          contentText:
              'Cảm xúc không đúng cũng không sai. Việc đầu tiên là gọi tên chúng...',
          order: 1,
          estimatedMinutes: 10,
          reflectionQuestion:
              'Hôm nay bạn đã cảm thấy những cảm xúc gì? Hãy liệt kê chúng.',
        ),
        LessonModel(
          id: 'lesson_ind_02',
          courseId: 'course_individual_01',
          title: 'Bài 2: Kỹ thuật Thở 4-7-8',
          description: 'Phương pháp điều hòa nhịp thở.',
          type: LessonType.video, // Placeholder type
          contentUrl: 'https://youtube.com/placeholder',
          contentText: 'Kỹ thuật thở 4-7-8 giúp giảm căng thẳng tức thì...',
          order: 2,
          estimatedMinutes: 15,
          reflectionQuestion:
              'Bạn cảm thấy thế nào trước và sau khi thực hành thở?',
        ),
        LessonModel(
          id: 'lesson_ind_03',
          courseId: 'course_individual_01',
          title: 'Bài 3: Viết Nhật ký Biết ơn',
          description: 'Thực hành lòng biết ơn mỗi ngày.',
          type: LessonType.text,
          contentUrl: '',
          contentText: 'Lòng biết ơn giúp chuyển hóa năng lượng tiêu cực...',
          order: 3,
          estimatedMinutes: 20,
          reflectionQuestion: 'Viết ra 3 điều bạn biết ơn ngay lúc này.',
        ),
      ],
    );

    // 2. Couple Course: "Giao tiếp Không bạo lực (NVC)"
    await _createCourse(
      CourseModel(
        id: 'course_couple_01',
        title: 'Giao tiếp Yêu thương',
        description:
            'Xây dựng kết nối sâu sắc thông qua giao tiếp trắc ẩn và lắng nghe chủ động.',
        thumbnailUrl:
            'https://images.unsplash.com/photo-1529156069898-49953e39b3ac?w=800',
        instructorId: 'admin_02',
        instructorName: 'Coach Minh & Lan',
        lessonsCount: 3,
        rating: 4.9,
        isApproved: true,
        createdAt: DateTime.now(),
        level: 'Intermediate',
        targetAudience: 'Couple',
        tags: ['Communication', 'Relationship', 'Love'],
        duration: '60 mins',
      ),
      [
        LessonModel(
          id: 'lesson_cpl_01',
          courseId: 'course_couple_01',
          title: 'Bài 1: Lắng nghe Chủ động',
          description: 'Học cách nghe để hiểu, không phải để đáp trả.',
          type: LessonType.text,
          contentUrl: '',
          contentText: 'Lắng nghe chủ động đòi hỏi sự hiện diện hoàn toàn...',
          order: 1,
          estimatedMinutes: 15,
          coupleActionTask:
              'Ngồi đối diện nhau. Người A nói 2 phút về tâm trạng. Người B chỉ nghe, không ngắt lời. Đổi vai.',
        ),
        LessonModel(
          id: 'lesson_cpl_02',
          courseId: 'course_couple_01',
          title: 'Bài 2: Ngôn ngữ Yêu thương',
          description: '5 Ngôn ngữ tình yêu.',
          type: LessonType.video,
          contentUrl: 'https://youtube.com/placeholder',
          contentText: 'Mỗi người có cách cảm nhận tình yêu khác nhau...',
          order: 2,
          estimatedMinutes: 20,
          coupleActionTask:
              'Làm bài kiểm tra ngôn ngữ tình yêu cùng nhau và chia sẻ kết quả.',
        ),
        LessonModel(
          id: 'lesson_cpl_03',
          courseId: 'course_couple_01',
          title: 'Bài 3: Giải quyết Xung đột',
          description: 'Biến tranh cãi thành hiểu biết.',
          type: LessonType.text,
          contentUrl: '',
          contentText: 'Khi xung đột, hãy tập trung vào cảm xúc và nhu cầu...',
          order: 3,
          estimatedMinutes: 25,
          coupleActionTask:
              'Cùng nhau thảo luận về một mâu thuẫn nhỏ gần đây mà không đổ lỗi.',
        ),
      ],
    );

    // 3. Mixed Course: "Tài chính Gia đình"
    await _createCourse(
      CourseModel(
        id: 'course_mixed_01',
        title: 'Tài chính Thông minh',
        description: 'Quản lý tài chính cá nhân và gia đình hiệu quả.',
        thumbnailUrl:
            'https://images.unsplash.com/photo-1579621970563-ebec7560ff3e?w=800',
        instructorId: 'admin_03',
        instructorName: 'Finance Expert',
        lessonsCount: 2,
        rating: 4.5,
        isApproved: true,
        createdAt: DateTime.now(),
        level: 'Basic',
        targetAudience: 'Both',
        tags: ['Finance', 'Planning', 'Future'],
        duration: '40 mins',
      ),
      [
        LessonModel(
          id: 'lesson_mix_01',
          courseId: 'course_mixed_01',
          title: 'Bài 1: Tư duy về Tiền bạc',
          description: 'Hiểu đúng về giá trị của tiền.',
          type: LessonType.text,
          contentUrl: '',
          contentText: 'Tiền bạc là phương tiện, không phải mục đích...',
          order: 1,
          estimatedMinutes: 15,
          reflectionQuestion:
              'Quan điểm về tiền bạc của bạn chịu ảnh hưởng từ đâu?',
        ),
        LessonModel(
          id: 'lesson_mix_02',
          courseId: 'course_mixed_01',
          title: 'Bài 2: Lập Ngân sách Chung',
          description: 'Cách quản lý chi tiêu cho cặp đôi.',
          type: LessonType.text,
          contentUrl: '',
          contentText: 'Công khai tài chính và lập quỹ chung...',
          order: 2,
          estimatedMinutes: 25,
          coupleActionTask:
              'Liệt kê các khoản chi cố định hàng tháng của cả hai.',
          reflectionQuestion:
              'Bạn lo lắng điều gì nhất về tài chính?', // Supports both if logic allows, or model could have both fields populated
        ),
      ],
    );
  }

  Future<void> _createCourse(
    CourseModel course,
    List<LessonModel> lessons,
  ) async {
    final courseRef = _firestore.collection('courses').doc(course.id);
    await courseRef.set(course.toMap());

    // Create lessons sub-collection
    for (var lesson in lessons) {
      await courseRef.collection('lessons').doc(lesson.id).set(lesson.toMap());
    }

    // Update lesson count just in case
    await courseRef.update({'lessonsCount': lessons.length});

    print('Seeded Course: ${course.title}');
  }
}
