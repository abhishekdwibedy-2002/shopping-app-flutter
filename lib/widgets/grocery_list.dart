import 'package:flutter/material.dart';
import 'package:shoppingapp/data/categories.dart';
import 'package:shoppingapp/models/grocery_item.dart';
import 'package:shoppingapp/widgets/new_item.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class GroceryList extends StatefulWidget {
  const GroceryList({super.key});

  @override
  State<GroceryList> createState() => _GroceryItemState();
}

class _GroceryItemState extends State<GroceryList> {
  List<GroceryItem> groceryItem = [];
  var isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    loadItems();
  }

  void loadItems() async {
    final url = Uri.https('flutterproject-639cc-default-rtdb.firebaseio.com',
        'shopping-list.json');
    final response = await http.get(url);


    if (response.statusCode >= 400) {
      setState(() {
        error = 'Failed To Fetch Data !! Please Try Again Later...';
      });
    }

    if(response.body == 'null') {
      setState(() {
        isLoading=false;
      });
      return ;
    }

    final Map<String, dynamic> listData = json.decode(response.body);
    final List<GroceryItem> loadedItem = [];
    for (final item in listData.entries) {
      final category = categories.entries
          .firstWhere(
              (element) => element.value.title == item.value['category'])
          .value;
      loadedItem.add(GroceryItem(
          id: item.key,
          name: item.value['name'],
          quantity: item.value['quantity'],
          category: category));
    }
    setState(() {
      groceryItem = loadedItem;
      isLoading = false;
    });
  }

  void addItem() async {
    final newItem = await Navigator.of(context).push<GroceryItem>(
      MaterialPageRoute(
        builder: (ctx) => const NewItem(),
      ),
    );
    loadItems();
    if (newItem == null) {
      return;
    }

    setState(() {
      groceryItem.add(newItem);
    });
  }

  void removeItem(GroceryItem item) async {
    final index = groceryItem.indexOf(item);
    setState(() {
      groceryItem.remove(item);
    });
    final url = Uri.https('flutterproject-639cc-default-rtdb.firebaseio.com',
        'shopping-list/${item.id}.json');
    var response = await http.delete(url);

    if (response.statusCode >= 400) {
      setState(() {
        groceryItem.insert(index, item);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content = const Center(child: Text('No Items Added Yet...'));

    if (isLoading) {
      content = const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (groceryItem.isNotEmpty) {
      content = ListView.builder(
        itemCount: groceryItem.length,
        itemBuilder: (ctx, index) => Dismissible(
          onDismissed: (direction) {
            removeItem(groceryItem[index]);
          },
          key: ValueKey(groceryItem[index].id),
          child: ListTile(
            title: Text(groceryItem[index].name),
            leading: Container(
              height: 20,
              width: 20,
              color: groceryItem[index].category.color,
            ),
            trailing: Text(
              groceryItem[index].quantity.toString(),
            ),
          ),
        ),
      );
    }

    if (error != null) {
      content = Center(child: Text(error!));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Groceries'),
        actions: [IconButton(onPressed: addItem, icon: const Icon(Icons.add))],
      ),
      body: content,
    );
  }
}
