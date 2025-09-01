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

Generated: Sat Aug 30 22:32:26 EDT 2025
