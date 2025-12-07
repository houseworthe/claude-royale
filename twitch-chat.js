const tmi = require('tmi.js');
const fs = require('fs');
const path = require('path');

// Configuration
const CHANNEL = process.env.TWITCH_CHANNEL || 'FadedDragon72';
const CHAT_LOG_FILE = path.join(__dirname, 'chat-log.txt');
const MAX_MESSAGES = 50; // Keep last 50 messages

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

// Create client (anonymous/read-only - no auth needed)
const client = new tmi.Client({
    channels: [CHANNEL]
});

// Load existing messages on startup
loadExistingMessages();

// Handle incoming messages
client.on('message', (channel, tags, message, self) => {
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
    console.log(`Connected to Twitch chat for #${CHANNEL}`);
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
