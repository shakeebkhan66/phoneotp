import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:phoneotp/screens/home_screen.dart';

enum MobileVerificationState{
  SHOW_MOBILE_FORM_STATE,                    // here user can enter his mobile number
  SHOW_OTP_FORM_STATE,                      // here user will enter the otp received on his mobile
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {

  MobileVerificationState currentState = MobileVerificationState.SHOW_MOBILE_FORM_STATE;
  final phoneController = TextEditingController();
  final otpController = TextEditingController();

  FirebaseAuth _auth = FirebaseAuth.instance;
  late String verificationId;
  bool showLoading = false;

  void signInWithPhoneAuthCredential(AuthCredential credential) async{

    setState(() {
      showLoading = true;
    });
    try {
      final authCredential = await _auth.signInWithCredential(credential);
      setState(() {
        showLoading = false;
      });
      if(authCredential.user != null){
        Navigator.push(context, MaterialPageRoute(builder: (context)=> HomeScreen()));
      }
    } on FirebaseAuthException catch (e) {
     setState(() {
       showLoading = false;
     });
     _scaffoldKey.currentState!.showSnackBar(SnackBar(content: Text(e.message.toString())));
    }

  }

  getMobileFormWidget(context){
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15.0),
      child: Column(
        children: [
          Spacer(),
          TextField(
            controller: phoneController,
            decoration: InputDecoration(
              hintText: "Phone Number",
            ),
          ),
          SizedBox(height: 16),
          MaterialButton(
              onPressed: () async{
                setState(() {
                  showLoading = true;
                });
               await _auth.verifyPhoneNumber(
                    phoneNumber: phoneController.text,
                    verificationCompleted: (PhoneAuthCredential phoneAuthCredential) async{
                      setState(() {
                        showLoading = false;
                      });
                      // signInWithPhoneAuthCredential(phoneAuthCredential);
                    },
                    verificationFailed: (verificationFailed) async{
                      setState(() {
                        showLoading = false;
                      });
                      _scaffoldKey.currentState!.showSnackBar(SnackBar(content: Text(verificationFailed.message.toString())));
                    },
                    codeSent: (verificationId, resendingToken) async{
                    setState(() {
                      showLoading = false;
                      currentState = MobileVerificationState.SHOW_OTP_FORM_STATE;
                      this.verificationId = verificationId;
                    });
                    },
                    codeAutoRetrievalTimeout: (verificationId) async{},
                );
              },
              child: Text("SEND"),
              color: Colors.green,
            textColor: Colors.white,
          ),
          Spacer(),
        ],
      ),
    );
  }
  getOtpFormWidget(context){
    return Column(
      children: [
        Spacer(),
        TextField(
          controller: otpController,
          decoration: InputDecoration(
            hintText: "Enter OTP",
          ),
        ),
        SizedBox(height: 16),
        MaterialButton(
          onPressed: () async{
            // ignore: non_constant_identifier_names
            final AuthCredential =
            PhoneAuthProvider.credential(verificationId: verificationId, smsCode: otpController.text
            );
            signInWithPhoneAuthCredential(AuthCredential);

          },
          child: Text("VERIFY"),
          color: Colors.green,
          textColor: Colors.white,
        ),
        Spacer(),
      ],
    );
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
        body: Container(
          child: showLoading ? Center(child: CircularProgressIndicator()) : currentState == MobileVerificationState.SHOW_MOBILE_FORM_STATE ?
          getMobileFormWidget(context) :
          getOtpFormWidget(context),
        ),
    );
  }

}
