<?php

/**
 * Swagger UI groups endpoints by tag, in the order the spec's root `tags`
 * array lists them -- swagger-php's own order follows file-scan order
 * (roughly alphabetical by path), not anything meaningful. Reorders that
 * array to: Auth first, then every Inventory tag, then every Rental tag,
 * then every Transport tag, then everything else (Locations, Admin/*)
 * last -- run right after `artisan l5-swagger:generate` so it applies on
 * every fresh generation, not just once.
 */

$path = __DIR__ . '/../storage/api-docs/api-docs.json';
if (!file_exists($path)) {
    fwrite(STDERR, "reorder-swagger-tags: $path not found, skipping\n");
    exit(0);
}

$doc = json_decode(file_get_contents($path), true);
if (!isset($doc['tags']) || !is_array($doc['tags'])) {
    exit(0);
}

$priority = static function (string $name): int {
    if ($name === 'Auth') {
        return 0;
    }
    if (str_starts_with($name, 'Inventory')) {
        return 1;
    }
    if (str_starts_with($name, 'Rental')) {
        return 2;
    }
    if (str_starts_with($name, 'Transport')) {
        return 3;
    }
    return 4;
};

usort($doc['tags'], static function (array $a, array $b) use ($priority): int {
    $pa = $priority($a['name']);
    $pb = $priority($b['name']);
    return $pa <=> $pb ?: strcmp($a['name'], $b['name']);
});

file_put_contents($path, json_encode($doc, JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT));
echo "reorder-swagger-tags: reordered " . count($doc['tags']) . " tags\n";
