import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:zpi_frontend/src/models/user.dart';
import 'package:zpi_frontend/src/services/apiservice.dart';

import '../services/user_data.dart';

class MemberListAdmin extends StatefulWidget {

  final List<User> members;
  final String groupname;
  final String admin;
  final Function(User) onRemoveMember;

  MemberListAdmin({required this.members, required this.groupname, required this.onRemoveMember, required this.admin});

  @override
  _MemberListAdminState createState() => _MemberListAdminState();
}


class _MemberListAdminState extends State<MemberListAdmin> {
  List<User> localMembers = [];
  late String user;
  late List<String> _allInstruments = [];

  Future<void> _loadAsync() async {
    user = (await UserPreferences.getUserName())!;
    setState(() {}); // Refresh the UI after retrieving the username
  }

  @override
  void initState() {
    super.initState();
    _loadAsync();
    localMembers = widget.members;
    _getAllInstruments();
  }

  Future<void> _getAllInstruments() async{
    try {
      _allInstruments = await ApiService().getAllInstrumentsFromGroup(widget.groupname);
      setState(() {});
    } catch (e) {
      print('Error fetching instruments: $e');
    }
  }

  @override
  void didUpdateWidget(MemberListAdmin oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.members != widget.members) {
      setState(() {
        localMembers = widget.members; // Update local list if parent list changes
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
              leading: CircleAvatar(
                backgroundImage: AssetImage('assets/images/prof_dziekan.jpg'),
              ),
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
                      changeUserInstrument('test1', widget.groupname, member.username, newInstrument);
                      setState(() {
                      });
                    },
                    )
                ],
  ),
              trailing: ElevatedButton(
                onPressed: () => widget.onRemoveMember(localMembers[index]),
                child: Text("Usuń członka")
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
      String receivedString = await ApiService.updateAndGetTokenForGroup(widget.groupname, user);
      showStringDialog(context, receivedString);
    } 
    catch (error) {
      // showErrorDialog(context, error.toString());
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

                      // Show toast instead of snackbar
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

  Future<void> changeUserInstrument(String admin, String groupname, String member, String? instrument) async {

    if(instrument == null){
      
    }
    //TODO better null handling here (instrument!)
    var response = await ApiService().updateUserInstrument(admin, groupname, member, instrument!);

    if(response){
      setState(() {
      
      });
    }else{
      print('Unable to change instrument!');
    }
  }



}



