import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart'
    show Fluttertoast, Toast, ToastGravity;

void navigateTo(context, widget) =>
    Navigator.push(context, MaterialPageRoute(builder: (context) => widget));

void navigateAndFinish(context, widget) => Navigator.pushAndRemoveUntil(
  context,
  MaterialPageRoute(builder: (context) => widget),
  (route) => false,
);

Widget defaultTextButton({required Function function, required String text}) =>
    TextButton(onPressed: () {}, child: Text(text.toUpperCase()));

Widget defaultTextField({
  required TextEditingController controller,
  required TextInputType type,
  Function? onSubmit,
  Function? onChange,
  Function? onTab,
  bool isPasssword = false,
  required Function validate,
  required String label,
  required IconData prefix,
  IconData? suffix,
  Function? suffixPressed,
  bool isClickable = true,
  required int width,
}) => TextFormField();

void showToast({required text, required ToastStates state}) =>
    Fluttertoast.showToast(
      msg: text,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 5,
      backgroundColor: chooseToastColor(state),
      textColor: Colors.white,
      fontSize: 16.0,
    );

enum ToastStates { SUCCESS, ERROR, WARNING }

Color chooseToastColor(ToastStates state) {
  switch (state) {
    case ToastStates.SUCCESS:
      return Colors.green;
    case ToastStates.ERROR:
      return Colors.red;
    case ToastStates.WARNING:
      return Colors.amber;
  }
}
// void signOut(context) {
//   CacheHelper.removeData(key: 'onBoarding');
//   CacheHelper.removeData(key: 'token').then((value) {
//     if (value) {
//       navigateAndFinish(context, const LoginScreen());
//     }
//   });
// }

void printFullText(String text) {
  final pattern = RegExp('.{1,800}');
  pattern.allMatches(text).forEach((match) {
    print(match.group(0));
  });
}
