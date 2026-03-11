<?php
// setup-node.php — Auto-create location, node, and write Wings config.yml
// Runs via: php artisan tinker --execute="require('/scripts/setup-node.php');"

use App\Models\Location;
use App\Models\Node;

// Skip if a node already exists
if (Node::count() > 0) {
    echo "[pterodactyl] Node already exists, skipping auto-setup.\n";
    return;
}

// Create default location
$location = Location::firstOrCreate(
    ['short' => 'local'],
    ['long'  => 'Local Node']
);

// Derive FQDN from APP_URL (e.g. http://100.77.153.97:8800 → 100.77.153.97)
$fqdn = parse_url(config('app.url'), PHP_URL_HOST) ?: 'localhost';

// Create the node — model auto-generates uuid, daemon_token_id, daemon_token
$node = Node::create([
    'name'                 => 'Default Node',
    'description'          => 'Auto-created local node',
    'location_id'          => $location->id,
    'fqdn'                 => $fqdn,
    'scheme'               => 'http',
    'behind_proxy'         => false,
    'maintenance_mode'     => false,
    'memory'               => 0,
    'memory_overallocate'  => 0,
    'disk'                 => 0,
    'disk_overallocate'    => 0,
    'upload_size'          => 100,
    'daemonListen'         => 8080,
    'daemonSFTP'           => 2022,
    'daemonBase'           => '/var/lib/pterodactyl/volumes',
]);

echo "[pterodactyl] Node created: {$node->name} (FQDN: {$fqdn})\n";

// Try the built-in configuration service first
$configPath = '/wings-config/config.yml';
$written = false;

try {
    $service = app(\App\Services\Nodes\NodeConfigurationService::class);
    $configuration = $service->handle($node);

    // The service may return an object or array — normalise to array
    $data = is_object($configuration) && method_exists($configuration, 'toArray')
        ? $configuration->toArray()
        : (array) $configuration;

    $yaml = \Symfony\Component\Yaml\Yaml::dump($data, 10, 2);
    file_put_contents($configPath, $yaml);
    $written = true;
} catch (\Throwable $e) {
    echo "[pterodactyl] NodeConfigurationService failed: {$e->getMessage()}\n";
    echo "[pterodactyl] Falling back to manual config generation.\n";
}

// Fallback: build the YAML manually
if (!$written) {
    try {
        $token = decrypt($node->daemon_token);

        $config = [
            'debug'   => false,
            'uuid'    => $node->uuid,
            'token_id' => $node->daemon_token_id,
            'token'   => $token,
            'api'     => [
                'host' => '0.0.0.0',
                'port' => 8080,
                'ssl'  => [
                    'enabled' => false,
                    'cert'    => '',
                    'key'     => '',
                ],
            ],
            'system'  => [
                'data' => '/var/lib/pterodactyl/volumes',
                'sftp' => [
                    'bind_port' => 2022,
                ],
            ],
            'allowed_mounts' => [],
            'remote'  => config('app.url'),
        ];

        $yaml = \Symfony\Component\Yaml\Yaml::dump($config, 10, 2);
        file_put_contents($configPath, $yaml);
        $written = true;
    } catch (\Throwable $e) {
        echo "[pterodactyl] Manual config generation also failed: {$e->getMessage()}\n";
    }
}

if ($written) {
    echo "[pterodactyl] Wings config written to {$configPath}\n";
} else {
    echo "[pterodactyl] WARNING: Could not write Wings config. Configure Wings manually.\n";
}
