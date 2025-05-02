import 'package:flutter/material.dart';
import 'package:helps/create/posts_list_screen.dart';

import '../auth/check/check_screen.dart';
import '../auth/login/login_screen.dart';
import '../auth/signUp/sign_up_screen.dart';
import '../launch/launch_screen.dart';



Map<String, WidgetBuilder> appRoutes = {

    '/': (context) => const SplashScreen(),
    '/login': (context) => const LoginScreen(),
    '/signup': (context) => const SignupScreen(),
    '/posts': (context) => const PostsListScreen(),
    '/check': (context) => const CheckAuthScreen(),



};