import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/coming_soon_view.dart';

class DiscussionForumScreen extends StatelessWidget {
  const DiscussionForumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Discussion Forum')),
      body: const ComingSoonView(
        icon: Icons.forum_outlined,
        title: 'Discussion Forum',
        message: 'Ask questions and share cases with other physios.',
        color: AppColors.accentPurple,
      ),
    );
  }
}
