# User Guide — Happening

Welcome to Happening! This guide will help you understand how to use the timeline strip and get the most out of your day.

---

## 1. What is Happening?

Happening is a **persistent, always-on-top horizontal timeline strip** that lives at the top of your screen. It shows your Google Calendar events flowing toward a fixed "Now" indicator in real time.

> "The calendar comes to you."

---

## 2. Getting Started

### 1. Launching the App
When you first launch the app, you will see a **Sign-In Strip**.

### 2. Signing In
1. Click the **"Tap to Sign In"** button on the strip.
2. Your default web browser will open to the Google Account selection page.
3. Select your Google account and grant Happening permission to read your calendar events.
4. Once authorized, you can close the browser tab.
5. Happening will automatically load your events for today and start the timeline.

---

## 3. Understanding the Interface

### The Strip
The strip is always visible at the top of your primary display. It stays above all other windows so you always have immediate, glanceable awareness of your schedule.

### Now Indicator
The **Now Indicator** is a fixed vertical line (at the 10% mark from the left) that represents the current moment. 
- Everything to the **left** of the line is the **past**.
- Everything to the **right** of the line is the **future**.

### Event Blocks
Each calendar event appears as a **colored block**.
- The length of the block represents the event's duration.
- The gap between blocks represents the time between events.
- Events slide from right to left as time passes.

### Countdown Timer
Located near the Now Indicator, the **Countdown** tells you exactly how much time remains until your next event starts.
- **Example**: "38 min" means your next meeting starts in 38 minutes.

### End of Day
When you have no more events scheduled for the rest of today, Happening displays a **Celebration Message** (e.g., "All done for today! ✨").

---

## 4. Interaction Features

### Hover Details (v0.1+)
Move your mouse over an event block to see more information:
- **Title**: The full title of the event.
- **Time**: The start and end time.
- **Join Button**: If the event has a Google Meet, Zoom, or Teams link, a button will appear to join the call instantly.
- **Calendar Link**: A button to open the event in your web browser.

### Settings & Controls (Coming Soon)
A gear icon will appear on the far right of the strip when you hover over it, allowing you to:
- Adjust font sizes (Small, Medium, Large).
- Log out and switch Google accounts.
- Manually refresh the calendar.

---

## 5. Troubleshooting

- **Strip is hidden**: Happening is designed to be "Always on Top," but some fullscreen applications (like games or certain video players) may override this.
- **Events not showing**: 
  - Ensure you are signed into the correct Google account.
  - Happening only shows events from your **Primary** calendar.
  - Check that the event is scheduled for **today**.
- **Window Positioning (Linux)**: On some Linux distributions using Wayland, the strip may appear in the center of the screen. We use an X11 bridge to fix this; if it persists, please contact support.

---

## 6. Feedback & Bugs
Found a bug? Have a suggestion? Reach out to us at [drusifer@gmail.com].
