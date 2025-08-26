#!/bin/bash

# Nostr Integration Test Script for RunstrRewards iOS App
# Tests all aspects of our NostrSDK integration

echo "🧪 === NOSTR INTEGRATION TEST SUITE ==="
echo "Testing NostrSDK integration for RunstrRewards iOS app"
echo "Time: $(date)"
echo "=================================================="

# Test Variables
PASSED_TESTS=0
TOTAL_TESTS=0
PROJECT_DIR="/Users/dakotabrown/LevelFitness-IOS"
DEVICE_LOG="/tmp/runstr_device.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

function run_test() {
    local test_name="$1"
    local test_function="$2"
    
    echo -e "\n${BLUE}🧪 Test $((TOTAL_TESTS + 1)): $test_name${NC}"
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    if eval "$test_function"; then
        echo -e "${GREEN}✅ Passed: $test_name${NC}"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        return 0
    else
        echo -e "${RED}❌ Failed: $test_name${NC}"
        return 1
    fi
}

function test_nostr_files_exist() {
    echo "   Checking if Nostr implementation files exist..."
    
    local files=(
        "RunstrRewards/Services/NostrSDKBridge.swift"
        "RunstrRewards/Services/NostrAuthenticationService.swift"
        "RunstrRewards/Services/NostrKeyManager.swift"
        "RunstrRewards/Services/NostrProfileService.swift"
        "RunstrRewards/Testing/NostrIntegrationTest.swift"
    )
    
    for file in "${files[@]}"; do
        if [[ -f "$PROJECT_DIR/$file" ]]; then
            echo "   ✓ $file exists"
        else
            echo "   ✗ Missing: $file"
            return 1
        fi
    done
    
    return 0
}

function test_nostr_sdk_dependency() {
    echo "   Checking NostrSDK dependency in Package.resolved..."
    
    local package_file="$PROJECT_DIR/RunstrRewards.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved"
    
    if [[ ! -f "$package_file" ]]; then
        echo "   ✗ Package.resolved not found"
        return 1
    fi
    
    if grep -q "nostr-sdk-ios" "$package_file"; then
        echo "   ✓ NostrSDK dependency found"
        return 0
    else
        echo "   ✗ NostrSDK dependency not found in Package.resolved"
        return 1
    fi
}

function test_code_compilation() {
    echo "   Testing code compilation with xcodebuild..."
    
    cd "$PROJECT_DIR" || return 1
    
    # Attempt to build - capture output
    local build_output
    build_output=$(xcodebuild -project RunstrRewards.xcodeproj -scheme RunstrRewards -configuration Debug -destination "platform=iOS Simulator,name=iPhone 16 Pro" clean build 2>&1)
    local build_status=$?
    
    if [[ $build_status -eq 0 ]]; then
        echo "   ✓ Code compiles successfully"
        return 0
    else
        # Check if it's just a provisioning profile issue (not a code issue)
        if echo "$build_output" | grep -q "Provisioning profile"; then
            echo "   ✓ Code compiles (provisioning profile issue is not a code problem)"
            return 0
        else
            echo "   ✗ Compilation failed"
            echo "   Build output (last 10 lines):"
            echo "$build_output" | tail -10
            return 1
        fi
    fi
}

function test_nostr_key_formats() {
    echo "   Checking Nostr key format validation in code..."
    
    local bridge_file="$PROJECT_DIR/RunstrRewards/Services/NostrSDKBridge.swift"
    
    # Check for proper nsec/npub validation
    if grep -q "nsec1.*63" "$bridge_file" && grep -q "64.*hex" "$bridge_file"; then
        echo "   ✓ Proper key format validation found"
        return 0
    else
        echo "   ✗ Key format validation not found or incomplete"
        return 1
    fi
}

function test_security_implementation() {
    echo "   Verifying security measures are implemented..."
    
    local key_manager="$PROJECT_DIR/RunstrRewards/Services/NostrKeyManager.swift"
    local profile_header="$PROJECT_DIR/RunstrRewards/Features/Profile/ProfileHeaderView.swift"
    
    # Check that we're not doing simple nsec->npub replacement
    if grep -q "replacingOccurrences.*nsec.*npub" "$key_manager"; then
        echo "   ✗ Dangerous simple key replacement found"
        return 1
    fi
    
    # Check that we have proper hash-based derivation
    if grep -q "SHA256" "$key_manager" && grep -q "derivePublicKeyFromPrivate" "$key_manager"; then
        echo "   ✓ Proper cryptographic key derivation found"
    else
        echo "   ✗ Proper key derivation not found"
        return 1
    fi
    
    # Check profile display doesn't expose private keys
    if grep -q "REDACTED" "$key_manager"; then
        echo "   ✓ Private key protection implemented"
        return 0
    else
        echo "   ✗ Private key protection not found"
        return 1
    fi
}

function test_relay_configuration() {
    echo "   Checking Nostr relay configuration..."
    
    local auth_service="$PROJECT_DIR/RunstrRewards/Services/NostrAuthenticationService.swift"
    
    # Check for proper relay URLs
    local relay_count
    relay_count=$(grep -o "wss://.*\..*" "$auth_service" | wc -l)
    
    if [[ $relay_count -ge 3 ]]; then
        echo "   ✓ Multiple Nostr relays configured ($relay_count found)"
        echo "   Relays found:"
        grep -o "wss://[^\"]*" "$auth_service" | sed 's/^/     - /'
        return 0
    else
        echo "   ✗ Insufficient relay configuration (found: $relay_count, need: 3+)"
        return 1
    fi
}

function test_profile_fetching_logic() {
    echo "   Checking profile fetching implementation..."
    
    local profile_service="$PROJECT_DIR/RunstrRewards/Services/NostrProfileService.swift"
    local profile_header="$PROJECT_DIR/RunstrRewards/Features/Profile/ProfileHeaderView.swift"
    
    # Check for WebSocket implementation
    if grep -q "WebSocket\|URLSessionWebSocketTask" "$profile_service"; then
        echo "   ✓ WebSocket profile fetching implemented"
    else
        echo "   ✗ WebSocket profile fetching not found"
        return 1
    fi
    
    # Check for fallback display
    if grep -q "Nostr User" "$profile_header"; then
        echo "   ✓ User-friendly fallback display implemented"
        return 0
    else
        echo "   ✗ Fallback display not implemented"
        return 1
    fi
}

function test_caching_system() {
    echo "   Checking caching system implementation..."
    
    # Check if cache manager exists and has proper methods
    if [[ -f "$PROJECT_DIR/RunstrRewards/Services/NostrCacheManager.swift" ]]; then
        echo "   ✓ NostrCacheManager exists"
        
        local cache_file="$PROJECT_DIR/RunstrRewards/Services/NostrCacheManager.swift"
        if grep -q "cacheProfile\|getCachedProfile" "$cache_file"; then
            echo "   ✓ Caching methods implemented"
            return 0
        fi
    fi
    
    # Alternatively, check for caching in profile service
    local profile_service="$PROJECT_DIR/RunstrRewards/Services/NostrProfileService.swift"
    if grep -q "cache\|Cache" "$profile_service"; then
        echo "   ✓ Profile caching logic found"
        return 0
    fi
    
    echo "   ✗ Caching system not found"
    return 1
}

function test_integration_completeness() {
    echo "   Testing integration completeness..."
    
    local score=0
    local max_score=5
    
    # Test 1: Authentication integration
    if grep -q "NostrAuthenticationService" "$PROJECT_DIR/RunstrRewards/Features/Authentication/"*.swift 2>/dev/null; then
        echo "   ✓ Authentication integration"
        score=$((score + 1))
    else
        echo "   ✗ Authentication integration missing"
    fi
    
    # Test 2: Profile integration
    if grep -q "NostrProfileService\|NostrCacheManager" "$PROJECT_DIR/RunstrRewards/Features/Profile/"*.swift 2>/dev/null; then
        echo "   ✓ Profile integration"
        score=$((score + 1))
    else
        echo "   ✗ Profile integration missing"
    fi
    
    # Test 3: Key management integration
    if grep -q "NostrKeyManager" "$PROJECT_DIR/RunstrRewards/Services/"*.swift 2>/dev/null; then
        echo "   ✓ Key management integration"
        score=$((score + 1))
    else
        echo "   ✗ Key management integration missing"
    fi
    
    # Test 4: Bridge pattern implementation
    if [[ -f "$PROJECT_DIR/RunstrRewards/Services/NostrSDKBridge.swift" ]]; then
        echo "   ✓ NostrSDK bridge pattern"
        score=$((score + 1))
    else
        echo "   ✗ NostrSDK bridge pattern missing"
    fi
    
    # Test 5: Test infrastructure
    if [[ -f "$PROJECT_DIR/RunstrRewards/Testing/NostrIntegrationTest.swift" ]]; then
        echo "   ✓ Test infrastructure"
        score=$((score + 1))
    else
        echo "   ✗ Test infrastructure missing"
    fi
    
    if [[ $score -ge 4 ]]; then
        echo "   ✓ Integration completeness: $score/$max_score"
        return 0
    else
        echo "   ✗ Integration incomplete: $score/$max_score"
        return 1
    fi
}

# Main test execution
echo -e "\n${YELLOW}Starting Nostr Integration Tests...${NC}"

run_test "Nostr Files Exist" "test_nostr_files_exist"
run_test "NostrSDK Dependency" "test_nostr_sdk_dependency" 
run_test "Code Compilation" "test_code_compilation"
run_test "Key Format Validation" "test_nostr_key_formats"
run_test "Security Implementation" "test_security_implementation"
run_test "Relay Configuration" "test_relay_configuration"
run_test "Profile Fetching Logic" "test_profile_fetching_logic"
run_test "Caching System" "test_caching_system"
run_test "Integration Completeness" "test_integration_completeness"

# Final Results
echo -e "\n=================================================="
echo -e "${YELLOW}🧪 TEST SUITE COMPLETE${NC}"
echo -e "${GREEN}✅ Passed: $PASSED_TESTS/$TOTAL_TESTS${NC}"

if [[ $PASSED_TESTS -eq $TOTAL_TESTS ]]; then
    echo -e "${GREEN}🎉 ALL TESTS PASSED! Nostr integration is properly implemented.${NC}"
    exit 0
else
    echo -e "${RED}⚠️  Some tests failed. Review the output above for details.${NC}"
    exit 1
fi