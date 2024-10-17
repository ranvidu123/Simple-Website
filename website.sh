#!/bin/bash

spinner() {
    local pid=$!
    local delay=0.1
    local spinstr='|/-\'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

animate_install() {
    echo -n "Installing $1... "
    "$2" & spinner
    echo "$1 installed."
}

install_ngrok() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        wget -q https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.tgz -O ngrok.tgz
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        wget -q https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-darwin-amd64.tgz -O ngrok.tgz
    else
        echo "Unsupported OS. Please install Ngrok manually."
        exit 1
    fi
    tar -xzf ngrok.tgz > /dev/null
    sudo mv ngrok /usr/local/bin/ > /dev/null
    rm ngrok.tgz
}

install_python() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        sudo apt update -qq && sudo apt install -y python3 python3-pip > /dev/null
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        brew install python > /dev/null
    else
        echo "Unsupported OS. Please install Python manually."
        exit 1
    fi
}

install_jq() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        sudo apt update -qq && sudo apt install -y jq > /dev/null
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        brew install jq > /dev/null
    else
        echo "Unsupported OS. Please install jq manually."
        exit 1
    fi
}

echo "Checking for Ngrok..."
if ! command -v ngrok &> /dev/null; then
    animate_install "Ngrok" install_ngrok
else
    echo "Ngrok already installed."
fi

echo "Checking for Python..."
if ! command -v python3 &> /dev/null && ! command -v python &> /dev/null; then
    animate_install "Python" install_python
else
    echo "Python already installed."
fi

echo "Checking for jq..."
if ! command -v jq &> /dev/null; then
    animate_install "jq" install_jq
else
    echo "jq already installed."
fi

echo "All requirements are installed. Proceeding with website setup..."

cat <<EOL > index.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>File Download Page</title>
    <link rel="stylesheet" href="styles.css">
</head>
<body>
    <div class="container">
        <h1>Welcome to the File Download Page</h1>
        <p>Click the button below to download the sample file.</p>
        <a href="sample.txt" class="download-button" download>Download Sample File</a>
        <footer>
            <p>Simple Website by <strong>Ranvidu123</strong></p>
        </footer>
    </div>
    <script src="script.js"></script>
</body>
</html>
EOL

echo "This is a sample text file for download." > sample.txt

cat <<EOL > styles.css
body {
    font-family: Arial, sans-serif;
    background-color: #f4f4f4;
    color: #333;
    display: flex;
    justify-content: center;
    align-items: center;
    height: 100vh;
    margin: 0;
}

.container {
    text-align: center;
    background: white;
    padding: 20px;
    border-radius: 8px;
    box-shadow: 0 0 10px rgba(0, 0, 0, 0.1);
}

h1 {
    margin-bottom: 10px;
}

.download-button {
    display: inline-block;
    padding: 10px 20px;
    background-color: #007bff;
    color: white;
    text-decoration: none;
    border-radius: 5px;
    transition: background-color 0.3s;
}

.download-button:hover {
    background-color: #0056b3;
}

footer {
    margin-top: 20px;
}

footer p {
    font-size: 14px;
    color: #666;
}
EOL

cat <<EOL > script.js
document.addEventListener("DOMContentLoaded", function() {
    console.log("Webpage Loaded!");
});
EOL

echo "Starting a simple HTTP server on port 8000..."
if command -v python3 &> /dev/null; then
    python3 -m http.server 8000 &
else
    python -m SimpleHTTPServer 8000 &
fi

sleep 2

echo "Starting ngrok..."
ngrok http 8000 &

sleep 2

ngrok_url=$(curl -s http://localhost:4040/api/tunnels | jq -r '.tunnels[0].public_url')

if [ -z "$ngrok_url" ]; then
    echo "Failed to get the ngrok URL. Please check if ngrok is running correctly."
    exit 1
fi

echo "Your website is accessible at: $ngrok_url"

wait
