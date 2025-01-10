import 'package:flutter/material.dart';
 
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
         title: Text('CatApp', 
         style: TextStyle(
          color: Colors.black
         ),),
         centerTitle: true,
      ),
    );
  }
}