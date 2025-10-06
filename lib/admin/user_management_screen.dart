import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:venus_assistant_app/main.dart'; // Make sure this import points to your UserModel

class AdminUserManagementScreen extends StatefulWidget {
  const AdminUserManagementScreen({super.key});

  @override
  State<AdminUserManagementScreen> createState() =>
      _AdminUserManagementScreenState();
}

class _AdminUserManagementScreenState extends State<AdminUserManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة المستخدمين'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          // ===== MODIFICATION START =====
          // This is where the colors were changed to white
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          // ===== MODIFICATION END =====
          tabs: const [
            Tab(text: 'طلبات معلقة'),
            Tab(text: 'المستخدمون الحاليون'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildUsersList(isPending: true),
          _buildUsersList(isPending: false),
        ],
      ),
    );
  }

  Widget _buildUsersList({required bool isPending}) {
    Query query = FirebaseFirestore.instance
        .collection('users')
        .where('status', isEqualTo: isPending ? 'pending' : 'approved');

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('حدث خطأ: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
              child: Text(isPending
                  ? 'لا توجد طلبات معلقة'
                  : 'لا يوجد مستخدمون حاليون'));
        }

        final users = snapshot.data!.docs;

        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final userDoc = users[index];
            final data = userDoc.data() as Map<String, dynamic>;
            final portId = data['portId'] ?? 'غير محدد';
            final code = data['code'] ?? 'غير محدد';
            final role = data['role'] ?? 'غير محدد';

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: ListTile(
                title: Text(data['name'] ?? 'No Name'),
                subtitle:
                    Text('الوظيفة: $role\nالكود: $code\nرقم المنفذ: $portId'),
                isThreeLine: true,
                trailing: isPending
                    ? _buildPendingActions(userDoc.id)
                    : _buildApprovedActions(userDoc),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPendingActions(String userId) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.check_circle, color: Colors.green),
          tooltip: 'موافقة',
          onPressed: () => _updateUserStatus(userId, 'approved'),
        ),
        IconButton(
          icon: const Icon(Icons.cancel, color: Colors.red),
          tooltip: 'رفض',
          onPressed: () => _deleteUser(userId),
        ),
      ],
    );
  }

  Widget _buildApprovedActions(DocumentSnapshot userDoc) {
    return IconButton(
      icon: const Icon(Icons.edit, color: Colors.blue),
      tooltip: 'تعديل',
      onPressed: () => _showEditUserDialog(context, userDoc),
    );
  }

  void _updateUserStatus(String userId, String status) {
    FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .update({'status': status}).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تحديث حالة المستخدم بنجاح.')));
    });
  }

  void _deleteUser(String userId) {
    FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .delete()
        .then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حذف المستخدم بنجاح.')));
    });
  }

  void _showEditUserDialog(BuildContext context, DocumentSnapshot userDoc) {
    final data = userDoc.data() as Map<String, dynamic>;
    final nameController = TextEditingController(text: data['name']);
    final codeController = TextEditingController(text: data['code']);
    final portIdController = TextEditingController(text: data['portId']);
    String selectedRole = data['role'];
    final roles = ['مندوب', 'مشرف', 'مدير', 'Admin'];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('تعديل بيانات ${data['name']}'),
          content: SingleChildScrollView(
            child: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'الاسم'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: codeController,
                      decoration: const InputDecoration(labelText: 'الكود'),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: selectedRole,
                      decoration: const InputDecoration(labelText: 'الوظيفة'),
                      items: roles.map((String role) {
                        return DropdownMenuItem<String>(
                          value: role,
                          child: Text(role),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() {
                          selectedRole = newValue!;
                        });
                      },
                    ),
                    if (selectedRole == 'مندوب') ...[
                      const SizedBox(height: 8),
                      TextField(
                        controller: portIdController,
                        decoration:
                            const InputDecoration(labelText: 'رقم المنفذ'),
                        keyboardType: TextInputType.number,
                      ),
                    ]
                  ],
                );
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('إلغاء'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: const Text('حفظ التعديلات'),
              onPressed: () {
                Map<String, dynamic> updatedData = {
                  'name': nameController.text.trim(),
                  'code': codeController.text.trim(),
                  'role': selectedRole,
                };

                if (selectedRole == 'مندوب') {
                  updatedData['portId'] = portIdController.text.trim();
                } else {
                  // If role is not delegate, remove the portId field
                  updatedData['portId'] = FieldValue.delete();
                }

                userDoc.reference.update(updatedData).then((_) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('تم تحديث بيانات المستخدم بنجاح.')));
                });
              },
            ),
          ],
        );
      },
    );
  }
}
