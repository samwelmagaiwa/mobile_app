<?php

namespace App\OpenApi;

use OpenApi\Attributes as OA;

/**
 * Root OpenAPI document: info, servers, and the shared bearer-token
 * security scheme every protected endpoint references. This class holds
 * no code -- it exists purely so swagger-php has one place to find the
 * top-level attributes instead of scattering them across controllers.
 */
#[OA\Info(
    version: '1.0.0',
    title: 'Depot Mapato API',
    description: "REST API powering the Depot Mapato mobile app across its three services -- "
        . "**Inventory** (sales, stock, POS), **Rental** (properties, tenants, billing), and "
        . "**Transport** (drivers, agreements, payments) -- plus shared auth and admin endpoints.\n\n"
        . "### Authentication\n"
        . "Almost every endpoint requires a Laravel Sanctum bearer token. Call `POST /auth/login` "
        . "first, then click **Authorize** above and paste the returned `token` value (no `Bearer ` "
        . "prefix needed -- it's added automatically).\n\n"
        . "### Errors\n"
        . "Failures return a JSON body with a `message` field and, for validation failures, an "
        . "`errors` object keyed by field name -- the standard Laravel validation error shape.",
    contact: new OA\Contact(name: 'Depot Mapato'),
)]
#[OA\Server(url: '/api', description: 'Current environment')]
#[OA\SecurityScheme(
    securityScheme: 'bearerAuth',
    type: 'http',
    scheme: 'bearer',
    bearerFormat: 'Sanctum personal access token',
    description: 'Paste the `token` returned by POST /auth/login.',
)]
class OpenApiSpec
{
}
