import Foundation
import UserNotifications

// MARK: - Notification Intelligence Data Models

struct NotificationMetrics: Codable {
    let notificationId: String
    let type: String
    let sentAt: Date
    let delivered: Bool
    let opened: Bool
    let actionTaken: Bool
    let engagementScore: Double
    let context: [String: String]?
    
    enum CodingKeys: String, CodingKey {
        case notificationId = "notification_id"
        case type
        case sentAt = "sent_at"
        case delivered
        case opened
        case actionTaken = "action_taken"
        case engagementScore = "engagement_score"
        case context
    }
}

struct UserNotificationProfile: Codable {
    let userId: String
    let averageEngagement: Double
    let notificationFrequency: NotificationFrequency
    let sleepStart: Int // Hour (0-23)
    let sleepEnd: Int // Hour (0-23)
    let timeZone: String
    let preferences: NotificationPreferences
    let lastNotificationSent: Date?
    let dailyNotificationCount: Int
    let weeklyNotificationCount: Int
    let totalNotificationsSent: Int
    let totalEngagements: Int
    let profileUpdated: Date
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case averageEngagement = "average_engagement"
        case notificationFrequency = "notification_frequency"
        case sleepStart = "sleep_start"
        case sleepEnd = "sleep_end"
        case timeZone = "time_zone"
        case preferences
        case lastNotificationSent = "last_notification_sent"
        case dailyNotificationCount = "daily_notification_count"
        case weeklyNotificationCount = "weekly_notification_count"
        case totalNotificationsSent = "total_notifications_sent"
        case totalEngagements = "total_engagements"
        case profileUpdated = "profile_updated"
    }
    
    var engagementRate: Double {
        guard totalNotificationsSent > 0 else { return 0 }
        return Double(totalEngagements) / Double(totalNotificationsSent)
    }
}

enum NotificationFrequency: String, Codable {
    case minimal = "minimal"     // Only critical notifications
    case moderate = "moderate"   // Important notifications
    case active = "active"       // Most notifications
    case maximum = "maximum"     // All notifications
}

struct NotificationPreferences: Codable {
    let workoutRewards: Bool
    let leaderboardChanges: Bool
    let eventReminders: Bool
    let challengeInvites: Bool
    let streakReminders: Bool
    let weeklySummaries: Bool
    let teamActivity: Bool
    let achievements: Bool
    
    enum CodingKeys: String, CodingKey {
        case workoutRewards = "workout_rewards"
        case leaderboardChanges = "leaderboard_changes"
        case eventReminders = "event_reminders"
        case challengeInvites = "challenge_invites"
        case streakReminders = "streak_reminders"
        case weeklySummaries = "weekly_summaries"
        case teamActivity = "team_activity"
        case achievements
    }
}

struct NotificationCandidate {
    let type: String
    let title: String
    let body: String
    let score: Double
    let context: [String: String]
    let urgency: NotificationUrgency
    let category: String
}

enum NotificationUrgency {
    case immediate  // Send right away
    case normal     // Send within normal hours
    case deferred   // Can wait for optimal time
}

// MARK: - Notification Intelligence Service

class NotificationIntelligence {
    static let shared = NotificationIntelligence()
    
    private var userProfiles: [String: UserNotificationProfile] = [:]
    private let notificationService = NotificationService.shared
    
    private let profileCacheKey = "notification_user_profiles"
    private let metricsCacheKey = "notification_metrics"
    
    // Notification limits
    private let maxDailyNotifications = 8
    private let maxHourlyNotifications = 2
    private let minNotificationInterval: TimeInterval = 1800 // 30 minutes
    
    private init() {
        loadUserProfiles()
    }
    
    // MARK: - Profile Management
    
    private func loadUserProfiles() {
        if let data = UserDefaults.standard.data(forKey: profileCacheKey),
           let profiles = try? JSONDecoder().decode([String: UserNotificationProfile].self, from: data) {
            userProfiles = profiles
            print("NotificationIntelligence: Loaded \(profiles.count) user profiles")
        }
    }
    
    private func saveUserProfiles() {
        if let data = try? JSONEncoder().encode(userProfiles) {
            UserDefaults.standard.set(data, forKey: profileCacheKey)
        }
    }
    
    private func getUserProfile(userId: String) -> UserNotificationProfile {
        if let profile = userProfiles[userId] {
            return profile
        }
        
        // Create default profile
        let defaultProfile = UserNotificationProfile(
            userId: userId,
            averageEngagement: 0.5,
            notificationFrequency: .moderate,
            sleepStart: 22, // 10 PM
            sleepEnd: 7,    // 7 AM
            timeZone: TimeZone.current.identifier,
            preferences: NotificationPreferences(
                workoutRewards: true,
                leaderboardChanges: true,
                eventReminders: true,
                challengeInvites: true,
                streakReminders: true,
                weeklySummaries: true,
                teamActivity: false,
                achievements: true
            ),
            lastNotificationSent: nil,
            dailyNotificationCount: 0,
            weeklyNotificationCount: 0,
            totalNotificationsSent: 0,
            totalEngagements: 0,
            profileUpdated: Date()
        )
        
        userProfiles[userId] = defaultProfile
        saveUserProfiles()
        return defaultProfile
    }
    
    // MARK: - Notification Scoring
    
    func evaluateNotification(_ candidate: NotificationCandidate, userId: String) -> (shouldSend: Bool, delay: TimeInterval?) {
        let profile = getUserProfile(userId: userId)
        
        // Check basic eligibility
        guard isNotificationTypeEnabled(candidate.type, profile: profile) else {
            print("NotificationIntelligence: ❌ Notification type '\(candidate.type)' disabled for user")
            return (shouldSend: false, delay: nil)
        }
        
        // Check notification limits
        guard !hasExceededLimits(profile: profile) else {
            print("NotificationIntelligence: ⏰ User has exceeded notification limits")
            return (shouldSend: false, delay: calculateOptimalDelay(profile: profile))
        }
        
        // Check if it's sleep time
        if isInSleepHours(profile: profile) && candidate.urgency != .immediate {
            print("NotificationIntelligence: 😴 User is sleeping, deferring notification")
            return (shouldSend: false, delay: calculateWakeUpDelay(profile: profile))
        }
        
        // Check minimum interval since last notification
        if let lastSent = profile.lastNotificationSent {
            let timeSinceLastNotification = Date().timeIntervalSince(lastSent)
            if timeSinceLastNotification < minNotificationInterval && candidate.urgency != .immediate {
                let remainingInterval = minNotificationInterval - timeSinceLastNotification
                print("NotificationIntelligence: ⏱️ Too soon since last notification, delaying \(Int(remainingInterval))s")
                return (shouldSend: false, delay: remainingInterval)
            }
        }
        
        // Calculate engagement-based score threshold
        let scoreThreshold = calculateScoreThreshold(profile: profile)
        
        // Make final decision
        let shouldSend = candidate.score >= scoreThreshold
        
        if shouldSend {
            print("NotificationIntelligence: ✅ Notification approved (score: \(candidate.score) >= \(scoreThreshold))")
        } else {
            print("NotificationIntelligence: ❌ Notification rejected (score: \(candidate.score) < \(scoreThreshold))")
        }
        
        return (shouldSend: shouldSend, delay: nil)
    }
    
    private func calculateScoreThreshold(profile: UserNotificationProfile) -> Double {
        let baseThreshold: Double
        
        switch profile.notificationFrequency {
        case .minimal:
            baseThreshold = 0.9
        case .moderate:
            baseThreshold = 0.7
        case .active:
            baseThreshold = 0.5
        case .maximum:
            baseThreshold = 0.3
        }
        
        // Adjust based on engagement rate
        let engagementMultiplier = 1.0 - (profile.engagementRate * 0.3) // Higher engagement = lower threshold
        
        // Adjust based on recent notification frequency
        let frequencyMultiplier = min(1.5, 1.0 + (Double(profile.dailyNotificationCount) * 0.1))
        
        return baseThreshold * engagementMultiplier * frequencyMultiplier
    }
    
    private func isNotificationTypeEnabled(_ type: String, profile: UserNotificationProfile) -> Bool {
        switch type {
        case "workout_reward":
            return profile.preferences.workoutRewards
        case "leaderboard_change":
            return profile.preferences.leaderboardChanges
        case "event_reminder":
            return profile.preferences.eventReminders
        case "challenge_invitation":
            return profile.preferences.challengeInvites
        case "streak_reminder":
            return profile.preferences.streakReminders
        case "weekly_summary":
            return profile.preferences.weeklySummaries
        case "team_activity":
            return profile.preferences.teamActivity
        case "achievement":
            return profile.preferences.achievements
        default:
            return true // Allow unknown types by default
        }
    }
    
    private func hasExceededLimits(profile: UserNotificationProfile) -> Bool {
        let calendar = Calendar.current
        let now = Date()
        
        // Check daily limit
        if calendar.isDateInToday(profile.profileUpdated) {
            if profile.dailyNotificationCount >= maxDailyNotifications {
                return true
            }
        }
        
        // Check hourly limit (would need to implement hourly tracking)
        // For now, use the minimum interval check
        
        return false
    }
    
    private func isInSleepHours(profile: UserNotificationProfile) -> Bool {
        let calendar = Calendar.current
        let now = Date()
        let currentHour = calendar.component(.hour, from: now)
        
        if profile.sleepStart <= profile.sleepEnd {
            // Sleep period doesn't cross midnight (e.g., 22:00 - 07:00 next day)
            return currentHour >= profile.sleepStart || currentHour < profile.sleepEnd
        } else {
            // Sleep period crosses midnight (unusual case)
            return currentHour >= profile.sleepStart && currentHour < profile.sleepEnd
        }
    }
    
    private func calculateOptimalDelay(profile: UserNotificationProfile) -> TimeInterval {
        // Delay until next day if daily limit exceeded
        let calendar = Calendar.current
        let now = Date()
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) ?? now
        let tomorrowMorning = calendar.date(bySettingHour: 8, minute: 0, second: 0, of: tomorrow) ?? tomorrow
        
        return tomorrowMorning.timeIntervalSince(now)
    }
    
    private func calculateWakeUpDelay(profile: UserNotificationProfile) -> TimeInterval {
        let calendar = Calendar.current
        let now = Date()
        
        // Calculate next wake-up time
        var wakeUpDate = calendar.date(bySettingHour: profile.sleepEnd, minute: 0, second: 0, of: now) ?? now
        
        // If wake-up time has already passed today, move to tomorrow
        if wakeUpDate <= now {
            wakeUpDate = calendar.date(byAdding: .day, value: 1, to: wakeUpDate) ?? wakeUpDate
        }
        
        return wakeUpDate.timeIntervalSince(now)
    }
    
    // MARK: - Notification Creation
    
    func createWorkoutRewardNotification(amount: Int, workoutType: String, userId: String) -> NotificationCandidate? {
        let score = calculateWorkoutRewardScore(amount: amount, workoutType: workoutType)
        
        return NotificationCandidate(
            type: "workout_reward",
            title: "Workout Reward Earned! 🎉",
            body: "You earned \(amount) sats for your \(workoutType) workout!",
            score: score,
            context: ["amount": "\(amount)", "workout_type": workoutType],
            urgency: .normal,
            category: "WORKOUT_REWARD"
        )
    }
    
    func createLeaderboardChangeNotification(position: Int, previousPosition: Int?, leaderboardName: String, userId: String) -> NotificationCandidate? {
        let score = calculateLeaderboardScore(position: position, previousPosition: previousPosition)
        
        let (title, body) = generateLeaderboardMessage(position: position, previousPosition: previousPosition, leaderboardName: leaderboardName)
        
        return NotificationCandidate(
            type: "leaderboard_change",
            title: title,
            body: body,
            score: score,
            context: ["position": "\(position)", "leaderboard": leaderboardName],
            urgency: position <= 3 ? .normal : .deferred,
            category: "LEADERBOARD_UPDATE"
        )
    }
    
    func createEventReminderNotification(eventName: String, startsIn: TimeInterval, userId: String) -> NotificationCandidate? {
        let score = calculateEventReminderScore(startsIn: startsIn)
        
        let timeString = formatTimeRemaining(startsIn)
        
        return NotificationCandidate(
            type: "event_reminder",
            title: "Event Starting Soon! ⏰",
            body: "\(eventName) starts in \(timeString). Don't miss the prize pool!",
            score: score,
            context: ["event_name": eventName, "starts_in": "\(Int(startsIn))"],
            urgency: startsIn <= 3600 ? .immediate : .normal, // Immediate if < 1 hour
            category: "EVENT_REMINDER"
        )
    }
    
    // MARK: - Scoring Algorithms
    
    private func calculateWorkoutRewardScore(amount: Int, workoutType: String) -> Double {
        var baseScore = 0.6
        
        // Higher rewards get higher scores
        if amount >= 500 {
            baseScore += 0.3
        } else if amount >= 200 {
            baseScore += 0.2
        } else if amount >= 100 {
            baseScore += 0.1
        }
        
        // Certain workout types are more engaging
        switch workoutType.lowercased() {
        case "running", "cycling":
            baseScore += 0.1
        case "hiit", "strength_training":
            baseScore += 0.15
        default:
            break
        }
        
        return min(baseScore, 1.0)
    }
    
    private func calculateLeaderboardScore(position: Int, previousPosition: Int?) -> Double {
        var baseScore = 0.5
        
        // Top positions are always important
        if position <= 3 {
            baseScore = 0.9
        } else if position <= 10 {
            baseScore = 0.7
        } else if position <= 50 {
            baseScore = 0.5
        } else {
            baseScore = 0.3
        }
        
        // Factor in position change
        if let previous = previousPosition {
            let change = previous - position
            if change > 0 { // Moved up
                baseScore += min(Double(change) * 0.05, 0.3)
            } else if change < 0 { // Moved down
                baseScore += min(Double(abs(change)) * 0.02, 0.1)
            }
        } else {
            baseScore += 0.2 // First time on leaderboard
        }
        
        return min(baseScore, 1.0)
    }
    
    private func calculateEventReminderScore(startsIn: TimeInterval) -> Double {
        let hoursUntilEvent = startsIn / 3600
        
        if hoursUntilEvent <= 1 {
            return 0.95 // Very urgent
        } else if hoursUntilEvent <= 4 {
            return 0.8 // Important
        } else if hoursUntilEvent <= 24 {
            return 0.6 // Moderate
        } else {
            return 0.4 // Low priority
        }
    }
    
    // MARK: - Helper Methods
    
    private func generateLeaderboardMessage(position: Int, previousPosition: Int?, leaderboardName: String) -> (title: String, body: String) {
        if let previous = previousPosition {
            let change = previous - position
            if change > 0 {
                let emoji = position <= 3 ? "🏆" : position <= 10 ? "🔥" : "📈"
                return (
                    title: "\(emoji) You moved up \(change) spots!",
                    body: "Now ranked #\(position) on the \(leaderboardName) leaderboard"
                )
            } else if change < 0 {
                return (
                    title: "📉 Leaderboard Update",
                    body: "You're now #\(position) on the \(leaderboardName) leaderboard"
                )
            } else {
                return (
                    title: "🎯 Position Maintained",
                    body: "You're holding steady at #\(position) on \(leaderboardName)"
                )
            }
        } else {
            return (
                title: "🎯 You're on the leaderboard!",
                body: "You're ranked #\(position) on the \(leaderboardName) leaderboard!"
            )
        }
    }
    
    private func formatTimeRemaining(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval / 3600)
        let minutes = Int((timeInterval.truncatingRemainder(dividingBy: 3600)) / 60)
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    // MARK: - Engagement Tracking
    
    func recordNotificationSent(_ candidate: NotificationCandidate, userId: String) {
        guard var profile = userProfiles[userId] else { return }
        
        // Update counters
        profile = UserNotificationProfile(
            userId: profile.userId,
            averageEngagement: profile.averageEngagement,
            notificationFrequency: profile.notificationFrequency,
            sleepStart: profile.sleepStart,
            sleepEnd: profile.sleepEnd,
            timeZone: profile.timeZone,
            preferences: profile.preferences,
            lastNotificationSent: Date(),
            dailyNotificationCount: resetDailyCountIfNeeded(profile) + 1,
            weeklyNotificationCount: profile.weeklyNotificationCount + 1,
            totalNotificationsSent: profile.totalNotificationsSent + 1,
            totalEngagements: profile.totalEngagements,
            profileUpdated: Date()
        )
        
        userProfiles[userId] = profile
        saveUserProfiles()
        
        print("NotificationIntelligence: 📤 Recorded notification sent for user \(userId)")
    }
    
    func recordNotificationEngagement(userId: String, type: String, engaged: Bool) {
        guard var profile = userProfiles[userId] else { return }
        
        if engaged {
            profile = UserNotificationProfile(
                userId: profile.userId,
                averageEngagement: profile.averageEngagement,
                notificationFrequency: profile.notificationFrequency,
                sleepStart: profile.sleepStart,
                sleepEnd: profile.sleepEnd,
                timeZone: profile.timeZone,
                preferences: profile.preferences,
                lastNotificationSent: profile.lastNotificationSent,
                dailyNotificationCount: profile.dailyNotificationCount,
                weeklyNotificationCount: profile.weeklyNotificationCount,
                totalNotificationsSent: profile.totalNotificationsSent,
                totalEngagements: profile.totalEngagements + 1,
                profileUpdated: Date()
            )
            
            userProfiles[userId] = profile
            saveUserProfiles()
            
            print("NotificationIntelligence: 👆 Recorded engagement for user \(userId)")
        }
    }
    
    private func resetDailyCountIfNeeded(_ profile: UserNotificationProfile) -> Int {
        let calendar = Calendar.current
        
        if calendar.isDateInToday(profile.profileUpdated) {
            return profile.dailyNotificationCount
        } else {
            return 0
        }
    }
    
    // MARK: - Public Interface
    
    func shouldSendNotification(_ candidate: NotificationCandidate, userId: String) -> Bool {
        let evaluation = evaluateNotification(candidate, userId: userId)
        
        if evaluation.shouldSend {
            recordNotificationSent(candidate, userId: userId)
            return true
        }
        
        return false
    }
    
    func updateUserPreferences(userId: String, preferences: NotificationPreferences) {
        guard var profile = userProfiles[userId] else {
            _ = getUserProfile(userId: userId) // Create default profile
            return updateUserPreferences(userId: userId, preferences: preferences)
        }
        
        profile = UserNotificationProfile(
            userId: profile.userId,
            averageEngagement: profile.averageEngagement,
            notificationFrequency: profile.notificationFrequency,
            sleepStart: profile.sleepStart,
            sleepEnd: profile.sleepEnd,
            timeZone: profile.timeZone,
            preferences: preferences,
            lastNotificationSent: profile.lastNotificationSent,
            dailyNotificationCount: profile.dailyNotificationCount,
            weeklyNotificationCount: profile.weeklyNotificationCount,
            totalNotificationsSent: profile.totalNotificationsSent,
            totalEngagements: profile.totalEngagements,
            profileUpdated: Date()
        )
        
        userProfiles[userId] = profile
        saveUserProfiles()
    }
    
    func updateSleepSchedule(userId: String, sleepStart: Int, sleepEnd: Int) {
        guard var profile = userProfiles[userId] else {
            _ = getUserProfile(userId: userId)
            return updateSleepSchedule(userId: userId, sleepStart: sleepStart, sleepEnd: sleepEnd)
        }
        
        profile = UserNotificationProfile(
            userId: profile.userId,
            averageEngagement: profile.averageEngagement,
            notificationFrequency: profile.notificationFrequency,
            sleepStart: sleepStart,
            sleepEnd: sleepEnd,
            timeZone: profile.timeZone,
            preferences: profile.preferences,
            lastNotificationSent: profile.lastNotificationSent,
            dailyNotificationCount: profile.dailyNotificationCount,
            weeklyNotificationCount: profile.weeklyNotificationCount,
            totalNotificationsSent: profile.totalNotificationsSent,
            totalEngagements: profile.totalEngagements,
            profileUpdated: Date()
        )
        
        userProfiles[userId] = profile
        saveUserProfiles()
    }
}