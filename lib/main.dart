import 'dart:async';
import 'package:flutter/material.dart';
import 'services/api_service.dart';

void main() {
  runApp(const SharoPartnerApp());
}

class SharoPartnerApp extends StatelessWidget {
  const SharoPartnerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'شاڕۆ پارتنەر | Sharo Partner',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Bahij',
        primaryColor: const Color(0xFF0A2540),
        scaffoldBackgroundColor: const Color(0xFFF1F5F9),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0A2540),
          primary: const Color(0xFF0A2540),
          secondary: const Color(0xFF059669),
        ),
        useMaterial3: true,
      ),
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },
      home: const SharoPartnerDashboard(),
    );
  }
}

class SharoPartnerDashboard extends StatefulWidget {
  const SharoPartnerDashboard({super.key});

  @override
  State<SharoPartnerDashboard> createState() => _SharoPartnerDashboardState();
}

class _SharoPartnerDashboardState extends State<SharoPartnerDashboard> {
  int _currentTab = 0;
  bool isStoreOpen = true;
  Timer? _syncTimer;

  List<Map<String, dynamic>> orders = [
    {
      'id': 'SHR-9182',
      'customer': 'محەمەد کەمال',
      'phone': '0770 123 4567',
      'address': 'دەربەندیخان - گەڕەکی سەرسیر',
      'time': '١٢:٤٠ پ.ن',
      'items': [
        {'name': 'کەبابی تایبەتی دەربەندیخان', 'qty': 2, 'price': 9500},
        {'name': 'قۆزی بەرخ بە برنجی کوردی', 'qty': 1, 'price': 14000},
      ],
      'total': 33000,
      'status': 'new', // new, preparing, ready, delivered
      'prepTime': 25,
    },
    {
      'id': 'SHR-9180',
      'customer': 'سەروەر ئەحمەد',
      'phone': '0750 998 1122',
      'address': 'دەربەندیخان - گەڕەکی بیرکێ',
      'time': '١٢:١٥ پ.ن',
      'items': [
        {'name': 'دەبڵ سمەش برگر شاڕۆ', 'qty': 2, 'price': 8000},
      ],
      'total': 16000,
      'status': 'preparing',
      'prepTime': 20,
    },
    {
      'id': 'SHR-9175',
      'customer': 'دیاری جەلال',
      'phone': '0771 445 6677',
      'address': 'دەربەندیخان - گەڕەکی شەمێران',
      'time': '١١:٣٠ پ.ن',
      'items': [
        {'name': 'کەبابی تایبەتی دەربەندیخان', 'qty': 1, 'price': 9500},
      ],
      'total': 9500,
      'status': 'ready',
      'prepTime': 0,
    },
  ];

  List<Map<String, dynamic>> menuItems = [
    {
      'id': 'm1',
      'name': 'کەبابی تایبەتی کەیف',
      'category': 'خواردنی کوردی',
      'price': 9500,
      'available': true,
      'image': 'assets/images/foods.jpg',
    },
    {
      'id': 'm2',
      'name': 'قۆزی بەرخ بە برنجی کوردی',
      'category': 'خواردنی کوردی',
      'price': 14000,
      'available': true,
      'image': 'assets/images/foods.jpg',
    },
    {
      'id': 'm3',
      'name': 'دەبڵ سمەش برگر شاڕۆ',
      'category': 'فست فوود',
      'price': 8000,
      'available': false,
      'image': 'assets/images/burger1.png',
    },
  ];

  @override
  void initState() {
    super.initState();
    _fetchCloudOrders();
    _syncTimer = Timer.periodic(const Duration(seconds: 4), (_) => _fetchCloudOrders());
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchCloudOrders() async {
    final cloudOrders = await ApiService.getStoreOrders();
    if (cloudOrders.isNotEmpty && mounted) {
      setState(() {
        for (var co in cloudOrders) {
          final id = co['id'];
          final status = co['status'];
          String mappedStatus = 'new';
          if (status == 'store_preparing') mappedStatus = 'preparing';
          if (status == 'store_ready') mappedStatus = 'ready';
          if (status == 'on_way' || status == 'delivered') mappedStatus = 'delivered';

          final existingIdx = orders.indexWhere((o) => o['id'] == id);
          if (existingIdx >= 0) {
            orders[existingIdx]['status'] = mappedStatus;
          } else {
            orders.insert(0, {
              'id': id,
              'customer': co['customerName'] ?? 'کڕیاری شاڕۆ',
              'phone': co['customerPhone'] ?? '0770 000 0000',
              'address': co['customerLocation'] ?? 'دەربەندیخان',
              'time': co['date'] ?? 'ئێستا',
              'items': [
                {'name': co['itemsSummary'] ?? 'داواکاری شاڕۆ', 'qty': 1, 'price': co['total'] ?? 15000}
              ],
              'total': co['total'] ?? 15000,
              'status': mappedStatus,
              'prepTime': 25,
            });
          }
        }
      });
    }
  }

  Future<void> acceptOrder(String id) async {
    await ApiService.acceptOrder(id);
    setState(() {
      final index = orders.indexWhere((o) => o['id'] == id);
      if (index >= 0) {
        orders[index]['status'] = 'preparing';
      }
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(backgroundColor: Colors.green, content: Text('داواکاری پەسەندکرا و درا بە چێشتخانە')),
      );
    }
  }

  Future<void> markOrderReady(String id) async {
    await ApiService.readyOrder(id);
    setState(() {
      final index = orders.indexWhere((o) => o['id'] == id);
      if (index >= 0) {
        orders[index]['status'] = 'ready';
      }
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(backgroundColor: Colors.blue, content: Text('ئاگاداری بۆ کاپتنی شاڕۆ نێردرا')),
      );
    }
  }

  void rejectOrder(String id) {
    setState(() {
      orders.removeWhere((o) => o['id'] == id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('داواکاری ڕەتکرایەوە')),
    );
  }

  void toggleItemAvailability(String id) {
    setState(() {
      final item = menuItems.firstWhere((i) => i['id'] == id);
      item['available'] = !(item['available'] as bool);
    });
  }

  void deleteMenuItem(String id) {
    setState(() {
      menuItems.removeWhere((i) => i['id'] == id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(backgroundColor: Colors.red, content: Text('خواردنەکە لە مێنیو سڕایەوە')),
    );
  }

  void _showAddOrEditFoodDialog({Map<String, dynamic>? itemToEdit}) {
    final isEditing = itemToEdit != null;
    final nameCtrl = TextEditingController(text: isEditing ? itemToEdit['name'] : '');
    final priceCtrl = TextEditingController(text: isEditing ? itemToEdit['price'].toString() : '');
    final catCtrl = TextEditingController(text: isEditing ? itemToEdit['category'] : 'خواردنی کوردی');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'دەستکاریکردنی خواردن' : 'زیادکردنی خواردنی نوێ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'ناوی خواردن')),
            TextField(controller: priceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'نرخ بە دیناری عێراقی')),
            TextField(controller: catCtrl, decoration: const InputDecoration(labelText: 'بەش (Category)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('پاشگەزبوونەوە')),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.isNotEmpty && priceCtrl.text.isNotEmpty) {
                final price = int.tryParse(priceCtrl.text) ?? 5000;
                setState(() {
                  if (isEditing) {
                    itemToEdit['name'] = nameCtrl.text;
                    itemToEdit['price'] = price;
                    itemToEdit['category'] = catCtrl.text;
                  } else {
                    menuItems.add({
                      'id': 'm${DateTime.now().millisecondsSinceEpoch}',
                      'name': nameCtrl.text,
                      'category': catCtrl.text,
                      'price': price,
                      'available': true,
                      'image': 'assets/images/foods.jpg',
                    });
                  }
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(backgroundColor: Colors.green, content: Text(isEditing ? 'خواردنەکە نوێکرایەوە' : 'خواردنی نوێ بە سەرکەوتوویی زیادکرا')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0A2540), foregroundColor: Colors.white),
            child: Text(isEditing ? 'پاشەکەوتکردن' : 'زیادکردن'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A2540),
        foregroundColor: Colors.white,
        title: Row(
          children: [
            Image.asset('assets/icons/ic_launcher.png', width: 32, height: 32),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('شاڕۆ پارتنەر | پنێڵی فرۆشیار', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                Text('چێشتخانەی کەیف · پەیوەستە بە سێرڤەر', style: TextStyle(fontSize: 10, color: Colors.white70)),
              ],
            ),
          ],
        ),
        actions: [
          Row(
            children: [
              Text(isStoreOpen ? 'کراوەیە' : 'داخراوە', style: const TextStyle(fontSize: 11)),
              Switch(
                value: isStoreOpen,
                activeColor: Colors.greenAccent,
                onChanged: (val) => setState(() => isStoreOpen = val),
              ),
            ],
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentTab,
        children: [
          _buildOrdersTab(),
          _buildMenuTab(),
          _buildReportsTab(),
          _buildSettingsTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentTab,
        onTap: (index) => setState(() => _currentTab = index),
        selectedItemColor: const Color(0xFF0A2540),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: Badge(
              label: Text('${orders.where((o) => o['status'] == 'new').length}'),
              child: const Icon(Icons.receipt_long),
            ),
            label: 'داواکارییەکان',
          ),
          const BottomNavigationBarItem(icon: Icon(Icons.restaurant_menu), label: 'مێنیو (CRUD)'),
          const BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'داهات و ڕاپۆرت'),
          const BottomNavigationBarItem(icon: Icon(Icons.store), label: 'ستۆر'),
        ],
      ),
    );
  }

  Widget _buildOrdersTab() {
    final newOrders = orders.where((o) => o['status'] == 'new').toList();
    final preparingOrders = orders.where((o) => o['status'] == 'preparing').toList();
    final readyOrders = orders.where((o) => o['status'] == 'ready').toList();

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF0A2540), Color(0xFF1E3A8A)]),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('داواکاری نوێ', '${newOrders.length}', Colors.amber),
              _buildStatItem('لە چێشتخانە', '${preparingOrders.length}', Colors.lightBlueAccent),
              _buildStatItem('ئامادەیە بۆ کاپتن', '${readyOrders.length}', Colors.greenAccent),
            ],
          ),
        ),
        const SizedBox(height: 16),

        if (newOrders.isNotEmpty) ...[
          const Row(
            children: [
              Icon(Icons.notifications_active, color: Colors.orange, size: 20),
              SizedBox(width: 6),
              Text('داواکاری نوێ (چاوەڕوانی پەسەندکردن)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
            ],
          ),
          const SizedBox(height: 8),
          ...newOrders.map((o) => _buildOrderCard(o, isNew: true)),
          const SizedBox(height: 16),
        ],

        if (preparingOrders.isNotEmpty) ...[
          const Row(
            children: [
              Icon(Icons.kitchen, color: Colors.blue, size: 20),
              SizedBox(width: 6),
              Text('لە چێشتخانە ئامادە دەکرێت', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
            ],
          ),
          const SizedBox(height: 8),
          ...preparingOrders.map((o) => _buildOrderCard(o, isPreparing: true)),
          const SizedBox(height: 16),
        ],

        if (readyOrders.isNotEmpty) ...[
          const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 20),
              SizedBox(width: 6),
              Text('ئامادەیە بۆ وەرگرتنی کاپتنی شاڕۆ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
            ],
          ),
          const SizedBox(height: 8),
          ...readyOrders.map((o) => _buildOrderCard(o, isReady: true)),
        ],
      ],
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.white70)),
      ],
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order, {bool isNew = false, bool isPreparing = false, bool isReady = false}) {
    final items = (order['items'] as List<dynamic>);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isNew ? Colors.orange : (isPreparing ? Colors.blue.shade300 : Colors.green.shade300),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('داواکاری #${order['id']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text('${order['time']}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
              ],
            ),
            const Divider(height: 14),
            Row(
              children: [
                const Icon(Icons.person, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Text('${order['customer']} (${order['phone']})', style: const TextStyle(fontSize: 12)),
              ],
            ),
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Expanded(child: Text('${order['address']}', style: const TextStyle(fontSize: 11, color: Colors.grey))),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)),
              child: Column(
                children: items.map((it) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${it['qty']}x ${it['name']}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        Text('${it['price'] * it['qty']} د.ع', style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('کۆی گشتی:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('${order['total']} د.ع', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0A2540), fontSize: 15)),
              ],
            ),
            const SizedBox(height: 10),
            if (isNew)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => rejectOrder(order['id']),
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('ڕەتکردنەوە'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () => acceptOrder(order['id']),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0A2540), foregroundColor: Colors.white),
                      child: const Text('پەسەندکردن و دەستپێکردن'),
                    ),
                  ),
                ],
              ),
            if (isPreparing)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => markOrderReady(order['id']),
                  icon: const Icon(Icons.check, color: Colors.white),
                  label: const Text('ئامادەکردن تەواو بوو (بانگکردنی کاپتنی شاڕۆ)'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                ),
              ),
            if (isReady)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
                child: const Center(
                  child: Text('چاوەڕوانی وەرگرتنی کاپتنی شاڕۆیە...', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 11)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuTab() {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('بەڕێوەبردنی مێنیو (زیادکردن، گۆڕین، سڕینەوە)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ElevatedButton.icon(
              onPressed: () => _showAddOrEditFoodDialog(),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('خواردنی نوێ'),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0A2540), foregroundColor: Colors.white),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...menuItems.map((item) => Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(item['image'], width: 64, height: 64, fit: BoxFit.cover),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      Text('${item['category']} · ${item['price']} د.ع', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                      Text(
                        (item['available'] as bool) ? 'بەردەستە لە شاڕۆ' : 'نەماوە (Sold Out)',
                        style: TextStyle(
                          color: (item['available'] as bool) ? Colors.green : Colors.red,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                  onPressed: () => _showAddOrEditFoodDialog(itemToEdit: item),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                  onPressed: () => deleteMenuItem(item['id']),
                ),
                Switch(
                  value: item['available'] as bool,
                  activeColor: Colors.green,
                  onChanged: (val) => toggleItemAvailability(item['id']),
                ),
              ],
            ),
          ),
        )),
      ],
    );
  }

  Widget _buildReportsTab() {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('داهاتی ئەمرۆی چێشتخانە', style: TextStyle(color: Colors.grey, fontSize: 12)),
                SizedBox(height: 4),
                Text('245,000 د.ع', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0A2540))),
                SizedBox(height: 12),
                Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('کۆی داواکاری تەواوکراو:'),
                    Text('١٨ داواکاری', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('پشکی پاکی چێشتخانە (٨٥٪):'),
                    Text('208,250 د.ع', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                  ],
                ),
                SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('پشکی خزمەتگوزاری شاڕۆ (١٥٪):'),
                    Text('36,750 د.ع', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsTab() {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: const ListTile(
            leading: Icon(Icons.store, color: Color(0xFF0A2540)),
            title: Text('کەبابی دەربەندیخان (Darbandikhan)'),
            subtitle: Text('دەربەندیخان - ناو بازاڕ'),
          ),
        ),
        const SizedBox(height: 8),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: const ListTile(
            leading: Icon(Icons.phone, color: Color(0xFF0A2540)),
            title: Text('ژمارەی پەیوەندی'),
            subtitle: Text('+964 770 123 4567'),
          ),
        ),
        const SizedBox(height: 8),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: const ListTile(
            leading: Icon(Icons.cloud_done, color: Color(0xFF0A2540)),
            title: Text('دۆخی پەیوەندی بە سێرڤەری شاڕۆ'),
            subtitle: Text('پەیوەستە بە Fly.io Cloud API'),
            trailing: Icon(Icons.check_circle, color: Colors.green),
          ),
        ),
      ],
    );
  }
}
