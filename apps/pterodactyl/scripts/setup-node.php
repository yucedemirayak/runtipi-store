<?php
// setup-node.php — Auto-create location, node, and write Wings config.yml
// Runs via: php artisan tinker --execute="require('/scripts/setup-node.php');"

use Pterodactyl\Models\Location;
use Pterodactyl\Models\Node;

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

// Create the node
$node = Node::create([
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
    'daemonListen'         => 8080,
    'daemonSFTP'           => 2022,
    'daemonBase'           => '/var/lib/pterodactyl/volumes',
]);

echo "[pterodactyl] Node created: {$node->name} (ID: {$node->id}, FQDN: {$fqdn})\n";

// Write Wings config using the built-in artisan command
$exitCode = Artisan::call('p:node:configuration', [
    'node'     => $node->id,
    '--format' => 'yaml',
]);

if ($exitCode === 0) {
    $yaml = Artisan::output();
    file_put_contents('/wings-config/config.yml', $yaml);
    echo "[pterodactyl] Wings config written to /wings-config/config.yml\n";
} else {
    echo "[pterodactyl] WARNING: p:node:configuration failed (exit {$exitCode}).\n";
    echo "[pterodactyl] Configure Wings manually via Panel UI.\n";
}
