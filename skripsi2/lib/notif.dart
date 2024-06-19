import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class notifScreen extends StatefulWidget {
  final String id;
  const notifScreen({required this.id, super.key});

  @override
  notifScreenState createState() => notifScreenState(id: id);
}

class notifScreenState extends State<notifScreen> {
  final String id;
  notifScreenState({required this.id, Key? key});
  List<Map<String, dynamic>>? notifications;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    await getNotif();
  }

  Future<void> getNotif() async {
    final response = await http.post(
      Uri.parse('http://172.22.74.201/getNotif.php'),
      body: {'id': id},
    );
    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      if (jsonData['success']) {
        List<dynamic> data = jsonData['data'];
        data.sort((a, b) => a['tanggal'].compareTo(b['tanggal']));
        setState(() {
          notifications = data.cast<Map<String, dynamic>>();
        });
      } else {
        // print(jsonData['message']);
      }
    } else {
      // print('Failed to fetch data. Status code: ${response.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Notifications',
            style: TextStyle(color: Colors.black),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: notifications != null
          ? PopScope(
              canPop: false,
              onPopInvoked: (bool didPop) async {
                if (didPop) {
                  return;
                }
                Navigator.pop(context);
              },
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                itemCount: notifications!.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final notification = notifications![index];
                  final date = DateTime.parse(notification['tanggal']);
                  final formattedDate =
                      '${date.day}/${date.month}/${date.year}';
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: ListTile(
                      title: Text(
                        notification['notif'],
                        style: const TextStyle(color: Colors.black),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          formattedDate,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                  );
                },
              ),
            )
          : const Center(
              child: Text('Tidak ada notif'),
            ),
    );
  }
}
