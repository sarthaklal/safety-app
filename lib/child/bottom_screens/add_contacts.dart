import 'package:direct_call_plus/direct_call_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:safepath/child/bottom_screens/contact_screen.dart';
import 'package:safepath/components/primary_button.dart';
import 'package:safepath/db/db_services.dart';
import 'package:safepath/model/contacts_model.dart';
import 'package:sqflite/sqflite.dart';

import '../../l10n/app_localizations.dart';

class AddContacts extends StatefulWidget {
  const AddContacts({super.key});

  @override
  State<AddContacts> createState() => _AddContactsState();
}

class _AddContactsState extends State<AddContacts> {
  DatabaseHelper databaseHelper = DatabaseHelper();
  List<TContact>? contactList;
  int count = 0;

  _callNumber(String number) async{
    await DirectCallPlus.makeCall(number);
  }

  void showList() {
    Future<Database> dbFuture = databaseHelper.initializeDatabase();
    dbFuture.then((database) {
      Future<List<TContact>> contactListFuture =
          databaseHelper.getContactList();
      contactListFuture.then((value) {
        setState(() {
          this.contactList = value;
          this.count = value.length;
        });
      });
    });
  }

  void deleteContact(TContact contact) async {
    int result = await databaseHelper.deleteContact(contact.id);
    if(result!=0) {
      Fluttertoast.showToast(msg: 'Contact Removed Succesfully');
      showList();
    }
  }

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((timestamp) {
      showList();
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var localizations = AppLocalizations.of(context);
    contactList ??= [];
    return SafeArea(
      child: Container(
        padding: EdgeInsets.all(12),
        child: Column(
          children: [
            PrimaryButton(
                title: localizations!.translate("Add Emergency Contacts"),
                onPressed: () async {
                  bool result = await Navigator.push(context,
                      MaterialPageRoute(builder: (context) => ContactScreen()));
                  if (result == true) {
                    showList();
                  }
                }),
            Expanded(
              child: ListView.builder(
                  itemCount: count,
                  itemBuilder: (BuildContext context, int index) {
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ListTile(
                          title: Text(contactList![index].name),
                          trailing: Container(
                            width: 100,
                            child: Row(
                              children: [
                                IconButton(
                                    onPressed: () async{
                                      _callNumber(contactList![index].number);
                                    },
                                    icon: Icon(
                                      Icons.call,
                                      color: Colors.green,
                                    )),
                                IconButton(
                                    onPressed: () {
                                      deleteContact(contactList![index]);
                                    },
                                    icon: Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    )),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
            )
          ],
        ),
      ),
    );
  }
}
