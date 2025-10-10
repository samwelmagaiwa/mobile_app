<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Contracts\Validation\Validator;
use Illuminate\Http\Exceptions\HttpResponseException;
use App\Helpers\ResponseHelper;

class CreateDriverRequest extends FormRequest
{
    /**
     * Determine if the user is authorized to make this request.
     */
    public function authorize(): bool
    {
        // Allow for now since we're bypassing auth temporarily
        return true;
    }

    /**
     * Get the validation rules that apply to the request.
     */
    public function rules(): array
    {
        return [
            'name' => 'required|string|max:255',
            'email' => 'required|email|max:255|unique:users,email',
            'phone' => 'required_without:phone_number|string|max:20',
            'phone_number' => 'required_without:phone|string|max:20',
            'license_number' => 'required|string|max:50|unique:drivers,license_number',
            'license_expiry' => 'required|date|after:today',
            'address' => 'required|string|max:500',
            'emergency_contact' => 'required|string|max:20',
            'vehicle_number' => 'nullable|string|max:50',
            'vehicle_type' => 'nullable|in:bajaji,pikipiki,gari',
            'status' => 'nullable|in:active,inactive',
            'national_id' => 'nullable|string|max:50',
            'date_of_birth' => 'nullable|date|before:today',
            'password' => 'nullable|string|min:8',
        ];
    }

    /**
     * Get custom validation messages.
     */
    public function messages(): array
    {
        return [
            'name.required' => 'Jina ni lazima',
            'name.string' => 'Jina lazima liwe maandishi',
            'name.max' => 'Jina haliwezi kuwa na herufi zaidi ya 255',
            
            'email.required' => 'Barua pepe ni lazima',
            'email.email' => 'Ingiza barua pepe sahihi',
            'email.unique' => 'Barua pepe hii tayari imetumika',
            
            'phone.required_without' => 'Namba ya simu ni lazima',
            'phone.string' => 'Namba ya simu lazima iwe maandishi',
            'phone.max' => 'Namba ya simu haiwezi kuwa na herufi zaidi ya 20',
            
            'phone_number.required_without' => 'Namba ya simu ni lazima',
            'phone_number.string' => 'Namba ya simu lazima iwe maandishi',
            'phone_number.max' => 'Namba ya simu haiwezi kuwa na herufi zaidi ya 20',
            
            'license_number.required' => 'Namba ya leseni ni lazima',
            'license_number.unique' => 'Namba ya leseni hii tayari imetumika',
            'license_number.max' => 'Namba ya leseni haiwezi kuwa na herufi zaidi ya 50',
            
            'vehicle_type.in' => 'Aina ya gari lazima iwe bajaji, pikipiki, au gari',
            'status.in' => 'Hali lazima iwe active au inactive',
            
            'license_expiry.required' => 'Tarehe ya mwisho ya leseni ni lazima',
            'license_expiry.date' => 'Tarehe ya mwisho ya leseni si sahihi',
            'license_expiry.after' => 'Tarehe ya mwisho ya leseni lazima iwe baada ya leo',
            
            'address.required' => 'Anwani ni lazima',
            'address.string' => 'Anwani lazima iwe maandishi',
            'address.max' => 'Anwani haiwezi kuwa na herufi zaidi ya 500',
            
            'emergency_contact.required' => 'Namba ya dharura ni lazima',
            'emergency_contact.string' => 'Namba ya dharura lazima iwe maandishi',
            'emergency_contact.max' => 'Namba ya dharura haiwezi kuwa na herufi zaidi ya 20',
            
            'national_id.string' => 'Namba ya kitambulisho lazima iwe maandishi',
            'national_id.max' => 'Namba ya kitambulisho haiwezi kuwa na herufi zaidi ya 50',
            
            'date_of_birth.date' => 'Tarehe ya kuzaliwa si sahihi',
            'date_of_birth.before' => 'Tarehe ya kuzaliwa lazima iwe kabla ya leo',
            
            'password.min' => 'Neno la siri lazima liwe na angalau herufi 8',
        ];
    }

    /**
     * Handle a failed validation attempt.
     */
    protected function failedValidation(Validator $validator)
    {
        throw new HttpResponseException(
            ResponseHelper::validationError($validator->errors(), 'Taarifa zilizowekwa si sahihi')
        );
    }

    /**
     * Get the phone number (prioritize 'phone' over 'phone_number')
     */
    public function getPhoneNumber(): string
    {
        return $this->input('phone') ?? $this->input('phone_number');
    }

    /**
     * Get the password or generate a default one
     */
    public function getPassword(): string
    {
        return $this->input('password') ?? 'password123';
    }

    /**
     * Get the status as boolean
     */
    public function getIsActive(): bool
    {
        return $this->input('status') !== 'inactive';
    }
}