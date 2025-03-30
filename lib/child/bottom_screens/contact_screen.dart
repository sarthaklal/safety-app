import 'package:contacts_service/contacts_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:safepath/db/db_services.dart';
import 'package:safepath/model/contacts_model.dart';
import 'package:safepath/utils/constants.dart';

import '../../l10n/app_localizations.dart';

class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  List<Contact> contacts = [];
  List<Contact> contactsFiltered = [];
  DatabaseHelper _databaseHelper = DatabaseHelper();

  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    askPermission();
  }

  String flattenPhoneNumber(String phoneStr) {
    return phoneStr.replaceAllMapped(RegExp(r'^(\+)|\D'), (Match m) {
      return m[0] == "+" ? "+" : "";
    });
  }

  filterContacts() {
    List<Contact> _contacts = [];
    _contacts.addAll(contacts);
    if (searchController.text.isNotEmpty) {
      _contacts.retainWhere((element) {
        String searchTerm = searchController.text.toLowerCase();
        String searchTermFlatter = flattenPhoneNumber(searchTerm);
        String contactName = element.displayName!.toLowerCase();
        bool nameMatch = contactName.contains(searchTerm);
        if (nameMatch == true) {
          return true;
        }
        if (searchTermFlatter.isEmpty) {
          return false;
        }
        var phone = element.phones!.firstWhere((element) {
          String phoneFlatter = flattenPhoneNumber(element.value!);
          return phoneFlatter.contains(searchTermFlatter);
        });
        return phone.value != null;
      });
    }
    setState(() {
      contactsFiltered = _contacts;
    });
  }

  Future<void> askPermission() async {
    PermissionStatus permissionStatus = await getContactsPermission();
    if (permissionStatus == PermissionStatus.granted) {
      getAllContacts();
      searchController.addListener(() {
        filterContacts();
      });
    } else {
      handInvalidPermissions(permissionStatus);
    }
  }

  handInvalidPermissions(PermissionStatus permissionStatus) {
    if (permissionStatus == PermissionStatus.denied) {
      dialogueBox(context, 'Access to contacts denied by user');
    } else if (permissionStatus == PermissionStatus.permanentlyDenied) {
      dialogueBox(context, 'Access to contacts permanently denied by user');
    }
  }

  Future<PermissionStatus> getContactsPermission() async {
    PermissionStatus permission = await Permission.contacts.status;
    if (permission != PermissionStatus.granted &&
        permission != PermissionStatus.permanentlyDenied) {
      PermissionStatus permissionStatus = await Permission.contacts.request();
      return permissionStatus;
    } else {
      return permission;
    }
  }

  getAllContacts() async {
    List<Contact> _contacts = await ContactsService.getContacts(
      withThumbnails: false,
    );
    setState(() {
      contacts = _contacts;
    });
  }

  @override
  Widget build(BuildContext context) {
    var localizations = AppLocalizations.of(context);
    bool isSearching = searchController.text.isNotEmpty;
    bool listItemExist = (contactsFiltered.length > 0 || contacts.length > 0);
    return Scaffold(
      body: contacts.length == 0
          ? Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      autofocus: false,
                      controller: searchController,
                      decoration: InputDecoration(
                        labelText: localizations!.translate("Search Contacts"),
                        prefixIcon: Icon(Icons.search),
                      ),
                    ),
                  ),
                  listItemExist == true
                      ? Expanded(
                          child: ListView.builder(
                            itemCount: isSearching == true
                                ? contactsFiltered.length
                                : contacts.length,
                            itemBuilder: (BuildContext context, int index) {
                              Contact contact = isSearching == true
                                  ? contactsFiltered[index]
                                  : contacts[index];
                              return ListTile(
                                title: Text(contact.displayName!),
                                subtitle: Text(contact.phones!.first.value!),
                                leading: CircleAvatar(
                                  backgroundColor: primaryColor,
                                  child: Text(contact.initials()),
                                ),
                                onTap: () {
                                  if (contact.phones!.length > 0) {
                                    final String phoneNo =
                                        contact.phones!.elementAt(0).value!;
                                    final String name = contact.displayName!;
                                    _addContact(TContact(phoneNo, name));
                                  }
                                  else {
                                    Fluttertoast.showToast(msg: 'Contact already exists');
                                  }
                                },
                              );
                            },
                          ),
                        )
                      : Container(
                          child: Text("Searching"),
                        ),
                ],
              ),
            ),
    );
  }

  void _addContact(TContact newContact) async{
    int result = await _databaseHelper.insertContact(newContact);
    if(result!=0)
      {
        Fluttertoast.showToast(msg: 'Contact added succesfully');
      }
    else
      {
        Fluttertoast.showToast(msg: 'Failed to add contact');
      }
    Navigator.of(context).pop(true);
  }

}
