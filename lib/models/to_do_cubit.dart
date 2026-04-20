import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:to_do_list/models/database_helper.dart';

import '../modules/archived_tasks.dart';
import '../modules/done_tasks.dart';
import '../modules/new_tasks.dart';

part 'to_do_state.dart';

class ToDoCubit extends Cubit<ToDoState> {
  ToDoCubit() : super(ToDoInitial());

  bool isBottomSheet = false;
  IconData addTaskIcon = Icons.edit;

  // الإصلاح هنا: إزالة الـ ? وجعل القوائم غير قابلة للـ null
  List<Map<String, dynamic>> taskList = [];
  List<Map<String, dynamic>> newTasks = [];
  List<Map<String, dynamic>> doneTasks = [];
  List<Map<String, dynamic>> archivedTasks = [];
  List<bool> statusList = [];

  static int currentIndex = 0;
  static const List<Widget> screens = [NewTasks(), DoneTasks(), ArchiveTasks()];
  static const List<String> titles = [
    "New Tasks",
    "Done Tasks",
    "Archived Tasks"
  ];

  static ToDoCubit get(context) => BlocProvider.of(context);

  void changeBottomSheet({required bottomSheet, required icon}) {
    isBottomSheet = bottomSheet;
    addTaskIcon = icon;
    emit(ChangeBottomSheetState());
  }

  void changeNavBar(index) {
    currentIndex = index;
    emit(ChangeNavBarState());
  }

  Future<void> refreshTasks() async {
    // الإصلاح هنا: التأكد من جلب البيانات بشكل صحيح
    var value = await DBHelper.getDataFromDB();
    taskList = value ?? []; 
    newTasks = [];
    doneTasks = [];
    archivedTasks = [];
  }

  Future<void> insertData({
    required String title,
    required String time,
    required String date,
  }) async {
    try {
      await DBHelper.insertToDB(title: title, time: time, date: date);
      await getData();
      emit(InsertToDBState());
    } catch (error) {
      if (kDebugMode) {
        print("error in inserting database:  ${error.toString()}");
      }
    }
  }

  Future<void> getData() async {
    await refreshTasks();
    // الإصلاح هنا: إزالة الـ ? لأن القوائم لم تعد nullable
    taskList.forEach((element) {
      if (element['status'] == 'false' && element['archived'] == 'false') {
        newTasks.add(element);
      } else if (element['status'] == 'true' &&
          element['archived'] == 'false') {
        doneTasks.add(element);
      } else if (element['status'] == 'false' &&
          element['archived'] == 'true') {
        archivedTasks.add(element);
      }
    });
    emit(SelectDataState());
  }

  Future<void> updateStatus(int id, String status) async {
    if (status == 'true' || status == 'false') {
      await DBHelper.updateTaskStatus(id, status);
      await getData();
      emit(UpdateTaskState());
    }
  }

  Future<void> updateArchive(int id, String archive) async {
    await DBHelper.updateArchiveStatus(id, archive);
    await getData();
    emit(UpdateArchiveState());
  }

  Future<void> deleteTask(int id) async {
    await DBHelper.deleteTaskById(id);
    await getData();
    emit(DeleteTaskState());
  }
}