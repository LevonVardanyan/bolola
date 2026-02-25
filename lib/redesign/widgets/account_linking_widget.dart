import 'package:flutter/material.dart';
import 'package:politicsstatements/redesign/resources/theme.dart';
import 'package:politicsstatements/redesign/services/auth_service.dart';

class AccountLinkingWidget extends StatefulWidget {
  @override
  State<AccountLinkingWidget> createState() => _AccountLinkingWidgetState();
}

class _AccountLinkingWidgetState extends State<AccountLinkingWidget> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  String _errorMessage = '';
  String _successMessage = '';

  @override
  Widget build(BuildContext context) {
    final isGoogleLinked = _authService.isGoogleLinked();
    final isEmailLinked = _authService.isEmailPasswordLinked();

    return Card(
      color: AppTheme.primaryDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppTheme.textSecondary2.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              'Կապակցված հաշիվներ',
              style: AppTheme.activeTextsStyle.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            
            SizedBox(height: 8),
            
            Text(
              'Կառավարեք ձեր մուտքի եղանակները՝ ձեր հաշվին ավելի հեշտ մուտք գործելու համար:',
              style: AppTheme.itemSubTitleStyle,
            ),
            
            SizedBox(height: 20),

            // Success message
            if (_successMessage.isNotEmpty)
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12),
                margin: EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppTheme.accentGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.accentGreen.withValues(alpha: 0.3)),
                ),
                child: Row(
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
                width: double.infinity,
                padding: EdgeInsets.all(12),
                margin: EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppTheme.accentMagenta.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.accentMagenta.withValues(alpha: 0.3)),
                ),
                child: Row(
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

            // Email/Password status
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isEmailLinked 
                    ? AppTheme.accentGreen.withValues(alpha: 0.1)
                    : AppTheme.textSecondary2.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isEmailLinked 
                      ? AppTheme.accentGreen.withValues(alpha: 0.3)
                      : AppTheme.textSecondary2.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.email,
                    color: isEmailLinked ? Colors.green : AppTheme.textSecondary2,
                    size: 24,
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Էլ․ փոստ և գաղտնաբառ',
                          style: AppTheme.activeTextsStyle.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          isEmailLinked 
                              ? 'Կապակցված է - Կարող եք մուտք գործել ձեր էլ․ փոստով և գաղտնաբառով'
                              : 'Կապակցված չէ',
                          style: AppTheme.itemSubTitleStyle.copyWith(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isEmailLinked ? Icons.check_circle : Icons.cancel,
                    color: isEmailLinked ? Colors.green : AppTheme.textSecondary2,
                    size: 20,
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 12),

            // Google account status
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isGoogleLinked 
                    ? AppTheme.accentGreen.withValues(alpha: 0.1)
                    : AppTheme.textSecondary2.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isGoogleLinked 
                      ? AppTheme.accentGreen.withValues(alpha: 0.3)
                      : AppTheme.textSecondary2.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.account_circle,
                    color: isGoogleLinked ? Colors.green : AppTheme.textSecondary2,
                    size: 24,
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Google հաշիվ',
                          style: AppTheme.activeTextsStyle.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          isGoogleLinked 
                              ? 'Կապակցված է - Կարող եք մուտք գործել Google-ով'
                              : 'Կապակցված չէ - Կապակցրեք Google-ով մուտք գործելու համար',
                          style: AppTheme.itemSubTitleStyle.copyWith(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isGoogleLinked ? Icons.check_circle : Icons.cancel,
                    color: isGoogleLinked ? Colors.green : AppTheme.textSecondary2,
                    size: 20,
                  ),
                ],
              ),
            ),

            if (!isGoogleLinked && isEmailLinked) ...[
              SizedBox(height: 16),
              
              // Link Google account button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _isLoading ? null : _linkGoogleAccount,
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 12),
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
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.link, color: AppTheme.accentCyan),
                            SizedBox(width: 8),
                            Text(
                              'Կապակցել Google հաշիվը',
                              style: TextStyle(
                                color: AppTheme.accentCyan,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],

            if (isGoogleLinked && isEmailLinked) ...[
              SizedBox(height: 16),
              
              // Unlink Google account button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _isLoading ? null : _unlinkGoogleAccount,
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: Colors.red),
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
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.link_off, color: Colors.red),
                            SizedBox(width: 8),
                            Text(
                              'Անջատել Google հաշիվը',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _linkGoogleAccount() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _successMessage = '';
    });

    try {
      final success = await _authService.linkGoogleAccount();
      if (success) {
        setState(() {
          _successMessage = 'Google հաշիվը հաջողությամբ կապակցվեց: Այժմ կարող եք մուտք գործել Google-ով:';
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

  Future<void> _unlinkGoogleAccount() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _successMessage = '';
    });

    try {
      final success = await _authService.unlinkGoogleAccount();
      if (success) {
        setState(() {
          _successMessage = 'Google հաշիվը հաջողությամբ անջատվեց:';
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
} 