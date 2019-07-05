import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

//passando na main o nosso app que possui como home um statefulWidget
void main() {
  runApp(MaterialApp(
    home: Home(),
    debugShowCheckedModeBanner: false,
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

  Map<String, dynamic> _lastRemoved;

  int _lastRemovedPos;


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

  Future<Null> _refresh() async{
    await Future.delayed(Duration(seconds: 1));
    setState(() {
      _toDoList.sort((a,b){
        if(a["ok"] && !b["ok"]){
          return 1;
        }else if (!a["ok"] && b["ok"]){
          return -1;
        }else{
          return 0;
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Lista de Tarefas"),
        centerTitle: true,
        backgroundColor: Colors.blue[300],
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
                        labelStyle: TextStyle(color: Colors.blue[300])
                      ),
                    )
                ),
                RaisedButton(
                    color: Colors.blue[300],
                    child: Icon(Icons.add, color: Colors.white,),
                    onPressed: _addToDo
                )
              ],
            ),
          ),
          Expanded(
              child: RefreshIndicator(
                  child: ListView.builder(
                    padding: EdgeInsets.only(top: 10.0),
                    itemCount: _toDoList.length,
                    itemBuilder: builderItem,
                  ),
                  onRefresh: _refresh
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
      onDismissed: (direction){
        setState(() {
          _lastRemoved = Map.from(_toDoList[index]);
          _lastRemovedPos = index;
          _toDoList.removeAt(index);

          _writeFile();

          final snack = SnackBar(
              content: Text("Tarefa ${_lastRemoved['title']} foi removida"),
              action: SnackBarAction(
                  label: "Desfazer",
                  onPressed: (){
                    setState(() {
                      _toDoList.insert(_lastRemovedPos, _lastRemoved);
                      _writeFile();
                    });
                  }
              ),
            duration: Duration(seconds: 2),
          );
          Scaffold.of(context).removeCurrentSnackBar();
          Scaffold.of(context).showSnackBar(snack);
        });
      },
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
