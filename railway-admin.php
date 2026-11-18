<?php
// Sets the first admin's email and password from the service variables, right
// after the unattended install created it with the stock admin123 password.
// Runs once, before nginx starts, so the stock password is never reachable.
require '/var/www/bagisto/vendor/autoload.php';
$app = require '/var/www/bagisto/bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

$email = getenv('BAGISTO_ADMIN_EMAIL');
$password = getenv('BAGISTO_ADMIN_PASSWORD');
if (! filter_var($email, FILTER_VALIDATE_EMAIL)) {
    fwrite(STDERR, "BAGISTO_ADMIN_EMAIL is not a valid email address\n");
    exit(1);
}

$updated = Illuminate\Support\Facades\DB::table('admins')->orderBy('id')->limit(1)->update([
    'email' => $email,
    'password' => Illuminate\Support\Facades\Hash::make($password),
    'updated_at' => now(),
]);
if ($updated !== 1) {
    fwrite(STDERR, "Could not set the admin user\n");
    exit(1);
}
echo "Admin user set.\n";
