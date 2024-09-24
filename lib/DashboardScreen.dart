import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rentalappadmin/editememberScreen.dart';

import 'ClubDEtails.dart';
import 'adminDEtails.dart';

class AdminDashboard extends StatefulWidget {
  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // Number of tabs
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Admin Dashboard',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.settings, color:Colors.white,size: 26),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => EditAdminScreen()),
                );
              },
            ),
          ],
          backgroundColor: Colors.deepPurple,
          bottom: TabBar(
            labelColor: Colors.white, // Color for the selected tab
            unselectedLabelColor: Colors.grey, // Color for unselected tabs
            indicatorColor: Colors.blue, // Color for the indicator line
            indicatorWeight: 4.0, // Thickness of the indicator line
            tabs: [
              Tab(
                text: 'Members',
                icon: Icon(Icons.people), // Add an icon for the Members tab
              ),
              Tab(
                text: 'Treasury',
                icon: Icon(Icons.attach_money), // Add an icon for the Treasury tab
              ),
            ],
          ),

        ),
        body: TabBarView(
          children: [
            _buildAdminDashboard(), // First tab - Members
            ClubTreasuryScreen(),  // Second tab - Club Treasury
          ],
        ),
      ),
    );
  }

  Widget _buildAdminDashboard() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepPurple.shade200, Colors.deepPurple.shade600],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                final documents = snapshot.data?.docs ?? [];
                final filteredDocs = documents.where((doc) {
                  final data = doc.data();
                  final name = data['name'] ?? '';
                  return name.toLowerCase().contains(searchQuery.toLowerCase());
                }).toList();

                if (filteredDocs.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final doc = filteredDocs[index];
                    final data = doc.data();
                    final name = data['name'] ?? 'No name';
                    final rentalStatus = data['rentalStatus'] ?? 'No status';

                    return _buildMemberCard(
                      context,
                      doc,
                      name,
                      rentalStatus,
                      data['phoneNumber'] ?? 'No phone number',
                      data['rentalAmount'] ?? 'No amount',
                      data['rentalDate'] ?? 'No date',
                      data["pendingCash"] ?? "No pending cash",
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextField(
        onChanged: (value) {
          setState(() {
            searchQuery = value;
          });
        },
        decoration: InputDecoration(
          hintText: 'Search members...',
          prefixIcon: Icon(Icons.search),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(vertical: 15.0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
        ),
      ),
    );
  }

  Widget _buildMemberCard(
      BuildContext context,
      DocumentSnapshot<Map<String, dynamic>> doc,
      String name,
      String rentalStatus,
      String phoneNumber,
      String rentalAmount,
      String rentalDate,
      String pendingCash,
      ) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 10),
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        contentPadding: EdgeInsets.all(16.0),
        leading: CircleAvatar(
          backgroundColor: Colors.deepPurple.shade100,
          child: Icon(Icons.person, color: Colors.deepPurple),
        ),
        title: Text(
          name,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rental Status: $rentalStatus',
              style: TextStyle(color: _getStatusColor(rentalStatus), fontSize: 15),
            ),
            Text('Phone: $phoneNumber', style: TextStyle(fontSize: 13)),
            Text('Amount: $rentalAmount', style: TextStyle(fontSize: 13)),
            Text('Date: $rentalDate', style: TextStyle(fontSize: 13)),
            Text('Pending Cash: $pendingCash', style: TextStyle(fontSize: 13, color: Colors.blueAccent,fontWeight: FontWeight.bold)),
          ],
        ),
        trailing: IconButton(
          icon: Icon(Icons.edit, color: Colors.deepPurple),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EditMemberScreen(
                  docId: doc.id,
                  name: name,
                  phoneNumber: phoneNumber,
                  rentalAmount: rentalAmount,
                  rentalDate: rentalDate,
                  rentalStatus: rentalStatus,
                  userId: '', pendingCash: pendingCash,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 100, color: Colors.white54),
          SizedBox(height: 20),
          Text(
            'No members found.',
            style: TextStyle(fontSize: 18, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return Colors.green;
      case 'not paid':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
