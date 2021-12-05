import 'dart:convert';

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:examen_final/components/loader_component.dart';
import 'package:examen_final/models/encuesta.dart';
import 'package:examen_final/models/response.dart';
import 'package:examen_final/models/token.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:http/http.dart' as http;
import 'package:email_validator/email_validator.dart';

class OpinionForm extends StatefulWidget {
  final Token token;

  OpinionForm({required this.token});

  @override
  _OpinionFormState createState() => _OpinionFormState();
}

class _OpinionFormState extends State<OpinionForm> {
  final myController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  late Token _token;
  final Encuesta _user = new Encuesta(
      id: 0,
      email: '',
      qualification: 0,
      theBest: '',
      theWorst: '',
      remarks: '');
  final formController = TextEditingController();
  bool _showLoader = true;
  bool _edit = false;

  int id = 0;
  String date = '';
  
  String email = '';
  String emailError ='';
  bool emailShowError = false;
  TextEditingController emailController = TextEditingController();

  double qualification = 0;
  String qualificationError ='';
  bool qualificationShowError = false;
  TextEditingController qualificationController = TextEditingController();

  String theBest = '';
  String theBestError ='';
  bool theBestShowError = false;
  TextEditingController theBestController = TextEditingController();

  String theWorst = '';
  String theWorstError ='';
  bool theWorstShowError = false;
  TextEditingController theWorstController = TextEditingController();

  String remarks = '';
  String remarksError ='';
  bool remarksShowError = false;
  TextEditingController remarksController = TextEditingController();

  @override
  void dispose() {
    // Limpia el controlador cuando el Widget se descarte
    myController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: Center(child: Text("FORMULARIO")),
      ),
      body: Stack(
        children: <Widget>[
          _showLoader
              ? LoaderComponent(
                  text: 'Por favor espere...',
                )
              : showData(),
        ],
      ),
    );
  }

  showData() {
    final Size screenSize = MediaQuery.of(context).size;
    return Container(
        padding: new EdgeInsets.all(20.0),
        child: new Form(
          key: this._formKey,
          child: new ListView(
            children: <Widget>[
              Text("Califica el curso"),
              _ratingBar(),
              new TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (valor) => email = valor,
                  decoration: new InputDecoration(
                      hintText: 'you@example.com', 
                      labelText: email,
                      errorText: emailShowError ? emailError : null,
                  )),
              new TextFormField(
                  controller: theBestController,
                  onChanged: (valor) => theBest = valor,
                  decoration: new InputDecoration(
                      hintText: 'Lo que más te gustó', 
                      labelText: theBest,
                      errorText: theBestShowError ? theBestError : null,
                  )),
              new TextFormField(
                  controller: theWorstController,
                  onChanged: (valor) => theWorst = valor,
                  decoration: new InputDecoration(
                      hintText: 'Lo que menos te gustó', 
                      labelText: theWorst,
                      errorText: theWorstShowError ? theWorstError : null,
                  )),
              new TextFormField(
                  controller: remarksController,
                  onChanged: (valor) => remarks = valor,
                  decoration: new InputDecoration(
                      hintText: 'Comentarios', 
                      labelText: remarks,
                      errorText: remarksShowError ? remarksError : null,
                  )),
              new Container(
                width: screenSize.width,
                child: new ElevatedButton(
                  child: new Text(
                    'Enviar',
                    style: new TextStyle(color: Colors.white),
                  ),
                  onPressed: () => saveFormInfo(),
                  // color: Colors.blue,
                ),
                margin: new EdgeInsets.only(top: 20.0),
              )
            ],
          ),
        ));
  }

  Widget _ratingBar() {
    return RatingBar.builder(
      initialRating: qualification,
      minRating: 1,
      direction: Axis.horizontal,
      allowHalfRating: true,
      itemCount: 5,
      itemPadding: EdgeInsets.symmetric(horizontal: 4.0),
      itemBuilder: (context, _) => Icon(
        Icons.star,
        color: Colors.amber,
      ),
      onRatingUpdate: (rating) {
        qualification = rating.toDouble();
        print(rating);
      },
    );
  }

  Widget _image(String asset) {
    return Image.asset(
      asset,
      height: 30.0,
      width: 30.0,
      color: Colors.amber,
    );
  }

  bool validateFileds() {
    bool isValid = true;
    if (email.isEmpty) {
      isValid = false;
    }
    else if(!EmailValidator.validate(email)){
      isValid = false;
      emailShowError = true;
      emailError = 'Debes ingresar un email válido';
    }
    else if(!email.contains('correo.itm.edu')){
      isValid = false;
      emailShowError = true;
      emailError = 'El correo debe ser de dominio del itm';
    }
    else{
      emailShowError = false;
    }

    if(qualification <= 0){
      isValid = false;
      showAlertDialog(
        context: context,
        title: 'Error', 
        message: 'Debes seleccionar una calificación entre 1 y 5',
        actions: <AlertDialogAction>[
            AlertDialogAction(key: null, label: 'Aceptar'),
        ]
      );    
    }

    if(theBest.isEmpty){
      isValid = false;
      theBestError = "Debes ingresar una opinión positiva";
      theBestShowError = true;
    }

    if(theWorst.isEmpty){
      isValid = false;
      theWorstShowError = true;
      theWorstError = "Debe ingresar una opinión negativa";
    }

    if(remarks.isEmpty){
      isValid = false;
      remarksShowError = true;
      remarksError = "Por favor ingresa una sugerencia";
    }

    setState(() { });

    return isValid;
  }

  void initState() {
    super.initState();
    setState(() {
      _showLoader = true;
    });
    super.initState();
    _token = widget.token;
    getData();
  }

  getData() async {
    Response response = await getFormInfo(_token);
    if (response.isSuccess) {
      if (response.result != null) {
        Encuesta encuesta = Encuesta.fromJson(response.result);
        setState(() {
          _showLoader = false;
          _edit = true;
        });
        email = encuesta.email;
        qualification = encuesta.qualification.toDouble();
        theBest = encuesta.theBest;
        theWorst = encuesta.theWorst;
        remarks = encuesta.remarks;
      } else {
        setState(() {
          _showLoader = false;
        });
      }
    } else {
      setState(() {
        _showLoader = false;
      });
      showAlertDialog(
          context: context,
          title: 'Error',
          message: response.message,
          actions: <AlertDialogAction>[
            AlertDialogAction(key: null, label: 'Aceptar'),
          ]);
    }
  }

  static Future<Response> getFormInfo(Token token) async {
    var url = Uri.parse("https://vehicleszulu.azurewebsites.net/api/Finals");
    var response = await http.get(
      url,
      headers: {
        'content-type': 'application/json',
        'accept': 'application/json',
        'authorization': 'bearer ${token.token}'
      },
    );
    var body = response.body;
    var decodedJson = jsonDecode(body);
    if (response.statusCode >= 400) {
      return Response(isSuccess: false, message: body);
    } else if (decodedJson['id'] == 0) {
      return Response(isSuccess: true, result: null);
    }
    return Response(isSuccess: true, result: decodedJson);
  }

  saveFormInfo() async {
    if (!validateFileds()) {
      return;
    }

    print(validateFileds());

    var url = Uri.parse('https://vehicleszulu.azurewebsites.net/api/Finals');
    Map<String, dynamic> request = {
      'email': email,
      'qualification': qualification.toInt(),
      'theBest': theBest,
      'theWorst': theWorst,
      'remarks': remarks,
    };
    var bodyRequest = jsonEncode(request);
    var response = await http.post(
      url,
      headers: {
        'content-type': 'application/json',
        'accept': 'application/json',
        'authorization': 'bearer ${_token.token}'
      },
      body: bodyRequest,
    );
    print(response.body);

    if (response.statusCode >= 400) {
      print(response);
      await showAlertDialog(
          context: context,
          title: 'Error',
          message: response.body,
          actions: <AlertDialogAction>[
            AlertDialogAction(key: null, label: 'Aceptar'),
          ]);
      return;
    } else {
      await showAlertDialog(
          context: context,
          title: 'Registro exitoso',
          message: "Gracias por su opinión, los datos fueron guardados",
          actions: <AlertDialogAction>[
            AlertDialogAction(key: null, label: 'Aceptar'),
          ]);
    }
    var body = response.body;
    var decodedJson = jsonDecode(body);
    print(decodedJson);
  }
}
