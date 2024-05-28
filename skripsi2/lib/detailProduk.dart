import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:carousel_slider/carousel_slider.dart';

class prodDetailScreen extends StatefulWidget {
  final String id;
  final String idProduk;
  const prodDetailScreen({required this.id, required this.idProduk, super.key});

  @override
  prodDetailScreenState createState() =>
      prodDetailScreenState(id: id, idProduk: idProduk);
}

class prodDetailScreenState extends State<prodDetailScreen> {
  final String id;
  final String idProduk;
  prodDetailScreenState({required this.id, required this.idProduk, Key? key});

  List<Map<String, dynamic>>? userData;
  List<Map<String, dynamic>>? productsData;
  List<Map<String, dynamic>> angsuranDetails = [];
  double angsuranBunga = 0;
  String? selectedCategory;
  int selectedJangkaWaktu = 1;
  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    await getUserData();
    await getProdData();
    await getIuran();
    await getMaxLama();
  }

  Future<void> getUserData() async {
    if (id.isEmpty) {
      // print('Here Error: No id parameter provided.');
      return;
    }
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
      } else {
        // print(jsonData['message']);
      }
    }
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
            // print(maxLamaCicilan);
          });
        } else {
          // print('maxLamaCicilanVal is null');
        }
      } else {
        // print(jsonData['message']);
      }
    } else {
      // print('Failed to fetch data. Status code: ${response.statusCode}');
    }
  }

  Future<void> getProdData() async {
    // print("here");
    final response = await http.post(
      Uri.parse('http://192.168.1.75/getProducts.php'),
      body: {'idProduk': idProduk},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success']) {
        setState(() {
          productsData =
              (data['data'] as List<dynamic>).cast<Map<String, dynamic>>();
        });
        if (productsData!.isNotEmpty) {
          final product = productsData![0];
          hitungCicilan(product['harga']);
        }
        // print(productsData);
      } else {
        // print(data['message']);
      }
    } else {
      // print('Failed to load products by data');
    }
  }

  Future<void> beliBarang(
      String nama, int jangkaWaktu, String namaProduk, String harga) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Purchase'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Installment Months: $jangkaWaktu'),
              Text('Product Price: Rp. $harga'),
              Text('Total Bunga: Rp. ${angsuranBunga.toStringAsFixed(2)}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                final response = await http.post(
                  Uri.parse('http://192.168.1.75/pengajuan.php'),
                  body: {
                    'req': "market",
                    'idAnggota': id,
                    'idProduk': idProduk,
                    'namaProduk': namaProduk,
                    'nama': nama,
                    'jumlahPengajuan': harga.toString(),
                    'lamaPinjaman': jangkaWaktu.toString(),
                    'bunga': angsuranBunga.toString()
                  },
                );

                if (response.statusCode == 200) {
                  final data = jsonDecode(response.body);
                  if (data['success']) {
                    sendEmailNotification();
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Success'),
                          content: const Text('Pengajuan Pembelian Berhasil'),
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
                    if (data['message'] ==
                        'Pengajuan gagal, hanya bisa mengajukan 1 pengajuan.') {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Gagal'),
                            content: Text(data['message']),
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
                } else {
                  // print('Failed');
                }
              },
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );
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
          // print(iuran);
        });
      } else {
        // print(jsonData['message']);
      }
    } else {
      // print('Failed to fetch data. Status code: ${response.statusCode}');
    }
  }

  final TextEditingController jumlahCont = TextEditingController();
  double cicilanPokok = 0;
  double bungaCicilan = 0;
  double totalPinjaman = 0;
  void hitungCicilan(String harga) {
    angsuranDetails.clear();
    double jumlahPinjaman = int.tryParse(harga)?.toDouble() ?? 0.0;
    int jangkaWaktu = selectedJangkaWaktu;
    double angsuranPokok = jumlahPinjaman.toDouble() / jangkaWaktu;
    double totalAngsuran = 0;
    double totalBunga = 0;
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

  Future<void> sendEmailNotification() async {
    const String apiUrl = 'http://192.168.1.75/sendEmail.php';

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      if (response.statusCode == 200) {
        // print('Email sent successfully');
      } else {
        // print('Failed to send email. Status code: ${response.statusCode}');
      }
    } catch (e) {
      // print('Error sending email: $e');
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
          'Marketplace',
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: productsData == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(8.0), 
              child: ListView.builder(
                itemCount: productsData!.length,
                itemBuilder: (context, index) {
                  final product = productsData![index];
                  List<String> imgNames =
                      (product['imgNames'] as List<dynamic>).cast<String>();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CarouselSlider(
                        options: CarouselOptions(
                          aspectRatio: 16 / 9,
                          enlargeCenterPage: true,
                          autoPlay: true,
                          enableInfiniteScroll: true,
                        ),
                        items: imgNames.map<Widget>((imgName) {
                              return Container(
                                margin: const EdgeInsets.all(5.0),
                                child: Image.memory(
                                  base64Decode(imgName),
                                  height: 100,
                                  fit: BoxFit.cover,
                                ),
                              );
                            }).toList(),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 8.0), 
                        child: Text(
                          product['namaProduk'],
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 8.0), 
                        child: Text(
                          'Harga: ${formatAmount(product['harga'])}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(5.0),
                        child: DropdownButtonFormField<int>(
                          value: selectedJangkaWaktu,
                          onChanged: (int? newValue) {
                            setState(() {
                              selectedJangkaWaktu = newValue!;
                              hitungCicilan(product['harga']);
                            });
                          },
                          items: List.generate(
                                  maxLamaCicilan, (index) => index + 1)
                              .map<DropdownMenuItem<int>>((int value) {
                            return DropdownMenuItem<int>(
                              value: value,
                              child: Text('$value bulan'),
                            );
                          }).toList(),
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderSide: const BorderSide(color: Colors.black),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 12),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Simulasi Pembayaran:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 10),
                            for (var detail in angsuranDetails)
                              Column(
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
                                    'Total Angsuran: ${formatAmount(detail['totalAngsuran'])}',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  Text(
                                    'Angsuran Bunga:${formatAmount(detail['angsuranBunga'])}',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  Text(
                                    'Angsuran Pokok: ${formatAmount(detail['angsuranPokok'])}',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  Text(
                                    'Saldo Pinjaman: ${formatAmount(detail['saldoPinjaman'])}',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  const SizedBox(height: 5),
                                ],
                              ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 8.0),
                        child: ElevatedButton(
                          onPressed: () {
                            if (userData != null &&
                                userData!.isNotEmpty &&
                                userData![0]['nama'] != null) {
                              String nama = userData![0]['nama'].toString();
                              int jangkaWaktu = selectedJangkaWaktu;
                              beliBarang(nama, jangkaWaktu,
                                  product['namaProduk'], product['harga']);
                            } else {
                              // print('Error: User data is null or empty.');
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            minimumSize: const Size(double.infinity, 40),
                          ),
                          child: const Text('Buy Now',style: TextStyle(fontSize: 15,color: Colors.white),),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
    );
  }
}
