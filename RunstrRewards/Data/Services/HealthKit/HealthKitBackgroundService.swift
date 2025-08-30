import Foundation
import HealthKit

actor HealthKitBackgroundService {
    static let shared = HealthKitBackgroundService()
    
    private let healthStore = HKHealthStore()
    
    // Enhanced detection system
    private var observerQuery: HKObserverQuery?
    private var anchoredQuery: HKAnchoredObjectQuery?
    private var activityQuery: HKActivitySummaryQuery?
    private var queryAnchor: HKQueryAnchor?
    
    private var lastProcessedWorkoutDate = Date().addingTimeInterval(-3600)
    
    // Keys for UserDefaults persistence
    private let queryAnchorKey = "healthkit_query_anchor"
    private let lastProcessedDateKey = "healthkit_last_processed_date"
    
    private init() {
        // Load persisted data immediately (we're already in actor context)
        loadLastProcessedDate()
    }
    
    // MARK: - Background Sync
    
    func enableBackgroundDelivery() async throws {
        let workoutType = HKObjectType.workoutType()
        
        return try await withCheckedThrowingContinuation { continuation in
            healthStore.enableBackgroundDelivery(for: workoutType, frequency: .immediate) { success, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    print("HealthKitService: Background delivery enabled")
                    continuation.resume()
                }
            }
        }
    }
    
    func observeWorkouts(handler: @escaping ([HealthKitWorkout]) -> Void) {
        print("🚀 HealthKitService: Starting enhanced triple detection system")
        
        // Layer 1: HKObserverQuery for immediate detection
        setupObserverQuery(handler: handler)
        
        // Layer 2: HKAnchoredObjectQuery for reliable incremental updates
        setupAnchoredQuery(handler: handler)
        
        // Layer 3: HKActivitySummaryQuery for early workout indicators
        setupActivityQuery(handler: handler)
    }
    
    private func setupObserverQuery(handler: @escaping ([HealthKitWorkout]) -> Void) {
        let workoutType = HKObjectType.workoutType()
        
        observerQuery = HKObserverQuery(sampleType: workoutType, predicate: nil) { [weak self] query, completionHandler, error in
            if let error = error {
                print("❌ HealthKitService: Observer query error: \(error)")
                completionHandler()
                return
            }
            
            print("🔍 HealthKitService: IMMEDIATE workout detection triggered!")
            
            Task {
                await self?.processNewWorkouts(source: "ObserverQuery", handler: handler)
                completionHandler()
            }
        }
        
        guard let observerQuery = observerQuery else {
            print("❌ HealthKitService: Failed to create observer query")
            return
        }
        
        healthStore.execute(observerQuery)
        print("✅ HealthKitService: Observer query activated")
    }
    
    private func setupAnchoredQuery(handler: @escaping ([HealthKitWorkout]) -> Void) {
        let workoutType = HKObjectType.workoutType()
        
        // Load persisted anchor or start from nil for all-time query
        if queryAnchor == nil {
            queryAnchor = loadPersistedAnchor()
        }
        
        anchoredQuery = HKAnchoredObjectQuery(
            type: workoutType,
            predicate: nil,
            anchor: queryAnchor,
            limit: HKObjectQueryNoLimit
        ) { [weak self] query, samples, deletedObjects, newAnchor, error in
            
            if let error = error {
                print("❌ HealthKitService: Anchored query error: \(error)")
                return
            }
            
            guard let workouts = samples as? [HKWorkout], !workouts.isEmpty else {
                self?.queryAnchor = newAnchor
                self?.persistAnchor(newAnchor)
                return
            }
            
            print("⚓ HealthKitService: Anchored query found \(workouts.count) new workouts!")
            self?.queryAnchor = newAnchor
            self?.persistAnchor(newAnchor)
            
            Task {
                await self?.processAnchoredWorkouts(workouts, handler: handler)
            }
        }
        
        anchoredQuery?.updateHandler = { [weak self] query, samples, deletedObjects, newAnchor, error in
            guard let workouts = samples as? [HKWorkout], !workouts.isEmpty else {
                Task {
                    await self?.setQueryAnchor(newAnchor)
                    await self?.persistAnchor(newAnchor)
                }
                return
            }
            
            print("🔄 HealthKitService: Anchored query UPDATE - \(workouts.count) new workouts!")
            Task {
                await self?.setQueryAnchor(newAnchor)
                await self?.persistAnchor(newAnchor)
                await self?.processAnchoredWorkouts(workouts, handler: handler)
            }
        }
        
        guard let anchoredQuery = anchoredQuery else {
            print("❌ HealthKitService: Failed to create anchored query")
            return
        }
        
        healthStore.execute(anchoredQuery)
        print("✅ HealthKitService: Anchored query activated")
    }
    
    private func setupActivityQuery(handler: @escaping ([HealthKitWorkout]) -> Void) {
        let calendar = Calendar.current
        let now = Date()
        let _ = calendar.startOfDay(for: now) // For future use
        
        let predicate = HKQuery.predicateForActivitySummary(with: DateComponents(calendar: calendar, year: calendar.component(.year, from: now), month: calendar.component(.month, from: now), day: calendar.component(.day, from: now)))
        
        activityQuery = HKActivitySummaryQuery(predicate: predicate) { [weak self] query, summaries, error in
            if let error = error {
                print("❌ HealthKitService: Activity query error: \(error)")
                return
            }
            
            guard let summaries = summaries, !summaries.isEmpty else { return }
            
            print("🎯 HealthKitService: Activity summary detected - checking for workouts")
            
            Task {
                // Activity changed, immediately check for new workouts
                await self?.processNewWorkouts(source: "ActivityQuery", handler: handler)
            }
        }
        
        activityQuery?.updateHandler = { [weak self] query, summaries, error in
            print("📊 HealthKitService: Activity summary UPDATED - checking for new workouts immediately!")
            
            Task {
                await self?.processNewWorkouts(source: "ActivityUpdate", handler: handler)
            }
        }
        
        guard let activityQuery = activityQuery else {
            print("❌ HealthKitService: Failed to create activity query")
            return
        }
        
        healthStore.execute(activityQuery)
        print("✅ HealthKitService: Activity query activated")
    }
    
    private func processNewWorkouts(source: String, handler: @escaping ([HealthKitWorkout]) -> Void) async {
        do {
            // Fetch ALL recent workouts, don't filter by time initially
            let allWorkouts = try await HealthKitService.shared.fetchRecentWorkouts(limit: 20)
            print("📊 HealthKitService [\(source)]: Found \(allWorkouts.count) total workouts")
            
            // Only process truly NEW workouts since last processing
            let currentLastProcessed = lastProcessedWorkoutDate
            let newWorkouts = allWorkouts.filter { workout in
                workout.startDate > currentLastProcessed
            }
            
            print("🆕 HealthKitService [\(source)]: \(newWorkouts.count) workouts are NEW since last processing")
            
            if !newWorkouts.isEmpty {
                // Apply deduplication to prevent triple processing
                let uniqueWorkouts = await WorkoutProcessingDeduplicator.shared.filterUniqueWorkouts(newWorkouts, source: source)
                
                if !uniqueWorkouts.isEmpty {
                    // Update last processed date to prevent duplicates (within actor)
                    let newLastProcessedDate = uniqueWorkouts.map { $0.startDate }.max() ?? currentLastProcessed
                    lastProcessedWorkoutDate = newLastProcessedDate
                    persistLastProcessedDate()
                    
                    await MainActor.run {
                        handler(uniqueWorkouts)
                    
                        // Post notification for each UNIQUE workout IMMEDIATELY
                        for workout in uniqueWorkouts {
                            NotificationCenter.default.post(
                                name: NSNotification.Name("WorkoutAdded"),
                                object: nil,
                                userInfo: [
                                    "workout": workout,
                                    "userId": AuthenticationService.shared.currentUserId ?? "",
                                    "detection_source": source,
                                    "detection_time": Date()
                                ]
                            )
                            
                            print("⚡ HealthKitService [\(source)]: IMMEDIATE notification sent for workout \(workout.id)")
                        }
                        
                        print("🔔 HealthKitService [\(source)]: Posted \(uniqueWorkouts.count) IMMEDIATE workout notifications")
                    }
                } else {
                    print("🚫 HealthKitService [\(source)]: All workouts filtered out by deduplication")
                }
            }
            
        } catch {
            print("❌ HealthKitService [\(source)]: Failed to process new workouts: \(error)")
        }
    }
    
    private func processAnchoredWorkouts(_ hkWorkouts: [HKWorkout], handler: @escaping ([HealthKitWorkout]) -> Void) async {
        let healthKitWorkouts = hkWorkouts.map { workout in
            HealthKitWorkout(
                id: workout.uuid.uuidString,
                activityType: workout.workoutActivityType,
                startDate: workout.startDate,
                endDate: workout.endDate,
                duration: workout.duration,
                totalDistance: workout.totalDistance?.doubleValue(for: .meter()),
                totalEnergyBurned: workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()),
                syncSource: .healthKit,
                metadata: workout.metadata
            )
        }
        
        // Only process truly NEW workouts (within actor)
        let currentLastProcessed = lastProcessedWorkoutDate
        let newWorkouts = healthKitWorkouts.filter { workout in
            workout.startDate > currentLastProcessed
        }
        
        if !newWorkouts.isEmpty {
            // Apply deduplication to prevent triple processing
            let uniqueWorkouts = await WorkoutProcessingDeduplicator.shared.filterUniqueWorkouts(newWorkouts, source: "AnchoredQuery")
            
            if !uniqueWorkouts.isEmpty {
                // Update last processed date (within actor)
                let newLastProcessedDate = uniqueWorkouts.map { $0.startDate }.max() ?? currentLastProcessed
                lastProcessedWorkoutDate = newLastProcessedDate
                persistLastProcessedDate()
                
                await MainActor.run {
                    handler(uniqueWorkouts)
                    
                    for workout in uniqueWorkouts {
                        NotificationCenter.default.post(
                            name: NSNotification.Name("WorkoutAdded"),
                            object: nil,
                            userInfo: [
                                "workout": workout,
                                "userId": AuthenticationService.shared.currentUserId ?? "",
                                "detection_source": "AnchoredQuery",
                                "detection_time": Date()
                            ]
                        )
                    }
                    
                    print("⚓ HealthKitService: Processed \(uniqueWorkouts.count) unique anchored workouts")
                }
            } else {
                print("🚫 HealthKitService: All anchored workouts filtered out by deduplication")
            }
        }
    }
    
    // MARK: - Anchor Persistence Methods
    
    private func loadPersistedAnchor() -> HKQueryAnchor? {
        guard let data = UserDefaults.standard.data(forKey: queryAnchorKey) else {
            print("📄 HealthKitService: No persisted anchor found - starting fresh")
            return nil
        }
        
        do {
            let anchor = try NSKeyedUnarchiver.unarchivedObject(ofClass: HKQueryAnchor.self, from: data)
            print("📄 HealthKitService: Loaded persisted anchor")
            return anchor
        } catch {
            print("❌ HealthKitService: Failed to load persisted anchor: \(error)")
            return nil
        }
    }
    
    private func setQueryAnchor(_ anchor: HKQueryAnchor?) {
        queryAnchor = anchor
    }
    
    private func persistAnchor(_ anchor: HKQueryAnchor?) {
        guard let anchor = anchor else { return }
        
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: anchor, requiringSecureCoding: true)
            UserDefaults.standard.set(data, forKey: queryAnchorKey)
            print("💾 HealthKitService: Anchor persisted successfully")
        } catch {
            print("❌ HealthKitService: Failed to persist anchor: \(error)")
        }
    }
    
    private func loadLastProcessedDate() {
        if let date = UserDefaults.standard.object(forKey: lastProcessedDateKey) as? Date {
            lastProcessedWorkoutDate = date
            print("📄 HealthKitService: Loaded last processed date: \(date)")
        }
    }
    
    private func persistLastProcessedDate() {
        UserDefaults.standard.set(lastProcessedWorkoutDate, forKey: lastProcessedDateKey)
    }
    
    // MARK: - Immediate Detection Methods
    
    func forceWorkoutCheck(handler: @escaping ([HealthKitWorkout]) -> Void) async {
        print("🔥 HealthKitService: FORCE workout check initiated")
        await processNewWorkouts(source: "ForceCheck", handler: handler)
    }
    
    func stopAllQueries() {
        if let observerQuery = observerQuery {
            healthStore.stop(observerQuery)
            self.observerQuery = nil
        }
        
        if let anchoredQuery = anchoredQuery {
            healthStore.stop(anchoredQuery)
            self.anchoredQuery = nil
        }
        
        if let activityQuery = activityQuery {
            healthStore.stop(activityQuery)
            self.activityQuery = nil
        }
        
        print("🛑 HealthKitService: All queries stopped")
    }
}