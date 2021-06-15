import 'package:flutter/material.dart';

class DialogHelper {

  //Future<bool> deleteConfirm(DismissDirection direction, BuildContext context) async {
  Future<bool> deleteConfirm(BuildContext context) async {    
    return await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirm"),
          content: const Text("Are you sure you want to delete this crew?"),
          actions: <Widget>[
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true), 
              child: const Text("DELETE"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(false), 
              child: const Text("CANCEL"),
            ),
          ],
        );
      }
    );
  }

}