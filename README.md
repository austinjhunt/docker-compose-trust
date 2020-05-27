# Docker Compose Trust
Docker Compose is not compatible with Docker Content Trust, meaning you can't say 'docker-compose trust sign'.
You instead have to use 'docker trust sign <image>:<tag>' for every image in your compose file, and for each of them,
pass in the root signing key passphrase AND the repo signing key passphrase.
## Requirements
0. Have a LastPass account, and have [LastPass CLI](https://github.com/lastpass/lastpass-cli) installed (to use the lpass command)
1. Have your signing key passphrases for each image stored in LastPass as a secure password with the name in this standardized format:
```dct_IMAGE_signingkeypass```
```ex: dct_myserviceaccount/myubuntuimage_signingkeypass ```
2. Have your root signing key passphrase stored in LastPass as a secure password with the name in the standardized format:
``` dct-root-signing-key-pass ```
3. Have your signer key passphrase stored in LastPass as a secure password with the name in the standardized format:
``` dct-signer-key-pass ```
Note: an assumption is made here that the signer is the same for all images in your compose file.
## What does this do?
This script extracts the names of the referenced images from your docker-compose file, and uses the docker trust sign command on each of those images, allowing you to sign all of your images at once.
## How does it work?
Since docker trust prompts for the key-signing passphrases, the script uses the LastPass CLI to pull those passphrases from your LastPass account and
pass them into either 1) environment variables or 2) stdin.
## Usage
1. Clone the repository
``` git clone https://hammond.cofc.edu/huntaj/docker-compose-trust.git ```
2. Navigate into the project and source the script to create the alias for the primary function (alias is 'docker-compose-trust')
``` source docker-compose-sign-all.sh ```
3. Navigate into the directory where your docker-compose.yml file is that references all of the images you want to sign.
``` e.g.: cd ~/mycode/ ```
``` ls ```
``` docker-compose.yml .....```
4. Execute the alias
``` docker-compose-trust ```


