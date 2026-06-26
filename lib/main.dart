import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyCwpdxvi2rC2hiQ7Zg9U4y09ldAnVX0mUE",
      authDomain: "superdoggy-e6815.firebaseapp.com",
      projectId: "superdoggy-e6815",
      storageBucket: "superdoggy-e6815.firebasestorage.app",
      messagingSenderId: "453404962989",
      appId: "1:453404962989:web:5666ecd6bf846ecc30d624",
    ),
  );

  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: DoggyHomeScreen(),
    ),
  );
}

class DoggyHomeScreen extends StatefulWidget {
  const DoggyHomeScreen({super.key});
  @override
  State<DoggyHomeScreen> createState() => _DoggyHomeScreenState();
}

class _DoggyHomeScreenState extends State<DoggyHomeScreen> {
  final TextEditingController _t = TextEditingController();
  final TextEditingController _a = TextEditingController();
  final TextEditingController _editNameController = TextEditingController();
  final TextEditingController _editBalanceController = TextEditingController();
  final TextEditingController _n = TextEditingController();
  final TextEditingController _b = TextEditingController();

  String _curr = "全部資產";
  String _type = "EXPENSE";
  String _selectedAccountForTx = "";
  String _selectedCategory = "";

  String _userRole = "貓狗共用觀看";
  String _newAccountOwner = "共用";

  List<String> _localAccountNames = [];
  Map<String, String> _globalAccountOwners = {};
  List<String> _accountOrder = []; // 用來存儲資產卡片的排序

  final List<String> _expenseCategories = [
    "日用品",
    "餐飲",
    "交通",
    "娛樂",
    "服飾",
    "教育",
    "美容",
    "零食",
    "親子",
    "數位",
    "社交",
    "旅遊",
    "寵物",
    "居住",
    "汽車",
    "生活繳費",
    "茶酒",
    "醫療",
    "美妝",
    "遊戲",
  ];

  final List<String> _incomeCategories = ["薪水", "獎金", "投資", "兼職", "其他收入"];

  InputDecoration _inputDec(String label) => InputDecoration(
    labelText: label,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  );

  void _showAddTransactionDialog() {
    _t.clear();
    _a.clear();
    _selectedAccountForTx = "";
    _selectedCategory = "";
    _type = "EXPENSE";

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('💰 記一筆'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: _t, decoration: _inputDec('項目名稱')),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _a,
                      keyboardType: TextInputType.number,
                      decoration: _inputDec('金額'),
                    ),
                    const SizedBox(height: 12),
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('accounts')
                          .orderBy('createdAt', descending: false)
                          .snapshots(),
                      builder: (context, snapshot) {
                        List<String> availableAccounts = [];

                        if (snapshot.hasData && snapshot.data != null) {
                          final accountDocs = snapshot.data!.docs;
                          List<String> banListIds = ["現金", "共同存款", "信用卡"];
                          Set<String> uniqueAccounts = {};

                          for (var doc in accountDocs) {
                            if (banListIds.contains(doc.id)) continue;

                            final data = doc.data() as Map<String, dynamic>;
                            String name = data['name'] ?? "";
                            if (name.isEmpty) continue;

                            String owner = data['owner'] ?? "共用";

                            if (owner != "信用卡") {
                              if (_userRole == "貓狗共用觀看" ||
                                  owner == "共用" ||
                                  owner == _userRole) {
                                uniqueAccounts.add(name);
                              }
                            }
                          }

                          availableAccounts = uniqueAccounts.toList();
                        }

                        return Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade400),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: _selectedAccountForTx.isEmpty
                                ? null
                                : _selectedAccountForTx,
                            hint: const Text('選擇要記帳的資產'),
                            items: availableAccounts
                                .map<DropdownMenuItem<String>>((account) {
                                  return DropdownMenuItem<String>(
                                    value: account,
                                    child: Text(account),
                                  );
                                })
                                .toList(),
                            onChanged: (String? newValue) {
                              setDialogState(() {
                                _selectedAccountForTx = newValue ?? "";
                              });
                            },
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade200,
                            ),
                            onPressed: () {
                              setDialogState(() => _type = "EXPENSE");
                            },
                            child: Text(
                              '支出',
                              style: TextStyle(
                                color: _type == "EXPENSE"
                                    ? Colors.white
                                    : Colors.black,
                                fontWeight: _type == "EXPENSE"
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade200,
                            ),
                            onPressed: () {
                              setDialogState(() => _type = "INCOME");
                            },
                            child: Text(
                              '收入',
                              style: TextStyle(
                                color: _type == "INCOME"
                                    ? Colors.white
                                    : Colors.black,
                                fontWeight: _type == "INCOME"
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey.shade300,
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: const Text(
                              '取消',
                              style: TextStyle(color: Colors.black),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE6A055),
                            ),
                            onPressed: () async {
                              final int? amt = int.tryParse(_a.text);
                              if (_t.text.isEmpty || amt == null) {
                                if (mounted) {
                                  ScaffoldMessenger.of(
                                    dialogContext,
                                  ).clearSnackBars();
                                  ScaffoldMessenger.of(
                                    dialogContext,
                                  ).showSnackBar(
                                    const SnackBar(
                                      content: Text('⚠️ 請填寫項目名稱和金額'),
                                    ),
                                  );
                                }
                                return;
                              }

                              if (_selectedAccountForTx.isEmpty) {
                                if (mounted) {
                                  ScaffoldMessenger.of(
                                    dialogContext,
                                  ).clearSnackBars();
                                  ScaffoldMessenger.of(
                                    dialogContext,
                                  ).showSnackBar(
                                    const SnackBar(content: Text('⚠️ 請選擇資產')),
                                  );
                                }
                                return;
                              }

                              String targetAccountName = _selectedAccountForTx;
                              String currentOwner =
                                  _globalAccountOwners[targetAccountName] ??
                                  "共用";

                              print(
                                "💾 準備記帳: $targetAccountName, 所有者: $currentOwner, 類型: $_type, 金額: $amt",
                              );
                              print("📋 全局賬戶所有者: $_globalAccountOwners");

                              final txData = {
                                "title": _t.text,
                                "amount": amt,
                                "type": _type,
                                "account": targetAccountName,
                                "date": DateTime.now().toIso8601String(),
                              };

                              try {
                                await FirebaseFirestore.instance
                                    .collection('transactions')
                                    .add(txData);

                                final accountSnapshot = await FirebaseFirestore
                                    .instance
                                    .collection('accounts')
                                    .where('name', isEqualTo: targetAccountName)
                                    .get();

                                print(
                                  "🔍 查詢賬戶: $targetAccountName, 找到 ${accountSnapshot.docs.length} 個文檔",
                                );

                                if (accountSnapshot.docs.isNotEmpty) {
                                  final accountRef =
                                      accountSnapshot.docs.first.reference;
                                  print(
                                    "📝 更新賬戶: $targetAccountName, 類型: $_type, 金額: $amt",
                                  );

                                  await FirebaseFirestore.instance.runTransaction((
                                    transaction,
                                  ) async {
                                    final snapshot = await transaction.get(
                                      accountRef,
                                    );
                                    if (snapshot.exists) {
                                      int currentBalance =
                                          (snapshot.data()?['balance'] as num?)
                                              ?.toInt() ??
                                          0;
                                      int newBalance;
                                      if (currentOwner == "信用卡") {
                                        newBalance = _type == "EXPENSE"
                                            ? currentBalance + amt
                                            : currentBalance - amt;
                                      } else {
                                        newBalance = _type == "EXPENSE"
                                            ? currentBalance - amt
                                            : currentBalance + amt;
                                      }
                                      print(
                                        "💰 余額變化: $currentBalance -> $newBalance",
                                      );
                                      transaction.update(accountRef, {
                                        'balance': newBalance,
                                      });
                                    }
                                  });
                                } else {
                                  print("❌ 未找到賬戶: $targetAccountName");
                                }

                                if (mounted) {
                                  ScaffoldMessenger.of(
                                    dialogContext,
                                  ).clearSnackBars();
                                  ScaffoldMessenger.of(
                                    dialogContext,
                                  ).showSnackBar(
                                    const SnackBar(content: Text('✅ 記帳成功')),
                                  );
                                  Future.delayed(
                                    const Duration(milliseconds: 300),
                                    () {
                                      if (mounted) {
                                        Navigator.of(dialogContext).pop();
                                      }
                                    },
                                  );
                                }
                              } catch (e) {
                                print("記帳失敗: $e");
                                if (mounted) {
                                  ScaffoldMessenger.of(
                                    dialogContext,
                                  ).clearSnackBars();
                                  ScaffoldMessenger.of(
                                    dialogContext,
                                  ).showSnackBar(
                                    const SnackBar(content: Text('❌ 記帳失敗')),
                                  );
                                  Future.delayed(
                                    const Duration(milliseconds: 300),
                                    () {
                                      if (mounted) {
                                        Navigator.of(dialogContext).pop();
                                      }
                                    },
                                  );
                                }
                              }
                            },
                            child: const Text(
                              '完成',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _forceInitDefaultAccounts() async {
    Map<String, Map<String, dynamic>> defaultData = {
      "現金": {"balance": 1, "owner": "共用"},
      "貓罐頭基金": {"balance": 3000, "owner": "貓貓"},
      "狗骨頭銀行": {"balance": 45000, "owner": "狗狗"},
      "貓狗聯合金庫": {"balance": 1500, "owner": "共用"},
    };

    for (var entry in defaultData.entries) {
      await FirebaseFirestore.instance.collection('accounts').add({
        'name': entry.key,
        'balance': entry.value['balance'],
        'owner': entry.value['owner'],
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // 1. 雲端同步：修正後的安全記帳邏輯
  void _addTx() async {
    final int? amt = int.tryParse(_a.text);
    if (_t.text.isEmpty || amt == null) return;

    String targetAccountName = _selectedAccountForTx;

    if (targetAccountName.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('⚠️ 請先選擇要記帳的資產唷！')));
      return;
    }

    String currentOwner = _globalAccountOwners[targetAccountName] ?? "共用";

    final txData = {
      "title": _t.text,
      "amount": amt,
      "type": _type,
      "account": targetAccountName,
      "date": DateTime.now().toIso8601String(),
    };

    try {
      // 先建立交易紀錄
      await FirebaseFirestore.instance.collection('transactions').add(txData);

      // 🛠️ 核心修正：改用正確的 'name' 欄位條件去搜尋 accounts 裡的文件
      final accountSnapshot = await FirebaseFirestore.instance
          .collection('accounts')
          .where('name', isEqualTo: targetAccountName)
          .get();

      if (accountSnapshot.docs.isNotEmpty) {
        final accountRef = accountSnapshot.docs.first.reference;
        await FirebaseFirestore.instance.runTransaction((transaction) async {
          final snapshot = await transaction.get(accountRef);
          if (snapshot.exists) {
            int currentBalance =
                (snapshot.data()?['balance'] as num?)?.toInt() ?? 0;
            int newBalance;
            if (currentOwner == "信用卡") {
              newBalance = _type == "EXPENSE"
                  ? currentBalance + amt
                  : currentBalance - amt;
            } else {
              newBalance = _type == "EXPENSE"
                  ? currentBalance - amt
                  : currentBalance + amt;
            }
            transaction.update(accountRef, {'balance': newBalance});
          }
        });
      }
    } catch (e) {
      print("記帳同步失敗: $e");
    }

    _t.clear();
    _a.clear();
    setState(() {
      _selectedAccountForTx = "";
    });
    FocusScope.of(context).unfocus(); // 自動收起鍵盤
  }

  // 2. 雲端同步：長按刪除記帳紀錄
  void _deleteTx(Map<String, dynamic> item) async {
    final String? docId = item["id"];
    final String accountName = item["account"];
    final int amt = item["amount"];
    final String type = item["type"];

    if (docId == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('transactions')
          .doc(docId)
          .delete();

      final accountSnapshot = await FirebaseFirestore.instance
          .collection('accounts')
          .where('name', isEqualTo: accountName)
          .get();

      if (accountSnapshot.docs.isNotEmpty) {
        final accountRef = accountSnapshot.docs.first.reference;
        await FirebaseFirestore.instance.runTransaction((transaction) async {
          final snapshot = await transaction.get(accountRef);
          if (snapshot.exists) {
            int currentBalance =
                (snapshot.data()?['balance'] as num?)?.toInt() ?? 0;
            String currentOwner = snapshot.data()?['owner'] ?? "共用";
            int newBalance;
            if (currentOwner == "信用卡") {
              newBalance = type == "EXPENSE"
                  ? currentBalance - amt
                  : currentBalance + amt;
            } else {
              newBalance = type == "EXPENSE"
                  ? currentBalance + amt
                  : currentBalance - amt;
            }
            transaction.update(accountRef, {'balance': newBalance});
          }
        });
      }
    } catch (e) {
      print("刪除紀錄失敗: $e");
    }
  }

  // 3. 雲端同步：打造新私房碗 / 建立新信用卡
  void _showAddAccountDialog() {
    _newAccountOwner = "共用";
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('🐾 打造新資產/信用卡'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _n,
                    decoration: _inputDec('名稱（例如：現金 / 共同存款）'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _b,
                    keyboardType: TextInputType.number,
                    decoration: _inputDec('開戶金額 / 已刷卡費'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "類型/歸屬：",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      DropdownButton<String>(
                        value: _newAccountOwner,
                        items: const [
                          DropdownMenuItem(
                            value: "共用",
                            child: Text("👥 貓狗共用資產"),
                          ),
                          DropdownMenuItem(
                            value: "貓貓",
                            child: Text("🐱 貓貓私房資產"),
                          ),
                          DropdownMenuItem(
                            value: "狗狗",
                            child: Text("🐶 狗狗私房資產"),
                          ),
                          DropdownMenuItem(
                            value: "信用卡",
                            child: Text("💳 信用卡專屬"),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => _newAccountOwner = val);
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('取消'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE6A055),
                  ),
                  onPressed: () async {
                    final String name = _n.text.trim();
                    final int? balance = int.tryParse(_b.text);
                    if (name.isEmpty || balance == null) return;

                    try {
                      await FirebaseFirestore.instance
                          .collection('accounts')
                          .add({
                            'name': name,
                            'balance': balance,
                            'owner': _newAccountOwner,
                            'createdAt': FieldValue.serverTimestamp(),
                          });
                      // 建立成功後，自動將記帳主視角切換至該新資產
                      setState(() {
                        _curr = name;
                      });
                    } catch (e) {
                      print("帳戶上傳失敗: $e");
                    }

                    _n.clear();
                    _b.clear();
                    Navigator.pop(context);
                  },
                  child: const Text(
                    '建立',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // 4. 雲端同步：修改帳戶與卡費繳清
  void _showEditAccountDialog(
    String oldName,
    int currentBalance,
    String owner,
  ) {
    _editNameController.text = oldName;
    _editBalanceController.text = currentBalance.toString();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            owner == "信用卡" ? '💳 信用卡【$oldName】管理' : '✏️ 修改【$oldName】資料',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _editNameController,
                decoration: _inputDec('名稱'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _editBalanceController,
                keyboardType: TextInputType.number,
                decoration: _inputDec(owner == "信用卡" ? '目前累積已刷金額' : '餘額'),
              ),
            ],
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _showDeleteAccountDialog(oldName);
                  },
                  icon: const Icon(
                    Icons.delete_forever,
                    color: Colors.redAccent,
                    size: 18,
                  ),
                  label: const Text(
                    '刪除',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (owner == "信用卡") ...[
                  TextButton.icon(
                    onPressed: () async {
                      try {
                        final accountSnapshot = await FirebaseFirestore.instance
                            .collection('accounts')
                            .where('name', isEqualTo: oldName)
                            .get();
                        if (accountSnapshot.docs.isNotEmpty) {
                          await accountSnapshot.docs.first.reference.update({
                            'balance': 0,
                          });
                        }
                      } catch (e) {
                        print("繳清卡費失敗: $e");
                      }
                      Navigator.pop(context);
                    },
                    icon: const Icon(
                      Icons.monetization_on,
                      color: Colors.green,
                      size: 18,
                    ),
                    label: const Text(
                      '繳清',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('取消'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE6A055),
                  ),
                  onPressed: () async {
                    final String newName = _editNameController.text.trim();
                    final int? newBalance = int.tryParse(
                      _editBalanceController.text,
                    );
                    if (newName.isEmpty || newBalance == null) return;

                    try {
                      final accountSnapshot = await FirebaseFirestore.instance
                          .collection('accounts')
                          .where('name', isEqualTo: oldName)
                          .get();

                      if (accountSnapshot.docs.isNotEmpty) {
                        final docRef = accountSnapshot.docs.first.reference;
                        await docRef.update({
                          'name': newName,
                          'balance': newBalance,
                        });

                        if (oldName != newName) {
                          final txsSnapshot = await FirebaseFirestore.instance
                              .collection('transactions')
                              .where('account', isEqualTo: oldName)
                              .get();
                          for (var doc in txsSnapshot.docs) {
                            await doc.reference.update({'account': newName});
                          }
                          setState(() {
                            if (_curr == oldName) _curr = newName;
                          });
                        }
                      }
                    } catch (e) {
                      print("更新帳戶失敗: $e");
                    }
                    Navigator.pop(context);
                  },
                  child: const Text(
                    '更新',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  // 5. 雲端同步：刪除帳戶
  void _showDeleteAccountDialog(String accountName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('🗑️ 刪除【$accountName】'),
          content: const Text('確定要移除此帳戶嗎？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('留著'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
              onPressed: () async {
                try {
                  final accountSnapshot = await FirebaseFirestore.instance
                      .collection('accounts')
                      .where('name', isEqualTo: accountName)
                      .get();
                  if (accountSnapshot.docs.isNotEmpty) {
                    await accountSnapshot.docs.first.reference.delete();
                  }
                  setState(() {
                    if (_curr == accountName) _curr = "全部資產";
                  });
                } catch (e) {
                  print("刪除帳戶失敗: $e");
                }
                Navigator.pop(context);
              },
              child: const Text('刪除', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFDF9),
      appBar: AppBar(
        title: const Text("🐾 貓狗私房記帳簿", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFFE6A055),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.pets, color: Colors.white, size: 26),
            onSelected: (String role) {
              setState(() {
                _userRole = role;
                _curr = "全部資產";
              });
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem(value: "貓狗共用觀看", child: Text("👥 觀看全部資產")),
              const PopupMenuItem(value: "貓貓", child: Text("🐱 切換為：貓貓視角")),
              const PopupMenuItem(value: "狗狗", child: Text("🐶 切換為：狗狗視角")),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
            color: Colors.orange.shade100,
            child: Text(
              "當前肉墊視角：$_userRole",
              style: TextStyle(
                fontSize: 12,
                color: Colors.orange.shade900,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('accounts')
                .orderBy('createdAt', descending: false)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 100,
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final accountDocs = snapshot.data?.docs ?? [];
              Map<String, int> cloudAccs = {};
              Map<String, String> accountOwners = {};

              List<String> tempNormalAccs = [];
              Map<String, String> tempGlobalOwners = {};

              // 🛠️ 僅封鎖舊架構殘留的 Document ID 垃圾資料，不擋新中文欄位
              List<String> banList = ["現金", "共同存款", "信用卡"];

              for (var doc in accountDocs) {
                if (banList.contains(doc.id)) continue;

                final data = doc.data() as Map<String, dynamic>;
                String name = data['name'] ?? "";
                if (name.isEmpty) continue;

                // 打印所有賬戶信息用於調試
                print(
                  "📊 賬戶: $name, Owner: ${data['owner']}, Balance: ${data['balance']}",
                );

                String owner = data['owner'] ?? "共用";
                if (owner.isEmpty) owner = "共用";

                // 如果現金账户没有owner字段，自动设置为共用
                if (name == "現金") {
                  print("🔍 檢測到現金賬戶！Owner值: ${data['owner']}");
                  if (data['owner'] == null || data['owner'] == "") {
                    owner = "共用";
                    doc.reference.update({'owner': '共用'});
                    print("🔧 自動修復現金賬戶所有者設置為: 共用");
                  }
                }

                tempGlobalOwners[name] = owner;

                if (owner != "信用卡") {
                  if (_userRole == "貓狗共用觀看" ||
                      owner == "共用" ||
                      owner == _userRole) {
                    tempNormalAccs.add(name);
                    print("✅ 添加 $name 到可見賬戶列表 (所有者: $owner)");
                  }
                }

                if (_userRole == "貓狗共用觀看" ||
                    owner == "共用" ||
                    owner == _userRole ||
                    owner == "信用卡") {
                  cloudAccs[name] = (data['balance'] as num?)?.toInt() ?? 0;
                  accountOwners[name] = owner;
                  print(
                    "✅ 添加 $name 到顯示賬戶 (所有者: $owner, 余額: ${cloudAccs[name]})",
                  );
                }
              }

              if (accountDocs.isEmpty) {
                _forceInitDefaultAccounts();
              }

              _localAccountNames = tempNormalAccs;
              _globalAccountOwners = tempGlobalOwners;

              // 初始化和更新資產排序
              if (_accountOrder.isEmpty) {
                _accountOrder = cloudAccs.keys.toList();
                print("🆕 初始化資產排序: ${_accountOrder.join(', ')}");
              } else {
                // 添加任何新資產到排序列表末尾
                for (String accountName in cloudAccs.keys) {
                  if (!_accountOrder.contains(accountName)) {
                    _accountOrder.add(accountName);
                    print("➕ 添加新資產到排序列表: $accountName");
                  }
                }
                // 移除已刪除的資產
                _accountOrder.removeWhere(
                  (name) => !cloudAccs.containsKey(name),
                );
              }

              return Container(
                padding: const EdgeInsets.all(10),
                color: const Color(0xFFE6A055).withOpacity(0.05),
                height: 115,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    GestureDetector(
                      onTap: () => setState(() => _curr = "全部資產"),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 5),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _curr == "全部資產"
                              ? const Color(0xFFE6A055)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE6A055)),
                        ),
                        child: const Center(
                          child: Text(
                            "全部\n資產",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    ..._accountOrder
                        .where((name) => cloudAccs.containsKey(name))
                        .map<Widget>((accountName) {
                          final balance = cloudAccs[accountName]!;
                          final bool sel = _curr == accountName;
                          final String owner =
                              accountOwners[accountName] ?? "共用";

                          String ownerTag = "👥";
                          if (owner == "貓貓") ownerTag = "🐱";
                          if (owner == "狗狗") ownerTag = "🐶";
                          if (owner == "信用卡") ownerTag = "💳";

                          Color cardColor = sel
                              ? (owner == "信用卡"
                                    ? Colors.blueGrey.shade700
                                    : const Color(0xFFE6A055))
                              : Colors.white;

                          final accountCard = GestureDetector(
                            onTap: () => setState(() => _curr = accountName),
                            onLongPress: () =>
                                _showDeleteAccountDialog(accountName),
                            onDoubleTap: () => _showEditAccountDialog(
                              accountName,
                              balance,
                              owner,
                            ),
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 5),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: cardColor,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: owner == "信用卡"
                                      ? Colors.blueGrey
                                      : const Color(
                                          0xFFE6A055,
                                        ).withOpacity(0.5),
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "$ownerTag $accountName",
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: sel ? Colors.white70 : Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    owner == "信用卡"
                                        ? '已刷 \$$balance'
                                        : '\$$balance',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: sel
                                          ? Colors.white
                                          : (owner == "信用卡"
                                                ? Colors.deepOrange
                                                : (balance >= 0
                                                      ? Colors.black
                                                      : Colors.red)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );

                          // 用 Draggable 包裝卡片以支援拖動排序
                          return Draggable<String>(
                            data: accountName,
                            feedback: Material(
                              child: Transform.scale(
                                scale: 1.1,
                                child: accountCard,
                              ),
                            ),
                            childWhenDragging: Opacity(
                              opacity: 0.5,
                              child: accountCard,
                            ),
                            child: DragTarget<String>(
                              onAcceptWithDetails: (details) {
                                setState(() {
                                  final fromIndex = _accountOrder.indexOf(
                                    details.data,
                                  );
                                  final toIndex = _accountOrder.indexOf(
                                    accountName,
                                  );
                                  if (fromIndex != -1 && toIndex != -1) {
                                    final temp = _accountOrder[fromIndex];
                                    _accountOrder[fromIndex] =
                                        _accountOrder[toIndex];
                                    _accountOrder[toIndex] = temp;
                                    print(
                                      "🔄 資產重新排序: ${_accountOrder.join(', ')}",
                                    );
                                  }
                                });
                              },
                              builder: (context, candidateData, rejectedData) {
                                return accountCard;
                              },
                            ),
                          );
                        }),
                    GestureDetector(
                      onTap: _showAddAccountDialog,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 5),
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey),
                        ),
                        child: const Center(
                          child: Text(
                            '➕ 新增',
                            style: TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('transactions')
                  .orderBy('date', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? [];
                List<Map<String, dynamic>> cloudTxs = docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return {
                    "id": doc.id,
                    "title": data["title"] ?? "",
                    "amount": (data["amount"] as num?)?.toInt() ?? 0,
                    "type": data["type"] ?? "EXPENSE",
                    "account": data["account"] ?? "",
                    "date": data["date"] ?? "",
                  };
                }).toList();

                List<Map<String, dynamic>> displayTxs = _curr == "全部資產"
                    ? cloudTxs
                    : cloudTxs.where((tx) => tx["account"] == _curr).toList();

                if (displayTxs.isEmpty) {
                  return const Center(child: Text("🐾 這裡沒有可見的記帳紀錄唷！"));
                }

                // 按日期分組交易
                Map<String, List<Map<String, dynamic>>> groupedByDate = {};
                for (var tx in displayTxs) {
                  String dateKey = "";
                  try {
                    final dateTime = DateTime.parse(tx["date"] as String);
                    dateKey =
                        "${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}";
                  } catch (e) {
                    dateKey = "未知日期";
                  }

                  if (!groupedByDate.containsKey(dateKey)) {
                    groupedByDate[dateKey] = [];
                  }
                  groupedByDate[dateKey]!.add(tx);
                }

                // 建立顯示列表
                List<Widget> items = [];
                for (var date in groupedByDate.keys) {
                  // 添加日期標籤
                  try {
                    final dateParts = date.split('-');
                    final month = int.parse(dateParts[1]);
                    final day = int.parse(dateParts[2]);
                    final txDate = DateTime(
                      int.parse(dateParts[0]),
                      month,
                      day,
                    );
                    final today = DateTime.now();
                    final isToday =
                        txDate.year == today.year &&
                        txDate.month == today.month &&
                        txDate.day == today.day;

                    final dateLabel = isToday
                        ? "$month月${day}日，今天"
                        : "$month月${day}日";

                    items.add(
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                        child: Text(
                          dateLabel,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    );
                  } catch (e) {
                    items.add(
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                        child: Text(
                          date,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    );
                  }

                  // 添加該日期的所有交易
                  for (var item in groupedByDate[date]!) {
                    items.add(
                      ListTile(
                        leading: Icon(
                          item["type"] == "EXPENSE"
                              ? Icons.pets
                              : Icons.savings,
                          color: item["type"] == "EXPENSE"
                              ? Colors.orange
                              : Colors.green,
                        ),
                        title: Text(
                          item["title"],
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        subtitle: Text(item["account"]),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              (item["type"] == "EXPENSE" ? "-" : "+") +
                                  item["amount"].toString(),
                              style: TextStyle(
                                color: item["type"] == "EXPENSE"
                                    ? Colors.red
                                    : Colors.green,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => _deleteTx(item),
                              child: Icon(
                                Icons.delete_outline,
                                size: 20,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                }

                return ListView(children: items);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTransactionDialog,
        backgroundColor: const Color(0xFFE6A055),
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
    );
  }
}
