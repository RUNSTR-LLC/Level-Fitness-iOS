#!/bin/bash

# ========================================
# EXIT FEE MIGRATION VALIDATION SCRIPT
# ========================================
# This script validates the exit fee system migration files
# for basic SQL syntax and structure before deployment

set -e

echo "🔍 VALIDATING EXIT FEE SYSTEM MIGRATION"
echo "========================================"

# Define file paths
MIGRATION_FILE="../migrations/001_exit_fee_system.sql"
TEST_FILE="../tests/database/ExitFeeSystemMigrationTests.sql"

# Check if files exist
if [ ! -f "$MIGRATION_FILE" ]; then
    echo "❌ Migration file not found: $MIGRATION_FILE"
    exit 1
fi

if [ ! -f "$TEST_FILE" ]; then
    echo "❌ Test file not found: $TEST_FILE"
    exit 1
fi

echo "✅ Migration files found"

# Basic syntax validation using PostgreSQL if available
if command -v psql &> /dev/null; then
    echo "🔍 Checking SQL syntax with PostgreSQL..."
    
    # Create temporary database for validation
    export PGPASSWORD="${POSTGRES_PASSWORD:-password}"
    DB_NAME="exit_fee_validation_$(date +%s)"
    
    # Note: This would require a running PostgreSQL instance
    # For now, we'll do basic text validation
    echo "ℹ️  PostgreSQL validation requires running database instance"
else
    echo "ℹ️  PostgreSQL not available, skipping syntax validation"
fi

# Basic text validation
echo "🔍 Performing basic validation..."

# Check migration file structure
echo "Validating migration file structure..."

# Check for required sections
required_sections=(
    "ALTER TABLE team_members"
    "CREATE TABLE.*exit_fee_payments"
    "CREATE TABLE.*team_switch_operations"
    "CREATE UNIQUE INDEX.*unique_active_team_membership"
    "CREATE POLICY"
    "CREATE OR REPLACE FUNCTION"
)

missing_sections=0
for section in "${required_sections[@]}"; do
    if ! grep -q "$section" "$MIGRATION_FILE"; then
        echo "❌ Missing required section: $section"
        missing_sections=$((missing_sections + 1))
    else
        echo "✅ Found: $section"
    fi
done

if [ $missing_sections -gt 0 ]; then
    echo "❌ Migration file is missing $missing_sections required sections"
    exit 1
fi

# Check for proper SQL statement termination
unterminated_lines=$(grep -n "[^;]$" "$MIGRATION_FILE" | grep -v "^\s*--" | grep -v "^\s*$" | wc -l)
if [ $unterminated_lines -gt 5 ]; then  # Allow some flexibility
    echo "⚠️  Warning: $unterminated_lines lines may be missing semicolons"
fi

# Check test file structure
echo "Validating test file structure..."

required_test_sections=(
    "CREATE OR REPLACE FUNCTION run_exit_fee_migration_tests"
    "Table Creation"
    "Single Team Constraint"
    "Exit Fee Payment Creation"
    "RETURN QUERY SELECT"
)

missing_test_sections=0
for section in "${required_test_sections[@]}"; do
    if ! grep -q "$section" "$TEST_FILE"; then
        echo "❌ Missing required test section: $section"
        missing_test_sections=$((missing_test_sections + 1))
    else
        echo "✅ Found: $section"
    fi
done

if [ $missing_test_sections -gt 0 ]; then
    echo "❌ Test file is missing $missing_test_sections required sections"
    exit 1
fi

# Validate hardcoded constants
echo "🔍 Validating hardcoded constants..."

# Check for exit fee amount (should be 2000)
if grep -q "2000" "$MIGRATION_FILE"; then
    echo "✅ Exit fee amount (2000 sats) found"
else
    echo "❌ Exit fee amount (2000 sats) not found"
    exit 1
fi

# Check for RUNSTR Lightning address
if grep -q "RUNSTR@coinos.io" "$MIGRATION_FILE"; then
    echo "✅ RUNSTR Lightning address found"
else
    echo "❌ RUNSTR Lightning address not found"
    exit 1
fi

# Check for potential SQL injection vulnerabilities
echo "🔍 Checking for potential security issues..."

# Look for dynamic SQL without proper escaping
if grep -q "EXECUTE.*||" "$MIGRATION_FILE" || grep -q "format.*%" "$MIGRATION_FILE"; then
    echo "⚠️  Warning: Dynamic SQL found, ensure proper escaping"
fi

# Check for proper constraint naming
constraint_count=$(grep -c "CONSTRAINT.*_check CHECK" "$MIGRATION_FILE")
if [ $constraint_count -ge 3 ]; then
    echo "✅ Found $constraint_count check constraints"
else
    echo "⚠️  Warning: Expected at least 3 check constraints, found $constraint_count"
fi

# Validate index naming convention
index_count=$(grep -c "CREATE.*INDEX.*idx_" "$MIGRATION_FILE")
if [ $index_count -ge 8 ]; then
    echo "✅ Found $index_count indexes with proper naming"
else
    echo "⚠️  Warning: Expected at least 8 indexes, found $index_count"
fi

# Check for proper RLS policies
rls_count=$(grep -c "CREATE POLICY" "$MIGRATION_FILE")
if [ $rls_count -ge 4 ]; then
    echo "✅ Found $rls_count RLS policies"
else
    echo "⚠️  Warning: Expected at least 4 RLS policies, found $rls_count"
fi

# Validate file sizes (ensure they're not empty or too small)
migration_size=$(wc -l < "$MIGRATION_FILE")
test_size=$(wc -l < "$TEST_FILE")

if [ $migration_size -lt 100 ]; then
    echo "❌ Migration file too small ($migration_size lines), expected at least 100"
    exit 1
else
    echo "✅ Migration file size: $migration_size lines"
fi

if [ $test_size -lt 50 ]; then
    echo "❌ Test file too small ($test_size lines), expected at least 50"
    exit 1
else
    echo "✅ Test file size: $test_size lines"
fi

# Summary
echo ""
echo "========================================"
echo "✅ VALIDATION COMPLETED SUCCESSFULLY"
echo "========================================"
echo "Migration file: $migration_size lines, passed all checks"
echo "Test file: $test_size lines, passed all checks"
echo ""
echo "Next steps:"
echo "1. Review migration file manually"
echo "2. Apply to staging database: psql -f $MIGRATION_FILE"
echo "3. Run tests: psql -f $TEST_FILE"
echo "4. Verify results before production deployment"
echo ""

# Create deployment checklist
cat > ../deployment_checklist.md << EOF
# Exit Fee System Migration Deployment Checklist

## Pre-deployment
- [ ] Migration file validated locally
- [ ] Test file validated locally  
- [ ] Staging database backup created
- [ ] Migration applied to staging
- [ ] Tests run successfully on staging
- [ ] Performance impact assessed

## Constants Verified
- [ ] Exit fee amount: 2000 sats
- [ ] Lightning address: RUNSTR@coinos.io
- [ ] Constraint: unique_active_team_membership

## Deployment
- [ ] Production database backup created
- [ ] Migration applied to production
- [ ] Tests run on production
- [ ] Rollback plan ready if needed

## Post-deployment
- [ ] Analytics views working
- [ ] RLS policies active
- [ ] Performance indexes effective
- [ ] No constraint violations
- [ ] ExitFeeManager service can connect

Generated: $(date)
EOF

echo "📋 Deployment checklist created: ../deployment_checklist.md"