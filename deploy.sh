#!/bin/bash
source .env

# Check if --debug parameter is passed
debug="true"
for arg in "$@"
do
    if [ "$arg" == "--debug" ]
    then
        debug="true"
    fi
done

SIERRA_FILE=target/dev/comput_SimpleStorage.contract_class.json

# build the solution
build() {
    output=$(scarb build 2>&1)

    if [[ $output == *"Error"* ]]; then
        echo "Error: $output"
        exit 1
    fi
}

# declare the contract
declare() {
    build
        if [[ $debug == "true" ]]; then
        printf "declare %s\n" "$SIERRA_FILE" > debug_project.log
    fi
    output=$(starkli declare $SIERRA_FILE --keystore-password $KEYSTORE_PASSWORD --watch 2>&1)

    if [[ $output == *"Error"* ]]; then
        echo "Error: $output"
        exit 1
    fi

    # Check if ggrep is available
    if command -v ggrep >/dev/null 2>&1; then
        address=$(echo -e "$output" | ggrep -oP '0x[0-9a-fA-F]+')
    else
        # If ggrep is not available, use grep
        address=$(echo -e "$output" | grep -oP '0x[0-9a-fA-F]+')
    fi
    echo $address
}

# deploy the contract
deploy() {
    echo "Declaring contract..."
    class_hash=$(declare | tail -n 1)
    sleep 10
    echo "Deploying contract..."
    if [[ $debug == "true" ]]; then
        printf "deploy %s \n" "$class_hash" >> debug_project.log
    fi
    output=$(starkli deploy $class_hash --keystore-password $KEYSTORE_PASSWORD --watch 2>&1)

    if [[ $output == *"Error"* ]]; then
        echo "Error: $output"
        exit 1
    fi

    # Check if ggrep is available
    if command -v ggrep >/dev/null 2>&1; then
        address=$(echo -e "$output" | ggrep -oP '0x[0-9a-fA-F]+' | tail -n 1) 
    else
        # If ggrep is not available, use grep
        address=$(echo -e "$output" | grep -oP '0x[0-9a-fA-F]+' | tail -n 1) 
    fi
    echo $address
}


contract_address=$(deploy)
echo $contract_address