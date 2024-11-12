import 'package:flutter/material.dart';
import 'package:zpi_frontend/src/models/group_list.dart';
import 'package:zpi_frontend/src/screens/banddetailsscreen_in_work.dart';
import 'package:zpi_frontend/src/services/apiservice.dart';
import '../services/user_data.dart';
import '../widgets/app_drawer_menu.dart';

class BandListScreen extends StatefulWidget {
  @override
  _BandListScreenState createState() => _BandListScreenState();
}

class _BandListScreenState extends State<BandListScreen> {
  Future<List<GroupList>> _groups = Future.value([]);
  late String user;

  @override
  void initState() {
    super.initState();
    _loadAsync();
  }

  Future<void> _loadAsync() async {
    user = (await UserPreferences.getUserName())!;
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    setState(() {
      _groups = ApiService().fetchAllGroups(user);
    });
  }

  void _showCreateGroupDialog() {
    final TextEditingController groupNameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Create New Group"),
        content: TextField(
          controller: groupNameController,
          decoration: InputDecoration(labelText: "Group Name"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              String groupName = groupNameController.text;
              if (groupName.isNotEmpty) {
                bool success = await ApiService().createGroup(group: groupName, owner: user);
                if (success) {
                  Navigator.pop(context); // Close the dialog
                  _loadGroups(); // Refresh the group list
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Group created successfully!')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to create group.')),
                  );
                }
              }
            },
            child: Text("Create"),
          ),
        ],
      ),
    );
  }

  void _showJoinGroupDialog() {
    final TextEditingController groupCodeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Join Group"),
        content: TextField(
          controller: groupCodeController,
          decoration: InputDecoration(labelText: "Group Code"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              String groupCode = groupCodeController.text;
              if (groupCode.isNotEmpty) {
                bool success = await ApiService().joinGroup(
                  username: user,
                  token: groupCode,
                  instrument: '',
                );
                if (success) {
                  Navigator.pop(context); // Close the dialog
                  _loadGroups(); // Refresh the group list
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Joined group successfully!')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to join group.')),
                  );
                }
              }
            },
            child: Text("Join"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Text('Bands List'),
      ),
      drawer: AppDrawer(),
      body: FutureBuilder<List<GroupList>>(
        future: _groups,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No groups found.'));
          } else {
            final groups = snapshot.data!;
            return ListView(
              children: [
                // List of groups
                ...groups.map((group) => Card(
                  color: Colors.grey,
                  child: InkWell(
                    onTap: () async {
                      final selectedGroup = await ApiService().fetchGroupByName(group.groupName);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => GroupDetailsScreen(
                            group: selectedGroup,
                            admin: user == group.owner,
                          ),
                        ),
                      );
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/images/band_pf.jpg',
                          fit: BoxFit.fill,
                        ),
                        Text(
                          group.groupName,
                          style: const TextStyle(fontSize: 30),
                        ),
                      ],
                    ),
                  ),
                )),
                // Create New Group button
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    onPressed: _showCreateGroupDialog,
                    child: Text('Create New Group'),
                  ),
                ),
              ],
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showJoinGroupDialog,
        child: Icon(Icons.group_add),
        tooltip: 'Join Group',
      ),
    );
  }
}
