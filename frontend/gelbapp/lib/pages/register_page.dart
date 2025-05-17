import 'package:flutter/material.dart';
import '../services/auth_service.dart'; // Adjust the path based on your structure

class RegisterPage extends StatefulWidget {
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _obscurePassword = true;
  bool _isButtonDisabled = false;

  String? _authError;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Card(
          color: const Color.fromARGB(255, 15, 15, 14),
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: SizedBox(
              width: 300,
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'GelbApp',
                          style: TextStyle(fontSize: 24, color: Colors.white),
                        ),
                        Image.asset(
                          'assets/logo.png',
                          width: 50,
                          height: 50,
                        ),
                      ],
                    ),
                    SizedBox(height: 30),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Username',
                        labelStyle: TextStyle(color: Colors.white),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFFFEDD37), width: 2.0),
                        ),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white24),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your username';
                        }
                        return null;
                      },
                      style: TextStyle(color: Colors.white),
                      cursorColor: Color(0xFFFEDD37),
                      controller: _usernameController,
                    ),
                    SizedBox(height: 30),
                                        TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Email',
                        labelStyle: TextStyle(color: Colors.white),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFFFEDD37), width: 2.0),
                        ),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white24),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        return null;
                      },
                      style: TextStyle(color: Colors.white),
                      cursorColor: Color(0xFFFEDD37),
                      controller: _emailController,
                    ),
                    SizedBox(height: 30),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        labelStyle: TextStyle(color: Colors.white),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFFFEDD37), width: 2.0),
                        ),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white24),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility : Icons.visibility_off,
                            color: Colors.grey[400],
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      cursorColor: Color(0xFFFEDD37),
                      style: TextStyle(color: Colors.white),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        return null;
                      },
                    ),
                    if (_authError != null) // <-- show error if login fails
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: Text(
                          _authError!,
                          style: TextStyle(color: Colors.redAccent),
                        ),
                      ),
                    SizedBox(height: 35),
                    Center(
                      child: ElevatedButton(
                      onPressed: _isButtonDisabled
                          ? null
                          : () async {
                              if (_formKey.currentState!.validate()) {
                                setState(() => _isButtonDisabled = true); // disable button
                                setState(() {
                                    _authError = null; // clear error
                                  });
                                final authService = AuthService();
                                final success = await authService.register(
                                  _usernameController.text,
                                  _emailController.text,
                                  _passwordController.text,
                                );

                                if (success) {
                                  setState(() {
                                    _authError = null; // clear error
                                  });
                                  Navigator.pushReplacementNamed(context, '/');
                                } else {
                                  setState(() {
                                    _authError = 'Error registering. Please try again.';
                                  });
                                }
                                
                                // Re-enable button after the process
                                setState(() => _isButtonDisabled = false);
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color.fromARGB(211, 254, 221, 55),
                      ),
                      child: _isButtonDisabled
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text('Register', style: TextStyle(color: Colors.white)),
                    )
                    ),
                    SizedBox(height: 40),
                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.pushNamed(context, '/login'),
                        child: Text('Already have an account?', style: TextStyle(color: Colors.grey[400])),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
