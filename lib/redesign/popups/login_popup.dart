import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:politicsstatements/redesign/resources/theme.dart';
import 'package:politicsstatements/redesign/services/auth_service.dart';
import 'package:politicsstatements/redesign/widgets/commong_widgets.dart';

Future<bool?> showLoginPopup(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (context) => LoginPopup(),
  );
}

Future<void> showForgotPasswordPopup(BuildContext context, String? email) {
  return showDialog<void>(
    context: context,
    builder: (context) => ForgotPasswordPopup(initialEmail: email),
  );
}

Future<void> showAccountConflictPopup(BuildContext context, String email) {
  return showDialog<void>(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: AppTheme.cardDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        width: kIsWeb ? 450 : double.infinity,
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
                         // Header
             ModalTitle(title: 'Հաշիվը արդեն գոյություն ունի'),
             
             SizedBox(height: 16),
             
             // Explanation
             Container(
               padding: EdgeInsets.all(16),
               decoration: BoxDecoration(
                 color: Colors.orange.withValues(alpha: 0.1),
                 borderRadius: BorderRadius.circular(8),
                 border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
               ),
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   Row(
                     children: [
                       Icon(
                         Icons.info_outline,
                         color: Colors.orange,
                         size: 20,
                       ),
                       SizedBox(width: 12),
                       Expanded(
                         child: Text(
                           'Հաշիվների կոնֆլիկտ',
                           style: TextStyle(
                             color: Colors.orange,
                             fontSize: 16,
                             fontWeight: FontWeight.w600,
                           ),
                         ),
                       ),
                     ],
                   ),
                   SizedBox(height: 8),
                   Text(
                     'Դուք արդեն ունեք հաշիվ "$email" էլ․ փոստով՝ էլ․ փոստ/գաղտնաబառ մուտքի եղանակով:',
                     style: AppTheme.itemSubTitleStyle,
                   ),
                 ],
               ),
             ),
             
             SizedBox(height: 20),
             
             Text(
               'Ընտրեք այս տարբերակներից մեկը՝',
               style: AppTheme.activeTextsStyle.copyWith(
                 fontWeight: FontWeight.w600,
               ),
             ),
            
            SizedBox(height: 16),
            
            // Option 1: Sign in with password
            OutlinedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Close any existing dialogs and show login
                Navigator.of(context).pop();
                showLoginPopup(context);
              },
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.all(16),
                side: BorderSide(color: AppTheme.accentCyan),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.email, color: AppTheme.accentCyan),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                                             children: [
                         Text(
                           'Մուտք էլ․ փոստով և գաղտնաբառով',
                           style: TextStyle(
                             color: AppTheme.accentCyan,
                             fontSize: 16,
                             fontWeight: FontWeight.w500,
                           ),
                         ),
                         SizedBox(height: 4),
                         Text(
                           'Օգտագործեք ձեր գոյություն ունեցող էլ․ փոստը և գաղտնաբառը',
                           style: AppTheme.itemSubTitleStyle.copyWith(fontSize: 12),
                         ),
                       ],
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 12),
            
            // Option 2: Reset password
            OutlinedButton(
              onPressed: () {
                Navigator.of(context).pop();
                showForgotPasswordPopup(context, email);
              },
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.all(16),
                side: BorderSide(color: AppTheme.dividerDark),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.lock_reset, color: AppTheme.accentCyan),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                                             children: [
                         Text(
                           'Վերականգնել գաղտնաբառը',
                           style: TextStyle(
                             color: AppTheme.accentCyan,
                             fontSize: 16,
                             fontWeight: FontWeight.w500,
                           ),
                         ),
                         SizedBox(height: 4),
                         Text(
                           'Ստացեք գաղտնաբառի վերականգնման նամակ, եթե մոռացել եք ձեր գաղտնաբառը',
                           style: AppTheme.itemSubTitleStyle.copyWith(fontSize: 12),
                         ),
                       ],
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 20),
            
            // Info about linking accounts
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.accentCyan.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: AppTheme.accentCyan,
                    size: 16,
                  ),
                  SizedBox(width: 8),
                                     Expanded(
                     child: Text(
                       'Էլ․ փոստ/գաղտնաբառով մուտք գործելուց հետո կարող եք կապել ձեր Google հաշիվը հաշվի կարգավորումներում՝ երկու մուտքի եղանակներն էլ օգտագործելու համար:',
                       style: AppTheme.itemSubTitleStyle.copyWith(fontSize: 12),
                     ),
                   ),
                 ],
               ),
             ),
             
             SizedBox(height: 16),
             
             // Cancel button
             TextButton(
               onPressed: () => Navigator.of(context).pop(),
               child: Text(
                 'Չեղարկել',
                 style: AppTheme.itemSubTitleStyle,
               ),
             ),
          ],
        ),
      ),
    ),
  );
}

class LoginPopup extends StatefulWidget {
  @override
  State<LoginPopup> createState() => _LoginPopupState();
}

class _LoginPopupState extends State<LoginPopup> {
  final AuthService _authService = AuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  
  bool _isLoading = false;
  bool _isSignUp = false;
  bool _showResetPassword = false;
  String _errorMessage = '';
  String _successMessage = '';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _sendPasswordReset() async {
    if (_emailController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Խնդրում ենք մուտքագրել ձեր էլ․ փոստի հասցեն';
        _successMessage = '';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _successMessage = '';
    });

    try {
      final success = await _authService.sendPasswordResetEmail(_emailController.text.trim());
      if (success) {
        setState(() {
          _successMessage = 'Գաղտնաբառի վերականգնման նամակը ուղարկվեց! Ստուգեք ձեր էլ․ փոստը:';
          _showResetPassword = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = _authService.getAuthErrorMessage(e);
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _successMessage = '';
    });

    try {
      final success = await _authService.signInWithGoogle();
      if (success) {
        Navigator.of(context).pop(true);
      } else {
        setState(() {
          _errorMessage = 'Google-ով մուտքը ձախողվեց: Խնդրում ենք նորից փորձել:';
        });
      }
    } catch (e) {
      final errorMessage = _authService.getAuthErrorMessage(e);
      
      // Check if this is an account conflict error and show helpful popup
      if (errorMessage.contains('հաշիվ գոյություն ունի այս էլ․ փոստով') || 
          errorMessage.contains('account with this email already exists')) {
        // Try to extract email from the error or use current email field
        String? email = _emailController.text.trim().isNotEmpty 
            ? _emailController.text.trim() 
            : null;
            
        setState(() {
          _isLoading = false;
        });
        
        if (email != null && email.isNotEmpty) {
          showAccountConflictPopup(context, email);
        } else {
          setState(() {
            _errorMessage = errorMessage + '\n\nԽնդրում ենք մուտքագրել ձեր էլ․ փոստը վերևում և նորից փորձել, կամ օգտագործել "Մոռացե՞լ եք գաղտնաբառը"՝ գաղտնաբառը վերականգնելու համար:';
          });
        }
        return;
      } else {
        setState(() {
          _errorMessage = errorMessage;
        });
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _signInWithEmail() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Խնդրում ենք լրացրել բոլոր դաշտերը';
        _successMessage = '';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _successMessage = '';
    });

    try {
      bool success;
      if (_isSignUp) {
        if (_nameController.text.isEmpty) {
          setState(() {
            _errorMessage = 'Խնդրում ենք մուտքագրել ձեր անունը';
            _isLoading = false;
          });
          return;
        }
        success = await _authService.createAccountWithEmailAndPassword(
          _emailController.text.trim(),
          _passwordController.text,
          _nameController.text.trim(),
        );
      } else {
        success = await _authService.signInWithEmailAndPassword(
          _emailController.text.trim(),
          _passwordController.text,
        );
      }

      if (success) {
        Navigator.of(context).pop(true);
      } else {
        setState(() {
          _errorMessage = _isSignUp 
            ? 'Հաշիվ ստեղծելը ձախողվեց: Խնդրում ենք ստուգել մանրամասները:' 
            : 'Մուտքը ձախողվեց: Խնդրում ենք ստուգել ձեր տվյալները:';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = _authService.getAuthErrorMessage(e);
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.cardDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        width: kIsWeb ? 400 : double.infinity,
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            ModalTitle(
              title: _showResetPassword ? 'Գաղտնաբառի վերականգնում' : 
                     _isSignUp ? 'Հաշիվ ստեղծել' : 'Մուտք',
            ),
            
            SizedBox(height: 24),

            // Success message
            if (_successMessage.isNotEmpty)
              Container(
                padding: EdgeInsets.all(16),
                margin: EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      color: Colors.green,
                      size: 20,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _successMessage,
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Error message
            if (_errorMessage.isNotEmpty)
              Container(
                padding: EdgeInsets.all(16),
                margin: EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 20,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _errorMessage,
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            if (_showResetPassword) ...[
              // Reset password mode
              Text(
                'Մուտքագրեք ձեր էլ․ փոստի հասցեն, և մենք ձեզ կուղարկենք գաղտնաբառի վերականգնման հղում:',
                style: AppTheme.itemSubTitleStyle,
              ),
              SizedBox(height: 16),
              
              // Email field for reset
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: AppTheme.activeTextsStyle,
                decoration: InputDecoration(
                  hintText: 'Էլ․ փոստ',
                  hintStyle: AppTheme.textFieldHintStyle,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppTheme.dividerDark),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppTheme.dividerDark),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppTheme.accentCyan),
                  ),
                ),
              ),
              
              SizedBox(height: 24),

              // Send reset email button
              OutlinedButton(
                onPressed: _isLoading ? null : _sendPasswordReset,
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: AppTheme.accentCyan),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentCyan),
                      ),
                    )
                  : Text(
                      'Ուղարկել վերականգնման նամակ',
                      style: TextStyle(
                        color: AppTheme.accentCyan,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
              ),

              SizedBox(height: 16),

              // Back to login button
              TextButton(
                onPressed: _isLoading ? null : () {
                  setState(() {
                    _showResetPassword = false;
                    _errorMessage = '';
                    _successMessage = '';
                  });
                },
                child: Text(
                  'Վերադառնալ մուտքի էջ',
                  style: AppTheme.strongStyle,
                ),
              ),
            ] else ...[
              // Normal login/signup mode
              
                             // Name field for sign up
               if (_isSignUp) ...[
                 TextField(
                   controller: _nameController,
                   style: AppTheme.activeTextsStyle,
                   decoration: InputDecoration(
                     hintText: 'Անուն Ազգանուն',
                     hintStyle: AppTheme.textFieldHintStyle,
                     border: OutlineInputBorder(
                       borderRadius: BorderRadius.circular(8),
                       borderSide: BorderSide(color: AppTheme.dividerDark),
                     ),
                     enabledBorder: OutlineInputBorder(
                       borderRadius: BorderRadius.circular(8),
                       borderSide: BorderSide(color: AppTheme.dividerDark),
                     ),
                     focusedBorder: OutlineInputBorder(
                       borderRadius: BorderRadius.circular(8),
                       borderSide: BorderSide(color: AppTheme.accentCyan),
                     ),
                   ),
                 ),
                 SizedBox(height: 16),
               ],

               // Email field
               TextField(
                 controller: _emailController,
                 keyboardType: TextInputType.emailAddress,
                 style: AppTheme.activeTextsStyle,
                 decoration: InputDecoration(
                   hintText: 'Էլ․ փոստ',
                   hintStyle: AppTheme.textFieldHintStyle,
                   border: OutlineInputBorder(
                     borderRadius: BorderRadius.circular(8),
                     borderSide: BorderSide(color: AppTheme.dividerDark),
                   ),
                   enabledBorder: OutlineInputBorder(
                     borderRadius: BorderRadius.circular(8),
                     borderSide: BorderSide(color: AppTheme.dividerDark),
                   ),
                   focusedBorder: OutlineInputBorder(
                     borderRadius: BorderRadius.circular(8),
                     borderSide: BorderSide(color: AppTheme.accentCyan),
                   ),
                 ),
               ),
               
               SizedBox(height: 16),

               // Password field
               TextField(
                 controller: _passwordController,
                 obscureText: true,
                 style: AppTheme.activeTextsStyle,
                 decoration: InputDecoration(
                   hintText: 'Գաղտնաբառ',
                   hintStyle: AppTheme.textFieldHintStyle,
                   border: OutlineInputBorder(
                     borderRadius: BorderRadius.circular(8),
                     borderSide: BorderSide(color: AppTheme.dividerDark),
                   ),
                   enabledBorder: OutlineInputBorder(
                     borderRadius: BorderRadius.circular(8),
                     borderSide: BorderSide(color: AppTheme.dividerDark),
                   ),
                   focusedBorder: OutlineInputBorder(
                     borderRadius: BorderRadius.circular(8),
                     borderSide: BorderSide(color: AppTheme.accentCyan),
                   ),
                 ),
               ),

               // Forgot password link (only show during sign in)
               if (!_isSignUp) ...[
                 SizedBox(height: 8),
                 Align(
                   alignment: Alignment.centerRight,
                   child: TextButton(
                     onPressed: _isLoading ? null : () {
                       setState(() {
                         _showResetPassword = true;
                         _errorMessage = '';
                         _successMessage = '';
                       });
                     },
                     child: Text(
                       'Մոռացե՞լ եք գաղտնաբառը',
                       style: AppTheme.strongStyle.copyWith(fontSize: 14),
                     ),
                   ),
                 ),
               ],

              SizedBox(height: 16),

              // Email Sign In/Up Button
              OutlinedButton(
                onPressed: _isLoading ? null : _signInWithEmail,
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: AppTheme.accentCyan),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentCyan),
                      ),
                    )
                                       : Text(
                       _isSignUp ? 'Ստեղծել հաշիվ' : 'Մուտք',
                       style: TextStyle(
                         color: AppTheme.accentCyan,
                         fontSize: 16,
                         fontWeight: FontWeight.w500,
                       ),
                     ),
               ),

               SizedBox(height: 16),

               // Divider
               Row(
                 children: [
                   Expanded(child: Divider(color: AppTheme.dividerDark)),
                   Padding(
                     padding: EdgeInsets.symmetric(horizontal: 16),
                     child: Text(
                       'կամ',
                       style: AppTheme.itemSubTitleStyle,
                     ),
                   ),
                   Expanded(child: Divider(color: AppTheme.dividerDark)),
                 ],
               ),

               SizedBox(height: 16),

               // Google Sign In Button
               OutlinedButton(
                   onPressed: _isLoading ? null : _signInWithGoogle,
                   style: OutlinedButton.styleFrom(
                     padding: EdgeInsets.symmetric(vertical: 16),
                     side: BorderSide(color: AppTheme.dividerDark),
                     shape: RoundedRectangleBorder(
                       borderRadius: BorderRadius.circular(8),
                     ),
                   ),
                   child: Row(
                     mainAxisAlignment: MainAxisAlignment.center,
                     children: [
                       Icon(Icons.login, color: AppTheme.accentCyan),
                       SizedBox(width: 8),
                       Text(
                         'Google-ով շարունակել',
                         style: AppTheme.activeTextsStyle,
                       ),
                     ],
                   ),
                 ),

               SizedBox(height: 24),

               // Switch between Sign In and Sign Up
               Row(
                 mainAxisAlignment: MainAxisAlignment.center,
                 children: [
                   Text(
                     _isSignUp ? 'Արդեն ունե՞ք հաշիվ: ' : "Չունե՞ք հաշիվ: ",
                     style: AppTheme.itemSubTitleStyle,
                   ),
                   InkWell(
                     onTap: _isLoading ? null : () {
                       setState(() {
                         _isSignUp = !_isSignUp;
                         _errorMessage = '';
                         _successMessage = '';
                       });
                     },
                     child: Text(
                       _isSignUp ? 'Մուտք' : 'Գրանցվել',
                       style: AppTheme.strongStyle,
                     ),
                   ),
                 ],
               ),
            ],
          ],
        ),
      ),
    );
  }
}

class ForgotPasswordPopup extends StatefulWidget {
  final String? initialEmail;
  
  const ForgotPasswordPopup({Key? key, this.initialEmail}) : super(key: key);
  
  @override
  State<ForgotPasswordPopup> createState() => _ForgotPasswordPopupState();
}

class _ForgotPasswordPopupState extends State<ForgotPasswordPopup> {
  final AuthService _authService = AuthService();
  late final TextEditingController _emailController;
  
  bool _isLoading = false;
  String _errorMessage = '';
  String _successMessage = '';

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail ?? '');
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendPasswordReset() async {
    if (_emailController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Խնդրում ենք մուտքագրել ձեր էլ․ փոստի հասցեն';
        _successMessage = '';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _successMessage = '';
    });

    try {
      final success = await _authService.sendPasswordResetEmail(_emailController.text.trim());
      if (success) {
        setState(() {
          _successMessage = 'Գաղտնաբառի վերականգնման նամակը ուղարկվեց! Ստուգեք ձեր էլ․ փոստը:';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = _authService.getAuthErrorMessage(e);
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.cardDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        width: kIsWeb ? 400 : double.infinity,
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
                         // Header
             ModalTitle(title: 'Գաղտնաբառի վերականգնում'),
             
             SizedBox(height: 24),

             if (_successMessage.isNotEmpty) ...[
               // Success message
               Container(
                 padding: EdgeInsets.all(16),
                 margin: EdgeInsets.only(bottom: 16),
                 decoration: BoxDecoration(
                   color: Colors.green.withValues(alpha: 0.1),
                   borderRadius: BorderRadius.circular(8),
                   border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                 ),
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     Row(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         Icon(
                           Icons.check_circle_outline,
                           color: Colors.green,
                           size: 20,
                         ),
                         SizedBox(width: 12),
                         Expanded(
                           child: Text(
                             _successMessage,
                             style: TextStyle(
                               color: Colors.green,
                               fontSize: 14,
                               fontWeight: FontWeight.w500,
                             ),
                           ),
                         ),
                       ],
                     ),
                   ],
                 ),
               ),

               // Close button after success
               OutlinedButton(
                 onPressed: () => Navigator.of(context).pop(),
                 style: OutlinedButton.styleFrom(
                   padding: EdgeInsets.symmetric(vertical: 16),
                   side: BorderSide(color: AppTheme.accentCyan),
                   shape: RoundedRectangleBorder(
                     borderRadius: BorderRadius.circular(8),
                   ),
                 ),
                 child: Text(
                   'Փակել',
                   style: TextStyle(
                     color: AppTheme.accentCyan,
                     fontSize: 16,
                     fontWeight: FontWeight.w500,
                   ),
                 ),
               ),
            ] else ...[
              // Error message
              if (_errorMessage.isNotEmpty)
                Container(
                  padding: EdgeInsets.all(16),
                  margin: EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 20,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage,
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                             // Instructions
               Text(
                 'Մուտքագրեք ձեր էլ․ փոստի հասցեն, և մենք ձեզ կուղարկենք գաղտնաբառի վերականգնման հղում:',
                 style: AppTheme.itemSubTitleStyle,
               ),
               SizedBox(height: 16),
               
               // Email field
               TextField(
                 controller: _emailController,
                 keyboardType: TextInputType.emailAddress,
                 style: AppTheme.activeTextsStyle,
                 decoration: InputDecoration(
                   hintText: 'Էլ․ փոստ',
                   hintStyle: AppTheme.textFieldHintStyle,
                   border: OutlineInputBorder(
                     borderRadius: BorderRadius.circular(8),
                     borderSide: BorderSide(color: AppTheme.dividerDark),
                   ),
                   enabledBorder: OutlineInputBorder(
                     borderRadius: BorderRadius.circular(8),
                     borderSide: BorderSide(color: AppTheme.dividerDark),
                   ),
                   focusedBorder: OutlineInputBorder(
                     borderRadius: BorderRadius.circular(8),
                     borderSide: BorderSide(color: AppTheme.accentCyan),
                   ),
                 ),
               ),
               
               SizedBox(height: 24),

               // Send reset email button
               OutlinedButton(
                 onPressed: _isLoading ? null : _sendPasswordReset,
                 style: OutlinedButton.styleFrom(
                   padding: EdgeInsets.symmetric(vertical: 16),
                   side: BorderSide(color: AppTheme.accentCyan),
                   shape: RoundedRectangleBorder(
                     borderRadius: BorderRadius.circular(8),
                   ),
                 ),
                 child: _isLoading
                   ? SizedBox(
                       height: 20,
                       width: 20,
                       child: CircularProgressIndicator(
                         strokeWidth: 2,
                         valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentCyan),
                       ),
                     )
                   : Text(
                       'Ուղարկել վերականգնման նամակ',
                       style: TextStyle(
                         color: AppTheme.accentCyan,
                         fontSize: 16,
                         fontWeight: FontWeight.w500,
                       ),
                     ),
               ),

               SizedBox(height: 16),

               // Cancel button
               TextButton(
                 onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                 child: Text(
                   'Չեղարկել',
                   style: AppTheme.itemSubTitleStyle,
                 ),
               ),
            ],
          ],
        ),
      ),
    );
  }
} 