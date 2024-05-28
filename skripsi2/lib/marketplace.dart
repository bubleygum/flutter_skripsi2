import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:skripsi2/detailProduk.dart';
import 'package:skripsi2/home.dart';
import 'package:skripsi2/pengajuan.dart';

class marketplaceScreen extends StatefulWidget {
  final String id;

  marketplaceScreen({required this.id, super.key});

  @override
  marketplaceScreenState createState() => marketplaceScreenState(id: id);
}

class marketplaceScreenState extends State<marketplaceScreen> {
  final String id;

  marketplaceScreenState({required this.id, Key? key});

  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>>? userData;
  List<Map<String, dynamic>>? productsData;
  String? selectedCategory;
  bool isAscending = true;
  bool isLoading = false;
  double iuran = 0;
  String? errorMessage;
  int _currentIndex = 1;
  @override
  void initState() {
    super.initState();
    isLoading = true;
    loadData().then((_) {
      setState(() {
        isLoading = false;
      });
    });
  }

  Future<void> loadData() async {
    await getUserData();
    await getProductsData();
    await getIuran();
  }

  Future<void> getUserData() async {
    // if (id.isEmpty) {
    //   print('Here Error: No id parameter provided.');
    //   return;
    // }
    // print("id" + id);
    final response = await http.post(
        Uri.parse('http://192.168.1.75/getDataAnggota.php'),
        body: {'id': id});
    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      if (jsonData['success']) {
        setState(() {
          userData =
              (jsonData['data'] as List<dynamic>).cast<Map<String, dynamic>>();
          // print(userData);
        });
      } else {
        // print(jsonData['message']);
      }
    }
  }

  Future<List<Map<String, dynamic>>> fetchCategories() async {
    final response =
        await http.get(Uri.parse('http://192.168.1.75/getCategories.php'));
    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      if (jsonData['success']) {
        final categories =
            (jsonData['data'] as List<dynamic>).cast<Map<String, dynamic>>();
        categories.insert(0, {'idKategori': '', 'kategori': 'All'});
        return categories;
      } else {
        // print(jsonData['message']);
        return [];
      }
    } else {
      throw Exception('Failed to load categories');
    }
  }

  Future<void> getProductsData() async {
    final response =
        await http.get(Uri.parse('http://192.168.1.75/getProducts.php'));
    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      if (jsonData['success']) {
        setState(() {
          productsData =
              (jsonData['data'] as List<dynamic>).cast<Map<String, dynamic>>();
          // print(productsData);
        });
      } else {
        // print(jsonData['message']);
      }
    }
  }

  Future<List<Map<String, dynamic>>> getProductFromCategory(
      String idKategori) async {
    try {
      final response = await http.post(
        Uri.parse('http://192.168.1.75/getCategories.php'),
        body: {'idKategori': idKategori},
      );
      if (response.statusCode == 200) {
        final responseBody = response.body;
        final data = jsonDecode(responseBody);
        if (data['success']) {
          if (data['data'] is List<dynamic>) {
            List<Map<String, dynamic>> productsData =
                List<Map<String, dynamic>>.from(data['data']);
            // print('Products data: $productsData');
            return productsData;
          } else {
            // print('Data is not a list: $data');
          }
        } else {
          // print('Success key is not set to true: $data');
        }
      } else {
        // print('Response status code is not 200: ${response.statusCode}');
      }
    } catch (e) {
      // print('Error: $e');
    }
    throw Exception('Failed to load products by category');
  }

  List<Map<String, dynamic>> getSearchedProducts() {
    final keyword = _searchController.text.toLowerCase();
    if (keyword.isNotEmpty) {
      return productsData!
          .where((product) =>
              product['namaProduk'].toLowerCase().contains(keyword))
          .toList();
    } else {
      return productsData!;
    }
  }

  Future<void> showCategoryDialog() async {
    final categories = await fetchCategories();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Category'),
          content: SingleChildScrollView(
            child: Column(
              children: categories.map((category) {
                return ListTile(
                  title: Text(category['kategori']),
                  onTap: () async {
                    setState(() {
                      selectedCategory = category['idKategori'];
                    });
                    // print('Chosen category: ${category['idKategori']}');
                    if (category['idKategori'] == '') {
                      // Show all products when "All" category is selected
                      getProductsData();
                      errorMessage = null;
                    } else {
                      final String categoryId = category['idKategori'];
                      // print(categoryId);
                      try {
                        final products =
                            await getProductFromCategory(categoryId);
                        if (products.isEmpty) {
                          setState(() {
                            productsData = [];
                            errorMessage = 'no product in this category';
                          });
                        } else {
                          setState(() {
                            productsData = products;
                            errorMessage = null;
                          });
                        }
                      } catch (e) {
                        setState(() {
                          productsData = [];
                          errorMessage = 'no product in this category';
                        });
                        // print('Error: $e');
                      }
                    }
                    Navigator.pop(context);
                  },
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

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

  double calculateMonthlyInstallment(
      double harga, int jangkaWaktu, double iuran) {
    double jumlahPinjaman = harga;
    double bunga = jumlahPinjaman * (iuran / 100);
    double angsuranPokok = jumlahPinjaman / jangkaWaktu;
    double totalAngsuran = 0;

    for (int i = 1; i <= jangkaWaktu; i++) {
      double angsuranBulanan = angsuranPokok + bunga;
      totalAngsuran += angsuranBulanan;
      jumlahPinjaman -= angsuranPokok;
    }

    return totalAngsuran / jangkaWaktu;
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
    List<Map<String, dynamic>> productsToDisplay = productsData ?? [];
    if (_searchController.text.isNotEmpty) {
      productsToDisplay = productsToDisplay
          .where((product) => product['namaProduk']
              .toLowerCase()
              .contains(_searchController.text.toLowerCase()))
          .toList();
    }
    productsToDisplay.sort((a, b) =>
        (a['namaProduk'] as String).compareTo(b['namaProduk'] as String));

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
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Container(
                      height: 45,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color.fromRGBO(179, 192, 212, 1),
                        ),
                        borderRadius: BorderRadius.circular(25.0),
                      ),
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          hintText: 'Search products...',
                          prefixIcon: Icon(Icons.search),
                          border: InputBorder.none,
                        ),
                        onChanged: (value) {
                          setState(() {});
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.green,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.filter_list, color: Colors.white),
                      onPressed: () {
                        showCategoryDialog();
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (errorMessage != null)
                Center(
                  child: Text(errorMessage!),
                )
              else if (productsToDisplay.isEmpty)
                const Center(
                  child: Text('no product in this category'),
                )
              else
                GridView.count(
                  shrinkWrap: true,
                  crossAxisCount: MediaQuery.of(context).size.width ~/ 150,
                  childAspectRatio: 0.5,
                  mainAxisSpacing: 5,
                  crossAxisSpacing: 5,
                  children: productsToDisplay.map((product) {
                    double harga = double.tryParse(product['harga']) ?? 0.0;
                    int jangkaWaktu = 12;
                    double monthlyInstallment =
                        calculateMonthlyInstallment(harga, jangkaWaktu, iuran);
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => prodDetailScreen(
                              id: id,
                              idProduk: product['idProduk'],
                            ),
                          ),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Card(
                          child: Column(
                            children: [
                              Image.memory(
                                base64Decode(product['imgName']),
                                height: 150,
                                fit: BoxFit.cover,
                              ),
                              Container(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product['namaProduk'],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      formatAmount(product['harga']),
                                      style: const TextStyle(
                                        fontSize: 15,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Pembayaran / bulan (12 bulan): ${formatAmount(monthlyInstallment)}',
                                      style: const TextStyle(
                                        fontStyle: FontStyle.italic,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                )
            ],
          ),
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
