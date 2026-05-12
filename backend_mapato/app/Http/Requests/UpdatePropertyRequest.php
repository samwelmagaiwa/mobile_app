<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdatePropertyRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'name' => ['sometimes', 'string', 'max:255'],
            'property_type' => ['sometimes', Rule::in([
                'apartment', 'rental_compound', 'standalone_house', 
                'hostel', 'commercial_building', 'mixed_use', 'office_space', 'shop_units'
            ])],
            'region' => ['sometimes', 'string', 'max:100'],
            'district' => ['sometimes', 'string', 'max:100'],
            'ward' => ['nullable', 'string', 'max:100'],
            'street' => ['nullable', 'string', 'max:255'],
            'address' => ['sometimes', 'string', 'max:500'],
            'description' => ['nullable', 'string', 'max:1000'],
            'billing_cycle' => ['sometimes', Rule::in(['monthly', 'quarterly', 'yearly'])],
            'currency' => ['sometimes', 'string', 'max:10'],
            'status' => ['sometimes', Rule::in(['active', 'inactive', 'under_maintenance', 'archived'])],
            'total_units' => ['sometimes', 'integer', 'min:0'],
            'number_of_blocks' => ['sometimes', 'integer', 'min:1'],
            'caretaker_id' => ['nullable', 'exists:users,id'],
            'default_rent_amount' => ['nullable', 'numeric', 'min:0'],
            'default_deposit_amount' => ['nullable', 'numeric', 'min:0'],
            'utility_billing_enabled' => ['sometimes', 'boolean'],
            'latitude' => ['nullable', 'numeric', 'between:-90,90'],
            'longitude' => ['nullable', 'numeric', 'between:-180,180'],
            'cover_image' => ['nullable', 'url'],
        ];
    }
}