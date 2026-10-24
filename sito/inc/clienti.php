<?php
// Accesso dei clienti alla loro area. Gli account sono in data/contenuti.json
// (poi nel database): la password è salvata solo cifrata, con lo stesso
// metodo del gestionale (sha256 di "sale::password").

function sessione(): void
{
    if (session_status() !== PHP_SESSION_ACTIVE) {
        session_set_cookie_params(['httponly' => true, 'samesite' => 'Lax', 'secure' => !empty($_SERVER['HTTPS'])]);
        session_start();
    }
}

function cliente_da_id(string $id): ?array
{
    foreach (dati()['clients'] ?? [] as $c) {
        if ($c['id'] === $id) return $c;
    }
    return null;
}

/** Il cliente collegato in questa sessione, se l'accesso è ancora attivo. */
function cliente_collegato(): ?array
{
    $id = $_SESSION['cliente'] ?? '';
    $c = $id !== '' ? cliente_da_id((string) $id) : null;
    return $c && ($c['active'] ?? true) ? $c : null;
}

/** Vero se l'accesso è riuscito, altrimenti il messaggio d'errore. */
function accedi_cliente(string $email, string $password)
{
    // Al massimo 5 tentativi sbagliati ogni 10 minuti.
    $t = array_filter($_SESSION['tentativi'] ?? [], fn($x) => $x > time() - 600);
    if (count($t) >= 5) return 'Troppi tentativi: riprovate tra qualche minuto.';
    $email = mb_strtolower(trim($email));
    foreach (dati()['clients'] ?? [] as $c) {
        if (mb_strtolower($c['email']) !== $email) continue;
        $ok = ($c['passwordHash'] ?? '') !== '' &&
            hash_equals($c['passwordHash'], hash('sha256', ($c['passwordSalt'] ?? '') . '::' . $password));
        if ($ok && !($c['active'] ?? true)) return "L'accesso è sospeso: contattate lo studio.";
        if ($ok) {
            session_regenerate_id(true);
            $_SESSION['cliente'] = $c['id'];
            unset($_SESSION['tentativi']);
            return true;
        }
    }
    $t[] = time();
    $_SESSION['tentativi'] = $t;
    return 'Email o password non corrette.';
}

function esci_cliente(): void
{
    unset($_SESSION['cliente']);
    session_regenerate_id(true);
}
