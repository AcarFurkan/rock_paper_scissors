import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phone_form_field/phone_form_field.dart';
import 'package:rock_paper_scissors_mobile/scanner_screen.dart';
import 'package:rock_paper_scissors_mobile/user.dart';
import 'package:rock_paper_scissors_mobile/user_preferences.dart';

enum AuthPage { login, register }

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  AuthPage authPage = AuthPage.login;
  final PhoneController phoneController = PhoneController(
      initialValue: const PhoneNumber(isoCode: IsoCode.TR, nsn: ''));

  final nameController = TextEditingController();

  final ilController = TextEditingController();

  final ilceController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  String get phoneNumber =>
      "+${phoneController.value.countryCode}${phoneController.value.nsn}";
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((e) {
      checkLocalUser();
    });
  }

  checkLocalUser() async {
    final user = await UserPreferences.getUser();
    if (user != null) {
      Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute<void>(
              builder: (BuildContext context) => ControllerPage()),
          (Route<dynamic> route) => false);
    }
  }

  Future<User?> checkIsUser() async {
    try {
      DocumentSnapshot documentSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(phoneNumber)
          .get();

      if (documentSnapshot.exists) {
        print("User data: ${documentSnapshot.data()}");
        final res = documentSnapshot.data() as Map<String, dynamic>?;
        if (res != null) {
          return User.fromMap(res);
        } else {
          return null;
        }
      } else {
        print("No user found with this phone number.");
        return null;
      }
    } catch (e) {
      print("Error reading document: $e");
      return null;
    }
  }

  Future<void> createUser(User user) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(phoneNumber)
        .set(user.toMap());
  }

  bool loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Giris Yap'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Form(
            key: formKey,
            child: Column(
              children: [
                const SizedBox(
                  height: 10,
                ),
                PhoneField(
                  phoneController: phoneController,
                ),
                if (authPage == AuthPage.register)
                  Column(
                    children: [
                      const SizedBox(
                        height: 10,
                      ),
                      TextFormField(
                        controller: nameController,
                        inputFormatters: <TextInputFormatter>[
                          FilteringTextInputFormatter.allow(
                              RegExp(r'[a-zA-ZğüşöçıİĞÜŞÖÇ\s]+')),
                        ],
                        validator: (value) {
                          value ??= "";
                          if (value.trim().length < 5) {
                            return "çok kısa en az 5 karakter olmali";
                          }

                          return null;
                        },
                        decoration: InputDecoration(
                            labelText: "Isim SoyIsim",
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15))),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      TextFormField(
                        inputFormatters: <TextInputFormatter>[
                          FilteringTextInputFormatter.allow(RegExp(
                              r'[a-zA-ZğüşöçıİĞÜŞÖÇ]')), // Sadece harfleri kabul eder
                        ],
                        controller: ilController,
                        validator: (value) {
                          value ??= "";
                          if (value.trim().length < 2) {
                            return "çok kisa en az 2 karakter olmali";
                          }

                          return null;
                        },
                        decoration: InputDecoration(
                            labelText: "IL",
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15))),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      TextFormField(
                        inputFormatters: <TextInputFormatter>[
                          FilteringTextInputFormatter.allow(RegExp(
                              r'[a-zA-ZğüşöçıİĞÜŞÖÇ]')), // Sadece harfleri kabul eder
                        ],
                        controller: ilceController,
                        validator: (value) {
                          value ??= "";
                          if (value.trim().length < 2) {
                            return "çok kisa en az 2 karakter olmali";
                          }

                          return null;
                        },
                        decoration: InputDecoration(
                            labelText: "ILCE",
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15))),
                      ),
                    ],
                  ),
                const SizedBox(
                  height: 10,
                ),
                if (!loading)
                  Column(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                            onPressed: () {
                              FocusManager.instance.primaryFocus?.unfocus();

                              if (authPage == AuthPage.login) {
                                setState(() {
                                  authPage = AuthPage.register;
                                });
                              } else {
                                setState(() {
                                  authPage = AuthPage.login;
                                });
                              }
                            },
                            child: Text(authPage == AuthPage.login
                                ? 'Hesabin yok mu ? Hemen Kayit ol!'
                                : 'Hesabin var mi ? Hemen Giris Yap!')),
                      ),
                      ElevatedButton(
                          onPressed: () {
                            if (authPage == AuthPage.login) {
                              if (formKey.currentState!.validate()) {
                                login();
                              }
                            } else {
                              if (formKey.currentState!.validate() &&
                                  phoneController.value.isValid()) {
                                FocusManager.instance.primaryFocus?.unfocus();

                                register();
                              }
                            }
                          },
                          child: Text(authPage == AuthPage.register
                              ? 'Kayit Ol'
                              : 'Giris Yap'))
                    ],
                  )
                else
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  )
              ],
            ),
          ),
        ),
      ),
    );
  }

  login() async {
    try {
      setState(() {
        loading = true;
      });
      final user = await checkIsUser();
      setState(() {
        loading = false;
      });
      if (user == null) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
            const SnackBar(content: Text('Kullanici bulunamadi')));
      } else {
        saveUserToLocal(user);
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(const SnackBar(
            backgroundColor: Colors.green, content: Text('Giris Basarili')));
        Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute<void>(
                builder: (BuildContext context) => ControllerPage()),
            (Route<dynamic> route) => false);
      }
    } catch (e) {
      setState(() {
        loading = false;
      });
    }
  }

  saveUserToLocal(User user) async {
    try {
      await UserPreferences.saveUser(user);
    } catch (e) {
      log('shared pref error');
    }
  }

  register() async {
    try {
      setState(() {
        loading = true;
      });
      var user = await checkIsUser();

      if (user == null) {
        //register
        user = User(
            phone: phoneNumber,
            name: nameController.text.trim(),
            city: ilController.text.trim(),
            district: ilceController.text.trim());
        await createUser(user);

        setState(() {
          loading = false;
        });
        saveUserToLocal(user);

        Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute<void>(
                builder: (BuildContext context) => ControllerPage()),
            (Route<dynamic> route) => false);
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(const SnackBar(
            backgroundColor: Colors.green,
            content: Text('Kayit Basiriyla olusturuldu')));
      } else {
        setState(() {
          loading = false;
        });
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(const SnackBar(
            content: Text('Bu numara ile kayitli kullanici var.')));
      }
    } catch (e) {
      setState(() {
        loading = false;
      });
    }
  }
}

class PhoneField extends StatelessWidget {
  const PhoneField({super.key, required this.phoneController});
  final PhoneController phoneController;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: PhoneFormField(
        controller: phoneController,
        validator: PhoneValidator.compose([
          PhoneValidator.required(context,
              errorText: 'Telefon numarası boş bırakılamaz'),
          PhoneValidator.validMobile(context,
              errorText: 'Geçerli bir telefon giriniz'),
        ]),
        inputFormatters: [LengthLimitingTextInputFormatter(13)],
        countrySelectorNavigator: const CountrySelectorNavigator.page(),
        onChanged: (phoneNumber) => print('changed into $phoneNumber'),
        enabled: true,
        isCountrySelectionEnabled: false,
        isCountryButtonPersistent: true,
        decoration: InputDecoration(
          labelText: 'Telefon Numarası',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        countryButtonStyle: const CountryButtonStyle(
          showDialCode: true,
          showIsoCode: true,
          showFlag: true,
          flagSize: 20,
        ),
      ),
    );
  }
}
