<?php

/*
| Rental / Transport route -> permission map.
|
| The `role` middleware lets a request through when the user's role matches OR
| when the user holds an explicit grant (users.permissions) for the first
| pattern below that matches the route URI (without the "api/" prefix).
| Patterns use fnmatch(); order matters, first match wins. Routes with no
| pattern here (user management, backups, ...) remain strictly role-only.
*/

$transportAny = [
    'manage_vehicles_transport', 'manage_drivers_transport', 'manage_agreements_transport',
    'manage_payments_transport', 'manage_debts_transport', 'view_reports_transport',
    'manage_reminders_transport',
];
$rentalAny = [
    'manage_properties_rental', 'manage_houses_rental', 'onboard_tenants_rental',
    'manage_agreements_rental', 'manage_billing_rental', 'view_reports_rental',
    'manage_maintenance_rental',
];

return [
    'routes' => [
        // Transport (admin/* prefix)
        'admin/vehicles*'          => ['manage_vehicles_transport'],
        'admin/assign-driver'      => ['manage_vehicles_transport', 'manage_drivers_transport'],
        'admin/drivers*'           => ['manage_drivers_transport'],
        'admin/driver-agreements*' => ['manage_agreements_transport'],
        'admin/payments*'          => ['manage_payments_transport'],
        'admin/receipts*'          => ['manage_payments_transport'],
        'admin/debts*'             => ['manage_debts_transport'],
        'admin/reminders*'         => ['manage_reminders_transport'],
        'admin/reports*'           => ['view_reports_transport'],
        'admin/analytics*'         => ['view_reports_transport'],
        'admin/dashboard*'         => $transportAny,

        // Rental
        'rental/properties*'       => ['manage_properties_rental'],
        'rental/blocks*'           => ['manage_properties_rental'],
        'rental/caretakers*'       => ['manage_properties_rental'],
        'rental/houses*'           => ['manage_houses_rental'],
        'rental/tenants*'          => ['onboard_tenants_rental'],
        'rental/agreements*'       => ['manage_agreements_rental'],
        'rental/payments*'         => ['manage_billing_rental'],
        'rental/receipts*'         => ['manage_billing_rental'],
        'rental/billing/*'         => ['manage_billing_rental'],
        'rental/reports/houses'    => ['manage_houses_rental', 'view_reports_rental'],
        'rental/reports*'          => ['view_reports_rental'],
        'rental/dashboard'         => $rentalAny,
        'rental/maintenance*'      => ['manage_maintenance_rental'],
    ],
];
