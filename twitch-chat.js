const tmi = require('tmi.js');
const fs = require('fs');
const path = require('path');

// Configuration
const CHANNEL = process.env.TWITCH_CHANNEL || 'FadedDragon72';
const USERNAME = process.env.TWITCH_USERNAME;
const OAUTH_TOKEN = process.env.TWITCH_OAUTH_TOKEN;
const CHAT_LOG_FILE = path.join(__dirname, 'chat-log.txt');
const MAX_MESSAGES = 50; // Keep last 50 messages

// Check if running in send mode
const SEND_MODE = process.argv[2] === '--send';
const SEND_MESSAGE = process.argv[3];

// Build client options (authenticated if credentials exist, anonymous otherwise)
const clientOptions = { channels: [CHANNEL] };
if (OAUTH_TOKEN && USERNAME) {
    clientOptions.identity = {
        username: USERNAME,
        password: `oauth:${OAUTH_TOKEN}`
    };
}

const client = new tmi.Client(clientOptions);

// --- SEND MODE: Send a message and exit ---
if (SEND_MODE) {
    if (!SEND_MESSAGE) {
        console.error('Usage: node twitch-chat.js --send "message"');
        process.exit(1);
    }
    if (!OAUTH_TOKEN || !USERNAME) {
        console.error('Error: TWITCH_OAUTH_TOKEN and TWITCH_USERNAME required for sending');
        process.exit(1);
    }

    client.connect()
        .then(() => {
            return client.say(CHANNEL, SEND_MESSAGE);
        })
        .then(() => {
            console.log(`Sent to #${CHANNEL}: ${SEND_MESSAGE}`);
            setTimeout(() => process.exit(0), 500);
        })
        .catch(err => {
            console.error('Failed to send:', err.message);
            process.exit(1);
        });

    // Don't run the rest of the collector code
    return;
}

// --- COLLECTOR MODE: Listen and log messages ---

// Store messages in memory
let messages = [];

// Load existing messages if file exists
function loadExistingMessages() {
    try {
        if (fs.existsSync(CHAT_LOG_FILE)) {
            const content = fs.readFileSync(CHAT_LOG_FILE, 'utf8');
            const lines = content.trim().split('\n').filter(line => line.length > 0);
            messages = lines.slice(-MAX_MESSAGES);
        }
    } catch (err) {
        console.error('Error loading existing messages:', err.message);
        messages = [];
    }
}

// Save messages to file
function saveMessages() {
    try {
        fs.writeFileSync(CHAT_LOG_FILE, messages.join('\n') + '\n');
    } catch (err) {
        console.error('Error saving messages:', err.message);
    }
}

// Format timestamp
function formatTime(date) {
    return date.toLocaleTimeString('en-US', {
        hour: '2-digit',
        minute: '2-digit',
        second: '2-digit',
        hour12: false
    });
}

// Load existing messages on startup
loadExistingMessages();

// Handle incoming messages
client.on('message', (channel, tags, message, self) => {
    // Ignore messages from ourselves
    if (self) return;

    const timestamp = formatTime(new Date());
    const username = tags['display-name'] || tags.username;
    const formattedMsg = `[${timestamp}] ${username}: ${message}`;

    // Add to array
    messages.push(formattedMsg);

    // Keep only last MAX_MESSAGES
    if (messages.length > MAX_MESSAGES) {
        messages = messages.slice(-MAX_MESSAGES);
    }

    // Save to file
    saveMessages();

    // Log to console for monitoring
    console.log(formattedMsg);
});

// Connection events
client.on('connected', (addr, port) => {
    const authStatus = OAUTH_TOKEN ? '(authenticated)' : '(anonymous)';
    console.log(`Connected to Twitch chat for #${CHANNEL} ${authStatus}`);
    console.log(`Logging messages to: ${CHAT_LOG_FILE}`);
    console.log('---');
});

client.on('disconnected', (reason) => {
    console.log('Disconnected:', reason);
});

// Connect
client.connect().catch(err => {
    console.error('Failed to connect:', err.message);
    process.exit(1);
});

// Handle graceful shutdown
process.on('SIGINT', () => {
    console.log('\nShutting down chat reader...');
    saveMessages();
    client.disconnect();
    process.exit(0);
});

process.on('SIGTERM', () => {
    saveMessages();
    client.disconnect();
    process.exit(0);
});
