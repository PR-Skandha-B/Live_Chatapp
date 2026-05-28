import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _descController;
  bool _isEditing = false;
  String? _selectedAvatar;
  
  final List<String> _presetAvatars = [
    '',
    'https://api.dicebear.com/7.x/adventurer/png?seed=Felix',
    'https://api.dicebear.com/7.x/adventurer/png?seed=Aneka',
    'https://api.dicebear.com/7.x/bottts/png?seed=Robot',
    'https://api.dicebear.com/7.x/pixel-art/png?seed=Pixel',
    'https://api.dicebear.com/7.x/fun-emoji/png?seed=Smile',
    'https://api.dicebear.com/7.x/lorelei/png?seed=Lorelei',
  ];

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;
    _descController = TextEditingController(text: user?.description ?? '');
    if (user?.avatar != null && user!.avatar.isNotEmpty) {
      _selectedAvatar = user.avatar;
    }
  }

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  void _saveProfile() async {
    final success = await context.read<AuthProvider>().updateProfile(
      _selectedAvatar?.isEmpty == true ? '' : _selectedAvatar,
      _descController.text.trim(),
    );
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );
      setState(() => _isEditing = false);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.read<AuthProvider>().error ?? 'Failed to update')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    if (user == null) return const Scaffold(body: Center(child: Text('Not logged in')));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: context.watch<AuthProvider>().isLoading ? null : _saveProfile,
            )
          else
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 60,
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
              backgroundImage: _selectedAvatar != null && _selectedAvatar!.isNotEmpty
                  ? NetworkImage(_selectedAvatar!)
                  : null,
              child: _selectedAvatar == null || _selectedAvatar!.isEmpty
                  ? Icon(Icons.person, size: 60, color: Theme.of(context).primaryColor)
                  : null,
            ),
            if (_isEditing) ...[
              const SizedBox(height: 16),
              const Text('Change Avatar', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SizedBox(
                height: 60,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _presetAvatars.length,
                  itemBuilder: (context, index) {
                    final avatarUrl = _presetAvatars[index];
                    final isSelected = _selectedAvatar == avatarUrl;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedAvatar = avatarUrl),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
                            width: 3,
                          ),
                        ),
                        child: avatarUrl.isEmpty
                            ? CircleAvatar(
                                radius: 26,
                                backgroundColor: Colors.grey[300],
                                child: const Icon(Icons.person, color: Colors.grey, size: 30),
                              )
                            : CircleAvatar(
                                radius: 26,
                                backgroundImage: NetworkImage(avatarUrl),
                              ),
                      ),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 24),
            Text(
              user.username,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              user.email,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 32),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('About Me', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 8),
            _isEditing
                ? TextField(
                    controller: _descController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Write something about yourself...',
                      border: OutlineInputBorder(),
                    ),
                  )
                : Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      user.description.isNotEmpty ? user.description : 'No description provided.',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
