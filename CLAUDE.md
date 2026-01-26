# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Affirm iOS SDK - A merchant SDK that enables iOS apps to integrate Affirm's buy-now-pay-later financing platform. The SDK provides two main components:
1. **Checkout Flow** - Handle purchase financing through Affirm (regular checkout or Virtual Card Network)
2. **Promotional Messaging** - Display "As low as" promotional payment messaging to customers

## Build and Test Commands

### Building the SDK
```bash
# Build the SDK for iOS Simulator
xcodebuild build-for-testing -project AffirmSDK.xcodeproj -scheme AffirmSDK -destination "platform=iOS Simulator,name=iPhone 15"

# Clean build
xcodebuild clean build -project AffirmSDK.xcodeproj -scheme AffirmSDK -destination "platform=iOS Simulator,name=iPhone 15"
```

### Running Tests
```bash
# Run all tests
xcodebuild clean test -project AffirmSDK.xcodeproj -scheme AffirmSDK -destination "platform=iOS Simulator,name=iPhone 15"
```

### Example Apps
```bash
# Install dependencies for example apps
cd Examples
pod install

# Then open Examples.xcworkspace and run the Examples or ExamplesSwift target
```

## Architecture and Code Organization

### Core Source Directory
- **AffirmSDK/** - Main SDK source code (Objective-C .h/.m files)
- **SPM/** - Mirror of AffirmSDK for Swift Package Manager distribution
- **AffirmSDKTests/** - Unit tests
- **Examples/** - Demo apps (Objective-C and Swift)

### Key Components

#### 1. Configuration (`AffirmConfiguration`)
The singleton configuration object that must be initialized at app startup with:
- Public API key
- Environment (sandbox vs production)
- Locale and country code
- Currency
- Merchant name

#### 2. Checkout Flow (`AffirmCheckout` + `AffirmCheckoutViewController`)
**AffirmCheckout**: The data model containing:
- Items being purchased
- Shipping/billing details
- Tax and shipping amounts
- Discounts and metadata
- Total amount (amounts are in dollars, not cents)

**AffirmCheckoutViewController**: Handles the checkout UI flow with two modes:
- **Regular Checkout**: Returns a checkout token via `checkout:completedWithToken:`
- **VCN (Virtual Card Network)**: Returns credit card info via `vcnCheckout:completedWithCreditCard:`

Key parameters:
- `useVCN`: Boolean to toggle between regular and VCN checkout
- `getReasonCodes`: Boolean to get cancellation reason codes
- `cardAuthWindow`: Authorization window for VCN (in minutes)

#### 3. Promotional Messaging (`AffirmPromotionalButton`)
Displays "As low as $X/month" messaging inline in the app. Configuration options:
- HTML styling (with remote fonts/CSS)
- Local font styling
- Raw HTML string rendering
- Automatically hides if no promo is available

Tapping the button opens `AffirmPrequalModalViewController` for prequalification.

#### 4. Data Fetching (`AffirmDataHandler`)
Provides raw promotional message strings and handles network requests for promo data.

#### 5. Network Layer (`AffirmRequest`, `AffirmClient`)
Request/response objects for:
- **AffirmPromoRequest/Response**: Fetching promotional messages
- **AffirmCheckoutRequest/Response**: Creating checkout sessions
- **AffirmLogRequest**: Event tracking
- **AffirmErrorResponse**: Error handling

### Important Data Models
- **AffirmItem**: Individual purchase items with SKU, price, quantity
- **AffirmShippingDetail**: Shipping address information
- **AffirmBillingDetail**: Billing address information
- **AffirmDiscount**: Discount information
- **AffirmCreditCard**: VCN card details returned from checkout
- **AffirmReasonCode**: Cancellation reason codes
- **AffirmOrder/AffirmProduct**: Order tracking models

### Distribution Methods

The SDK supports multiple distribution methods, with source duplicated across:
1. **CocoaPods**: Uses `AffirmSDK/` directory
2. **Carthage**: Uses `AffirmSDK/` directory
3. **Swift Package Manager**: Uses `SPM/` directory (includes XIBs and bundle resources)
4. **Manual Integration**: Direct drag-and-drop of `AffirmSDK/` folder

**IMPORTANT**: When making code changes, update BOTH `AffirmSDK/` and `SPM/` directories to maintain consistency across distribution methods.

## Key Implementation Notes

### Amount Handling
- All monetary amounts should be in **dollars** (not cents)
- Round to nearest dollar before passing to SDK methods
- SDK converts to cents internally for API calls

### Checkout Token Flow
1. User completes checkout → SDK returns token
2. Token must be sent to merchant server
3. Merchant server uses token to authorize charge via Affirm API

### VCN Checkout Flow
1. User completes VCN checkout → SDK returns `AffirmCreditCard` object
2. Merchant processes card through existing payment gateway
3. No server-side Affirm API call needed

### Web View Architecture
- All user-facing flows use `WKWebView` via `AffirmBaseWebViewController`
- Shared `WKProcessPool` in `AffirmConfiguration` for cookie/session persistence
- JavaScript bridge for communication between native and web layers

### Environment Configuration
Two environments available:
- `AffirmEnvironmentSandbox`: For testing
- `AffirmEnvironmentProduction`: For live transactions

Get URLs via `AffirmConfiguration` methods:
- `jsURL`: Affirm JavaScript URL
- `promosURL`: Promotional messaging endpoint
- `checkoutURL`: Checkout endpoint
- `trackerURL`: Analytics endpoint

## Testing Notes

Test targets:
- **AffirmSDK** (main scheme): Framework target
- **AffirmSDKTests**: Unit test suite covering checkout, configuration, and promo functionality

Tests focus on:
- Model serialization/deserialization
- Configuration validation
- Checkout object creation
- Promotional message formatting
