import 'package:flutter/material.dart';

class DialogHelper {

  Future<bool> deleteConfirm(BuildContext context, String itemToDelete) async {
    return await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirm"),
          content: Text("Are you sure you want to delete this $itemToDelete?"),
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
