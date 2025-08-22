import 'dart:convert';
import 'dart:io';

// ----------------- User Class -----------------
class User {
  String username;
  String password;

  User(this.username, this.password);

  Map<String, dynamic> toJson() => {
        'username': username,
        'password': password,
      };

  factory User.fromJson(Map<String, dynamic> json) {
    return User(json['username'], json['password']);
  }
}

// ----------------- User Manager -----------------
class UserManager {
  final String filePath = 'users.json';
  List<User> users = [];

  UserManager() {
    loadUsers();
  }

  void loadUsers() {
    try {
      final file = File(filePath);
      if (file.existsSync()) {
        final data = jsonDecode(file.readAsStringSync());
        users = (data as List).map((u) => User.fromJson(u)).toList();
      }
    } catch (e) {
      print("Error loading users: $e");
    }
  }

  void saveUsers() {
    final file = File(filePath);
    file.writeAsStringSync(jsonEncode(users.map((u) => u.toJson()).toList()));
  }

  bool register(String username, String password) {
    if (users.any((u) => u.username == username)) {
      print("❌ Username already exists!");
      return false;
    }
    users.add(User(username, password));
    saveUsers();
    print("✅ Registered successfully!");
    return true;
  }

  User? login(String username, String password) {
    for (var u in users) {
      if (u.username == username && u.password == password) {
        print("✅ Login successful! Welcome $username.\n");
        return u;
      }
    }
    print("❌ Invalid username or password.");
    return null;
  }
}

// ----------------- Task Class -----------------
class Task {
  static int _idCounter = 1;
  int id;
  String title;
  String description;
  String dueDate;
  String priority;
  String status;
  String owner; // username who owns the task

  Task(this.title, this.description, this.dueDate, this.priority, this.owner,
      {this.status = "Pending"})
      : id = _idCounter++;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'dueDate': dueDate,
        'priority': priority,
        'status': status,
        'owner': owner,
      };

  factory Task.fromJson(Map<String, dynamic> json) {
    var task = Task(
      json['title'],
      json['description'],
      json['dueDate'],
      json['priority'],
      json['owner'],
      status: json['status'],
    );
    task.id = json['id'];
    if (task.id >= _idCounter) {
      _idCounter = task.id + 1;
    }
    return task;
  }

  @override
  String toString() {
    return "[$id] $title | $priority | $status | Due: $dueDate";
  }
}

// ----------------- Task Manager -----------------
class TaskManager {
  final String filePath = 'tasks.json';
  List<Task> tasks = [];

  TaskManager() {
    loadTasks();
  }

  void loadTasks() {
    try {
      final file = File(filePath);
      if (file.existsSync()) {
        final data = jsonDecode(file.readAsStringSync());
        tasks = (data as List).map((t) => Task.fromJson(t)).toList();
      }
    } catch (e) {
      print("Error loading tasks: $e");
    }
  }

  void saveTasks() {
    final file = File(filePath);
    file.writeAsStringSync(jsonEncode(tasks.map((t) => t.toJson()).toList()));
  }

  void createTask(User user) {
    stdout.write("Enter Task Title: ");
    String title = stdin.readLineSync() ?? "";
    stdout.write("Enter Description: ");
    String desc = stdin.readLineSync() ?? "";
    stdout.write("Enter Due Date (YYYYMMDD): ");
    String dueDate = stdin.readLineSync() ?? "";
    stdout.write("Enter Priority (High/Medium/Low): ");
    String priority = stdin.readLineSync() ?? "";

    tasks.add(Task(title, desc, dueDate, priority, user.username));
    saveTasks();
    print("✅ Task Created Successfully!");
  }

  void listTasks(User user) {
    var userTasks = tasks.where((t) => t.owner == user.username).toList();
    if (userTasks.isEmpty) {
      print("No tasks available.");
      return;
    }
    print("\n---- Your Tasks ----");
    for (var t in userTasks) {
      print(t);
    }
  }

  void updateTask(User user) {
    listTasks(user);
    stdout.write("Enter Task ID to update: ");
    int? id = int.tryParse(stdin.readLineSync() ?? "");
    var task = tasks.firstWhere(
        (t) => t.id == id && t.owner == user.username,
        orElse: () => Task("", "", "", "", user.username));
    if (task.title == "") {
      print("❌ Task not found.");
      return;
    }

    stdout.write("Update Status (Pending/Done): ");
    task.status = stdin.readLineSync() ?? task.status;
    saveTasks();
    print("✅ Task Updated!");
  }

  void deleteTask(User user) {
    listTasks(user);
    stdout.write("Enter Task ID to delete: ");
    int? id = int.tryParse(stdin.readLineSync() ?? "");
    tasks.removeWhere((t) => t.id == id && t.owner == user.username);
    saveTasks();
    print("✅ Task Deleted!");
  }

  void searchTask(User user) {
    stdout.write("Enter keyword or ID: ");
    String input = stdin.readLineSync() ?? "";
    var userTasks = tasks.where((t) => t.owner == user.username).toList();
    var results = userTasks.where((t) =>
        t.title.contains(input) ||
        t.description.contains(input) ||
        t.id.toString() == input);
    if (results.isEmpty) {
      print("No matching tasks found.");
    } else {
      print("\n--- Search Results ---");
      for (var r in results) {
        print(r);
      }
    }
  }

  void sortTasks(User user) {
    var userTasks = tasks.where((t) => t.owner == user.username).toList();
    if (userTasks.isEmpty) {
      print("No tasks to sort.");
      return;
    }
    print("Sort by: 1. Deadline  2. Priority  3. ID");
    String? choice = stdin.readLineSync();
    if (choice == "1") {
      userTasks.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    } else if (choice == "2") {
      userTasks.sort((a, b) => a.priority.compareTo(b.priority));
    } else {
      userTasks.sort((a, b) => a.id.compareTo(b.id));
    }
    print("\n--- Sorted Tasks ---");
    for (var t in userTasks) {
      print(t);
    }
  }
}

// ----------------- Smart Task Manager Console -----------------
void smartTaskManager(User user, TaskManager taskManager) {
  print("📋 Smart Task Manager ready for ${user.username}!");

  while (true) {
    print("\n--- Task Manager Menu ---");
    print("1. Create Task");
    print("2. View Tasks");
    print("3. Update Task");
    print("4. Delete Task");
    print("5. Search Task");
    print("6. Sort Tasks");
    print("7. Logout");
    stdout.write(">> ");
    String? choice = stdin.readLineSync();

    if (choice == "1") {
      taskManager.createTask(user);
    } else if (choice == "2") {
      taskManager.listTasks(user);
    } else if (choice == "3") {
      taskManager.updateTask(user);
    } else if (choice == "4") {
      taskManager.deleteTask(user);
    } else if (choice == "5") {
      taskManager.searchTask(user);
    } else if (choice == "6") {
      taskManager.sortTasks(user);
    } else if (choice == "7") {
      print("👋 Logged out. Returning to main menu...");
      break;
    } else {
      print("Invalid choice.");
    }
  }
}

// ----------------- Main Program -----------------
void main() {
  UserManager userManager = UserManager();
  TaskManager taskManager = TaskManager();

  while (true) {
    print("\nWelcome to Smart Task Manager");
    print("1. Register");
    print("2. Login");
    print("3. Exit");
    stdout.write(">> ");
    String? choice = stdin.readLineSync();

    if (choice == "1") {
      stdout.write("Enter Username: ");
      String username = stdin.readLineSync() ?? "";
      stdout.write("Enter Password: ");
      String password = stdin.readLineSync() ?? "";
      userManager.register(username, password);

    } else if (choice == "2") {
      stdout.write("Enter Username: ");
      String username = stdin.readLineSync() ?? "";
      stdout.write("Enter Password: ");
      String password = stdin.readLineSync() ?? "";
      User? currentUser = userManager.login(username, password);

      if (currentUser != null) {
        smartTaskManager(currentUser, taskManager);
      }

    } else if (choice == "3") {
      print("Goodbye!");
      break;
    } else {
      print("Invalid choice, try again.");
    }
  }
}
