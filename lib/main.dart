import 'dart:convert';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/date_symbol_data_local.dart';

//passando na main o nosso app que possui como home um statefulWidget
void main() {
  runApp(MaterialApp(
    home: Home(),
    theme: ThemeData(
      hintColor: Colors.blue[300],
    ),
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

  GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  Map<String, dynamic> _lastRemoved;

  int _lastRemovedPos;

  String _deadline;

  @override
  void initState() {
    super.initState();

    initializeDateFormatting();

    _readFile().then((data) {
      setState(() {
        _toDoList = json.decode(data);
      });
    });
  }

  void _addToDo() {
    setState(() {
      if(_formKey.currentState.validate()){
        Map<String, dynamic> newToDo = Map();
        newToDo["title"] = _toDoController.text;
        _toDoController.text = "";
        newToDo["ok"] = false;
        newToDo["deadline"] = _deadline;
        _toDoList.add(newToDo);
        _writeFile();
        Navigator.of(context).pop();
      }
    });
  }

  Text _taskDone(index, {bool check}) {
    if (check) {
      return Text(
        _toDoList[index]["title"],
        style: TextStyle(decoration: TextDecoration.lineThrough),
      );
    } else {
      return Text(_toDoList[index]["title"]);
    }
  }

  Future<Null> _refresh() async {
    await Future.delayed(Duration(seconds: 1));
    setState(() {
      _toDoList.sort((a, b) {
        if (a["ok"] && !b["ok"]) {
          return 1;
        } else if (!a["ok"] && b["ok"]) {
          return -1;
        } else {
          return 0;
        }
      });
    });
  }

  Future<void> _inputTask() async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Adicionar Nova Tarefa'),
          content: SingleChildScrollView(
            child: Form(
                key: _formKey,
                child: ListBody(
                  children: <Widget>[
                    Padding(
                      padding: EdgeInsets.only(top: 5.0),
                      child: TextFormField(
                        decoration: InputDecoration(
                            labelText: "Inserir Nova Tarefa",
                            labelStyle: TextStyle(color: Colors.blue[300]),
                            border: OutlineInputBorder()),
                        controller: _toDoController,
                        validator: (value) {
                          if (value.isEmpty) {
                            return "Insira o nome de uma tarefa";
                          }
                        },
                      ))
                  ],
                )),
          ),
          actions: <Widget>[
            RaisedButton(
                color: Colors.blue[300],
                child: Icon(
                  Icons.calendar_today,
                  color: Colors.white,
                ),
                onPressed: _selectDeadLine),
            RaisedButton(
                color: Colors.blue[300],
                child: Text("ADD"),
                textColor: Colors.white,
                onPressed: _addToDo)
          ],
        );
      },
    );
  }

  Future _selectDeadLine() async {
    DateTime picked = await showDatePicker(
        context: context,
        initialDate: new DateTime.now(),
        firstDate: new DateTime(2019),
        lastDate: new DateTime(2025));
    if (picked != null)
      setState(() {
        final f = new DateFormat.yMMMd('pt_BR');
        _deadline = f.format(picked);
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
          Expanded(
              child: RefreshIndicator(
                  child: ListView.builder(
                    padding: EdgeInsets.only(top: 10.0),
                    itemCount: _toDoList.length,
                    itemBuilder: builderItem,
                  ),
                  onRefresh: _refresh)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
          child: Icon(Icons.add),
          onPressed: () {
            _inputTask();
          }),
    );
  }

  Widget builderItem(context, index) {
    return Dismissible(
      key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
      background: Container(
        color: Colors.red,
        child: Align(
          alignment: Alignment(-0.9, 0.0),
          child: Icon(
            Icons.delete,
            color: Colors.white,
          ),
        ),
      ),
      direction: DismissDirection.startToEnd,
      child: CheckboxListTile(
        title: _taskDone(index, check: _toDoList[index]["ok"]),
        subtitle: Text(_toDoList[index]["deadline"]),
        value: _toDoList[index]["ok"],
        secondary: CircleAvatar(
          child: Icon(_toDoList[index]["ok"] ? Icons.check : Icons.error),
        ),
        onChanged: (check) {
          setState(() {
            _toDoList[index]["ok"] = check;
            _taskDone(index, check: _toDoList[index]["ok"]);
            _writeFile();
          });
        },
      ),
      onDismissed: (direction) {
        setState(() {
          _lastRemoved = Map.from(_toDoList[index]);
          _lastRemovedPos = index;
          _toDoList.removeAt(index);

          _writeFile();

          final snack = SnackBar(
            content: Text("Tarefa ${_lastRemoved['title']} foi removida"),
            action: SnackBarAction(
                label: "Desfazer",
                onPressed: () {
                  setState(() {
                    _toDoList.insert(_lastRemovedPos, _lastRemoved);
                    _writeFile();
                  });
                }),
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
    return File("${directory.path}/tasks2.json");
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
