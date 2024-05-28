import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:skripsi2/marketplace.dart';
import 'package:skripsi2/notif.dart';
import 'package:skripsi2/pengajuan.dart';
import 'auth_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'login.dart';

class homeScreen extends StatefulWidget {
  final String id;
  const homeScreen({required this.id, super.key});

  @override
  homeScreenState createState() => homeScreenState(id: id);
}

class homeScreenState extends State<homeScreen> {
  final String id;
  homeScreenState({required this.id, Key? key});
  int _currentIndex = 0;
  @override
  void initState() {
    super.initState();
    loadData();
  }

  List<Map<String, dynamic>>? userData;
  Map<String, dynamic>? userPengajuan;
  Future<void> loadData() async {
    await getUserData();
    await getPengajuan();
  }

  Future<void> getUserData() async {
    final response = await http.post(
        Uri.parse('http://192.168.1.75/getDataAnggota.php'),
        body: {'id': id});
    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      if (jsonData['success']) {
        setState(() {
          userData =
              (jsonData['data'] as List<dynamic>).cast<Map<String, dynamic>>();
        });
      }
    }
  }

  Future<void> getPengajuan() async {
    final response = await http.post(
        Uri.parse('http://192.168.1.75/getPengajuan.php'),
        body: {'id': id});
    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      if (jsonData['success']) {
        setState(() {
          userPengajuan = jsonData['data'];
        });
      }
    }
  }

  Future<void> logout(BuildContext context) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    bool confirmLogout = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); 
              },
              child: const Text('Yes'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('No'),
            ),
          ],
        );
      },
    );

    if (confirmLogout) {
      await prefs.setBool('isLoggedIn', false);
      await prefs.remove('idAnggota');
      await prefs.remove('email');
      BlocProvider.of<AuthBloc>(context).add(AuthEvent.logout);
      Navigator.of(context)
          .pushReplacement(MaterialPageRoute(builder: (context) => const login()));
    }
  }

  String formatAmount(dynamic amount) {
    if (amount is String) {
      amount = double.tryParse(amount);
    }
    if (amount != null) {
      String formattedAmount = amount.toStringAsFixed(2);
      List<String> parts = formattedAmount.split('.');
      String integerPart = parts[0];
      String fractionalPart = parts.length > 1 ? '.${parts[1]}' : '';
      String formattedIntegerPart = '';
      for (int i = integerPart.length - 1; i >= 0; i--) {
        formattedIntegerPart = integerPart[i] + formattedIntegerPart;
        if ((integerPart.length - i) % 3 == 0 && i != 0) {
          formattedIntegerPart = '.$formattedIntegerPart';
        }
      }
      return 'Rp.$formattedIntegerPart${fractionalPart == '.00' ? '' : fractionalPart}';
    } else {
      return 'Tidak ada pengajuan aktif';
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double boxWidth = screenWidth - 10;
    String userName = (userData != null && userData!.isNotEmpty)
        ? userData![0]['nama']
        : 'Loading...';
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            userName,
            style: const TextStyle(color: Colors.black),
          ),
        ),
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: const FaIcon(FontAwesomeIcons.rightFromBracket),
              color: Colors.black,
              onPressed: () {
                logout(context);
              },
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            color: Colors.black,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => notifScreen(
                          id: id,
                        )),
              );
            },
          ),
        ],
      ),
      body: userData != null && userPengajuan != null
          ? SingleChildScrollView(
              child: Column(
                children: [
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        'DATA PINJAMAN',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.topCenter,
                    child: Container(
                      width: boxWidth,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  formatAmount(
                                    userPengajuan?['jumlahPengajuan'] ??
                                        'Tidak ada pengajuan aktif',
                                  ),
                                  style: const TextStyle(
                                    fontSize: 30,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${userPengajuan?['tglPinjaman'] ?? 'Tidak ada pengajuan aktif'}',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    color: Colors.white,
                                    fontWeight: FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text.rich(
                              TextSpan(
                                children: <TextSpan>[
                                  const TextSpan(
                                    text: 'Total Pinjaman: ',
                                    style: TextStyle(
                                      fontWeight: FontWeight.normal,
                                      color: Colors.white,
                                      fontSize: 15,
                                    ),
                                  ),
                                  TextSpan(
                                    text: (userPengajuan != null &&
                                            userPengajuan!['lamaPinjaman'] !=
                                                null &&
                                            userPengajuan!['bunga'] != null)
                                        ? formatAmount(double.parse(userPengajuan!['jumlahPengajuan']) + (double.parse(userPengajuan!['bunga'])))
                                        : 'Tidak ada pengajuan aktif',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      color: Colors.white,
                                      fontWeight: FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text.rich(
                              TextSpan(
                                children: <TextSpan>[
                                  const TextSpan(
                                    text: 'Jumlah Cicilan: ',
                                    style: TextStyle(
                                      fontWeight: FontWeight.normal,
                                      color: Colors.white,
                                      fontSize: 15,
                                    ),
                                  ),
                                  TextSpan(
                                    text:
                                        '${userPengajuan?['lamaPinjaman'] + " (Cicilan:${formatAmount((double.parse(userPengajuan!['jumlahPengajuan']) + (double.parse(userPengajuan!['bunga']))) / 12)})" ?? 'Tidak ada pengajuan aktif'}',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      color: Colors.white,
                                      fontWeight: FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.yellow[50],
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 8, horizontal: 12),
                              child: Center(
                                child: Text(
                                  'Sisa Cicilan: ${(userPengajuan != null &&
                                              userPengajuan!['lamaPinjaman'] !=
                                                  null &&
                                              userPengajuan!['pembayaran'] !=
                                                  null)
                                          ? '${(int.parse(userPengajuan!['lamaPinjaman']) - (userPengajuan!['pembayaran'] as List).length)}x: ${formatAmount(userPengajuan?["sisa"])}'
                                          : 'Tidak ada pengajuan aktif'}',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    color: Colors.black,
                                    fontWeight: FontWeight.normal,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        'Pembayaran Cicilan',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: boxWidth,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (userPengajuan != null)
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount:
                                  int.parse(userPengajuan!['lamaPinjaman']),
                              itemBuilder: (context, index) {
                                var pembayaran = userPengajuan!['pembayaran'];
                                var cicilanData = pembayaran.length > index
                                    ? pembayaran[index]
                                    : null;

                                Color cicilanColor = cicilanData != null
                                    ? Colors.green
                                    : Colors.black;

                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 4.0),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Align(
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            'Cicilan ${index + 1}',
                                            style: TextStyle(
                                              fontWeight: FontWeight.normal,
                                              color:
                                                  cicilanColor,
                                              fontSize: 15,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Align(
                                          alignment: Alignment.center,
                                          child: Text(
                                            cicilanData != null
                                                ? formatAmount(
                                                    cicilanData['cicilan'])
                                                : '',
                                            style: const TextStyle(
                                              fontSize: 15,
                                              color: Colors.black,
                                              fontWeight: FontWeight.normal,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Align(
                                          alignment: Alignment.centerRight,
                                          child: Text(
                                            cicilanData != null
                                                ? cicilanData['tglPembayaran']
                                                : '',
                                            style: const TextStyle(
                                              fontSize: 15,
                                              color: Colors.black,
                                              fontWeight: FontWeight.normal,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            )
                          else
                            const Text(
                              'Data pembayaran tidak tersedia',
                              style: TextStyle(color: Colors.black),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        'DATA PINJAMAN',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.topCenter,
                    child: Container(
                      width: boxWidth,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Tidak ada pinjaman',
                                  style: TextStyle(
                                    fontSize: 30,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 10),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        'Pembayaran Cicilan',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: boxWidth,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Data pembayaran tidak tersedia',
                            style: TextStyle(color: Colors.black),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });

          if (index == 0) {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => homeScreen(
                        id: id,
                      )),
            );
          } else if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => marketplaceScreen(
                        id: id,
                      )),
            );
          } else if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => pengajuanScreen(
                        id: id,
                      )),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.store),
            label: 'Marketplace',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.attach_money),
            label: 'Pengajuan',
          ),
        ],
        selectedItemColor: Colors.green,
      ),
    );
  }
}
