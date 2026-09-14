<?php

namespace App\OpenApi;

use OpenApi\Attributes as OA;

/**
 * Shared response/request schemas referenced across controllers via
 * `#[OA\JsonContent(ref: '#/components/schemas/...')]`. Centralized here
 * so the same error/pagination shape isn't redefined in every file.
 */
#[OA\Schema(
    schema: 'ErrorResponse',
    properties: [
        new OA\Property(property: 'message', type: 'string', example: 'Not found'),
    ],
)]
#[OA\Schema(
    schema: 'ValidationErrorResponse',
    properties: [
        new OA\Property(property: 'message', type: 'string', example: 'The given data was invalid.'),
        new OA\Property(
            property: 'errors',
            type: 'object',
            additionalProperties: new OA\AdditionalProperties(
                type: 'array',
                items: new OA\Items(type: 'string'),
            ),
            example: ['email' => ['The email field is required.']],
        ),
    ],
)]
#[OA\Schema(
    schema: 'PaginationMeta',
    properties: [
        new OA\Property(property: 'current_page', type: 'integer', example: 1),
        new OA\Property(property: 'last_page', type: 'integer', example: 5),
        new OA\Property(property: 'per_page', type: 'integer', example: 20),
        new OA\Property(property: 'total', type: 'integer', example: 93),
    ],
)]
#[OA\Schema(
    schema: 'User',
    properties: [
        new OA\Property(property: 'id', type: 'string', format: 'uuid'),
        new OA\Property(property: 'name', type: 'string', example: 'Samwel Magaiwa'),
        new OA\Property(property: 'email', type: 'string', format: 'email'),
        new OA\Property(property: 'phone_number', type: 'string', example: '+255743519104'),
        new OA\Property(property: 'role', type: 'string', example: 'admin', enum: [
            'super_admin', 'admin', 'sales_officer', 'manager', 'operator',
            'driver', 'landlord', 'caretaker', 'tenant', 'vendor',
        ]),
        new OA\Property(property: 'is_active', type: 'boolean'),
        new OA\Property(property: 'created_at', type: 'string', format: 'date-time'),
    ],
    type: 'object',
)]
class Schemas
{
}
