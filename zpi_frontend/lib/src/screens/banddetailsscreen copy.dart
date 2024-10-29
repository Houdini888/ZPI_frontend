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

    Future<void> removeMember(String username) async{
      print('removing $username from ${widget.group.groupName}');
      bool success = await ApiService.removeMemberfromGroup(username, widget.group.groupName);

      if(success) {
        setState(() {
          users.removeWhere((user) => user == username);

        });
        print('User $username removed successfully');
      }else {
        ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to remove member')),
        );
      }
  }

  @override
  Widget build(BuildContext context) {

    final users = widget.group.users;

    return Scaffold(
      // Using a CustomScrollView to allow for flexible scrolling behavior
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250.0,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.group.groupName,
                style: const TextStyle(
                  fontSize: 32.0,            // Large text size
                  fontWeight: FontWeight.bold, // Bold (thick) text
                  color: Colors.blueGrey
                ),
              ),
              background: Image.asset(
                      'assets/images/band_pf.jpg',
                      fit: BoxFit.cover,
                    ),
                  
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Column(
                    children: [
                      const Text(
                    "Current song: TODO",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const ElevatedButton(
                    onPressed: null,
                     child: Text("Choose the song")
                     ),
                    ],
                  ),

                  //separator
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      // const Expanded(
                      //   flex: 1,
                      //   child: ElevatedButton(
                      //       onPressed: null,
                      //       child: Text("Choose your piece"),
                      //       ),
                      // ),
                      const SizedBox(width: 100),
                      Expanded(
                        child: SizedBox(
                          height: 500,
                          child: MemberList(
                            members: users, 
                            groupname: widget.group.groupName,
                            onRemoveMember: removeMember,
                            ),
                        )
                      ), 
                    ],
                  ),

                  // Add more widgets here in the future
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}


