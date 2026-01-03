# bootstrap.nu
# setup chezmoi in brand-new environment
let GPG_KEY_ID = "5443D40CFB826567374D73B8FD13251EBE42D48D"
let SSH_KEY_PATH = "~/.ssh/bbk_main" | path expand
let ENCRYPTED_SSH_KEY_PATH = "~/.local/share/chezmoi/dot_ssh/encrypted_private_bbk_main.asc" | path expand

# Check GPG key exists
let gpg_key_status = gpg --list-secret-keys $GPG_KEY_ID | complete | get exit_code
if $gpg_key_status != 0 {
	print $"Error: GPG key ($gpg_key_status) not found. Please make sure your GPG key is imported and available."
	exit 1
}
print $"Found GPG Key ($GPG_KEY_ID)"
# Check and decrypt SSH key
if not ( $SSH_KEY_PATH | path exists ) {
	print $"SSH key ($SSH_KEY_PATH) does not exist, trying to decrypt..."

    if not ($ENCRYPTED_SSH_KEY_PATH | path exists) {
        print $"Error: Encrypted SSH key file ($ENCRYPTED_SSH_KEY_PATH) not found."
        print "Please make sure your Chezmoi repository contains this file and it has been synced to your local."
        exit 1
    }

    # Decrypt operation
	if ((gpg -o $SSH_KEY_PATH --decrypt $ENCRYPTED_SSH_KEY_PATH | complete | get exit_code) == 0) {
		open $SSH_KEY_PATH
        print "SSH key successfully decrypted and placed at '$SSH_KEY_PATH'."
    } else {
        print "Error: SSH key decryption failed. Please check GPG environment, encrypted file or your password."
}} else { print $"SSH Key ($SSH_KEY_PATH) already exists, skip." }

# setup ssh-agent
print $"Setting up ssh-agent..."
ssh-add $SSH_KEY_PATH

print "Chezmoi has set up successfully, you can now run 'chezmoi apply -R' to apply your entire configuration. Or run chezmoi apply <path> to apply specific files or directory."
