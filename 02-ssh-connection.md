# 02 — SSH Connection from Windows

## Objective

Establish a secure, encrypted remote shell session from the local Windows machine in Perth to the cloud VM in Sydney, using public-key authentication.

## Why SSH

SSH (Secure Shell) is the standard protocol for remote administration of Linux/Unix systems. It provides:

1. **Encryption** — all traffic between client and server is encrypted, protecting against eavesdropping
2. **Integrity** — cryptographic checksums detect any tampering with traffic in transit
3. **Authentication** — public-key cryptography proves the identity of both client and server
4. **Multiplexing** — a single SSH session can carry shell, file transfer, and tunneled traffic

SSH replaces older insecure protocols such as Telnet (unencrypted shell) and rlogin.

## How SSH Public-Key Authentication Works

Public-key cryptography uses **two mathematically linked keys**:

- **Private key** — kept secret on the client (local) machine; never shared
- **Public key** — placed on the server in `~/.ssh/authorized_keys`; safe to distribute

The authentication exchange (simplified):

1. Client connects to server and announces which public key it intends to use
2. Server sends a random challenge encrypted with that public key
3. Only the holder of the matching private key can decrypt the challenge
4. Client decrypts and returns the challenge; server verifies the match
5. Authentication succeeds; encrypted session begins

The mathematical link between the keys is one-way: it is computationally infeasible to derive the private key from the public key. This is why public keys are safe to share but private keys must be protected.

## Pre-requisites on Windows

Modern Windows 10/11 includes the OpenSSH client by default, accessible through PowerShell. No additional software (such as PuTTY) is required for this project.

## Step 1 — Locate the Private Key File

The private key file (`ict171-server_key.pem`) was downloaded from Azure during VM provisioning. It must be stored in a known, secure location on the local machine.

### Command to find any .pem file on the system

```powershell
Get-ChildItem -Path $HOME -Recurse -Filter *.pem -ErrorAction SilentlyContinue | Select-Object FullName
```

**Breakdown of this command:**

| Component | Purpose |
|-----------|---------|
| `Get-ChildItem` | PowerShell cmdlet for listing files and folders (equivalent to `dir` or `ls`) |
| `-Path $HOME` | Starts the search from the user's home directory (`C:\Users\<username>\`) |
| `-Recurse` | Searches subdirectories as well, not just the top level |
| `-Filter *.pem` | Limits results to files ending in `.pem` |
| `-ErrorAction SilentlyContinue` | Suppresses permission-denied errors on system folders, keeping output clean |
| `\| Select-Object FullName` | Pipes results to display only the full path (cleaner output than the default file listing) |

In this project, the key was located at:

```
C:\Users\alazi\Downloads\ict171-server_key.pem
```

## Step 2 — Set Restrictive File Permissions on the Private Key

The OpenSSH client refuses to use a private key file if it has permissive file permissions, because that would allow other users on the system to read the key. Windows defaults to permissive inherited permissions for files in `Downloads`, so the permissions must be tightened.

### Navigate to the key's directory

```powershell
cd "C:\Users\alazi\Downloads"
```

`cd` (change directory) moves the PowerShell session into the specified folder. The quotes are required when the path contains spaces (none in this case, but it's a good habit).

### Strip inherited permissions

```powershell
icacls .\ict171-server_key.pem /inheritance:r
```

| Component | Purpose |
|-----------|---------|
| `icacls` | Windows command-line tool for displaying and modifying file Access Control Lists (ACLs) |
| `.\ict171-server_key.pem` | The target file; `.\` means "in the current directory" |
| `/inheritance:r` | Removes (`r` for "remove") all inherited permissions from parent folders |

After this command, the file has no permissions assigned at all (effectively no one can read it), so we must explicitly grant access to the current user.

### Grant read access to the current user only

```powershell
icacls .\ict171-server_key.pem /grant:r "${env:USERNAME}:(R)"
```

| Component | Purpose |
|-----------|---------|
| `/grant:r` | Replace existing permissions (the `:r` means "replace", not "add") |
| `${env:USERNAME}` | PowerShell environment variable that expands to the current Windows username |
| `:(R)` | Grant Read permission only |

After this, the private key is readable **only by the current Windows user**, which is what SSH requires.

## Step 3 — Establish the SSH Connection

```powershell
ssh -i .\ict171-server_key.pem azureuser@20.5.169.97
```

| Component | Purpose |
|-----------|---------|
| `ssh` | The OpenSSH client |
| `-i .\ict171-server_key.pem` | Specifies the **identity file** (private key) to use for authentication |
| `azureuser` | The remote username (matches what was set during VM provisioning) |
| `@20.5.169.97` | The remote host — the public IPv4 address of the Azure VM |

### First-Connection Host Verification

On the first connection to a new host, SSH displays the server's host key fingerprint and asks for confirmation:

```
The authenticity of host '20.5.169.97 (20.5.169.97)' can't be established.
ED25519 key fingerprint is SHA256:weAfAJdaGpT0LZKxttTzVtpf8gJppBjytMw8tHwHog4.
This key is not known by any other names.
Are you sure you want to continue connecting (yes/no/[fingerprint])?
```

This is a security feature, not an error. SSH is asking the user to verify that the server they're connecting to is genuinely their server, not an attacker intercepting the connection.

Typing `yes` and pressing Enter accepts the host key and adds it to `~/.ssh/known_hosts` on the local machine. Subsequent connections to this IP will not display this prompt; any mismatch on a future connection will trigger a security warning.

## Step 4 — Verify Successful Connection

After accepting the host key, the server displays its welcome message and presents a shell prompt:

```
Welcome to Ubuntu 24.04.4 LTS (GNU/Linux 6.17.0-1015-azure x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/pro

  System information as of Tue May 26 02:02:54 UTC 2026

  System load:  0.0                Processes:             117
  Usage of /:   5.8% of 28.02GB    Users logged in:       0
  Memory usage: 33%                IPv4 address for eth0: 10.1.0.4
  Swap usage:   0%

azureuser@ict171-server:~$
```

The shell prompt `azureuser@ict171-server:~$` indicates:

- `azureuser` — the username on the remote system
- `ict171-server` — the hostname of the remote VM
- `~` — the current working directory (the user's home folder, `/home/azureuser`)
- `$` — non-root user prompt (root would show `#`)

All subsequent commands are executed on the remote VM, not the local Windows machine.

## Common Failure Modes

| Symptom | Cause | Resolution |
|---------|-------|------------|
| `Permissions for 'key.pem' are too open` | Step 2 was skipped or incomplete | Re-run the `icacls` commands |
| `Permission denied (publickey)` | Wrong key file specified, or key doesn't match the VM | Verify the correct `.pem` file is being used |
| Connection times out | NSG/firewall blocks port 22, or VM is stopped | Verify VM status and NSG rules in Azure portal |
| Connection refused | SSH daemon not running on the VM | Restart VM from Azure portal |

## Security Note — Why the Private Key Must Never Be Shared

If the private key file is ever exposed (uploaded to a public repository, pasted into a chat, emailed, etc.), it must be considered permanently compromised. Anyone in possession of the file can authenticate to the VM as `azureuser`, with full administrative privileges via `sudo`. The correct recovery procedure is:

1. Treat the key as burned — do not attempt to "secure" it after exposure
2. Either rebuild the VM (cleanest) or use Azure's "Reset SSH public key" feature to install a new key
3. Generate and use a fresh key pair going forward

This principle (assume compromise, rotate credentials) is fundamental to credential hygiene in real-world infrastructure operations.

## Output

A successful SSH session was established from `C:\Users\alazi\Downloads\` on the Windows machine to `azureuser@ict171-server` (Public IP 20.5.169.97) over port 22 using RSA public-key authentication.
