class LoginRequest {

  LoginRequest({
    required this.email,
    required this.password,
    required this.phoneNumber,
  });
  final String email;
  final String password;
  final String phoneNumber;

  Map<String, dynamic> toJson() => <String, >{
      "email": email,
      "password": password,
      "phone_number": phoneNumber,
    };
}

class OtpVerificationRequest {

  OtpVerificationRequest({
    required this.userId,
    required this.otp,
  });
  final String userId;
  final String otp;

  Map<String, dynamic> toJson() => <String, >{
      "user_id": userId,
      "otp": otp,
    };
}

class ForgotPasswordRequest {

  ForgotPasswordRequest({required this.email});
  final String email;

  Map<String, dynamic> toJson() => <String, >{
      "email": email,
    };
}

class ResetPasswordRequest {

  ResetPasswordRequest({
    required this.userId,
    required this.otp,
    required this.password,
    required this.passwordConfirmation,
  });
  final String userId;
  final String otp;
  final String password;
  final String passwordConfirmation;

  Map<String, dynamic> toJson() => <String, >{
      "user_id": userId,
      "otp": otp,
      "password": password,
      "password_confirmation": passwordConfirmation,
    };
}