# To Do List

A Flutter task planner with Home, Record, and Calendar screens. Tasks can be
added by voice or entered manually, assigned a date, time, and Work/Personal
category, checked off, and saved locally on the device.

The app starts with an empty task list. Each screen keeps its header visible
while its content scrolls. To create a voice task, press and hold the central
microphone while speaking, then release to review and edit the suggested title,
date, and time before saving.

Open Settings from the Home or Calendar header to switch between light and dark
themes or grant notification permission. Upcoming tasks are scheduled as local
device notifications for their due date and time (Android may deliver these
inexactly while the device is idle). Completed tasks remain visible with a
completed status.

## Run

```sh
flutter pub get
flutter run
```

Voice input uses the device's speech-recognition service and requires
microphone/speech-recognition permission. On Android, the system speech service
may also need an internet connection. If speech recognition is unavailable,
tasks can still be entered manually.

Voice phrases such as “Remind me to send the update tomorrow at nine” infer the
task title, date, and time. The parser recognizes today/tomorrow, weekdays,
“next week”, “in N days”, month-and-day dates, numeric times, and spoken
one-through-twelve hour times. If a date or time is not recognized, select it
from the review screen before saving.
