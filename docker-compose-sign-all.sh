#!/bin/bash
# Austin Hunt
# May 27, 2020
# Docker Compose is not compatible with Docker Content Trust, meaning you can't say 'docker-compose trust sign'.
# You instead have to use 'docker trust sign <image>:<tag>' for every image in your compose file, and for each of them,
# pass in the root signing key passphrase AND the repo signing key passphrase.

# Dynamically pull the list of images from your docker-compose file.
dockercomposetrust(){
    echo "Do you have all of your image signing passphrases stored in lastpass as dct_IMAGE_signingkeypass? (y/n)"
    read ans
    if [[ $ans != 'Y' && $ans != 'y' && $ans != 'yes' ]]; then
        echo "Please do that first."
        echo "Exiting..."
        exit 1
    fi


    echo "Checking if you are logged in to LastPass CLI..."
    sleep 1
    # Log in if not already
    if [[ $(lpass status) != *"Logged in"* ]]; then
        echo "Logging into LastPass..."
        sleep 1
        echo "Enter your LastPass username"
        read username
        lpass login $username
    else
        echo "You are already logged in :)"
        sleep 1
    fi



    images=$( docker-compose config | grep image | cut -d' ' -f6 )

    # You need to name your LastPass signing key passphrase for EACH image as follows:
    # dct_IMAGE_signingkeypass
    # e.g. dct_serviceAccount/image_signingkeypass


    # You also NEED to have LastPass CLI installed.

    # Get the root signing key, which should be named
    # dct-root-signing-key-pass
    rskp=$(lpass show --password dct-root-signing-key-pass)

    # Store your key passphrase that you created when you used
    # docker trust key generate <signer>
    signerkeypass=$(lpass show --password dct-signer-key-pass)
    # This will pipe into docker trust sign <image>:<tag>


    # Temporarily set this environment variable to bypass the prompt for root signing key passphrase.
    export DOCKER_CONTENT_TRUST_ROOT_PASSPHRASE="${rskp}"

    for image in $images; do
        lastpass_pass_store="dct_${image}_signingkeypass"
        password=$(lpass show --password $lastpass_pass_store)
        echo "Lastpass store for image ${image}: ${lastpass_pass_store}"
        echo "Using password: ${password}"
        # Temporarily set this environment variable for this repository specifically to bypass prompt
        # for the repo signing key passphrase.
        export DOCKER_CONTENT_TRUST_REPOSITORY_PASSPHRASE="${password}"

        # Should not prompt for either the root or the repo signing key passphrases!
        # docker trust sign requires that a tag be included. Check if one is there. If not, add latest.
        if [[ ${image} != *":"* ]]; then
            # Does not contain a tag.
            # Add :latest to end
            image="${image}:latest"
        fi
        echo "Signing image: ${image}"
        {
            echo $signerkeypass | docker trust sign $image
        } || {
            echo "First sign attempt failed. Retrying with empty DCT environment variables."
            DOCKER_CONTENT_TRUST_REPOSITORY_PASSPHRASE=""
            DOCKER_CONTENT_TRUST_ROOT_PASSPHRASE=""
            echo $signerkeypass | docker trust sign $image
        }
    done;

    # Empty those environment variables if requested.
    echo "Would you like to clear the environment variable DOCKER_CONTENT_TRUST_ROOT_PASSPHRASE? (y/n)"
    read ans
    if [[ $ans != 'Y' && $ans != 'y' && $ans != 'yes' ]]; then
        echo "Clearing..."
        export DOCKER_CONTENT_TRUST_ROOT_PASSPHRASE=""
    fi

    echo "Would you like to clear the environment variable DOCKER_CONTENT_TRUST_REPOSITORY_PASSPHRASE? (y/n)"
    read ans
    if [[ $ans != 'Y' && $ans != 'y' && $ans != 'yes' ]]; then
        echo "Clearing..."
        export DOCKER_CONTENT_TRUST_REPOSITORY_PASSPHRASE=""
    fi
}
alias docker-compose-trust=dockercomposetrust