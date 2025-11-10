<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Log;
use Illuminate\Validation\ValidationException;

class AuthController extends Controller
{
    /**
     * Show the login form
     */
    public function showLoginForm()
    {
        return view('auth.login');
    }
    
    /**
     * Handle login request
     */
    public function login(Request $request)
    {
        // Log login attempt
        Log::info('Web login attempt started', [
            'email' => $request->email,
            'ip_address' => $request->ip(),
            'user_agent' => $request->userAgent(),
            'timestamp' => now()->toISOString(),
        ]);

        try {
            $request->validate(
                [
                    'email' => 'required|email',
                    'password' => 'required|string',
                    'phone_number' => ['required', 'regex:/^(0\d{9}|\+\d{9,15})$/'],
                ],
                [
                    'phone_number.required' => 'Namba ya simu inahitajika',
                    'phone_number.regex' => 'Namba ya simu si sahihi. Tumia namba ya ndani (mfano: 0743519100) au ya kimataifa (mfano: +255743519100).',
                ]
            );

            // Find user by email
            $user = User::where('email', $request->email)->first();

            if (!$user) {
                Log::warning('Web login failed - User not found', [
                    'email' => $request->email,
                    'ip_address' => $request->ip(),
                    'reason' => 'user_not_found',
                    'timestamp' => now()->toISOString(),
                ]);
                
                throw ValidationException::withMessages([
                    'email' => ['Invalid credentials provided.'],
                ]);
            }

            // Verify password
            if (!Hash::check($request->password, $user->password)) {
                Log::warning('Web login failed - Invalid password', [
                    'user_id' => $user->id,
                    'email' => $request->email,
                    'ip_address' => $request->ip(),
                    'reason' => 'invalid_password',
                    'timestamp' => now()->toISOString(),
                ]);
                
                throw ValidationException::withMessages([
                    'password' => ['Invalid credentials provided.'],
                ]);
            }

            // Check if user is active
            if (!$user->is_active) {
                Log::warning('Web login failed - Account inactive', [
                    'user_id' => $user->id,
                    'email' => $request->email,
                    'ip_address' => $request->ip(),
                    'reason' => 'account_inactive',
                    'timestamp' => now()->toISOString(),
                ]);
                
                return back()->withErrors([
                    'email' => 'Your account is currently inactive. Please contact support.',
                ]);
            }

            // Verify phone number matches
            if ($user->phone_number !== $request->phone_number) {
                Log::warning('Web login failed - Phone number mismatch', [
                    'user_id' => $user->id,
                    'email' => $request->email,
                    'provided_phone' => $request->phone_number,
                    'registered_phone' => $user->phone_number,
                    'ip_address' => $request->ip(),
                    'reason' => 'phone_mismatch',
                    'timestamp' => now()->toISOString(),
                ]);
                
                throw ValidationException::withMessages([
                    'phone_number' => ['Phone number does not match our records.'],
                ]);
            }

            // Update last login
            $user->updateLastLogin();

            // Create session token for web authentication
            $token = $user->createToken('web_session')->plainTextToken;
            
            // Store token in session for web authentication
            session(['auth_token' => $token]);
            
            // Log successful login
            Log::info('Web login successful', [
                'user_id' => $user->id,
                'email' => $user->email,
                'name' => $user->name,
                'role' => $user->role,
                'ip_address' => $request->ip(),
                'user_agent' => $request->userAgent(),
                'last_login_at' => $user->last_login_at,
                'timestamp' => now()->toISOString(),
            ]);

            // Redirect based on user role
            switch ($user->role) {
                case 'super_admin':
                case 'admin':
                    return redirect()->route('admin.dashboard')->with('success', 'Welcome back, ' . $user->name . '!');
                case 'driver':
                    return redirect()->route('driver.dashboard')->with('success', 'Welcome back, ' . $user->name . '!');
                default:
                    return redirect('/')->with('success', 'Login successful!');
            }

        } catch (ValidationException $e) {
            Log::error('Web login failed - Validation error', [
                'email' => $request->email,
                'ip_address' => $request->ip(),
                'validation_errors' => $e->errors(),
                'reason' => 'validation_failed',
                'timestamp' => now()->toISOString(),
            ]);
            
            return back()->withErrors($e->errors())->withInput($request->except('password'));
            
        } catch (\Exception $e) {
            Log::error('Web login failed - System error', [
                'email' => $request->email,
                'ip_address' => $request->ip(),
                'error_message' => $e->getMessage(),
                'error_file' => $e->getFile(),
                'error_line' => $e->getLine(),
                'reason' => 'system_error',
                'timestamp' => now()->toISOString(),
            ]);
            
            return back()->withErrors([
                'email' => 'Login failed due to a system error. Please try again.',
            ])->withInput($request->except('password'));
        }
    }
    
    /**
     * Handle logout request
     */
    public function logout(Request $request)
    {
        try {
            // Get current user if authenticated
            $user = $request->user();
            
            if ($user) {
                // Log logout attempt
                Log::info('Web logout attempt', [
                    'user_id' => $user->id,
                    'email' => $user->email,
                    'ip_address' => $request->ip(),
                    'timestamp' => now()->toISOString(),
                ]);
                
                // Revoke current token
                $user->currentAccessToken()?->delete();
                
                Log::info('Web logout successful', [
                    'user_id' => $user->id,
                    'email' => $user->email,
                    'ip_address' => $request->ip(),
                    'timestamp' => now()->toISOString(),
                ]);
            }
            
            // Clear session
            session()->forget('auth_token');
            session()->invalidate();
            session()->regenerateToken();
            
            return redirect()->route('login')->with('success', 'You have been logged out successfully.');
            
        } catch (\Exception $e) {
            Log::error('Web logout failed', [
                'user_id' => $request->user()?->id,
                'error_message' => $e->getMessage(),
                'ip_address' => $request->ip(),
                'timestamp' => now()->toISOString(),
            ]);
            
            return redirect()->route('login')->with('error', 'Logout failed. Please try again.');
        }
    }
}