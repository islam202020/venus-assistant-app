import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Screen 1: Shows a list of sectors as cards
class DataManagementScreen extends StatelessWidget {
  const DataManagementScreen({super.key});

  void _showSectorDialog(BuildContext context, {DocumentSnapshot? sectorDoc}) {
    final nameController =
        TextEditingController(text: sectorDoc != null ? sectorDoc['name'] : '');
    final managerController = TextEditingController(
        text: sectorDoc != null ? sectorDoc['managerName'] : '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(sectorDoc == null ? 'إضافة قطاع' : 'تعديل قطاع'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'اسم القطاع')),
            TextField(
                controller: managerController,
                decoration:
                    const InputDecoration(labelText: 'اسم مدير القطاع')),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty &&
                  managerController.text.isNotEmpty) {
                final data = {
                  'name': nameController.text,
                  'managerName': managerController.text,
                };
                if (sectorDoc == null) {
                  FirebaseFirestore.instance.collection('sectors').add(data);
                } else {
                  sectorDoc.reference.update(data);
                }
                Navigator.of(context).pop();
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة القطاعات'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('sectors')
            .orderBy('name')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('لا توجد قطاعات. اضغط على زر (+) للبدء.'),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final sectorDoc = snapshot.data!.docs[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  leading: const Icon(Icons.business_center,
                      color: Colors.indigo, size: 40),
                  title: Text(sectorDoc['name'],
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('المدير: ${sectorDoc['managerName']}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () =>
                            _showSectorDialog(context, sectorDoc: sectorDoc),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => sectorDoc.reference.delete(),
                      ),
                    ],
                  ),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => SectorDetailScreen(sectorDoc: sectorDoc),
                  )),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showSectorDialog(context),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}

// Screen 2: Shows the details of a single sector
class SectorDetailScreen extends StatelessWidget {
  final DocumentSnapshot sectorDoc;
  const SectorDetailScreen({super.key, required this.sectorDoc});

  void _showSupervisorDialog(BuildContext context,
      {DocumentSnapshot? supervisorDoc}) {
    final nameController = TextEditingController(
        text: supervisorDoc != null ? supervisorDoc['name'] : '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(supervisorDoc == null ? 'إضافة مشرف' : 'تعديل مشرف'),
        content: TextField(
            controller: nameController,
            decoration: const InputDecoration(labelText: 'اسم المشرف')),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                final data = {'name': nameController.text};
                if (supervisorDoc == null) {
                  FirebaseFirestore.instance.collection('supervisors').add({
                    ...data,
                    'sectorId': sectorDoc.id,
                  });
                } else {
                  supervisorDoc.reference.update(data);
                }
                Navigator.of(context).pop();
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('قطاع: ${sectorDoc['name']}'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('مدير القطاع: ${sectorDoc['managerName']}',
                style: Theme.of(context).textTheme.titleLarge),
            const Divider(height: 30),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('supervisors')
                  .where('sectorId', isEqualTo: sectorDoc.id)
                  .orderBy('name')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...snapshot.data!.docs.map((supervisorDoc) {
                      return SupervisorOutletsCard(
                          supervisorDoc: supervisorDoc);
                    }).toList(),
                    const SizedBox(height: 20),
                    Center(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('إضافة مشرف جديد'),
                        onPressed: () => _showSupervisorDialog(context),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// Widget to display a supervisor and their outlets
class SupervisorOutletsCard extends StatelessWidget {
  final DocumentSnapshot supervisorDoc;
  const SupervisorOutletsCard({super.key, required this.supervisorDoc});

  void _showOutletDialog(BuildContext context, {DocumentSnapshot? outletDoc}) {
    final numberController = TextEditingController(
        text: outletDoc != null ? outletDoc['number'] : '');
    final phoneController = TextEditingController(
        text: outletDoc != null ? outletDoc['phone'] : '');
    final addressController = TextEditingController(
        text: outletDoc != null ? outletDoc['address'] : '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(outletDoc == null ? 'إضافة منفذ' : 'تعديل منفذ'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: numberController,
                  decoration: const InputDecoration(labelText: 'رقم المنفذ'),
                  keyboardType: TextInputType.number),
              TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'رقم الهاتف'),
                  keyboardType: TextInputType.phone),
              TextField(
                  controller: addressController,
                  decoration: const InputDecoration(labelText: 'العنوان')),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              if (numberController.text.isNotEmpty) {
                final data = {
                  'number': numberController.text,
                  'phone': phoneController.text,
                  'address': addressController.text,
                };
                if (outletDoc == null) {
                  FirebaseFirestore.instance.collection('outlets').add({
                    ...data,
                    'supervisorId': supervisorDoc.id,
                    'sectorId': supervisorDoc['sectorId'],
                  });
                } else {
                  outletDoc.reference.update(data);
                }
                Navigator.of(context).pop();
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _editSupervisor(BuildContext context) {
    // Re-uses the dialog logic from the parent screen for simplicity
    SectorDetailScreen(sectorDoc: supervisorDoc)
        ._showSupervisorDialog(context, supervisorDoc: supervisorDoc);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.person, color: Colors.orange, size: 30),
              title: Text('المشرف: ${supervisorDoc['name']}',
                  style: Theme.of(context).textTheme.titleMedium),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _editSupervisor(context)),
                  IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => supervisorDoc.reference.delete()),
                ],
              ),
            ),
            const Divider(),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('outlets')
                  .where('supervisorId', isEqualTo: supervisorDoc.id)
                  .snapshots(),
              builder: (context, outletSnapshot) {
                if (!outletSnapshot.hasData) return const SizedBox.shrink();

                final docs = outletSnapshot.data!.docs;
                docs.sort((a, b) {
                  int numA =
                      int.tryParse((a.data() as Map)['number'] ?? '0') ?? 0;
                  int numB =
                      int.tryParse((b.data() as Map)['number'] ?? '0') ?? 0;
                  return numA.compareTo(numB);
                });

                return Column(
                  children: [
                    ...docs.map((outletDoc) {
                      return ListTile(
                        leading: CircleAvatar(child: Text(outletDoc['number'])),
                        title: Text('هاتف: ${outletDoc['phone']}'),
                        subtitle: Text(outletDoc['address']),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit, size: 20),
                          onPressed: () =>
                              _showOutletDialog(context, outletDoc: outletDoc),
                        ),
                      );
                    }).toList(),
                    TextButton.icon(
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('إضافة منفذ'),
                      onPressed: () => _showOutletDialog(context),
                    )
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
