import 'dart:io';

import 'package:path/path.dart';
import 'package:zpi_frontend/src/models/group.dart';
import 'package:zpi_frontend/src/models/user.dart';
import 'package:zpi_frontend/src/screens/setlists_main.dart';
import 'package:zpi_frontend/src/widgets/bands_files_list_member.dart';
import 'package:zpi_frontend/src/widgets/memberlist_user.dart';
import 'package:flutter/material.dart';
import 'package:zpi_frontend/src/services/apiservice.dart';
import '../services/user_data.dart';
import 'package:zpi_frontend/src/widgets/statuscircle.dart';
import '../widgets/bands_files_list_admin.dart';
import '../widgets/memberlist_admin.dart';
import '../services/websocket_statusservice_local.dart';
import '../services/websocketservice.dart';
import '../widgets/iconselector.dart';
import '../services/websocket_iconservice.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/setlist.dart';

class GroupDetailsScreen extends StatefulWidget {
  final Group group;
  final bool admin;
  final String adminName;

  const GroupDetailsScreen(
      {super.key,
      required this.group,
      required this.admin,
      required this.adminName});

  @override
  _GroupDetailsScreenState createState() => _GroupDetailsScreenState();
}

class _GroupDetailsScreenState extends State<GroupDetailsScreen> {
  late List<User> users;
  late String groupName;
  late String currentUser;
  late String device;
  late WebSocket_StatusService _ws_StatusService;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    users = widget.group.users;
    groupName = widget.group.groupName;
    _initializeWebSocket();
  }

  Future<void> _loadAsync() async {
    currentUser = (await UserPreferences.getUserName())!;
  }

  Future<void> _initializeWebSocket() async {
    currentUser = (await UserPreferences.getUserName())!;
    device = (await UserPreferences.getSessionCode())!;
    _ws_StatusService = WebSocket_StatusService(
      username: currentUser,
      group: groupName,
      device: device,
    );

    await _ws_StatusService.initialize();

    setState(() {
      _isInitialized = true;
    });
  }

  Future<void> removeMember(User user) async {
    bool success = await ApiService().removeMemberFromGroup(
        username: user.username,groupName: widget.group.groupName);

    if (success) {
      setState(() {
        users.removeWhere((removed) => removed == user);
      });
    } 
  }

  @override
  Widget build(BuildContext context) {

    if (!_isInitialized) {
      return Scaffold(
        appBar: AppBar(
          title: Text("Band details"),
          automaticallyImplyLeading: false,
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

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
                  Tab(text: "Files"),
                  Tab(text: "Concerts"),
                ],
              ),
            ),
          ),
        ),
        body: TabBarView(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton(
                      onPressed: (){
                          String instrument = users.firstWhere((user) => user.username == currentUser).instrument;
                          UserPreferences.saveActiveGroup(groupName);
                          UserPreferences.saveActiveGroupInstrument(instrument);

                          WebSocketService().disconnect();
                          WebSocketService().connect(currentUser, groupName);

                      },
                      child: const Text("Activate Group"),
                    ),
                    const SizedBox(height: 24),
                    // Member List Section
                    SizedBox(
                      height: 500,
                      child: widget.admin
                          ? MemberListAdmin(
                              members: users,
                              groupname: widget.group.groupName,
                              onRemoveMember: removeMember,
                              admin: widget.adminName,
                              ws_StatusService: _ws_StatusService,
                              loggedInUsername: currentUser,
                            )
                          : MemberListUser(
                              members: users,
                              groupname: widget.group.groupName,
                              onRemoveMember: removeMember,
                              admin: widget.adminName
                              ),
                    ),
                    
                  ],
                ),
              ),
            ),
            widget.admin
                ? BandsFilesListAdmin(group: widget.group)
                : BandsFilesListMember(group: widget.group),
            widget.admin
                ?Setlists(band: widget.group.groupName,)
                // ? ConcertPanelAdmin(group: widget.group)
                : Text("data"),
          ],
        ),
      ),
    );
  }
}
