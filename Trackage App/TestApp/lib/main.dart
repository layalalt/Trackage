import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:minio/io.dart';
import 'dart:convert';
import 'package:minio/minio.dart';
import 'package:http/http.dart' as http;
import 'package:csv/csv.dart';
import 'package:dio/dio.dart';
import 'csv_data_provider.dart';
import 'UserSession.dart';
import 'dart:math';
import 'package:intl/intl.dart';

String lastName = "";
String myPresignedUrl = "https://s3.eu-north-1.amazonaws.com/trackage.1/database.csv?response-content-disposition=inline&X-Amz-Content-Sha256=UNSIGNED-PAYLOAD&X-Amz-Security-Token=IQoJb3JpZ2luX2VjEHMaCmV1LW5vcnRoLTEiSDBGAiEA0V7t%2FB3WmWxpjAasMvcaE52NfWm1Aq0n%2B7Nq7AY8WXgCIQD70Fqu3FIlDQQ2gDJX2knKb0%2FH2CLtjwrCHLAfl%2BcTbiq5AwgsEAAaDDU1NzY5MDU4NDM2NiIM8MArBlsSkRlt9ROzKpYDoubDYqjV1kPn79mk7%2FHVFqBDPd%2BxVBOeBvbIeuzwu3%2FzgcPC9E%2BdVxJ8RCwO6HAMrgfpwGgcjiXyTbjbRkqjXT2OcuhMTpkWBeTkQmc32NX6%2BofuA0%2FdChTgln9azk3v%2FdLFhkeEdYglDcAVUNdDe94%2FEWAR3sf%2FfBix85QHES5MFyfOvvyOllINf1sDlXSJFlbEyyOB7yQVl5BJje76HMNd%2FtyHl0ptuZs7PkLseIh8gQvCnWQ6Qn8pyEo7b1NF2zzm19Vnx9zuqcQY%2BATDxJKZpkvOna%2F87ID42lMpYU%2FZxD8umDi3IjoFdqzCTtfganWQV8%2BN7oXclCeiK1IZQBogZS%2BYJc3M4O66REB0bfMI3Dzizjd678LFXmSFxNfeKzW6XiQ5PNu6bihx7ILzrPWtXKIJN9UGAxjATwj6VhkN2qX9N2ad5vHd%2BN8OaHGWhxXlSDfgl1k3Bj%2B0ZptscEZV234RP2%2FDV03QMP9558jsoX72eUXBII2J%2Fr1qFFQF87KqjDJpekSoBINx2prQGpWZjEu%2FhjCvmJfBBjrdArGw448anKCdYyu7XU3vsoOcuvloOWNe5EnK1aD3GtxF1MQ7fLo1LXYpojhfdoiFmI8yjPCBZP0m8pEy7u970zuNfWkddLU6qj2ZXYS%2FQlMdLzAbX5LnbKCGcPu0pc58GLx7Rwsy%2FfkUutjtBqvaO4AYkxo8gaAXpWv2E8rak8ZeoUlQXWRDhDThZcS8jRSOClIzS5fSrEWx29GzE4UFvxrWeJ4zG9La1FXPDbj%2B9p6iq7H8YLpyVstqM4HBGPzaQDT%2FPC%2FE19ewuILbsHiVLR%2B7XVqtg7zxfLjTthbw3ltDzMos9RrwnOtRjhgKi267A9ukYJi0IeurANCTXZABvTgJooLT4GTmPNH14Cm8%2BphQNkEp0iYsqb5z2XPcHM6SROdXFjiYzA0yFArh59TI%2BhJlpeZ8qpDYpdPHjcS6DUf0hbedZUwJkt5HeqH2x4W6iWc2hmc1Gbswg6mVKd4%3D&X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=ASIAYDWHS7UXJWGUAXCB%2F20250515%2Feu-north-1%2Fs3%2Faws4_request&X-Amz-Date=20250515T111655Z&X-Amz-Expires=43200&X-Amz-SignedHeaders=host&X-Amz-Signature=267beee675013d3c51810941e2167b55b28d6c354ff7a15747a33f324161750d";
String presignedUrl = "https://s3.eu-north-1.amazonaws.com/trackage.1/database.csv?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=ASIAYDWHS7UXD2EQQ5QD%2F20250515%2Feu-north-1%2Fs3%2Faws4_request&X-Amz-Date=20250515T111538Z&X-Amz-Expires=3600&X-Amz-SignedHeaders=host&X-Amz-Security-Token=IQoJb3JpZ2luX2VjEHMaCmV1LW5vcnRoLTEiRjBEAiB1VXNS2Y08J3AKYNzPr9TJWcZSwZG1TPkivSrFEhZ7WwIgBZEh0tz3eX32Decy3RK%2BrMXAqHGx5RMJvOPxQ7z8VTEq4wIILBAAGgw1NTc2OTA1ODQzNjYiDOxKlLtD54JftLML9SrAApLZB6rSs6Aah3Cj1ySpYsmfM2Y%2FwiCaGQ38QbjskkRIiL7iujZL1lj1KfThhtmkqUkqziVX%2FIhwk6Ev2DKOAufxoTu%2Fsh5yT%2F0C56TZeainx66EZVFJqoQDaUllPUhXFnrEtSTwwIbijk%2BLcUUWTDGtWwRUQBfp0VrcDR8P7tbbPRstIpN4cErLrDSNCWOEIRl0jDCG53%2BV5EC4dWZhP2QIJW5g9%2FZwJvoZOVpIt8mq8jkm70eu1%2Fu3UTh%2F9WDs6JkMdEVQQr0Iq4CcJp3N8cvlKnhqN9lX8vXxM2DIpAWgg0tYvncvgcLagXzgZZtKfk9ntcZcW2pcGFOYQ3PWZE44%2F4Bo97wRUCTx1RzJPDLQcw7Qur%2FVRT7%2BWp1c1xf%2BB%2FN%2FAwxbdlxlhrmkDK4mCIhjxbueCcpq5MoKMmT8btK1MK%2BYl8EGOq4CnNm3%2Bab4UFNhgJGNjsCJsZ86YUwO1oBHZydcDp9XkpIBRuLn9NGfeevI8F%2B3LeCF4VezfQC7WMYR1xGy1M%2FtAa55U8yLSNccjFIPMedSCZTT5stZCdc8aTfVOeeX7%2FDZ9RY16%2FnPSgGpZB1%2FAMMCxMqat%2BRE7b1wrAGBB4g2UES1%2BZwOC0LoJkrnqGMNCBFNLGcOvFbODF2IFFZiz%2BmRvqEIoLz3teZ05H2GtpiUrfe1nUBipXTQmiU9KiXePJzyO8e6Q86kQLeoi5zKW9cnfkQE7DEJmvOOV0cb8TNtx%2FX3zp99vrBuVxT%2FNVaTmsrXdMAI%2BXDW1J01yLFb4NL1VZyYJ%2Fgsn5AsYmI%2B6zPfjnpIzv9P31ulyu9iXPiG18cznIuyRi8IJKatt7XddOw%3D&X-Amz-Signature=0aaaf766947fb3dadb9ca013d42fe3620e6e37d5ad7974608f25ee454f945d98";

extension CaseInsensitiveCompare on String {
  bool equalsIgnoreCase(String other) =>
      this.toLowerCase() == other.toLowerCase();
}

Future<void> uploadToS3(String csvContent) async {
  print("🔼 Sending raw CSV content:\n$csvContent");

  List<String> lines = csvContent.split('\n');
  print("🔼 First 5 lines of CSV:");
  for (int i = 0; i < (lines.length < 5 ? lines.length : 5); i++) {
    print("Line ${i + 1}: ${lines[i]}");
  }

  try {
    final response = await http.put(
      Uri.parse(presignedUrl),
      headers: {
      },
      body: utf8.encode(csvContent),
    );

    if (response.statusCode == 200) {
      print("✅ Upload successful!");
    } else {
      print("❌ Upload failed: ${response.statusCode}");
      print("📩 Response body: ${response.body}");
    }
  } catch (e) {
    print("❗ Exception during upload: $e");
  }
}





void main(){
  runApp(TrackageApp());

  // debug
  debugPrint("Testing CSV loading...");
  CsvDataProvider.fetchData(myPresignedUrl).then((_) {
    debugPrint("CSV load completed. Row count: ${CsvDataProvider.dataRows.length}");
    if (CsvDataProvider.dataRows.isNotEmpty) {
      debugPrint("First row: ${CsvDataProvider.dataRows.first}");
      debugPrint("Headers: ${CsvDataProvider.headers}");
    }
  }).catchError((e) {
    debugPrint("CSV load failed: $e");
  });
}

class TrackageApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Trackage',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.light,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF19437D),
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 20, horizontal: 30),
            textStyle: TextStyle(fontSize: 18),
          ),
        ),
      ),
      home: SignInPage(),
    );
  }
}


class SignInPage extends StatefulWidget {
  @override
  _SignInPageState createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _formKey = GlobalKey<FormState>();
  String lastName = '';
  String reservationID = '';
  bool isLoading = false;

  Future<void> _login(String reservationID, String lastName) async {
    setState(() => isLoading = true);

    try {
      await CsvDataProvider.fetchData(myPresignedUrl);

      final originalResID = reservationID.trim();
      final originalLastName = lastName.trim();

      print("Searching for (original case): '$originalResID' / '$originalLastName'");

      final matchingRow = CsvDataProvider.dataRows.firstWhere(
            (row) {
          if (row.length < 6) return false;

          final rowResID = row[3].toString().trim();
          final rowLastName = row[5].toString().trim();

          return rowResID.equalsIgnoreCase(originalResID) &&
              rowLastName.equalsIgnoreCase(originalLastName);
        },
        orElse: () => [],
      );

      if (matchingRow.isNotEmpty) {
        UserSession.setSession(
          resID: originalResID,
          lName: originalLastName,
          row: matchingRow,
        );
        Navigator.push(context, MaterialPageRoute(
          builder: (context) => MainPage(userRow: matchingRow),
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No matching reservation found'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Login error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Login error occurred'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFFFFF),
      resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
        //child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Logo section
              SizedBox(height: 70),
              Image.asset(
                'assets/TrackageLogo.jpg',
                height: 150,
              ),
              SizedBox(height: 20),
              Text(
                "Trackage",
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20),
              Text(
                "Login",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 10),
              Text(
                "Enter your Reservation ID and last name",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 30),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Phone Number Input
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Last name',
                        labelStyle: TextStyle(color: Color(0xFF155E81)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                          borderSide: BorderSide(color: Color(0xFF155E81),),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                          borderSide: BorderSide(color: Color(0xFF155E81)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                          borderSide: BorderSide(color: Color(0xFF19437D)),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your last name';
                        }
                        return null;
                      },
                      onChanged: (value) {
                        setState(() {
                          lastName = value;
                        });
                      },
                      cursorColor: Color(0xFF19437D),

                    ),
                    SizedBox(height: 20),
                    // Password Input
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Reservation ID',
                        labelStyle: TextStyle(color: Color(0xFF155E81)),

                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                          borderSide: BorderSide(color: Color(0xFF155E81)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                          borderSide: BorderSide(color: Color(0xFF155E81)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                          borderSide: BorderSide(color: Color(0xFF155E81)),
                        ),
                      ),
                      //obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your reservation ID';
                        }
                        return null;
                      },
                      onChanged: (value) {
                        setState(() {
                          reservationID = value;
                        });
                      },
                      cursorColor: Color(0xFF19437D),

                    ),
                    SizedBox(height: 30),
                    // Continue Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF14501C),
                          padding: EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          if (_formKey.currentState!.validate() && !isLoading) {
                            _login(reservationID, lastName); // Call the login function
                            // here go to page 2
                          }
                        },
                        child: isLoading
                            ? CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        )
                            : Text(
                          'Continue',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      )
    );
  }
}
Future<void> updateClaimStatus({
  required String reservationID,
  required String newStatus,
  required String uploadUrl,
}) async {
  try {
    // Find and update the correct row
    for (int i = 0; i < CsvDataProvider.dataRows.length; i++) {
      if (CsvDataProvider.dataRows[i][3].toString().trim() == reservationID.trim()) {
        CsvDataProvider.dataRows[i][15] = newStatus;
        break;
      }
    }

    // Reconstruct CSV
    final updatedCsv = const ListToCsvConverter().convert([
      CsvDataProvider.headers,
      ...CsvDataProvider.dataRows,
    ]);

    // Upload to S3
    final response = await http.put(
      Uri.parse(uploadUrl),
      headers: {'Content-Type': 'text/csv'},
      body: utf8.encode(updatedCsv),
    );

    if (response.statusCode == 200) {
      print('Claim status updated successfully!');
    } else {
      throw Exception('Upload failed: ${response.statusCode}');
    }
  } catch (e) {
    print("Error updating claim status: $e");
    rethrow;
  }
}

// PAGE 2
class MainPage extends StatefulWidget {
  final List<dynamic> userRow;
  const MainPage({Key? key, required this.userRow}) : super(key: key);


  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  String? selectedOption;
  bool isSaving = false;

  Future<void> saveLuggageChoice(BuildContext context) async {
    if (selectedOption == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please select a luggage claim method.")),
      );
      return;
    }

    final index = CsvDataProvider.dataRows.indexWhere(
          (row) =>
      row[3].toString().trim() == widget.userRow[3].toString().trim() &&
          row[5].toString().trim().toLowerCase() == widget.userRow[5].toString().trim().toLowerCase(),
    );

    if (index != -1) {
      while (CsvDataProvider.dataRows[index].length <= 7) {
        CsvDataProvider.dataRows[index].add('');
      }

      CsvDataProvider.dataRows[index][1] = selectedOption!;

      final allRows = [
        CsvDataProvider.headers,
        ...CsvDataProvider.dataRows
      ];
      final csvContent = const ListToCsvConverter().convert(allRows);

      try {
        await uploadToS3(csvContent);
        print("✅ Upload successful!");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Your selection was saved.")),
        );
      } catch (e) {
        print("❌ Upload failed: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error updating delay status.")),
        );
      }
    }

  }

  @override
  Widget build(BuildContext context) {
   return MaterialApp(
     home: DefaultTabController(
       length: 3,
       child: Scaffold(
         appBar: AppBar(
           bottom: const TabBar(
             tabs: [
               Tab(text: 'Claim Options'),
               Tab(text: 'Tracking'),
               Tab(text: 'Support'),
             ],
             indicatorColor: Colors.black,
             labelColor: Colors.black,
             unselectedLabelColor: Colors.grey,
           ),
           //title: const Text('Trackage'),
           backgroundColor: Color(0xFFFFFFFF),
           elevation: 0,
           toolbarHeight: 20,
         ),
         backgroundColor: Color(0xFFFFFFFF),
         body: Padding(
           padding: EdgeInsets.symmetric(horizontal: 30, vertical: 30),
             child: TabBarView(
               children: [
                 Column(
                   //crossAxisAlignment: CrossAxisAlignment.stretch,
                   mainAxisAlignment: MainAxisAlignment.center,
                   children: [
                     Text("How would you like to claim your luggage?",
                       style: TextStyle(fontSize:33, fontWeight: FontWeight.bold, color: Colors.black,
                       ), textAlign: TextAlign.center,
                     ),
                     SizedBox(height: 80),
                     ElevatedButton(onPressed: (){
                       setState(() {
                         selectedOption = "SLHS Electronic Gates";
                       });
                     }, style: ElevatedButton.styleFrom( backgroundColor: Color(0xFFE4EBFF), foregroundColor: Color(
                         0xFF19437D),  minimumSize: Size(double.infinity, 80), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)) ),
                         child: Text("Mata Smart Gates",  style: TextStyle(fontSize:23, color: Colors.black,
                     ),)),
                     SizedBox(height: 20),
                     ElevatedButton(onPressed: (){
                       setState(() {
                         selectedOption = "Delivery";
                       });
                     }, style: ElevatedButton.styleFrom( backgroundColor: Color(0xFFE4EBFF), foregroundColor: Color(
                         0xFF19437D),  minimumSize: Size(double.infinity, 80), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)) ),
                         child: Text("Delivery Service",  style: TextStyle(fontSize:23, color: Colors.black,
                         ),)),
                     SizedBox(height: 20),
                     ElevatedButton(
                       onPressed: () {
                         setState(() {
                           selectedOption = "Pickup Outside the Terminal";
                         });
                       },
                       style: ElevatedButton.styleFrom(
                         backgroundColor: Color(0xFFE4EBFF),
                         foregroundColor: Color(0xFF19437D),
                         minimumSize: Size(double.infinity, 80),
                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                       ),
                       child: Center(
                         child: Text(
                           "Pick up Outside the Terminal",
                           style: TextStyle(fontSize: 23, color: Colors.black),
                           textAlign: TextAlign.center,
                         ),
                       ),
                     ),
                     SizedBox(height: 100), // Space below the text
                     Builder(
                       builder: (BuildContext innerContext) {
                         return ElevatedButton(
                           onPressed: () => saveLuggageChoice(innerContext),
                           style: ElevatedButton.styleFrom(
                             backgroundColor: Color(0xFF19437D),
                             foregroundColor: Color(0xFF19437D),
                             minimumSize: Size(double.infinity, 60),
                           ),
                           child: Text(
                             "Done",
                             style: TextStyle(fontSize: 23, color: Colors.white),
                           ),
                         );
                       },
                     ),


                   ],

                 ),
                 TrackingPage(),
                 Center(
                     child: Text("email@support.sa", style: TextStyle(fontSize: 24),),
                 ),
               ], //children
             ),
         )
       ),
     ), //tap controller
   ); //material app
  } //widget
} //MainPage

Future<void> submitDelayPickup({
  required BuildContext context,
  required String reservationID,
  required String lastName,
  required String presignedUrl,
  required int delayMinutes,
}) async {
  try {
    // Use CsvDataProvider to fetch data
    await CsvDataProvider.fetchData(presignedUrl);
    final headers = CsvDataProvider.headers;
    final dataRows = CsvDataProvider.dataRows;
    print("🔍 Searching for resID: '$reservationID'");
    print("🔍 Searching for lastName: '$lastName'");
    print("📊 First 3 rows:");

    print("Searching for resID: '$reservationID' and lastName: '$lastName'");
    for (int i = 0; i < min(5, dataRows.length); i++) {
      print("Row $i: ${dataRows[i]}");
    }

    final index = dataRows.indexWhere(
          (row) =>
      row[3].toString().trim() == reservationID.trim() &&
          row[5].toString().trim().toLowerCase() == lastName.trim().toLowerCase(),
    );

    if (index != -1) {
      // Ensure the row has enough columns
      while (dataRows[index].length <= 15) {
        dataRows[index].add('');
      }

      final format = DateFormat.Hm(); // handles 'HH:mm' format

      DateTime originalTime = format.parse(dataRows[index][15].toString());
      DateTime updatedTime = originalTime.add(Duration(minutes: delayMinutes));

      // Format back to 'HH:mm' string and store it
      dataRows[index][15] = format.format(updatedTime);

      final updatedCsv = const ListToCsvConverter().convert([
        headers,
        ...dataRows,
      ]);

      await uploadToS3(updatedCsv);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Delay status submitted.")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("User not found.")),
      );
    }
  } catch (e) {
    print("Error: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error updating delay status.")),
    );
  }
}

// Mock Tracking UI
class TrackingPage extends StatefulWidget {
  @override

  _TrackingPageState createState() => _TrackingPageState();
}

class _TrackingPageState extends State<TrackingPage> {
  Map<String, dynamic> bagData = {}; // Placeholder for tracking data
  String? selectedOption;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDataForUser(UserSession.lastName);
  }
  Future<void> _loadDataForUser(String lastName) async {
    try {
      await CsvDataProvider.fetchData(myPresignedUrl);
      final userRow = CsvDataProvider.getUserRow(UserSession.reservationID, lastName);

      if (userRow != null) {
        setState(() {
          bagData = {
            "estimatedArrival": userRow[11]?.toString() ?? "N/A",
            "pickupGate": userRow[13]?.toString() ?? "Not Assigned",
            "flightNumber": userRow[7]?.toString() ?? "N/A",
            "numberOfBags": userRow[9]?.toString() ?? "0",
            "status": userRow[14]?.toString().toLowerCase() ?? "unknown",
          };
          print("DEBUG - bagData contents: $bagData"); // Add this line
          print("DEBUG - full userRow: $userRow");

        });
      }
    } catch (e) {
      print("Error loading user data: $e");
    }
  }

  Widget buildInfoRow(String label, String value, bool boldValue) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 16, color: Colors.grey)),
          Text(value ?? "Loading",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: boldValue ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }

  Widget buildBagInfoBox(Map<String, dynamic> bagData) {
    return Container(
      padding: EdgeInsets.all(20),
      width: 400,
      decoration: BoxDecoration(
        color: Color(0xFFF0F4FF),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildInfoRow(
            "Estimated Arrival Time",
            "${formatTime(bagData['estimatedArrival'])} ±15 min",
            false, ),
          buildInfoRow("Time in Transit", "04:24", false),
          buildInfoRow(
            "Pickup Gate",
            bagData['pickupGate']?.isNotEmpty ?? false
                ? bagData['pickupGate']!
                : "not Assigned",
            false,
          ),
          buildInfoRow("Flight Number", bagData['flightNumber'], false),
          buildInfoRow("Number of Bags", bagData['numberOfBags'], false),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    if (bagData.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    Widget statusWidget;
    final String status = bagData["status"] ?? "unknown";

    switch (status.toLowerCase()) {
      case "in-transit":
        statusWidget = buildInTransitView("In-transit..");
        break;
      case "in-slhs":
        statusWidget = buildInTransitView("In SLHS..");
        break;
      case "ready for pickup":
        statusWidget = buildPickupReadyView();
        break;
      default:
        statusWidget = buildUnknownView("Status Unknown");
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(child: statusWidget),
    );
  }

  Widget buildInTransitView(String statusText) {
    return Container(
    color: Colors.white,
    child: Center(
      child: bagData.isEmpty
          ? CircularProgressIndicator()
          : Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topRight,
            children: [
              Image.asset('assets/conveyor.png', width: 300, height: 40),
              Positioned(
                top: -48,
                right: 118,
                child: Icon(Icons.luggage, size: 60, color: Color(0xFF245DAC)),
              ),
            ],
          ),
          SizedBox(height: 10),
          Text(statusText,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          SizedBox(height: 20),
          Container(
            padding: EdgeInsets.all(20),
            width: 400,
            decoration: BoxDecoration(
              color: Color(0xFFF0F4FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              buildInfoRow(
              "Estimated Arrival Time",
              "${formatTime(bagData['estimatedArrival'])} ±15 min",
              false, ),
              buildInfoRow("Time in Transit", "04:24", false),
                buildInfoRow("Pickup Gate",
                    bagData['pickupGate']?.isNotEmpty ?? false
                        ? bagData['pickupGate']!
                        : "not Assigned", false),
                buildInfoRow("Flight Number", bagData['flightNumber'], false),
                buildInfoRow("Number of Bags", bagData['numberOfBags'], false),
              ],
            ),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () async {
              final userRow = CsvDataProvider.getUserRow(
                  UserSession.reservationID, UserSession.lastName);

              if (userRow == null || userRow.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("User not found.")),
                );
                return;
              }

              int? selectedDelay = await showDialog<int>(
                context: context,
                builder: (BuildContext context) {
                  int delayValue = 1;
                  return AlertDialog(
                    title: Text("Select Delay Time (in minutes)",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Color(0xFF245DAC),
                      ),
                    ),
                    content: StatefulBuilder(
                      builder: (BuildContext context, StateSetter setState) {
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                activeTrackColor: Color(0xFF245DAC),
                                inactiveTrackColor: Color(0xFF245DAC).withOpacity(0.3),
                                thumbColor: Color(0xFF245DAC),
                                overlayColor: Color(0xFF245DAC).withOpacity(0.2),
                                valueIndicatorColor: Color(0xFF245DAC),
                              ),
                              child: Slider(
                                value: delayValue.toDouble(),
                                min: 1,
                                max: 10,
                                divisions: 9,
                                label: "$delayValue min",
                                onChanged: (double value) {
                                  setState(() {
                                    delayValue = value.toInt();
                                  });
                                },
                              ),
                            ),
                            Text("$delayValue minute${delayValue > 1 ? 's' : ''}",
                                style: TextStyle(color: Color(0xFF245DAC))),
                          ],
                        );
                      },
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, null),
                        child: Text("Cancel"),
                        style: TextButton.styleFrom(
                          foregroundColor: Color(0xFF245DAC),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, delayValue),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF245DAC),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text("Confirm"),
                      ),
                    ],
                  );
                },
              );

              if (selectedDelay != null) {
                submitDelayPickup(
                  context: context,
                  reservationID: userRow[3].toString(),
                  lastName: userRow[5].toString(),
                  presignedUrl: myPresignedUrl,
                  delayMinutes: selectedDelay,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF19437D),
              foregroundColor: Colors.white,
              minimumSize: Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text("Delay Pickup", style: TextStyle(fontSize: 18)),
          ),
        ],
      ),
    ),
    );
  }

  Widget buildUnknownView(String statusText) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topRight,
          children: [
            Image.asset('assets/conveyor.png', width: 300, height: 40),
            Positioned(
              top: -48,
              right: 200,
              child: Icon(Icons.luggage, size: 60, color: Color(0xFF245DAC)),
            ),
          ],
        ),
        SizedBox(height: 10),
        Text(statusText, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        SizedBox(height: 20),
        buildBagInfoBox(bagData),
      ],
    );
  }

  Widget buildPickupReadyView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topRight,
          children: [
            Image.asset('assets/conveyor.png', width: 300, height: 40),
            Positioned(
              top: -48,
              right: 20,
              child: Icon(Icons.luggage, size: 60, color: Color(0xFF245DAC)),
            ),
          ],
        ),
        SizedBox(height: 10),
        Text("Ready for Pickup", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        SizedBox(height: 20),
        Container(
          padding: EdgeInsets.all(20),
          width: 400,
          decoration: BoxDecoration(
            color: Color(0xFFF0F4FF),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildInfoRow("Pickup Gate", bagData['pickupGate'], true),
              buildInfoRow("Number of Bags", bagData['numberOfBags'], true),
              SizedBox(height: 20),
              Center(child: Image.asset('assets/barcode.png', height: 60)),
            ],
          ),
        ),
        SizedBox(height: 20),
        ElevatedButton(
          onPressed: confirmPickup,
          child: Text("Confirm Pickup"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF19437D),
            foregroundColor: Colors.white,
            minimumSize: Size(double.infinity, 50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }

  void confirmPickup() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Pickup Confirmed"),
        content: Text("Thank you for confirming. Enjoy your trip!"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text("OK"),
          ),
        ],
      ),
    );
  }
  String formatTime(String timeString) {
    final parts = timeString.split(':');
    if (parts.length < 2) {
      return timeString; // fallback
    }
    final hour = parts[0].padLeft(2, '0');
    final minute = parts[1].padLeft(2, '0');
    return "$hour:$minute";
  }

}


