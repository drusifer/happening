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

### Events & Tasks
- **Event Blocks**: Each calendar event appears as a colored block. The length represents the duration, and the colors match your Google Calendar.
- **Task Markers (◇)**: Calendar items marked as tasks (or "Focus Time" in some cases) appear as diamond-shaped markers on the timeline.

### Tick Marks & Time
The timeline features adaptive tick marks to help you keep track of the day:
- **Hour Ticks**: Large markers with labels (e.g., "10am").
- **30-Min Ticks**: Smaller markers with half-hour labels.
- **15-Min Ticks**: Tiny markers for precise glanceable timing.

### Gap Labels
Gaps between events represent your free time. When a gap is large enough, Happening displays the duration (e.g., "45m") directly on the strip.

### Countdown Timer
Located to the right of the Now Indicator, the countdown keeps you informed of your next transition:
- **White**: Time until your next event starts.
- **Amber**: Time until your *current* meeting ends.
- **Orange/Red**: Urgency signals when a transition is imminent (under 5 minutes).

### End of Day
When you have no more events scheduled for the rest of today, Happening displays a **Celebration Message** (e.g., "All done for today! ✨").

---

## 4. Interaction Features

### Hover Details
Move your mouse over an event block or task to see more information:
- **Title**: The full title of the item.
- **Time**: The start and end time.
- **Join Button**: If the event has a Google Meet, Zoom, or Teams link, a button will appear to join the call instantly.
- **Calendar Link**: A button to open the event in your web browser.

### Settings & Controls
Hover over the far right of the strip to reveal the **Gear** and **Refresh** icons:
- **Font Size**: Choose between Small, Medium, and Large text. The strip height will adjust automatically to match your preference.
- **Manual Refresh**: Force a live sync with Google Calendar.
- **Logout**: Clear your credentials and switch Google accounts.

### Upcoming in v0.2.0 (In Progress)
- **Multi-Calendar Support**: Select and display events from multiple Google Calendars.
- **Themes**: Dark, Light, and System theme support.
- **Collision Detection**: Visual indicators for overlapping events.

---

## 5. Troubleshooting

- **Strip is hidden**: Happening is designed to be "Always on Top," but some fullscreen applications (like games or certain video players) may override this.
- **Events not showing**: 
  - Ensure you are signed into the correct Google account.
  - Happening currently shows events from your **Primary** calendar (multi-calendar support is coming in v0.2.0).
  - Check that the event is scheduled for **today**.
- **Window Positioning (Linux)**: On some Linux distributions using Wayland, the strip may appear in the center of the screen. We use an X11 bridge to fix this; if it persists, ensure `GDK_BACKEND=x11` is set in your environment.

---

## 6. Feedback & Bugs
Found a bug? Have a suggestion? Reach out to us at [drusifer@gmail.com].
