import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
        apiKey: "AIzaSyBEpo2OiDI2G08kFRVieBaGvz90RDx7RwA",
        authDomain: "attend-d8027.firebaseapp.com",
        databaseURL: "https://attend-d8027-default-rtdb.firebaseio.com",
        projectId: "attend-d8027",
        storageBucket: "attend-d8027.appspot.com",
        messagingSenderId: "416571483233",
        appId: "1:416571483233:web:204c554ca5694c678d3620",
        measurementId: "G-ZBEVN73JTG"
    ),
  );
  runApp(AttendanceApp());
}

class AttendanceApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home : GradeClassInputScreen(),
    );
  }
}

class GradeClassInputScreen extends StatefulWidget{
  @override
  _GradeClassInputScreenState createState()=>_GradeClassInputScreenState();
}


class _GradeClassInputScreenState extends State<GradeClassInputScreen> {
  late TextEditingController gradeController;
  late TextEditingController classNumberController;

  @override
  void initState() {
    super.initState();
    gradeController = TextEditingController();
    classNumberController = TextEditingController();
    _loadGradeAndClassNumber();
  }

  _loadGradeAndClassNumber() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    gradeController.text = prefs.getString('grade') ?? '';
    classNumberController.text = prefs.getString('classNumber') ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar : AppBar(title : Text('출석 체크')),
      body : Column(
        children : [
          TextField(
            controller: gradeController,
            decoration : InputDecoration(labelText:'학년'),
          ),
          TextField(
            controller: classNumberController,
            decoration : InputDecoration(labelText:'반'),
          ),
          ElevatedButton(onPressed : () async {
            SharedPreferences prefs = await SharedPreferences.getInstance();
            await prefs.setString('grade', gradeController.text);
            await prefs.setString('classNumber', classNumberController.text);
            Navigator.push(context, MaterialPageRoute(builder:(context)=>StudentListScreen(gradeController.text,classNumberController.text)));
          }, child : Text('입력완료')),
        ],
      ),
    );
  }
}

class StudentListScreen extends StatefulWidget{

  final String grade;
  final String classNumber;

  StudentListScreen(this.grade,this.classNumber);

  @override
  _StudentListScreenState createState()=>_StudentListScreenState();
}


class _StudentListScreenState extends State<StudentListScreen> {

  final dbRef = FirebaseDatabase.instance.reference().child("students");
  Map<dynamic, dynamic>? attendance;
  int weekNo=1;

  @override
  void initState() {
    super.initState();
    _loadWeekNo(); // Load the week number at startup
    dbRef.child(widget.grade).child(widget.classNumber).once().then((DatabaseEvent event) {
      if (event.snapshot.value != null) {
        setState(() {
          if (event.snapshot.value is Map) {
            attendance = Map.from(event.snapshot.value as Map);
          } else {
            // Handle the case where snapshot.value is not a map
          }
        });
      }
    });
  }
  _loadWeekNo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      weekNo = prefs.getInt('weekNo') ?? 1;
    });
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar : AppBar(title : Text('${widget.grade}학년 ${widget.classNumber}반')),
      body :
      Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(icon: Icon(Icons.arrow_left), onPressed: weekNo > 1 ? () => setState(() => weekNo--) : null),
              Text('$weekNo 주차'),
              IconButton(icon: Icon(Icons.arrow_right), onPressed: weekNo < 52 ? () => setState(() => weekNo++) : null),
            ],
          ),
          Expanded(
            child:
            attendance != null ? ListView.builder(itemCount : attendance!.length,
                itemBuilder :(BuildContext context, int index){
                  String name = attendance!.keys.elementAt(index);
                  bool isPresent = attendance![name][weekNo.toString()] ?? false;
                  return ListTile(
                    title : Text(name),
                    tileColor : isPresent ? Colors.blue[100] : Colors.grey[100],
                    onTap : (){
                      setState((){
                        attendance![name][weekNo.toString()] = !isPresent;
                      });
                    },
                  );
                }) :
            Center(child:CircularProgressIndicator()),
          ),
        ],
      ),
      floatingActionButton:FloatingActionButton(onPressed:() async{
        await dbRef.child(widget.grade).child(widget.classNumber).set(attendance!);
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setInt('weekNo', weekNo + 1); // Save the next week number when attendance is checked

// When the data has been set successfully, show a SnackBar and then navigate back.
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('출석체크가 완료되었습니다.')))
            .closed
            .then((reason) { Navigator.pop(context); });

      }, child:Icon(Icons.check)),
    );
  }
}