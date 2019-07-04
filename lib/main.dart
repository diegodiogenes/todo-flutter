import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

//passando na main o nosso app que possui como home um statefulWidget
void main() {
  runApp(MaterialApp(
    home: Home(),
  ));
}

// criando o nosso statefulwidget
class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {

  List _toDoList = [];

  final _toDoController = TextEditingController();


  @override
  void initState() {
    super.initState();

    _readFile().then((data){
      setState(() {
        _toDoList = json.decode(data);
      });

    });
  }

  void _addToDo(){
    setState(() {
      Map<String, dynamic> newToDo = Map();
      newToDo["title"] = _toDoController.text;
      _toDoController.text = "";
      newToDo["ok"] = false;
      _toDoList.add(newToDo);
      _writeFile();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Lista de Tarefas"),
        centerTitle: true,
        backgroundColor: Colors.redAccent,
      ),
      body: Column(
        children: <Widget>[
          Container(
            padding: EdgeInsets.fromLTRB(17.0, 1.0, 7.0, 1.0),
            child: Row(
              children: <Widget>[
                Expanded(
                    child:TextField(
                      controller: _toDoController,
                      decoration: InputDecoration(
                        labelText: "Nova Tarefa",
                        labelStyle: TextStyle(color: Colors.redAccent)
                      ),
                    )
                ),
                RaisedButton(
                    color: Colors.redAccent,
                    child: Icon(Icons.add, color: Colors.white,),
                    onPressed: _addToDo
                )
              ],
            ),
          ),
          Expanded(
              child: ListView.builder(
                padding: EdgeInsets.only(top: 10.0),
                itemCount: _toDoList.length,
                itemBuilder: builderItem,
              )
          )
        ],
      ),
    );
  }

  Widget builderItem(context, index){
    return Dismissible(
      key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
      background: Container(
        color: Colors.red,
        child: Align(
          alignment: Alignment(-0.9, 0.0),
          child: Icon(Icons.delete, color: Colors.white,),
        ),
      ),
      direction: DismissDirection.startToEnd,
      child:   CheckboxListTile(
        title: Text(_toDoList[index]["title"]),
        value: _toDoList[index]["ok"],
        secondary: CircleAvatar(
          child: Icon(_toDoList[index]["ok"] ? Icons.check : Icons.error),
        ),
        onChanged: (check){
          setState(() {
            _toDoList[index]["ok"] = check;
            _writeFile();
          });
        },
      ),
    );
  }

  // pegando nosso arquivo json onde estará salvo as nossas tarefas

  Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File("${directory.path}/data.json");
  }

  // método para escrever no arquivo json as novas tarefas

  Future<File> _writeFile() async {
    String data = json.encode(_toDoList);
    final file = await _getFile();
    return file.writeAsString(data);
  }

  // método para ler do arquivo json as tarefas

  Future<String> _readFile() async {
    final file = await _getFile();

    try {
      return file.readAsString();
    } catch (e) {
      return null;
    }
  }
}
