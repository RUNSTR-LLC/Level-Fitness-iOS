#!/bin/bash

# Script to update all file paths in project.pbxproj

PROJECT_FILE="RunstrRewards.xcodeproj/project.pbxproj"

# Team files
sed -i '' 's|path = TeamDetail.*\.swift|path = Features/Teams/&|g; s|Features/Teams/path = Features/Teams/|Features/Teams/|g' "$PROJECT_FILE"
sed -i '' 's|path = TeamCreation.*\.swift|path = Features/Teams/&|g; s|Features/Teams/path = Features/Teams/|Features/Teams/|g' "$PROJECT_FILE"
sed -i '' 's|path = TeamBasic.*\.swift|path = Features/Teams/&|g; s|Features/Teams/path = Features/Teams/|Features/Teams/|g' "$PROJECT_FILE"
sed -i '' 's|path = TeamLeaderboard.*\.swift|path = Features/Teams/&|g; s|Features/Teams/path = Features/Teams/|Features/Teams/|g' "$PROJECT_FILE"
sed -i '' 's|path = TeamMetric.*\.swift|path = Features/Teams/&|g; s|Features/Teams/path = Features/Teams/|Features/Teams/|g' "$PROJECT_FILE"
sed -i '' 's|path = TeamReview.*\.swift|path = Features/Teams/&|g; s|Features/Teams/path = Features/Teams/|Features/Teams/|g' "$PROJECT_FILE"
sed -i '' 's|path = TeamMembers.*\.swift|path = Features/Teams/&|g; s|Features/Teams/path = Features/Teams/|Features/Teams/|g' "$PROJECT_FILE"
sed -i '' 's|path = TeamSubscription.*\.swift|path = Features/Teams/&|g; s|Features/Teams/path = Features/Teams/|Features/Teams/|g' "$PROJECT_FILE"
sed -i '' 's|path = TeamWallet.*\.swift|path = Features/Teams/&|g; s|Features/Teams/path = Features/Teams/|Features/Teams/|g' "$PROJECT_FILE"
sed -i '' 's|path = TeamActivity.*\.swift|path = Features/Teams/&|g; s|Features/Teams/path = Features/Teams/|Features/Teams/|g' "$PROJECT_FILE"
sed -i '' 's|path = QRCode.*\.swift|path = Features/Teams/&|g; s|Features/Teams/path = Features/Teams/|Features/Teams/|g' "$PROJECT_FILE"

# Competition files
sed -i '' 's|path = CompetitionsViewController\.swift|path = Features/Competitions/CompetitionsViewController.swift|g' "$PROJECT_FILE"
sed -i '' 's|path = CompetitionTabNavigationView\.swift|path = Features/Competitions/CompetitionTabNavigationView.swift|g' "$PROJECT_FILE"
sed -i '' 's|path = LeaderboardItemView\.swift|path = Features/Competitions/LeaderboardItemView.swift|g' "$PROJECT_FILE"
sed -i '' 's|path = LeagueView\.swift|path = Features/Competitions/LeagueView.swift|g' "$PROJECT_FILE"

# Event files
sed -i '' 's|path = EventsView\.swift|path = Features/Events/EventsView.swift|g' "$PROJECT_FILE"
sed -i '' 's|path = Event.*\.swift|path = Features/Events/&|g; s|Features/Events/path = Features/Events/|Features/Events/|g' "$PROJECT_FILE"
sed -i '' 's|path = Prize.*\.swift|path = Features/Events/&|g; s|Features/Events/path = Features/Events/|Features/Events/|g' "$PROJECT_FILE"
sed -i '' 's|path = Member.*\.swift|path = Features/Events/&|g; s|Features/Events/path = Features/Events/|Features/Events/|g' "$PROJECT_FILE"

# Profile files
sed -i '' 's|path = Profile.*\.swift|path = Features/Profile/&|g; s|Features/Profile/path = Features/Profile/|Features/Profile/|g' "$PROJECT_FILE"
sed -i '' 's|path = EditProfileViewController\.swift|path = Features/Profile/EditProfileViewController.swift|g' "$PROJECT_FILE"
sed -i '' 's|path = NotificationTogglesView\.swift|path = Features/Profile/NotificationTogglesView.swift|g' "$PROJECT_FILE"

# Workout files
sed -i '' 's|path = WorkoutsViewController\.swift|path = Features/Workouts/WorkoutsViewController.swift|g' "$PROJECT_FILE"
sed -i '' 's|path = Workout.*\.swift|path = Features/Workouts/&|g; s|Features/Workouts/path = Features/Workouts/|Features/Workouts/|g' "$PROJECT_FILE"
sed -i '' 's|path = ConnectedAppsViewController\.swift|path = Features/Workouts/ConnectedAppsViewController.swift|g' "$PROJECT_FILE"

# Earnings files
sed -i '' 's|path = EarningsViewController\.swift|path = Features/Earnings/EarningsViewController.swift|g' "$PROJECT_FILE"
sed -i '' 's|path = EarningsHeaderView\.swift|path = Features/Earnings/EarningsHeaderView.swift|g' "$PROJECT_FILE"
sed -i '' 's|path = Wallet.*\.swift|path = Features/Earnings/&|g; s|Features/Earnings/path = Features/Earnings/|Features/Earnings/|g' "$PROJECT_FILE"
sed -i '' 's|path = Transaction.*\.swift|path = Features/Earnings/&|g; s|Features/Earnings/path = Features/Earnings/|Features/Earnings/|g' "$PROJECT_FILE"
sed -i '' 's|path = PaymentSheetViewController\.swift|path = Features/Earnings/PaymentSheetViewController.swift|g' "$PROJECT_FILE"
sed -i '' 's|path = LotteryComingSoonViewController\.swift|path = Features/Earnings/LotteryComingSoonViewController.swift|g' "$PROJECT_FILE"

# Settings files
sed -i '' 's|path = SettingsViewController\.swift|path = Features/Settings/SettingsViewController.swift|g' "$PROJECT_FILE"

echo "Path updates completed!"