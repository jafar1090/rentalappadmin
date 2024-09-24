import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<PieChartSectionData> _pieChartSections = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  double advanceCash = 0.0;
  double totalReceivedCash = 0.0;
  double pendingCash = 0.0;
  double expenses = 0.0;
  List<Map<String, dynamic>> transactions = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final doc = await _firestore.collection('club').doc('financials').get();
      final data = doc.data();
      if (data != null) {
        setState(() {
          totalReceivedCash = data['totalReceivedCash'] ?? 0.0;
          pendingCash = data['pendingCash'] ?? 0.0;
          expenses = data['expenses'] ?? 0.0;
          advanceCash = data['advanceCash'] ?? 0.0;

          // Correcting the conversion of Firestore timestamps to DateTime
          transactions = List<Map<String, dynamic>>.from(data['transactions'] ?? []).map((transaction) {
            return {
              'type': transaction['type'],
              'amount': transaction['amount'],
              'date': (transaction['date'] as Timestamp).toDate(),  // Convert Timestamp to DateTime
              'who': transaction['who'],
              'where': transaction['where'],
            };
          }).toList();

          _generateChartData();
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching data: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _removeTransaction(int index) async {
    final transaction = transactions[index];

    // Show confirmation dialog
    bool? confirmDelete = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Confirm Delete"),
          content: Text("Are you sure you want to delete this transaction?"),
          actions: [
            TextButton(
              child: Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop(false); // Return false if cancelled
              },
            ),
            TextButton(
              child: Text("Delete", style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop(true); // Return true if confirmed
              },
            ),
          ],
        );
      },
    );

    // If user confirmed, proceed with deletion
    if (confirmDelete == true) {
      try {
        await _firestore.collection('club').doc('financials').update({
          'transactions': FieldValue.arrayRemove([transaction])
        });

        setState(() {
          transactions.removeAt(index);
          _generateChartData();
          _updateFirestore();
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error removing transaction: $e')),
        );
      }
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating data: $e')),
      );
    }
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
        titleStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
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

  void _handleTransactionAction(String actionType, double amount, String who, String where) {
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
        advanceCash += amount;
        break;
      case 'Add Expense':
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

    transactions.add({
      'type': actionType,
      'amount': amount,
      'date': DateTime.now(),
      'who': who,
      'where': where,
    });

    _updateFirestore();
    _generateChartData();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Transaction History'),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            if (_isLoading)
              Center(child: CircularProgressIndicator())
            else if (_errorMessage != null)
              Center(child: Text(_errorMessage!))
            else ...[
                Expanded(
                  child:ListView.builder(
                    itemCount: transactions.length,
                    itemBuilder: (context, index) {
                      final transaction = transactions[index];
                      DateTime transactionDate;

                      // Safely convert Timestamp to DateTime if necessary
                      if (transaction['date'] is Timestamp) {
                        transactionDate = (transaction['date'] as Timestamp).toDate();
                      } else {
                        transactionDate = transaction['date'];
                      }

                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          contentPadding: EdgeInsets.all(8.0),
                          title: Text('${transaction['type']} - ₹${transaction['amount'].toStringAsFixed(2)}'),
                          subtitle: Text(
                              'Date: ${DateFormat.yMMMd().format(transactionDate)}\n'
                                  'Who: ${transaction['who']}, Where: ${transaction['where']}'
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              _removeTransaction(index);
                            },
                          ),
                        ),
                      );
                    },
                  )

                ),
              ],
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Open dialog or new screen to add a transaction
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
