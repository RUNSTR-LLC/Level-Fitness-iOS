import Foundation

// MARK: - Integration Models

struct CompetitionFlow {
    let flowId: String
    let eventId: String
    let teamId: String
    let userId: String
    let stage: CompetitionStage
    let autoEntryEnabled: Bool
    let prizeDistributionEnabled: Bool
    let startDate: Date
    let lastUpdateDate: Date
    let metadata: [String: Any]
}

enum CompetitionStage {
    case qualification       // User working towards qualification
    case qualified          // User has qualified but not yet entered
    case autoEntered        // User has been automatically entered
    case competing          // Event is active, user is competing
    case eventCompleted     // Event finished, awaiting distribution
    case prizeCalculated    // Prize amounts calculated
    case prizeDistributed   // User has received their share
    case completed          // Full flow completed
}

struct IntegrationEvent {
    let eventId: String
    let userId: String
    let teamId: String?
    let type: IntegrationEventType
    let timestamp: Date
    let data: [String: Any]
    let processed: Bool
}

enum IntegrationEventType {
    case workoutCompleted
    case qualificationAchieved
    case autoEntryTriggered
    case eventStarted
    case eventCompleted
    case prizeCalculated
    case prizeDistributed
    case teamWalletUpdated
}

// MARK: - CompetitionIntegrationService

class CompetitionIntegrationService {
    static let shared = CompetitionIntegrationService()
    
    // Service dependencies
    private let autoEntryService = AutoEntryService.shared
    private let progressTracker = EventProgressTracker.shared
    private let distributionService = TeamPrizeDistributionService.shared
    private let notificationService = EventNotificationService.shared
    private let realtimeService = RealtimeLeaderboardService.shared
    
    // Integration state
    private var activeFlows: [String: CompetitionFlow] = [:]
    private var eventQueue: [IntegrationEvent] = []
    private var processingTimer: Timer?
    
    private init() {
        setupIntegration()
        startEventProcessing()
    }
    
    // MARK: - Setup
    
    private func setupIntegration() {
        setupNotificationObservers()
        loadActiveFlows()
        print("🔗 Integration: Competition integration service initialized")
    }
    
    private func setupNotificationObservers() {
        let notificationCenter = NotificationCenter.default
        
        // Listen to workout sync events
        notificationCenter.addObserver(
            self,
            selector: #selector(handleWorkoutCompleted),
            name: NSNotification.Name("WorkoutAdded"),
            object: nil
        )
        
        // Listen to auto-entry qualification
        notificationCenter.addObserver(
            self,
            selector: #selector(handleUserQualified),
            name: NSNotification.Name("UserQualifiedForEvent"),
            object: nil
        )
        
        // Listen to event progress updates
        notificationCenter.addObserver(
            self,
            selector: #selector(handleProgressUpdate),
            name: NSNotification.Name("EventProgressUpdated"),
            object: nil
        )
        
        // Listen to prize distribution events
        notificationCenter.addObserver(
            self,
            selector: #selector(handlePrizeDistributed),
            name: NSNotification.Name("PrizeDistributed"),
            object: nil
        )
        
        // Listen to real-time leaderboard updates
        notificationCenter.addObserver(
            self,
            selector: #selector(handleLeaderboardUpdate),
            name: NSNotification.Name("RealtimeLeaderboardUpdate"),
            object: nil
        )
    }
    
    private func startEventProcessing() {
        // Process integration events every 5 seconds
        processingTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.processEventQueue()
        }
    }
    
    // MARK: - Flow Management
    
    func startCompetitionFlow(eventId: String, teamId: String, userId: String, autoEntry: Bool = true) -> CompetitionFlow {
        let flowId = UUID().uuidString
        
        let flow = CompetitionFlow(
            flowId: flowId,
            eventId: eventId,
            teamId: teamId,
            userId: userId,
            stage: .qualification,
            autoEntryEnabled: autoEntry,
            prizeDistributionEnabled: true,
            startDate: Date(),
            lastUpdateDate: Date(),
            metadata: [:]
        )
        
        activeFlows[flowId] = flow
        
        // Register event with auto-entry service
        if autoEntry {
            registerEventForAutoEntry(eventId: eventId, userId: userId)
        }
        
        // Start progress tracking
        startProgressTracking(eventId: eventId, userId: userId)
        
        print("🔗 Integration: Started competition flow \(flowId) for event \(eventId)")
        
        return flow
    }
    
    func updateFlowStage(flowId: String, newStage: CompetitionStage) {
        guard var flow = activeFlows[flowId] else {
            print("🔗 Integration: Flow \(flowId) not found for stage update")
            return
        }
        
        let previousStage = flow.stage
        
        flow = CompetitionFlow(
            flowId: flow.flowId,
            eventId: flow.eventId,
            teamId: flow.teamId,
            userId: flow.userId,
            stage: newStage,
            autoEntryEnabled: flow.autoEntryEnabled,
            prizeDistributionEnabled: flow.prizeDistributionEnabled,
            startDate: flow.startDate,
            lastUpdateDate: Date(),
            metadata: flow.metadata
        )
        
        activeFlows[flowId] = flow
        
        // Handle stage transitions
        handleStageTransition(flow: flow, previousStage: previousStage, newStage: newStage)
        
        print("🔗 Integration: Updated flow \(flowId) stage: \(previousStage) → \(newStage)")
    }
    
    private func handleStageTransition(flow: CompetitionFlow, previousStage: CompetitionStage, newStage: CompetitionStage) {
        switch (previousStage, newStage) {
        case (.qualification, .qualified):
            // User has qualified, prepare for auto-entry
            scheduleAutoEntry(flow: flow)
            
        case (.qualified, .autoEntered):
            // User has been auto-entered, start competition tracking
            startCompetitionTracking(flow: flow)
            
        case (.competing, .eventCompleted):
            // Event finished, calculate prizes
            schedulePrizeCalculation(flow: flow)
            
        case (.prizeCalculated, .prizeDistributed):
            // Prize distributed, finalize flow
            finalizeFlow(flow: flow)
            
        default:
            break
        }
    }
    
    // MARK: - Event Handlers
    
    @objc private func handleWorkoutCompleted(_ notification: Notification) {
        guard let workout = notification.userInfo?["workout"] as? HealthKitWorkout,
              let userId = notification.userInfo?["userId"] as? String else {
            return
        }
        
        // Find active flows for this user
        let userFlows = activeFlows.values.filter { $0.userId == userId }
        
        for flow in userFlows {
            queueIntegrationEvent(
                eventId: flow.eventId,
                userId: userId,
                teamId: flow.teamId,
                type: .workoutCompleted,
                data: [
                    "workoutId": workout.id,
                    "distance": workout.totalDistance,
                    "duration": workout.duration,
                    "calories": workout.totalEnergyBurned
                ]
            )
        }
        
        print("🔗 Integration: Queued workout completion for \(userFlows.count) active flows")
    }
    
    @objc private func handleUserQualified(_ notification: Notification) {
        guard let eventId = notification.userInfo?["eventId"] as? String,
              let userId = notification.userInfo?["userId"] as? String else {
            return
        }
        
        // Find the flow for this event and user
        if let flow = activeFlows.values.first(where: { $0.eventId == eventId && $0.userId == userId }) {
            updateFlowStage(flowId: flow.flowId, newStage: .qualified)
            
            queueIntegrationEvent(
                eventId: eventId,
                userId: userId,
                teamId: flow.teamId,
                type: .qualificationAchieved,
                data: [:]
            )
        }
    }
    
    @objc private func handleProgressUpdate(_ notification: Notification) {
        guard let eventId = notification.userInfo?["eventId"] as? String,
              let userId = notification.userInfo?["userId"] as? String,
              let updateType = notification.userInfo?["updateType"] as? ProgressUpdateType else {
            return
        }
        
        // Handle significant progress updates
        if case .goalAchieved = updateType {
            if let flow = activeFlows.values.first(where: { $0.eventId == eventId && $0.userId == userId }) {
                queueIntegrationEvent(
                    eventId: eventId,
                    userId: userId,
                    teamId: flow.teamId,
                    type: .eventCompleted,
                    data: ["reason": "Goal achieved"]
                )
            }
        }
    }
    
    @objc private func handlePrizeDistributed(_ notification: Notification) {
        guard let distributionId = notification.userInfo?["distributionId"] as? String,
              let distribution = distributionService.getDistribution(distributionId: distributionId) else {
            return
        }
        
        // Update flows for all recipients
        for recipient in distribution.recipients {
            if let flow = activeFlows.values.first(where: { 
                $0.eventId == distribution.eventId && $0.userId == recipient.userId 
            }) {
                updateFlowStage(flowId: flow.flowId, newStage: .prizeDistributed)
                
                queueIntegrationEvent(
                    eventId: distribution.eventId,
                    userId: recipient.userId,
                    teamId: distribution.teamId,
                    type: .prizeDistributed,
                    data: [
                        "amount": recipient.allocation,
                        "distributionId": distributionId
                    ]
                )
            }
        }
    }
    
    @objc private func handleLeaderboardUpdate(_ notification: Notification) {
        guard let update = notification.userInfo?["update"] as? LiveLeaderboardUpdate else {
            return
        }
        
        // Handle event completion from leaderboard
        if case .eventComplete = update.updateType {
            let flows = activeFlows.values.filter { $0.eventId == update.eventId }
            
            for flow in flows {
                updateFlowStage(flowId: flow.flowId, newStage: .eventCompleted)
            }
        }
    }
    
    // MARK: - Service Integration
    
    private func registerEventForAutoEntry(eventId: String, userId: String) {
        // In a real implementation, this would set up qualification criteria
        // and register the event with the auto-entry service
        print("🔗 Integration: Registered event \(eventId) for auto-entry for user \(userId)")
    }
    
    private func startProgressTracking(eventId: String, userId: String) {
        // Start tracking user progress in this event
        print("🔗 Integration: Started progress tracking for user \(userId) in event \(eventId)")
    }
    
    private func scheduleAutoEntry(flow: CompetitionFlow) {
        if flow.autoEntryEnabled {
            // Simulate auto-entry process
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.updateFlowStage(flowId: flow.flowId, newStage: .autoEntered)
                
                // Send auto-entry notification
                self.notificationService.createEventStartedNotification(
                    eventId: flow.eventId,
                    eventName: "Event \(flow.eventId)"
                )
            }
        }
    }
    
    private func startCompetitionTracking(flow: CompetitionFlow) {
        // Start real-time leaderboard tracking
        realtimeService.startRealtimeUpdates(for: flow.eventId, eventType: .challenge)
        
        // Update flow to competing stage
        updateFlowStage(flowId: flow.flowId, newStage: .competing)
        
        print("🔗 Integration: Started competition tracking for flow \(flow.flowId)")
    }
    
    private func schedulePrizeCalculation(flow: CompetitionFlow) {
        if flow.prizeDistributionEnabled {
            // Simulate prize calculation delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                self.calculateAndDistributePrizes(flow: flow)
            }
        }
    }
    
    private func calculateAndDistributePrizes(flow: CompetitionFlow) {
        // Create a prize distribution
        let result = distributionService.createDistribution(
            eventId: flow.eventId,
            teamId: flow.teamId,
            method: .performance,
            totalPrize: 25000, // 25k sats
            captainUserId: "team_captain",
            notes: "Automated distribution for \(flow.eventId)"
        )
        
        switch result {
        case .success(let distribution):
            updateFlowStage(flowId: flow.flowId, newStage: .prizeCalculated)
            
            // Execute the distribution
            let executionResult = distributionService.executeDistribution(distributionId: distribution.distributionId)
            
            switch executionResult {
            case .success:
                print("🔗 Integration: Prize distribution executed successfully for flow \(flow.flowId)")
                
            case .failure(let error):
                print("🔗 Integration: Prize distribution failed for flow \(flow.flowId): \(error)")
            }
            
        case .failure(let error):
            print("🔗 Integration: Prize calculation failed for flow \(flow.flowId): \(error)")
        }
    }
    
    private func finalizeFlow(flow: CompetitionFlow) {
        updateFlowStage(flowId: flow.flowId, newStage: .completed)
        
        // Clean up resources
        realtimeService.stopRealtimeUpdates(for: flow.eventId)
        
        // Archive the flow
        archiveFlow(flow: flow)
        
        print("🔗 Integration: Finalized flow \(flow.flowId)")
    }
    
    // MARK: - Event Queue Processing
    
    private func queueIntegrationEvent(eventId: String, userId: String, teamId: String?, type: IntegrationEventType, data: [String: Any]) {
        let event = IntegrationEvent(
            eventId: eventId,
            userId: userId,
            teamId: teamId,
            type: type,
            timestamp: Date(),
            data: data,
            processed: false
        )
        
        eventQueue.append(event)
    }
    
    private func processEventQueue() {
        let unprocessedEvents = eventQueue.filter { !$0.processed }
        
        if unprocessedEvents.isEmpty {
            return
        }
        
        print("🔗 Integration: Processing \(unprocessedEvents.count) events")
        
        for event in unprocessedEvents {
            processIntegrationEvent(event)
        }
        
        // Remove processed events older than 1 hour
        let oneHourAgo = Date().addingTimeInterval(-3600)
        eventQueue = eventQueue.filter { !$0.processed || $0.timestamp > oneHourAgo }
    }
    
    private func processIntegrationEvent(_ event: IntegrationEvent) {
        switch event.type {
        case .workoutCompleted:
            processWorkoutCompletion(event)
        case .qualificationAchieved:
            processQualificationAchieved(event)
        case .autoEntryTriggered:
            processAutoEntry(event)
        case .eventStarted:
            processEventStarted(event)
        case .eventCompleted:
            processEventCompleted(event)
        case .prizeCalculated:
            processPrizeCalculated(event)
        case .prizeDistributed:
            processPrizeDistributed(event)
        case .teamWalletUpdated:
            processTeamWalletUpdated(event)
        }
        
        // Mark as processed
        if let index = eventQueue.firstIndex(where: { $0.eventId == event.eventId && $0.timestamp == event.timestamp }) {
            var updatedEvent = event
            eventQueue[index] = IntegrationEvent(
                eventId: updatedEvent.eventId,
                userId: updatedEvent.userId,
                teamId: updatedEvent.teamId,
                type: updatedEvent.type,
                timestamp: updatedEvent.timestamp,
                data: updatedEvent.data,
                processed: true
            )
        }
    }
    
    // MARK: - Event Processing Methods
    
    private func processWorkoutCompletion(_ event: IntegrationEvent) {
        // Check if this workout qualifies user for any events
        let userFlows = activeFlows.values.filter { 
            $0.userId == event.userId && $0.stage == .qualification 
        }
        
        for flow in userFlows {
            // Check qualification status
            // This would integrate with the AutoEntryService qualification checking
            print("🔗 Integration: Checking qualification for workout in flow \(flow.flowId)")
        }
    }
    
    private func processQualificationAchieved(_ event: IntegrationEvent) {
        // User has qualified - trigger auto-entry if enabled
        if let flow = activeFlows.values.first(where: { 
            $0.eventId == event.eventId && $0.userId == event.userId 
        }), flow.autoEntryEnabled {
            
            queueIntegrationEvent(
                eventId: event.eventId,
                userId: event.userId,
                teamId: event.teamId,
                type: .autoEntryTriggered,
                data: [:]
            )
        }
    }
    
    private func processAutoEntry(_ event: IntegrationEvent) {
        // Execute auto-entry
        print("🔗 Integration: Processing auto-entry for user \(event.userId) in event \(event.eventId)")
    }
    
    private func processEventStarted(_ event: IntegrationEvent) {
        // Event has started, update all relevant flows
        let eventFlows = activeFlows.values.filter { $0.eventId == event.eventId }
        
        for flow in eventFlows {
            if flow.stage == .autoEntered {
                updateFlowStage(flowId: flow.flowId, newStage: .competing)
            }
        }
    }
    
    private func processEventCompleted(_ event: IntegrationEvent) {
        // Event completed, prepare for prize calculation
        print("🔗 Integration: Processing event completion for \(event.eventId)")
    }
    
    private func processPrizeCalculated(_ event: IntegrationEvent) {
        // Prize calculated, ready for distribution
        print("🔗 Integration: Prize calculated for event \(event.eventId)")
    }
    
    private func processPrizeDistributed(_ event: IntegrationEvent) {
        // Prize distributed, update user's payout history
        print("🔗 Integration: Prize distributed to user \(event.userId) for event \(event.eventId)")
    }
    
    private func processTeamWalletUpdated(_ event: IntegrationEvent) {
        // Team wallet updated, may affect prize distributions
        print("🔗 Integration: Team wallet updated for team \(event.teamId ?? "unknown")")
    }
    
    // MARK: - Flow Management
    
    private func loadActiveFlows() {
        // In a real implementation, this would load from persistent storage
        print("🔗 Integration: Loaded active flows from storage")
    }
    
    private func archiveFlow(flow: CompetitionFlow) {
        // Archive completed flow
        activeFlows.removeValue(forKey: flow.flowId)
        
        // In a real implementation, this would save to persistent storage
        print("🔗 Integration: Archived flow \(flow.flowId)")
    }
    
    // MARK: - Data Access
    
    func getActiveFlows(for userId: String) -> [CompetitionFlow] {
        return activeFlows.values.filter { $0.userId == userId }
    }
    
    func getFlowsForEvent(_ eventId: String) -> [CompetitionFlow] {
        return activeFlows.values.filter { $0.eventId == eventId }
    }
    
    func getFlowsForTeam(_ teamId: String) -> [CompetitionFlow] {
        return activeFlows.values.filter { $0.teamId == teamId }
    }
    
    func getFlow(flowId: String) -> CompetitionFlow? {
        return activeFlows[flowId]
    }
    
    // MARK: - Statistics
    
    func getIntegrationStats() -> (activeFlows: Int, queuedEvents: Int, totalProcessed: Int) {
        let activeFlowCount = activeFlows.count
        let queuedEventCount = eventQueue.filter { !$0.processed }.count
        let totalProcessed = eventQueue.filter { $0.processed }.count
        
        return (activeFlowCount, queuedEventCount, totalProcessed)
    }
    
    // MARK: - Manual Controls
    
    func forceProcessQueue() {
        processEventQueue()
    }
    
    func pauseProcessing() {
        processingTimer?.invalidate()
        processingTimer = nil
        print("🔗 Integration: Processing paused")
    }
    
    func resumeProcessing() {
        if processingTimer == nil {
            startEventProcessing()
            print("🔗 Integration: Processing resumed")
        }
    }
    
    deinit {
        processingTimer?.invalidate()
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Integration Extensions

extension CompetitionIntegrationService {
    
    // Convenience method to start a full competition flow for a user joining a team event
    func joinTeamCompetition(eventId: String, teamId: String, userId: String) -> CompetitionFlow {
        let flow = startCompetitionFlow(
            eventId: eventId, 
            teamId: teamId, 
            userId: userId, 
            autoEntry: true
        )
        
        // Set up team-specific integrations
        setupTeamIntegrations(flow: flow)
        
        return flow
    }
    
    private func setupTeamIntegrations(flow: CompetitionFlow) {
        // Connect to team wallet for prize distributions
        // Set up team-specific notifications
        // Configure team leaderboard tracking
        print("🔗 Integration: Set up team integrations for flow \(flow.flowId)")
    }
    
    // Method to simulate a complete competition flow for testing
    func simulateCompetitionFlow(eventId: String, teamId: String, userId: String) {
        let flow = startCompetitionFlow(eventId: eventId, teamId: teamId, userId: userId)
        
        // Simulate qualification after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.updateFlowStage(flowId: flow.flowId, newStage: .qualified)
            
            // Auto-entry after 2 more seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.updateFlowStage(flowId: flow.flowId, newStage: .autoEntered)
                
                // Start competing after 1 second
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.updateFlowStage(flowId: flow.flowId, newStage: .competing)
                    
                    // Complete event after 5 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                        self.updateFlowStage(flowId: flow.flowId, newStage: .eventCompleted)
                    }
                }
            }
        }
        
        print("🔗 Integration: Started simulated competition flow \(flow.flowId)")
    }
}