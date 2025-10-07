<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class TransactionRequest extends FormRequest
{
    /**
     * Determine if the user is authorized to make this request.
     */
    public function authorize(): bool
    {
        return true;
    }

    /**
     * Get the validation rules that apply to the request.
     */
    public function rules(): array
    {
        return [
            'device_id' => 'required|exists:devices,id',
            'amount' => 'required|numeric|min:0.01',
            'type' => 'required|in:income,expense',
            'category' => 'required|string|max:100',
            'description' => 'required|string|max:500',
            'customer_name' => 'nullable|string|max:255',
            'customer_phone' => 'nullable|string|max:20',
            'notes' => 'nullable|string|max:1000',
            'transaction_date' => 'nullable|date',
        ];
    }

    /**
     * Get custom error messages for validation rules.
     */
    public function messages(): array
    {
        return [
            'device_id.required' => 'Chombo kinahitajika',
            'device_id.exists' => 'Chombo hakipo',
            'amount.required' => 'Kiasi kinahitajika',
            'amount.numeric' => 'Kiasi lazima kiwe nambari',
            'amount.min' => 'Kiasi lazima kiwe zaidi ya sifuri',
            'type.required' => 'Aina ya muamala inahitajika',
            'type.in' => 'Aina ya muamala si sahihi',
            'category.required' => 'Jamii inahitajika',
            'description.required' => 'Maelezo yanahitajika',
            'transaction_date.date' => 'Tarehe ya muamala si sahihi',
        ];
    }

    /**
     * Prepare the data for validation.
     */
    protected function prepareForValidation(): void
    {
        // Set transaction date to current time if not provided
        if (!$this->has('transaction_date')) {
            $this->merge([
                'transaction_date' => now(),
            ]);
        }
    }
}