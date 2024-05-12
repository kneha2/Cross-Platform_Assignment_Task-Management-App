import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:parse_server_sdk/parse_server_sdk.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Parse().initialize(
      'CIPHmYPjrJ1aaqAPDjhxy1rWiq7NNag4sebZ6AgQ',
      'https://parseapi.back4app.com',
      clientKey: 'OxUnGUs7tTjXPQMTlBTe97Y73kSCOnwmF5lMyGl9',
    autoSendSessionId: true,
    debug: true,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QuickTask App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _signUp(BuildContext context) async {
    try {
      final user = ParseUser(_emailController.text, _passwordController.text, _emailController.text)
        ..set('email', _emailController.text); // Set additional fields if needed
      var response = await user.signUp();
      if (response.success) {
        _showSnackBar(context, 'Sign up successful!');
      } else {
        _showSnackBar(context, 'Sign up failed: ${response.error!.message}');
      }
    } catch (e) {
      _showSnackBar(context, 'Sign up failed: $e');
    }
  }

  Future<void> _login(BuildContext context) async {
    try {
      final user = ParseUser(_emailController.text, _passwordController.text, _emailController.text);
      var response = await user.login();
      if (response.success) {
        _showSnackBar(context, 'Login successful!');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => TaskListPage()),
        );
      } else {
        _showSnackBar(context, 'Login failed: ${response.error!.message}');
      }
    } catch (e) {
      _showSnackBar(context, 'Login failed: $e');
    }
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email),
              ),
            ),
            SizedBox(height: 16.0),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: Icon(Icons.lock),
              ),
              obscureText: true,
            ),
            SizedBox(height: 20.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => _signUp(context),
                  child: Text('Sign Up'),
                ),
                ElevatedButton(
                  onPressed: () => _login(context),
                  child: Text('Login'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class Task {
  late String objectId;
  String title;
  DateTime dueDate;
  bool isCompleted;

  Task({required this.title, required this.dueDate, this.isCompleted = false, required this.objectId});
}

class TaskListPage extends StatefulWidget {
  @override
  _TaskListPageState createState() => _TaskListPageState();
}

class _TaskListPageState extends State<TaskListPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _dueDateController = TextEditingController();
  late List<Task> tasks = [];

  @override
  void initState() {
    super.initState();
    _fetchTasks();
  }

  Future<void> _fetchTasks() async {
    final currentUser = await ParseUser.currentUser();
    if (currentUser != null) {
      final queryBuilder = QueryBuilder<ParseObject>(ParseObject('Task'))
        ..whereEqualTo('user', currentUser)
        ..orderByDescending('createdAt');
      final response = await queryBuilder.query();
      if (response.success && response.results != null) {
        setState(() {
          tasks = response.results!.map((taskData) {
            return Task(
              objectId: taskData.objectId!,
              title: taskData.get('title')!,
              dueDate: DateTime.parse(taskData.get('dueDate')!),
              isCompleted: taskData.get('isCompleted') ?? false,
            );
          }).toList();
        });
      } else {
        print('Error fetching tasks: ${response.error!.message}');
      }
    }
  }

  Future<void> _addTask() async {
    try {
      final newTask = Task(title: _titleController.text, dueDate: DateTime.parse(_dueDateController.text), objectId: ''); // Provide a temporary objectId
      final parseObject = ParseObject('Task')
        ..set('title', newTask.title)
        ..set('dueDate', newTask.dueDate.toIso8601String())
        ..set('isCompleted', newTask.isCompleted)
        ..set('user', await ParseUser.currentUser());

      final response = await parseObject.save();
      if (response.success) {
        _fetchTasks();
        _titleController.clear();
        _dueDateController.clear();
      } else {
        print('Error adding task: ${response.error!.message}');
      }
    } catch (e) {
      print('Error adding task: $e');
    }
  }

  Future<void> _toggleTaskStatus(Task task) async {
    try {
      final parseObject = ParseObject('Task')..objectId = task.objectId;
      parseObject.set('isCompleted', !task.isCompleted);
      final response = await parseObject.save();
      if (response.success) {
        _fetchTasks();
      } else {
        print('Error updating task status: ${response.error!.message}');
      }
    } catch (e) {
      print('Error updating task status: $e');
    }
  }

  Future<void> _editTask(Task task, String newTitle, DateTime newDueDate) async {
    try {
      final parseObject = ParseObject('Task')..objectId = task.objectId;
      parseObject.set('title', newTitle);
      parseObject.set('dueDate', newDueDate.toIso8601String());
      final response = await parseObject.save();
      if (response.success) {
        _fetchTasks();
      } else {
        print('Error updating task: ${response.error!.message}');
      }
    } catch (e) {
      print('Error updating task: $e');
    }
  }

  Future<void> _deleteTask(Task task) async {
    try {
      final parseObject = ParseObject('Task')..objectId = task.objectId;
      final response = await parseObject.delete();
      if (response.success) {
        setState(() {
          tasks.remove(task);
        });
      } else {
        print('Error deleting task: ${response.error!.message}');
      }
    } catch (e) {
      print('Error deleting task: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Task List')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];
                return ListTile(
                  title: Text(
                    task.title,
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                      decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  subtitle: Text(
                    'Due Date: ${DateFormat('yyyy-MM-dd').format(task.dueDate)}',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  trailing: Checkbox(
                    value: task.isCompleted,
                    onChanged: (value) => _toggleTaskStatus(task),
                  ),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: Text('Edit Task'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextField(
                                controller: TextEditingController(text: task.title),
                                onChanged: (value) => task.title = value,
                                decoration: InputDecoration(labelText: 'Title'),
                              ),
                              TextField(
                                controller: TextEditingController(text: DateFormat('yyyy-MM-dd').format(task.dueDate)),
                                onChanged: (value) => task.dueDate = DateTime.parse(value),
                                decoration: InputDecoration(labelText: 'Due Date (YYYY-MM-DD)'),
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                _editTask(task, task.title, task.dueDate);
                                Navigator.pop(context);
                              },
                              child: Text('Save'),
                            ),
                            TextButton(
                              onPressed: () {
                                _deleteTask(task);
                                Navigator.pop(context);
                              },
                              child: Text('Delete'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: 'Title',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(width: 10.0),
                Expanded(
                  child: TextField(
                    controller: _dueDateController,
                    decoration: InputDecoration(
                      labelText: 'Due Date (YYYY-MM-DD)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(width: 10.0),
                ElevatedButton(
                  onPressed: _addTask,
                  child: Text('Add Task'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
