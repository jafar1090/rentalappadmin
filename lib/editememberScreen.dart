import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'logingpage.dart';

class EditMemberScreen extends StatefulWidget {
  final String docId;
  final String name;
  final String phoneNumber;
  final String rentalAmount;
  final String rentalDate;
  final String rentalStatus;
  final String pendingCash; // New field for pending cash

  EditMemberScreen({
    required this.docId,
    required this.name,
    required this.phoneNumber,
    required this.rentalAmount,
    required this.rentalDate,
    required this.rentalStatus,
    required this.pendingCash, required String userId, // New field for pending cash
  });

  @override
  _EditMemberScreenState createState() => _EditMemberScreenState();
}

class _EditMemberScreenState extends State<EditMemberScreen> {
  final _nameController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _rentalAmountController = TextEditingController();
  final _rentalDateController = TextEditingController();
  final _pendingCashController = TextEditingController(); // New controller
  String _rentalStatus = '';

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.name;
    _phoneNumberController.text = widget.phoneNumber;
    _rentalAmountController.text = widget.rentalAmount;
    _rentalDateController.text = widget.rentalDate;
    _rentalStatus = widget.rentalStatus;
    _pendingCashController.text = widget.pendingCash; // Initialize pending cash
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Member'),
        backgroundColor: Colors.blueAccent,
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _logout, // Call the logout function
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Edit Member Details',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20),
              _buildTextField(
                controller: _nameController,
                label: 'Name',
                icon: Icons.person,
              ),
              _buildTextField(
                controller: _phoneNumberController,
                label: 'Phone Number',
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
              ),
              _buildTextField(
                controller: _rentalAmountController,
                label: 'Rental Amount',
                icon: Icons.attach_money,
                keyboardType: TextInputType.number,
              ),
              _buildTextField(
                controller: _rentalDateController,
                label: 'Rental Date',
                icon: Icons.calendar_today,
                keyboardType: TextInputType.datetime,
              ),
              _buildTextField(
                controller: _pendingCashController, // New field for pending cash
                label: 'Pending Cash',
                icon: Icons.money_off,
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 20),
              _buildStatusTextField(),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _updateMember,
                child: Text('Update'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: EdgeInsets.symmetric(vertical: 15.0),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
        keyboardType: keyboardType,
      ),
    );
  }

  Widget _buildStatusTextField() {
    return TextField(
      readOnly: true,
      controller: TextEditingController(text: _rentalStatus),
      decoration: InputDecoration(
        labelText: 'Rental Status',
        prefixIcon: Icon(Icons.info),
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                Icons.check_circle, // Paid icon
                color: _rentalStatus == 'Paid' ? Colors.blueAccent : Colors.grey,
              ),
              onPressed: () => _updateStatus('Paid'),
            ),
            IconButton(
              icon: Icon(
                Icons.cancel, // Not Paid icon
                color: _rentalStatus == 'Not Paid' ? Colors.blueAccent : Colors.grey,
              ),
              onPressed: () => _updateStatus('Not Paid'),
            ),
          ],
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
    );
  }

  void _updateStatus(String status) {
    setState(() {
      _rentalStatus = status;
    });
  }

  void _updateMember() async {
    if (_nameController.text.isEmpty ||
        _phoneNumberController.text.isEmpty ||
        _rentalAmountController.text.isEmpty ||
        _rentalDateController.text.isEmpty ||
        _pendingCashController.text.isEmpty || // Check pending cash
        _rentalStatus.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill all fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    await FirebaseFirestore.instance.collection('users').doc(widget.docId).update({
      'name': _nameController.text,
      'phoneNumber': _phoneNumberController.text,
      'rentalAmount': _rentalAmountController.text,
      'rentalDate': _rentalDateController.text,
      'pendingCash': _pendingCashController.text, // Update pending cash
      'rentalStatus': _rentalStatus,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Member details updated successfully'),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.pop(context);
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => LoginScreen()),
          (route) => false,
    );
  }
}
