import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rentalappadmin/tranSactionhistory.dart';

class ClubTreasuryScreen extends StatefulWidget {
  @override
  _ClubTreasuryScreenState createState() => _ClubTreasuryScreenState();
}

class _ClubTreasuryScreenState extends State<ClubTreasuryScreen> {
  int _selectedIndex = 0;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  double advanceCash = 0.0;
  double totalReceivedCash = 0.0;
  double pendingCash = 0.0;
  double expenses = 0.0;
  List<Map<String, dynamic>> transactions = [];
  List<PieChartSectionData> _pieChartSections = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  void _loadInitialData() async {
    try {
      final docSnapshot = await _firestore.collection('club')
          .doc('financials')
          .get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data()!;
        setState(() {
          totalReceivedCash = data['totalReceivedCash'] ?? 0.0;
          pendingCash = data['pendingCash'] ?? 0.0;
          expenses = data['expenses'] ?? 0.0;

          // Convert the transaction timestamps from Firestore
          transactions =
              List<Map<String, dynamic>>.from(data['transactions'] ?? []).map((
                  transaction) {
                return {
                  'type': transaction['type'],
                  'amount': transaction['amount'],
                  'date': (transaction['date'] as Timestamp).toDate(),
                  // Convert Timestamp to DateTime
                  'who': transaction['who'],
                  'where': transaction['where'],
                };
              }).toList();

          _generateChartData();
        });
      }
    } catch (e) {
      print('Error loading data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 1) { // Transactions index
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => HistoryScreen()),
      );
    }
  }

  Future<void> _updateFirestore() async {
    try {
      await _firestore.collection('club').doc('financials').set({
        'totalReceivedCash': totalReceivedCash,
        'pendingCash': pendingCash,
        'expenses': expenses,
        'transactions': transactions,
        'advanceCash': advanceCash,
      });
    } catch (e) {
      print('Error updating data: $e');
    }
  }

  void _showTransactionDialog(String s) {
    final TextEditingController amountController = TextEditingController();
    final TextEditingController whoController = TextEditingController();
    final TextEditingController whereController = TextEditingController();
    String selectedTransactionType = 'Add to Pending Cash'; // Default transaction type

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Add Transaction'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButton<String>(
                      value: selectedTransactionType,
                      items: [
                        DropdownMenuItem(
                            value: 'Add to Pending Cash', child: Text(
                            'Add to Pending Cash')),
                        DropdownMenuItem(
                            value: 'Add to Total Received Cash', child: Text(
                            'Add to Total Received Cash')),
                        DropdownMenuItem(value: 'Add to Rent Cash', child: Text(
                            'Add to Rent Cash')),
                        DropdownMenuItem(
                            value: 'Add to Advance Cash', child: Text(
                            'Add to Advance Cash')),
                        DropdownMenuItem(value: 'Add Expense', child: Text(
                            'Add Expense')), // New option
                      ],
                      onChanged: (value) {
                        setState(() {
                          selectedTransactionType = value!;
                        });
                      },
                    ),
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(hintText: 'Enter amount'),
                    ),
                    if (selectedTransactionType.contains('Received') ||
                        selectedTransactionType.contains('Expense'))
                      TextField(
                        controller: whoController,
                        decoration: InputDecoration(
                            hintText: 'Who gave/received the amount'),
                      ),
                    if (selectedTransactionType.contains('Received') ||
                        selectedTransactionType.contains('Expense'))
                      TextField(
                        controller: whereController,
                        decoration: InputDecoration(
                            hintText: 'Where it was given/used'),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    final double amount =
                        double.tryParse(amountController.text) ?? 0;
                    final String who = whoController.text;
                    final String where = whereController.text;

                    if (amount > 0 &&
                        (selectedTransactionType != 'Add Expense' ||
                            (who.isNotEmpty && where.isNotEmpty))) {
                      setState(() {
                        _handleTransactionAction(
                            selectedTransactionType, amount, who, where);
                        _generateChartData();
                        _updateFirestore();
                      });
                      Navigator.pop(context);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Please enter valid input.')),
                      );
                    }
                  },
                  child: Text('Submit'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _handleTransactionAction(String actionType, double amount, String who,
      String where) {
    switch (actionType) {
      case 'Add to Pending Cash':
        pendingCash += amount;
        break;
      case 'Add to Total Received Cash':
        totalReceivedCash += amount;
        break;
      case 'Add to Rent Cash':
        totalReceivedCash += amount;
        break;
      case 'Add to Advance Cash':
        advanceCash += amount; // Ensure you update the advance cash
        break;
      case 'Add Expense': // Handle expenses
        expenses += amount;
        break;
      case 'Reduce Pending Cash':
        pendingCash -= amount;
        break;
      case 'Update Total Received Cash':
        totalReceivedCash = amount;
        break;
      default:
        break;
    }

    // Add transaction to the list
    transactions.add({
      'type': actionType,
      'amount': amount,
      'date': DateTime.now(),
      'who': who,
      'where': where,
    });
  }

  void _generateChartData() {
    final data = {
      'Received': totalReceivedCash,
      'Pending': pendingCash,
      'Expenses': expenses,
    };

    final sections = data.entries.map((entry) {
      return PieChartSectionData(
        color: _getColorForCategory(entry.key),
        value: entry.value,
        title: '${entry.value.toStringAsFixed(2)}',
        radius: 60,
        titleStyle: TextStyle(
            fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();

    setState(() {
      _pieChartSections = sections;
    });
  }

  Color _getColorForCategory(String category) {
    switch (category) {
      case 'Received':
        return Colors.green;
      case 'Pending':
        return Colors.orange;
      case 'Expenses':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _removeTransaction(int index) async {
    final transaction = transactions[index];
    await _firestore.collection('club').doc('financials').update({
      'transactions': FieldValue.arrayRemove([transaction])
    });

    setState(() {
      transactions.removeAt(index);
      _generateChartData();
      _updateFirestore();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(

        // Maintain your chosen background color



      ),

      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
        padding: EdgeInsets.all(19.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSummaryCards(),
              SizedBox(height: 16),
          
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showTransactionDialog('Add to Pending Cash'),
        child: Icon(Icons.add),
        tooltip: 'Add Transaction',
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard), label: 'Overview'),
          BottomNavigationBarItem(
              icon: Icon(Icons.history), label: 'Transactions'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: Colors.teal[100],
        selectedItemColor: Colors.teal,
        unselectedItemColor: Colors.black54,
        elevation: 8,
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Column(
      children: [
        _buildFinancialCard(
          title: 'Pending Cash',
          amount: pendingCash,
          color: Colors.orange,
          icon: Icons.money_off,
          gradientColors: [Colors.orange.shade300, Colors.orange.shade700],
        ),
        SizedBox(height: 16),
        _buildFinancialCard(
          title: 'Total Received Cash',
          amount: totalReceivedCash,
          color: Colors.green,
          icon: Icons.attach_money,
          gradientColors: [Colors.green.shade300, Colors.green.shade700],
        ),
        SizedBox(height: 16),
        _buildFinancialCard(
          title: 'Expenses',
          amount: expenses,
          color: Colors.red,
          icon: Icons.explicit,
          gradientColors: [Colors.red.shade300, Colors.red.shade700],
        ),
        SizedBox(height: 16),
        _buildFinancialCard(
          title: 'Advance Cash',
          amount: advanceCash,
          color: Colors.blue,
          icon: Icons.account_balance_wallet,
          gradientColors: [Colors.blue.shade300, Colors.blue.shade700],
        ),
      ],
    );
  }

  Widget _buildFinancialCard({
    required String title,
    required double amount,
    required Color color,
    required IconData icon,
    required List<Color> gradientColors,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: Offset(2, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, size: 36, color: Colors.white),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '₹${amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}



