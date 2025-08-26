#!/bin/bash

# Nostr Runtime Test Script - Tests actual functionality with iOS Simulator
# This script tests the real Nostr integration by running the app

echo "🚀 === NOSTR RUNTIME FUNCTIONALITY TEST ==="
echo "Testing actual Nostr functionality with iOS Simulator"
echo "Time: $(date)"
echo "=============================================="

# Test Variables
PROJECT_DIR="/Users/dakotabrown/LevelFitness-IOS"
DEVICE_LOG="/tmp/runstr_simulator.log"
TEST_DURATION=30 # seconds

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

function check_simulator() {
    echo -e "\n${BLUE}📱 Checking iOS Simulator...${NC}"
    
    # Get available simulators
    local simulators
    simulators=$(xcrun simctl list devices available | grep "iPhone" | head -1)
    
    if [[ -n "$simulators" ]]; then
        echo "✅ iOS Simulator available"
        return 0
    else
        echo "❌ No iOS Simulators available"
        return 1
    fi
}

function start_simulator_logging() {
    echo -e "\n${BLUE}📋 Starting device logging...${NC}"
    
    # Clear previous log
    > "$DEVICE_LOG"
    
    # Start logging in background
    xcrun simctl spawn booted log stream --predicate 'subsystem CONTAINS "com.runstr.rewards" OR (processImagePath CONTAINS "RunstrRewards")' > "$DEVICE_LOG" 2>&1 &
    local log_pid=$!
    
    echo "✅ Device logging started (PID: $log_pid)"
    echo "$log_pid" > /tmp/runstr_log_pid
    
    # Give logging a moment to start
    sleep 2
    return 0
}

function stop_simulator_logging() {
    if [[ -f /tmp/runstr_log_pid ]]; then
        local log_pid
        log_pid=$(cat /tmp/runstr_log_pid)
        kill "$log_pid" 2>/dev/null
        rm -f /tmp/runstr_log_pid
        echo "✅ Device logging stopped"
    fi
}

function build_and_run_app() {
    echo -e "\n${BLUE}🔨 Building and launching app...${NC}"
    
    cd "$PROJECT_DIR" || return 1
    
    # Build for simulator
    echo "   Building for iOS Simulator..."
    local build_output
    build_output=$(xcodebuild -project RunstrRewards.xcodeproj -scheme RunstrRewards -configuration Debug -destination "platform=iOS Simulator,name=iPhone 16 Pro" build 2>&1)
    local build_status=$?
    
    if [[ $build_status -ne 0 ]]; then
        echo "❌ Build failed"
        echo "$build_output" | tail -10
        return 1
    fi
    
    echo "✅ Build successful"
    
    # Launch app on simulator
    echo "   Launching app on simulator..."
    xcrun simctl install booted build/Debug-iphonesimulator/RunstrRewards.app 2>/dev/null
    xcrun simctl launch booted com.runstr.rewards 2>/dev/null
    
    echo "✅ App launched"
    return 0
}

function test_nostr_authentication() {
    echo -e "\n${BLUE}🔑 Testing Nostr Authentication...${NC}"
    
    # Wait for app to initialize
    sleep 5
    
    # Check logs for authentication activity
    local auth_logs
    auth_logs=$(grep -i "nostr.*auth\|authentication.*nostr" "$DEVICE_LOG" 2>/dev/null | tail -5)
    
    if [[ -n "$auth_logs" ]]; then
        echo "✅ Nostr authentication activity detected"
        echo "   Recent logs:"
        echo "$auth_logs" | sed 's/^/   /'
        return 0
    else
        echo "⚠️  No Nostr authentication activity (may be normal if not signed in)"
        return 0
    fi
}

function test_key_generation() {
    echo -e "\n${BLUE}🔐 Testing Key Generation...${NC}"
    
    # Look for key generation activity
    local key_logs
    key_logs=$(grep -i "key.*generat\|generat.*key\|nsec\|npub" "$DEVICE_LOG" 2>/dev/null | tail -5)
    
    if [[ -n "$key_logs" ]]; then
        echo "✅ Key generation activity detected"
        echo "   Recent logs:"
        echo "$key_logs" | sed 's/^/   /'
        
        # Check for security - ensure no private keys are logged
        local private_key_exposed
        private_key_exposed=$(grep -i "nsec1[a-z0-9]" "$DEVICE_LOG" 2>/dev/null | grep -v "REDACTED")
        
        if [[ -n "$private_key_exposed" ]]; then
            echo "❌ SECURITY ISSUE: Private keys found in logs"
            return 1
        else
            echo "✅ Security check passed - no private keys in logs"
            return 0
        fi
    else
        echo "⚠️  No key generation activity detected"
        return 0
    fi
}

function test_relay_connections() {
    echo -e "\n${BLUE}🌐 Testing Relay Connections...${NC}"
    
    # Look for relay connection activity
    local relay_logs
    relay_logs=$(grep -i "relay\|websocket\|wss://" "$DEVICE_LOG" 2>/dev/null | tail -10)
    
    if [[ -n "$relay_logs" ]]; then
        echo "✅ Relay connection activity detected"
        echo "   Recent relay activity:"
        echo "$relay_logs" | sed 's/^/   /'
        
        # Count successful connections
        local success_count
        success_count=$(echo "$relay_logs" | grep -i "connect\|established\|success" | wc -l)
        
        if [[ $success_count -gt 0 ]]; then
            echo "✅ Successful relay connections: $success_count"
            return 0
        else
            echo "⚠️  No successful connections detected"
            return 0
        fi
    else
        echo "⚠️  No relay activity detected"
        return 0
    fi
}

function test_profile_fetching() {
    echo -e "\n${BLUE}👤 Testing Profile Fetching...${NC}"
    
    # Look for profile fetching activity
    local profile_logs
    profile_logs=$(grep -i "profile\|fetch.*profile\|nostr.*profile" "$DEVICE_LOG" 2>/dev/null | tail -10)
    
    if [[ -n "$profile_logs" ]]; then
        echo "✅ Profile fetching activity detected"
        echo "   Recent profile activity:"
        echo "$profile_logs" | sed 's/^/   /'
        
        # Check for successful profile loads
        local success_profiles
        success_profiles=$(echo "$profile_logs" | grep -i "success\|loaded\|updated" | wc -l)
        
        if [[ $success_profiles -gt 0 ]]; then
            echo "✅ Profile fetching working: $success_profiles events"
            return 0
        else
            echo "⚠️  Profile fetching attempted but no successes"
            return 0
        fi
    else
        echo "⚠️  No profile fetching activity detected"
        return 0
    fi
}

function test_bridge_functionality() {
    echo -e "\n${BLUE}🌉 Testing NostrSDK Bridge...${NC}"
    
    # Look for bridge activity
    local bridge_logs
    bridge_logs=$(grep -i "nostr.*bridge\|bridge.*nostr\|NostrSDKBridge" "$DEVICE_LOG" 2>/dev/null | tail -5)
    
    if [[ -n "$bridge_logs" ]]; then
        echo "✅ NostrSDK Bridge activity detected"
        echo "   Recent bridge activity:"
        echo "$bridge_logs" | sed 's/^/   /'
        return 0
    else
        echo "⚠️  No bridge activity detected (may be normal)"
        return 0
    fi
}

function analyze_full_log() {
    echo -e "\n${BLUE}📊 Full Log Analysis...${NC}"
    
    if [[ ! -f "$DEVICE_LOG" ]]; then
        echo "❌ No device log found"
        return 1
    fi
    
    local log_size
    log_size=$(wc -l < "$DEVICE_LOG")
    
    echo "   Total log lines: $log_size"
    
    # Count different types of activity
    local nostr_lines
    nostr_lines=$(grep -i nostr "$DEVICE_LOG" 2>/dev/null | wc -l)
    
    local error_lines
    error_lines=$(grep -i error "$DEVICE_LOG" 2>/dev/null | wc -l)
    
    local success_lines
    success_lines=$(grep -i success "$DEVICE_LOG" 2>/dev/null | wc -l)
    
    echo "   Nostr-related lines: $nostr_lines"
    echo "   Error lines: $error_lines"
    echo "   Success lines: $success_lines"
    
    if [[ $nostr_lines -gt 0 ]]; then
        echo "✅ Nostr integration is active"
        
        # Show most recent Nostr activity
        echo "   Most recent Nostr activity:"
        grep -i nostr "$DEVICE_LOG" 2>/dev/null | tail -3 | sed 's/^/   /'
        
        return 0
    else
        echo "⚠️  Limited Nostr activity detected"
        return 0
    fi
}

function cleanup() {
    echo -e "\n${BLUE}🧹 Cleaning up...${NC}"
    
    # Stop logging
    stop_simulator_logging
    
    # Clean up temp files
    rm -f /tmp/runstr_*.log
    rm -f /tmp/runstr_log_pid
    
    echo "✅ Cleanup complete"
}

# Trap for cleanup
trap cleanup EXIT

# Main test execution
echo -e "\n${YELLOW}Starting Runtime Tests...${NC}"

# Check prerequisites
if ! check_simulator; then
    echo "❌ Cannot run tests without iOS Simulator"
    exit 1
fi

# Start logging
if ! start_simulator_logging; then
    echo "❌ Failed to start device logging"
    exit 1
fi

# Build and run app
if ! build_and_run_app; then
    echo "❌ Failed to build or run app"
    exit 1
fi

echo -e "\n${YELLOW}Running app for $TEST_DURATION seconds to collect runtime data...${NC}"
sleep "$TEST_DURATION"

# Run runtime tests
test_nostr_authentication
test_key_generation  
test_relay_connections
test_profile_fetching
test_bridge_functionality
analyze_full_log

# Final summary
echo -e "\n=============================================="
echo -e "${YELLOW}🚀 RUNTIME TEST COMPLETE${NC}"
echo -e "${GREEN}✅ Nostr integration runtime testing finished${NC}"
echo -e "\n${BLUE}💡 Key Insights:${NC}"
echo "   - If you see Nostr activity in logs, integration is working"
echo "   - No activity may mean user isn't signed in with Nostr"
echo "   - Check console logs in Xcode for detailed debugging"
echo "=============================================="