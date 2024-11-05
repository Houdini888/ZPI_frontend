import 'package:zpi_frontend/src/models/group.dart';
import 'package:zpi_frontend/src/widgets/memberlist.dart';
import 'package:flutter/material.dart';
import 'package:zpi_frontend/src/services/apiservice.dart';

class GroupDetailsScreen extends StatefulWidget {
  final Group group;

  const GroupDetailsScreen({super.key, required this.group});

  @override
  _GroupDetailsScreenState createState() => _GroupDetailsScreenState();
}

class _GroupDetailsScreenState extends State<GroupDetailsScreen> {
  late List<dynamic> users;

  @override
  void initState() {
    super.initState();
    users = widget.group.users;
  }

  Future<void> removeMember(String username) async {
    print('Removing $username from ${widget.group.groupName}');
    bool success = await ApiService.removeMemberfromGroup(
        username, widget.group.groupName);

    if (success) {
      setState(() {
        users.removeWhere((user) => user == username);
      });
      print('User $username removed successfully');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to remove member')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      initialIndex: 0,
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.group.groupName,
            style: const TextStyle(
              fontSize: 32.0,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey,
            ),
          ),
          flexibleSpace: Stack(
            children: [
              Image.asset(
              'assets/images/band_pf.jpg',
                fit: BoxFit.cover,
                width: double.infinity,
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withOpacity(0.7),
                      Colors.transparent,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),

            ],

          ),
            bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48.0),
            child: Container(
              color: Colors.black87, // Background color for the TabBar
              child: const TabBar(
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                indicatorColor: Colors.blueGrey,
                tabs: [
                  Tab(text: "Details"),
                  Tab(text: "Empty Tab 1"),
                  Tab(text: "Empty Tab 2"),
                ],
              ),
            ),
          ),
        ),
        body: TabBarView(
          children: <Widget>[
            // First Tab: All Functionalities
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Current Song Section
                    const Text(
                      "Current song: TODO",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const ElevatedButton(
                      onPressed: null,
                      child: Text("Choose the song"),
                    ),
                    const SizedBox(height: 24),

                    // Member List Section
                    SizedBox(
                      height: 500,
                      child: MemberList(
                        members: users,
                        groupname: widget.group.groupName,
                        onRemoveMember: removeMember,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Second Tab: Empty
            const Center(child: Text("Empty Tab 1")),
            // Third Tab: Empty
            const Center(child: Text("Empty Tab 2")),
          ],
        ),
      ),
    );
  }
}
