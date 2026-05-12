<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class StorePropertyRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'name' => ['required', 'string', 'max:255'],
            'property_type' => ['required', Rule::in([
                'apartment', 'rental_compound', 'standalone_house', 
                'hostel', 'commercial_building', 'mixed_use', 'office_space', 'shop_units'
            ])],
            'region' => ['required', 'string', 'max:100'],
            'district' => ['required', 'string', 'max:100'],
            'ward' => ['nullable', 'string', 'max:100'],
            'street' => ['nullable', 'string', 'max:255'],
            'address' => ['required', 'string', 'max:500'],
            'description' => ['nullable', 'string', 'max:1000'],
            'billing_cycle' => ['required', Rule::in(['monthly', 'quarterly', 'yearly'])],
            'currency' => ['sometimes', 'string', 'max:10', 'default:TZS'],
            'status' => ['sometimes', Rule::in(['active', 'inactive', 'under_maintenance', 'archived']), 'default:active'],
            'total_units' => ['nullable', 'integer', 'min:0'],
            'number_of_blocks' => ['nullable', 'integer', 'min:1'],
            'caretaker_id' => ['nullable', 'exists:users,id'],
            'default_rent_amount' => ['nullable', 'numeric', 'min:0'],
            'default_deposit_amount' => ['nullable', 'numeric', 'min:0'],
            'utility_billing_enabled' => ['sometimes', 'boolean'],
            'latitude' => ['nullable', 'numeric', 'between:-90,90'],
            'longitude' => ['nullable', 'numeric', 'between:-180,180'],
            'cover_image' => ['nullable', 'url'],
        ];
    }

    public function messages(): array
    {
        return [
            'name.required' => 'Jina la mali linahitajika',
            'property_type.required' => 'Aina ya mali inahitajika',
            'property_type.in' => 'Aina ya mali si sahihi',
            'region.required' => 'Mkoa unahitajika',
            'district.required' => 'Wilaya inahitajika',
            'address.required' => 'Anuani inahitajika',
            'billing_cycle.required' => 'Kipindi cha kodi kinahitajika',
            'billing_cycle.in' => 'Kipindi cha kodi si sahihi',
        ];
    }
}