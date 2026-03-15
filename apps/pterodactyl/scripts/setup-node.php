<?php
// setup-node.php — Auto-create location, node, and write Wings config.yml
// Uses Panel's own NodeCreationService for correct token encryption.
// Runs via: php artisan tinker --execute="require('/scripts/setup-node.php');"

use Pterodactyl\Models\Location;
use Pterodactyl\Models\Node;
use Pterodactyl\Services\Nodes\NodeCreationService;

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

// Use the Server IP from APP_URL for Node FQDN.
// APP_URL is set to http://<SERVER_IP>:<APP_PORT> by docker-compose.
// Browser WebSocket connects to FQDN:daemonListen, so FQDN must be
// the external IP and daemonListen must be the host-mapped port (8081).
$fqdn = parse_url(config('app.url'), PHP_URL_HOST) ?: 'localhost';

$service = app(NodeCreationService::class);
$node = $service->handle([
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
    'daemonListen'         => 8081,
    'daemonSFTP'           => 2022,
]);

echo "[pterodactyl] Node created: {$node->name} (ID: {$node->id}, FQDN: {$fqdn})\n";

// Use the model's own getYamlConfiguration() which correctly:
// - decrypts daemon_token with decrypt() (matching encrypt() used above)
// - uses DUMP_EMPTY_ARRAY_AS_SEQUENCE for allowed_mounts: []
// - sets remote URL from route('index') → uses APP_URL with the real IP
$yaml = $node->getYamlConfiguration();

// Wings creates a pterodactyl0 Docker bridge network for game servers.
// Its default subnet (172.18.0.0/16) overlaps with Runtipi's main network.
// Assign a non-conflicting subnet.
// Also enable CORS private network access for browser WebSocket.
$yaml .= "\ndocker:\n  network:\n    interfaces:\n      v4:\n        subnet: 172.19.0.0/16\n        gateway: 172.19.0.1\nallow_cors_private_network: true\n";

file_put_contents('/wings-config/config.yml', $yaml);
echo "[pterodactyl] Wings config written to /wings-config/config.yml\n";
