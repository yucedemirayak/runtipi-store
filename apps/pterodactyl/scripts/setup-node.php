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

// Use the Docker internal hostname so Panel can reach Wings directly on port 8080.
// The external IP:8081 mapping is for external clients; Panel uses internal network.
$fqdn = 'pterodactyl-wings';

// Use Panel's own NodeCreationService — it handles uuid, daemon_token
// encryption (encrypt() not encryptString()), daemon_token_id, and
// uses forceFill() to bypass $fillable restrictions.
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
    'daemonListen'         => 8080,
    'daemonSFTP'           => 2022,
]);

echo "[pterodactyl] Node created: {$node->name} (ID: {$node->id}, FQDN: {$fqdn})\n";

// Use the model's own getYamlConfiguration() which correctly:
// - decrypts daemon_token with decrypt() (matching encrypt() used above)
// - uses DUMP_EMPTY_ARRAY_AS_SEQUENCE for allowed_mounts: []
// - sets remote URL from route('index')
$yaml = $node->getYamlConfiguration();

// Wings creates a pterodactyl0 Docker bridge network for game servers.
// Its default subnet (172.18.0.0/16) overlaps with Runtipi's main network.
// Assign a non-conflicting subnet.
$yaml .= "\ndocker:\n  network:\n    interfaces:\n      v4:\n        subnet: 172.19.0.0/16\n        gateway: 172.19.0.1\n";

file_put_contents('/wings-config/config.yml', $yaml);
echo "[pterodactyl] Wings config written to /wings-config/config.yml\n";
