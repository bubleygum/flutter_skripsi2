import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:skripsi2/home.dart';
import 'package:skripsi2/marketplace.dart';

class pengajuanScreen extends StatefulWidget {
  final String id;

  pengajuanScreen({required this.id, super.key});

  @override
  pengajuanScreenState createState() => pengajuanScreenState(id: id);
}

class pengajuanScreenState extends State<pengajuanScreen> {
  final String id;

  pengajuanScreenState({required this.id, Key? key});
  final TextEditingController jumlahPengajuan = TextEditingController();
  final TextEditingController lamaCicilan = TextEditingController();
  final TextEditingController jumlahCont = TextEditingController();
  int _currentIndex = 2;
  double totalBunga = 0;
  double angsuranBunga = 0;
  int selectedJangkaWaktu = 1;
  @override
  void initState() {
    super.initState();
    loadData();
  }

  List<Map<String, dynamic>>? userData;

  Future<void> loadData() async {
    await getUserData();
    await getIuran();
    await getMaxLama();
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

  double iuran = 0;

  Future<void> getIuran() async {
    final response = await http.post(
      Uri.parse('http://192.168.1.75/iuran.php'),
    );

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      if (jsonData['success']) {
        final iuranValue = double.tryParse(jsonData['data']['iuran']) ?? 0.0;
        setState(() {
          iuran = iuranValue;
        });
      } 
      // else {
      //   print(jsonData['message']);
      // }
    } 
    // else {
    //   print('Failed to fetch data. Status code: ${response.statusCode}');
    // }
  }

  int maxLamaCicilan = 0;

  Future<void> getMaxLama() async {
    var url = Uri.parse('http://192.168.1.75/pengajuan.php');
    var response = await http.post(url, body: {
      'req': 'getMaxLama',
    });

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      if (jsonData['success']) {
        if (jsonData['data']['maxLamaCicilan'] != null) {
          final maxLamaCicilanVal = jsonData['data']['maxLamaCicilan'];
          setState(() {
            maxLamaCicilan = int.parse(maxLamaCicilanVal.toString());
          });
        } else {
          // print('maxLamaCicilanVal is null');
        }
      } 
      // else {
      //   print(jsonData['message']);
      // }
    } 
    // else {
    //   print('Failed to fetch data. Status code: ${response.statusCode}');
    // }
  }

  double cicilanPokok = 0;
  double bungaCicilan = 0;
  double totalPinjaman = 0;
  List<Map<String, dynamic>> angsuranDetails = [];
  void simulasi() {
    angsuranDetails.clear();
    double jumlahPinjaman =
        int.tryParse(jumlahCont.text.toString())?.toDouble() ?? 0.0;
    int jangkaWaktu = selectedJangkaWaktu;
    double angsuranPokok = jumlahPinjaman.toDouble() / jangkaWaktu;
    double totalAngsuran = 0;
    double bunga = jumlahPinjaman * (iuran / 100);
    for (int i = 1; i <= jangkaWaktu; i++) {
      double angsuranBulanan = angsuranPokok + bunga;
      totalBunga += bunga;
      totalAngsuran += angsuranBulanan;
      jumlahPinjaman -= angsuranPokok;

      angsuranDetails.add({
        'bulan': i,
        'totalAngsuran': totalAngsuran,
        'angsuranBunga': bunga,
        'angsuranPokok': angsuranPokok,
        'saldoPinjaman': jumlahPinjaman.toDouble()
      });
    }

    setState(() {
      cicilanPokok = angsuranPokok;
      bungaCicilan = totalBunga;
      totalPinjaman = totalAngsuran;
      angsuranBunga = totalBunga;
    });
  }

  final String pdfUrl =
      'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf';

  void downloadPDF() async {
    final uri = Uri.parse(pdfUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      // print('Could not launch $pdfUrl');
    }
  }

  Future<void> uploadImageToServer(
      Uint8List? bytes, BuildContext context) async {
    if (bytes == null) {
      return;
    }
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('http://192.168.1.75/pengajuan.php'),
    );
    request.fields['req'] = "upload";
    request.fields['idAnggota'] = id;
    request.fields['nama'] = userData?[0]['nama'];
    request.fields['jumlahPengajuan'] = jumlahCont.text;
    request.fields['bunga'] = angsuranBunga.toString();
    request.fields['lamaPinjaman'] = selectedJangkaWaktu.toString();
    request.files.add(http.MultipartFile.fromBytes(
      'image',
      bytes,
      filename: 'image.jpg',
    ));

    var response = await request.send();

    if (response.statusCode == 200) {
      var responseBody = await response.stream.bytesToString();
      var jsonResponse = json.decode(responseBody);

      if (jsonResponse['success']) {
        await sendEmailNotification();
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Success'),
              content: const Text('Pengajuan berhasil'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      } else {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Error'),
              content: Text(
                  'Failed to upload image. Error: ${jsonResponse['message']}'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      }
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Error'),
            content:
                Text('Failed to upload image. Error: ${response.reasonPhrase}'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> uploadButtonPressed() async {
    FilePickerResult? result =
        await FilePicker.platform.pickFiles(type: FileType.image);

    if (result != null && result.files.isNotEmpty) {
      var platformFile = result.files.first;
      Uint8List? bytes;

      if (kIsWeb) {
        setState(() {
          bytes = platformFile.bytes;
        });
      } else {
        File file = File(platformFile.path ?? '');
        setState(() {
          bytes = file.readAsBytesSync();
        });
      }

      await uploadImageToServer(bytes, context);
    }
  }

  Future<void> sendEmailNotification() async {
    const String apiUrl = 'http://192.168.1.75/sendEmail.php';

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );
    } catch (e) {
      // print('Error sending email: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: Colors.black,
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Pengajuan',
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                downloadPDF();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                minimumSize: const Size(double.infinity, 40),
              ),
              child: const Text(
                'Download Formulir Pengajuan',
                style: TextStyle(fontSize: 15, color: Colors.white),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Pengajuan',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: jumlahCont,
              style: const TextStyle(fontSize: 15, height: 1.5),
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly
              ],
              decoration: InputDecoration(
                hintText: 'Jumlah Pinjaman',
                hintStyle: const TextStyle(fontSize: 15),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              ),
              onChanged: (value) {
                simulasi();
              },
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<int>(
              value: selectedJangkaWaktu,
              onChanged: (int? newValue) {
                setState(() {
                  selectedJangkaWaktu = newValue!;
                  simulasi();
                });
              },
              items: List.generate(maxLamaCicilan, (index) => index + 1)
                  .map<DropdownMenuItem<int>>((int value) {
                return DropdownMenuItem<int>(
                  value: value,
                  child: Text('$value bulan'),
                );
              }).toList(),
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Bunga saat ini: $iuran%',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: angsuranDetails.map((detail) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Angsuran ke-${detail['bulan']}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Total Angsuran: Rp. ${detail['totalAngsuran'].toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 14),
                    ),
                    Text(
                      'Angsuran Bunga: Rp. ${detail['angsuranBunga'].toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 14),
                    ),
                    Text(
                      'Angsuran Pokok: Rp. ${detail['angsuranPokok'].toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 14),
                    ),
                    Text(
                      'Saldo Pinjaman: Rp. ${detail['saldoPinjaman'].toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 10),
                  ],
                );
              }).toList(),
            ),
            ElevatedButton(
              onPressed: () {
                if (jumlahCont.text.isEmpty) {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Error'),
                        content: const Text(
                            'Tidak dapat mengupload formulir, isi data terlebih dahulu'),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: const Text('OK'),
                          ),
                        ],
                      );
                    },
                  );
                  return;
                } else {
                  uploadButtonPressed();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                minimumSize: const Size(double.infinity, 40),
              ),
              child: const Text(
                'Upload Formulir Pengajuan',
                style: TextStyle(fontSize: 15, color: Colors.white),
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
