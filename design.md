# Hello Counter App - Interface Design

## Design Philosophy
This is a minimal, single-screen counter app focused on simplicity and clarity. The design follows iOS HIG principles with a clean, centered layout optimized for one-handed use in portrait orientation (9:16).

## Screen List
1. **Home Screen** - The only screen, containing the counter display and controls

## Primary Content and Functionality

### Home Screen
- **Large Counter Display**: Shows the current count in a prominent, easy-to-read format (centered, large font)
- **Increment Button**: Large circular button to increase the counter by 1
- **Decrement Button**: Large circular button to decrease the counter by 1
- **Reset Button**: Secondary button to reset counter to 0

## Key User Flows
1. **Increment Counter**: User taps the "+" button → Counter increases by 1
2. **Decrement Counter**: User taps the "-" button → Counter decreases by 1
3. **Reset Counter**: User taps "Reset" button → Counter returns to 0

## Color Choices
- **Primary Action Color**: iOS Blue (#007AFF) - for increment button
- **Secondary Action Color**: iOS Red (#FF3B30) - for decrement button
- **Background**: White (light mode) / Dark gray (#151718) (dark mode)
- **Text**: Dark gray (#11181C) (light mode) / Light gray (#ECEDEE) (dark mode)
- **Reset Button**: Gray (#8E8E93) - neutral action

## Layout Details
- Counter number centered vertically and horizontally
- Buttons arranged in a row below the counter
- Large touch targets (minimum 60pt) for easy tapping
- Consistent 16pt spacing between elements
- All content within safe area bounds

## Typography
- **Counter Display**: 72pt, bold, monospace for clarity
- **Button Labels**: 24pt, semibold
- **Reset Button**: 16pt, regular

## Data Storage
- Local only (AsyncStorage) - no cloud sync needed
- Persists counter value between app launches
