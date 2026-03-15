<?php
// setup-node.php — Auto-create location, node, and write Wings config.yml
// Runs via: php artisan tinker --execute="require('/scripts/setup-node.php');"

use Pterodactyl\Models\Location;
use Pterodactyl\Models\Node;
use Illuminate\Support\Str;


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

// Generate values that Node::create doesn't auto-fill
$tokenPlain = Str::random(64);
$tokenId = Str::random(16);
$nodeUuid = Str::uuid()->toString();

// Create the node with all required fields
$node = new Node();
$node->uuid                = $nodeUuid;
$node->name                = 'Default Node';
$node->description         = 'Auto-created local node';
$node->location_id         = $location->id;
$node->fqdn                = $fqdn;
$node->scheme              = 'http';
$node->behind_proxy        = false;
$node->maintenance_mode    = false;
$node->memory              = 1024;
$node->memory_overallocate = -1;
$node->disk                = 10240;
$node->disk_overallocate   = -1;
$node->upload_size         = 100;
$node->daemon_token_id     = $tokenId;
$node->daemon_token        = $tokenPlain;
$node->daemonListen        = 8080;
$node->daemonSFTP          = 2022;
$node->daemonBase          = '/var/lib/pterodactyl/volumes';
$node->save();

echo "[pterodactyl] Node created: {$node->name} (ID: {$node->id}, FQDN: {$fqdn})\n";

// Build Wings config.yml manually since we have all the values
$config = [
    'debug'   => false,
    'uuid'    => $nodeUuid,
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
// Symfony YAML dumps empty array as {}, Wings expects [] (sequence)
$yaml = str_replace('allowed_mounts: {  }', 'allowed_mounts: []', $yaml);
file_put_contents('/wings-config/config.yml', $yaml);
echo "[pterodactyl] Wings config written to /wings-config/config.yml\n";
