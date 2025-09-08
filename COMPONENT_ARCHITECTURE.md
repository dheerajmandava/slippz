# Slippz Warranty Tracker - Component Architecture

## Overview
This document outlines the redesigned component architecture for the Slippz warranty tracker app, based on the Figma design requirements.

## Main Screen
**File:** `lib/screens/warranty_tracker_screen.dart`
- Main entry point for the warranty tracker
- Combines all components into a cohesive interface
- Handles data loading and state management
- Uses sample data when no real receipts are available

## Component Structure

### 1. AppHeader
**File:** `lib/widgets/app_header.dart`
- Custom header with "Slippz" branding
- Hand-drawn style typography
- App logo and navigation actions
- Responsive design with proper spacing

### 2. WarrantySummaryCard
**File:** `lib/widgets/warranty_summary_card.dart`
- Donut chart showing warranty coverage
- Displays covered value vs expiring soon value
- Total value display in center
- Color-coded legend (teal for covered, yellow for expiring)
- Uses fl_chart package for visualization

### 3. SlipCard
**File:** `lib/widgets/slip_card.dart`
- Individual receipt/slip display card
- Shows merchant, product, price, and AI insights
- Displays warranty status and purchase date
- Merchant-specific icons
- Clean, modern card design

### 4. LatestSlipsSection
**File:** `lib/widgets/latest_slips_section.dart`
- Container for the "Latest Slips" section
- Displays up to 3 recent receipts
- "View All" navigation option
- Empty state handling
- Integrates with SlipCard components

## Design System

### Colors
- **Primary Teal:** `#14B8A6` (covered warranties)
- **Warning Yellow:** `#F59E0B` (expiring warranties)
- **Background:** `#F9FAFB` (light gray)
- **Card Background:** `#FFFFFF` (white)
- **Text Primary:** `#111827` (dark gray)
- **Text Secondary:** `#6B7280` (medium gray)

### Typography
- **App Title:** 24px, FontWeight.w800, italic style
- **Section Headers:** 18px, FontWeight.w700, italic style
- **Card Titles:** 14px, FontWeight.w700
- **Body Text:** 14px, FontWeight.w500
- **Small Text:** 12px, FontWeight.w500

### Spacing
- **Card Padding:** 16px
- **Section Spacing:** 24px
- **Component Spacing:** 12px
- **Icon Size:** 24px (large), 16px (medium), 14px (small)

## Data Flow

1. **WarrantyTrackerScreen** loads data from DatabaseService
2. Falls back to SampleDataService if no data exists
3. Calculates warranty values (covered, expiring, total)
4. Passes data to child components
5. Components render based on received data

## Sample Data
**File:** `lib/services/sample_data_service.dart`
- Provides sample receipts for demonstration
- Includes Best Buy, Whole Foods, and Tesla Service examples
- Matches the Figma design requirements
- Used when no real data is available

## Key Features

### Warranty Tracking
- Visual donut chart showing coverage status
- Color-coded warranty status indicators
- AI-powered categorization and insights
- Expiry date tracking and warnings

### Modern UI/UX
- Hand-drawn aesthetic matching Figma design
- Clean card-based layout
- Proper spacing and typography hierarchy
- Responsive design principles

### Component Separation
- Each component has a single responsibility
- Reusable and maintainable code structure
- Easy to modify individual components
- Clear data flow and prop passing

## Usage

The main screen is automatically loaded when users are authenticated. The component structure allows for easy customization and extension:

```dart
// Main screen usage
WarrantyTrackerScreen()

// Individual component usage
WarrantySummaryCard(
  coveredValue: 560.0,
  expiringValue: 100.0,
  totalValue: 1247.0,
)

SlipCard(
  receipt: receipt,
  aiInsight: 'Categorized: Electronics',
  warrantyStatus: '2y left',
)
```

## Future Enhancements

1. **Animation:** Add smooth transitions between states
2. **Theming:** Support for dark mode and custom themes
3. **Accessibility:** Enhanced screen reader support
4. **Performance:** Optimize chart rendering for large datasets
5. **Customization:** User-configurable color schemes and layouts
