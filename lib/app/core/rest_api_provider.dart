import 'package:flutter/material.dart';
import 'package:portugal_guide/app/helpers/env_key_helper_config.dart';

class AppRestApiProvider extends ChangeNotifier {

  String apiUrl = '${EnvKeyHelperConfig.mocApi1}/user/';
  
}