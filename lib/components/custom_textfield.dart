import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {

  final String? hintText;
  final TextEditingController? controller;
  final String? Function(String?)? validate;
  final Function(String?)? onsave;
  final int? maxLines;
  final bool isPassword;
  final bool enable;
  final bool? check;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;
  final Widget? prefix;
  final Widget? suffix;

  CustomTextField({
  this.controller,
  this.enable=true,
  this.check,
  this.focusNode,
  this.hintText,
  this.isPassword=false,
  this.keyboardType,
  this.maxLines,
  this.onsave,
  this.prefix,
  this.suffix,
  this.textInputAction,
  this.validate
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      enabled: enable==true?true:enable,
      maxLines: maxLines==null?1:maxLines,
      onSaved: onsave,
      focusNode: focusNode,
      textInputAction: textInputAction,
      keyboardType: keyboardType==null?TextInputType.name:keyboardType,
      controller: controller,
      validator: validate,
      obscureText: isPassword==false?false:isPassword,
      decoration: InputDecoration(
        prefixIcon: prefix ,
          suffixIcon: suffix,
          labelText: hintText??"Hint Text ...",
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(
              style: BorderStyle.solid,
              color: Color(0XFF909A9E),
            )
          ),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(
                style: BorderStyle.solid,
                color: Color(0XFF909A9E),
              )
          ),
          focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(
                style: BorderStyle.solid,
                color: Theme.of(context).primaryColor,
              )
          ),
          errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(
                style: BorderStyle.solid,
                color: Colors.red,
              )
          )
      ),
    );
  }
}
