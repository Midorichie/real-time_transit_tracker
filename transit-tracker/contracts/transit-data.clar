;; transit-data.clar - Smart contract for transit data storage and retrieval
;; Author: [Your Name]
;; Version: 0.1.0

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-invalid-data (err u102))
(define-constant err-invalid-coordinates (err u103))
(define-constant err-unauthorized (err u104))

;; Access control map for managing authorized data providers
(define-map authorized-providers 
  { provider: principal } 
  { active: bool }
)

;; Print events for important actions (security audit trail)
(define-data-var enable-event-logging bool true)

;; Data variables
(define-data-var last-update uint u0)  ;; Timestamp of last data update

;; Data maps
(define-map transit-stops
  { stop-id: (string-ascii 20) }
  {
    name: (string-ascii 100),
    latitude: int,
    longitude: int,
    active: bool
  }
)

(define-map transit-vehicles
  { vehicle-id: (string-ascii 20) }
  {
    route-id: (string-ascii 20),
    latitude: int,
    longitude: int,
    last-position-update: uint,
    status: (string-ascii 20)  ;; "in-service", "out-of-service", etc.
  }
)

(define-map transit-routes
  { route-id: (string-ascii 20) }
  {
    name: (string-ascii 100),
    stops: (list 20 (string-ascii 20)),
    active: bool
  }
)

;; Read-only functions

(define-read-only (get-stop (stop-id (string-ascii 20)))
  (map-get? transit-stops { stop-id: stop-id })
)

(define-read-only (get-vehicle (vehicle-id (string-ascii 20)))
  (map-get? transit-vehicles { vehicle-id: vehicle-id })
)

(define-read-only (get-route (route-id (string-ascii 20)))
  (map-get? transit-routes { route-id: route-id })
)

(define-read-only (get-last-update)
  (var-get last-update)
)

(define-read-only (is-authorized-provider (provider principal))
  (default-to false (get active (map-get? authorized-providers { provider: provider })))
)

;; Helper function to log events when enabled
(define-private (log-event (event-type (string-ascii 20)) (entity-id (string-ascii 20)))
  (if (var-get enable-event-logging)
      (print { event-type: event-type, entity-id: entity-id, block: block-height, sender: tx-sender })
      (print { event-type: "logging-disabled", entity-id: entity-id, block: block-height, sender: tx-sender }))  ;; Both branches now return the same type
)

;; Public functions with access control

(define-public (add-stop 
  (stop-id (string-ascii 20)) 
  (name (string-ascii 100)) 
  (latitude int) 
  (longitude int))
  
  (begin
    ;; Allow contract owner or authorized providers
    (asserts! (or (is-eq tx-sender contract-owner) (is-authorized-provider tx-sender)) err-unauthorized)
    
    ;; Validate coordinates
    (asserts! (and (>= latitude (* -90 1000000)) (<= latitude (* 90 1000000))) err-invalid-coordinates)
    (asserts! (and (>= longitude (* -180 1000000)) (<= longitude (* 180 1000000))) err-invalid-coordinates)
    
    (map-set transit-stops
      { stop-id: stop-id }
      {
        name: name,
        latitude: latitude,
        longitude: longitude,
        active: true
      }
    )
    
    ;; Log the event
    (log-event "add-stop" stop-id)
    
    (ok true)
  )
)

(define-public (add-vehicle 
  (vehicle-id (string-ascii 20)) 
  (route-id (string-ascii 20)) 
  (latitude int) 
  (longitude int) 
  (status (string-ascii 20)))
  
  (begin
    ;; Allow contract owner or authorized providers
    (asserts! (or (is-eq tx-sender contract-owner) (is-authorized-provider tx-sender)) err-unauthorized)
    
    ;; Validate coordinates
    (asserts! (and (>= latitude (* -90 1000000)) (<= latitude (* 90 1000000))) err-invalid-coordinates)
    (asserts! (and (>= longitude (* -180 1000000)) (<= longitude (* 180 1000000))) err-invalid-coordinates)
    
    ;; Validate route exists
    (asserts! (is-some (get-route route-id)) err-not-found)
    
    (map-set transit-vehicles
      { vehicle-id: vehicle-id }
      {
        route-id: route-id,
        latitude: latitude,
        longitude: longitude,
        last-position-update: block-height,
        status: status
      }
    )
    
    ;; Log the event
    (log-event "add-vehicle" vehicle-id)
    
    (ok true)
  )
)

(define-public (add-route 
  (route-id (string-ascii 20)) 
  (name (string-ascii 100)) 
  (stops (list 20 (string-ascii 20))))
  
  (begin
    ;; Allow contract owner or authorized providers
    (asserts! (or (is-eq tx-sender contract-owner) (is-authorized-provider tx-sender)) err-unauthorized)
    
    ;; Validate that all stops exist
    ;; This is a simplified check - in production would need to validate each stop
    (asserts! (> (len stops) u0) err-invalid-data)
    
    (map-set transit-routes
      { route-id: route-id }
      {
        name: name,
        stops: stops,
        active: true
      }
    )
    
    ;; Log the event
    (log-event "add-route" route-id)
    
    (ok true)
  )
)

(define-public (update-vehicle-position 
  (vehicle-id (string-ascii 20)) 
  (latitude int) 
  (longitude int))
  
  (let ((vehicle (unwrap! (get-vehicle vehicle-id) err-not-found)))
    (begin
      (asserts! (is-eq tx-sender contract-owner) err-owner-only)
      ;; Validate coordinates
      (asserts! (and (>= latitude (* -90 1000000)) (<= latitude (* 90 1000000))) err-invalid-coordinates)
      (asserts! (and (>= longitude (* -180 1000000)) (<= longitude (* 180 1000000))) err-invalid-coordinates)
      
      (map-set transit-vehicles
        { vehicle-id: vehicle-id }
        (merge vehicle {
          latitude: latitude,
          longitude: longitude,
          last-position-update: block-height
        })
      )
      (var-set last-update block-height)
      (ok true)
    )
  )
)

(define-public (set-stop-status 
  (stop-id (string-ascii 20)) 
  (active bool))
  
  (let ((stop (unwrap! (get-stop stop-id) err-not-found)))
    (begin
      (asserts! (is-eq tx-sender contract-owner) err-owner-only)
      (map-set transit-stops
        { stop-id: stop-id }
        (merge stop { active: active })
      )
      (ok true)
    )
  )
)

(define-public (set-route-status 
  (route-id (string-ascii 20)) 
  (active bool))
  
  (let ((route (unwrap! (get-route route-id) err-not-found)))
    (begin
      (asserts! (is-eq tx-sender contract-owner) err-owner-only)
      (map-set transit-routes
        { route-id: route-id }
        (merge route { active: active })
      )
      
      ;; Log the event
      (log-event "route-status" route-id)
      
      (ok true)
    )
  )
)

;; Provider management functions - only for contract owner

(define-public (set-provider-status (provider principal) (active bool))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (map-set authorized-providers
      { provider: provider }
      { active: active }
    )
    
    ;; Log the event
    (print { event-type: "set-provider", provider: provider, active: active })
    
    (ok true)
  )
)

(define-public (toggle-event-logging (enabled bool))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (var-set enable-event-logging enabled)
    (ok true)
  )
)
