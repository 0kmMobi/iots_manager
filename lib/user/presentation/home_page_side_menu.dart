import 'package:iots_manager/user/bloc/user_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomePageSideMenu extends StatelessWidget {
  const HomePageSideMenu({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          const DrawerHeader(
            decoration: BoxDecoration(
                color: Colors.green,
                //image: DecorationImage( fit: BoxFit.fill, image: AssetImage('assets/images/cover.jpg'))
            ),
            child: Text( 'Side menu', style: TextStyle(color: Colors.white, fontSize: 25), ),
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () => {Navigator.of(context).pop()},
          ),
          ListTile(
            leading: const Icon(Icons.exit_to_app),
            title: const Text('Logout'),
            onTap: () {
              BlocProvider.of<UserBloc>(context).add(LogOutEvent());
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}