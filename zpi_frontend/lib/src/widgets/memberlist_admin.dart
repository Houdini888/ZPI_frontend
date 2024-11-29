import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:zpi_frontend/src/models/user.dart';
import 'package:zpi_frontend/src/services/apiservice.dart';
import 'package:zpi_frontend/src/services/websocket_statusservice.dart';
import 'package:zpi_frontend/src/services/websocketservice.dart';
import 'package:zpi_frontend/src/services/websocket_statusservice_local.dart';
import 'package:zpi_frontend/src/widgets/statuscircle.dart';

import '../services/user_data.dart';

class MemberListAdmin extends StatefulWidget {

  final List<User> members;
  final String groupname;
  final String admin;
  final Function(User) onRemoveMember;

  final WebSocket_StatusService ws_StatusService;
  final String loggedInUsername;


  MemberListAdmin({
    required this.members,
    required this.groupname,
    required this.onRemoveMember,
    required this.admin,
    required this.ws_StatusService, // Added
    required this.loggedInUsername, // Added
  });

  @override
  _MemberListAdminState createState() => _MemberListAdminState();
}


class _MemberListAdminState extends State<MemberListAdmin> {
  List<User> localMembers = [];
  late String user;
  late List<String> _allInstruments = [];
  bool _isUserLoaded = false;
  bool _currentUserReady = false;

  Future<void> _loadAsync() async {
  user = (await UserPreferences.getUserName())!;

  setState(() {
    _isUserLoaded = true;
  });
}

  @override
  void initState() {
    super.initState();
    _loadAsync();
    localMembers = widget.members;
    _getAllInstruments();
    _listenToStatusUpdates();
  }

  Future<void> _getAllInstruments() async{
    try {
      _allInstruments = await ApiService().getAllInstrumentsFromGroup(widget.groupname, user);
      setState(() {});
    } catch (e) {
      print('Error fetching instruments: $e');
    }
  }

  void _listenToStatusUpdates() {
    widget.ws_StatusService.statusStream.listen((statuses) {
      if (statuses.containsKey(user)) {
        bool isReady = statuses[user]!;
        if (isReady && !_currentUserReady) {
          setState(() {
            _currentUserReady = true;
          });
        } else if (!isReady && _currentUserReady) {
          setState(() {
            _currentUserReady = false;
          });
        }
      }
    });
  }

  @override
  void didUpdateWidget(MemberListAdmin oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.members != widget.members) {
      setState(() {
        localMembers = widget.members;
      });
    }
  }

  @override
  Widget build(BuildContext context) {

    if (!_isUserLoaded) {
      return Scaffold(
        appBar: AppBar(
          title: Text("Band members"),
          automaticallyImplyLeading: false,
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

  return Scaffold(
    appBar: AppBar(
      title: Text("Band members"),
      automaticallyImplyLeading: false,
    ),
    body: ListView.builder(
      itemCount: localMembers.length+1,
      itemBuilder: (context, index) {
        if (index < localMembers.length) {
          final member = localMembers[index];
          return Column(
            children: <Widget> [
              ListTile(
              leading: StatusCircle(username: member.username, ws_StatusService: widget.ws_StatusService, loggedInUsername: user,),
              title: Row(
                children: [
                  Text(
                      member.username,
                      style: member.username == widget.admin?TextStyle(fontWeight: FontWeight.bold, color: Colors.amber): TextStyle(fontWeight: FontWeight.bold),
                    ),
                  SizedBox(width: 10,),
                  DropdownButton(
                    value: member.instrument,
                    items: _allInstruments.map((String instrument) {
                      return DropdownMenuItem<String>(
                        value: instrument,
                        child: Text(instrument),
                      );
                    }).toList(),
                    onChanged: (String? newInstrument) {
                      changeUserInstrument(widget.admin, widget.groupname, member, newInstrument);
                      setState(() {
                      });
                    },
                    ),
                ],
              ),
              trailing: ElevatedButton(
                onPressed: () => widget.onRemoveMember(localMembers[index]),
                child: Text("Delete")
                ),
              onTap: () {}
            ),
            Divider(),
            ],
          );
        } else {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: (){
                fetchStringFromBackend(context);
              }, 
              child: Text("Generuj token")),
          );
        }
      }
    ),
  );
}

Future<void> fetchStringFromBackend(BuildContext context) async {
    try {
      String receivedString = await ApiService().updateToken(group: widget.groupname, owner: user);
      showStringDialog(context, receivedString);
    } 
    catch (error) {
      print(error);
    }
  }


  void showStringDialog(BuildContext context, String data) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Token'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              bool isCopied = false;

              return Row(
                children: [
                  Expanded(
                    child: SelectableText(data, style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  IconButton(
                    icon: Icon(isCopied ? Icons.check : Icons.copy, color: isCopied ? Colors.green : null),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: data));
                      setState(() {
                        isCopied = true;
                      });

                      Fluttertoast.showToast(
                        msg: 'Token copied to clipboard',
                        toastLength: Toast.LENGTH_SHORT,
                        gravity: ToastGravity.BOTTOM,
                      );
                    },
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> changeUserInstrument(String admin, String groupname, User member, String? instrument) async {

    if(instrument == null){
      
    }
    //TODO better null handling here (instrument!)
    var response = await ApiService().updateUserInstrument(admin, groupname, member.username, instrument!);

    if(response){
      final activeGroup = await UserPreferences.getActiveGroup();
      if(member.username == user && activeGroup == groupname)
      {
        UserPreferences.saveActiveGroupInstrument(instrument);
      }
      setState(() {
        member.instrument = instrument;
    });
    }else{
      print('Unable to change instrument!');
    }
  }



}



