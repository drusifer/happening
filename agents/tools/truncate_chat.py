import os

chat_path = 'agents/CHAT.md'

if not os.path.exists(chat_path):
    print(f"Error: {chat_path} not found.")
    exit(1)

with open(chat_path, 'r') as f:
    lines = f.readlines()

new_lines = []
current_header = None
current_body = []

def process_message():
    if current_header:
        body_text = "".join(current_body).strip()
        if len(body_text) > 256:
            body_text = body_text[:253] + "..."
        new_lines.append(current_header)
        new_lines.append("\n " + body_text + "\n\n")

for line in lines:
    if line.startswith("[<small>"):
        # Process previous message
        process_message()
        # Start new message
        current_header = line
        current_body = []
    elif current_header:
        current_body.append(line)
    else:
        # Lines at the top (like archive links)
        new_lines.append(line)

# Process last message
process_message()

# Write back
with open(chat_path, 'w') as f:
    f.writelines(new_lines)

print("Chat messages truncated successfully.")
