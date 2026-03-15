<?php
// setup-node.php — Auto-create location, node, and write Wings config.yml
// Runs via: php artisan tinker --execute="require('/scripts/setup-node.php');"

use Pterodactyl\Models\Location;
use Pterodactyl\Models\Node;
use Illuminate\Support\Str;
use Illuminate\Support\Facades\Crypt;

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

// Generate token values that Node::create doesn't auto-fill
$tokenPlain = Str::random(64);
$tokenId = Str::random(16);

// Create the node with all required fields
$node = Node::create([
    'uuid'                 => Str::uuid()->toString(),
    'name'                 => 'Default Node',
    'description'          => 'Auto-created local node',
    'location_id'          => $location->id,
    'fqdn'                 => $fqdn,
    'scheme'               => 'http',
    'behind_proxy'         => false,
    'maintenance_mode'     => false,
    'memory'               => 1024,
    'memory_overallocate'  => -1,
    'disk'                 => 10240,
    'disk_overallocate'    => -1,
    'upload_size'          => 100,
    'daemon_token_id'      => $tokenId,
    'daemon_token'         => Crypt::encryptString($tokenPlain),
    'daemonListen'         => 8080,
    'daemonSFTP'           => 2022,
    'daemonBase'           => '/var/lib/pterodactyl/volumes',
]);

echo "[pterodactyl] Node created: {$node->name} (ID: {$node->id}, FQDN: {$fqdn})\n";

// Build Wings config.yml manually since we have all the values
$config = [
    'debug'   => false,
    'uuid'    => $node->uuid,
    'token_id' => $tokenId,
    'token'   => $tokenPlain,
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
file_put_contents('/wings-config/config.yml', $yaml);
echo "[pterodactyl] Wings config written to /wings-config/config.yml\n";
