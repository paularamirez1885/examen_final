// import 'package:email_validator/email_validator.dart';
import 'dart:convert';
import 'package:examen_final/components/loader_component.dart';
import 'package:examen_final/models/token.dart';
import 'package:examen_final/screens/opinion_form.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:adaptive_dialog/adaptive_dialog.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({ Key? key }) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String _email = '';
  String _emailError = '';
  bool _emailShowError = false;

  String _password = '';
  String _passwordError = '';
  bool _passwordShowError = false;

  bool _rememberme = true;
  bool _passwordShow = false;

  bool _showLoader = false;



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              SizedBox(height: 20,),
              _showEmail(),
              _showPassword(),
              _showRememberme(),
              _showButtons()
            ],
          )
        )      
    );
  }

  Widget _showEmail() {
    return Container(
      padding: EdgeInsets.all(10),
      child: TextField(
        autofocus: true,
        keyboardType: TextInputType.emailAddress,
        decoration: InputDecoration(
          hintText: 'Ingresar correo electrónico',
          labelText: 'Correo electrónico',
          errorText: _emailShowError ?  _emailError : null,
          prefixIcon:  Icon(Icons.alternate_email),
          suffixIcon: Icon(Icons.email),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10) 
          ),
        ),
        onChanged: (value) {
          _email = value;
        },
      ),
    );
  }

  Widget _showPassword() {
    return Container(
      padding: EdgeInsets.all(10),
      child: TextField(
        obscureText: !_passwordShow,
        decoration: InputDecoration(
          prefixIcon: Icon(Icons.lock),
          suffixIcon: IconButton(
            icon: _passwordShow ? Icon(Icons.visibility) : Icon(Icons.visibility_off),
            onPressed: () {
              setState(() {
                _passwordShow = !_passwordShow;
              });
            },
          ), 
          hintText: 'Ingresar contraseña',
          labelText: 'Contraseña',
          errorText: _passwordShowError ? _passwordError : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10) 
          ),
        ),
        onChanged: (value) {
          _password = value;
        },
      ),
    );
  }

  Widget _showRememberme() {
    return CheckboxListTile(
      title: Text('Recordarme'),
      value: _rememberme, 
      onChanged: (value) {
        setState(() {
          _rememberme = value!;
        });
      },
    );
  }

 Widget _showButtons() {
   return Container(
     margin: EdgeInsets.only(left: 10, right: 10),
     child: Column(
       children: [
       Row(
       mainAxisAlignment: MainAxisAlignment.spaceAround,
       children:<Widget> [
         Expanded(
           child: ElevatedButton(
             child: Text('Ingresar'),
             style: ButtonStyle(
               backgroundColor: MaterialStateProperty.resolveWith<Color>(
                 (Set<MaterialState> states){
                   return Color(0xFFff64af);
                 }
               ),
             ),
             onPressed: () => _login(),
           ),
         ),
         SizedBox(width: 20,),
         Expanded(
           child: ElevatedButton(
             style: ButtonStyle(
               backgroundColor: MaterialStateProperty.resolveWith<Color>(
                 (Set<MaterialState> states){
                   return Color(0xFF32c2c8);
                 }
               ),
             ),
             child: Text('Registrarme'),
             onPressed: () {},
           ),
         ),
       ],
      ),
      _showGoogleButton(),
      ],
    )
  );
}

 Widget _showGoogleButton(){
   return Row(
           children: <Widget>[
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _loginGoogle(), 
            icon: FaIcon(
              FontAwesomeIcons.google,
              color: Colors.red,
            ), 
            label: Text('Ingresar con Google'),
            style: ElevatedButton.styleFrom(
              primary: Colors.white,
              onPrimary: Colors.black
            )
          )
        ),
          _showLoader ? LoaderComponent(text: 'Por favor espere...',) : Container(),
      ],
   );
 }

 void _login() {
   if (!_validateFields()) {
     return;
   }
 }

  bool _validateFields() {
    bool hasErrors = false;

    if (_email.isEmpty) {
      hasErrors = true;
      _emailShowError = true;
      _emailError = 'Debes ingresar tu correo electrónico';
    }
    //else if(!EmailValidator.validate(_email)){
    //   hasErrors = true;
    //   _emailError = 'Debes ingresar un correo válido.'; 
    // }else{
    //   _emailShowError = false;
    // }

    if (_password.isEmpty) {
      hasErrors = true;
      _passwordShowError = true;
      _passwordError = 'Debes ingresar tu contraseña.';
    }else if(_password.length < 6){
      hasErrors = true;
      _passwordError = 'Debes ingresar una contraseña de al menos 6 carácteres.'; 
    }else{
      _passwordShowError = false;
    }

    setState(() { });

    return hasErrors;
  }

   void _loginGoogle() async {
     setState(() {
      _showLoader = true;
    });
     var googleSignIn = GoogleSignIn();
     await googleSignIn.signOut();
     var user = await googleSignIn.signIn();
    Map<String, dynamic> request = {
      'Email': user?.email,
      'Id': user?.id,
      'LoginType': 1,
      'FullName': user?.displayName,
      'PhotoURL': user?.photoUrl,
    };
    await socialMediaLogin(request);
  }

  socialMediaLogin(Map<String, dynamic> request) async {
     var url = Uri.parse('https://vehicleszulu.azurewebsites.net/api/Account/SocialLogin');
     var bodyRequest = jsonEncode(request);
    var response = await http.post(
      url,
      headers: {
        'content-type' : 'application/json',
        'accept' : 'application/json',
      },
      body: bodyRequest,
    );
    setState(() {
      _showLoader = false;
    });

    if(response.statusCode >= 400) {
      await showAlertDialog(
        context: context,
        title: 'Error', 
        message: 'El usuario ya cuenta con sesión activa',
        actions: <AlertDialogAction>[
            AlertDialogAction(key: null, label: 'Aceptar'),
        ]
      );    
      return;
    }

    var body = response.body;
    var decodedJson = jsonDecode(body);
    var token = Token.fromJson(decodedJson);
    print(token.token);
        _goToForm(token);
  }

  _goToForm(Token token) async {
    await Navigator.push(context, 
      MaterialPageRoute(
        builder: (context) => OpinionForm(token: token)
      )
    );
  }

}