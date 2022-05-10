import 'package:flutter/material.dart';
import 'package:flutter_pw_validator/flutter_pw_validator.dart';
import 'package:pomodoro_app/auth/auth_screen.dart';
import 'package:pomodoro_app/constants/color_constants.dart';
import 'package:provider/provider.dart';
import '../services/auth.dart';
import '../models/http_exception.dart';

class AuthCard extends StatefulWidget {
  const AuthCard({Key? key}) : super(key: key);

  @override
  State<AuthCard> createState() => _AuthCardState();
}

class _AuthCardState extends State<AuthCard> {
  final GlobalKey<FormState> _formKey=GlobalKey();
  AuthMode _authMode=AuthMode.Login;
  Map<String, String> _authData={
    'email' : '',
    'password' : '',
  };

  bool _isLoading=false;
  final _passwordController=TextEditingController();
  bool _obscureText=true;

   _showErrorDialog(String message){
    showDialog(
        context: context,
        builder: (ctx){
          return AlertDialog(
            title:Text('An Error Occured!'),
            content: Text(message),
            actions: [
              TextButton(
                  onPressed:(){
                    Navigator.of(ctx).pop();
                  },
                  child: Text('Okay'))
            ],
          );
        });
  }


  Future<void> _submit()async{
    if(!_formKey.currentState!.validate()){
      //INVALID
      return;
    }
    _formKey.currentState!.save();
    setState(() {
      _isLoading=true;
    });
    try{
      if(_authMode ==AuthMode.Login){
        await Provider.of<Auth>(context,listen: false).login(
            _authData['email']!,
            _authData['password']!);
      }else{
        await Provider.of<Auth>(context,listen: false).signUp(
            _authData['email']!,
            _authData['password']!);
      }
    } on HttpException catch(error){
      var errorMessage = 'Authentication failed!';
       if(error.toString().contains('EMAIL_EXISTS')){
         errorMessage ='This e-mail address is already in use.';
       }else if(error.toString().contains('INVALID_EMAIL')){
         errorMessage='This is not a valid e-mail address';
       }else if(error.toString().contains('WEAK_PASSWORD')){
         errorMessage='This password is too weak.';
       }else if(error.toString().contains('EMAIL_NOT_FOUND')){
         errorMessage='Could not find a user with that e-mail.';
       }else if(error.toString().contains('INVALID_PASSWORD')){
         errorMessage='Invalid password.';
       }
      _showErrorDialog(errorMessage);
    }catch(error){
      const errorMessage = 'Could not authenticate you. Please try again later.';
      _showErrorDialog(errorMessage);
    }
    setState(() {
      _isLoading=false;
    });
  }

  void _switchAuthMode(){
    if(_authMode ==AuthMode.Login){
      setState(() {
        _authMode=AuthMode.SignUp;
      });
    }else {
      setState(() {
        _authMode=AuthMode.Login;
      });
    }
  }



  @override
  Widget build(BuildContext context) {

    final deviceSize=MediaQuery.of(context).size;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 8,
      child: Container(
        height: _authMode ==AuthMode.SignUp
            ? deviceSize.height*0.6
            : deviceSize.height*0.4,
        constraints:
        BoxConstraints(
            minHeight: _authMode ==AuthMode.SignUp
                ? deviceSize.height*0.6
                : deviceSize.height*0.4
        ),
        width: deviceSize.width*0.75,
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  decoration: InputDecoration(
                      labelText: 'E-Mail',
                      prefixIcon:Icon(
                          Icons.email,
                          color: Theme.of(context).primaryColor),
                      border:OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20)) ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (val){
                    if(val!.isEmpty || !val.contains('@')){
                      return 'Invalid E-Mail!';
                    }
                    return null;
                  },
                  onSaved: (val){
                    _authData['email'] =val!;
                  },
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 10.0),
                  child: TextFormField(
                    decoration: InputDecoration(
                        suffix: InkWell(
                          onTap:(){
                            setState(() {
                              _obscureText = !_obscureText;
                            });
                          },
                         child: Icon(
                           _obscureText ? Icons.visibility : Icons.visibility_off,
                           color: ColorConstants.primaryColor,
                           size: MediaQuery.of(context).size.width * 0.05,
                         ),
                        ),
                        labelText: 'Password',
                        prefixIcon:Icon(
                            Icons.lock,
                            color: Theme.of(context).primaryColor),
                        border:OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20)) ),
                        obscureText: _obscureText,

                    controller: _passwordController,
                    validator: (val){
                      if(val!.isEmpty || val.length <5){
                        return 'Password is too short';
                      }
                    },
                    onSaved: (val){
                      _authData['password'] =val!;
                    },
                  ),
                ),
                if(_authMode ==AuthMode.SignUp)
                  Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: TextFormField(
                      enabled: _authMode ==AuthMode.SignUp,
                      decoration: InputDecoration(
                          labelText: 'Confirm Password',
                          border:OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20))),
                      obscureText: true,
                      validator: _authMode ==AuthMode.SignUp
                          ? (val) {
                        if(val != _passwordController.text){
                          return 'Passwords do not match!';
                        }
                      }
                          : null,
                    ),
                  ),
                if(_authMode==AuthMode.SignUp)
                  Padding(
                    padding: const EdgeInsets.only(top:5.0),
                    child: FlutterPwValidator(
                        width: deviceSize.width*0.8,
                        height: deviceSize.height*0.12,
                        defaultColor:ColorConstants.grey,
                        failureColor:ColorConstants.error,
                        numericCharCount: 1,
                        normalCharCount: 1,
                        minLength: 6,
                        onSuccess:(){
                          print('MATCHED');
                        },
                        controller:_passwordController),
                  ),
                if(_isLoading)
                  const CircularProgressIndicator()
                else
                  ConstrainedBox(
                    constraints: BoxConstraints.tightFor(
                        width: deviceSize.width*0.5,
                        height: deviceSize.height*0.09),
                    child: Padding(
                      padding: const EdgeInsets.only(
                          top:40),
                      child: ElevatedButton(
                        child: Text(_authMode ==AuthMode.Login ? 'LOGIN' : 'SIGN UP'),
                        onPressed: _submit,
                        style: ButtonStyle(
                            shape:MaterialStateProperty.resolveWith<OutlinedBorder>((_) {
                              return RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10));}),
                            backgroundColor: MaterialStateProperty.all(
                                Theme.of(context).primaryColor)),),
                    ),
                  ),
                TextButton(
                  child: Text('${_authMode ==AuthMode.Login
                      ? 'SIGNUP'
                      : 'LOGIN'}'),
                  onPressed: _switchAuthMode,style: TextButton.styleFrom(
                    padding:EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4),
                    tapTargetSize:MaterialTapTargetSize.shrinkWrap,
                    textStyle: TextStyle(
                        color: Theme.of(context).primaryColor
                    )),)
              ],
            ),
          ),
        ),
      ),
    );
  }
}